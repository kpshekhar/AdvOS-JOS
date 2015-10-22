
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
f0100039:	e8 6a 00 00 00       	call   f01000a8 <i386_init>

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
f0100045:	83 ec 10             	sub    $0x10,%esp
f0100048:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010004b:	83 3d 80 be 22 f0 00 	cmpl   $0x0,0xf022be80
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 80 be 22 f0    	mov    %esi,0xf022be80

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 85 5d 00 00       	call   f0105de9 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 c0 64 10 f0 	movl   $0xf01064c0,(%esp)
f010007d:	e8 aa 40 00 00       	call   f010412c <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 6b 40 00 00       	call   f01040f9 <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 32 7d 10 f0 	movl   $0xf0107d32,(%esp)
f0100095:	e8 92 40 00 00       	call   f010412c <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 ff 08 00 00       	call   f01009a5 <monitor>
f01000a6:	eb f2                	jmp    f010009a <_panic+0x5a>

f01000a8 <i386_init>:
static void boot_aps(void);


void
i386_init(void)
{
f01000a8:	55                   	push   %ebp
f01000a9:	89 e5                	mov    %esp,%ebp
f01000ab:	53                   	push   %ebx
f01000ac:	83 ec 14             	sub    $0x14,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000af:	b8 08 d0 26 f0       	mov    $0xf026d008,%eax
f01000b4:	2d 07 ad 22 f0       	sub    $0xf022ad07,%eax
f01000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000c4:	00 
f01000c5:	c7 04 24 07 ad 22 f0 	movl   $0xf022ad07,(%esp)
f01000cc:	e8 c6 56 00 00       	call   f0105797 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000d1:	e8 c9 05 00 00       	call   f010069f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 2c 65 10 f0 	movl   $0xf010652c,(%esp)
f01000e5:	e8 42 40 00 00       	call   f010412c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000ea:	e8 06 15 00 00       	call   f01015f5 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000ef:	e8 df 37 00 00       	call   f01038d3 <env_init>
	trap_init();
f01000f4:	e8 eb 40 00 00       	call   f01041e4 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000f9:	e8 dc 59 00 00       	call   f0105ada <mp_init>
	lapic_init();
f01000fe:	66 90                	xchg   %ax,%ax
f0100100:	e8 ff 5c 00 00       	call   f0105e04 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f0100105:	e8 52 3f 00 00       	call   f010405c <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010010a:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0100111:	e8 51 5f 00 00       	call   f0106067 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100116:	83 3d 88 be 22 f0 07 	cmpl   $0x7,0xf022be88
f010011d:	77 24                	ja     f0100143 <i386_init+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f0100126:	00 
f0100127:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f010012e:	f0 
f010012f:	c7 44 24 04 59 00 00 	movl   $0x59,0x4(%esp)
f0100136:	00 
f0100137:	c7 04 24 47 65 10 f0 	movl   $0xf0106547,(%esp)
f010013e:	e8 fd fe ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100143:	b8 12 5a 10 f0       	mov    $0xf0105a12,%eax
f0100148:	2d 98 59 10 f0       	sub    $0xf0105998,%eax
f010014d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100151:	c7 44 24 04 98 59 10 	movl   $0xf0105998,0x4(%esp)
f0100158:	f0 
f0100159:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100160:	e8 7f 56 00 00       	call   f01057e4 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100165:	bb 20 c0 22 f0       	mov    $0xf022c020,%ebx
f010016a:	eb 4d                	jmp    f01001b9 <i386_init+0x111>
		if (c == cpus + cpunum())  // We've started already.
f010016c:	e8 78 5c 00 00       	call   f0105de9 <cpunum>
f0100171:	6b c0 74             	imul   $0x74,%eax,%eax
f0100174:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0100179:	39 c3                	cmp    %eax,%ebx
f010017b:	74 39                	je     f01001b6 <i386_init+0x10e>
f010017d:	89 d8                	mov    %ebx,%eax
f010017f:	2d 20 c0 22 f0       	sub    $0xf022c020,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100184:	c1 f8 02             	sar    $0x2,%eax
f0100187:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f010018d:	c1 e0 0f             	shl    $0xf,%eax
f0100190:	8d 80 00 50 23 f0    	lea    -0xfdcb000(%eax),%eax
f0100196:	a3 84 be 22 f0       	mov    %eax,0xf022be84
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010019b:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f01001a2:	00 
f01001a3:	0f b6 03             	movzbl (%ebx),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 a6 5d 00 00       	call   f0105f54 <lapic_startap>
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f01001ae:	8b 43 04             	mov    0x4(%ebx),%eax
f01001b1:	83 f8 01             	cmp    $0x1,%eax
f01001b4:	75 f8                	jne    f01001ae <i386_init+0x106>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01001b6:	83 c3 74             	add    $0x74,%ebx
f01001b9:	6b 05 c4 c3 22 f0 74 	imul   $0x74,0xf022c3c4,%eax
f01001c0:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f01001c5:	39 c3                	cmp    %eax,%ebx
f01001c7:	72 a3                	jb     f010016c <i386_init+0xc4>
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	//ENV_CREATE(user_primes, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001d0:	00 
f01001d1:	c7 04 24 52 87 19 f0 	movl   $0xf0198752,(%esp)
f01001d8:	e8 e9 38 00 00       	call   f0103ac6 <env_create>

	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001dd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001e4:	00 
f01001e5:	c7 04 24 52 87 19 f0 	movl   $0xf0198752,(%esp)
f01001ec:	e8 d5 38 00 00       	call   f0103ac6 <env_create>

	ENV_CREATE(user_yield, ENV_TYPE_USER);
f01001f1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001f8:	00 
f01001f9:	c7 04 24 52 87 19 f0 	movl   $0xf0198752,(%esp)
f0100200:	e8 c1 38 00 00       	call   f0103ac6 <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f0100205:	e8 1c 47 00 00       	call   f0104926 <sched_yield>

f010020a <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f010020a:	55                   	push   %ebp
f010020b:	89 e5                	mov    %esp,%ebp
f010020d:	83 ec 18             	sub    $0x18,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f0100210:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100215:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010021a:	77 20                	ja     f010023c <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010021c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100220:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0100227:	f0 
f0100228:	c7 44 24 04 70 00 00 	movl   $0x70,0x4(%esp)
f010022f:	00 
f0100230:	c7 04 24 47 65 10 f0 	movl   $0xf0106547,(%esp)
f0100237:	e8 04 fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010023c:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0100241:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f0100244:	e8 a0 5b 00 00       	call   f0105de9 <cpunum>
f0100249:	89 44 24 04          	mov    %eax,0x4(%esp)
f010024d:	c7 04 24 53 65 10 f0 	movl   $0xf0106553,(%esp)
f0100254:	e8 d3 3e 00 00       	call   f010412c <cprintf>

	lapic_init();
f0100259:	e8 a6 5b 00 00       	call   f0105e04 <lapic_init>
	env_init_percpu();
f010025e:	e8 46 36 00 00       	call   f01038a9 <env_init_percpu>
	trap_init_percpu();
f0100263:	e8 e8 3e 00 00       	call   f0104150 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100268:	e8 7c 5b 00 00       	call   f0105de9 <cpunum>
f010026d:	6b d0 74             	imul   $0x74,%eax,%edx
f0100270:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100276:	b8 01 00 00 00       	mov    $0x1,%eax
f010027b:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010027f:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0100286:	e8 dc 5d 00 00       	call   f0106067 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f010028b:	e8 96 46 00 00       	call   f0104926 <sched_yield>

f0100290 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100290:	55                   	push   %ebp
f0100291:	89 e5                	mov    %esp,%ebp
f0100293:	53                   	push   %ebx
f0100294:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100297:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010029a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010029d:	89 44 24 08          	mov    %eax,0x8(%esp)
f01002a1:	8b 45 08             	mov    0x8(%ebp),%eax
f01002a4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01002a8:	c7 04 24 69 65 10 f0 	movl   $0xf0106569,(%esp)
f01002af:	e8 78 3e 00 00       	call   f010412c <cprintf>
	vcprintf(fmt, ap);
f01002b4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01002b8:	8b 45 10             	mov    0x10(%ebp),%eax
f01002bb:	89 04 24             	mov    %eax,(%esp)
f01002be:	e8 36 3e 00 00       	call   f01040f9 <vcprintf>
	cprintf("\n");
f01002c3:	c7 04 24 32 7d 10 f0 	movl   $0xf0107d32,(%esp)
f01002ca:	e8 5d 3e 00 00       	call   f010412c <cprintf>
	va_end(ap);
}
f01002cf:	83 c4 14             	add    $0x14,%esp
f01002d2:	5b                   	pop    %ebx
f01002d3:	5d                   	pop    %ebp
f01002d4:	c3                   	ret    
f01002d5:	66 90                	xchg   %ax,%ax
f01002d7:	66 90                	xchg   %ax,%ax
f01002d9:	66 90                	xchg   %ax,%ax
f01002db:	66 90                	xchg   %ax,%ax
f01002dd:	66 90                	xchg   %ax,%ax
f01002df:	90                   	nop

f01002e0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002e0:	55                   	push   %ebp
f01002e1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002e3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002e8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002e9:	a8 01                	test   $0x1,%al
f01002eb:	74 08                	je     f01002f5 <serial_proc_data+0x15>
f01002ed:	b2 f8                	mov    $0xf8,%dl
f01002ef:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002f0:	0f b6 c0             	movzbl %al,%eax
f01002f3:	eb 05                	jmp    f01002fa <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002f5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002fa:	5d                   	pop    %ebp
f01002fb:	c3                   	ret    

f01002fc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002fc:	55                   	push   %ebp
f01002fd:	89 e5                	mov    %esp,%ebp
f01002ff:	53                   	push   %ebx
f0100300:	83 ec 04             	sub    $0x4,%esp
f0100303:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100305:	eb 2a                	jmp    f0100331 <cons_intr+0x35>
		if (c == 0)
f0100307:	85 d2                	test   %edx,%edx
f0100309:	74 26                	je     f0100331 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f010030b:	a1 24 b2 22 f0       	mov    0xf022b224,%eax
f0100310:	8d 48 01             	lea    0x1(%eax),%ecx
f0100313:	89 0d 24 b2 22 f0    	mov    %ecx,0xf022b224
f0100319:	88 90 20 b0 22 f0    	mov    %dl,-0xfdd4fe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f010031f:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100325:	75 0a                	jne    f0100331 <cons_intr+0x35>
			cons.wpos = 0;
f0100327:	c7 05 24 b2 22 f0 00 	movl   $0x0,0xf022b224
f010032e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100331:	ff d3                	call   *%ebx
f0100333:	89 c2                	mov    %eax,%edx
f0100335:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100338:	75 cd                	jne    f0100307 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010033a:	83 c4 04             	add    $0x4,%esp
f010033d:	5b                   	pop    %ebx
f010033e:	5d                   	pop    %ebp
f010033f:	c3                   	ret    

f0100340 <kbd_proc_data>:
f0100340:	ba 64 00 00 00       	mov    $0x64,%edx
f0100345:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100346:	a8 01                	test   $0x1,%al
f0100348:	0f 84 ef 00 00 00    	je     f010043d <kbd_proc_data+0xfd>
f010034e:	b2 60                	mov    $0x60,%dl
f0100350:	ec                   	in     (%dx),%al
f0100351:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100353:	3c e0                	cmp    $0xe0,%al
f0100355:	75 0d                	jne    f0100364 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100357:	83 0d 00 b0 22 f0 40 	orl    $0x40,0xf022b000
		return 0;
f010035e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100363:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100364:	55                   	push   %ebp
f0100365:	89 e5                	mov    %esp,%ebp
f0100367:	53                   	push   %ebx
f0100368:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010036b:	84 c0                	test   %al,%al
f010036d:	79 37                	jns    f01003a6 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010036f:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f0100375:	89 cb                	mov    %ecx,%ebx
f0100377:	83 e3 40             	and    $0x40,%ebx
f010037a:	83 e0 7f             	and    $0x7f,%eax
f010037d:	85 db                	test   %ebx,%ebx
f010037f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100382:	0f b6 d2             	movzbl %dl,%edx
f0100385:	0f b6 82 e0 66 10 f0 	movzbl -0xfef9920(%edx),%eax
f010038c:	83 c8 40             	or     $0x40,%eax
f010038f:	0f b6 c0             	movzbl %al,%eax
f0100392:	f7 d0                	not    %eax
f0100394:	21 c1                	and    %eax,%ecx
f0100396:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
		return 0;
f010039c:	b8 00 00 00 00       	mov    $0x0,%eax
f01003a1:	e9 9d 00 00 00       	jmp    f0100443 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f01003a6:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f01003ac:	f6 c1 40             	test   $0x40,%cl
f01003af:	74 0e                	je     f01003bf <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003b1:	83 c8 80             	or     $0xffffff80,%eax
f01003b4:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f01003b6:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003b9:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
	}

	shift |= shiftcode[data];
f01003bf:	0f b6 d2             	movzbl %dl,%edx
f01003c2:	0f b6 82 e0 66 10 f0 	movzbl -0xfef9920(%edx),%eax
f01003c9:	0b 05 00 b0 22 f0    	or     0xf022b000,%eax
	shift ^= togglecode[data];
f01003cf:	0f b6 8a e0 65 10 f0 	movzbl -0xfef9a20(%edx),%ecx
f01003d6:	31 c8                	xor    %ecx,%eax
f01003d8:	a3 00 b0 22 f0       	mov    %eax,0xf022b000

	c = charcode[shift & (CTL | SHIFT)][data];
f01003dd:	89 c1                	mov    %eax,%ecx
f01003df:	83 e1 03             	and    $0x3,%ecx
f01003e2:	8b 0c 8d c0 65 10 f0 	mov    -0xfef9a40(,%ecx,4),%ecx
f01003e9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003ed:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003f0:	a8 08                	test   $0x8,%al
f01003f2:	74 1b                	je     f010040f <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01003f4:	89 da                	mov    %ebx,%edx
f01003f6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003f9:	83 f9 19             	cmp    $0x19,%ecx
f01003fc:	77 05                	ja     f0100403 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01003fe:	83 eb 20             	sub    $0x20,%ebx
f0100401:	eb 0c                	jmp    f010040f <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f0100403:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f0100406:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100409:	83 fa 19             	cmp    $0x19,%edx
f010040c:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010040f:	f7 d0                	not    %eax
f0100411:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100413:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100415:	f6 c2 06             	test   $0x6,%dl
f0100418:	75 29                	jne    f0100443 <kbd_proc_data+0x103>
f010041a:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100420:	75 21                	jne    f0100443 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100422:	c7 04 24 83 65 10 f0 	movl   $0xf0106583,(%esp)
f0100429:	e8 fe 3c 00 00       	call   f010412c <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010042e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100433:	b8 03 00 00 00       	mov    $0x3,%eax
f0100438:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100439:	89 d8                	mov    %ebx,%eax
f010043b:	eb 06                	jmp    f0100443 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010043d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100442:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100443:	83 c4 14             	add    $0x14,%esp
f0100446:	5b                   	pop    %ebx
f0100447:	5d                   	pop    %ebp
f0100448:	c3                   	ret    

f0100449 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100449:	55                   	push   %ebp
f010044a:	89 e5                	mov    %esp,%ebp
f010044c:	57                   	push   %edi
f010044d:	56                   	push   %esi
f010044e:	53                   	push   %ebx
f010044f:	83 ec 1c             	sub    $0x1c,%esp
f0100452:	89 c7                	mov    %eax,%edi
f0100454:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100459:	be fd 03 00 00       	mov    $0x3fd,%esi
f010045e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100463:	eb 06                	jmp    f010046b <cons_putc+0x22>
f0100465:	89 ca                	mov    %ecx,%edx
f0100467:	ec                   	in     (%dx),%al
f0100468:	ec                   	in     (%dx),%al
f0100469:	ec                   	in     (%dx),%al
f010046a:	ec                   	in     (%dx),%al
f010046b:	89 f2                	mov    %esi,%edx
f010046d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010046e:	a8 20                	test   $0x20,%al
f0100470:	75 05                	jne    f0100477 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100472:	83 eb 01             	sub    $0x1,%ebx
f0100475:	75 ee                	jne    f0100465 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100477:	89 f8                	mov    %edi,%eax
f0100479:	0f b6 c0             	movzbl %al,%eax
f010047c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010047f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100484:	ee                   	out    %al,(%dx)
f0100485:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010048a:	be 79 03 00 00       	mov    $0x379,%esi
f010048f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100494:	eb 06                	jmp    f010049c <cons_putc+0x53>
f0100496:	89 ca                	mov    %ecx,%edx
f0100498:	ec                   	in     (%dx),%al
f0100499:	ec                   	in     (%dx),%al
f010049a:	ec                   	in     (%dx),%al
f010049b:	ec                   	in     (%dx),%al
f010049c:	89 f2                	mov    %esi,%edx
f010049e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010049f:	84 c0                	test   %al,%al
f01004a1:	78 05                	js     f01004a8 <cons_putc+0x5f>
f01004a3:	83 eb 01             	sub    $0x1,%ebx
f01004a6:	75 ee                	jne    f0100496 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004a8:	ba 78 03 00 00       	mov    $0x378,%edx
f01004ad:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f01004b1:	ee                   	out    %al,(%dx)
f01004b2:	b2 7a                	mov    $0x7a,%dl
f01004b4:	b8 0d 00 00 00       	mov    $0xd,%eax
f01004b9:	ee                   	out    %al,(%dx)
f01004ba:	b8 08 00 00 00       	mov    $0x8,%eax
f01004bf:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004c0:	89 fa                	mov    %edi,%edx
f01004c2:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004c8:	89 f8                	mov    %edi,%eax
f01004ca:	80 cc 07             	or     $0x7,%ah
f01004cd:	85 d2                	test   %edx,%edx
f01004cf:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01004d2:	89 f8                	mov    %edi,%eax
f01004d4:	0f b6 c0             	movzbl %al,%eax
f01004d7:	83 f8 09             	cmp    $0x9,%eax
f01004da:	74 76                	je     f0100552 <cons_putc+0x109>
f01004dc:	83 f8 09             	cmp    $0x9,%eax
f01004df:	7f 0a                	jg     f01004eb <cons_putc+0xa2>
f01004e1:	83 f8 08             	cmp    $0x8,%eax
f01004e4:	74 16                	je     f01004fc <cons_putc+0xb3>
f01004e6:	e9 9b 00 00 00       	jmp    f0100586 <cons_putc+0x13d>
f01004eb:	83 f8 0a             	cmp    $0xa,%eax
f01004ee:	66 90                	xchg   %ax,%ax
f01004f0:	74 3a                	je     f010052c <cons_putc+0xe3>
f01004f2:	83 f8 0d             	cmp    $0xd,%eax
f01004f5:	74 3d                	je     f0100534 <cons_putc+0xeb>
f01004f7:	e9 8a 00 00 00       	jmp    f0100586 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01004fc:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f0100503:	66 85 c0             	test   %ax,%ax
f0100506:	0f 84 e5 00 00 00    	je     f01005f1 <cons_putc+0x1a8>
			crt_pos--;
f010050c:	83 e8 01             	sub    $0x1,%eax
f010050f:	66 a3 28 b2 22 f0    	mov    %ax,0xf022b228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f0100515:	0f b7 c0             	movzwl %ax,%eax
f0100518:	66 81 e7 00 ff       	and    $0xff00,%di
f010051d:	83 cf 20             	or     $0x20,%edi
f0100520:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
f0100526:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010052a:	eb 78                	jmp    f01005a4 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010052c:	66 83 05 28 b2 22 f0 	addw   $0x50,0xf022b228
f0100533:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100534:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f010053b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100541:	c1 e8 16             	shr    $0x16,%eax
f0100544:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100547:	c1 e0 04             	shl    $0x4,%eax
f010054a:	66 a3 28 b2 22 f0    	mov    %ax,0xf022b228
f0100550:	eb 52                	jmp    f01005a4 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100552:	b8 20 00 00 00       	mov    $0x20,%eax
f0100557:	e8 ed fe ff ff       	call   f0100449 <cons_putc>
		cons_putc(' ');
f010055c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100561:	e8 e3 fe ff ff       	call   f0100449 <cons_putc>
		cons_putc(' ');
f0100566:	b8 20 00 00 00       	mov    $0x20,%eax
f010056b:	e8 d9 fe ff ff       	call   f0100449 <cons_putc>
		cons_putc(' ');
f0100570:	b8 20 00 00 00       	mov    $0x20,%eax
f0100575:	e8 cf fe ff ff       	call   f0100449 <cons_putc>
		cons_putc(' ');
f010057a:	b8 20 00 00 00       	mov    $0x20,%eax
f010057f:	e8 c5 fe ff ff       	call   f0100449 <cons_putc>
f0100584:	eb 1e                	jmp    f01005a4 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100586:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f010058d:	8d 50 01             	lea    0x1(%eax),%edx
f0100590:	66 89 15 28 b2 22 f0 	mov    %dx,0xf022b228
f0100597:	0f b7 c0             	movzwl %ax,%eax
f010059a:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
f01005a0:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01005a4:	66 81 3d 28 b2 22 f0 	cmpw   $0x7cf,0xf022b228
f01005ab:	cf 07 
f01005ad:	76 42                	jbe    f01005f1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f01005af:	a1 2c b2 22 f0       	mov    0xf022b22c,%eax
f01005b4:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f01005bb:	00 
f01005bc:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005c2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005c6:	89 04 24             	mov    %eax,(%esp)
f01005c9:	e8 16 52 00 00       	call   f01057e4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005ce:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005d4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005d9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005df:	83 c0 01             	add    $0x1,%eax
f01005e2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005e7:	75 f0                	jne    f01005d9 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005e9:	66 83 2d 28 b2 22 f0 	subw   $0x50,0xf022b228
f01005f0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005f1:	8b 0d 30 b2 22 f0    	mov    0xf022b230,%ecx
f01005f7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005fc:	89 ca                	mov    %ecx,%edx
f01005fe:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005ff:	0f b7 1d 28 b2 22 f0 	movzwl 0xf022b228,%ebx
f0100606:	8d 71 01             	lea    0x1(%ecx),%esi
f0100609:	89 d8                	mov    %ebx,%eax
f010060b:	66 c1 e8 08          	shr    $0x8,%ax
f010060f:	89 f2                	mov    %esi,%edx
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100617:	89 ca                	mov    %ecx,%edx
f0100619:	ee                   	out    %al,(%dx)
f010061a:	89 d8                	mov    %ebx,%eax
f010061c:	89 f2                	mov    %esi,%edx
f010061e:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f010061f:	83 c4 1c             	add    $0x1c,%esp
f0100622:	5b                   	pop    %ebx
f0100623:	5e                   	pop    %esi
f0100624:	5f                   	pop    %edi
f0100625:	5d                   	pop    %ebp
f0100626:	c3                   	ret    

f0100627 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100627:	80 3d 34 b2 22 f0 00 	cmpb   $0x0,0xf022b234
f010062e:	74 11                	je     f0100641 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100636:	b8 e0 02 10 f0       	mov    $0xf01002e0,%eax
f010063b:	e8 bc fc ff ff       	call   f01002fc <cons_intr>
}
f0100640:	c9                   	leave  
f0100641:	f3 c3                	repz ret 

f0100643 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100643:	55                   	push   %ebp
f0100644:	89 e5                	mov    %esp,%ebp
f0100646:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100649:	b8 40 03 10 f0       	mov    $0xf0100340,%eax
f010064e:	e8 a9 fc ff ff       	call   f01002fc <cons_intr>
}
f0100653:	c9                   	leave  
f0100654:	c3                   	ret    

f0100655 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100655:	55                   	push   %ebp
f0100656:	89 e5                	mov    %esp,%ebp
f0100658:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010065b:	e8 c7 ff ff ff       	call   f0100627 <serial_intr>
	kbd_intr();
f0100660:	e8 de ff ff ff       	call   f0100643 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100665:	a1 20 b2 22 f0       	mov    0xf022b220,%eax
f010066a:	3b 05 24 b2 22 f0    	cmp    0xf022b224,%eax
f0100670:	74 26                	je     f0100698 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100672:	8d 50 01             	lea    0x1(%eax),%edx
f0100675:	89 15 20 b2 22 f0    	mov    %edx,0xf022b220
f010067b:	0f b6 88 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100682:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100684:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010068a:	75 11                	jne    f010069d <cons_getc+0x48>
			cons.rpos = 0;
f010068c:	c7 05 20 b2 22 f0 00 	movl   $0x0,0xf022b220
f0100693:	00 00 00 
f0100696:	eb 05                	jmp    f010069d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100698:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010069d:	c9                   	leave  
f010069e:	c3                   	ret    

f010069f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010069f:	55                   	push   %ebp
f01006a0:	89 e5                	mov    %esp,%ebp
f01006a2:	57                   	push   %edi
f01006a3:	56                   	push   %esi
f01006a4:	53                   	push   %ebx
f01006a5:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f01006a8:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f01006af:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f01006b6:	5a a5 
	if (*cp != 0xA55A) {
f01006b8:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f01006bf:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006c3:	74 11                	je     f01006d6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01006c5:	c7 05 30 b2 22 f0 b4 	movl   $0x3b4,0xf022b230
f01006cc:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006cf:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006d4:	eb 16                	jmp    f01006ec <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01006d6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006dd:	c7 05 30 b2 22 f0 d4 	movl   $0x3d4,0xf022b230
f01006e4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006e7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006ec:	8b 0d 30 b2 22 f0    	mov    0xf022b230,%ecx
f01006f2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006f7:	89 ca                	mov    %ecx,%edx
f01006f9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006fa:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006fd:	89 da                	mov    %ebx,%edx
f01006ff:	ec                   	in     (%dx),%al
f0100700:	0f b6 f0             	movzbl %al,%esi
f0100703:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100706:	b8 0f 00 00 00       	mov    $0xf,%eax
f010070b:	89 ca                	mov    %ecx,%edx
f010070d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010070e:	89 da                	mov    %ebx,%edx
f0100710:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100711:	89 3d 2c b2 22 f0    	mov    %edi,0xf022b22c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f0100717:	0f b6 d8             	movzbl %al,%ebx
f010071a:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f010071c:	66 89 35 28 b2 22 f0 	mov    %si,0xf022b228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f0100723:	e8 1b ff ff ff       	call   f0100643 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f0100728:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f010072f:	25 fd ff 00 00       	and    $0xfffd,%eax
f0100734:	89 04 24             	mov    %eax,(%esp)
f0100737:	e8 b1 38 00 00       	call   f0103fed <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010073c:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100741:	b8 00 00 00 00       	mov    $0x0,%eax
f0100746:	89 f2                	mov    %esi,%edx
f0100748:	ee                   	out    %al,(%dx)
f0100749:	b2 fb                	mov    $0xfb,%dl
f010074b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100750:	ee                   	out    %al,(%dx)
f0100751:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100756:	b8 0c 00 00 00       	mov    $0xc,%eax
f010075b:	89 da                	mov    %ebx,%edx
f010075d:	ee                   	out    %al,(%dx)
f010075e:	b2 f9                	mov    $0xf9,%dl
f0100760:	b8 00 00 00 00       	mov    $0x0,%eax
f0100765:	ee                   	out    %al,(%dx)
f0100766:	b2 fb                	mov    $0xfb,%dl
f0100768:	b8 03 00 00 00       	mov    $0x3,%eax
f010076d:	ee                   	out    %al,(%dx)
f010076e:	b2 fc                	mov    $0xfc,%dl
f0100770:	b8 00 00 00 00       	mov    $0x0,%eax
f0100775:	ee                   	out    %al,(%dx)
f0100776:	b2 f9                	mov    $0xf9,%dl
f0100778:	b8 01 00 00 00       	mov    $0x1,%eax
f010077d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010077e:	b2 fd                	mov    $0xfd,%dl
f0100780:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100781:	3c ff                	cmp    $0xff,%al
f0100783:	0f 95 c1             	setne  %cl
f0100786:	88 0d 34 b2 22 f0    	mov    %cl,0xf022b234
f010078c:	89 f2                	mov    %esi,%edx
f010078e:	ec                   	in     (%dx),%al
f010078f:	89 da                	mov    %ebx,%edx
f0100791:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100792:	84 c9                	test   %cl,%cl
f0100794:	75 0c                	jne    f01007a2 <cons_init+0x103>
		cprintf("Serial port does not exist!\n");
f0100796:	c7 04 24 8f 65 10 f0 	movl   $0xf010658f,(%esp)
f010079d:	e8 8a 39 00 00       	call   f010412c <cprintf>
}
f01007a2:	83 c4 1c             	add    $0x1c,%esp
f01007a5:	5b                   	pop    %ebx
f01007a6:	5e                   	pop    %esi
f01007a7:	5f                   	pop    %edi
f01007a8:	5d                   	pop    %ebp
f01007a9:	c3                   	ret    

f01007aa <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01007aa:	55                   	push   %ebp
f01007ab:	89 e5                	mov    %esp,%ebp
f01007ad:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01007b0:	8b 45 08             	mov    0x8(%ebp),%eax
f01007b3:	e8 91 fc ff ff       	call   f0100449 <cons_putc>
}
f01007b8:	c9                   	leave  
f01007b9:	c3                   	ret    

f01007ba <getchar>:

int
getchar(void)
{
f01007ba:	55                   	push   %ebp
f01007bb:	89 e5                	mov    %esp,%ebp
f01007bd:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007c0:	e8 90 fe ff ff       	call   f0100655 <cons_getc>
f01007c5:	85 c0                	test   %eax,%eax
f01007c7:	74 f7                	je     f01007c0 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007c9:	c9                   	leave  
f01007ca:	c3                   	ret    

f01007cb <iscons>:

int
iscons(int fdnum)
{
f01007cb:	55                   	push   %ebp
f01007cc:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007ce:	b8 01 00 00 00       	mov    $0x1,%eax
f01007d3:	5d                   	pop    %ebp
f01007d4:	c3                   	ret    
f01007d5:	66 90                	xchg   %ax,%ax
f01007d7:	66 90                	xchg   %ax,%ax
f01007d9:	66 90                	xchg   %ax,%ax
f01007db:	66 90                	xchg   %ax,%ax
f01007dd:	66 90                	xchg   %ax,%ax
f01007df:	90                   	nop

f01007e0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007e0:	55                   	push   %ebp
f01007e1:	89 e5                	mov    %esp,%ebp
f01007e3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007e6:	c7 44 24 08 e0 67 10 	movl   $0xf01067e0,0x8(%esp)
f01007ed:	f0 
f01007ee:	c7 44 24 04 fe 67 10 	movl   $0xf01067fe,0x4(%esp)
f01007f5:	f0 
f01007f6:	c7 04 24 03 68 10 f0 	movl   $0xf0106803,(%esp)
f01007fd:	e8 2a 39 00 00       	call   f010412c <cprintf>
f0100802:	c7 44 24 08 a4 68 10 	movl   $0xf01068a4,0x8(%esp)
f0100809:	f0 
f010080a:	c7 44 24 04 0c 68 10 	movl   $0xf010680c,0x4(%esp)
f0100811:	f0 
f0100812:	c7 04 24 03 68 10 f0 	movl   $0xf0106803,(%esp)
f0100819:	e8 0e 39 00 00       	call   f010412c <cprintf>
f010081e:	c7 44 24 08 15 68 10 	movl   $0xf0106815,0x8(%esp)
f0100825:	f0 
f0100826:	c7 44 24 04 32 68 10 	movl   $0xf0106832,0x4(%esp)
f010082d:	f0 
f010082e:	c7 04 24 03 68 10 f0 	movl   $0xf0106803,(%esp)
f0100835:	e8 f2 38 00 00       	call   f010412c <cprintf>
	return 0;
}
f010083a:	b8 00 00 00 00       	mov    $0x0,%eax
f010083f:	c9                   	leave  
f0100840:	c3                   	ret    

f0100841 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100841:	55                   	push   %ebp
f0100842:	89 e5                	mov    %esp,%ebp
f0100844:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100847:	c7 04 24 3d 68 10 f0 	movl   $0xf010683d,(%esp)
f010084e:	e8 d9 38 00 00       	call   f010412c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100853:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010085a:	00 
f010085b:	c7 04 24 cc 68 10 f0 	movl   $0xf01068cc,(%esp)
f0100862:	e8 c5 38 00 00       	call   f010412c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100867:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010086e:	00 
f010086f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100876:	f0 
f0100877:	c7 04 24 f4 68 10 f0 	movl   $0xf01068f4,(%esp)
f010087e:	e8 a9 38 00 00       	call   f010412c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100883:	c7 44 24 08 b7 64 10 	movl   $0x1064b7,0x8(%esp)
f010088a:	00 
f010088b:	c7 44 24 04 b7 64 10 	movl   $0xf01064b7,0x4(%esp)
f0100892:	f0 
f0100893:	c7 04 24 18 69 10 f0 	movl   $0xf0106918,(%esp)
f010089a:	e8 8d 38 00 00       	call   f010412c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010089f:	c7 44 24 08 07 ad 22 	movl   $0x22ad07,0x8(%esp)
f01008a6:	00 
f01008a7:	c7 44 24 04 07 ad 22 	movl   $0xf022ad07,0x4(%esp)
f01008ae:	f0 
f01008af:	c7 04 24 3c 69 10 f0 	movl   $0xf010693c,(%esp)
f01008b6:	e8 71 38 00 00       	call   f010412c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01008bb:	c7 44 24 08 08 d0 26 	movl   $0x26d008,0x8(%esp)
f01008c2:	00 
f01008c3:	c7 44 24 04 08 d0 26 	movl   $0xf026d008,0x4(%esp)
f01008ca:	f0 
f01008cb:	c7 04 24 60 69 10 f0 	movl   $0xf0106960,(%esp)
f01008d2:	e8 55 38 00 00       	call   f010412c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008d7:	b8 07 d4 26 f0       	mov    $0xf026d407,%eax
f01008dc:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008e1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008e6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008ec:	85 c0                	test   %eax,%eax
f01008ee:	0f 48 c2             	cmovs  %edx,%eax
f01008f1:	c1 f8 0a             	sar    $0xa,%eax
f01008f4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008f8:	c7 04 24 84 69 10 f0 	movl   $0xf0106984,(%esp)
f01008ff:	e8 28 38 00 00       	call   f010412c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100904:	b8 00 00 00 00       	mov    $0x0,%eax
f0100909:	c9                   	leave  
f010090a:	c3                   	ret    

f010090b <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f010090b:	55                   	push   %ebp
f010090c:	89 e5                	mov    %esp,%ebp
f010090e:	57                   	push   %edi
f010090f:	56                   	push   %esi
f0100910:	53                   	push   %ebx
f0100911:	83 ec 6c             	sub    $0x6c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100914:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f0100916:	c7 04 24 56 68 10 f0 	movl   $0xf0106856,(%esp)
f010091d:	e8 0a 38 00 00       	call   f010412c <cprintf>
	
	while (ebp){
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f0100922:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100925:	eb 6d                	jmp    f0100994 <mon_backtrace+0x89>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f0100927:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f010092a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010092e:	89 34 24             	mov    %esi,(%esp)
f0100931:	e8 20 43 00 00       	call   f0104c56 <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f0100936:	89 f0                	mov    %esi,%eax
f0100938:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010093b:	89 44 24 30          	mov    %eax,0x30(%esp)
f010093f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100942:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f0100946:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100949:	89 44 24 28          	mov    %eax,0x28(%esp)
f010094d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100950:	89 44 24 24          	mov    %eax,0x24(%esp)
f0100954:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100957:	89 44 24 20          	mov    %eax,0x20(%esp)
f010095b:	8b 43 18             	mov    0x18(%ebx),%eax
f010095e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100962:	8b 43 14             	mov    0x14(%ebx),%eax
f0100965:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100969:	8b 43 10             	mov    0x10(%ebx),%eax
f010096c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100970:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100973:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100977:	8b 43 08             	mov    0x8(%ebx),%eax
f010097a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010097e:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100982:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100986:	c7 04 24 b0 69 10 f0 	movl   $0xf01069b0,(%esp)
f010098d:	e8 9a 37 00 00       	call   f010412c <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f0100992:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100994:	85 db                	test   %ebx,%ebx
f0100996:	75 8f                	jne    f0100927 <mon_backtrace+0x1c>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100998:	b8 00 00 00 00       	mov    $0x0,%eax
f010099d:	83 c4 6c             	add    $0x6c,%esp
f01009a0:	5b                   	pop    %ebx
f01009a1:	5e                   	pop    %esi
f01009a2:	5f                   	pop    %edi
f01009a3:	5d                   	pop    %ebp
f01009a4:	c3                   	ret    

f01009a5 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f01009a5:	55                   	push   %ebp
f01009a6:	89 e5                	mov    %esp,%ebp
f01009a8:	57                   	push   %edi
f01009a9:	56                   	push   %esi
f01009aa:	53                   	push   %ebx
f01009ab:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f01009ae:	c7 04 24 f4 69 10 f0 	movl   $0xf01069f4,(%esp)
f01009b5:	e8 72 37 00 00       	call   f010412c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01009ba:	c7 04 24 18 6a 10 f0 	movl   $0xf0106a18,(%esp)
f01009c1:	e8 66 37 00 00       	call   f010412c <cprintf>

	if (tf != NULL)
f01009c6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009ca:	74 0b                	je     f01009d7 <monitor+0x32>
		print_trapframe(tf);
f01009cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01009cf:	89 04 24             	mov    %eax,(%esp)
f01009d2:	e8 58 39 00 00       	call   f010432f <print_trapframe>

	while (1) {
		buf = readline("K> ");
f01009d7:	c7 04 24 68 68 10 f0 	movl   $0xf0106868,(%esp)
f01009de:	e8 5d 4b 00 00       	call   f0105540 <readline>
f01009e3:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009e5:	85 c0                	test   %eax,%eax
f01009e7:	74 ee                	je     f01009d7 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009e9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009f0:	be 00 00 00 00       	mov    $0x0,%esi
f01009f5:	eb 0a                	jmp    f0100a01 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009f7:	c6 03 00             	movb   $0x0,(%ebx)
f01009fa:	89 f7                	mov    %esi,%edi
f01009fc:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009ff:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100a01:	0f b6 03             	movzbl (%ebx),%eax
f0100a04:	84 c0                	test   %al,%al
f0100a06:	74 63                	je     f0100a6b <monitor+0xc6>
f0100a08:	0f be c0             	movsbl %al,%eax
f0100a0b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a0f:	c7 04 24 6c 68 10 f0 	movl   $0xf010686c,(%esp)
f0100a16:	e8 3f 4d 00 00       	call   f010575a <strchr>
f0100a1b:	85 c0                	test   %eax,%eax
f0100a1d:	75 d8                	jne    f01009f7 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f0100a1f:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a22:	74 47                	je     f0100a6b <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a24:	83 fe 0f             	cmp    $0xf,%esi
f0100a27:	75 16                	jne    f0100a3f <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a29:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a30:	00 
f0100a31:	c7 04 24 71 68 10 f0 	movl   $0xf0106871,(%esp)
f0100a38:	e8 ef 36 00 00       	call   f010412c <cprintf>
f0100a3d:	eb 98                	jmp    f01009d7 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100a3f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a42:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a46:	eb 03                	jmp    f0100a4b <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a48:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a4b:	0f b6 03             	movzbl (%ebx),%eax
f0100a4e:	84 c0                	test   %al,%al
f0100a50:	74 ad                	je     f01009ff <monitor+0x5a>
f0100a52:	0f be c0             	movsbl %al,%eax
f0100a55:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a59:	c7 04 24 6c 68 10 f0 	movl   $0xf010686c,(%esp)
f0100a60:	e8 f5 4c 00 00       	call   f010575a <strchr>
f0100a65:	85 c0                	test   %eax,%eax
f0100a67:	74 df                	je     f0100a48 <monitor+0xa3>
f0100a69:	eb 94                	jmp    f01009ff <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100a6b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a72:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a73:	85 f6                	test   %esi,%esi
f0100a75:	0f 84 5c ff ff ff    	je     f01009d7 <monitor+0x32>
f0100a7b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a80:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a83:	8b 04 85 40 6a 10 f0 	mov    -0xfef95c0(,%eax,4),%eax
f0100a8a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a8e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a91:	89 04 24             	mov    %eax,(%esp)
f0100a94:	e8 63 4c 00 00       	call   f01056fc <strcmp>
f0100a99:	85 c0                	test   %eax,%eax
f0100a9b:	75 24                	jne    f0100ac1 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100a9d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100aa0:	8b 55 08             	mov    0x8(%ebp),%edx
f0100aa3:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100aa7:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100aaa:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100aae:	89 34 24             	mov    %esi,(%esp)
f0100ab1:	ff 14 85 48 6a 10 f0 	call   *-0xfef95b8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100ab8:	85 c0                	test   %eax,%eax
f0100aba:	78 25                	js     f0100ae1 <monitor+0x13c>
f0100abc:	e9 16 ff ff ff       	jmp    f01009d7 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100ac1:	83 c3 01             	add    $0x1,%ebx
f0100ac4:	83 fb 03             	cmp    $0x3,%ebx
f0100ac7:	75 b7                	jne    f0100a80 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100ac9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100acc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad0:	c7 04 24 8e 68 10 f0 	movl   $0xf010688e,(%esp)
f0100ad7:	e8 50 36 00 00       	call   f010412c <cprintf>
f0100adc:	e9 f6 fe ff ff       	jmp    f01009d7 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ae1:	83 c4 5c             	add    $0x5c,%esp
f0100ae4:	5b                   	pop    %ebx
f0100ae5:	5e                   	pop    %esi
f0100ae6:	5f                   	pop    %edi
f0100ae7:	5d                   	pop    %ebp
f0100ae8:	c3                   	ret    
f0100ae9:	66 90                	xchg   %ax,%ax
f0100aeb:	66 90                	xchg   %ax,%ax
f0100aed:	66 90                	xchg   %ax,%ax
f0100aef:	90                   	nop

f0100af0 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100af0:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0100af6:	c1 f8 03             	sar    $0x3,%eax
f0100af9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100afc:	89 c2                	mov    %eax,%edx
f0100afe:	c1 ea 0c             	shr    $0xc,%edx
f0100b01:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0100b07:	72 26                	jb     f0100b2f <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100b09:	55                   	push   %ebp
f0100b0a:	89 e5                	mov    %esp,%ebp
f0100b0c:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b0f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b13:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0100b1a:	f0 
f0100b1b:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100b22:	00 
f0100b23:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0100b2a:	e8 11 f5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100b2f:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));  //page2kva returns virtual address of the 
}
f0100b34:	c3                   	ret    

f0100b35 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b35:	89 d1                	mov    %edx,%ecx
f0100b37:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100b3a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100b3d:	a8 01                	test   $0x1,%al
f0100b3f:	74 5d                	je     f0100b9e <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b41:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b46:	89 c1                	mov    %eax,%ecx
f0100b48:	c1 e9 0c             	shr    $0xc,%ecx
f0100b4b:	3b 0d 88 be 22 f0    	cmp    0xf022be88,%ecx
f0100b51:	72 26                	jb     f0100b79 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b53:	55                   	push   %ebp
f0100b54:	89 e5                	mov    %esp,%ebp
f0100b56:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b59:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b5d:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0100b64:	f0 
f0100b65:	c7 44 24 04 10 04 00 	movl   $0x410,0x4(%esp)
f0100b6c:	00 
f0100b6d:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100b74:	e8 c7 f4 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b79:	c1 ea 0c             	shr    $0xc,%edx
f0100b7c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b82:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b89:	89 c2                	mov    %eax,%edx
f0100b8b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b8e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b93:	85 d2                	test   %edx,%edx
f0100b95:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b9a:	0f 44 c2             	cmove  %edx,%eax
f0100b9d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b9e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100ba3:	c3                   	ret    

f0100ba4 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ba4:	83 3d 3c b2 22 f0 00 	cmpl   $0x0,0xf022b23c
f0100bab:	75 11                	jne    f0100bbe <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100bad:	ba 07 e0 26 f0       	mov    $0xf026e007,%edx
f0100bb2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bb8:	89 15 3c b2 22 f0    	mov    %edx,0xf022b23c
	}
	
	if (n==0){
f0100bbe:	85 c0                	test   %eax,%eax
f0100bc0:	75 06                	jne    f0100bc8 <boot_alloc+0x24>
	return nextfree;
f0100bc2:	a1 3c b2 22 f0       	mov    0xf022b23c,%eax
f0100bc7:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100bc8:	8b 0d 3c b2 22 f0    	mov    0xf022b23c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100bce:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100bd4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bda:	01 ca                	add    %ecx,%edx
f0100bdc:	89 15 3c b2 22 f0    	mov    %edx,0xf022b23c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100be2:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100be8:	77 26                	ja     f0100c10 <boot_alloc+0x6c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100bea:	55                   	push   %ebp
f0100beb:	89 e5                	mov    %esp,%ebp
f0100bed:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bf0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100bf4:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0100bfb:	f0 
f0100bfc:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f0100c03:	00 
f0100c04:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100c0b:	e8 30 f4 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100c10:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0100c15:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100c18:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
f0100c1e:	39 c2                	cmp    %eax,%edx
f0100c20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c25:	0f 46 c1             	cmovbe %ecx,%eax
	}
	return result;
}
f0100c28:	c3                   	ret    

f0100c29 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100c29:	55                   	push   %ebp
f0100c2a:	89 e5                	mov    %esp,%ebp
f0100c2c:	57                   	push   %edi
f0100c2d:	56                   	push   %esi
f0100c2e:	53                   	push   %ebx
f0100c2f:	83 ec 4c             	sub    $0x4c,%esp
f0100c32:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c35:	84 c0                	test   %al,%al
f0100c37:	0f 85 47 03 00 00    	jne    f0100f84 <check_page_free_list+0x35b>
f0100c3d:	e9 54 03 00 00       	jmp    f0100f96 <check_page_free_list+0x36d>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100c42:	c7 44 24 08 64 6a 10 	movl   $0xf0106a64,0x8(%esp)
f0100c49:	f0 
f0100c4a:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0100c51:	00 
f0100c52:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100c59:	e8 e2 f3 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c5e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c61:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c64:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c67:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c6a:	89 c2                	mov    %eax,%edx
f0100c6c:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c72:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c78:	0f 95 c2             	setne  %dl
f0100c7b:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c7e:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c82:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c84:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c88:	8b 00                	mov    (%eax),%eax
f0100c8a:	85 c0                	test   %eax,%eax
f0100c8c:	75 dc                	jne    f0100c6a <check_page_free_list+0x41>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c8e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c91:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c97:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c9a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c9d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c9f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100ca2:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ca7:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cac:	8b 1d 44 b2 22 f0    	mov    0xf022b244,%ebx
f0100cb2:	eb 63                	jmp    f0100d17 <check_page_free_list+0xee>
f0100cb4:	89 d8                	mov    %ebx,%eax
f0100cb6:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0100cbc:	c1 f8 03             	sar    $0x3,%eax
f0100cbf:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100cc2:	89 c2                	mov    %eax,%edx
f0100cc4:	c1 ea 16             	shr    $0x16,%edx
f0100cc7:	39 f2                	cmp    %esi,%edx
f0100cc9:	73 4a                	jae    f0100d15 <check_page_free_list+0xec>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ccb:	89 c2                	mov    %eax,%edx
f0100ccd:	c1 ea 0c             	shr    $0xc,%edx
f0100cd0:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0100cd6:	72 20                	jb     f0100cf8 <check_page_free_list+0xcf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cd8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cdc:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0100ce3:	f0 
f0100ce4:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100ceb:	00 
f0100cec:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0100cf3:	e8 48 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100cf8:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100cff:	00 
f0100d00:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d07:	00 
	return (void *)(pa + KERNBASE);
f0100d08:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100d0d:	89 04 24             	mov    %eax,(%esp)
f0100d10:	e8 82 4a 00 00       	call   f0105797 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d15:	8b 1b                	mov    (%ebx),%ebx
f0100d17:	85 db                	test   %ebx,%ebx
f0100d19:	75 99                	jne    f0100cb4 <check_page_free_list+0x8b>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100d1b:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d20:	e8 7f fe ff ff       	call   f0100ba4 <boot_alloc>
f0100d25:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d28:	8b 15 44 b2 22 f0    	mov    0xf022b244,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d2e:	8b 0d 90 be 22 f0    	mov    0xf022be90,%ecx
		assert(pp < pages + npages);
f0100d34:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0100d39:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d3c:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100d3f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d42:	89 4d cc             	mov    %ecx,-0x34(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d45:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d4a:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d4d:	e9 c4 01 00 00       	jmp    f0100f16 <check_page_free_list+0x2ed>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d52:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100d55:	73 24                	jae    f0100d7b <check_page_free_list+0x152>
f0100d57:	c7 44 24 0c 6f 74 10 	movl   $0xf010746f,0xc(%esp)
f0100d5e:	f0 
f0100d5f:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100d66:	f0 
f0100d67:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0100d6e:	00 
f0100d6f:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100d76:	e8 c5 f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100d7b:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d7e:	72 24                	jb     f0100da4 <check_page_free_list+0x17b>
f0100d80:	c7 44 24 0c 90 74 10 	movl   $0xf0107490,0xc(%esp)
f0100d87:	f0 
f0100d88:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100d8f:	f0 
f0100d90:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0100d97:	00 
f0100d98:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100d9f:	e8 9c f2 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100da4:	89 d0                	mov    %edx,%eax
f0100da6:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100da9:	a8 07                	test   $0x7,%al
f0100dab:	74 24                	je     f0100dd1 <check_page_free_list+0x1a8>
f0100dad:	c7 44 24 0c 88 6a 10 	movl   $0xf0106a88,0xc(%esp)
f0100db4:	f0 
f0100db5:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100dbc:	f0 
f0100dbd:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0100dc4:	00 
f0100dc5:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100dcc:	e8 6f f2 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100dd1:	c1 f8 03             	sar    $0x3,%eax
f0100dd4:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100dd7:	85 c0                	test   %eax,%eax
f0100dd9:	75 24                	jne    f0100dff <check_page_free_list+0x1d6>
f0100ddb:	c7 44 24 0c a4 74 10 	movl   $0xf01074a4,0xc(%esp)
f0100de2:	f0 
f0100de3:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100dea:	f0 
f0100deb:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0100df2:	00 
f0100df3:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100dfa:	e8 41 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100dff:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e04:	75 24                	jne    f0100e2a <check_page_free_list+0x201>
f0100e06:	c7 44 24 0c b5 74 10 	movl   $0xf01074b5,0xc(%esp)
f0100e0d:	f0 
f0100e0e:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100e15:	f0 
f0100e16:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0100e1d:	00 
f0100e1e:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100e25:	e8 16 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e2a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e2f:	75 24                	jne    f0100e55 <check_page_free_list+0x22c>
f0100e31:	c7 44 24 0c bc 6a 10 	movl   $0xf0106abc,0xc(%esp)
f0100e38:	f0 
f0100e39:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100e40:	f0 
f0100e41:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0100e48:	00 
f0100e49:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100e50:	e8 eb f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e55:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e5a:	75 24                	jne    f0100e80 <check_page_free_list+0x257>
f0100e5c:	c7 44 24 0c ce 74 10 	movl   $0xf01074ce,0xc(%esp)
f0100e63:	f0 
f0100e64:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100e6b:	f0 
f0100e6c:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0100e73:	00 
f0100e74:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100e7b:	e8 c0 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e80:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e85:	0f 86 32 01 00 00    	jbe    f0100fbd <check_page_free_list+0x394>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e8b:	89 c1                	mov    %eax,%ecx
f0100e8d:	c1 e9 0c             	shr    $0xc,%ecx
f0100e90:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100e93:	77 20                	ja     f0100eb5 <check_page_free_list+0x28c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e95:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e99:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0100ea0:	f0 
f0100ea1:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100ea8:	00 
f0100ea9:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0100eb0:	e8 8b f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100eb5:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100ebb:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100ebe:	0f 86 e9 00 00 00    	jbe    f0100fad <check_page_free_list+0x384>
f0100ec4:	c7 44 24 0c e0 6a 10 	movl   $0xf0106ae0,0xc(%esp)
f0100ecb:	f0 
f0100ecc:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100ed3:	f0 
f0100ed4:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0100edb:	00 
f0100edc:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100ee3:	e8 58 f1 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100ee8:	c7 44 24 0c e8 74 10 	movl   $0xf01074e8,0xc(%esp)
f0100eef:	f0 
f0100ef0:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100ef7:	f0 
f0100ef8:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0100eff:	00 
f0100f00:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100f07:	e8 34 f1 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100f0c:	83 c3 01             	add    $0x1,%ebx
f0100f0f:	eb 03                	jmp    f0100f14 <check_page_free_list+0x2eb>
		else
			++nfree_extmem;
f0100f11:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100f14:	8b 12                	mov    (%edx),%edx
f0100f16:	85 d2                	test   %edx,%edx
f0100f18:	0f 85 34 fe ff ff    	jne    f0100d52 <check_page_free_list+0x129>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100f1e:	85 db                	test   %ebx,%ebx
f0100f20:	7f 24                	jg     f0100f46 <check_page_free_list+0x31d>
f0100f22:	c7 44 24 0c 05 75 10 	movl   $0xf0107505,0xc(%esp)
f0100f29:	f0 
f0100f2a:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100f31:	f0 
f0100f32:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0100f39:	00 
f0100f3a:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100f41:	e8 fa f0 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100f46:	85 ff                	test   %edi,%edi
f0100f48:	7f 24                	jg     f0100f6e <check_page_free_list+0x345>
f0100f4a:	c7 44 24 0c 17 75 10 	movl   $0xf0107517,0xc(%esp)
f0100f51:	f0 
f0100f52:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0100f59:	f0 
f0100f5a:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0100f61:	00 
f0100f62:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0100f69:	e8 d2 f0 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100f6e:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100f72:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f76:	c7 04 24 28 6b 10 f0 	movl   $0xf0106b28,(%esp)
f0100f7d:	e8 aa 31 00 00       	call   f010412c <cprintf>
f0100f82:	eb 49                	jmp    f0100fcd <check_page_free_list+0x3a4>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100f84:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0100f89:	85 c0                	test   %eax,%eax
f0100f8b:	0f 85 cd fc ff ff    	jne    f0100c5e <check_page_free_list+0x35>
f0100f91:	e9 ac fc ff ff       	jmp    f0100c42 <check_page_free_list+0x19>
f0100f96:	83 3d 44 b2 22 f0 00 	cmpl   $0x0,0xf022b244
f0100f9d:	0f 84 9f fc ff ff    	je     f0100c42 <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100fa3:	be 00 04 00 00       	mov    $0x400,%esi
f0100fa8:	e9 ff fc ff ff       	jmp    f0100cac <check_page_free_list+0x83>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100fad:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fb2:	0f 85 59 ff ff ff    	jne    f0100f11 <check_page_free_list+0x2e8>
f0100fb8:	e9 2b ff ff ff       	jmp    f0100ee8 <check_page_free_list+0x2bf>
f0100fbd:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fc2:	0f 85 44 ff ff ff    	jne    f0100f0c <check_page_free_list+0x2e3>
f0100fc8:	e9 1b ff ff ff       	jmp    f0100ee8 <check_page_free_list+0x2bf>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100fcd:	83 c4 4c             	add    $0x4c,%esp
f0100fd0:	5b                   	pop    %ebx
f0100fd1:	5e                   	pop    %esi
f0100fd2:	5f                   	pop    %edi
f0100fd3:	5d                   	pop    %ebp
f0100fd4:	c3                   	ret    

f0100fd5 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100fd5:	b8 01 00 00 00       	mov    $0x1,%eax
f0100fda:	eb 18                	jmp    f0100ff4 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100fdc:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f0100fe2:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100fe5:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100feb:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100ff1:	83 c0 01             	add    $0x1,%eax
f0100ff4:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0100ffa:	72 e0                	jb     f0100fdc <page_init+0x7>
//


void
page_init(void)
{
f0100ffc:	55                   	push   %ebp
f0100ffd:	89 e5                	mov    %esp,%ebp
f0100fff:	57                   	push   %edi
f0101000:	56                   	push   %esi
f0101001:	53                   	push   %ebx
f0101002:	83 ec 1c             	sub    $0x1c,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0101005:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f010100c:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f010100f:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0101014:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0101019:	bb 01 00 00 00       	mov    $0x1,%ebx
f010101e:	eb 73                	jmp    f0101093 <page_init+0xbe>
		if (i == mpentyPg) {
f0101020:	83 fb 07             	cmp    $0x7,%ebx
f0101023:	75 16                	jne    f010103b <page_init+0x66>
			cprintf("Skipped this page %d\n", i);
f0101025:	c7 44 24 04 07 00 00 	movl   $0x7,0x4(%esp)
f010102c:	00 
f010102d:	c7 04 24 28 75 10 f0 	movl   $0xf0107528,(%esp)
f0101034:	e8 f3 30 00 00       	call   f010412c <cprintf>
			continue;	
f0101039:	eb 52                	jmp    f010108d <page_init+0xb8>
f010103b:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0101042:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f0101048:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f010104f:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0101056:	83 3d 44 b2 22 f0 00 	cmpl   $0x0,0xf022b244
f010105d:	75 10                	jne    f010106f <page_init+0x9a>
			page_free_list = &pages[i];
f010105f:	89 c2                	mov    %eax,%edx
f0101061:	03 15 90 be 22 f0    	add    0xf022be90,%edx
f0101067:	89 15 44 b2 22 f0    	mov    %edx,0xf022b244
f010106d:	eb 16                	jmp    f0101085 <page_init+0xb0>
		} else {
			prev->pp_link = &pages[i];
f010106f:	89 c2                	mov    %eax,%edx
f0101071:	03 15 90 be 22 f0    	add    0xf022be90,%edx
f0101077:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0101079:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f010107f:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0101082:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0101085:	03 05 90 be 22 f0    	add    0xf022be90,%eax
f010108b:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f010108d:	83 c3 01             	add    $0x1,%ebx
f0101090:	83 c6 08             	add    $0x8,%esi
f0101093:	3b 1d 48 b2 22 f0    	cmp    0xf022b248,%ebx
f0101099:	72 85                	jb     f0101020 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f010109b:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f01010a0:	8d 44 d8 f8          	lea    -0x8(%eax,%ebx,8),%eax
f01010a4:	a3 38 b2 22 f0       	mov    %eax,0xf022b238
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f01010a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01010ae:	e8 f1 fa ff ff       	call   f0100ba4 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01010b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01010b8:	77 20                	ja     f01010da <page_init+0x105>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01010ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01010be:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f01010c5:	f0 
f01010c6:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
f01010cd:	00 
f01010ce:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01010d5:	e8 66 ef ff ff       	call   f0100040 <_panic>
f01010da:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f01010df:	c1 e8 0c             	shr    $0xc,%eax
f01010e2:	8b 1d 38 b2 22 f0    	mov    0xf022b238,%ebx
f01010e8:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f01010ef:	eb 2c                	jmp    f010111d <page_init+0x148>
		pages[i].pp_ref = 0;
f01010f1:	89 d1                	mov    %edx,%ecx
f01010f3:	03 0d 90 be 22 f0    	add    0xf022be90,%ecx
f01010f9:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f01010ff:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0101105:	89 d1                	mov    %edx,%ecx
f0101107:	03 0d 90 be 22 f0    	add    0xf022be90,%ecx
f010110d:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f010110f:	89 d3                	mov    %edx,%ebx
f0101111:	03 1d 90 be 22 f0    	add    0xf022be90,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0101117:	83 c0 01             	add    $0x1,%eax
f010111a:	83 c2 08             	add    $0x8,%edx
f010111d:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0101123:	72 cc                	jb     f01010f1 <page_init+0x11c>
f0101125:	89 1d 38 b2 22 f0    	mov    %ebx,0xf022b238
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f010112b:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0101130:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101134:	c7 04 24 50 6b 10 f0 	movl   $0xf0106b50,(%esp)
f010113b:	e8 ec 2f 00 00       	call   f010412c <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0101140:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0101145:	8b 15 88 be 22 f0    	mov    0xf022be88,%edx
f010114b:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f010114f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101153:	c7 04 24 3e 75 10 f0 	movl   $0xf010753e,(%esp)
f010115a:	e8 cd 2f 00 00       	call   f010412c <cprintf>
}
f010115f:	83 c4 1c             	add    $0x1c,%esp
f0101162:	5b                   	pop    %ebx
f0101163:	5e                   	pop    %esi
f0101164:	5f                   	pop    %edi
f0101165:	5d                   	pop    %ebp
f0101166:	c3                   	ret    

f0101167 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0101167:	55                   	push   %ebp
f0101168:	89 e5                	mov    %esp,%ebp
f010116a:	53                   	push   %ebx
f010116b:	83 ec 14             	sub    $0x14,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f010116e:	8b 1d 44 b2 22 f0    	mov    0xf022b244,%ebx
f0101174:	85 db                	test   %ebx,%ebx
f0101176:	74 75                	je     f01011ed <page_alloc+0x86>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0101178:	8b 03                	mov    (%ebx),%eax
f010117a:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
	allocPage->pp_link = NULL;	//Break the link 
f010117f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0101185:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101189:	74 58                	je     f01011e3 <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010118b:	89 d8                	mov    %ebx,%eax
f010118d:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101193:	c1 f8 03             	sar    $0x3,%eax
f0101196:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101199:	89 c2                	mov    %eax,%edx
f010119b:	c1 ea 0c             	shr    $0xc,%edx
f010119e:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f01011a4:	72 20                	jb     f01011c6 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011a6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011aa:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f01011b1:	f0 
f01011b2:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01011b9:	00 
f01011ba:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f01011c1:	e8 7a ee ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f01011c6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01011cd:	00 
f01011ce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01011d5:	00 
	return (void *)(pa + KERNBASE);
f01011d6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011db:	89 04 24             	mov    %eax,(%esp)
f01011de:	e8 b4 45 00 00       	call   f0105797 <memset>
	}
	
	allocPage->pp_ref = 0;
f01011e3:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
f01011e9:	89 d8                	mov    %ebx,%eax
f01011eb:	eb 05                	jmp    f01011f2 <page_alloc+0x8b>
page_alloc(int alloc_flags)
{
	// Check if there is a free_page available 
	if (!page_free_list)
	{ 
	return NULL;
f01011ed:	b8 00 00 00 00       	mov    $0x0,%eax
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
	}
	
	allocPage->pp_ref = 0;
	return allocPage;
}
f01011f2:	83 c4 14             	add    $0x14,%esp
f01011f5:	5b                   	pop    %ebx
f01011f6:	5d                   	pop    %ebp
f01011f7:	c3                   	ret    

f01011f8 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01011f8:	55                   	push   %ebp
f01011f9:	89 e5                	mov    %esp,%ebp
f01011fb:	83 ec 18             	sub    $0x18,%esp
f01011fe:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0101201:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0101206:	74 1c                	je     f0101224 <page_free+0x2c>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0101208:	c7 44 24 08 7c 6b 10 	movl   $0xf0106b7c,0x8(%esp)
f010120f:	f0 
f0101210:	c7 44 24 04 ad 01 00 	movl   $0x1ad,0x4(%esp)
f0101217:	00 
f0101218:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010121f:	e8 1c ee ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0101224:	85 c0                	test   %eax,%eax
f0101226:	75 1c                	jne    f0101244 <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f0101228:	c7 44 24 08 bc 6b 10 	movl   $0xf0106bbc,0x8(%esp)
f010122f:	f0 
f0101230:	c7 44 24 04 b4 01 00 	movl   $0x1b4,0x4(%esp)
f0101237:	00 
f0101238:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010123f:	e8 fc ed ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0101244:	8b 15 44 b2 22 f0    	mov    0xf022b244,%edx
f010124a:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010124c:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
	}


}
f0101251:	c9                   	leave  
f0101252:	c3                   	ret    

f0101253 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101253:	55                   	push   %ebp
f0101254:	89 e5                	mov    %esp,%ebp
f0101256:	83 ec 18             	sub    $0x18,%esp
f0101259:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010125c:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101260:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101263:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101267:	66 85 d2             	test   %dx,%dx
f010126a:	75 08                	jne    f0101274 <page_decref+0x21>
		page_free(pp);
f010126c:	89 04 24             	mov    %eax,(%esp)
f010126f:	e8 84 ff ff ff       	call   f01011f8 <page_free>
}
f0101274:	c9                   	leave  
f0101275:	c3                   	ret    

f0101276 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101276:	55                   	push   %ebp
f0101277:	89 e5                	mov    %esp,%ebp
f0101279:	57                   	push   %edi
f010127a:	56                   	push   %esi
f010127b:	53                   	push   %ebx
f010127c:	83 ec 1c             	sub    $0x1c,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f010127f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101282:	c1 eb 16             	shr    $0x16,%ebx
f0101285:	c1 e3 02             	shl    $0x2,%ebx
f0101288:	03 5d 08             	add    0x8(%ebp),%ebx

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f010128b:	8b 3b                	mov    (%ebx),%edi
f010128d:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0101293:	74 3e                	je     f01012d3 <pgdir_walk+0x5d>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f0101295:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010129b:	89 f8                	mov    %edi,%eax
f010129d:	c1 e8 0c             	shr    $0xc,%eax
f01012a0:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f01012a6:	72 20                	jb     f01012c8 <pgdir_walk+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012a8:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01012ac:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f01012b3:	f0 
f01012b4:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
f01012bb:	00 
f01012bc:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01012c3:	e8 78 ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01012c8:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f01012ce:	e9 8f 00 00 00       	jmp    f0101362 <pgdir_walk+0xec>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f01012d3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01012d7:	0f 84 94 00 00 00    	je     f0101371 <pgdir_walk+0xfb>
f01012dd:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f01012e4:	e8 7e fe ff ff       	call   f0101167 <page_alloc>
f01012e9:	89 c6                	mov    %eax,%esi
f01012eb:	85 c0                	test   %eax,%eax
f01012ed:	0f 84 85 00 00 00    	je     f0101378 <pgdir_walk+0x102>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f01012f3:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012f8:	89 c7                	mov    %eax,%edi
f01012fa:	2b 3d 90 be 22 f0    	sub    0xf022be90,%edi
f0101300:	c1 ff 03             	sar    $0x3,%edi
f0101303:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101306:	89 f8                	mov    %edi,%eax
f0101308:	c1 e8 0c             	shr    $0xc,%eax
f010130b:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0101311:	72 20                	jb     f0101333 <pgdir_walk+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101313:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101317:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f010131e:	f0 
f010131f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101326:	00 
f0101327:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f010132e:	e8 0d ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101333:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f0101339:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101340:	00 
f0101341:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101348:	00 
f0101349:	89 3c 24             	mov    %edi,(%esp)
f010134c:	e8 46 44 00 00       	call   f0105797 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101351:	2b 35 90 be 22 f0    	sub    0xf022be90,%esi
f0101357:	c1 fe 03             	sar    $0x3,%esi
f010135a:	c1 e6 0c             	shl    $0xc,%esi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f010135d:	83 ce 07             	or     $0x7,%esi
f0101360:	89 33                	mov    %esi,(%ebx)
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f0101362:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101365:	c1 e8 0a             	shr    $0xa,%eax
f0101368:	25 fc 0f 00 00       	and    $0xffc,%eax
f010136d:	01 f8                	add    %edi,%eax
f010136f:	eb 0c                	jmp    f010137d <pgdir_walk+0x107>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0101371:	b8 00 00 00 00       	mov    $0x0,%eax
f0101376:	eb 05                	jmp    f010137d <pgdir_walk+0x107>
f0101378:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f010137d:	83 c4 1c             	add    $0x1c,%esp
f0101380:	5b                   	pop    %ebx
f0101381:	5e                   	pop    %esi
f0101382:	5f                   	pop    %edi
f0101383:	5d                   	pop    %ebp
f0101384:	c3                   	ret    

f0101385 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101385:	55                   	push   %ebp
f0101386:	89 e5                	mov    %esp,%ebp
f0101388:	57                   	push   %edi
f0101389:	56                   	push   %esi
f010138a:	53                   	push   %ebx
f010138b:	83 ec 2c             	sub    $0x2c,%esp
f010138e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101391:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f0101397:	8b 45 08             	mov    0x8(%ebp),%eax
f010139a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f010139f:	8d b1 ff 0f 00 00    	lea    0xfff(%ecx),%esi
f01013a5:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01013ab:	89 d3                	mov    %edx,%ebx
f01013ad:	29 d0                	sub    %edx,%eax
f01013af:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f01013b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013b5:	83 c8 01             	or     $0x1,%eax
f01013b8:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01013bb:	eb 48                	jmp    f0101405 <boot_map_region+0x80>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f01013bd:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01013c4:	00 
f01013c5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013c9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01013cc:	89 04 24             	mov    %eax,(%esp)
f01013cf:	e8 a2 fe ff ff       	call   f0101276 <pgdir_walk>
f01013d4:	85 c0                	test   %eax,%eax
f01013d6:	75 1c                	jne    f01013f4 <boot_map_region+0x6f>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f01013d8:	c7 44 24 08 f0 6b 10 	movl   $0xf0106bf0,0x8(%esp)
f01013df:	f0 
f01013e0:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f01013e7:	00 
f01013e8:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01013ef:	e8 4c ec ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f01013f4:	0b 7d dc             	or     -0x24(%ebp),%edi
f01013f7:	89 38                	mov    %edi,(%eax)
		vaBegin += PGSIZE;
f01013f9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f01013ff:	81 ee 00 10 00 00    	sub    $0x1000,%esi
f0101405:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101408:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f010140b:	85 f6                	test   %esi,%esi
f010140d:	75 ae                	jne    f01013bd <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f010140f:	83 c4 2c             	add    $0x2c,%esp
f0101412:	5b                   	pop    %ebx
f0101413:	5e                   	pop    %esi
f0101414:	5f                   	pop    %edi
f0101415:	5d                   	pop    %ebp
f0101416:	c3                   	ret    

f0101417 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101417:	55                   	push   %ebp
f0101418:	89 e5                	mov    %esp,%ebp
f010141a:	53                   	push   %ebx
f010141b:	83 ec 14             	sub    $0x14,%esp
f010141e:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0101421:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101428:	00 
f0101429:	8b 45 0c             	mov    0xc(%ebp),%eax
f010142c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101430:	8b 45 08             	mov    0x8(%ebp),%eax
f0101433:	89 04 24             	mov    %eax,(%esp)
f0101436:	e8 3b fe ff ff       	call   f0101276 <pgdir_walk>
f010143b:	89 c2                	mov    %eax,%edx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f010143d:	85 c0                	test   %eax,%eax
f010143f:	74 1a                	je     f010145b <page_lookup+0x44>
f0101441:	8b 00                	mov    (%eax),%eax
f0101443:	a8 01                	test   $0x1,%al
f0101445:	74 1b                	je     f0101462 <page_lookup+0x4b>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f0101447:	c1 e8 0c             	shr    $0xc,%eax
f010144a:	8b 0d 90 be 22 f0    	mov    0xf022be90,%ecx
f0101450:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		if (pte_store) {
f0101453:	85 db                	test   %ebx,%ebx
f0101455:	74 10                	je     f0101467 <page_lookup+0x50>
			*pte_store = pgTbEty;
f0101457:	89 13                	mov    %edx,(%ebx)
f0101459:	eb 0c                	jmp    f0101467 <page_lookup+0x50>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f010145b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101460:	eb 05                	jmp    f0101467 <page_lookup+0x50>
f0101462:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f0101467:	83 c4 14             	add    $0x14,%esp
f010146a:	5b                   	pop    %ebx
f010146b:	5d                   	pop    %ebp
f010146c:	c3                   	ret    

f010146d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010146d:	55                   	push   %ebp
f010146e:	89 e5                	mov    %esp,%ebp
f0101470:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101473:	e8 71 49 00 00       	call   f0105de9 <cpunum>
f0101478:	6b c0 74             	imul   $0x74,%eax,%eax
f010147b:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0101482:	74 16                	je     f010149a <tlb_invalidate+0x2d>
f0101484:	e8 60 49 00 00       	call   f0105de9 <cpunum>
f0101489:	6b c0 74             	imul   $0x74,%eax,%eax
f010148c:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0101492:	8b 55 08             	mov    0x8(%ebp),%edx
f0101495:	39 50 60             	cmp    %edx,0x60(%eax)
f0101498:	75 06                	jne    f01014a0 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010149a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010149d:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01014a0:	c9                   	leave  
f01014a1:	c3                   	ret    

f01014a2 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f01014a2:	55                   	push   %ebp
f01014a3:	89 e5                	mov    %esp,%ebp
f01014a5:	56                   	push   %esi
f01014a6:	53                   	push   %ebx
f01014a7:	83 ec 20             	sub    $0x20,%esp
f01014aa:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01014ad:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f01014b0:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01014b3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01014b7:	89 74 24 04          	mov    %esi,0x4(%esp)
f01014bb:	89 1c 24             	mov    %ebx,(%esp)
f01014be:	e8 54 ff ff ff       	call   f0101417 <page_lookup>
f01014c3:	85 c0                	test   %eax,%eax
f01014c5:	74 1d                	je     f01014e4 <page_remove+0x42>
		return;
	}
	page_decref(remPage);
f01014c7:	89 04 24             	mov    %eax,(%esp)
f01014ca:	e8 84 fd ff ff       	call   f0101253 <page_decref>
	*pte = 0;
f01014cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014d2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01014d8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01014dc:	89 1c 24             	mov    %ebx,(%esp)
f01014df:	e8 89 ff ff ff       	call   f010146d <tlb_invalidate>
}
f01014e4:	83 c4 20             	add    $0x20,%esp
f01014e7:	5b                   	pop    %ebx
f01014e8:	5e                   	pop    %esi
f01014e9:	5d                   	pop    %ebp
f01014ea:	c3                   	ret    

f01014eb <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01014eb:	55                   	push   %ebp
f01014ec:	89 e5                	mov    %esp,%ebp
f01014ee:	57                   	push   %edi
f01014ef:	56                   	push   %esi
f01014f0:	53                   	push   %ebx
f01014f1:	83 ec 1c             	sub    $0x1c,%esp
f01014f4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014f7:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f01014fa:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101501:	00 
f0101502:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101506:	8b 45 08             	mov    0x8(%ebp),%eax
f0101509:	89 04 24             	mov    %eax,(%esp)
f010150c:	e8 65 fd ff ff       	call   f0101276 <pgdir_walk>
f0101511:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f0101513:	85 c0                	test   %eax,%eax
f0101515:	0f 84 85 00 00 00    	je     f01015a0 <page_insert+0xb5>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f010151b:	8b 00                	mov    (%eax),%eax
f010151d:	a8 01                	test   $0x1,%al
f010151f:	74 5b                	je     f010157c <page_insert+0x91>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f0101521:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101526:	89 f2                	mov    %esi,%edx
f0101528:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f010152e:	c1 fa 03             	sar    $0x3,%edx
f0101531:	c1 e2 0c             	shl    $0xc,%edx
f0101534:	39 d0                	cmp    %edx,%eax
f0101536:	75 11                	jne    f0101549 <page_insert+0x5e>
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f0101538:	8b 55 14             	mov    0x14(%ebp),%edx
f010153b:	83 ca 01             	or     $0x1,%edx
f010153e:	09 d0                	or     %edx,%eax
f0101540:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101542:	b8 00 00 00 00       	mov    $0x0,%eax
f0101547:	eb 5c                	jmp    f01015a5 <page_insert+0xba>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f0101549:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010154d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101550:	89 04 24             	mov    %eax,(%esp)
f0101553:	e8 4a ff ff ff       	call   f01014a2 <page_remove>
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f0101558:	8b 55 14             	mov    0x14(%ebp),%edx
f010155b:	83 ca 01             	or     $0x1,%edx
f010155e:	89 f0                	mov    %esi,%eax
f0101560:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101566:	c1 f8 03             	sar    $0x3,%eax
f0101569:	c1 e0 0c             	shl    $0xc,%eax
f010156c:	09 d0                	or     %edx,%eax
f010156e:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101570:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		}
		return 0;
f0101575:	b8 00 00 00 00       	mov    $0x0,%eax
f010157a:	eb 29                	jmp    f01015a5 <page_insert+0xba>
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f010157c:	8b 55 14             	mov    0x14(%ebp),%edx
f010157f:	83 ca 01             	or     $0x1,%edx
f0101582:	89 f0                	mov    %esi,%eax
f0101584:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f010158a:	c1 f8 03             	sar    $0x3,%eax
f010158d:	c1 e0 0c             	shl    $0xc,%eax
f0101590:	09 d0                	or     %edx,%eax
f0101592:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f0101594:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f0101599:	b8 00 00 00 00       	mov    $0x0,%eax
f010159e:	eb 05                	jmp    f01015a5 <page_insert+0xba>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f01015a0:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f01015a5:	83 c4 1c             	add    $0x1c,%esp
f01015a8:	5b                   	pop    %ebx
f01015a9:	5e                   	pop    %esi
f01015aa:	5f                   	pop    %edi
f01015ab:	5d                   	pop    %ebp
f01015ac:	c3                   	ret    

f01015ad <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01015ad:	55                   	push   %ebp
f01015ae:	89 e5                	mov    %esp,%ebp
f01015b0:	56                   	push   %esi
f01015b1:	53                   	push   %ebx
f01015b2:	83 ec 10             	sub    $0x10,%esp
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f01015b5:	8b 1d 00 03 12 f0    	mov    0xf0120300,%ebx
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f01015bb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015be:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f01015c4:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f01015ca:	c7 44 24 04 1b 00 00 	movl   $0x1b,0x4(%esp)
f01015d1:	00 
f01015d2:	8b 45 08             	mov    0x8(%ebp),%eax
f01015d5:	89 04 24             	mov    %eax,(%esp)
f01015d8:	89 f1                	mov    %esi,%ecx
f01015da:	89 da                	mov    %ebx,%edx
f01015dc:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01015e1:	e8 9f fd ff ff       	call   f0101385 <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f01015e6:	01 35 00 03 12 f0    	add    %esi,0xf0120300
	
	return save; 
	
}
f01015ec:	89 d8                	mov    %ebx,%eax
f01015ee:	83 c4 10             	add    $0x10,%esp
f01015f1:	5b                   	pop    %ebx
f01015f2:	5e                   	pop    %esi
f01015f3:	5d                   	pop    %ebp
f01015f4:	c3                   	ret    

f01015f5 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01015f5:	55                   	push   %ebp
f01015f6:	89 e5                	mov    %esp,%ebp
f01015f8:	57                   	push   %edi
f01015f9:	56                   	push   %esi
f01015fa:	53                   	push   %ebx
f01015fb:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01015fe:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101605:	e8 b9 29 00 00       	call   f0103fc3 <mc146818_read>
f010160a:	89 c3                	mov    %eax,%ebx
f010160c:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f0101613:	e8 ab 29 00 00       	call   f0103fc3 <mc146818_read>
f0101618:	c1 e0 08             	shl    $0x8,%eax
f010161b:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f010161d:	89 d8                	mov    %ebx,%eax
f010161f:	c1 e0 0a             	shl    $0xa,%eax
f0101622:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101628:	85 c0                	test   %eax,%eax
f010162a:	0f 48 c2             	cmovs  %edx,%eax
f010162d:	c1 f8 0c             	sar    $0xc,%eax
f0101630:	a3 48 b2 22 f0       	mov    %eax,0xf022b248
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101635:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010163c:	e8 82 29 00 00       	call   f0103fc3 <mc146818_read>
f0101641:	89 c3                	mov    %eax,%ebx
f0101643:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010164a:	e8 74 29 00 00       	call   f0103fc3 <mc146818_read>
f010164f:	c1 e0 08             	shl    $0x8,%eax
f0101652:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101654:	89 d8                	mov    %ebx,%eax
f0101656:	c1 e0 0a             	shl    $0xa,%eax
f0101659:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010165f:	85 c0                	test   %eax,%eax
f0101661:	0f 48 c2             	cmovs  %edx,%eax
f0101664:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101667:	85 c0                	test   %eax,%eax
f0101669:	74 0e                	je     f0101679 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010166b:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101671:	89 15 88 be 22 f0    	mov    %edx,0xf022be88
f0101677:	eb 0c                	jmp    f0101685 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101679:	8b 15 48 b2 22 f0    	mov    0xf022b248,%edx
f010167f:	89 15 88 be 22 f0    	mov    %edx,0xf022be88

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101685:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101688:	c1 e8 0a             	shr    $0xa,%eax
f010168b:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010168f:	a1 48 b2 22 f0       	mov    0xf022b248,%eax
f0101694:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101697:	c1 e8 0a             	shr    $0xa,%eax
f010169a:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010169e:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f01016a3:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01016a6:	c1 e8 0a             	shr    $0xa,%eax
f01016a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016ad:	c7 04 24 3c 6c 10 f0 	movl   $0xf0106c3c,(%esp)
f01016b4:	e8 73 2a 00 00       	call   f010412c <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01016b9:	b8 00 10 00 00       	mov    $0x1000,%eax
f01016be:	e8 e1 f4 ff ff       	call   f0100ba4 <boot_alloc>
f01016c3:	a3 8c be 22 f0       	mov    %eax,0xf022be8c
	memset(kern_pgdir, 0, PGSIZE);
f01016c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016cf:	00 
f01016d0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016d7:	00 
f01016d8:	89 04 24             	mov    %eax,(%esp)
f01016db:	e8 b7 40 00 00       	call   f0105797 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01016e0:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01016e5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01016ea:	77 20                	ja     f010170c <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01016ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016f0:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f01016f7:	f0 
f01016f8:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f01016ff:	00 
f0101700:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101707:	e8 34 e9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010170c:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101712:	83 ca 05             	or     $0x5,%edx
f0101715:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f010171b:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0101720:	c1 e0 03             	shl    $0x3,%eax
f0101723:	e8 7c f4 ff ff       	call   f0100ba4 <boot_alloc>
f0101728:	a3 90 be 22 f0       	mov    %eax,0xf022be90
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f010172d:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f0101733:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010173a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010173e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101745:	00 
f0101746:	89 04 24             	mov    %eax,(%esp)
f0101749:	e8 49 40 00 00       	call   f0105797 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f010174e:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101753:	e8 4c f4 ff ff       	call   f0100ba4 <boot_alloc>
f0101758:	a3 4c b2 22 f0       	mov    %eax,0xf022b24c
	memset(envs,0,sizeof(struct Env)*NENV);
f010175d:	c7 44 24 08 00 f0 01 	movl   $0x1f000,0x8(%esp)
f0101764:	00 
f0101765:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010176c:	00 
f010176d:	89 04 24             	mov    %eax,(%esp)
f0101770:	e8 22 40 00 00       	call   f0105797 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101775:	e8 5b f8 ff ff       	call   f0100fd5 <page_init>

	check_page_free_list(1);
f010177a:	b8 01 00 00 00       	mov    $0x1,%eax
f010177f:	e8 a5 f4 ff ff       	call   f0100c29 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101784:	83 3d 90 be 22 f0 00 	cmpl   $0x0,0xf022be90
f010178b:	75 1c                	jne    f01017a9 <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f010178d:	c7 44 24 08 55 75 10 	movl   $0xf0107555,0x8(%esp)
f0101794:	f0 
f0101795:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f010179c:	00 
f010179d:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01017a4:	e8 97 e8 ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01017a9:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f01017ae:	bb 00 00 00 00       	mov    $0x0,%ebx
f01017b3:	eb 05                	jmp    f01017ba <mem_init+0x1c5>
		++nfree;
f01017b5:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01017b8:	8b 00                	mov    (%eax),%eax
f01017ba:	85 c0                	test   %eax,%eax
f01017bc:	75 f7                	jne    f01017b5 <mem_init+0x1c0>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c5:	e8 9d f9 ff ff       	call   f0101167 <page_alloc>
f01017ca:	89 c7                	mov    %eax,%edi
f01017cc:	85 c0                	test   %eax,%eax
f01017ce:	75 24                	jne    f01017f4 <mem_init+0x1ff>
f01017d0:	c7 44 24 0c 70 75 10 	movl   $0xf0107570,0xc(%esp)
f01017d7:	f0 
f01017d8:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01017df:	f0 
f01017e0:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f01017e7:	00 
f01017e8:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01017ef:	e8 4c e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017fb:	e8 67 f9 ff ff       	call   f0101167 <page_alloc>
f0101800:	89 c6                	mov    %eax,%esi
f0101802:	85 c0                	test   %eax,%eax
f0101804:	75 24                	jne    f010182a <mem_init+0x235>
f0101806:	c7 44 24 0c 86 75 10 	movl   $0xf0107586,0xc(%esp)
f010180d:	f0 
f010180e:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101815:	f0 
f0101816:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f010181d:	00 
f010181e:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101825:	e8 16 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010182a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101831:	e8 31 f9 ff ff       	call   f0101167 <page_alloc>
f0101836:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101839:	85 c0                	test   %eax,%eax
f010183b:	75 24                	jne    f0101861 <mem_init+0x26c>
f010183d:	c7 44 24 0c 9c 75 10 	movl   $0xf010759c,0xc(%esp)
f0101844:	f0 
f0101845:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010184c:	f0 
f010184d:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0101854:	00 
f0101855:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010185c:	e8 df e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101861:	39 f7                	cmp    %esi,%edi
f0101863:	75 24                	jne    f0101889 <mem_init+0x294>
f0101865:	c7 44 24 0c b2 75 10 	movl   $0xf01075b2,0xc(%esp)
f010186c:	f0 
f010186d:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101874:	f0 
f0101875:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f010187c:	00 
f010187d:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101884:	e8 b7 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101889:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010188c:	39 c6                	cmp    %eax,%esi
f010188e:	74 04                	je     f0101894 <mem_init+0x29f>
f0101890:	39 c7                	cmp    %eax,%edi
f0101892:	75 24                	jne    f01018b8 <mem_init+0x2c3>
f0101894:	c7 44 24 0c 78 6c 10 	movl   $0xf0106c78,0xc(%esp)
f010189b:	f0 
f010189c:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01018a3:	f0 
f01018a4:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f01018ab:	00 
f01018ac:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01018b3:	e8 88 e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018b8:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01018be:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f01018c3:	c1 e0 0c             	shl    $0xc,%eax
f01018c6:	89 f9                	mov    %edi,%ecx
f01018c8:	29 d1                	sub    %edx,%ecx
f01018ca:	c1 f9 03             	sar    $0x3,%ecx
f01018cd:	c1 e1 0c             	shl    $0xc,%ecx
f01018d0:	39 c1                	cmp    %eax,%ecx
f01018d2:	72 24                	jb     f01018f8 <mem_init+0x303>
f01018d4:	c7 44 24 0c c4 75 10 	movl   $0xf01075c4,0xc(%esp)
f01018db:	f0 
f01018dc:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01018e3:	f0 
f01018e4:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01018eb:	00 
f01018ec:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01018f3:	e8 48 e7 ff ff       	call   f0100040 <_panic>
f01018f8:	89 f1                	mov    %esi,%ecx
f01018fa:	29 d1                	sub    %edx,%ecx
f01018fc:	c1 f9 03             	sar    $0x3,%ecx
f01018ff:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101902:	39 c8                	cmp    %ecx,%eax
f0101904:	77 24                	ja     f010192a <mem_init+0x335>
f0101906:	c7 44 24 0c e1 75 10 	movl   $0xf01075e1,0xc(%esp)
f010190d:	f0 
f010190e:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101915:	f0 
f0101916:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f010191d:	00 
f010191e:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101925:	e8 16 e7 ff ff       	call   f0100040 <_panic>
f010192a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010192d:	29 d1                	sub    %edx,%ecx
f010192f:	89 ca                	mov    %ecx,%edx
f0101931:	c1 fa 03             	sar    $0x3,%edx
f0101934:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101937:	39 d0                	cmp    %edx,%eax
f0101939:	77 24                	ja     f010195f <mem_init+0x36a>
f010193b:	c7 44 24 0c fe 75 10 	movl   $0xf01075fe,0xc(%esp)
f0101942:	f0 
f0101943:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010194a:	f0 
f010194b:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0101952:	00 
f0101953:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010195a:	e8 e1 e6 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010195f:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0101964:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101967:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f010196e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101971:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101978:	e8 ea f7 ff ff       	call   f0101167 <page_alloc>
f010197d:	85 c0                	test   %eax,%eax
f010197f:	74 24                	je     f01019a5 <mem_init+0x3b0>
f0101981:	c7 44 24 0c 1b 76 10 	movl   $0xf010761b,0xc(%esp)
f0101988:	f0 
f0101989:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101990:	f0 
f0101991:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0101998:	00 
f0101999:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01019a0:	e8 9b e6 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01019a5:	89 3c 24             	mov    %edi,(%esp)
f01019a8:	e8 4b f8 ff ff       	call   f01011f8 <page_free>
	page_free(pp1);
f01019ad:	89 34 24             	mov    %esi,(%esp)
f01019b0:	e8 43 f8 ff ff       	call   f01011f8 <page_free>
	page_free(pp2);
f01019b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019b8:	89 04 24             	mov    %eax,(%esp)
f01019bb:	e8 38 f8 ff ff       	call   f01011f8 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019c0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019c7:	e8 9b f7 ff ff       	call   f0101167 <page_alloc>
f01019cc:	89 c6                	mov    %eax,%esi
f01019ce:	85 c0                	test   %eax,%eax
f01019d0:	75 24                	jne    f01019f6 <mem_init+0x401>
f01019d2:	c7 44 24 0c 70 75 10 	movl   $0xf0107570,0xc(%esp)
f01019d9:	f0 
f01019da:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01019e1:	f0 
f01019e2:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f01019e9:	00 
f01019ea:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01019f1:	e8 4a e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01019f6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019fd:	e8 65 f7 ff ff       	call   f0101167 <page_alloc>
f0101a02:	89 c7                	mov    %eax,%edi
f0101a04:	85 c0                	test   %eax,%eax
f0101a06:	75 24                	jne    f0101a2c <mem_init+0x437>
f0101a08:	c7 44 24 0c 86 75 10 	movl   $0xf0107586,0xc(%esp)
f0101a0f:	f0 
f0101a10:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101a17:	f0 
f0101a18:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f0101a1f:	00 
f0101a20:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101a27:	e8 14 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a2c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a33:	e8 2f f7 ff ff       	call   f0101167 <page_alloc>
f0101a38:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a3b:	85 c0                	test   %eax,%eax
f0101a3d:	75 24                	jne    f0101a63 <mem_init+0x46e>
f0101a3f:	c7 44 24 0c 9c 75 10 	movl   $0xf010759c,0xc(%esp)
f0101a46:	f0 
f0101a47:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101a4e:	f0 
f0101a4f:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0101a56:	00 
f0101a57:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101a5e:	e8 dd e5 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a63:	39 fe                	cmp    %edi,%esi
f0101a65:	75 24                	jne    f0101a8b <mem_init+0x496>
f0101a67:	c7 44 24 0c b2 75 10 	movl   $0xf01075b2,0xc(%esp)
f0101a6e:	f0 
f0101a6f:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101a76:	f0 
f0101a77:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0101a7e:	00 
f0101a7f:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101a86:	e8 b5 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a8b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a8e:	39 c7                	cmp    %eax,%edi
f0101a90:	74 04                	je     f0101a96 <mem_init+0x4a1>
f0101a92:	39 c6                	cmp    %eax,%esi
f0101a94:	75 24                	jne    f0101aba <mem_init+0x4c5>
f0101a96:	c7 44 24 0c 78 6c 10 	movl   $0xf0106c78,0xc(%esp)
f0101a9d:	f0 
f0101a9e:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101aa5:	f0 
f0101aa6:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0101aad:	00 
f0101aae:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101ab5:	e8 86 e5 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101aba:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ac1:	e8 a1 f6 ff ff       	call   f0101167 <page_alloc>
f0101ac6:	85 c0                	test   %eax,%eax
f0101ac8:	74 24                	je     f0101aee <mem_init+0x4f9>
f0101aca:	c7 44 24 0c 1b 76 10 	movl   $0xf010761b,0xc(%esp)
f0101ad1:	f0 
f0101ad2:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101ad9:	f0 
f0101ada:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0101ae1:	00 
f0101ae2:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101ae9:	e8 52 e5 ff ff       	call   f0100040 <_panic>
f0101aee:	89 f0                	mov    %esi,%eax
f0101af0:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101af6:	c1 f8 03             	sar    $0x3,%eax
f0101af9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101afc:	89 c2                	mov    %eax,%edx
f0101afe:	c1 ea 0c             	shr    $0xc,%edx
f0101b01:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0101b07:	72 20                	jb     f0101b29 <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101b09:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101b0d:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0101b14:	f0 
f0101b15:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101b1c:	00 
f0101b1d:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0101b24:	e8 17 e5 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101b29:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b30:	00 
f0101b31:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101b38:	00 
	return (void *)(pa + KERNBASE);
f0101b39:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b3e:	89 04 24             	mov    %eax,(%esp)
f0101b41:	e8 51 3c 00 00       	call   f0105797 <memset>
	page_free(pp0);
f0101b46:	89 34 24             	mov    %esi,(%esp)
f0101b49:	e8 aa f6 ff ff       	call   f01011f8 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101b4e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101b55:	e8 0d f6 ff ff       	call   f0101167 <page_alloc>
f0101b5a:	85 c0                	test   %eax,%eax
f0101b5c:	75 24                	jne    f0101b82 <mem_init+0x58d>
f0101b5e:	c7 44 24 0c 2a 76 10 	movl   $0xf010762a,0xc(%esp)
f0101b65:	f0 
f0101b66:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101b6d:	f0 
f0101b6e:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f0101b75:	00 
f0101b76:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101b7d:	e8 be e4 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101b82:	39 c6                	cmp    %eax,%esi
f0101b84:	74 24                	je     f0101baa <mem_init+0x5b5>
f0101b86:	c7 44 24 0c 48 76 10 	movl   $0xf0107648,0xc(%esp)
f0101b8d:	f0 
f0101b8e:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101b95:	f0 
f0101b96:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0101b9d:	00 
f0101b9e:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101ba5:	e8 96 e4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101baa:	89 f0                	mov    %esi,%eax
f0101bac:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0101bb2:	c1 f8 03             	sar    $0x3,%eax
f0101bb5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101bb8:	89 c2                	mov    %eax,%edx
f0101bba:	c1 ea 0c             	shr    $0xc,%edx
f0101bbd:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0101bc3:	72 20                	jb     f0101be5 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101bc5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101bc9:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0101bd0:	f0 
f0101bd1:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101bd8:	00 
f0101bd9:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0101be0:	e8 5b e4 ff ff       	call   f0100040 <_panic>
f0101be5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101beb:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101bf1:	80 38 00             	cmpb   $0x0,(%eax)
f0101bf4:	74 24                	je     f0101c1a <mem_init+0x625>
f0101bf6:	c7 44 24 0c 58 76 10 	movl   $0xf0107658,0xc(%esp)
f0101bfd:	f0 
f0101bfe:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101c05:	f0 
f0101c06:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0101c0d:	00 
f0101c0e:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101c15:	e8 26 e4 ff ff       	call   f0100040 <_panic>
f0101c1a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101c1d:	39 d0                	cmp    %edx,%eax
f0101c1f:	75 d0                	jne    f0101bf1 <mem_init+0x5fc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101c21:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c24:	a3 44 b2 22 f0       	mov    %eax,0xf022b244

	// free the pages we took
	page_free(pp0);
f0101c29:	89 34 24             	mov    %esi,(%esp)
f0101c2c:	e8 c7 f5 ff ff       	call   f01011f8 <page_free>
	page_free(pp1);
f0101c31:	89 3c 24             	mov    %edi,(%esp)
f0101c34:	e8 bf f5 ff ff       	call   f01011f8 <page_free>
	page_free(pp2);
f0101c39:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c3c:	89 04 24             	mov    %eax,(%esp)
f0101c3f:	e8 b4 f5 ff ff       	call   f01011f8 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c44:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0101c49:	eb 05                	jmp    f0101c50 <mem_init+0x65b>
		--nfree;
f0101c4b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c4e:	8b 00                	mov    (%eax),%eax
f0101c50:	85 c0                	test   %eax,%eax
f0101c52:	75 f7                	jne    f0101c4b <mem_init+0x656>
		--nfree;
	assert(nfree == 0);
f0101c54:	85 db                	test   %ebx,%ebx
f0101c56:	74 24                	je     f0101c7c <mem_init+0x687>
f0101c58:	c7 44 24 0c 62 76 10 	movl   $0xf0107662,0xc(%esp)
f0101c5f:	f0 
f0101c60:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101c67:	f0 
f0101c68:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0101c6f:	00 
f0101c70:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101c77:	e8 c4 e3 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101c7c:	c7 04 24 98 6c 10 f0 	movl   $0xf0106c98,(%esp)
f0101c83:	e8 a4 24 00 00       	call   f010412c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c88:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c8f:	e8 d3 f4 ff ff       	call   f0101167 <page_alloc>
f0101c94:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c97:	85 c0                	test   %eax,%eax
f0101c99:	75 24                	jne    f0101cbf <mem_init+0x6ca>
f0101c9b:	c7 44 24 0c 70 75 10 	movl   $0xf0107570,0xc(%esp)
f0101ca2:	f0 
f0101ca3:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101caa:	f0 
f0101cab:	c7 44 24 04 25 04 00 	movl   $0x425,0x4(%esp)
f0101cb2:	00 
f0101cb3:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101cba:	e8 81 e3 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101cbf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cc6:	e8 9c f4 ff ff       	call   f0101167 <page_alloc>
f0101ccb:	89 c3                	mov    %eax,%ebx
f0101ccd:	85 c0                	test   %eax,%eax
f0101ccf:	75 24                	jne    f0101cf5 <mem_init+0x700>
f0101cd1:	c7 44 24 0c 86 75 10 	movl   $0xf0107586,0xc(%esp)
f0101cd8:	f0 
f0101cd9:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101ce0:	f0 
f0101ce1:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f0101ce8:	00 
f0101ce9:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101cf0:	e8 4b e3 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101cf5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cfc:	e8 66 f4 ff ff       	call   f0101167 <page_alloc>
f0101d01:	89 c6                	mov    %eax,%esi
f0101d03:	85 c0                	test   %eax,%eax
f0101d05:	75 24                	jne    f0101d2b <mem_init+0x736>
f0101d07:	c7 44 24 0c 9c 75 10 	movl   $0xf010759c,0xc(%esp)
f0101d0e:	f0 
f0101d0f:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101d16:	f0 
f0101d17:	c7 44 24 04 27 04 00 	movl   $0x427,0x4(%esp)
f0101d1e:	00 
f0101d1f:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101d26:	e8 15 e3 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101d2b:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101d2e:	75 24                	jne    f0101d54 <mem_init+0x75f>
f0101d30:	c7 44 24 0c b2 75 10 	movl   $0xf01075b2,0xc(%esp)
f0101d37:	f0 
f0101d38:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101d3f:	f0 
f0101d40:	c7 44 24 04 2a 04 00 	movl   $0x42a,0x4(%esp)
f0101d47:	00 
f0101d48:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101d4f:	e8 ec e2 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101d54:	39 c3                	cmp    %eax,%ebx
f0101d56:	74 05                	je     f0101d5d <mem_init+0x768>
f0101d58:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d5b:	75 24                	jne    f0101d81 <mem_init+0x78c>
f0101d5d:	c7 44 24 0c 78 6c 10 	movl   $0xf0106c78,0xc(%esp)
f0101d64:	f0 
f0101d65:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101d6c:	f0 
f0101d6d:	c7 44 24 04 2b 04 00 	movl   $0x42b,0x4(%esp)
f0101d74:	00 
f0101d75:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101d7c:	e8 bf e2 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101d81:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0101d86:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101d89:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f0101d90:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101d93:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d9a:	e8 c8 f3 ff ff       	call   f0101167 <page_alloc>
f0101d9f:	85 c0                	test   %eax,%eax
f0101da1:	74 24                	je     f0101dc7 <mem_init+0x7d2>
f0101da3:	c7 44 24 0c 1b 76 10 	movl   $0xf010761b,0xc(%esp)
f0101daa:	f0 
f0101dab:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101db2:	f0 
f0101db3:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f0101dba:	00 
f0101dbb:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101dc2:	e8 79 e2 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101dc7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101dca:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101dce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101dd5:	00 
f0101dd6:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101ddb:	89 04 24             	mov    %eax,(%esp)
f0101dde:	e8 34 f6 ff ff       	call   f0101417 <page_lookup>
f0101de3:	85 c0                	test   %eax,%eax
f0101de5:	74 24                	je     f0101e0b <mem_init+0x816>
f0101de7:	c7 44 24 0c b8 6c 10 	movl   $0xf0106cb8,0xc(%esp)
f0101dee:	f0 
f0101def:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101df6:	f0 
f0101df7:	c7 44 24 04 37 04 00 	movl   $0x437,0x4(%esp)
f0101dfe:	00 
f0101dff:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101e06:	e8 35 e2 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101e0b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e12:	00 
f0101e13:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e1a:	00 
f0101e1b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e1f:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101e24:	89 04 24             	mov    %eax,(%esp)
f0101e27:	e8 bf f6 ff ff       	call   f01014eb <page_insert>
f0101e2c:	85 c0                	test   %eax,%eax
f0101e2e:	78 24                	js     f0101e54 <mem_init+0x85f>
f0101e30:	c7 44 24 0c f0 6c 10 	movl   $0xf0106cf0,0xc(%esp)
f0101e37:	f0 
f0101e38:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101e3f:	f0 
f0101e40:	c7 44 24 04 3a 04 00 	movl   $0x43a,0x4(%esp)
f0101e47:	00 
f0101e48:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101e4f:	e8 ec e1 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101e54:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e57:	89 04 24             	mov    %eax,(%esp)
f0101e5a:	e8 99 f3 ff ff       	call   f01011f8 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101e5f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e66:	00 
f0101e67:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e6e:	00 
f0101e6f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e73:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101e78:	89 04 24             	mov    %eax,(%esp)
f0101e7b:	e8 6b f6 ff ff       	call   f01014eb <page_insert>
f0101e80:	85 c0                	test   %eax,%eax
f0101e82:	74 24                	je     f0101ea8 <mem_init+0x8b3>
f0101e84:	c7 44 24 0c 20 6d 10 	movl   $0xf0106d20,0xc(%esp)
f0101e8b:	f0 
f0101e8c:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101e93:	f0 
f0101e94:	c7 44 24 04 3e 04 00 	movl   $0x43e,0x4(%esp)
f0101e9b:	00 
f0101e9c:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101ea3:	e8 98 e1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101ea8:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101eae:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0101eb3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101eb6:	8b 17                	mov    (%edi),%edx
f0101eb8:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ebe:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ec1:	29 c1                	sub    %eax,%ecx
f0101ec3:	89 c8                	mov    %ecx,%eax
f0101ec5:	c1 f8 03             	sar    $0x3,%eax
f0101ec8:	c1 e0 0c             	shl    $0xc,%eax
f0101ecb:	39 c2                	cmp    %eax,%edx
f0101ecd:	74 24                	je     f0101ef3 <mem_init+0x8fe>
f0101ecf:	c7 44 24 0c 50 6d 10 	movl   $0xf0106d50,0xc(%esp)
f0101ed6:	f0 
f0101ed7:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101ede:	f0 
f0101edf:	c7 44 24 04 3f 04 00 	movl   $0x43f,0x4(%esp)
f0101ee6:	00 
f0101ee7:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101eee:	e8 4d e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ef3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ef8:	89 f8                	mov    %edi,%eax
f0101efa:	e8 36 ec ff ff       	call   f0100b35 <check_va2pa>
f0101eff:	89 da                	mov    %ebx,%edx
f0101f01:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101f04:	c1 fa 03             	sar    $0x3,%edx
f0101f07:	c1 e2 0c             	shl    $0xc,%edx
f0101f0a:	39 d0                	cmp    %edx,%eax
f0101f0c:	74 24                	je     f0101f32 <mem_init+0x93d>
f0101f0e:	c7 44 24 0c 78 6d 10 	movl   $0xf0106d78,0xc(%esp)
f0101f15:	f0 
f0101f16:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101f1d:	f0 
f0101f1e:	c7 44 24 04 40 04 00 	movl   $0x440,0x4(%esp)
f0101f25:	00 
f0101f26:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101f2d:	e8 0e e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f32:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f37:	74 24                	je     f0101f5d <mem_init+0x968>
f0101f39:	c7 44 24 0c 6d 76 10 	movl   $0xf010766d,0xc(%esp)
f0101f40:	f0 
f0101f41:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101f48:	f0 
f0101f49:	c7 44 24 04 41 04 00 	movl   $0x441,0x4(%esp)
f0101f50:	00 
f0101f51:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101f58:	e8 e3 e0 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101f5d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f60:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f65:	74 24                	je     f0101f8b <mem_init+0x996>
f0101f67:	c7 44 24 0c 7e 76 10 	movl   $0xf010767e,0xc(%esp)
f0101f6e:	f0 
f0101f6f:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101f76:	f0 
f0101f77:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f0101f7e:	00 
f0101f7f:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101f86:	e8 b5 e0 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f8b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f92:	00 
f0101f93:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f9a:	00 
f0101f9b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f9f:	89 3c 24             	mov    %edi,(%esp)
f0101fa2:	e8 44 f5 ff ff       	call   f01014eb <page_insert>
f0101fa7:	85 c0                	test   %eax,%eax
f0101fa9:	74 24                	je     f0101fcf <mem_init+0x9da>
f0101fab:	c7 44 24 0c a8 6d 10 	movl   $0xf0106da8,0xc(%esp)
f0101fb2:	f0 
f0101fb3:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101fba:	f0 
f0101fbb:	c7 44 24 04 45 04 00 	movl   $0x445,0x4(%esp)
f0101fc2:	00 
f0101fc3:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0101fca:	e8 71 e0 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101fcf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fd4:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0101fd9:	e8 57 eb ff ff       	call   f0100b35 <check_va2pa>
f0101fde:	89 f2                	mov    %esi,%edx
f0101fe0:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0101fe6:	c1 fa 03             	sar    $0x3,%edx
f0101fe9:	c1 e2 0c             	shl    $0xc,%edx
f0101fec:	39 d0                	cmp    %edx,%eax
f0101fee:	74 24                	je     f0102014 <mem_init+0xa1f>
f0101ff0:	c7 44 24 0c e4 6d 10 	movl   $0xf0106de4,0xc(%esp)
f0101ff7:	f0 
f0101ff8:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0101fff:	f0 
f0102000:	c7 44 24 04 47 04 00 	movl   $0x447,0x4(%esp)
f0102007:	00 
f0102008:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010200f:	e8 2c e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102014:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102019:	74 24                	je     f010203f <mem_init+0xa4a>
f010201b:	c7 44 24 0c 8f 76 10 	movl   $0xf010768f,0xc(%esp)
f0102022:	f0 
f0102023:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010202a:	f0 
f010202b:	c7 44 24 04 48 04 00 	movl   $0x448,0x4(%esp)
f0102032:	00 
f0102033:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010203a:	e8 01 e0 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f010203f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102046:	e8 1c f1 ff ff       	call   f0101167 <page_alloc>
f010204b:	85 c0                	test   %eax,%eax
f010204d:	74 24                	je     f0102073 <mem_init+0xa7e>
f010204f:	c7 44 24 0c 1b 76 10 	movl   $0xf010761b,0xc(%esp)
f0102056:	f0 
f0102057:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010205e:	f0 
f010205f:	c7 44 24 04 4b 04 00 	movl   $0x44b,0x4(%esp)
f0102066:	00 
f0102067:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010206e:	e8 cd df ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102073:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010207a:	00 
f010207b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102082:	00 
f0102083:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102087:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010208c:	89 04 24             	mov    %eax,(%esp)
f010208f:	e8 57 f4 ff ff       	call   f01014eb <page_insert>
f0102094:	85 c0                	test   %eax,%eax
f0102096:	74 24                	je     f01020bc <mem_init+0xac7>
f0102098:	c7 44 24 0c a8 6d 10 	movl   $0xf0106da8,0xc(%esp)
f010209f:	f0 
f01020a0:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01020a7:	f0 
f01020a8:	c7 44 24 04 4e 04 00 	movl   $0x44e,0x4(%esp)
f01020af:	00 
f01020b0:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01020b7:	e8 84 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01020bc:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020c1:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01020c6:	e8 6a ea ff ff       	call   f0100b35 <check_va2pa>
f01020cb:	89 f2                	mov    %esi,%edx
f01020cd:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f01020d3:	c1 fa 03             	sar    $0x3,%edx
f01020d6:	c1 e2 0c             	shl    $0xc,%edx
f01020d9:	39 d0                	cmp    %edx,%eax
f01020db:	74 24                	je     f0102101 <mem_init+0xb0c>
f01020dd:	c7 44 24 0c e4 6d 10 	movl   $0xf0106de4,0xc(%esp)
f01020e4:	f0 
f01020e5:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01020ec:	f0 
f01020ed:	c7 44 24 04 4f 04 00 	movl   $0x44f,0x4(%esp)
f01020f4:	00 
f01020f5:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01020fc:	e8 3f df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102101:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102106:	74 24                	je     f010212c <mem_init+0xb37>
f0102108:	c7 44 24 0c 8f 76 10 	movl   $0xf010768f,0xc(%esp)
f010210f:	f0 
f0102110:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102117:	f0 
f0102118:	c7 44 24 04 50 04 00 	movl   $0x450,0x4(%esp)
f010211f:	00 
f0102120:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102127:	e8 14 df ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010212c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102133:	e8 2f f0 ff ff       	call   f0101167 <page_alloc>
f0102138:	85 c0                	test   %eax,%eax
f010213a:	74 24                	je     f0102160 <mem_init+0xb6b>
f010213c:	c7 44 24 0c 1b 76 10 	movl   $0xf010761b,0xc(%esp)
f0102143:	f0 
f0102144:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010214b:	f0 
f010214c:	c7 44 24 04 54 04 00 	movl   $0x454,0x4(%esp)
f0102153:	00 
f0102154:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010215b:	e8 e0 de ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0102160:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f0102166:	8b 02                	mov    (%edx),%eax
f0102168:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010216d:	89 c1                	mov    %eax,%ecx
f010216f:	c1 e9 0c             	shr    $0xc,%ecx
f0102172:	3b 0d 88 be 22 f0    	cmp    0xf022be88,%ecx
f0102178:	72 20                	jb     f010219a <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010217a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010217e:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0102185:	f0 
f0102186:	c7 44 24 04 57 04 00 	movl   $0x457,0x4(%esp)
f010218d:	00 
f010218e:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102195:	e8 a6 de ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010219a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010219f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01021a2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021a9:	00 
f01021aa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021b1:	00 
f01021b2:	89 14 24             	mov    %edx,(%esp)
f01021b5:	e8 bc f0 ff ff       	call   f0101276 <pgdir_walk>
f01021ba:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01021bd:	8d 51 04             	lea    0x4(%ecx),%edx
f01021c0:	39 d0                	cmp    %edx,%eax
f01021c2:	74 24                	je     f01021e8 <mem_init+0xbf3>
f01021c4:	c7 44 24 0c 14 6e 10 	movl   $0xf0106e14,0xc(%esp)
f01021cb:	f0 
f01021cc:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01021d3:	f0 
f01021d4:	c7 44 24 04 58 04 00 	movl   $0x458,0x4(%esp)
f01021db:	00 
f01021dc:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01021e3:	e8 58 de ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01021e8:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01021ef:	00 
f01021f0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021f7:	00 
f01021f8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021fc:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102201:	89 04 24             	mov    %eax,(%esp)
f0102204:	e8 e2 f2 ff ff       	call   f01014eb <page_insert>
f0102209:	85 c0                	test   %eax,%eax
f010220b:	74 24                	je     f0102231 <mem_init+0xc3c>
f010220d:	c7 44 24 0c 54 6e 10 	movl   $0xf0106e54,0xc(%esp)
f0102214:	f0 
f0102215:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010221c:	f0 
f010221d:	c7 44 24 04 5b 04 00 	movl   $0x45b,0x4(%esp)
f0102224:	00 
f0102225:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010222c:	e8 0f de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102231:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102237:	ba 00 10 00 00       	mov    $0x1000,%edx
f010223c:	89 f8                	mov    %edi,%eax
f010223e:	e8 f2 e8 ff ff       	call   f0100b35 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102243:	89 f2                	mov    %esi,%edx
f0102245:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f010224b:	c1 fa 03             	sar    $0x3,%edx
f010224e:	c1 e2 0c             	shl    $0xc,%edx
f0102251:	39 d0                	cmp    %edx,%eax
f0102253:	74 24                	je     f0102279 <mem_init+0xc84>
f0102255:	c7 44 24 0c e4 6d 10 	movl   $0xf0106de4,0xc(%esp)
f010225c:	f0 
f010225d:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102264:	f0 
f0102265:	c7 44 24 04 5c 04 00 	movl   $0x45c,0x4(%esp)
f010226c:	00 
f010226d:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102274:	e8 c7 dd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102279:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010227e:	74 24                	je     f01022a4 <mem_init+0xcaf>
f0102280:	c7 44 24 0c 8f 76 10 	movl   $0xf010768f,0xc(%esp)
f0102287:	f0 
f0102288:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010228f:	f0 
f0102290:	c7 44 24 04 5d 04 00 	movl   $0x45d,0x4(%esp)
f0102297:	00 
f0102298:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010229f:	e8 9c dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01022a4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01022ab:	00 
f01022ac:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01022b3:	00 
f01022b4:	89 3c 24             	mov    %edi,(%esp)
f01022b7:	e8 ba ef ff ff       	call   f0101276 <pgdir_walk>
f01022bc:	f6 00 04             	testb  $0x4,(%eax)
f01022bf:	75 24                	jne    f01022e5 <mem_init+0xcf0>
f01022c1:	c7 44 24 0c 94 6e 10 	movl   $0xf0106e94,0xc(%esp)
f01022c8:	f0 
f01022c9:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01022d0:	f0 
f01022d1:	c7 44 24 04 5e 04 00 	movl   $0x45e,0x4(%esp)
f01022d8:	00 
f01022d9:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01022e0:	e8 5b dd ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01022e5:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01022ea:	f6 00 04             	testb  $0x4,(%eax)
f01022ed:	75 24                	jne    f0102313 <mem_init+0xd1e>
f01022ef:	c7 44 24 0c a0 76 10 	movl   $0xf01076a0,0xc(%esp)
f01022f6:	f0 
f01022f7:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01022fe:	f0 
f01022ff:	c7 44 24 04 5f 04 00 	movl   $0x45f,0x4(%esp)
f0102306:	00 
f0102307:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010230e:	e8 2d dd ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102313:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010231a:	00 
f010231b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102322:	00 
f0102323:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102327:	89 04 24             	mov    %eax,(%esp)
f010232a:	e8 bc f1 ff ff       	call   f01014eb <page_insert>
f010232f:	85 c0                	test   %eax,%eax
f0102331:	74 24                	je     f0102357 <mem_init+0xd62>
f0102333:	c7 44 24 0c a8 6d 10 	movl   $0xf0106da8,0xc(%esp)
f010233a:	f0 
f010233b:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102342:	f0 
f0102343:	c7 44 24 04 62 04 00 	movl   $0x462,0x4(%esp)
f010234a:	00 
f010234b:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102352:	e8 e9 dc ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102357:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010235e:	00 
f010235f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102366:	00 
f0102367:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010236c:	89 04 24             	mov    %eax,(%esp)
f010236f:	e8 02 ef ff ff       	call   f0101276 <pgdir_walk>
f0102374:	f6 00 02             	testb  $0x2,(%eax)
f0102377:	75 24                	jne    f010239d <mem_init+0xda8>
f0102379:	c7 44 24 0c c8 6e 10 	movl   $0xf0106ec8,0xc(%esp)
f0102380:	f0 
f0102381:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102388:	f0 
f0102389:	c7 44 24 04 63 04 00 	movl   $0x463,0x4(%esp)
f0102390:	00 
f0102391:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102398:	e8 a3 dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010239d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01023a4:	00 
f01023a5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01023ac:	00 
f01023ad:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01023b2:	89 04 24             	mov    %eax,(%esp)
f01023b5:	e8 bc ee ff ff       	call   f0101276 <pgdir_walk>
f01023ba:	f6 00 04             	testb  $0x4,(%eax)
f01023bd:	74 24                	je     f01023e3 <mem_init+0xdee>
f01023bf:	c7 44 24 0c fc 6e 10 	movl   $0xf0106efc,0xc(%esp)
f01023c6:	f0 
f01023c7:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01023ce:	f0 
f01023cf:	c7 44 24 04 64 04 00 	movl   $0x464,0x4(%esp)
f01023d6:	00 
f01023d7:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01023de:	e8 5d dc ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01023e3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01023ea:	00 
f01023eb:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01023f2:	00 
f01023f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023f6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01023fa:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01023ff:	89 04 24             	mov    %eax,(%esp)
f0102402:	e8 e4 f0 ff ff       	call   f01014eb <page_insert>
f0102407:	85 c0                	test   %eax,%eax
f0102409:	78 24                	js     f010242f <mem_init+0xe3a>
f010240b:	c7 44 24 0c 34 6f 10 	movl   $0xf0106f34,0xc(%esp)
f0102412:	f0 
f0102413:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010241a:	f0 
f010241b:	c7 44 24 04 67 04 00 	movl   $0x467,0x4(%esp)
f0102422:	00 
f0102423:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010242a:	e8 11 dc ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010242f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102436:	00 
f0102437:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010243e:	00 
f010243f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102443:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102448:	89 04 24             	mov    %eax,(%esp)
f010244b:	e8 9b f0 ff ff       	call   f01014eb <page_insert>
f0102450:	85 c0                	test   %eax,%eax
f0102452:	74 24                	je     f0102478 <mem_init+0xe83>
f0102454:	c7 44 24 0c 6c 6f 10 	movl   $0xf0106f6c,0xc(%esp)
f010245b:	f0 
f010245c:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102463:	f0 
f0102464:	c7 44 24 04 6a 04 00 	movl   $0x46a,0x4(%esp)
f010246b:	00 
f010246c:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102473:	e8 c8 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102478:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010247f:	00 
f0102480:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102487:	00 
f0102488:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010248d:	89 04 24             	mov    %eax,(%esp)
f0102490:	e8 e1 ed ff ff       	call   f0101276 <pgdir_walk>
f0102495:	f6 00 04             	testb  $0x4,(%eax)
f0102498:	74 24                	je     f01024be <mem_init+0xec9>
f010249a:	c7 44 24 0c fc 6e 10 	movl   $0xf0106efc,0xc(%esp)
f01024a1:	f0 
f01024a2:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01024a9:	f0 
f01024aa:	c7 44 24 04 6b 04 00 	movl   $0x46b,0x4(%esp)
f01024b1:	00 
f01024b2:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01024b9:	e8 82 db ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01024be:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f01024c4:	ba 00 00 00 00       	mov    $0x0,%edx
f01024c9:	89 f8                	mov    %edi,%eax
f01024cb:	e8 65 e6 ff ff       	call   f0100b35 <check_va2pa>
f01024d0:	89 c1                	mov    %eax,%ecx
f01024d2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01024d5:	89 d8                	mov    %ebx,%eax
f01024d7:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f01024dd:	c1 f8 03             	sar    $0x3,%eax
f01024e0:	c1 e0 0c             	shl    $0xc,%eax
f01024e3:	39 c1                	cmp    %eax,%ecx
f01024e5:	74 24                	je     f010250b <mem_init+0xf16>
f01024e7:	c7 44 24 0c a8 6f 10 	movl   $0xf0106fa8,0xc(%esp)
f01024ee:	f0 
f01024ef:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01024f6:	f0 
f01024f7:	c7 44 24 04 6e 04 00 	movl   $0x46e,0x4(%esp)
f01024fe:	00 
f01024ff:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102506:	e8 35 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010250b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102510:	89 f8                	mov    %edi,%eax
f0102512:	e8 1e e6 ff ff       	call   f0100b35 <check_va2pa>
f0102517:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f010251a:	74 24                	je     f0102540 <mem_init+0xf4b>
f010251c:	c7 44 24 0c d4 6f 10 	movl   $0xf0106fd4,0xc(%esp)
f0102523:	f0 
f0102524:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010252b:	f0 
f010252c:	c7 44 24 04 6f 04 00 	movl   $0x46f,0x4(%esp)
f0102533:	00 
f0102534:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010253b:	e8 00 db ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102540:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102545:	74 24                	je     f010256b <mem_init+0xf76>
f0102547:	c7 44 24 0c b6 76 10 	movl   $0xf01076b6,0xc(%esp)
f010254e:	f0 
f010254f:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102556:	f0 
f0102557:	c7 44 24 04 71 04 00 	movl   $0x471,0x4(%esp)
f010255e:	00 
f010255f:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102566:	e8 d5 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010256b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102570:	74 24                	je     f0102596 <mem_init+0xfa1>
f0102572:	c7 44 24 0c c7 76 10 	movl   $0xf01076c7,0xc(%esp)
f0102579:	f0 
f010257a:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102581:	f0 
f0102582:	c7 44 24 04 72 04 00 	movl   $0x472,0x4(%esp)
f0102589:	00 
f010258a:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102591:	e8 aa da ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102596:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010259d:	e8 c5 eb ff ff       	call   f0101167 <page_alloc>
f01025a2:	85 c0                	test   %eax,%eax
f01025a4:	74 04                	je     f01025aa <mem_init+0xfb5>
f01025a6:	39 c6                	cmp    %eax,%esi
f01025a8:	74 24                	je     f01025ce <mem_init+0xfd9>
f01025aa:	c7 44 24 0c 04 70 10 	movl   $0xf0107004,0xc(%esp)
f01025b1:	f0 
f01025b2:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01025b9:	f0 
f01025ba:	c7 44 24 04 75 04 00 	movl   $0x475,0x4(%esp)
f01025c1:	00 
f01025c2:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01025c9:	e8 72 da ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01025ce:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025d5:	00 
f01025d6:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01025db:	89 04 24             	mov    %eax,(%esp)
f01025de:	e8 bf ee ff ff       	call   f01014a2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025e3:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f01025e9:	ba 00 00 00 00       	mov    $0x0,%edx
f01025ee:	89 f8                	mov    %edi,%eax
f01025f0:	e8 40 e5 ff ff       	call   f0100b35 <check_va2pa>
f01025f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025f8:	74 24                	je     f010261e <mem_init+0x1029>
f01025fa:	c7 44 24 0c 28 70 10 	movl   $0xf0107028,0xc(%esp)
f0102601:	f0 
f0102602:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102609:	f0 
f010260a:	c7 44 24 04 79 04 00 	movl   $0x479,0x4(%esp)
f0102611:	00 
f0102612:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102619:	e8 22 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010261e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102623:	89 f8                	mov    %edi,%eax
f0102625:	e8 0b e5 ff ff       	call   f0100b35 <check_va2pa>
f010262a:	89 da                	mov    %ebx,%edx
f010262c:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0102632:	c1 fa 03             	sar    $0x3,%edx
f0102635:	c1 e2 0c             	shl    $0xc,%edx
f0102638:	39 d0                	cmp    %edx,%eax
f010263a:	74 24                	je     f0102660 <mem_init+0x106b>
f010263c:	c7 44 24 0c d4 6f 10 	movl   $0xf0106fd4,0xc(%esp)
f0102643:	f0 
f0102644:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010264b:	f0 
f010264c:	c7 44 24 04 7a 04 00 	movl   $0x47a,0x4(%esp)
f0102653:	00 
f0102654:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010265b:	e8 e0 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102660:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102665:	74 24                	je     f010268b <mem_init+0x1096>
f0102667:	c7 44 24 0c 6d 76 10 	movl   $0xf010766d,0xc(%esp)
f010266e:	f0 
f010266f:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102676:	f0 
f0102677:	c7 44 24 04 7b 04 00 	movl   $0x47b,0x4(%esp)
f010267e:	00 
f010267f:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102686:	e8 b5 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010268b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102690:	74 24                	je     f01026b6 <mem_init+0x10c1>
f0102692:	c7 44 24 0c c7 76 10 	movl   $0xf01076c7,0xc(%esp)
f0102699:	f0 
f010269a:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01026a1:	f0 
f01026a2:	c7 44 24 04 7c 04 00 	movl   $0x47c,0x4(%esp)
f01026a9:	00 
f01026aa:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01026b1:	e8 8a d9 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f01026b6:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01026bd:	00 
f01026be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01026c5:	00 
f01026c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01026ca:	89 3c 24             	mov    %edi,(%esp)
f01026cd:	e8 19 ee ff ff       	call   f01014eb <page_insert>
f01026d2:	85 c0                	test   %eax,%eax
f01026d4:	74 24                	je     f01026fa <mem_init+0x1105>
f01026d6:	c7 44 24 0c 4c 70 10 	movl   $0xf010704c,0xc(%esp)
f01026dd:	f0 
f01026de:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01026e5:	f0 
f01026e6:	c7 44 24 04 7f 04 00 	movl   $0x47f,0x4(%esp)
f01026ed:	00 
f01026ee:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01026f5:	e8 46 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01026fa:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01026ff:	75 24                	jne    f0102725 <mem_init+0x1130>
f0102701:	c7 44 24 0c d8 76 10 	movl   $0xf01076d8,0xc(%esp)
f0102708:	f0 
f0102709:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102710:	f0 
f0102711:	c7 44 24 04 80 04 00 	movl   $0x480,0x4(%esp)
f0102718:	00 
f0102719:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102720:	e8 1b d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102725:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102728:	74 24                	je     f010274e <mem_init+0x1159>
f010272a:	c7 44 24 0c e4 76 10 	movl   $0xf01076e4,0xc(%esp)
f0102731:	f0 
f0102732:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102739:	f0 
f010273a:	c7 44 24 04 81 04 00 	movl   $0x481,0x4(%esp)
f0102741:	00 
f0102742:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102749:	e8 f2 d8 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010274e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102755:	00 
f0102756:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010275b:	89 04 24             	mov    %eax,(%esp)
f010275e:	e8 3f ed ff ff       	call   f01014a2 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102763:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102769:	ba 00 00 00 00       	mov    $0x0,%edx
f010276e:	89 f8                	mov    %edi,%eax
f0102770:	e8 c0 e3 ff ff       	call   f0100b35 <check_va2pa>
f0102775:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102778:	74 24                	je     f010279e <mem_init+0x11a9>
f010277a:	c7 44 24 0c 28 70 10 	movl   $0xf0107028,0xc(%esp)
f0102781:	f0 
f0102782:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102789:	f0 
f010278a:	c7 44 24 04 85 04 00 	movl   $0x485,0x4(%esp)
f0102791:	00 
f0102792:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102799:	e8 a2 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010279e:	ba 00 10 00 00       	mov    $0x1000,%edx
f01027a3:	89 f8                	mov    %edi,%eax
f01027a5:	e8 8b e3 ff ff       	call   f0100b35 <check_va2pa>
f01027aa:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027ad:	74 24                	je     f01027d3 <mem_init+0x11de>
f01027af:	c7 44 24 0c 84 70 10 	movl   $0xf0107084,0xc(%esp)
f01027b6:	f0 
f01027b7:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01027be:	f0 
f01027bf:	c7 44 24 04 86 04 00 	movl   $0x486,0x4(%esp)
f01027c6:	00 
f01027c7:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01027ce:	e8 6d d8 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01027d3:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01027d8:	74 24                	je     f01027fe <mem_init+0x1209>
f01027da:	c7 44 24 0c f9 76 10 	movl   $0xf01076f9,0xc(%esp)
f01027e1:	f0 
f01027e2:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01027e9:	f0 
f01027ea:	c7 44 24 04 87 04 00 	movl   $0x487,0x4(%esp)
f01027f1:	00 
f01027f2:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01027f9:	e8 42 d8 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01027fe:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102803:	74 24                	je     f0102829 <mem_init+0x1234>
f0102805:	c7 44 24 0c c7 76 10 	movl   $0xf01076c7,0xc(%esp)
f010280c:	f0 
f010280d:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102814:	f0 
f0102815:	c7 44 24 04 88 04 00 	movl   $0x488,0x4(%esp)
f010281c:	00 
f010281d:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102824:	e8 17 d8 ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102829:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102830:	e8 32 e9 ff ff       	call   f0101167 <page_alloc>
f0102835:	85 c0                	test   %eax,%eax
f0102837:	74 04                	je     f010283d <mem_init+0x1248>
f0102839:	39 c3                	cmp    %eax,%ebx
f010283b:	74 24                	je     f0102861 <mem_init+0x126c>
f010283d:	c7 44 24 0c ac 70 10 	movl   $0xf01070ac,0xc(%esp)
f0102844:	f0 
f0102845:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010284c:	f0 
f010284d:	c7 44 24 04 8b 04 00 	movl   $0x48b,0x4(%esp)
f0102854:	00 
f0102855:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010285c:	e8 df d7 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102861:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102868:	e8 fa e8 ff ff       	call   f0101167 <page_alloc>
f010286d:	85 c0                	test   %eax,%eax
f010286f:	74 24                	je     f0102895 <mem_init+0x12a0>
f0102871:	c7 44 24 0c 1b 76 10 	movl   $0xf010761b,0xc(%esp)
f0102878:	f0 
f0102879:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102880:	f0 
f0102881:	c7 44 24 04 8e 04 00 	movl   $0x48e,0x4(%esp)
f0102888:	00 
f0102889:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102890:	e8 ab d7 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102895:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010289a:	8b 08                	mov    (%eax),%ecx
f010289c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01028a2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01028a5:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f01028ab:	c1 fa 03             	sar    $0x3,%edx
f01028ae:	c1 e2 0c             	shl    $0xc,%edx
f01028b1:	39 d1                	cmp    %edx,%ecx
f01028b3:	74 24                	je     f01028d9 <mem_init+0x12e4>
f01028b5:	c7 44 24 0c 50 6d 10 	movl   $0xf0106d50,0xc(%esp)
f01028bc:	f0 
f01028bd:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01028c4:	f0 
f01028c5:	c7 44 24 04 91 04 00 	movl   $0x491,0x4(%esp)
f01028cc:	00 
f01028cd:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01028d4:	e8 67 d7 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01028d9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01028df:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028e2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01028e7:	74 24                	je     f010290d <mem_init+0x1318>
f01028e9:	c7 44 24 0c 7e 76 10 	movl   $0xf010767e,0xc(%esp)
f01028f0:	f0 
f01028f1:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01028f8:	f0 
f01028f9:	c7 44 24 04 93 04 00 	movl   $0x493,0x4(%esp)
f0102900:	00 
f0102901:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102908:	e8 33 d7 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f010290d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102910:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102916:	89 04 24             	mov    %eax,(%esp)
f0102919:	e8 da e8 ff ff       	call   f01011f8 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010291e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102925:	00 
f0102926:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010292d:	00 
f010292e:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102933:	89 04 24             	mov    %eax,(%esp)
f0102936:	e8 3b e9 ff ff       	call   f0101276 <pgdir_walk>
f010293b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010293e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102941:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f0102947:	8b 7a 04             	mov    0x4(%edx),%edi
f010294a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102950:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f0102956:	89 f8                	mov    %edi,%eax
f0102958:	c1 e8 0c             	shr    $0xc,%eax
f010295b:	39 c8                	cmp    %ecx,%eax
f010295d:	72 20                	jb     f010297f <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010295f:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102963:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f010296a:	f0 
f010296b:	c7 44 24 04 9a 04 00 	movl   $0x49a,0x4(%esp)
f0102972:	00 
f0102973:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010297a:	e8 c1 d6 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010297f:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102985:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102988:	74 24                	je     f01029ae <mem_init+0x13b9>
f010298a:	c7 44 24 0c 0a 77 10 	movl   $0xf010770a,0xc(%esp)
f0102991:	f0 
f0102992:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102999:	f0 
f010299a:	c7 44 24 04 9b 04 00 	movl   $0x49b,0x4(%esp)
f01029a1:	00 
f01029a2:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01029a9:	e8 92 d6 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01029ae:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f01029b5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01029b8:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01029be:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f01029c4:	c1 f8 03             	sar    $0x3,%eax
f01029c7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029ca:	89 c2                	mov    %eax,%edx
f01029cc:	c1 ea 0c             	shr    $0xc,%edx
f01029cf:	39 d1                	cmp    %edx,%ecx
f01029d1:	77 20                	ja     f01029f3 <mem_init+0x13fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029d3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029d7:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f01029de:	f0 
f01029df:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01029e6:	00 
f01029e7:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f01029ee:	e8 4d d6 ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01029f3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029fa:	00 
f01029fb:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102a02:	00 
	return (void *)(pa + KERNBASE);
f0102a03:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102a08:	89 04 24             	mov    %eax,(%esp)
f0102a0b:	e8 87 2d 00 00       	call   f0105797 <memset>
	page_free(pp0);
f0102a10:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102a13:	89 3c 24             	mov    %edi,(%esp)
f0102a16:	e8 dd e7 ff ff       	call   f01011f8 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102a1b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102a22:	00 
f0102a23:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102a2a:	00 
f0102a2b:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102a30:	89 04 24             	mov    %eax,(%esp)
f0102a33:	e8 3e e8 ff ff       	call   f0101276 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a38:	89 fa                	mov    %edi,%edx
f0102a3a:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0102a40:	c1 fa 03             	sar    $0x3,%edx
f0102a43:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a46:	89 d0                	mov    %edx,%eax
f0102a48:	c1 e8 0c             	shr    $0xc,%eax
f0102a4b:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0102a51:	72 20                	jb     f0102a73 <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a53:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a57:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0102a5e:	f0 
f0102a5f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102a66:	00 
f0102a67:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0102a6e:	e8 cd d5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102a73:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102a79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a7c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a82:	f6 00 01             	testb  $0x1,(%eax)
f0102a85:	74 24                	je     f0102aab <mem_init+0x14b6>
f0102a87:	c7 44 24 0c 22 77 10 	movl   $0xf0107722,0xc(%esp)
f0102a8e:	f0 
f0102a8f:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102a96:	f0 
f0102a97:	c7 44 24 04 a5 04 00 	movl   $0x4a5,0x4(%esp)
f0102a9e:	00 
f0102a9f:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102aa6:	e8 95 d5 ff ff       	call   f0100040 <_panic>
f0102aab:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102aae:	39 d0                	cmp    %edx,%eax
f0102ab0:	75 d0                	jne    f0102a82 <mem_init+0x148d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102ab2:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102ab7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102abd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102ac0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102ac6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102ac9:	89 0d 44 b2 22 f0    	mov    %ecx,0xf022b244

	// free the pages we took
	page_free(pp0);
f0102acf:	89 04 24             	mov    %eax,(%esp)
f0102ad2:	e8 21 e7 ff ff       	call   f01011f8 <page_free>
	page_free(pp1);
f0102ad7:	89 1c 24             	mov    %ebx,(%esp)
f0102ada:	e8 19 e7 ff ff       	call   f01011f8 <page_free>
	page_free(pp2);
f0102adf:	89 34 24             	mov    %esi,(%esp)
f0102ae2:	e8 11 e7 ff ff       	call   f01011f8 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102ae7:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f0102aee:	00 
f0102aef:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102af6:	e8 b2 ea ff ff       	call   f01015ad <mmio_map_region>
f0102afb:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102afd:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102b04:	00 
f0102b05:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b0c:	e8 9c ea ff ff       	call   f01015ad <mmio_map_region>
f0102b11:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102b13:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102b19:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102b1e:	77 08                	ja     f0102b28 <mem_init+0x1533>
f0102b20:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102b26:	77 24                	ja     f0102b4c <mem_init+0x1557>
f0102b28:	c7 44 24 0c d0 70 10 	movl   $0xf01070d0,0xc(%esp)
f0102b2f:	f0 
f0102b30:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102b37:	f0 
f0102b38:	c7 44 24 04 b5 04 00 	movl   $0x4b5,0x4(%esp)
f0102b3f:	00 
f0102b40:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102b47:	e8 f4 d4 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102b4c:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102b52:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102b58:	77 08                	ja     f0102b62 <mem_init+0x156d>
f0102b5a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102b60:	77 24                	ja     f0102b86 <mem_init+0x1591>
f0102b62:	c7 44 24 0c f8 70 10 	movl   $0xf01070f8,0xc(%esp)
f0102b69:	f0 
f0102b6a:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102b71:	f0 
f0102b72:	c7 44 24 04 b6 04 00 	movl   $0x4b6,0x4(%esp)
f0102b79:	00 
f0102b7a:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102b81:	e8 ba d4 ff ff       	call   f0100040 <_panic>
f0102b86:	89 da                	mov    %ebx,%edx
f0102b88:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102b8a:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102b90:	74 24                	je     f0102bb6 <mem_init+0x15c1>
f0102b92:	c7 44 24 0c 20 71 10 	movl   $0xf0107120,0xc(%esp)
f0102b99:	f0 
f0102b9a:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102ba1:	f0 
f0102ba2:	c7 44 24 04 b8 04 00 	movl   $0x4b8,0x4(%esp)
f0102ba9:	00 
f0102baa:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102bb1:	e8 8a d4 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102bb6:	39 c6                	cmp    %eax,%esi
f0102bb8:	73 24                	jae    f0102bde <mem_init+0x15e9>
f0102bba:	c7 44 24 0c 39 77 10 	movl   $0xf0107739,0xc(%esp)
f0102bc1:	f0 
f0102bc2:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102bc9:	f0 
f0102bca:	c7 44 24 04 ba 04 00 	movl   $0x4ba,0x4(%esp)
f0102bd1:	00 
f0102bd2:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102bd9:	e8 62 d4 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102bde:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi
f0102be4:	89 da                	mov    %ebx,%edx
f0102be6:	89 f8                	mov    %edi,%eax
f0102be8:	e8 48 df ff ff       	call   f0100b35 <check_va2pa>
f0102bed:	85 c0                	test   %eax,%eax
f0102bef:	74 24                	je     f0102c15 <mem_init+0x1620>
f0102bf1:	c7 44 24 0c 48 71 10 	movl   $0xf0107148,0xc(%esp)
f0102bf8:	f0 
f0102bf9:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102c00:	f0 
f0102c01:	c7 44 24 04 bc 04 00 	movl   $0x4bc,0x4(%esp)
f0102c08:	00 
f0102c09:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102c10:	e8 2b d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102c15:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102c1b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102c1e:	89 c2                	mov    %eax,%edx
f0102c20:	89 f8                	mov    %edi,%eax
f0102c22:	e8 0e df ff ff       	call   f0100b35 <check_va2pa>
f0102c27:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102c2c:	74 24                	je     f0102c52 <mem_init+0x165d>
f0102c2e:	c7 44 24 0c 6c 71 10 	movl   $0xf010716c,0xc(%esp)
f0102c35:	f0 
f0102c36:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102c3d:	f0 
f0102c3e:	c7 44 24 04 bd 04 00 	movl   $0x4bd,0x4(%esp)
f0102c45:	00 
f0102c46:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102c4d:	e8 ee d3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102c52:	89 f2                	mov    %esi,%edx
f0102c54:	89 f8                	mov    %edi,%eax
f0102c56:	e8 da de ff ff       	call   f0100b35 <check_va2pa>
f0102c5b:	85 c0                	test   %eax,%eax
f0102c5d:	74 24                	je     f0102c83 <mem_init+0x168e>
f0102c5f:	c7 44 24 0c 9c 71 10 	movl   $0xf010719c,0xc(%esp)
f0102c66:	f0 
f0102c67:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102c6e:	f0 
f0102c6f:	c7 44 24 04 be 04 00 	movl   $0x4be,0x4(%esp)
f0102c76:	00 
f0102c77:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102c7e:	e8 bd d3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102c83:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102c89:	89 f8                	mov    %edi,%eax
f0102c8b:	e8 a5 de ff ff       	call   f0100b35 <check_va2pa>
f0102c90:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c93:	74 24                	je     f0102cb9 <mem_init+0x16c4>
f0102c95:	c7 44 24 0c c0 71 10 	movl   $0xf01071c0,0xc(%esp)
f0102c9c:	f0 
f0102c9d:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102ca4:	f0 
f0102ca5:	c7 44 24 04 bf 04 00 	movl   $0x4bf,0x4(%esp)
f0102cac:	00 
f0102cad:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102cb4:	e8 87 d3 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102cb9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102cc0:	00 
f0102cc1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102cc5:	89 3c 24             	mov    %edi,(%esp)
f0102cc8:	e8 a9 e5 ff ff       	call   f0101276 <pgdir_walk>
f0102ccd:	f6 00 1a             	testb  $0x1a,(%eax)
f0102cd0:	75 24                	jne    f0102cf6 <mem_init+0x1701>
f0102cd2:	c7 44 24 0c ec 71 10 	movl   $0xf01071ec,0xc(%esp)
f0102cd9:	f0 
f0102cda:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102ce1:	f0 
f0102ce2:	c7 44 24 04 c1 04 00 	movl   $0x4c1,0x4(%esp)
f0102ce9:	00 
f0102cea:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102cf1:	e8 4a d3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102cf6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102cfd:	00 
f0102cfe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102d02:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102d07:	89 04 24             	mov    %eax,(%esp)
f0102d0a:	e8 67 e5 ff ff       	call   f0101276 <pgdir_walk>
f0102d0f:	f6 00 04             	testb  $0x4,(%eax)
f0102d12:	74 24                	je     f0102d38 <mem_init+0x1743>
f0102d14:	c7 44 24 0c 30 72 10 	movl   $0xf0107230,0xc(%esp)
f0102d1b:	f0 
f0102d1c:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102d23:	f0 
f0102d24:	c7 44 24 04 c2 04 00 	movl   $0x4c2,0x4(%esp)
f0102d2b:	00 
f0102d2c:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102d33:	e8 08 d3 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102d38:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d3f:	00 
f0102d40:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102d44:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102d49:	89 04 24             	mov    %eax,(%esp)
f0102d4c:	e8 25 e5 ff ff       	call   f0101276 <pgdir_walk>
f0102d51:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102d57:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d5e:	00 
f0102d5f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d62:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d66:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102d6b:	89 04 24             	mov    %eax,(%esp)
f0102d6e:	e8 03 e5 ff ff       	call   f0101276 <pgdir_walk>
f0102d73:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102d79:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d80:	00 
f0102d81:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102d85:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102d8a:	89 04 24             	mov    %eax,(%esp)
f0102d8d:	e8 e4 e4 ff ff       	call   f0101276 <pgdir_walk>
f0102d92:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102d98:	c7 04 24 4b 77 10 f0 	movl   $0xf010774b,(%esp)
f0102d9f:	e8 88 13 00 00       	call   f010412c <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102da4:	a1 90 be 22 f0       	mov    0xf022be90,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102da9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dae:	77 20                	ja     f0102dd0 <mem_init+0x17db>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102db0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102db4:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0102dbb:	f0 
f0102dbc:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f0102dc3:	00 
f0102dc4:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102dcb:	e8 70 d2 ff ff       	call   f0100040 <_panic>
f0102dd0:	8b 15 88 be 22 f0    	mov    0xf022be88,%edx
f0102dd6:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102ddd:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102de3:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102dea:	00 
	return (physaddr_t)kva - KERNBASE;
f0102deb:	05 00 00 00 10       	add    $0x10000000,%eax
f0102df0:	89 04 24             	mov    %eax,(%esp)
f0102df3:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102df8:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102dfd:	e8 83 e5 ff ff       	call   f0101385 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f0102e02:	a1 4c b2 22 f0       	mov    0xf022b24c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e07:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e0c:	77 20                	ja     f0102e2e <mem_init+0x1839>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e0e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e12:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0102e19:	f0 
f0102e1a:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0102e21:	00 
f0102e22:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102e29:	e8 12 d2 ff ff       	call   f0100040 <_panic>
f0102e2e:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102e35:	00 
	return (physaddr_t)kva - KERNBASE;
f0102e36:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e3b:	89 04 24             	mov    %eax,(%esp)
f0102e3e:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102e43:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102e48:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102e4d:	e8 33 e5 ff ff       	call   f0101385 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e52:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102e57:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e5c:	77 20                	ja     f0102e7e <mem_init+0x1889>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e5e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e62:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0102e69:	f0 
f0102e6a:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
f0102e71:	00 
f0102e72:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102e79:	e8 c2 d1 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102e7e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e85:	00 
f0102e86:	c7 04 24 00 60 11 00 	movl   $0x116000,(%esp)
f0102e8d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e92:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e97:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102e9c:	e8 e4 e4 ff ff       	call   f0101385 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f0102ea1:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102ea8:	00 
f0102ea9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102eb0:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102eb5:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102eba:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102ebf:	e8 c1 e4 ff ff       	call   f0101385 <boot_map_region>
f0102ec4:	bf 00 d0 26 f0       	mov    $0xf026d000,%edi
f0102ec9:	bb 00 d0 22 f0       	mov    $0xf022d000,%ebx
f0102ece:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ed3:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102ed9:	77 20                	ja     f0102efb <mem_init+0x1906>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102edb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102edf:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0102ee6:	f0 
f0102ee7:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
f0102eee:	00 
f0102eef:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102ef6:	e8 45 d1 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f0102efb:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102f02:	00 
f0102f03:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102f09:	89 04 24             	mov    %eax,(%esp)
f0102f0c:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102f11:	89 f2                	mov    %esi,%edx
f0102f13:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0102f18:	e8 68 e4 ff ff       	call   f0101385 <boot_map_region>
f0102f1d:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102f23:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f0102f29:	39 fb                	cmp    %edi,%ebx
f0102f2b:	75 a6                	jne    f0102ed3 <mem_init+0x18de>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102f2d:	8b 3d 8c be 22 f0    	mov    0xf022be8c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102f33:	a1 88 be 22 f0       	mov    0xf022be88,%eax
f0102f38:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102f3b:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102f42:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102f47:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102f4a:	8b 35 90 be 22 f0    	mov    0xf022be90,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f50:	89 75 cc             	mov    %esi,-0x34(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102f53:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102f59:	89 45 c8             	mov    %eax,-0x38(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102f5c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102f61:	eb 6a                	jmp    f0102fcd <mem_init+0x19d8>
f0102f63:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102f69:	89 f8                	mov    %edi,%eax
f0102f6b:	e8 c5 db ff ff       	call   f0100b35 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f70:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102f77:	77 20                	ja     f0102f99 <mem_init+0x19a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f79:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102f7d:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0102f84:	f0 
f0102f85:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102f8c:	00 
f0102f8d:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102f94:	e8 a7 d0 ff ff       	call   f0100040 <_panic>
f0102f99:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102f9c:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102f9f:	39 d0                	cmp    %edx,%eax
f0102fa1:	74 24                	je     f0102fc7 <mem_init+0x19d2>
f0102fa3:	c7 44 24 0c 64 72 10 	movl   $0xf0107264,0xc(%esp)
f0102faa:	f0 
f0102fab:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0102fb2:	f0 
f0102fb3:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102fba:	00 
f0102fbb:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0102fc2:	e8 79 d0 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102fc7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102fcd:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102fd0:	77 91                	ja     f0102f63 <mem_init+0x196e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102fd2:	8b 1d 4c b2 22 f0    	mov    0xf022b24c,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fd8:	89 de                	mov    %ebx,%esi
f0102fda:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102fdf:	89 f8                	mov    %edi,%eax
f0102fe1:	e8 4f db ff ff       	call   f0100b35 <check_va2pa>
f0102fe6:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102fec:	77 20                	ja     f010300e <mem_init+0x1a19>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fee:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102ff2:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0102ff9:	f0 
f0102ffa:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0103001:	00 
f0103002:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103009:	e8 32 d0 ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010300e:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0103013:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0103019:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f010301c:	39 d0                	cmp    %edx,%eax
f010301e:	74 24                	je     f0103044 <mem_init+0x1a4f>
f0103020:	c7 44 24 0c 98 72 10 	movl   $0xf0107298,0xc(%esp)
f0103027:	f0 
f0103028:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010302f:	f0 
f0103030:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0103037:	00 
f0103038:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010303f:	e8 fc cf ff ff       	call   f0100040 <_panic>
f0103044:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010304a:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0103050:	0f 85 a8 05 00 00    	jne    f01035fe <mem_init+0x2009>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103056:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103059:	c1 e6 0c             	shl    $0xc,%esi
f010305c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103061:	eb 3b                	jmp    f010309e <mem_init+0x1aa9>
f0103063:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0103069:	89 f8                	mov    %edi,%eax
f010306b:	e8 c5 da ff ff       	call   f0100b35 <check_va2pa>
f0103070:	39 c3                	cmp    %eax,%ebx
f0103072:	74 24                	je     f0103098 <mem_init+0x1aa3>
f0103074:	c7 44 24 0c cc 72 10 	movl   $0xf01072cc,0xc(%esp)
f010307b:	f0 
f010307c:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0103083:	f0 
f0103084:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f010308b:	00 
f010308c:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103093:	e8 a8 cf ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103098:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010309e:	39 f3                	cmp    %esi,%ebx
f01030a0:	72 c1                	jb     f0103063 <mem_init+0x1a6e>
f01030a2:	c7 45 d0 00 d0 22 f0 	movl   $0xf022d000,-0x30(%ebp)
f01030a9:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f01030b0:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f01030b5:	b8 00 d0 22 f0       	mov    $0xf022d000,%eax
f01030ba:	05 00 80 00 20       	add    $0x20008000,%eax
f01030bf:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01030c2:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f01030c8:	89 45 cc             	mov    %eax,-0x34(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01030cb:	89 f2                	mov    %esi,%edx
f01030cd:	89 f8                	mov    %edi,%eax
f01030cf:	e8 61 da ff ff       	call   f0100b35 <check_va2pa>
f01030d4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01030d7:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f01030dd:	77 20                	ja     f01030ff <mem_init+0x1b0a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030df:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01030e3:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f01030ea:	f0 
f01030eb:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f01030f2:	00 
f01030f3:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01030fa:	e8 41 cf ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030ff:	89 f3                	mov    %esi,%ebx
f0103101:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103104:	03 4d d4             	add    -0x2c(%ebp),%ecx
f0103107:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f010310a:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f010310d:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f0103110:	39 c2                	cmp    %eax,%edx
f0103112:	74 24                	je     f0103138 <mem_init+0x1b43>
f0103114:	c7 44 24 0c f4 72 10 	movl   $0xf01072f4,0xc(%esp)
f010311b:	f0 
f010311c:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0103123:	f0 
f0103124:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f010312b:	00 
f010312c:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103133:	e8 08 cf ff ff       	call   f0100040 <_panic>
f0103138:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010313e:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f0103141:	0f 85 a9 04 00 00    	jne    f01035f0 <mem_init+0x1ffb>
f0103147:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010314d:	89 da                	mov    %ebx,%edx
f010314f:	89 f8                	mov    %edi,%eax
f0103151:	e8 df d9 ff ff       	call   f0100b35 <check_va2pa>
f0103156:	83 f8 ff             	cmp    $0xffffffff,%eax
f0103159:	74 24                	je     f010317f <mem_init+0x1b8a>
f010315b:	c7 44 24 0c 3c 73 10 	movl   $0xf010733c,0xc(%esp)
f0103162:	f0 
f0103163:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010316a:	f0 
f010316b:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f0103172:	00 
f0103173:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010317a:	e8 c1 ce ff ff       	call   f0100040 <_panic>
f010317f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0103185:	39 f3                	cmp    %esi,%ebx
f0103187:	75 c4                	jne    f010314d <mem_init+0x1b58>
f0103189:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f010318f:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f0103196:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f010319d:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f01031a3:	0f 85 19 ff ff ff    	jne    f01030c2 <mem_init+0x1acd>
f01031a9:	b8 00 00 00 00       	mov    $0x0,%eax
f01031ae:	e9 c2 00 00 00       	jmp    f0103275 <mem_init+0x1c80>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f01031b3:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f01031b9:	83 fa 04             	cmp    $0x4,%edx
f01031bc:	77 2e                	ja     f01031ec <mem_init+0x1bf7>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f01031be:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01031c2:	0f 85 aa 00 00 00    	jne    f0103272 <mem_init+0x1c7d>
f01031c8:	c7 44 24 0c 64 77 10 	movl   $0xf0107764,0xc(%esp)
f01031cf:	f0 
f01031d0:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01031d7:	f0 
f01031d8:	c7 44 24 04 f5 03 00 	movl   $0x3f5,0x4(%esp)
f01031df:	00 
f01031e0:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01031e7:	e8 54 ce ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01031ec:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01031f1:	76 55                	jbe    f0103248 <mem_init+0x1c53>
				assert(pgdir[i] & PTE_P);
f01031f3:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01031f6:	f6 c2 01             	test   $0x1,%dl
f01031f9:	75 24                	jne    f010321f <mem_init+0x1c2a>
f01031fb:	c7 44 24 0c 64 77 10 	movl   $0xf0107764,0xc(%esp)
f0103202:	f0 
f0103203:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010320a:	f0 
f010320b:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f0103212:	00 
f0103213:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010321a:	e8 21 ce ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f010321f:	f6 c2 02             	test   $0x2,%dl
f0103222:	75 4e                	jne    f0103272 <mem_init+0x1c7d>
f0103224:	c7 44 24 0c 75 77 10 	movl   $0xf0107775,0xc(%esp)
f010322b:	f0 
f010322c:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0103233:	f0 
f0103234:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f010323b:	00 
f010323c:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103243:	e8 f8 cd ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0103248:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010324c:	74 24                	je     f0103272 <mem_init+0x1c7d>
f010324e:	c7 44 24 0c 86 77 10 	movl   $0xf0107786,0xc(%esp)
f0103255:	f0 
f0103256:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010325d:	f0 
f010325e:	c7 44 24 04 fc 03 00 	movl   $0x3fc,0x4(%esp)
f0103265:	00 
f0103266:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010326d:	e8 ce cd ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0103272:	83 c0 01             	add    $0x1,%eax
f0103275:	3d 00 04 00 00       	cmp    $0x400,%eax
f010327a:	0f 85 33 ff ff ff    	jne    f01031b3 <mem_init+0x1bbe>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0103280:	c7 04 24 60 73 10 f0 	movl   $0xf0107360,(%esp)
f0103287:	e8 a0 0e 00 00       	call   f010412c <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010328c:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0103291:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103296:	77 20                	ja     f01032b8 <mem_init+0x1cc3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103298:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010329c:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f01032a3:	f0 
f01032a4:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
f01032ab:	00 
f01032ac:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01032b3:	e8 88 cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032b8:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01032bd:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01032c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01032c5:	e8 5f d9 ff ff       	call   f0100c29 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01032ca:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01032cd:	83 e0 f3             	and    $0xfffffff3,%eax
f01032d0:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01032d5:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01032d8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032df:	e8 83 de ff ff       	call   f0101167 <page_alloc>
f01032e4:	89 c3                	mov    %eax,%ebx
f01032e6:	85 c0                	test   %eax,%eax
f01032e8:	75 24                	jne    f010330e <mem_init+0x1d19>
f01032ea:	c7 44 24 0c 70 75 10 	movl   $0xf0107570,0xc(%esp)
f01032f1:	f0 
f01032f2:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01032f9:	f0 
f01032fa:	c7 44 24 04 d7 04 00 	movl   $0x4d7,0x4(%esp)
f0103301:	00 
f0103302:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103309:	e8 32 cd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010330e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103315:	e8 4d de ff ff       	call   f0101167 <page_alloc>
f010331a:	89 c7                	mov    %eax,%edi
f010331c:	85 c0                	test   %eax,%eax
f010331e:	75 24                	jne    f0103344 <mem_init+0x1d4f>
f0103320:	c7 44 24 0c 86 75 10 	movl   $0xf0107586,0xc(%esp)
f0103327:	f0 
f0103328:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010332f:	f0 
f0103330:	c7 44 24 04 d8 04 00 	movl   $0x4d8,0x4(%esp)
f0103337:	00 
f0103338:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010333f:	e8 fc cc ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0103344:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010334b:	e8 17 de ff ff       	call   f0101167 <page_alloc>
f0103350:	89 c6                	mov    %eax,%esi
f0103352:	85 c0                	test   %eax,%eax
f0103354:	75 24                	jne    f010337a <mem_init+0x1d85>
f0103356:	c7 44 24 0c 9c 75 10 	movl   $0xf010759c,0xc(%esp)
f010335d:	f0 
f010335e:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0103365:	f0 
f0103366:	c7 44 24 04 d9 04 00 	movl   $0x4d9,0x4(%esp)
f010336d:	00 
f010336e:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103375:	e8 c6 cc ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f010337a:	89 1c 24             	mov    %ebx,(%esp)
f010337d:	e8 76 de ff ff       	call   f01011f8 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0103382:	89 f8                	mov    %edi,%eax
f0103384:	e8 67 d7 ff ff       	call   f0100af0 <page2kva>
f0103389:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103390:	00 
f0103391:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0103398:	00 
f0103399:	89 04 24             	mov    %eax,(%esp)
f010339c:	e8 f6 23 00 00       	call   f0105797 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f01033a1:	89 f0                	mov    %esi,%eax
f01033a3:	e8 48 d7 ff ff       	call   f0100af0 <page2kva>
f01033a8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01033af:	00 
f01033b0:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01033b7:	00 
f01033b8:	89 04 24             	mov    %eax,(%esp)
f01033bb:	e8 d7 23 00 00       	call   f0105797 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01033c0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01033c7:	00 
f01033c8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01033cf:	00 
f01033d0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033d4:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f01033d9:	89 04 24             	mov    %eax,(%esp)
f01033dc:	e8 0a e1 ff ff       	call   f01014eb <page_insert>
	assert(pp1->pp_ref == 1);
f01033e1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01033e6:	74 24                	je     f010340c <mem_init+0x1e17>
f01033e8:	c7 44 24 0c 6d 76 10 	movl   $0xf010766d,0xc(%esp)
f01033ef:	f0 
f01033f0:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01033f7:	f0 
f01033f8:	c7 44 24 04 de 04 00 	movl   $0x4de,0x4(%esp)
f01033ff:	00 
f0103400:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103407:	e8 34 cc ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010340c:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103413:	01 01 01 
f0103416:	74 24                	je     f010343c <mem_init+0x1e47>
f0103418:	c7 44 24 0c 80 73 10 	movl   $0xf0107380,0xc(%esp)
f010341f:	f0 
f0103420:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0103427:	f0 
f0103428:	c7 44 24 04 df 04 00 	movl   $0x4df,0x4(%esp)
f010342f:	00 
f0103430:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103437:	e8 04 cc ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010343c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103443:	00 
f0103444:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010344b:	00 
f010344c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103450:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0103455:	89 04 24             	mov    %eax,(%esp)
f0103458:	e8 8e e0 ff ff       	call   f01014eb <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010345d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103464:	02 02 02 
f0103467:	74 24                	je     f010348d <mem_init+0x1e98>
f0103469:	c7 44 24 0c a4 73 10 	movl   $0xf01073a4,0xc(%esp)
f0103470:	f0 
f0103471:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f0103478:	f0 
f0103479:	c7 44 24 04 e1 04 00 	movl   $0x4e1,0x4(%esp)
f0103480:	00 
f0103481:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f0103488:	e8 b3 cb ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010348d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103492:	74 24                	je     f01034b8 <mem_init+0x1ec3>
f0103494:	c7 44 24 0c 8f 76 10 	movl   $0xf010768f,0xc(%esp)
f010349b:	f0 
f010349c:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01034a3:	f0 
f01034a4:	c7 44 24 04 e2 04 00 	movl   $0x4e2,0x4(%esp)
f01034ab:	00 
f01034ac:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01034b3:	e8 88 cb ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01034b8:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01034bd:	74 24                	je     f01034e3 <mem_init+0x1eee>
f01034bf:	c7 44 24 0c f9 76 10 	movl   $0xf01076f9,0xc(%esp)
f01034c6:	f0 
f01034c7:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01034ce:	f0 
f01034cf:	c7 44 24 04 e3 04 00 	movl   $0x4e3,0x4(%esp)
f01034d6:	00 
f01034d7:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01034de:	e8 5d cb ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01034e3:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01034ea:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01034ed:	89 f0                	mov    %esi,%eax
f01034ef:	e8 fc d5 ff ff       	call   f0100af0 <page2kva>
f01034f4:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01034fa:	74 24                	je     f0103520 <mem_init+0x1f2b>
f01034fc:	c7 44 24 0c c8 73 10 	movl   $0xf01073c8,0xc(%esp)
f0103503:	f0 
f0103504:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010350b:	f0 
f010350c:	c7 44 24 04 e5 04 00 	movl   $0x4e5,0x4(%esp)
f0103513:	00 
f0103514:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010351b:	e8 20 cb ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103520:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103527:	00 
f0103528:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f010352d:	89 04 24             	mov    %eax,(%esp)
f0103530:	e8 6d df ff ff       	call   f01014a2 <page_remove>
	assert(pp2->pp_ref == 0);
f0103535:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010353a:	74 24                	je     f0103560 <mem_init+0x1f6b>
f010353c:	c7 44 24 0c c7 76 10 	movl   $0xf01076c7,0xc(%esp)
f0103543:	f0 
f0103544:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010354b:	f0 
f010354c:	c7 44 24 04 e7 04 00 	movl   $0x4e7,0x4(%esp)
f0103553:	00 
f0103554:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010355b:	e8 e0 ca ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103560:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
f0103565:	8b 08                	mov    (%eax),%ecx
f0103567:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010356d:	89 da                	mov    %ebx,%edx
f010356f:	2b 15 90 be 22 f0    	sub    0xf022be90,%edx
f0103575:	c1 fa 03             	sar    $0x3,%edx
f0103578:	c1 e2 0c             	shl    $0xc,%edx
f010357b:	39 d1                	cmp    %edx,%ecx
f010357d:	74 24                	je     f01035a3 <mem_init+0x1fae>
f010357f:	c7 44 24 0c 50 6d 10 	movl   $0xf0106d50,0xc(%esp)
f0103586:	f0 
f0103587:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f010358e:	f0 
f010358f:	c7 44 24 04 ea 04 00 	movl   $0x4ea,0x4(%esp)
f0103596:	00 
f0103597:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f010359e:	e8 9d ca ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01035a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01035a9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01035ae:	74 24                	je     f01035d4 <mem_init+0x1fdf>
f01035b0:	c7 44 24 0c 7e 76 10 	movl   $0xf010767e,0xc(%esp)
f01035b7:	f0 
f01035b8:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01035bf:	f0 
f01035c0:	c7 44 24 04 ec 04 00 	movl   $0x4ec,0x4(%esp)
f01035c7:	00 
f01035c8:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01035cf:	e8 6c ca ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01035d4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01035da:	89 1c 24             	mov    %ebx,(%esp)
f01035dd:	e8 16 dc ff ff       	call   f01011f8 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01035e2:	c7 04 24 f4 73 10 f0 	movl   $0xf01073f4,(%esp)
f01035e9:	e8 3e 0b 00 00       	call   f010412c <cprintf>
f01035ee:	eb 1c                	jmp    f010360c <mem_init+0x2017>
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01035f0:	89 da                	mov    %ebx,%edx
f01035f2:	89 f8                	mov    %edi,%eax
f01035f4:	e8 3c d5 ff ff       	call   f0100b35 <check_va2pa>
f01035f9:	e9 0c fb ff ff       	jmp    f010310a <mem_init+0x1b15>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01035fe:	89 da                	mov    %ebx,%edx
f0103600:	89 f8                	mov    %edi,%eax
f0103602:	e8 2e d5 ff ff       	call   f0100b35 <check_va2pa>
f0103607:	e9 0d fa ff ff       	jmp    f0103019 <mem_init+0x1a24>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f010360c:	83 c4 4c             	add    $0x4c,%esp
f010360f:	5b                   	pop    %ebx
f0103610:	5e                   	pop    %esi
f0103611:	5f                   	pop    %edi
f0103612:	5d                   	pop    %ebp
f0103613:	c3                   	ret    

f0103614 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0103614:	55                   	push   %ebp
f0103615:	89 e5                	mov    %esp,%ebp
f0103617:	57                   	push   %edi
f0103618:	56                   	push   %esi
f0103619:	53                   	push   %ebx
f010361a:	83 ec 2c             	sub    $0x2c,%esp
f010361d:	8b 75 08             	mov    0x8(%ebp),%esi
f0103620:	8b 4d 14             	mov    0x14(%ebp),%ecx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0103623:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103626:	03 5d 10             	add    0x10(%ebp),%ebx
  if (va_beg >= ULIM || va_end >= ULIM) {
f0103629:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010362f:	77 09                	ja     f010363a <user_mem_check+0x26>
f0103631:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f0103638:	76 1f                	jbe    f0103659 <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f010363a:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0103641:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0103646:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f010364a:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
    return -E_FAULT;
f010364f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103654:	e9 b8 00 00 00       	jmp    f0103711 <user_mem_check+0xfd>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f0103659:	8b 45 0c             	mov    0xc(%ebp),%eax
f010365c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0103661:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
f0103667:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010366d:	8b 15 88 be 22 f0    	mov    0xf022be88,%edx
f0103673:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103676:	89 75 08             	mov    %esi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0103679:	e9 86 00 00 00       	jmp    f0103704 <user_mem_check+0xf0>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f010367e:	89 c7                	mov    %eax,%edi
f0103680:	c1 ef 16             	shr    $0x16,%edi
f0103683:	8b 75 08             	mov    0x8(%ebp),%esi
f0103686:	8b 56 60             	mov    0x60(%esi),%edx
f0103689:	8b 14 ba             	mov    (%edx,%edi,4),%edx
f010368c:	f6 c2 01             	test   $0x1,%dl
f010368f:	75 13                	jne    f01036a4 <user_mem_check+0x90>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0103691:	3b 45 0c             	cmp    0xc(%ebp),%eax
f0103694:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f0103698:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
      return -E_FAULT;
f010369d:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01036a2:	eb 6d                	jmp    f0103711 <user_mem_check+0xfd>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f01036a4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01036aa:	89 d7                	mov    %edx,%edi
f01036ac:	c1 ef 0c             	shr    $0xc,%edi
f01036af:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f01036b2:	72 20                	jb     f01036d4 <user_mem_check+0xc0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01036b4:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01036b8:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f01036bf:	f0 
f01036c0:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f01036c7:	00 
f01036c8:	c7 04 24 63 74 10 f0 	movl   $0xf0107463,(%esp)
f01036cf:	e8 6c c9 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f01036d4:	89 c7                	mov    %eax,%edi
f01036d6:	c1 ef 0c             	shr    $0xc,%edi
f01036d9:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
f01036df:	89 ce                	mov    %ecx,%esi
f01036e1:	23 b4 ba 00 00 00 f0 	and    -0x10000000(%edx,%edi,4),%esi
f01036e8:	39 f1                	cmp    %esi,%ecx
f01036ea:	74 13                	je     f01036ff <user_mem_check+0xeb>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f01036ec:	3b 45 0c             	cmp    0xc(%ebp),%eax
f01036ef:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f01036f3:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
      return -E_FAULT;
f01036f8:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01036fd:	eb 12                	jmp    f0103711 <user_mem_check+0xfd>
    }

    va_beg2 += PGSIZE;
f01036ff:	05 00 10 00 00       	add    $0x1000,%eax
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0103704:	39 d8                	cmp    %ebx,%eax
f0103706:	0f 82 72 ff ff ff    	jb     f010367e <user_mem_check+0x6a>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f010370c:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0103711:	83 c4 2c             	add    $0x2c,%esp
f0103714:	5b                   	pop    %ebx
f0103715:	5e                   	pop    %esi
f0103716:	5f                   	pop    %edi
f0103717:	5d                   	pop    %ebp
f0103718:	c3                   	ret    

f0103719 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0103719:	55                   	push   %ebp
f010371a:	89 e5                	mov    %esp,%ebp
f010371c:	53                   	push   %ebx
f010371d:	83 ec 14             	sub    $0x14,%esp
f0103720:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103723:	8b 45 14             	mov    0x14(%ebp),%eax
f0103726:	83 c8 04             	or     $0x4,%eax
f0103729:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010372d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103730:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103734:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103737:	89 44 24 04          	mov    %eax,0x4(%esp)
f010373b:	89 1c 24             	mov    %ebx,(%esp)
f010373e:	e8 d1 fe ff ff       	call   f0103614 <user_mem_check>
f0103743:	85 c0                	test   %eax,%eax
f0103745:	79 24                	jns    f010376b <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0103747:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f010374c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103750:	8b 43 48             	mov    0x48(%ebx),%eax
f0103753:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103757:	c7 04 24 20 74 10 f0 	movl   $0xf0107420,(%esp)
f010375e:	e8 c9 09 00 00       	call   f010412c <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0103763:	89 1c 24             	mov    %ebx,(%esp)
f0103766:	e8 e6 06 00 00       	call   f0103e51 <env_destroy>
	}
}
f010376b:	83 c4 14             	add    $0x14,%esp
f010376e:	5b                   	pop    %ebx
f010376f:	5d                   	pop    %ebp
f0103770:	c3                   	ret    

f0103771 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103771:	55                   	push   %ebp
f0103772:	89 e5                	mov    %esp,%ebp
f0103774:	57                   	push   %edi
f0103775:	56                   	push   %esi
f0103776:	53                   	push   %ebx
f0103777:	83 ec 1c             	sub    $0x1c,%esp
f010377a:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f010377c:	89 d3                	mov    %edx,%ebx
f010377e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0103784:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010378b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0103791:	eb 6d                	jmp    f0103800 <region_alloc+0x8f>
		struct PageInfo *p = page_alloc(0);
f0103793:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010379a:	e8 c8 d9 ff ff       	call   f0101167 <page_alloc>
		if (p == NULL)
f010379f:	85 c0                	test   %eax,%eax
f01037a1:	75 1c                	jne    f01037bf <region_alloc+0x4e>
			panic("Page alloc failed!");
f01037a3:	c7 44 24 08 94 77 10 	movl   $0xf0107794,0x8(%esp)
f01037aa:	f0 
f01037ab:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
f01037b2:	00 
f01037b3:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f01037ba:	e8 81 c8 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f01037bf:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01037c6:	00 
f01037c7:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01037cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037cf:	8b 47 60             	mov    0x60(%edi),%eax
f01037d2:	89 04 24             	mov    %eax,(%esp)
f01037d5:	e8 11 dd ff ff       	call   f01014eb <page_insert>
f01037da:	85 c0                	test   %eax,%eax
f01037dc:	74 1c                	je     f01037fa <region_alloc+0x89>
			panic("Page table couldn't be allocated!!");
f01037de:	c7 44 24 08 14 78 10 	movl   $0xf0107814,0x8(%esp)
f01037e5:	f0 
f01037e6:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f01037ed:	00 
f01037ee:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f01037f5:	e8 46 c8 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f01037fa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0103800:	39 f3                	cmp    %esi,%ebx
f0103802:	72 8f                	jb     f0103793 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0103804:	83 c4 1c             	add    $0x1c,%esp
f0103807:	5b                   	pop    %ebx
f0103808:	5e                   	pop    %esi
f0103809:	5f                   	pop    %edi
f010380a:	5d                   	pop    %ebp
f010380b:	c3                   	ret    

f010380c <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f010380c:	55                   	push   %ebp
f010380d:	89 e5                	mov    %esp,%ebp
f010380f:	56                   	push   %esi
f0103810:	53                   	push   %ebx
f0103811:	8b 45 08             	mov    0x8(%ebp),%eax
f0103814:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0103817:	85 c0                	test   %eax,%eax
f0103819:	75 1a                	jne    f0103835 <envid2env+0x29>
		*env_store = curenv;
f010381b:	e8 c9 25 00 00       	call   f0105de9 <cpunum>
f0103820:	6b c0 74             	imul   $0x74,%eax,%eax
f0103823:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103829:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010382c:	89 01                	mov    %eax,(%ecx)
		return 0;
f010382e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103833:	eb 70                	jmp    f01038a5 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103835:	89 c3                	mov    %eax,%ebx
f0103837:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010383d:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0103840:	03 1d 4c b2 22 f0    	add    0xf022b24c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103846:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f010384a:	74 05                	je     f0103851 <envid2env+0x45>
f010384c:	39 43 48             	cmp    %eax,0x48(%ebx)
f010384f:	74 10                	je     f0103861 <envid2env+0x55>
		*env_store = 0;
f0103851:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103854:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010385a:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010385f:	eb 44                	jmp    f01038a5 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103861:	84 d2                	test   %dl,%dl
f0103863:	74 36                	je     f010389b <envid2env+0x8f>
f0103865:	e8 7f 25 00 00       	call   f0105de9 <cpunum>
f010386a:	6b c0 74             	imul   $0x74,%eax,%eax
f010386d:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103873:	74 26                	je     f010389b <envid2env+0x8f>
f0103875:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103878:	e8 6c 25 00 00       	call   f0105de9 <cpunum>
f010387d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103880:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103886:	3b 70 48             	cmp    0x48(%eax),%esi
f0103889:	74 10                	je     f010389b <envid2env+0x8f>
		*env_store = 0;
f010388b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010388e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103894:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103899:	eb 0a                	jmp    f01038a5 <envid2env+0x99>
	}

	*env_store = e;
f010389b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010389e:	89 18                	mov    %ebx,(%eax)
	return 0;
f01038a0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038a5:	5b                   	pop    %ebx
f01038a6:	5e                   	pop    %esi
f01038a7:	5d                   	pop    %ebp
f01038a8:	c3                   	ret    

f01038a9 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f01038a9:	55                   	push   %ebp
f01038aa:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f01038ac:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f01038b1:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f01038b4:	b8 23 00 00 00       	mov    $0x23,%eax
f01038b9:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01038bb:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01038bd:	b0 10                	mov    $0x10,%al
f01038bf:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01038c1:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01038c3:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01038c5:	ea cc 38 10 f0 08 00 	ljmp   $0x8,$0xf01038cc
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01038cc:	b0 00                	mov    $0x0,%al
f01038ce:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01038d1:	5d                   	pop    %ebp
f01038d2:	c3                   	ret    

f01038d3 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01038d3:	8b 0d 50 b2 22 f0    	mov    0xf022b250,%ecx
f01038d9:	a1 4c b2 22 f0       	mov    0xf022b24c,%eax
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f01038de:	ba 00 04 00 00       	mov    $0x400,%edx
f01038e3:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f01038ea:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f01038f1:	85 c9                	test   %ecx,%ecx
f01038f3:	74 05                	je     f01038fa <env_init+0x27>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f01038f5:	89 40 c8             	mov    %eax,-0x38(%eax)
f01038f8:	eb 02                	jmp    f01038fc <env_init+0x29>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f01038fa:	89 c1                	mov    %eax,%ecx
f01038fc:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f01038ff:	83 ea 01             	sub    $0x1,%edx
f0103902:	75 df                	jne    f01038e3 <env_init+0x10>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0103904:	55                   	push   %ebp
f0103905:	89 e5                	mov    %esp,%ebp
f0103907:	89 0d 50 b2 22 f0    	mov    %ecx,0xf022b250
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f010390d:	e8 97 ff ff ff       	call   f01038a9 <env_init_percpu>
}
f0103912:	5d                   	pop    %ebp
f0103913:	c3                   	ret    

f0103914 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0103914:	55                   	push   %ebp
f0103915:	89 e5                	mov    %esp,%ebp
f0103917:	53                   	push   %ebx
f0103918:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f010391b:	8b 1d 50 b2 22 f0    	mov    0xf022b250,%ebx
f0103921:	85 db                	test   %ebx,%ebx
f0103923:	0f 84 8b 01 00 00    	je     f0103ab4 <env_alloc+0x1a0>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103929:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103930:	e8 32 d8 ff ff       	call   f0101167 <page_alloc>
f0103935:	85 c0                	test   %eax,%eax
f0103937:	0f 84 7e 01 00 00    	je     f0103abb <env_alloc+0x1a7>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f010393d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103942:	2b 05 90 be 22 f0    	sub    0xf022be90,%eax
f0103948:	c1 f8 03             	sar    $0x3,%eax
f010394b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010394e:	89 c2                	mov    %eax,%edx
f0103950:	c1 ea 0c             	shr    $0xc,%edx
f0103953:	3b 15 88 be 22 f0    	cmp    0xf022be88,%edx
f0103959:	72 20                	jb     f010397b <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010395b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010395f:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0103966:	f0 
f0103967:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f010396e:	00 
f010396f:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0103976:	e8 c5 c6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010397b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103980:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0103983:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0103988:	8b 15 8c be 22 f0    	mov    0xf022be8c,%edx
f010398e:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103991:	8b 53 60             	mov    0x60(%ebx),%edx
f0103994:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103997:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f010399a:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010399f:	75 e7                	jne    f0103988 <env_alloc+0x74>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f01039a1:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01039a4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01039a9:	77 20                	ja     f01039cb <env_alloc+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01039ab:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01039af:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f01039b6:	f0 
f01039b7:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f01039be:	00 
f01039bf:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f01039c6:	e8 75 c6 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01039cb:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01039d1:	83 ca 05             	or     $0x5,%edx
f01039d4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01039da:	8b 43 48             	mov    0x48(%ebx),%eax
f01039dd:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01039e2:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01039e7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01039ec:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01039ef:	89 da                	mov    %ebx,%edx
f01039f1:	2b 15 4c b2 22 f0    	sub    0xf022b24c,%edx
f01039f7:	c1 fa 02             	sar    $0x2,%edx
f01039fa:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0103a00:	09 d0                	or     %edx,%eax
f0103a02:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0103a05:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a08:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0103a0b:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0103a12:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0103a19:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103a20:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103a27:	00 
f0103a28:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103a2f:	00 
f0103a30:	89 1c 24             	mov    %ebx,(%esp)
f0103a33:	e8 5f 1d 00 00       	call   f0105797 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103a38:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103a3e:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103a44:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103a4a:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103a51:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103a57:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103a5e:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103a62:	8b 43 44             	mov    0x44(%ebx),%eax
f0103a65:	a3 50 b2 22 f0       	mov    %eax,0xf022b250
	*newenv_store = e;
f0103a6a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a6d:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103a6f:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103a72:	e8 72 23 00 00       	call   f0105de9 <cpunum>
f0103a77:	6b d0 74             	imul   $0x74,%eax,%edx
f0103a7a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a7f:	83 ba 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%edx)
f0103a86:	74 11                	je     f0103a99 <env_alloc+0x185>
f0103a88:	e8 5c 23 00 00       	call   f0105de9 <cpunum>
f0103a8d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a90:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103a96:	8b 40 48             	mov    0x48(%eax),%eax
f0103a99:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103a9d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103aa1:	c7 04 24 b2 77 10 f0 	movl   $0xf01077b2,(%esp)
f0103aa8:	e8 7f 06 00 00       	call   f010412c <cprintf>
	return 0;
f0103aad:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ab2:	eb 0c                	jmp    f0103ac0 <env_alloc+0x1ac>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103ab4:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103ab9:	eb 05                	jmp    f0103ac0 <env_alloc+0x1ac>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103abb:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103ac0:	83 c4 14             	add    $0x14,%esp
f0103ac3:	5b                   	pop    %ebx
f0103ac4:	5d                   	pop    %ebp
f0103ac5:	c3                   	ret    

f0103ac6 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103ac6:	55                   	push   %ebp
f0103ac7:	89 e5                	mov    %esp,%ebp
f0103ac9:	57                   	push   %edi
f0103aca:	56                   	push   %esi
f0103acb:	53                   	push   %ebx
f0103acc:	83 ec 3c             	sub    $0x3c,%esp
f0103acf:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0103ad2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103ad9:	00 
f0103ada:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103add:	89 04 24             	mov    %eax,(%esp)
f0103ae0:	e8 2f fe ff ff       	call   f0103914 <env_alloc>
	if (r){
f0103ae5:	85 c0                	test   %eax,%eax
f0103ae7:	74 20                	je     f0103b09 <env_create+0x43>
	panic("env_alloc: %e", r);
f0103ae9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103aed:	c7 44 24 08 c7 77 10 	movl   $0xf01077c7,0x8(%esp)
f0103af4:	f0 
f0103af5:	c7 44 24 04 b1 01 00 	movl   $0x1b1,0x4(%esp)
f0103afc:	00 
f0103afd:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103b04:	e8 37 c5 ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f0103b09:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103b0c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f0103b0f:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103b15:	74 1c                	je     f0103b33 <env_create+0x6d>
	{
		panic ("Not a valid ELF binary image");
f0103b17:	c7 44 24 08 d5 77 10 	movl   $0xf01077d5,0x8(%esp)
f0103b1e:	f0 
f0103b1f:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
f0103b26:	00 
f0103b27:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103b2e:	e8 0d c5 ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f0103b33:	89 fb                	mov    %edi,%ebx
f0103b35:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f0103b38:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103b3c:	c1 e6 05             	shl    $0x5,%esi
f0103b3f:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f0103b41:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103b44:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103b47:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b4c:	77 20                	ja     f0103b6e <env_create+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b4e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b52:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0103b59:	f0 
f0103b5a:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f0103b61:	00 
f0103b62:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103b69:	e8 d2 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103b6e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103b73:	0f 22 d8             	mov    %eax,%cr3
f0103b76:	eb 71                	jmp    f0103be9 <env_create+0x123>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f0103b78:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103b7b:	75 69                	jne    f0103be6 <env_create+0x120>
		
		if(ph->p_memsz < ph->p_filesz){
f0103b7d:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103b80:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103b83:	73 1c                	jae    f0103ba1 <env_create+0xdb>
		panic ("Memory size is smaller than file size!!");
f0103b85:	c7 44 24 08 38 78 10 	movl   $0xf0107838,0x8(%esp)
f0103b8c:	f0 
f0103b8d:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f0103b94:	00 
f0103b95:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103b9c:	e8 9f c4 ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0103ba1:	8b 53 08             	mov    0x8(%ebx),%edx
f0103ba4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103ba7:	e8 c5 fb ff ff       	call   f0103771 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103bac:	8b 43 10             	mov    0x10(%ebx),%eax
f0103baf:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103bb3:	89 f8                	mov    %edi,%eax
f0103bb5:	03 43 04             	add    0x4(%ebx),%eax
f0103bb8:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bbc:	8b 43 08             	mov    0x8(%ebx),%eax
f0103bbf:	89 04 24             	mov    %eax,(%esp)
f0103bc2:	e8 85 1c 00 00       	call   f010584c <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0103bc7:	8b 43 10             	mov    0x10(%ebx),%eax
f0103bca:	8b 53 14             	mov    0x14(%ebx),%edx
f0103bcd:	29 c2                	sub    %eax,%edx
f0103bcf:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103bd3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103bda:	00 
f0103bdb:	03 43 08             	add    0x8(%ebx),%eax
f0103bde:	89 04 24             	mov    %eax,(%esp)
f0103be1:	e8 b1 1b 00 00       	call   f0105797 <memset>
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0103be6:	83 c3 20             	add    $0x20,%ebx
f0103be9:	39 de                	cmp    %ebx,%esi
f0103beb:	77 8b                	ja     f0103b78 <env_create+0xb2>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0103bed:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103bf2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103bf7:	77 20                	ja     f0103c19 <env_create+0x153>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103bf9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103bfd:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0103c04:	f0 
f0103c05:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
f0103c0c:	00 
f0103c0d:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103c14:	e8 27 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103c19:	05 00 00 00 10       	add    $0x10000000,%eax
f0103c1e:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0103c21:	8b 47 18             	mov    0x18(%edi),%eax
f0103c24:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103c27:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0103c2a:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103c2f:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103c34:	89 f8                	mov    %edi,%eax
f0103c36:	e8 36 fb ff ff       	call   f0103771 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f0103c3b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103c3e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c41:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103c44:	83 c4 3c             	add    $0x3c,%esp
f0103c47:	5b                   	pop    %ebx
f0103c48:	5e                   	pop    %esi
f0103c49:	5f                   	pop    %edi
f0103c4a:	5d                   	pop    %ebp
f0103c4b:	c3                   	ret    

f0103c4c <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103c4c:	55                   	push   %ebp
f0103c4d:	89 e5                	mov    %esp,%ebp
f0103c4f:	57                   	push   %edi
f0103c50:	56                   	push   %esi
f0103c51:	53                   	push   %ebx
f0103c52:	83 ec 2c             	sub    $0x2c,%esp
f0103c55:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103c58:	e8 8c 21 00 00       	call   f0105de9 <cpunum>
f0103c5d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c60:	39 b8 28 c0 22 f0    	cmp    %edi,-0xfdd3fd8(%eax)
f0103c66:	75 34                	jne    f0103c9c <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103c68:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103c6d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103c72:	77 20                	ja     f0103c94 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103c74:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c78:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0103c7f:	f0 
f0103c80:	c7 44 24 04 c7 01 00 	movl   $0x1c7,0x4(%esp)
f0103c87:	00 
f0103c88:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103c8f:	e8 ac c3 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103c94:	05 00 00 00 10       	add    $0x10000000,%eax
f0103c99:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103c9c:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103c9f:	e8 45 21 00 00       	call   f0105de9 <cpunum>
f0103ca4:	6b d0 74             	imul   $0x74,%eax,%edx
f0103ca7:	b8 00 00 00 00       	mov    $0x0,%eax
f0103cac:	83 ba 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%edx)
f0103cb3:	74 11                	je     f0103cc6 <env_free+0x7a>
f0103cb5:	e8 2f 21 00 00       	call   f0105de9 <cpunum>
f0103cba:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cbd:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103cc3:	8b 40 48             	mov    0x48(%eax),%eax
f0103cc6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103cca:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cce:	c7 04 24 f2 77 10 f0 	movl   $0xf01077f2,(%esp)
f0103cd5:	e8 52 04 00 00       	call   f010412c <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103cda:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103ce1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103ce4:	89 c8                	mov    %ecx,%eax
f0103ce6:	c1 e0 02             	shl    $0x2,%eax
f0103ce9:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103cec:	8b 47 60             	mov    0x60(%edi),%eax
f0103cef:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103cf2:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103cf8:	0f 84 b7 00 00 00    	je     f0103db5 <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103cfe:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103d04:	89 f0                	mov    %esi,%eax
f0103d06:	c1 e8 0c             	shr    $0xc,%eax
f0103d09:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103d0c:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103d12:	72 20                	jb     f0103d34 <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103d14:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103d18:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0103d1f:	f0 
f0103d20:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
f0103d27:	00 
f0103d28:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103d2f:	e8 0c c3 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103d34:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d37:	c1 e0 16             	shl    $0x16,%eax
f0103d3a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103d3d:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103d42:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103d49:	01 
f0103d4a:	74 17                	je     f0103d63 <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103d4c:	89 d8                	mov    %ebx,%eax
f0103d4e:	c1 e0 0c             	shl    $0xc,%eax
f0103d51:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103d54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d58:	8b 47 60             	mov    0x60(%edi),%eax
f0103d5b:	89 04 24             	mov    %eax,(%esp)
f0103d5e:	e8 3f d7 ff ff       	call   f01014a2 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103d63:	83 c3 01             	add    $0x1,%ebx
f0103d66:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103d6c:	75 d4                	jne    f0103d42 <env_free+0xf6>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103d6e:	8b 47 60             	mov    0x60(%edi),%eax
f0103d71:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103d74:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103d7b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103d7e:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103d84:	72 1c                	jb     f0103da2 <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103d86:	c7 44 24 08 60 78 10 	movl   $0xf0107860,0x8(%esp)
f0103d8d:	f0 
f0103d8e:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103d95:	00 
f0103d96:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0103d9d:	e8 9e c2 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103da2:	a1 90 be 22 f0       	mov    0xf022be90,%eax
f0103da7:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103daa:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103dad:	89 04 24             	mov    %eax,(%esp)
f0103db0:	e8 9e d4 ff ff       	call   f0101253 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103db5:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103db9:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103dc0:	0f 85 1b ff ff ff    	jne    f0103ce1 <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103dc6:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103dc9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103dce:	77 20                	ja     f0103df0 <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103dd0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103dd4:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0103ddb:	f0 
f0103ddc:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
f0103de3:	00 
f0103de4:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103deb:	e8 50 c2 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103df0:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103df7:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103dfc:	c1 e8 0c             	shr    $0xc,%eax
f0103dff:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0103e05:	72 1c                	jb     f0103e23 <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103e07:	c7 44 24 08 60 78 10 	movl   $0xf0107860,0x8(%esp)
f0103e0e:	f0 
f0103e0f:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103e16:	00 
f0103e17:	c7 04 24 55 74 10 f0 	movl   $0xf0107455,(%esp)
f0103e1e:	e8 1d c2 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103e23:	8b 15 90 be 22 f0    	mov    0xf022be90,%edx
f0103e29:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103e2c:	89 04 24             	mov    %eax,(%esp)
f0103e2f:	e8 1f d4 ff ff       	call   f0101253 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103e34:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103e3b:	a1 50 b2 22 f0       	mov    0xf022b250,%eax
f0103e40:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103e43:	89 3d 50 b2 22 f0    	mov    %edi,0xf022b250
}
f0103e49:	83 c4 2c             	add    $0x2c,%esp
f0103e4c:	5b                   	pop    %ebx
f0103e4d:	5e                   	pop    %esi
f0103e4e:	5f                   	pop    %edi
f0103e4f:	5d                   	pop    %ebp
f0103e50:	c3                   	ret    

f0103e51 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103e51:	55                   	push   %ebp
f0103e52:	89 e5                	mov    %esp,%ebp
f0103e54:	53                   	push   %ebx
f0103e55:	83 ec 14             	sub    $0x14,%esp
f0103e58:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103e5b:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103e5f:	75 19                	jne    f0103e7a <env_destroy+0x29>
f0103e61:	e8 83 1f 00 00       	call   f0105de9 <cpunum>
f0103e66:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e69:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103e6f:	74 09                	je     f0103e7a <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103e71:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103e78:	eb 2f                	jmp    f0103ea9 <env_destroy+0x58>
	}

	env_free(e);
f0103e7a:	89 1c 24             	mov    %ebx,(%esp)
f0103e7d:	e8 ca fd ff ff       	call   f0103c4c <env_free>

	if (curenv == e) {
f0103e82:	e8 62 1f 00 00       	call   f0105de9 <cpunum>
f0103e87:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e8a:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103e90:	75 17                	jne    f0103ea9 <env_destroy+0x58>
		curenv = NULL;
f0103e92:	e8 52 1f 00 00       	call   f0105de9 <cpunum>
f0103e97:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e9a:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f0103ea1:	00 00 00 
		sched_yield();
f0103ea4:	e8 7d 0a 00 00       	call   f0104926 <sched_yield>
	}
}
f0103ea9:	83 c4 14             	add    $0x14,%esp
f0103eac:	5b                   	pop    %ebx
f0103ead:	5d                   	pop    %ebp
f0103eae:	c3                   	ret    

f0103eaf <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103eaf:	55                   	push   %ebp
f0103eb0:	89 e5                	mov    %esp,%ebp
f0103eb2:	53                   	push   %ebx
f0103eb3:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103eb6:	e8 2e 1f 00 00       	call   f0105de9 <cpunum>
f0103ebb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ebe:	8b 98 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%ebx
f0103ec4:	e8 20 1f 00 00       	call   f0105de9 <cpunum>
f0103ec9:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103ecc:	8b 65 08             	mov    0x8(%ebp),%esp
f0103ecf:	61                   	popa   
f0103ed0:	07                   	pop    %es
f0103ed1:	1f                   	pop    %ds
f0103ed2:	83 c4 08             	add    $0x8,%esp
f0103ed5:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103ed6:	c7 44 24 08 08 78 10 	movl   $0xf0107808,0x8(%esp)
f0103edd:	f0 
f0103ede:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
f0103ee5:	00 
f0103ee6:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103eed:	e8 4e c1 ff ff       	call   f0100040 <_panic>

f0103ef2 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103ef2:	55                   	push   %ebp
f0103ef3:	89 e5                	mov    %esp,%ebp
f0103ef5:	53                   	push   %ebx
f0103ef6:	83 ec 14             	sub    $0x14,%esp
f0103ef9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103efc:	e8 e8 1e 00 00       	call   f0105de9 <cpunum>
f0103f01:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f04:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0103f0b:	75 10                	jne    f0103f1d <env_run+0x2b>
	curenv = e;
f0103f0d:	e8 d7 1e 00 00       	call   f0105de9 <cpunum>
f0103f12:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f15:	89 98 28 c0 22 f0    	mov    %ebx,-0xfdd3fd8(%eax)
f0103f1b:	eb 29                	jmp    f0103f46 <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103f1d:	e8 c7 1e 00 00       	call   f0105de9 <cpunum>
f0103f22:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f25:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f2b:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f2f:	75 15                	jne    f0103f46 <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f0103f31:	e8 b3 1e 00 00       	call   f0105de9 <cpunum>
f0103f36:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f39:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f3f:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f0103f46:	e8 9e 1e 00 00       	call   f0105de9 <cpunum>
f0103f4b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f4e:	89 98 28 c0 22 f0    	mov    %ebx,-0xfdd3fd8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103f54:	e8 90 1e 00 00       	call   f0105de9 <cpunum>
f0103f59:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f5c:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f62:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f0103f69:	e8 7b 1e 00 00       	call   f0105de9 <cpunum>
f0103f6e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f71:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f77:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f0103f7b:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103f7e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103f83:	77 20                	ja     f0103fa5 <env_run+0xb3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103f85:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f89:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f0103f90:	f0 
f0103f91:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0103f98:	00 
f0103f99:	c7 04 24 a7 77 10 f0 	movl   $0xf01077a7,(%esp)
f0103fa0:	e8 9b c0 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103fa5:	05 00 00 00 10       	add    $0x10000000,%eax
f0103faa:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103fad:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0103fb4:	e8 5a 21 00 00       	call   f0106113 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103fb9:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f0103fbb:	89 1c 24             	mov    %ebx,(%esp)
f0103fbe:	e8 ec fe ff ff       	call   f0103eaf <env_pop_tf>

f0103fc3 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103fc3:	55                   	push   %ebp
f0103fc4:	89 e5                	mov    %esp,%ebp
f0103fc6:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103fca:	ba 70 00 00 00       	mov    $0x70,%edx
f0103fcf:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103fd0:	b2 71                	mov    $0x71,%dl
f0103fd2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103fd3:	0f b6 c0             	movzbl %al,%eax
}
f0103fd6:	5d                   	pop    %ebp
f0103fd7:	c3                   	ret    

f0103fd8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103fd8:	55                   	push   %ebp
f0103fd9:	89 e5                	mov    %esp,%ebp
f0103fdb:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103fdf:	ba 70 00 00 00       	mov    $0x70,%edx
f0103fe4:	ee                   	out    %al,(%dx)
f0103fe5:	b2 71                	mov    $0x71,%dl
f0103fe7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fea:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103feb:	5d                   	pop    %ebp
f0103fec:	c3                   	ret    

f0103fed <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103fed:	55                   	push   %ebp
f0103fee:	89 e5                	mov    %esp,%ebp
f0103ff0:	56                   	push   %esi
f0103ff1:	53                   	push   %ebx
f0103ff2:	83 ec 10             	sub    $0x10,%esp
f0103ff5:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103ff8:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f0103ffe:	80 3d 54 b2 22 f0 00 	cmpb   $0x0,0xf022b254
f0104005:	74 4e                	je     f0104055 <irq_setmask_8259A+0x68>
f0104007:	89 c6                	mov    %eax,%esi
f0104009:	ba 21 00 00 00       	mov    $0x21,%edx
f010400e:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f010400f:	66 c1 e8 08          	shr    $0x8,%ax
f0104013:	b2 a1                	mov    $0xa1,%dl
f0104015:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0104016:	c7 04 24 7f 78 10 f0 	movl   $0xf010787f,(%esp)
f010401d:	e8 0a 01 00 00       	call   f010412c <cprintf>
	for (i = 0; i < 16; i++)
f0104022:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0104027:	0f b7 f6             	movzwl %si,%esi
f010402a:	f7 d6                	not    %esi
f010402c:	0f a3 de             	bt     %ebx,%esi
f010402f:	73 10                	jae    f0104041 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0104031:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104035:	c7 04 24 97 7d 10 f0 	movl   $0xf0107d97,(%esp)
f010403c:	e8 eb 00 00 00       	call   f010412c <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0104041:	83 c3 01             	add    $0x1,%ebx
f0104044:	83 fb 10             	cmp    $0x10,%ebx
f0104047:	75 e3                	jne    f010402c <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0104049:	c7 04 24 32 7d 10 f0 	movl   $0xf0107d32,(%esp)
f0104050:	e8 d7 00 00 00       	call   f010412c <cprintf>
}
f0104055:	83 c4 10             	add    $0x10,%esp
f0104058:	5b                   	pop    %ebx
f0104059:	5e                   	pop    %esi
f010405a:	5d                   	pop    %ebp
f010405b:	c3                   	ret    

f010405c <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010405c:	c6 05 54 b2 22 f0 01 	movb   $0x1,0xf022b254
f0104063:	ba 21 00 00 00       	mov    $0x21,%edx
f0104068:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010406d:	ee                   	out    %al,(%dx)
f010406e:	b2 a1                	mov    $0xa1,%dl
f0104070:	ee                   	out    %al,(%dx)
f0104071:	b2 20                	mov    $0x20,%dl
f0104073:	b8 11 00 00 00       	mov    $0x11,%eax
f0104078:	ee                   	out    %al,(%dx)
f0104079:	b2 21                	mov    $0x21,%dl
f010407b:	b8 20 00 00 00       	mov    $0x20,%eax
f0104080:	ee                   	out    %al,(%dx)
f0104081:	b8 04 00 00 00       	mov    $0x4,%eax
f0104086:	ee                   	out    %al,(%dx)
f0104087:	b8 03 00 00 00       	mov    $0x3,%eax
f010408c:	ee                   	out    %al,(%dx)
f010408d:	b2 a0                	mov    $0xa0,%dl
f010408f:	b8 11 00 00 00       	mov    $0x11,%eax
f0104094:	ee                   	out    %al,(%dx)
f0104095:	b2 a1                	mov    $0xa1,%dl
f0104097:	b8 28 00 00 00       	mov    $0x28,%eax
f010409c:	ee                   	out    %al,(%dx)
f010409d:	b8 02 00 00 00       	mov    $0x2,%eax
f01040a2:	ee                   	out    %al,(%dx)
f01040a3:	b8 01 00 00 00       	mov    $0x1,%eax
f01040a8:	ee                   	out    %al,(%dx)
f01040a9:	b2 20                	mov    $0x20,%dl
f01040ab:	b8 68 00 00 00       	mov    $0x68,%eax
f01040b0:	ee                   	out    %al,(%dx)
f01040b1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01040b6:	ee                   	out    %al,(%dx)
f01040b7:	b2 a0                	mov    $0xa0,%dl
f01040b9:	b8 68 00 00 00       	mov    $0x68,%eax
f01040be:	ee                   	out    %al,(%dx)
f01040bf:	b8 0a 00 00 00       	mov    $0xa,%eax
f01040c4:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01040c5:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01040cc:	66 83 f8 ff          	cmp    $0xffff,%ax
f01040d0:	74 12                	je     f01040e4 <pic_init+0x88>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01040d2:	55                   	push   %ebp
f01040d3:	89 e5                	mov    %esp,%ebp
f01040d5:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01040d8:	0f b7 c0             	movzwl %ax,%eax
f01040db:	89 04 24             	mov    %eax,(%esp)
f01040de:	e8 0a ff ff ff       	call   f0103fed <irq_setmask_8259A>
}
f01040e3:	c9                   	leave  
f01040e4:	f3 c3                	repz ret 

f01040e6 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01040e6:	55                   	push   %ebp
f01040e7:	89 e5                	mov    %esp,%ebp
f01040e9:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01040ec:	8b 45 08             	mov    0x8(%ebp),%eax
f01040ef:	89 04 24             	mov    %eax,(%esp)
f01040f2:	e8 b3 c6 ff ff       	call   f01007aa <cputchar>
	*cnt++;
}
f01040f7:	c9                   	leave  
f01040f8:	c3                   	ret    

f01040f9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01040f9:	55                   	push   %ebp
f01040fa:	89 e5                	mov    %esp,%ebp
f01040fc:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01040ff:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0104106:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104109:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010410d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104110:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104114:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104117:	89 44 24 04          	mov    %eax,0x4(%esp)
f010411b:	c7 04 24 e6 40 10 f0 	movl   $0xf01040e6,(%esp)
f0104122:	e8 b7 0f 00 00       	call   f01050de <vprintfmt>
	return cnt;
}
f0104127:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010412a:	c9                   	leave  
f010412b:	c3                   	ret    

f010412c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010412c:	55                   	push   %ebp
f010412d:	89 e5                	mov    %esp,%ebp
f010412f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0104132:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0104135:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104139:	8b 45 08             	mov    0x8(%ebp),%eax
f010413c:	89 04 24             	mov    %eax,(%esp)
f010413f:	e8 b5 ff ff ff       	call   f01040f9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0104144:	c9                   	leave  
f0104145:	c3                   	ret    
f0104146:	66 90                	xchg   %ax,%ax
f0104148:	66 90                	xchg   %ax,%ax
f010414a:	66 90                	xchg   %ax,%ax
f010414c:	66 90                	xchg   %ax,%ax
f010414e:	66 90                	xchg   %ax,%ax

f0104150 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0104150:	55                   	push   %ebp
f0104151:	89 e5                	mov    %esp,%ebp
f0104153:	56                   	push   %esi
f0104154:	53                   	push   %ebx
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
	// Load the IDT
	lidt(&idt_pd);  */
	
	int i = cpunum();
f0104155:	e8 8f 1c 00 00       	call   f0105de9 <cpunum>
f010415a:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f010415c:	e8 88 1c 00 00       	call   f0105de9 <cpunum>
f0104161:	89 c6                	mov    %eax,%esi
f0104163:	e8 81 1c 00 00       	call   f0105de9 <cpunum>
f0104168:	6b f6 74             	imul   $0x74,%esi,%esi
f010416b:	c1 e0 0f             	shl    $0xf,%eax
f010416e:	8d 80 00 50 23 f0    	lea    -0xfdcb000(%eax),%eax
f0104174:	89 86 30 c0 22 f0    	mov    %eax,-0xfdd3fd0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010417a:	e8 6a 1c 00 00       	call   f0105de9 <cpunum>
f010417f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104182:	66 c7 80 34 c0 22 f0 	movw   $0x10,-0xfdd3fcc(%eax)
f0104189:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f010418b:	8d 53 05             	lea    0x5(%ebx),%edx
f010418e:	6b c3 74             	imul   $0x74,%ebx,%eax
f0104191:	05 2c c0 22 f0       	add    $0xf022c02c,%eax
f0104196:	66 c7 04 d5 40 03 12 	movw   $0x67,-0xfedfcc0(,%edx,8)
f010419d:	f0 67 00 
f01041a0:	66 89 04 d5 42 03 12 	mov    %ax,-0xfedfcbe(,%edx,8)
f01041a7:	f0 
f01041a8:	89 c1                	mov    %eax,%ecx
f01041aa:	c1 e9 10             	shr    $0x10,%ecx
f01041ad:	88 0c d5 44 03 12 f0 	mov    %cl,-0xfedfcbc(,%edx,8)
f01041b4:	c6 04 d5 46 03 12 f0 	movb   $0x40,-0xfedfcba(,%edx,8)
f01041bb:	40 
f01041bc:	c1 e8 18             	shr    $0x18,%eax
f01041bf:	88 04 d5 47 03 12 f0 	mov    %al,-0xfedfcb9(,%edx,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f01041c6:	c6 04 d5 45 03 12 f0 	movb   $0x89,-0xfedfcbb(,%edx,8)
f01041cd:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f01041ce:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01041d5:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01041d8:	b8 aa 03 12 f0       	mov    $0xf01203aa,%eax
f01041dd:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f01041e0:	5b                   	pop    %ebx
f01041e1:	5e                   	pop    %esi
f01041e2:	5d                   	pop    %ebp
f01041e3:	c3                   	ret    

f01041e4 <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f01041e4:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f01041e9:	8b 14 85 b0 03 12 f0 	mov    -0xfedfc50(,%eax,4),%edx
f01041f0:	66 89 14 c5 60 b2 22 	mov    %dx,-0xfdd4da0(,%eax,8)
f01041f7:	f0 
f01041f8:	66 c7 04 c5 62 b2 22 	movw   $0x8,-0xfdd4d9e(,%eax,8)
f01041ff:	f0 08 00 
f0104202:	c6 04 c5 64 b2 22 f0 	movb   $0x0,-0xfdd4d9c(,%eax,8)
f0104209:	00 
f010420a:	c6 04 c5 65 b2 22 f0 	movb   $0x8e,-0xfdd4d9b(,%eax,8)
f0104211:	8e 
f0104212:	c1 ea 10             	shr    $0x10,%edx
f0104215:	66 89 14 c5 66 b2 22 	mov    %dx,-0xfdd4d9a(,%eax,8)
f010421c:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f010421d:	83 c0 01             	add    $0x1,%eax
f0104220:	83 f8 14             	cmp    $0x14,%eax
f0104223:	75 c4                	jne    f01041e9 <trap_init+0x5>
}


void
trap_init(void)
{
f0104225:	55                   	push   %ebp
f0104226:	89 e5                	mov    %esp,%ebp
f0104228:	83 ec 08             	sub    $0x8,%esp
	for (i=0; i<= T_SIMDERR;i++){
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f010422b:	a1 bc 03 12 f0       	mov    0xf01203bc,%eax
f0104230:	66 a3 78 b2 22 f0    	mov    %ax,0xf022b278
f0104236:	66 c7 05 7a b2 22 f0 	movw   $0x8,0xf022b27a
f010423d:	08 00 
f010423f:	c6 05 7c b2 22 f0 00 	movb   $0x0,0xf022b27c
f0104246:	c6 05 7d b2 22 f0 ee 	movb   $0xee,0xf022b27d
f010424d:	c1 e8 10             	shr    $0x10,%eax
f0104250:	66 a3 7e b2 22 f0    	mov    %ax,0xf022b27e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f0104256:	a1 70 04 12 f0       	mov    0xf0120470,%eax
f010425b:	66 a3 e0 b3 22 f0    	mov    %ax,0xf022b3e0
f0104261:	66 c7 05 e2 b3 22 f0 	movw   $0x8,0xf022b3e2
f0104268:	08 00 
f010426a:	c6 05 e4 b3 22 f0 00 	movb   $0x0,0xf022b3e4
f0104271:	c6 05 e5 b3 22 f0 ee 	movb   $0xee,0xf022b3e5
f0104278:	c1 e8 10             	shr    $0x10,%eax
f010427b:	66 a3 e6 b3 22 f0    	mov    %ax,0xf022b3e6

	// Per-CPU setup 
	trap_init_percpu();
f0104281:	e8 ca fe ff ff       	call   f0104150 <trap_init_percpu>
}
f0104286:	c9                   	leave  
f0104287:	c3                   	ret    

f0104288 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0104288:	55                   	push   %ebp
f0104289:	89 e5                	mov    %esp,%ebp
f010428b:	53                   	push   %ebx
f010428c:	83 ec 14             	sub    $0x14,%esp
f010428f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f0104292:	8b 03                	mov    (%ebx),%eax
f0104294:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104298:	c7 04 24 93 78 10 f0 	movl   $0xf0107893,(%esp)
f010429f:	e8 88 fe ff ff       	call   f010412c <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01042a4:	8b 43 04             	mov    0x4(%ebx),%eax
f01042a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042ab:	c7 04 24 a2 78 10 f0 	movl   $0xf01078a2,(%esp)
f01042b2:	e8 75 fe ff ff       	call   f010412c <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01042b7:	8b 43 08             	mov    0x8(%ebx),%eax
f01042ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042be:	c7 04 24 b1 78 10 f0 	movl   $0xf01078b1,(%esp)
f01042c5:	e8 62 fe ff ff       	call   f010412c <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01042ca:	8b 43 0c             	mov    0xc(%ebx),%eax
f01042cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042d1:	c7 04 24 c0 78 10 f0 	movl   $0xf01078c0,(%esp)
f01042d8:	e8 4f fe ff ff       	call   f010412c <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01042dd:	8b 43 10             	mov    0x10(%ebx),%eax
f01042e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042e4:	c7 04 24 cf 78 10 f0 	movl   $0xf01078cf,(%esp)
f01042eb:	e8 3c fe ff ff       	call   f010412c <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01042f0:	8b 43 14             	mov    0x14(%ebx),%eax
f01042f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042f7:	c7 04 24 de 78 10 f0 	movl   $0xf01078de,(%esp)
f01042fe:	e8 29 fe ff ff       	call   f010412c <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0104303:	8b 43 18             	mov    0x18(%ebx),%eax
f0104306:	89 44 24 04          	mov    %eax,0x4(%esp)
f010430a:	c7 04 24 ed 78 10 f0 	movl   $0xf01078ed,(%esp)
f0104311:	e8 16 fe ff ff       	call   f010412c <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0104316:	8b 43 1c             	mov    0x1c(%ebx),%eax
f0104319:	89 44 24 04          	mov    %eax,0x4(%esp)
f010431d:	c7 04 24 fc 78 10 f0 	movl   $0xf01078fc,(%esp)
f0104324:	e8 03 fe ff ff       	call   f010412c <cprintf>
}
f0104329:	83 c4 14             	add    $0x14,%esp
f010432c:	5b                   	pop    %ebx
f010432d:	5d                   	pop    %ebp
f010432e:	c3                   	ret    

f010432f <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f010432f:	55                   	push   %ebp
f0104330:	89 e5                	mov    %esp,%ebp
f0104332:	56                   	push   %esi
f0104333:	53                   	push   %ebx
f0104334:	83 ec 10             	sub    $0x10,%esp
f0104337:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f010433a:	e8 aa 1a 00 00       	call   f0105de9 <cpunum>
f010433f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104343:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104347:	c7 04 24 60 79 10 f0 	movl   $0xf0107960,(%esp)
f010434e:	e8 d9 fd ff ff       	call   f010412c <cprintf>
	print_regs(&tf->tf_regs);
f0104353:	89 1c 24             	mov    %ebx,(%esp)
f0104356:	e8 2d ff ff ff       	call   f0104288 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f010435b:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010435f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104363:	c7 04 24 7e 79 10 f0 	movl   $0xf010797e,(%esp)
f010436a:	e8 bd fd ff ff       	call   f010412c <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010436f:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0104373:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104377:	c7 04 24 91 79 10 f0 	movl   $0xf0107991,(%esp)
f010437e:	e8 a9 fd ff ff       	call   f010412c <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104383:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0104386:	83 f8 13             	cmp    $0x13,%eax
f0104389:	77 09                	ja     f0104394 <print_trapframe+0x65>
		return excnames[trapno];
f010438b:	8b 14 85 60 7c 10 f0 	mov    -0xfef83a0(,%eax,4),%edx
f0104392:	eb 1f                	jmp    f01043b3 <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f0104394:	83 f8 30             	cmp    $0x30,%eax
f0104397:	74 15                	je     f01043ae <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104399:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f010439c:	83 fa 0f             	cmp    $0xf,%edx
f010439f:	ba 17 79 10 f0       	mov    $0xf0107917,%edx
f01043a4:	b9 2a 79 10 f0       	mov    $0xf010792a,%ecx
f01043a9:	0f 47 d1             	cmova  %ecx,%edx
f01043ac:	eb 05                	jmp    f01043b3 <print_trapframe+0x84>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f01043ae:	ba 0b 79 10 f0       	mov    $0xf010790b,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01043b3:	89 54 24 08          	mov    %edx,0x8(%esp)
f01043b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043bb:	c7 04 24 a4 79 10 f0 	movl   $0xf01079a4,(%esp)
f01043c2:	e8 65 fd ff ff       	call   f010412c <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01043c7:	3b 1d 60 ba 22 f0    	cmp    0xf022ba60,%ebx
f01043cd:	75 19                	jne    f01043e8 <print_trapframe+0xb9>
f01043cf:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01043d3:	75 13                	jne    f01043e8 <print_trapframe+0xb9>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01043d5:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01043d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043dc:	c7 04 24 b6 79 10 f0 	movl   $0xf01079b6,(%esp)
f01043e3:	e8 44 fd ff ff       	call   f010412c <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f01043e8:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01043eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043ef:	c7 04 24 c5 79 10 f0 	movl   $0xf01079c5,(%esp)
f01043f6:	e8 31 fd ff ff       	call   f010412c <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01043fb:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01043ff:	75 51                	jne    f0104452 <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0104401:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0104404:	89 c2                	mov    %eax,%edx
f0104406:	83 e2 01             	and    $0x1,%edx
f0104409:	ba 39 79 10 f0       	mov    $0xf0107939,%edx
f010440e:	b9 44 79 10 f0       	mov    $0xf0107944,%ecx
f0104413:	0f 45 ca             	cmovne %edx,%ecx
f0104416:	89 c2                	mov    %eax,%edx
f0104418:	83 e2 02             	and    $0x2,%edx
f010441b:	ba 50 79 10 f0       	mov    $0xf0107950,%edx
f0104420:	be 56 79 10 f0       	mov    $0xf0107956,%esi
f0104425:	0f 44 d6             	cmove  %esi,%edx
f0104428:	83 e0 04             	and    $0x4,%eax
f010442b:	b8 5b 79 10 f0       	mov    $0xf010795b,%eax
f0104430:	be ac 7a 10 f0       	mov    $0xf0107aac,%esi
f0104435:	0f 44 c6             	cmove  %esi,%eax
f0104438:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010443c:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104440:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104444:	c7 04 24 d3 79 10 f0 	movl   $0xf01079d3,(%esp)
f010444b:	e8 dc fc ff ff       	call   f010412c <cprintf>
f0104450:	eb 0c                	jmp    f010445e <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0104452:	c7 04 24 32 7d 10 f0 	movl   $0xf0107d32,(%esp)
f0104459:	e8 ce fc ff ff       	call   f010412c <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010445e:	8b 43 30             	mov    0x30(%ebx),%eax
f0104461:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104465:	c7 04 24 e2 79 10 f0 	movl   $0xf01079e2,(%esp)
f010446c:	e8 bb fc ff ff       	call   f010412c <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0104471:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104475:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104479:	c7 04 24 f1 79 10 f0 	movl   $0xf01079f1,(%esp)
f0104480:	e8 a7 fc ff ff       	call   f010412c <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0104485:	8b 43 38             	mov    0x38(%ebx),%eax
f0104488:	89 44 24 04          	mov    %eax,0x4(%esp)
f010448c:	c7 04 24 04 7a 10 f0 	movl   $0xf0107a04,(%esp)
f0104493:	e8 94 fc ff ff       	call   f010412c <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104498:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f010449c:	74 27                	je     f01044c5 <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010449e:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01044a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044a5:	c7 04 24 13 7a 10 f0 	movl   $0xf0107a13,(%esp)
f01044ac:	e8 7b fc ff ff       	call   f010412c <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01044b1:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01044b5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044b9:	c7 04 24 22 7a 10 f0 	movl   $0xf0107a22,(%esp)
f01044c0:	e8 67 fc ff ff       	call   f010412c <cprintf>
	}
}
f01044c5:	83 c4 10             	add    $0x10,%esp
f01044c8:	5b                   	pop    %ebx
f01044c9:	5e                   	pop    %esi
f01044ca:	5d                   	pop    %ebp
f01044cb:	c3                   	ret    

f01044cc <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01044cc:	55                   	push   %ebp
f01044cd:	89 e5                	mov    %esp,%ebp
f01044cf:	57                   	push   %edi
f01044d0:	56                   	push   %esi
f01044d1:	53                   	push   %ebx
f01044d2:	83 ec 1c             	sub    $0x1c,%esp
f01044d5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01044d8:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f01044db:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f01044df:	75 20                	jne    f0104501 <page_fault_handler+0x35>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f01044e1:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01044e5:	c7 44 24 08 f8 7b 10 	movl   $0xf0107bf8,0x8(%esp)
f01044ec:	f0 
f01044ed:	c7 44 24 04 4c 01 00 	movl   $0x14c,0x4(%esp)
f01044f4:	00 
f01044f5:	c7 04 24 35 7a 10 f0 	movl   $0xf0107a35,(%esp)
f01044fc:	e8 3f bb ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104501:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f0104504:	e8 e0 18 00 00       	call   f0105de9 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104509:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010450d:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0104511:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0104514:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010451a:	8b 40 48             	mov    0x48(%eax),%eax
f010451d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104521:	c7 04 24 20 7c 10 f0 	movl   $0xf0107c20,(%esp)
f0104528:	e8 ff fb ff ff       	call   f010412c <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f010452d:	89 1c 24             	mov    %ebx,(%esp)
f0104530:	e8 fa fd ff ff       	call   f010432f <print_trapframe>
	env_destroy(curenv);
f0104535:	e8 af 18 00 00       	call   f0105de9 <cpunum>
f010453a:	6b c0 74             	imul   $0x74,%eax,%eax
f010453d:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104543:	89 04 24             	mov    %eax,(%esp)
f0104546:	e8 06 f9 ff ff       	call   f0103e51 <env_destroy>
}
f010454b:	83 c4 1c             	add    $0x1c,%esp
f010454e:	5b                   	pop    %ebx
f010454f:	5e                   	pop    %esi
f0104550:	5f                   	pop    %edi
f0104551:	5d                   	pop    %ebp
f0104552:	c3                   	ret    

f0104553 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0104553:	55                   	push   %ebp
f0104554:	89 e5                	mov    %esp,%ebp
f0104556:	57                   	push   %edi
f0104557:	56                   	push   %esi
f0104558:	83 ec 20             	sub    $0x20,%esp
f010455b:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010455e:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f010455f:	83 3d 80 be 22 f0 00 	cmpl   $0x0,0xf022be80
f0104566:	74 01                	je     f0104569 <trap+0x16>
		asm volatile("hlt");
f0104568:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0104569:	e8 7b 18 00 00       	call   f0105de9 <cpunum>
f010456e:	6b d0 74             	imul   $0x74,%eax,%edx
f0104571:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104577:	b8 01 00 00 00       	mov    $0x1,%eax
f010457c:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0104580:	83 f8 02             	cmp    $0x2,%eax
f0104583:	75 0c                	jne    f0104591 <trap+0x3e>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104585:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f010458c:	e8 d6 1a 00 00       	call   f0106067 <spin_lock>

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0104591:	9c                   	pushf  
f0104592:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104593:	f6 c4 02             	test   $0x2,%ah
f0104596:	74 24                	je     f01045bc <trap+0x69>
f0104598:	c7 44 24 0c 41 7a 10 	movl   $0xf0107a41,0xc(%esp)
f010459f:	f0 
f01045a0:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01045a7:	f0 
f01045a8:	c7 44 24 04 12 01 00 	movl   $0x112,0x4(%esp)
f01045af:	00 
f01045b0:	c7 04 24 35 7a 10 f0 	movl   $0xf0107a35,(%esp)
f01045b7:	e8 84 ba ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f01045bc:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01045c0:	83 e0 03             	and    $0x3,%eax
f01045c3:	66 83 f8 03          	cmp    $0x3,%ax
f01045c7:	0f 85 a7 00 00 00    	jne    f0104674 <trap+0x121>
f01045cd:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f01045d4:	e8 8e 1a 00 00       	call   f0106067 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f01045d9:	e8 0b 18 00 00       	call   f0105de9 <cpunum>
f01045de:	6b c0 74             	imul   $0x74,%eax,%eax
f01045e1:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f01045e8:	75 24                	jne    f010460e <trap+0xbb>
f01045ea:	c7 44 24 0c 5a 7a 10 	movl   $0xf0107a5a,0xc(%esp)
f01045f1:	f0 
f01045f2:	c7 44 24 08 7b 74 10 	movl   $0xf010747b,0x8(%esp)
f01045f9:	f0 
f01045fa:	c7 44 24 04 1a 01 00 	movl   $0x11a,0x4(%esp)
f0104601:	00 
f0104602:	c7 04 24 35 7a 10 f0 	movl   $0xf0107a35,(%esp)
f0104609:	e8 32 ba ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f010460e:	e8 d6 17 00 00       	call   f0105de9 <cpunum>
f0104613:	6b c0 74             	imul   $0x74,%eax,%eax
f0104616:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010461c:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0104620:	75 2d                	jne    f010464f <trap+0xfc>
			env_free(curenv);
f0104622:	e8 c2 17 00 00       	call   f0105de9 <cpunum>
f0104627:	6b c0 74             	imul   $0x74,%eax,%eax
f010462a:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104630:	89 04 24             	mov    %eax,(%esp)
f0104633:	e8 14 f6 ff ff       	call   f0103c4c <env_free>
			curenv = NULL;
f0104638:	e8 ac 17 00 00       	call   f0105de9 <cpunum>
f010463d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104640:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f0104647:	00 00 00 
			sched_yield();
f010464a:	e8 d7 02 00 00       	call   f0104926 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010464f:	e8 95 17 00 00       	call   f0105de9 <cpunum>
f0104654:	6b c0 74             	imul   $0x74,%eax,%eax
f0104657:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010465d:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104662:	89 c7                	mov    %eax,%edi
f0104664:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0104666:	e8 7e 17 00 00       	call   f0105de9 <cpunum>
f010466b:	6b c0 74             	imul   $0x74,%eax,%eax
f010466e:	8b b0 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104674:	89 35 60 ba 22 f0    	mov    %esi,0xf022ba60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f010467a:	8b 46 28             	mov    0x28(%esi),%eax
f010467d:	83 f8 0e             	cmp    $0xe,%eax
f0104680:	74 20                	je     f01046a2 <trap+0x14f>
f0104682:	83 f8 30             	cmp    $0x30,%eax
f0104685:	74 25                	je     f01046ac <trap+0x159>
f0104687:	83 f8 03             	cmp    $0x3,%eax
f010468a:	75 52                	jne    f01046de <trap+0x18b>
		case T_BRKPT:
			monitor(tf);
f010468c:	89 34 24             	mov    %esi,(%esp)
f010468f:	e8 11 c3 ff ff       	call   f01009a5 <monitor>
			cprintf("return from breakpoint....\n");
f0104694:	c7 04 24 61 7a 10 f0 	movl   $0xf0107a61,(%esp)
f010469b:	e8 8c fa ff ff       	call   f010412c <cprintf>
f01046a0:	eb 3c                	jmp    f01046de <trap+0x18b>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f01046a2:	89 34 24             	mov    %esi,(%esp)
f01046a5:	e8 22 fe ff ff       	call   f01044cc <page_fault_handler>
f01046aa:	eb 32                	jmp    f01046de <trap+0x18b>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f01046ac:	8b 46 04             	mov    0x4(%esi),%eax
f01046af:	89 44 24 14          	mov    %eax,0x14(%esp)
f01046b3:	8b 06                	mov    (%esi),%eax
f01046b5:	89 44 24 10          	mov    %eax,0x10(%esp)
f01046b9:	8b 46 10             	mov    0x10(%esi),%eax
f01046bc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01046c0:	8b 46 18             	mov    0x18(%esi),%eax
f01046c3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01046c7:	8b 46 14             	mov    0x14(%esi),%eax
f01046ca:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046ce:	8b 46 1c             	mov    0x1c(%esi),%eax
f01046d1:	89 04 24             	mov    %eax,(%esp)
f01046d4:	e8 37 03 00 00       	call   f0104a10 <syscall>
f01046d9:	89 46 1c             	mov    %eax,0x1c(%esi)
f01046dc:	eb 5d                	jmp    f010473b <trap+0x1e8>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01046de:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f01046e2:	75 16                	jne    f01046fa <trap+0x1a7>
		cprintf("Spurious interrupt on irq 7\n");
f01046e4:	c7 04 24 7d 7a 10 f0 	movl   $0xf0107a7d,(%esp)
f01046eb:	e8 3c fa ff ff       	call   f010412c <cprintf>
		print_trapframe(tf);
f01046f0:	89 34 24             	mov    %esi,(%esp)
f01046f3:	e8 37 fc ff ff       	call   f010432f <print_trapframe>
f01046f8:	eb 41                	jmp    f010473b <trap+0x1e8>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01046fa:	89 34 24             	mov    %esi,(%esp)
f01046fd:	e8 2d fc ff ff       	call   f010432f <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0104702:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0104707:	75 1c                	jne    f0104725 <trap+0x1d2>
		panic("unhandled trap in kernel");
f0104709:	c7 44 24 08 9a 7a 10 	movl   $0xf0107a9a,0x8(%esp)
f0104710:	f0 
f0104711:	c7 44 24 04 f7 00 00 	movl   $0xf7,0x4(%esp)
f0104718:	00 
f0104719:	c7 04 24 35 7a 10 f0 	movl   $0xf0107a35,(%esp)
f0104720:	e8 1b b9 ff ff       	call   f0100040 <_panic>
	}
	else {
		env_destroy(curenv);
f0104725:	e8 bf 16 00 00       	call   f0105de9 <cpunum>
f010472a:	6b c0 74             	imul   $0x74,%eax,%eax
f010472d:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104733:	89 04 24             	mov    %eax,(%esp)
f0104736:	e8 16 f7 ff ff       	call   f0103e51 <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f010473b:	e8 a9 16 00 00       	call   f0105de9 <cpunum>
f0104740:	6b c0 74             	imul   $0x74,%eax,%eax
f0104743:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f010474a:	74 2a                	je     f0104776 <trap+0x223>
f010474c:	e8 98 16 00 00       	call   f0105de9 <cpunum>
f0104751:	6b c0 74             	imul   $0x74,%eax,%eax
f0104754:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010475a:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010475e:	75 16                	jne    f0104776 <trap+0x223>
		env_run(curenv);
f0104760:	e8 84 16 00 00       	call   f0105de9 <cpunum>
f0104765:	6b c0 74             	imul   $0x74,%eax,%eax
f0104768:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010476e:	89 04 24             	mov    %eax,(%esp)
f0104771:	e8 7c f7 ff ff       	call   f0103ef2 <env_run>
	else
		sched_yield();
f0104776:	e8 ab 01 00 00       	call   f0104926 <sched_yield>
f010477b:	90                   	nop

f010477c <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f010477c:	6a 00                	push   $0x0
f010477e:	6a 00                	push   $0x0
f0104780:	e9 ba 00 00 00       	jmp    f010483f <_alltraps>
f0104785:	90                   	nop

f0104786 <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0104786:	6a 00                	push   $0x0
f0104788:	6a 01                	push   $0x1
f010478a:	e9 b0 00 00 00       	jmp    f010483f <_alltraps>
f010478f:	90                   	nop

f0104790 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0104790:	6a 00                	push   $0x0
f0104792:	6a 02                	push   $0x2
f0104794:	e9 a6 00 00 00       	jmp    f010483f <_alltraps>
f0104799:	90                   	nop

f010479a <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f010479a:	6a 00                	push   $0x0
f010479c:	6a 03                	push   $0x3
f010479e:	e9 9c 00 00 00       	jmp    f010483f <_alltraps>
f01047a3:	90                   	nop

f01047a4 <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f01047a4:	6a 00                	push   $0x0
f01047a6:	6a 04                	push   $0x4
f01047a8:	e9 92 00 00 00       	jmp    f010483f <_alltraps>
f01047ad:	90                   	nop

f01047ae <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f01047ae:	6a 00                	push   $0x0
f01047b0:	6a 05                	push   $0x5
f01047b2:	e9 88 00 00 00       	jmp    f010483f <_alltraps>
f01047b7:	90                   	nop

f01047b8 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f01047b8:	6a 00                	push   $0x0
f01047ba:	6a 06                	push   $0x6
f01047bc:	e9 7e 00 00 00       	jmp    f010483f <_alltraps>
f01047c1:	90                   	nop

f01047c2 <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f01047c2:	6a 00                	push   $0x0
f01047c4:	6a 07                	push   $0x7
f01047c6:	e9 74 00 00 00       	jmp    f010483f <_alltraps>
f01047cb:	90                   	nop

f01047cc <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f01047cc:	6a 08                	push   $0x8
f01047ce:	e9 6c 00 00 00       	jmp    f010483f <_alltraps>
f01047d3:	90                   	nop

f01047d4 <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f01047d4:	6a 00                	push   $0x0
f01047d6:	6a 09                	push   $0x9
f01047d8:	e9 62 00 00 00       	jmp    f010483f <_alltraps>
f01047dd:	90                   	nop

f01047de <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f01047de:	6a 0a                	push   $0xa
f01047e0:	e9 5a 00 00 00       	jmp    f010483f <_alltraps>
f01047e5:	90                   	nop

f01047e6 <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f01047e6:	6a 0b                	push   $0xb
f01047e8:	e9 52 00 00 00       	jmp    f010483f <_alltraps>
f01047ed:	90                   	nop

f01047ee <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f01047ee:	6a 0c                	push   $0xc
f01047f0:	e9 4a 00 00 00       	jmp    f010483f <_alltraps>
f01047f5:	90                   	nop

f01047f6 <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f01047f6:	6a 0d                	push   $0xd
f01047f8:	e9 42 00 00 00       	jmp    f010483f <_alltraps>
f01047fd:	90                   	nop

f01047fe <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f01047fe:	6a 0e                	push   $0xe
f0104800:	e9 3a 00 00 00       	jmp    f010483f <_alltraps>
f0104805:	90                   	nop

f0104806 <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0104806:	6a 00                	push   $0x0
f0104808:	6a 0f                	push   $0xf
f010480a:	e9 30 00 00 00       	jmp    f010483f <_alltraps>
f010480f:	90                   	nop

f0104810 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0104810:	6a 00                	push   $0x0
f0104812:	6a 10                	push   $0x10
f0104814:	e9 26 00 00 00       	jmp    f010483f <_alltraps>
f0104819:	90                   	nop

f010481a <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f010481a:	6a 11                	push   $0x11
f010481c:	e9 1e 00 00 00       	jmp    f010483f <_alltraps>
f0104821:	90                   	nop

f0104822 <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0104822:	6a 00                	push   $0x0
f0104824:	6a 12                	push   $0x12
f0104826:	e9 14 00 00 00       	jmp    f010483f <_alltraps>
f010482b:	90                   	nop

f010482c <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f010482c:	6a 00                	push   $0x0
f010482e:	6a 13                	push   $0x13
f0104830:	e9 0a 00 00 00       	jmp    f010483f <_alltraps>
f0104835:	90                   	nop

f0104836 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f0104836:	6a 00                	push   $0x0
f0104838:	6a 30                	push   $0x30
f010483a:	e9 00 00 00 00       	jmp    f010483f <_alltraps>

f010483f <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f010483f:	1e                   	push   %ds
	push %es
f0104840:	06                   	push   %es
	pushal
f0104841:	60                   	pusha  

	
	movw $GD_KD, %ax
f0104842:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104846:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104848:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f010484a:	54                   	push   %esp
	call trap
f010484b:	e8 03 fd ff ff       	call   f0104553 <trap>

f0104850 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0104850:	55                   	push   %ebp
f0104851:	89 e5                	mov    %esp,%ebp
f0104853:	83 ec 18             	sub    $0x18,%esp
f0104856:	8b 15 4c b2 22 f0    	mov    0xf022b24c,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010485c:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0104861:	8b 4a 54             	mov    0x54(%edx),%ecx
f0104864:	83 e9 01             	sub    $0x1,%ecx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104867:	83 f9 02             	cmp    $0x2,%ecx
f010486a:	76 0f                	jbe    f010487b <sched_halt+0x2b>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f010486c:	83 c0 01             	add    $0x1,%eax
f010486f:	83 c2 7c             	add    $0x7c,%edx
f0104872:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104877:	75 e8                	jne    f0104861 <sched_halt+0x11>
f0104879:	eb 07                	jmp    f0104882 <sched_halt+0x32>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f010487b:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104880:	75 1a                	jne    f010489c <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f0104882:	c7 04 24 b0 7c 10 f0 	movl   $0xf0107cb0,(%esp)
f0104889:	e8 9e f8 ff ff       	call   f010412c <cprintf>
		while (1)
			monitor(NULL);
f010488e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104895:	e8 0b c1 ff ff       	call   f01009a5 <monitor>
f010489a:	eb f2                	jmp    f010488e <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f010489c:	e8 48 15 00 00       	call   f0105de9 <cpunum>
f01048a1:	6b c0 74             	imul   $0x74,%eax,%eax
f01048a4:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f01048ab:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f01048ae:	a1 8c be 22 f0       	mov    0xf022be8c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01048b3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01048b8:	77 20                	ja     f01048da <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01048ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01048be:	c7 44 24 08 08 65 10 	movl   $0xf0106508,0x8(%esp)
f01048c5:	f0 
f01048c6:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f01048cd:	00 
f01048ce:	c7 04 24 d9 7c 10 f0 	movl   $0xf0107cd9,(%esp)
f01048d5:	e8 66 b7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01048da:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01048df:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01048e2:	e8 02 15 00 00       	call   f0105de9 <cpunum>
f01048e7:	6b d0 74             	imul   $0x74,%eax,%edx
f01048ea:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01048f0:	b8 02 00 00 00       	mov    $0x2,%eax
f01048f5:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01048f9:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0104900:	e8 0e 18 00 00       	call   f0106113 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104905:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104907:	e8 dd 14 00 00       	call   f0105de9 <cpunum>
f010490c:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f010490f:	8b 80 30 c0 22 f0    	mov    -0xfdd3fd0(%eax),%eax
f0104915:	bd 00 00 00 00       	mov    $0x0,%ebp
f010491a:	89 c4                	mov    %eax,%esp
f010491c:	6a 00                	push   $0x0
f010491e:	6a 00                	push   $0x0
f0104920:	fb                   	sti    
f0104921:	f4                   	hlt    
f0104922:	eb fd                	jmp    f0104921 <sched_halt+0xd1>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104924:	c9                   	leave  
f0104925:	c3                   	ret    

f0104926 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0104926:	55                   	push   %ebp
f0104927:	89 e5                	mov    %esp,%ebp
f0104929:	53                   	push   %ebx
f010492a:	83 ec 14             	sub    $0x14,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f010492d:	e8 b7 14 00 00       	call   f0105de9 <cpunum>
f0104932:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f0104935:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f010493a:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0104941:	74 32                	je     f0104975 <sched_yield+0x4f>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f0104943:	e8 a1 14 00 00       	call   f0105de9 <cpunum>
f0104948:	6b c0 74             	imul   $0x74,%eax,%eax
f010494b:	8b 90 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%edx
f0104951:	2b 15 4c b2 22 f0    	sub    0xf022b24c,%edx
f0104957:	c1 fa 02             	sar    $0x2,%edx
f010495a:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0104960:	83 c2 01             	add    $0x1,%edx
f0104963:	89 d0                	mov    %edx,%eax
f0104965:	c1 f8 1f             	sar    $0x1f,%eax
f0104968:	c1 e8 16             	shr    $0x16,%eax
f010496b:	01 c2                	add    %eax,%edx
f010496d:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104973:	29 c2                	sub    %eax,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f0104975:	8b 1d 4c b2 22 f0    	mov    0xf022b24c,%ebx
f010497b:	b8 00 04 00 00       	mov    $0x400,%eax
f0104980:	6b ca 7c             	imul   $0x7c,%edx,%ecx
f0104983:	83 7c 0b 54 02       	cmpl   $0x2,0x54(%ebx,%ecx,1)
f0104988:	74 6f                	je     f01049f9 <sched_yield+0xd3>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f010498a:	83 c2 01             	add    $0x1,%edx
f010498d:	89 d1                	mov    %edx,%ecx
f010498f:	c1 f9 1f             	sar    $0x1f,%ecx
f0104992:	c1 e9 16             	shr    $0x16,%ecx
f0104995:	01 ca                	add    %ecx,%edx
f0104997:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f010499d:	29 ca                	sub    %ecx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f010499f:	83 e8 01             	sub    $0x1,%eax
f01049a2:	75 dc                	jne    f0104980 <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f01049a4:	6b d2 7c             	imul   $0x7c,%edx,%edx
f01049a7:	01 da                	add    %ebx,%edx
f01049a9:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f01049ad:	75 08                	jne    f01049b7 <sched_yield+0x91>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f01049af:	89 14 24             	mov    %edx,(%esp)
f01049b2:	e8 3b f5 ff ff       	call   f0103ef2 <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f01049b7:	e8 2d 14 00 00       	call   f0105de9 <cpunum>
f01049bc:	6b c0 74             	imul   $0x74,%eax,%eax
f01049bf:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f01049c6:	74 2a                	je     f01049f2 <sched_yield+0xcc>
f01049c8:	e8 1c 14 00 00       	call   f0105de9 <cpunum>
f01049cd:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d0:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01049d6:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01049da:	75 16                	jne    f01049f2 <sched_yield+0xcc>
	    env_run(curenv) ;
f01049dc:	e8 08 14 00 00       	call   f0105de9 <cpunum>
f01049e1:	6b c0 74             	imul   $0x74,%eax,%eax
f01049e4:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01049ea:	89 04 24             	mov    %eax,(%esp)
f01049ed:	e8 00 f5 ff ff       	call   f0103ef2 <env_run>
	}
	// sched_halt never returns
	sched_halt();
f01049f2:	e8 59 fe ff ff       	call   f0104850 <sched_halt>
f01049f7:	eb 09                	jmp    f0104a02 <sched_yield+0xdc>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f01049f9:	6b d2 7c             	imul   $0x7c,%edx,%edx
f01049fc:	01 da                	add    %ebx,%edx
f01049fe:	66 90                	xchg   %ax,%ax
f0104a00:	eb ad                	jmp    f01049af <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f0104a02:	83 c4 14             	add    $0x14,%esp
f0104a05:	5b                   	pop    %ebx
f0104a06:	5d                   	pop    %ebp
f0104a07:	c3                   	ret    
f0104a08:	66 90                	xchg   %ax,%ax
f0104a0a:	66 90                	xchg   %ax,%ax
f0104a0c:	66 90                	xchg   %ax,%ax
f0104a0e:	66 90                	xchg   %ax,%ax

f0104a10 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104a10:	55                   	push   %ebp
f0104a11:	89 e5                	mov    %esp,%ebp
f0104a13:	53                   	push   %ebx
f0104a14:	83 ec 24             	sub    $0x24,%esp
f0104a17:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f0104a1a:	83 f8 0a             	cmp    $0xa,%eax
f0104a1d:	0f 87 0f 01 00 00    	ja     f0104b32 <syscall+0x122>
f0104a23:	ff 24 85 44 7d 10 f0 	jmp    *-0xfef82bc(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f0104a2a:	e8 ba 13 00 00       	call   f0105de9 <cpunum>
f0104a2f:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104a36:	00 
f0104a37:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104a3a:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104a3e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104a41:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104a45:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a48:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104a4e:	89 04 24             	mov    %eax,(%esp)
f0104a51:	e8 c3 ec ff ff       	call   f0103719 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104a56:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104a59:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104a5d:	8b 45 10             	mov    0x10(%ebp),%eax
f0104a60:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a64:	c7 04 24 e6 7c 10 f0 	movl   $0xf0107ce6,(%esp)
f0104a6b:	e8 bc f6 ff ff       	call   f010412c <cprintf>

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f0104a70:	b8 00 00 00 00       	mov    $0x0,%eax
f0104a75:	e9 d4 00 00 00       	jmp    f0104b4e <syscall+0x13e>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104a7a:	e8 d6 bb ff ff       	call   f0100655 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0104a7f:	90                   	nop
f0104a80:	e9 c9 00 00 00       	jmp    f0104b4e <syscall+0x13e>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0104a85:	e8 5f 13 00 00       	call   f0105de9 <cpunum>
f0104a8a:	6b c0 74             	imul   $0x74,%eax,%eax
f0104a8d:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104a93:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0104a96:	e9 b3 00 00 00       	jmp    f0104b4e <syscall+0x13e>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104a9b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0104aa2:	00 
f0104aa3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0104aa6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104aaa:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104aad:	89 04 24             	mov    %eax,(%esp)
f0104ab0:	e8 57 ed ff ff       	call   f010380c <envid2env>
		return r;
f0104ab5:	89 c2                	mov    %eax,%edx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104ab7:	85 c0                	test   %eax,%eax
f0104ab9:	78 6e                	js     f0104b29 <syscall+0x119>
		return r;
	if (e == curenv)
f0104abb:	e8 29 13 00 00       	call   f0105de9 <cpunum>
f0104ac0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0104ac3:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ac6:	39 90 28 c0 22 f0    	cmp    %edx,-0xfdd3fd8(%eax)
f0104acc:	75 23                	jne    f0104af1 <syscall+0xe1>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104ace:	e8 16 13 00 00       	call   f0105de9 <cpunum>
f0104ad3:	6b c0 74             	imul   $0x74,%eax,%eax
f0104ad6:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104adc:	8b 40 48             	mov    0x48(%eax),%eax
f0104adf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ae3:	c7 04 24 eb 7c 10 f0 	movl   $0xf0107ceb,(%esp)
f0104aea:	e8 3d f6 ff ff       	call   f010412c <cprintf>
f0104aef:	eb 28                	jmp    f0104b19 <syscall+0x109>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104af1:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104af4:	e8 f0 12 00 00       	call   f0105de9 <cpunum>
f0104af9:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0104afd:	6b c0 74             	imul   $0x74,%eax,%eax
f0104b00:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104b06:	8b 40 48             	mov    0x48(%eax),%eax
f0104b09:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104b0d:	c7 04 24 06 7d 10 f0 	movl   $0xf0107d06,(%esp)
f0104b14:	e8 13 f6 ff ff       	call   f010412c <cprintf>
	env_destroy(e);
f0104b19:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104b1c:	89 04 24             	mov    %eax,(%esp)
f0104b1f:	e8 2d f3 ff ff       	call   f0103e51 <env_destroy>
	return 0;
f0104b24:	ba 00 00 00 00       	mov    $0x0,%edx
		
	case SYS_getenvid:
		return sys_getenvid();
		
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f0104b29:	89 d0                	mov    %edx,%eax
f0104b2b:	eb 21                	jmp    f0104b4e <syscall+0x13e>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104b2d:	e8 f4 fd ff ff       	call   f0104926 <sched_yield>
	
	case SYS_yield:
		sys_yield();
		
	default:
		panic("Invalid System Call \n");
f0104b32:	c7 44 24 08 1e 7d 10 	movl   $0xf0107d1e,0x8(%esp)
f0104b39:	f0 
f0104b3a:	c7 44 24 04 27 01 00 	movl   $0x127,0x4(%esp)
f0104b41:	00 
f0104b42:	c7 04 24 34 7d 10 f0 	movl   $0xf0107d34,(%esp)
f0104b49:	e8 f2 b4 ff ff       	call   f0100040 <_panic>
		return -E_INVAL;
	}
}
f0104b4e:	83 c4 24             	add    $0x24,%esp
f0104b51:	5b                   	pop    %ebx
f0104b52:	5d                   	pop    %ebp
f0104b53:	c3                   	ret    

f0104b54 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104b54:	55                   	push   %ebp
f0104b55:	89 e5                	mov    %esp,%ebp
f0104b57:	57                   	push   %edi
f0104b58:	56                   	push   %esi
f0104b59:	53                   	push   %ebx
f0104b5a:	83 ec 14             	sub    $0x14,%esp
f0104b5d:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104b60:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104b63:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104b66:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104b69:	8b 1a                	mov    (%edx),%ebx
f0104b6b:	8b 01                	mov    (%ecx),%eax
f0104b6d:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104b70:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104b77:	e9 88 00 00 00       	jmp    f0104c04 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104b7c:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104b7f:	01 d8                	add    %ebx,%eax
f0104b81:	89 c7                	mov    %eax,%edi
f0104b83:	c1 ef 1f             	shr    $0x1f,%edi
f0104b86:	01 c7                	add    %eax,%edi
f0104b88:	d1 ff                	sar    %edi
f0104b8a:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104b8d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104b90:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104b93:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104b95:	eb 03                	jmp    f0104b9a <stab_binsearch+0x46>
			m--;
f0104b97:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104b9a:	39 c3                	cmp    %eax,%ebx
f0104b9c:	7f 1f                	jg     f0104bbd <stab_binsearch+0x69>
f0104b9e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104ba2:	83 ea 0c             	sub    $0xc,%edx
f0104ba5:	39 f1                	cmp    %esi,%ecx
f0104ba7:	75 ee                	jne    f0104b97 <stab_binsearch+0x43>
f0104ba9:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104bac:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104baf:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104bb2:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104bb6:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104bb9:	76 18                	jbe    f0104bd3 <stab_binsearch+0x7f>
f0104bbb:	eb 05                	jmp    f0104bc2 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104bbd:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104bc0:	eb 42                	jmp    f0104c04 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104bc2:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104bc5:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104bc7:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104bca:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104bd1:	eb 31                	jmp    f0104c04 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104bd3:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104bd6:	73 17                	jae    f0104bef <stab_binsearch+0x9b>
			*region_right = m - 1;
f0104bd8:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104bdb:	83 e8 01             	sub    $0x1,%eax
f0104bde:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104be1:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104be4:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104be6:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104bed:	eb 15                	jmp    f0104c04 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104bef:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104bf2:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0104bf5:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0104bf7:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104bfb:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104bfd:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104c04:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104c07:	0f 8e 6f ff ff ff    	jle    f0104b7c <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104c0d:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104c11:	75 0f                	jne    f0104c22 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104c13:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104c16:	8b 00                	mov    (%eax),%eax
f0104c18:	83 e8 01             	sub    $0x1,%eax
f0104c1b:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104c1e:	89 07                	mov    %eax,(%edi)
f0104c20:	eb 2c                	jmp    f0104c4e <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104c22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104c25:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104c27:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c2a:	8b 0f                	mov    (%edi),%ecx
f0104c2c:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104c2f:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104c32:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104c35:	eb 03                	jmp    f0104c3a <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104c37:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104c3a:	39 c8                	cmp    %ecx,%eax
f0104c3c:	7e 0b                	jle    f0104c49 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104c3e:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104c42:	83 ea 0c             	sub    $0xc,%edx
f0104c45:	39 f3                	cmp    %esi,%ebx
f0104c47:	75 ee                	jne    f0104c37 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104c49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104c4c:	89 07                	mov    %eax,(%edi)
	}
}
f0104c4e:	83 c4 14             	add    $0x14,%esp
f0104c51:	5b                   	pop    %ebx
f0104c52:	5e                   	pop    %esi
f0104c53:	5f                   	pop    %edi
f0104c54:	5d                   	pop    %ebp
f0104c55:	c3                   	ret    

f0104c56 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104c56:	55                   	push   %ebp
f0104c57:	89 e5                	mov    %esp,%ebp
f0104c59:	57                   	push   %edi
f0104c5a:	56                   	push   %esi
f0104c5b:	53                   	push   %ebx
f0104c5c:	83 ec 4c             	sub    $0x4c,%esp
f0104c5f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104c62:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104c65:	c7 07 70 7d 10 f0    	movl   $0xf0107d70,(%edi)
	info->eip_line = 0;
f0104c6b:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0104c72:	c7 47 08 70 7d 10 f0 	movl   $0xf0107d70,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104c79:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0104c80:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0104c83:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104c8a:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0104c90:	0f 87 cf 00 00 00    	ja     f0104d65 <debuginfo_eip+0x10f>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f0104c96:	e8 4e 11 00 00       	call   f0105de9 <cpunum>
f0104c9b:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104ca2:	00 
f0104ca3:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0104caa:	00 
f0104cab:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0104cb2:	00 
f0104cb3:	6b c0 74             	imul   $0x74,%eax,%eax
f0104cb6:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104cbc:	89 04 24             	mov    %eax,(%esp)
f0104cbf:	e8 50 e9 ff ff       	call   f0103614 <user_mem_check>
f0104cc4:	85 c0                	test   %eax,%eax
f0104cc6:	0f 88 5f 02 00 00    	js     f0104f2b <debuginfo_eip+0x2d5>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f0104ccc:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0104cd1:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104cd7:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104cdd:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104ce0:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104ce6:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f0104ce9:	89 f2                	mov    %esi,%edx
f0104ceb:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0104cee:	29 c2                	sub    %eax,%edx
f0104cf0:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104cf3:	e8 f1 10 00 00       	call   f0105de9 <cpunum>
f0104cf8:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104cff:	00 
f0104d00:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104d03:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104d07:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104d0a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104d0e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d11:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104d17:	89 04 24             	mov    %eax,(%esp)
f0104d1a:	e8 f5 e8 ff ff       	call   f0103614 <user_mem_check>
f0104d1f:	85 c0                	test   %eax,%eax
f0104d21:	0f 88 0b 02 00 00    	js     f0104f32 <debuginfo_eip+0x2dc>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f0104d27:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104d2a:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104d2d:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104d30:	e8 b4 10 00 00       	call   f0105de9 <cpunum>
f0104d35:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104d3c:	00 
f0104d3d:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104d40:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104d44:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104d47:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104d4b:	6b c0 74             	imul   $0x74,%eax,%eax
f0104d4e:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104d54:	89 04 24             	mov    %eax,(%esp)
f0104d57:	e8 b8 e8 ff ff       	call   f0103614 <user_mem_check>
f0104d5c:	85 c0                	test   %eax,%eax
f0104d5e:	79 1f                	jns    f0104d7f <debuginfo_eip+0x129>
f0104d60:	e9 d4 01 00 00       	jmp    f0104f39 <debuginfo_eip+0x2e3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104d65:	c7 45 bc 08 59 11 f0 	movl   $0xf0115908,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104d6c:	c7 45 c0 85 22 11 f0 	movl   $0xf0112285,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104d73:	be 84 22 11 f0       	mov    $0xf0112284,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104d78:	c7 45 c4 58 82 10 f0 	movl   $0xf0108258,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104d7f:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104d82:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104d85:	0f 83 b5 01 00 00    	jae    f0104f40 <debuginfo_eip+0x2ea>
f0104d8b:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104d8f:	0f 85 b2 01 00 00    	jne    f0104f47 <debuginfo_eip+0x2f1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104d95:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104d9c:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f0104d9f:	c1 fe 02             	sar    $0x2,%esi
f0104da2:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104da8:	83 e8 01             	sub    $0x1,%eax
f0104dab:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104dae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104db2:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0104db9:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104dbc:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104dbf:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104dc2:	89 f0                	mov    %esi,%eax
f0104dc4:	e8 8b fd ff ff       	call   f0104b54 <stab_binsearch>
	if (lfile == 0)
f0104dc9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104dcc:	85 c0                	test   %eax,%eax
f0104dce:	0f 84 7a 01 00 00    	je     f0104f4e <debuginfo_eip+0x2f8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104dd4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104dd7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104dda:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104ddd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104de1:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104de8:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104deb:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104dee:	89 f0                	mov    %esi,%eax
f0104df0:	e8 5f fd ff ff       	call   f0104b54 <stab_binsearch>

	if (lfun <= rfun) {
f0104df5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104df8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0104dfb:	39 f0                	cmp    %esi,%eax
f0104dfd:	7f 32                	jg     f0104e31 <debuginfo_eip+0x1db>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104dff:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104e02:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104e05:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f0104e08:	8b 0a                	mov    (%edx),%ecx
f0104e0a:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f0104e0d:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104e10:	2b 4d c0             	sub    -0x40(%ebp),%ecx
f0104e13:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f0104e16:	73 09                	jae    f0104e21 <debuginfo_eip+0x1cb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104e18:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104e1b:	03 4d c0             	add    -0x40(%ebp),%ecx
f0104e1e:	89 4f 08             	mov    %ecx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104e21:	8b 52 08             	mov    0x8(%edx),%edx
f0104e24:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104e27:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f0104e29:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104e2c:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0104e2f:	eb 0f                	jmp    f0104e40 <debuginfo_eip+0x1ea>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104e31:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0104e34:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104e37:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104e3a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e3d:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104e40:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104e47:	00 
f0104e48:	8b 47 08             	mov    0x8(%edi),%eax
f0104e4b:	89 04 24             	mov    %eax,(%esp)
f0104e4e:	e8 28 09 00 00       	call   f010577b <strfind>
f0104e53:	2b 47 08             	sub    0x8(%edi),%eax
f0104e56:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0104e59:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104e5d:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0104e64:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104e67:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104e6a:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104e6d:	89 f0                	mov    %esi,%eax
f0104e6f:	e8 e0 fc ff ff       	call   f0104b54 <stab_binsearch>
	if (lline > rline) {
f0104e74:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104e77:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104e7a:	0f 8f d5 00 00 00    	jg     f0104f55 <debuginfo_eip+0x2ff>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104e80:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104e83:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0104e88:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104e8b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104e8e:	89 c3                	mov    %eax,%ebx
f0104e90:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104e93:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104e96:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104e99:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104e9c:	89 df                	mov    %ebx,%edi
f0104e9e:	eb 06                	jmp    f0104ea6 <debuginfo_eip+0x250>
f0104ea0:	83 e8 01             	sub    $0x1,%eax
f0104ea3:	83 ea 0c             	sub    $0xc,%edx
f0104ea6:	89 c6                	mov    %eax,%esi
f0104ea8:	39 c7                	cmp    %eax,%edi
f0104eaa:	7f 3c                	jg     f0104ee8 <debuginfo_eip+0x292>
	       && stabs[lline].n_type != N_SOL
f0104eac:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104eb0:	80 f9 84             	cmp    $0x84,%cl
f0104eb3:	75 08                	jne    f0104ebd <debuginfo_eip+0x267>
f0104eb5:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104eb8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104ebb:	eb 11                	jmp    f0104ece <debuginfo_eip+0x278>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104ebd:	80 f9 64             	cmp    $0x64,%cl
f0104ec0:	75 de                	jne    f0104ea0 <debuginfo_eip+0x24a>
f0104ec2:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104ec6:	74 d8                	je     f0104ea0 <debuginfo_eip+0x24a>
f0104ec8:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104ecb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104ece:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104ed1:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104ed4:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0104ed7:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104eda:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104edd:	39 d0                	cmp    %edx,%eax
f0104edf:	73 0a                	jae    f0104eeb <debuginfo_eip+0x295>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104ee1:	03 45 c0             	add    -0x40(%ebp),%eax
f0104ee4:	89 07                	mov    %eax,(%edi)
f0104ee6:	eb 03                	jmp    f0104eeb <debuginfo_eip+0x295>
f0104ee8:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104eeb:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104eee:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104ef1:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104ef6:	39 da                	cmp    %ebx,%edx
f0104ef8:	7d 67                	jge    f0104f61 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
f0104efa:	83 c2 01             	add    $0x1,%edx
f0104efd:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104f00:	89 d0                	mov    %edx,%eax
f0104f02:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104f05:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104f08:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104f0b:	eb 04                	jmp    f0104f11 <debuginfo_eip+0x2bb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104f0d:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104f11:	39 c3                	cmp    %eax,%ebx
f0104f13:	7e 47                	jle    f0104f5c <debuginfo_eip+0x306>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104f15:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104f19:	83 c0 01             	add    $0x1,%eax
f0104f1c:	83 c2 0c             	add    $0xc,%edx
f0104f1f:	80 f9 a0             	cmp    $0xa0,%cl
f0104f22:	74 e9                	je     f0104f0d <debuginfo_eip+0x2b7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104f24:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f29:	eb 36                	jmp    f0104f61 <debuginfo_eip+0x30b>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104f2b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104f30:	eb 2f                	jmp    f0104f61 <debuginfo_eip+0x30b>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104f32:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104f37:	eb 28                	jmp    f0104f61 <debuginfo_eip+0x30b>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0104f39:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104f3e:	eb 21                	jmp    f0104f61 <debuginfo_eip+0x30b>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104f40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104f45:	eb 1a                	jmp    f0104f61 <debuginfo_eip+0x30b>
f0104f47:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104f4c:	eb 13                	jmp    f0104f61 <debuginfo_eip+0x30b>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104f4e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104f53:	eb 0c                	jmp    f0104f61 <debuginfo_eip+0x30b>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0104f55:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104f5a:	eb 05                	jmp    f0104f61 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104f5c:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104f61:	83 c4 4c             	add    $0x4c,%esp
f0104f64:	5b                   	pop    %ebx
f0104f65:	5e                   	pop    %esi
f0104f66:	5f                   	pop    %edi
f0104f67:	5d                   	pop    %ebp
f0104f68:	c3                   	ret    
f0104f69:	66 90                	xchg   %ax,%ax
f0104f6b:	66 90                	xchg   %ax,%ax
f0104f6d:	66 90                	xchg   %ax,%ax
f0104f6f:	90                   	nop

f0104f70 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104f70:	55                   	push   %ebp
f0104f71:	89 e5                	mov    %esp,%ebp
f0104f73:	57                   	push   %edi
f0104f74:	56                   	push   %esi
f0104f75:	53                   	push   %ebx
f0104f76:	83 ec 3c             	sub    $0x3c,%esp
f0104f79:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104f7c:	89 d7                	mov    %edx,%edi
f0104f7e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f81:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104f84:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104f87:	89 c3                	mov    %eax,%ebx
f0104f89:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104f8c:	8b 45 10             	mov    0x10(%ebp),%eax
f0104f8f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104f92:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104f97:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104f9a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104f9d:	39 d9                	cmp    %ebx,%ecx
f0104f9f:	72 05                	jb     f0104fa6 <printnum+0x36>
f0104fa1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0104fa4:	77 69                	ja     f010500f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104fa6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104fa9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104fad:	83 ee 01             	sub    $0x1,%esi
f0104fb0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104fb4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104fb8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104fbc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104fc0:	89 c3                	mov    %eax,%ebx
f0104fc2:	89 d6                	mov    %edx,%esi
f0104fc4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104fc7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104fca:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104fce:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104fd2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104fd5:	89 04 24             	mov    %eax,(%esp)
f0104fd8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104fdb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104fdf:	e8 4c 12 00 00       	call   f0106230 <__udivdi3>
f0104fe4:	89 d9                	mov    %ebx,%ecx
f0104fe6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104fea:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104fee:	89 04 24             	mov    %eax,(%esp)
f0104ff1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104ff5:	89 fa                	mov    %edi,%edx
f0104ff7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ffa:	e8 71 ff ff ff       	call   f0104f70 <printnum>
f0104fff:	eb 1b                	jmp    f010501c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0105001:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105005:	8b 45 18             	mov    0x18(%ebp),%eax
f0105008:	89 04 24             	mov    %eax,(%esp)
f010500b:	ff d3                	call   *%ebx
f010500d:	eb 03                	jmp    f0105012 <printnum+0xa2>
f010500f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0105012:	83 ee 01             	sub    $0x1,%esi
f0105015:	85 f6                	test   %esi,%esi
f0105017:	7f e8                	jg     f0105001 <printnum+0x91>
f0105019:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010501c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105020:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105024:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0105027:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010502a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010502e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0105032:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0105035:	89 04 24             	mov    %eax,(%esp)
f0105038:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010503b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010503f:	e8 1c 13 00 00       	call   f0106360 <__umoddi3>
f0105044:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105048:	0f be 80 7a 7d 10 f0 	movsbl -0xfef8286(%eax),%eax
f010504f:	89 04 24             	mov    %eax,(%esp)
f0105052:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105055:	ff d0                	call   *%eax
}
f0105057:	83 c4 3c             	add    $0x3c,%esp
f010505a:	5b                   	pop    %ebx
f010505b:	5e                   	pop    %esi
f010505c:	5f                   	pop    %edi
f010505d:	5d                   	pop    %ebp
f010505e:	c3                   	ret    

f010505f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010505f:	55                   	push   %ebp
f0105060:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0105062:	83 fa 01             	cmp    $0x1,%edx
f0105065:	7e 0e                	jle    f0105075 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0105067:	8b 10                	mov    (%eax),%edx
f0105069:	8d 4a 08             	lea    0x8(%edx),%ecx
f010506c:	89 08                	mov    %ecx,(%eax)
f010506e:	8b 02                	mov    (%edx),%eax
f0105070:	8b 52 04             	mov    0x4(%edx),%edx
f0105073:	eb 22                	jmp    f0105097 <getuint+0x38>
	else if (lflag)
f0105075:	85 d2                	test   %edx,%edx
f0105077:	74 10                	je     f0105089 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0105079:	8b 10                	mov    (%eax),%edx
f010507b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010507e:	89 08                	mov    %ecx,(%eax)
f0105080:	8b 02                	mov    (%edx),%eax
f0105082:	ba 00 00 00 00       	mov    $0x0,%edx
f0105087:	eb 0e                	jmp    f0105097 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0105089:	8b 10                	mov    (%eax),%edx
f010508b:	8d 4a 04             	lea    0x4(%edx),%ecx
f010508e:	89 08                	mov    %ecx,(%eax)
f0105090:	8b 02                	mov    (%edx),%eax
f0105092:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0105097:	5d                   	pop    %ebp
f0105098:	c3                   	ret    

f0105099 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0105099:	55                   	push   %ebp
f010509a:	89 e5                	mov    %esp,%ebp
f010509c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010509f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01050a3:	8b 10                	mov    (%eax),%edx
f01050a5:	3b 50 04             	cmp    0x4(%eax),%edx
f01050a8:	73 0a                	jae    f01050b4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01050aa:	8d 4a 01             	lea    0x1(%edx),%ecx
f01050ad:	89 08                	mov    %ecx,(%eax)
f01050af:	8b 45 08             	mov    0x8(%ebp),%eax
f01050b2:	88 02                	mov    %al,(%edx)
}
f01050b4:	5d                   	pop    %ebp
f01050b5:	c3                   	ret    

f01050b6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01050b6:	55                   	push   %ebp
f01050b7:	89 e5                	mov    %esp,%ebp
f01050b9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01050bc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01050bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01050c3:	8b 45 10             	mov    0x10(%ebp),%eax
f01050c6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01050ca:	8b 45 0c             	mov    0xc(%ebp),%eax
f01050cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01050d1:	8b 45 08             	mov    0x8(%ebp),%eax
f01050d4:	89 04 24             	mov    %eax,(%esp)
f01050d7:	e8 02 00 00 00       	call   f01050de <vprintfmt>
	va_end(ap);
}
f01050dc:	c9                   	leave  
f01050dd:	c3                   	ret    

f01050de <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01050de:	55                   	push   %ebp
f01050df:	89 e5                	mov    %esp,%ebp
f01050e1:	57                   	push   %edi
f01050e2:	56                   	push   %esi
f01050e3:	53                   	push   %ebx
f01050e4:	83 ec 3c             	sub    $0x3c,%esp
f01050e7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01050ea:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01050ed:	eb 14                	jmp    f0105103 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01050ef:	85 c0                	test   %eax,%eax
f01050f1:	0f 84 b3 03 00 00    	je     f01054aa <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f01050f7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01050fb:	89 04 24             	mov    %eax,(%esp)
f01050fe:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0105101:	89 f3                	mov    %esi,%ebx
f0105103:	8d 73 01             	lea    0x1(%ebx),%esi
f0105106:	0f b6 03             	movzbl (%ebx),%eax
f0105109:	83 f8 25             	cmp    $0x25,%eax
f010510c:	75 e1                	jne    f01050ef <vprintfmt+0x11>
f010510e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0105112:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0105119:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0105120:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105127:	ba 00 00 00 00       	mov    $0x0,%edx
f010512c:	eb 1d                	jmp    f010514b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010512e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105130:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0105134:	eb 15                	jmp    f010514b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105136:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0105138:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010513c:	eb 0d                	jmp    f010514b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010513e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105141:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105144:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010514b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010514e:	0f b6 0e             	movzbl (%esi),%ecx
f0105151:	0f b6 c1             	movzbl %cl,%eax
f0105154:	83 e9 23             	sub    $0x23,%ecx
f0105157:	80 f9 55             	cmp    $0x55,%cl
f010515a:	0f 87 2a 03 00 00    	ja     f010548a <vprintfmt+0x3ac>
f0105160:	0f b6 c9             	movzbl %cl,%ecx
f0105163:	ff 24 8d 40 7e 10 f0 	jmp    *-0xfef81c0(,%ecx,4)
f010516a:	89 de                	mov    %ebx,%esi
f010516c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0105171:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0105174:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0105178:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010517b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010517e:	83 fb 09             	cmp    $0x9,%ebx
f0105181:	77 36                	ja     f01051b9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105183:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0105186:	eb e9                	jmp    f0105171 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105188:	8b 45 14             	mov    0x14(%ebp),%eax
f010518b:	8d 48 04             	lea    0x4(%eax),%ecx
f010518e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105191:	8b 00                	mov    (%eax),%eax
f0105193:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105196:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0105198:	eb 22                	jmp    f01051bc <vprintfmt+0xde>
f010519a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010519d:	85 c9                	test   %ecx,%ecx
f010519f:	b8 00 00 00 00       	mov    $0x0,%eax
f01051a4:	0f 49 c1             	cmovns %ecx,%eax
f01051a7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01051aa:	89 de                	mov    %ebx,%esi
f01051ac:	eb 9d                	jmp    f010514b <vprintfmt+0x6d>
f01051ae:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01051b0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01051b7:	eb 92                	jmp    f010514b <vprintfmt+0x6d>
f01051b9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01051bc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01051c0:	79 89                	jns    f010514b <vprintfmt+0x6d>
f01051c2:	e9 77 ff ff ff       	jmp    f010513e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01051c7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01051ca:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01051cc:	e9 7a ff ff ff       	jmp    f010514b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01051d1:	8b 45 14             	mov    0x14(%ebp),%eax
f01051d4:	8d 50 04             	lea    0x4(%eax),%edx
f01051d7:	89 55 14             	mov    %edx,0x14(%ebp)
f01051da:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01051de:	8b 00                	mov    (%eax),%eax
f01051e0:	89 04 24             	mov    %eax,(%esp)
f01051e3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01051e6:	e9 18 ff ff ff       	jmp    f0105103 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01051eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01051ee:	8d 50 04             	lea    0x4(%eax),%edx
f01051f1:	89 55 14             	mov    %edx,0x14(%ebp)
f01051f4:	8b 00                	mov    (%eax),%eax
f01051f6:	99                   	cltd   
f01051f7:	31 d0                	xor    %edx,%eax
f01051f9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01051fb:	83 f8 09             	cmp    $0x9,%eax
f01051fe:	7f 0b                	jg     f010520b <vprintfmt+0x12d>
f0105200:	8b 14 85 a0 7f 10 f0 	mov    -0xfef8060(,%eax,4),%edx
f0105207:	85 d2                	test   %edx,%edx
f0105209:	75 20                	jne    f010522b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010520b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010520f:	c7 44 24 08 92 7d 10 	movl   $0xf0107d92,0x8(%esp)
f0105216:	f0 
f0105217:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010521b:	8b 45 08             	mov    0x8(%ebp),%eax
f010521e:	89 04 24             	mov    %eax,(%esp)
f0105221:	e8 90 fe ff ff       	call   f01050b6 <printfmt>
f0105226:	e9 d8 fe ff ff       	jmp    f0105103 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010522b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010522f:	c7 44 24 08 8d 74 10 	movl   $0xf010748d,0x8(%esp)
f0105236:	f0 
f0105237:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010523b:	8b 45 08             	mov    0x8(%ebp),%eax
f010523e:	89 04 24             	mov    %eax,(%esp)
f0105241:	e8 70 fe ff ff       	call   f01050b6 <printfmt>
f0105246:	e9 b8 fe ff ff       	jmp    f0105103 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010524b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010524e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105251:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0105254:	8b 45 14             	mov    0x14(%ebp),%eax
f0105257:	8d 50 04             	lea    0x4(%eax),%edx
f010525a:	89 55 14             	mov    %edx,0x14(%ebp)
f010525d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010525f:	85 f6                	test   %esi,%esi
f0105261:	b8 8b 7d 10 f0       	mov    $0xf0107d8b,%eax
f0105266:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0105269:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010526d:	0f 84 97 00 00 00    	je     f010530a <vprintfmt+0x22c>
f0105273:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105277:	0f 8e 9b 00 00 00    	jle    f0105318 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010527d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105281:	89 34 24             	mov    %esi,(%esp)
f0105284:	e8 9f 03 00 00       	call   f0105628 <strnlen>
f0105289:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010528c:	29 c2                	sub    %eax,%edx
f010528e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105291:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105295:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105298:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010529b:	8b 75 08             	mov    0x8(%ebp),%esi
f010529e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01052a1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01052a3:	eb 0f                	jmp    f01052b4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01052a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01052a9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01052ac:	89 04 24             	mov    %eax,(%esp)
f01052af:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01052b1:	83 eb 01             	sub    $0x1,%ebx
f01052b4:	85 db                	test   %ebx,%ebx
f01052b6:	7f ed                	jg     f01052a5 <vprintfmt+0x1c7>
f01052b8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01052bb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01052be:	85 d2                	test   %edx,%edx
f01052c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01052c5:	0f 49 c2             	cmovns %edx,%eax
f01052c8:	29 c2                	sub    %eax,%edx
f01052ca:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01052cd:	89 d7                	mov    %edx,%edi
f01052cf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01052d2:	eb 50                	jmp    f0105324 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01052d4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01052d8:	74 1e                	je     f01052f8 <vprintfmt+0x21a>
f01052da:	0f be d2             	movsbl %dl,%edx
f01052dd:	83 ea 20             	sub    $0x20,%edx
f01052e0:	83 fa 5e             	cmp    $0x5e,%edx
f01052e3:	76 13                	jbe    f01052f8 <vprintfmt+0x21a>
					putch('?', putdat);
f01052e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01052e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052ec:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01052f3:	ff 55 08             	call   *0x8(%ebp)
f01052f6:	eb 0d                	jmp    f0105305 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01052f8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01052fb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01052ff:	89 04 24             	mov    %eax,(%esp)
f0105302:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0105305:	83 ef 01             	sub    $0x1,%edi
f0105308:	eb 1a                	jmp    f0105324 <vprintfmt+0x246>
f010530a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010530d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105310:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105313:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105316:	eb 0c                	jmp    f0105324 <vprintfmt+0x246>
f0105318:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010531b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010531e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105321:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105324:	83 c6 01             	add    $0x1,%esi
f0105327:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010532b:	0f be c2             	movsbl %dl,%eax
f010532e:	85 c0                	test   %eax,%eax
f0105330:	74 27                	je     f0105359 <vprintfmt+0x27b>
f0105332:	85 db                	test   %ebx,%ebx
f0105334:	78 9e                	js     f01052d4 <vprintfmt+0x1f6>
f0105336:	83 eb 01             	sub    $0x1,%ebx
f0105339:	79 99                	jns    f01052d4 <vprintfmt+0x1f6>
f010533b:	89 f8                	mov    %edi,%eax
f010533d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105340:	8b 75 08             	mov    0x8(%ebp),%esi
f0105343:	89 c3                	mov    %eax,%ebx
f0105345:	eb 1a                	jmp    f0105361 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105347:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010534b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0105352:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105354:	83 eb 01             	sub    $0x1,%ebx
f0105357:	eb 08                	jmp    f0105361 <vprintfmt+0x283>
f0105359:	89 fb                	mov    %edi,%ebx
f010535b:	8b 75 08             	mov    0x8(%ebp),%esi
f010535e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105361:	85 db                	test   %ebx,%ebx
f0105363:	7f e2                	jg     f0105347 <vprintfmt+0x269>
f0105365:	89 75 08             	mov    %esi,0x8(%ebp)
f0105368:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010536b:	e9 93 fd ff ff       	jmp    f0105103 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105370:	83 fa 01             	cmp    $0x1,%edx
f0105373:	7e 16                	jle    f010538b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0105375:	8b 45 14             	mov    0x14(%ebp),%eax
f0105378:	8d 50 08             	lea    0x8(%eax),%edx
f010537b:	89 55 14             	mov    %edx,0x14(%ebp)
f010537e:	8b 50 04             	mov    0x4(%eax),%edx
f0105381:	8b 00                	mov    (%eax),%eax
f0105383:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105386:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105389:	eb 32                	jmp    f01053bd <vprintfmt+0x2df>
	else if (lflag)
f010538b:	85 d2                	test   %edx,%edx
f010538d:	74 18                	je     f01053a7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010538f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105392:	8d 50 04             	lea    0x4(%eax),%edx
f0105395:	89 55 14             	mov    %edx,0x14(%ebp)
f0105398:	8b 30                	mov    (%eax),%esi
f010539a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010539d:	89 f0                	mov    %esi,%eax
f010539f:	c1 f8 1f             	sar    $0x1f,%eax
f01053a2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01053a5:	eb 16                	jmp    f01053bd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01053a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01053aa:	8d 50 04             	lea    0x4(%eax),%edx
f01053ad:	89 55 14             	mov    %edx,0x14(%ebp)
f01053b0:	8b 30                	mov    (%eax),%esi
f01053b2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01053b5:	89 f0                	mov    %esi,%eax
f01053b7:	c1 f8 1f             	sar    $0x1f,%eax
f01053ba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01053bd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01053c0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01053c3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01053c8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01053cc:	0f 89 80 00 00 00    	jns    f0105452 <vprintfmt+0x374>
				putch('-', putdat);
f01053d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01053d6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01053dd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01053e0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01053e3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01053e6:	f7 d8                	neg    %eax
f01053e8:	83 d2 00             	adc    $0x0,%edx
f01053eb:	f7 da                	neg    %edx
			}
			base = 10;
f01053ed:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01053f2:	eb 5e                	jmp    f0105452 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01053f4:	8d 45 14             	lea    0x14(%ebp),%eax
f01053f7:	e8 63 fc ff ff       	call   f010505f <getuint>
			base = 10;
f01053fc:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0105401:	eb 4f                	jmp    f0105452 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0105403:	8d 45 14             	lea    0x14(%ebp),%eax
f0105406:	e8 54 fc ff ff       	call   f010505f <getuint>
			base = 8;
f010540b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105410:	eb 40                	jmp    f0105452 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0105412:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105416:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010541d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105420:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105424:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010542b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010542e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105431:	8d 50 04             	lea    0x4(%eax),%edx
f0105434:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105437:	8b 00                	mov    (%eax),%eax
f0105439:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010543e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105443:	eb 0d                	jmp    f0105452 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105445:	8d 45 14             	lea    0x14(%ebp),%eax
f0105448:	e8 12 fc ff ff       	call   f010505f <getuint>
			base = 16;
f010544d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105452:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0105456:	89 74 24 10          	mov    %esi,0x10(%esp)
f010545a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010545d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105461:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105465:	89 04 24             	mov    %eax,(%esp)
f0105468:	89 54 24 04          	mov    %edx,0x4(%esp)
f010546c:	89 fa                	mov    %edi,%edx
f010546e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105471:	e8 fa fa ff ff       	call   f0104f70 <printnum>
			break;
f0105476:	e9 88 fc ff ff       	jmp    f0105103 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010547b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010547f:	89 04 24             	mov    %eax,(%esp)
f0105482:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105485:	e9 79 fc ff ff       	jmp    f0105103 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010548a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010548e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105495:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105498:	89 f3                	mov    %esi,%ebx
f010549a:	eb 03                	jmp    f010549f <vprintfmt+0x3c1>
f010549c:	83 eb 01             	sub    $0x1,%ebx
f010549f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01054a3:	75 f7                	jne    f010549c <vprintfmt+0x3be>
f01054a5:	e9 59 fc ff ff       	jmp    f0105103 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01054aa:	83 c4 3c             	add    $0x3c,%esp
f01054ad:	5b                   	pop    %ebx
f01054ae:	5e                   	pop    %esi
f01054af:	5f                   	pop    %edi
f01054b0:	5d                   	pop    %ebp
f01054b1:	c3                   	ret    

f01054b2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01054b2:	55                   	push   %ebp
f01054b3:	89 e5                	mov    %esp,%ebp
f01054b5:	83 ec 28             	sub    $0x28,%esp
f01054b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01054bb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01054be:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01054c1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01054c5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01054c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01054cf:	85 c0                	test   %eax,%eax
f01054d1:	74 30                	je     f0105503 <vsnprintf+0x51>
f01054d3:	85 d2                	test   %edx,%edx
f01054d5:	7e 2c                	jle    f0105503 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01054d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01054da:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01054de:	8b 45 10             	mov    0x10(%ebp),%eax
f01054e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01054e5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01054e8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01054ec:	c7 04 24 99 50 10 f0 	movl   $0xf0105099,(%esp)
f01054f3:	e8 e6 fb ff ff       	call   f01050de <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01054f8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01054fb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01054fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0105501:	eb 05                	jmp    f0105508 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105503:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105508:	c9                   	leave  
f0105509:	c3                   	ret    

f010550a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010550a:	55                   	push   %ebp
f010550b:	89 e5                	mov    %esp,%ebp
f010550d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105510:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105513:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105517:	8b 45 10             	mov    0x10(%ebp),%eax
f010551a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010551e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105521:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105525:	8b 45 08             	mov    0x8(%ebp),%eax
f0105528:	89 04 24             	mov    %eax,(%esp)
f010552b:	e8 82 ff ff ff       	call   f01054b2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105530:	c9                   	leave  
f0105531:	c3                   	ret    
f0105532:	66 90                	xchg   %ax,%ax
f0105534:	66 90                	xchg   %ax,%ax
f0105536:	66 90                	xchg   %ax,%ax
f0105538:	66 90                	xchg   %ax,%ax
f010553a:	66 90                	xchg   %ax,%ax
f010553c:	66 90                	xchg   %ax,%ax
f010553e:	66 90                	xchg   %ax,%ax

f0105540 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105540:	55                   	push   %ebp
f0105541:	89 e5                	mov    %esp,%ebp
f0105543:	57                   	push   %edi
f0105544:	56                   	push   %esi
f0105545:	53                   	push   %ebx
f0105546:	83 ec 1c             	sub    $0x1c,%esp
f0105549:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010554c:	85 c0                	test   %eax,%eax
f010554e:	74 10                	je     f0105560 <readline+0x20>
		cprintf("%s", prompt);
f0105550:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105554:	c7 04 24 8d 74 10 f0 	movl   $0xf010748d,(%esp)
f010555b:	e8 cc eb ff ff       	call   f010412c <cprintf>

	i = 0;
	echoing = iscons(0);
f0105560:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105567:	e8 5f b2 ff ff       	call   f01007cb <iscons>
f010556c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010556e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105573:	e8 42 b2 ff ff       	call   f01007ba <getchar>
f0105578:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010557a:	85 c0                	test   %eax,%eax
f010557c:	79 17                	jns    f0105595 <readline+0x55>
			cprintf("read error: %e\n", c);
f010557e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105582:	c7 04 24 c8 7f 10 f0 	movl   $0xf0107fc8,(%esp)
f0105589:	e8 9e eb ff ff       	call   f010412c <cprintf>
			return NULL;
f010558e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105593:	eb 6d                	jmp    f0105602 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105595:	83 f8 7f             	cmp    $0x7f,%eax
f0105598:	74 05                	je     f010559f <readline+0x5f>
f010559a:	83 f8 08             	cmp    $0x8,%eax
f010559d:	75 19                	jne    f01055b8 <readline+0x78>
f010559f:	85 f6                	test   %esi,%esi
f01055a1:	7e 15                	jle    f01055b8 <readline+0x78>
			if (echoing)
f01055a3:	85 ff                	test   %edi,%edi
f01055a5:	74 0c                	je     f01055b3 <readline+0x73>
				cputchar('\b');
f01055a7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01055ae:	e8 f7 b1 ff ff       	call   f01007aa <cputchar>
			i--;
f01055b3:	83 ee 01             	sub    $0x1,%esi
f01055b6:	eb bb                	jmp    f0105573 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01055b8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01055be:	7f 1c                	jg     f01055dc <readline+0x9c>
f01055c0:	83 fb 1f             	cmp    $0x1f,%ebx
f01055c3:	7e 17                	jle    f01055dc <readline+0x9c>
			if (echoing)
f01055c5:	85 ff                	test   %edi,%edi
f01055c7:	74 08                	je     f01055d1 <readline+0x91>
				cputchar(c);
f01055c9:	89 1c 24             	mov    %ebx,(%esp)
f01055cc:	e8 d9 b1 ff ff       	call   f01007aa <cputchar>
			buf[i++] = c;
f01055d1:	88 9e 80 ba 22 f0    	mov    %bl,-0xfdd4580(%esi)
f01055d7:	8d 76 01             	lea    0x1(%esi),%esi
f01055da:	eb 97                	jmp    f0105573 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01055dc:	83 fb 0d             	cmp    $0xd,%ebx
f01055df:	74 05                	je     f01055e6 <readline+0xa6>
f01055e1:	83 fb 0a             	cmp    $0xa,%ebx
f01055e4:	75 8d                	jne    f0105573 <readline+0x33>
			if (echoing)
f01055e6:	85 ff                	test   %edi,%edi
f01055e8:	74 0c                	je     f01055f6 <readline+0xb6>
				cputchar('\n');
f01055ea:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01055f1:	e8 b4 b1 ff ff       	call   f01007aa <cputchar>
			buf[i] = 0;
f01055f6:	c6 86 80 ba 22 f0 00 	movb   $0x0,-0xfdd4580(%esi)
			return buf;
f01055fd:	b8 80 ba 22 f0       	mov    $0xf022ba80,%eax
		}
	}
}
f0105602:	83 c4 1c             	add    $0x1c,%esp
f0105605:	5b                   	pop    %ebx
f0105606:	5e                   	pop    %esi
f0105607:	5f                   	pop    %edi
f0105608:	5d                   	pop    %ebp
f0105609:	c3                   	ret    
f010560a:	66 90                	xchg   %ax,%ax
f010560c:	66 90                	xchg   %ax,%ax
f010560e:	66 90                	xchg   %ax,%ax

f0105610 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105610:	55                   	push   %ebp
f0105611:	89 e5                	mov    %esp,%ebp
f0105613:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105616:	b8 00 00 00 00       	mov    $0x0,%eax
f010561b:	eb 03                	jmp    f0105620 <strlen+0x10>
		n++;
f010561d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105620:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105624:	75 f7                	jne    f010561d <strlen+0xd>
		n++;
	return n;
}
f0105626:	5d                   	pop    %ebp
f0105627:	c3                   	ret    

f0105628 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105628:	55                   	push   %ebp
f0105629:	89 e5                	mov    %esp,%ebp
f010562b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010562e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105631:	b8 00 00 00 00       	mov    $0x0,%eax
f0105636:	eb 03                	jmp    f010563b <strnlen+0x13>
		n++;
f0105638:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010563b:	39 d0                	cmp    %edx,%eax
f010563d:	74 06                	je     f0105645 <strnlen+0x1d>
f010563f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105643:	75 f3                	jne    f0105638 <strnlen+0x10>
		n++;
	return n;
}
f0105645:	5d                   	pop    %ebp
f0105646:	c3                   	ret    

f0105647 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105647:	55                   	push   %ebp
f0105648:	89 e5                	mov    %esp,%ebp
f010564a:	53                   	push   %ebx
f010564b:	8b 45 08             	mov    0x8(%ebp),%eax
f010564e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105651:	89 c2                	mov    %eax,%edx
f0105653:	83 c2 01             	add    $0x1,%edx
f0105656:	83 c1 01             	add    $0x1,%ecx
f0105659:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010565d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105660:	84 db                	test   %bl,%bl
f0105662:	75 ef                	jne    f0105653 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105664:	5b                   	pop    %ebx
f0105665:	5d                   	pop    %ebp
f0105666:	c3                   	ret    

f0105667 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105667:	55                   	push   %ebp
f0105668:	89 e5                	mov    %esp,%ebp
f010566a:	53                   	push   %ebx
f010566b:	83 ec 08             	sub    $0x8,%esp
f010566e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105671:	89 1c 24             	mov    %ebx,(%esp)
f0105674:	e8 97 ff ff ff       	call   f0105610 <strlen>
	strcpy(dst + len, src);
f0105679:	8b 55 0c             	mov    0xc(%ebp),%edx
f010567c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105680:	01 d8                	add    %ebx,%eax
f0105682:	89 04 24             	mov    %eax,(%esp)
f0105685:	e8 bd ff ff ff       	call   f0105647 <strcpy>
	return dst;
}
f010568a:	89 d8                	mov    %ebx,%eax
f010568c:	83 c4 08             	add    $0x8,%esp
f010568f:	5b                   	pop    %ebx
f0105690:	5d                   	pop    %ebp
f0105691:	c3                   	ret    

f0105692 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105692:	55                   	push   %ebp
f0105693:	89 e5                	mov    %esp,%ebp
f0105695:	56                   	push   %esi
f0105696:	53                   	push   %ebx
f0105697:	8b 75 08             	mov    0x8(%ebp),%esi
f010569a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010569d:	89 f3                	mov    %esi,%ebx
f010569f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01056a2:	89 f2                	mov    %esi,%edx
f01056a4:	eb 0f                	jmp    f01056b5 <strncpy+0x23>
		*dst++ = *src;
f01056a6:	83 c2 01             	add    $0x1,%edx
f01056a9:	0f b6 01             	movzbl (%ecx),%eax
f01056ac:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01056af:	80 39 01             	cmpb   $0x1,(%ecx)
f01056b2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01056b5:	39 da                	cmp    %ebx,%edx
f01056b7:	75 ed                	jne    f01056a6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01056b9:	89 f0                	mov    %esi,%eax
f01056bb:	5b                   	pop    %ebx
f01056bc:	5e                   	pop    %esi
f01056bd:	5d                   	pop    %ebp
f01056be:	c3                   	ret    

f01056bf <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01056bf:	55                   	push   %ebp
f01056c0:	89 e5                	mov    %esp,%ebp
f01056c2:	56                   	push   %esi
f01056c3:	53                   	push   %ebx
f01056c4:	8b 75 08             	mov    0x8(%ebp),%esi
f01056c7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01056ca:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01056cd:	89 f0                	mov    %esi,%eax
f01056cf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01056d3:	85 c9                	test   %ecx,%ecx
f01056d5:	75 0b                	jne    f01056e2 <strlcpy+0x23>
f01056d7:	eb 1d                	jmp    f01056f6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01056d9:	83 c0 01             	add    $0x1,%eax
f01056dc:	83 c2 01             	add    $0x1,%edx
f01056df:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01056e2:	39 d8                	cmp    %ebx,%eax
f01056e4:	74 0b                	je     f01056f1 <strlcpy+0x32>
f01056e6:	0f b6 0a             	movzbl (%edx),%ecx
f01056e9:	84 c9                	test   %cl,%cl
f01056eb:	75 ec                	jne    f01056d9 <strlcpy+0x1a>
f01056ed:	89 c2                	mov    %eax,%edx
f01056ef:	eb 02                	jmp    f01056f3 <strlcpy+0x34>
f01056f1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01056f3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01056f6:	29 f0                	sub    %esi,%eax
}
f01056f8:	5b                   	pop    %ebx
f01056f9:	5e                   	pop    %esi
f01056fa:	5d                   	pop    %ebp
f01056fb:	c3                   	ret    

f01056fc <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01056fc:	55                   	push   %ebp
f01056fd:	89 e5                	mov    %esp,%ebp
f01056ff:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0105702:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105705:	eb 06                	jmp    f010570d <strcmp+0x11>
		p++, q++;
f0105707:	83 c1 01             	add    $0x1,%ecx
f010570a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010570d:	0f b6 01             	movzbl (%ecx),%eax
f0105710:	84 c0                	test   %al,%al
f0105712:	74 04                	je     f0105718 <strcmp+0x1c>
f0105714:	3a 02                	cmp    (%edx),%al
f0105716:	74 ef                	je     f0105707 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105718:	0f b6 c0             	movzbl %al,%eax
f010571b:	0f b6 12             	movzbl (%edx),%edx
f010571e:	29 d0                	sub    %edx,%eax
}
f0105720:	5d                   	pop    %ebp
f0105721:	c3                   	ret    

f0105722 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105722:	55                   	push   %ebp
f0105723:	89 e5                	mov    %esp,%ebp
f0105725:	53                   	push   %ebx
f0105726:	8b 45 08             	mov    0x8(%ebp),%eax
f0105729:	8b 55 0c             	mov    0xc(%ebp),%edx
f010572c:	89 c3                	mov    %eax,%ebx
f010572e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105731:	eb 06                	jmp    f0105739 <strncmp+0x17>
		n--, p++, q++;
f0105733:	83 c0 01             	add    $0x1,%eax
f0105736:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105739:	39 d8                	cmp    %ebx,%eax
f010573b:	74 15                	je     f0105752 <strncmp+0x30>
f010573d:	0f b6 08             	movzbl (%eax),%ecx
f0105740:	84 c9                	test   %cl,%cl
f0105742:	74 04                	je     f0105748 <strncmp+0x26>
f0105744:	3a 0a                	cmp    (%edx),%cl
f0105746:	74 eb                	je     f0105733 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105748:	0f b6 00             	movzbl (%eax),%eax
f010574b:	0f b6 12             	movzbl (%edx),%edx
f010574e:	29 d0                	sub    %edx,%eax
f0105750:	eb 05                	jmp    f0105757 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105752:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105757:	5b                   	pop    %ebx
f0105758:	5d                   	pop    %ebp
f0105759:	c3                   	ret    

f010575a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010575a:	55                   	push   %ebp
f010575b:	89 e5                	mov    %esp,%ebp
f010575d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105760:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105764:	eb 07                	jmp    f010576d <strchr+0x13>
		if (*s == c)
f0105766:	38 ca                	cmp    %cl,%dl
f0105768:	74 0f                	je     f0105779 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010576a:	83 c0 01             	add    $0x1,%eax
f010576d:	0f b6 10             	movzbl (%eax),%edx
f0105770:	84 d2                	test   %dl,%dl
f0105772:	75 f2                	jne    f0105766 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105774:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105779:	5d                   	pop    %ebp
f010577a:	c3                   	ret    

f010577b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010577b:	55                   	push   %ebp
f010577c:	89 e5                	mov    %esp,%ebp
f010577e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105781:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105785:	eb 07                	jmp    f010578e <strfind+0x13>
		if (*s == c)
f0105787:	38 ca                	cmp    %cl,%dl
f0105789:	74 0a                	je     f0105795 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010578b:	83 c0 01             	add    $0x1,%eax
f010578e:	0f b6 10             	movzbl (%eax),%edx
f0105791:	84 d2                	test   %dl,%dl
f0105793:	75 f2                	jne    f0105787 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0105795:	5d                   	pop    %ebp
f0105796:	c3                   	ret    

f0105797 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105797:	55                   	push   %ebp
f0105798:	89 e5                	mov    %esp,%ebp
f010579a:	57                   	push   %edi
f010579b:	56                   	push   %esi
f010579c:	53                   	push   %ebx
f010579d:	8b 7d 08             	mov    0x8(%ebp),%edi
f01057a0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01057a3:	85 c9                	test   %ecx,%ecx
f01057a5:	74 36                	je     f01057dd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01057a7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01057ad:	75 28                	jne    f01057d7 <memset+0x40>
f01057af:	f6 c1 03             	test   $0x3,%cl
f01057b2:	75 23                	jne    f01057d7 <memset+0x40>
		c &= 0xFF;
f01057b4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01057b8:	89 d3                	mov    %edx,%ebx
f01057ba:	c1 e3 08             	shl    $0x8,%ebx
f01057bd:	89 d6                	mov    %edx,%esi
f01057bf:	c1 e6 18             	shl    $0x18,%esi
f01057c2:	89 d0                	mov    %edx,%eax
f01057c4:	c1 e0 10             	shl    $0x10,%eax
f01057c7:	09 f0                	or     %esi,%eax
f01057c9:	09 c2                	or     %eax,%edx
f01057cb:	89 d0                	mov    %edx,%eax
f01057cd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01057cf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01057d2:	fc                   	cld    
f01057d3:	f3 ab                	rep stos %eax,%es:(%edi)
f01057d5:	eb 06                	jmp    f01057dd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01057d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01057da:	fc                   	cld    
f01057db:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01057dd:	89 f8                	mov    %edi,%eax
f01057df:	5b                   	pop    %ebx
f01057e0:	5e                   	pop    %esi
f01057e1:	5f                   	pop    %edi
f01057e2:	5d                   	pop    %ebp
f01057e3:	c3                   	ret    

f01057e4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01057e4:	55                   	push   %ebp
f01057e5:	89 e5                	mov    %esp,%ebp
f01057e7:	57                   	push   %edi
f01057e8:	56                   	push   %esi
f01057e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01057ec:	8b 75 0c             	mov    0xc(%ebp),%esi
f01057ef:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01057f2:	39 c6                	cmp    %eax,%esi
f01057f4:	73 35                	jae    f010582b <memmove+0x47>
f01057f6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01057f9:	39 d0                	cmp    %edx,%eax
f01057fb:	73 2e                	jae    f010582b <memmove+0x47>
		s += n;
		d += n;
f01057fd:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0105800:	89 d6                	mov    %edx,%esi
f0105802:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105804:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010580a:	75 13                	jne    f010581f <memmove+0x3b>
f010580c:	f6 c1 03             	test   $0x3,%cl
f010580f:	75 0e                	jne    f010581f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105811:	83 ef 04             	sub    $0x4,%edi
f0105814:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105817:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010581a:	fd                   	std    
f010581b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010581d:	eb 09                	jmp    f0105828 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010581f:	83 ef 01             	sub    $0x1,%edi
f0105822:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105825:	fd                   	std    
f0105826:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105828:	fc                   	cld    
f0105829:	eb 1d                	jmp    f0105848 <memmove+0x64>
f010582b:	89 f2                	mov    %esi,%edx
f010582d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010582f:	f6 c2 03             	test   $0x3,%dl
f0105832:	75 0f                	jne    f0105843 <memmove+0x5f>
f0105834:	f6 c1 03             	test   $0x3,%cl
f0105837:	75 0a                	jne    f0105843 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105839:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010583c:	89 c7                	mov    %eax,%edi
f010583e:	fc                   	cld    
f010583f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105841:	eb 05                	jmp    f0105848 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105843:	89 c7                	mov    %eax,%edi
f0105845:	fc                   	cld    
f0105846:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105848:	5e                   	pop    %esi
f0105849:	5f                   	pop    %edi
f010584a:	5d                   	pop    %ebp
f010584b:	c3                   	ret    

f010584c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010584c:	55                   	push   %ebp
f010584d:	89 e5                	mov    %esp,%ebp
f010584f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105852:	8b 45 10             	mov    0x10(%ebp),%eax
f0105855:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105859:	8b 45 0c             	mov    0xc(%ebp),%eax
f010585c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105860:	8b 45 08             	mov    0x8(%ebp),%eax
f0105863:	89 04 24             	mov    %eax,(%esp)
f0105866:	e8 79 ff ff ff       	call   f01057e4 <memmove>
}
f010586b:	c9                   	leave  
f010586c:	c3                   	ret    

f010586d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010586d:	55                   	push   %ebp
f010586e:	89 e5                	mov    %esp,%ebp
f0105870:	56                   	push   %esi
f0105871:	53                   	push   %ebx
f0105872:	8b 55 08             	mov    0x8(%ebp),%edx
f0105875:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105878:	89 d6                	mov    %edx,%esi
f010587a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010587d:	eb 1a                	jmp    f0105899 <memcmp+0x2c>
		if (*s1 != *s2)
f010587f:	0f b6 02             	movzbl (%edx),%eax
f0105882:	0f b6 19             	movzbl (%ecx),%ebx
f0105885:	38 d8                	cmp    %bl,%al
f0105887:	74 0a                	je     f0105893 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105889:	0f b6 c0             	movzbl %al,%eax
f010588c:	0f b6 db             	movzbl %bl,%ebx
f010588f:	29 d8                	sub    %ebx,%eax
f0105891:	eb 0f                	jmp    f01058a2 <memcmp+0x35>
		s1++, s2++;
f0105893:	83 c2 01             	add    $0x1,%edx
f0105896:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105899:	39 f2                	cmp    %esi,%edx
f010589b:	75 e2                	jne    f010587f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010589d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01058a2:	5b                   	pop    %ebx
f01058a3:	5e                   	pop    %esi
f01058a4:	5d                   	pop    %ebp
f01058a5:	c3                   	ret    

f01058a6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01058a6:	55                   	push   %ebp
f01058a7:	89 e5                	mov    %esp,%ebp
f01058a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01058ac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01058af:	89 c2                	mov    %eax,%edx
f01058b1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01058b4:	eb 07                	jmp    f01058bd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01058b6:	38 08                	cmp    %cl,(%eax)
f01058b8:	74 07                	je     f01058c1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01058ba:	83 c0 01             	add    $0x1,%eax
f01058bd:	39 d0                	cmp    %edx,%eax
f01058bf:	72 f5                	jb     f01058b6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01058c1:	5d                   	pop    %ebp
f01058c2:	c3                   	ret    

f01058c3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01058c3:	55                   	push   %ebp
f01058c4:	89 e5                	mov    %esp,%ebp
f01058c6:	57                   	push   %edi
f01058c7:	56                   	push   %esi
f01058c8:	53                   	push   %ebx
f01058c9:	8b 55 08             	mov    0x8(%ebp),%edx
f01058cc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01058cf:	eb 03                	jmp    f01058d4 <strtol+0x11>
		s++;
f01058d1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01058d4:	0f b6 0a             	movzbl (%edx),%ecx
f01058d7:	80 f9 09             	cmp    $0x9,%cl
f01058da:	74 f5                	je     f01058d1 <strtol+0xe>
f01058dc:	80 f9 20             	cmp    $0x20,%cl
f01058df:	74 f0                	je     f01058d1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01058e1:	80 f9 2b             	cmp    $0x2b,%cl
f01058e4:	75 0a                	jne    f01058f0 <strtol+0x2d>
		s++;
f01058e6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01058e9:	bf 00 00 00 00       	mov    $0x0,%edi
f01058ee:	eb 11                	jmp    f0105901 <strtol+0x3e>
f01058f0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01058f5:	80 f9 2d             	cmp    $0x2d,%cl
f01058f8:	75 07                	jne    f0105901 <strtol+0x3e>
		s++, neg = 1;
f01058fa:	8d 52 01             	lea    0x1(%edx),%edx
f01058fd:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0105901:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0105906:	75 15                	jne    f010591d <strtol+0x5a>
f0105908:	80 3a 30             	cmpb   $0x30,(%edx)
f010590b:	75 10                	jne    f010591d <strtol+0x5a>
f010590d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105911:	75 0a                	jne    f010591d <strtol+0x5a>
		s += 2, base = 16;
f0105913:	83 c2 02             	add    $0x2,%edx
f0105916:	b8 10 00 00 00       	mov    $0x10,%eax
f010591b:	eb 10                	jmp    f010592d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010591d:	85 c0                	test   %eax,%eax
f010591f:	75 0c                	jne    f010592d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105921:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105923:	80 3a 30             	cmpb   $0x30,(%edx)
f0105926:	75 05                	jne    f010592d <strtol+0x6a>
		s++, base = 8;
f0105928:	83 c2 01             	add    $0x1,%edx
f010592b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010592d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105932:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105935:	0f b6 0a             	movzbl (%edx),%ecx
f0105938:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010593b:	89 f0                	mov    %esi,%eax
f010593d:	3c 09                	cmp    $0x9,%al
f010593f:	77 08                	ja     f0105949 <strtol+0x86>
			dig = *s - '0';
f0105941:	0f be c9             	movsbl %cl,%ecx
f0105944:	83 e9 30             	sub    $0x30,%ecx
f0105947:	eb 20                	jmp    f0105969 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105949:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010594c:	89 f0                	mov    %esi,%eax
f010594e:	3c 19                	cmp    $0x19,%al
f0105950:	77 08                	ja     f010595a <strtol+0x97>
			dig = *s - 'a' + 10;
f0105952:	0f be c9             	movsbl %cl,%ecx
f0105955:	83 e9 57             	sub    $0x57,%ecx
f0105958:	eb 0f                	jmp    f0105969 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010595a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010595d:	89 f0                	mov    %esi,%eax
f010595f:	3c 19                	cmp    $0x19,%al
f0105961:	77 16                	ja     f0105979 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0105963:	0f be c9             	movsbl %cl,%ecx
f0105966:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105969:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010596c:	7d 0f                	jge    f010597d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010596e:	83 c2 01             	add    $0x1,%edx
f0105971:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0105975:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0105977:	eb bc                	jmp    f0105935 <strtol+0x72>
f0105979:	89 d8                	mov    %ebx,%eax
f010597b:	eb 02                	jmp    f010597f <strtol+0xbc>
f010597d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010597f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105983:	74 05                	je     f010598a <strtol+0xc7>
		*endptr = (char *) s;
f0105985:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105988:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010598a:	f7 d8                	neg    %eax
f010598c:	85 ff                	test   %edi,%edi
f010598e:	0f 44 c3             	cmove  %ebx,%eax
}
f0105991:	5b                   	pop    %ebx
f0105992:	5e                   	pop    %esi
f0105993:	5f                   	pop    %edi
f0105994:	5d                   	pop    %ebp
f0105995:	c3                   	ret    
f0105996:	66 90                	xchg   %ax,%ax

f0105998 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105998:	fa                   	cli    

	xorw    %ax, %ax
f0105999:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010599b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010599d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f010599f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01059a1:	0f 01 16             	lgdtl  (%esi)
f01059a4:	74 70                	je     f0105a16 <mpentry_end+0x4>
	movl    %cr0, %eax
f01059a6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01059a9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01059ad:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01059b0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01059b6:	08 00                	or     %al,(%eax)

f01059b8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01059b8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01059bc:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01059be:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01059c0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01059c2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01059c6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01059c8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01059ca:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f01059cf:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01059d2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01059d5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01059da:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01059dd:	8b 25 84 be 22 f0    	mov    0xf022be84,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01059e3:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01059e8:	b8 0a 02 10 f0       	mov    $0xf010020a,%eax
	call    *%eax
f01059ed:	ff d0                	call   *%eax

f01059ef <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01059ef:	eb fe                	jmp    f01059ef <spin>
f01059f1:	8d 76 00             	lea    0x0(%esi),%esi

f01059f4 <gdt>:
	...
f01059fc:	ff                   	(bad)  
f01059fd:	ff 00                	incl   (%eax)
f01059ff:	00 00                	add    %al,(%eax)
f0105a01:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0105a08:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105a0c <gdtdesc>:
f0105a0c:	17                   	pop    %ss
f0105a0d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105a12 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105a12:	90                   	nop
f0105a13:	66 90                	xchg   %ax,%ax
f0105a15:	66 90                	xchg   %ax,%ax
f0105a17:	66 90                	xchg   %ax,%ax
f0105a19:	66 90                	xchg   %ax,%ax
f0105a1b:	66 90                	xchg   %ax,%ax
f0105a1d:	66 90                	xchg   %ax,%ax
f0105a1f:	90                   	nop

f0105a20 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105a20:	55                   	push   %ebp
f0105a21:	89 e5                	mov    %esp,%ebp
f0105a23:	56                   	push   %esi
f0105a24:	53                   	push   %ebx
f0105a25:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105a28:	8b 0d 88 be 22 f0    	mov    0xf022be88,%ecx
f0105a2e:	89 c3                	mov    %eax,%ebx
f0105a30:	c1 eb 0c             	shr    $0xc,%ebx
f0105a33:	39 cb                	cmp    %ecx,%ebx
f0105a35:	72 20                	jb     f0105a57 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105a37:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105a3b:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0105a42:	f0 
f0105a43:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105a4a:	00 
f0105a4b:	c7 04 24 65 81 10 f0 	movl   $0xf0108165,(%esp)
f0105a52:	e8 e9 a5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105a57:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105a5d:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105a5f:	89 c2                	mov    %eax,%edx
f0105a61:	c1 ea 0c             	shr    $0xc,%edx
f0105a64:	39 d1                	cmp    %edx,%ecx
f0105a66:	77 20                	ja     f0105a88 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105a68:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105a6c:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0105a73:	f0 
f0105a74:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0105a7b:	00 
f0105a7c:	c7 04 24 65 81 10 f0 	movl   $0xf0108165,(%esp)
f0105a83:	e8 b8 a5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105a88:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0105a8e:	eb 36                	jmp    f0105ac6 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105a90:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105a97:	00 
f0105a98:	c7 44 24 04 75 81 10 	movl   $0xf0108175,0x4(%esp)
f0105a9f:	f0 
f0105aa0:	89 1c 24             	mov    %ebx,(%esp)
f0105aa3:	e8 c5 fd ff ff       	call   f010586d <memcmp>
f0105aa8:	85 c0                	test   %eax,%eax
f0105aaa:	75 17                	jne    f0105ac3 <mpsearch1+0xa3>
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105aac:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f0105ab1:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0105ab5:	01 c8                	add    %ecx,%eax
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105ab7:	83 c2 01             	add    $0x1,%edx
f0105aba:	83 fa 10             	cmp    $0x10,%edx
f0105abd:	75 f2                	jne    f0105ab1 <mpsearch1+0x91>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105abf:	84 c0                	test   %al,%al
f0105ac1:	74 0e                	je     f0105ad1 <mpsearch1+0xb1>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105ac3:	83 c3 10             	add    $0x10,%ebx
f0105ac6:	39 f3                	cmp    %esi,%ebx
f0105ac8:	72 c6                	jb     f0105a90 <mpsearch1+0x70>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0105aca:	b8 00 00 00 00       	mov    $0x0,%eax
f0105acf:	eb 02                	jmp    f0105ad3 <mpsearch1+0xb3>
f0105ad1:	89 d8                	mov    %ebx,%eax
}
f0105ad3:	83 c4 10             	add    $0x10,%esp
f0105ad6:	5b                   	pop    %ebx
f0105ad7:	5e                   	pop    %esi
f0105ad8:	5d                   	pop    %ebp
f0105ad9:	c3                   	ret    

f0105ada <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105ada:	55                   	push   %ebp
f0105adb:	89 e5                	mov    %esp,%ebp
f0105add:	57                   	push   %edi
f0105ade:	56                   	push   %esi
f0105adf:	53                   	push   %ebx
f0105ae0:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105ae3:	c7 05 c0 c3 22 f0 20 	movl   $0xf022c020,0xf022c3c0
f0105aea:	c0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105aed:	83 3d 88 be 22 f0 00 	cmpl   $0x0,0xf022be88
f0105af4:	75 24                	jne    f0105b1a <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105af6:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f0105afd:	00 
f0105afe:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0105b05:	f0 
f0105b06:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0105b0d:	00 
f0105b0e:	c7 04 24 65 81 10 f0 	movl   $0xf0108165,(%esp)
f0105b15:	e8 26 a5 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105b1a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105b21:	85 c0                	test   %eax,%eax
f0105b23:	74 16                	je     f0105b3b <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0105b25:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105b28:	ba 00 04 00 00       	mov    $0x400,%edx
f0105b2d:	e8 ee fe ff ff       	call   f0105a20 <mpsearch1>
f0105b32:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105b35:	85 c0                	test   %eax,%eax
f0105b37:	75 3c                	jne    f0105b75 <mp_init+0x9b>
f0105b39:	eb 20                	jmp    f0105b5b <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105b3b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105b42:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105b45:	2d 00 04 00 00       	sub    $0x400,%eax
f0105b4a:	ba 00 04 00 00       	mov    $0x400,%edx
f0105b4f:	e8 cc fe ff ff       	call   f0105a20 <mpsearch1>
f0105b54:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105b57:	85 c0                	test   %eax,%eax
f0105b59:	75 1a                	jne    f0105b75 <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105b5b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105b60:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105b65:	e8 b6 fe ff ff       	call   f0105a20 <mpsearch1>
f0105b6a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105b6d:	85 c0                	test   %eax,%eax
f0105b6f:	0f 84 54 02 00 00    	je     f0105dc9 <mp_init+0x2ef>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105b75:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105b78:	8b 70 04             	mov    0x4(%eax),%esi
f0105b7b:	85 f6                	test   %esi,%esi
f0105b7d:	74 06                	je     f0105b85 <mp_init+0xab>
f0105b7f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105b83:	74 11                	je     f0105b96 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0105b85:	c7 04 24 d8 7f 10 f0 	movl   $0xf0107fd8,(%esp)
f0105b8c:	e8 9b e5 ff ff       	call   f010412c <cprintf>
f0105b91:	e9 33 02 00 00       	jmp    f0105dc9 <mp_init+0x2ef>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105b96:	89 f0                	mov    %esi,%eax
f0105b98:	c1 e8 0c             	shr    $0xc,%eax
f0105b9b:	3b 05 88 be 22 f0    	cmp    0xf022be88,%eax
f0105ba1:	72 20                	jb     f0105bc3 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105ba3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105ba7:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0105bae:	f0 
f0105baf:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0105bb6:	00 
f0105bb7:	c7 04 24 65 81 10 f0 	movl   $0xf0108165,(%esp)
f0105bbe:	e8 7d a4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105bc3:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105bc9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105bd0:	00 
f0105bd1:	c7 44 24 04 7a 81 10 	movl   $0xf010817a,0x4(%esp)
f0105bd8:	f0 
f0105bd9:	89 1c 24             	mov    %ebx,(%esp)
f0105bdc:	e8 8c fc ff ff       	call   f010586d <memcmp>
f0105be1:	85 c0                	test   %eax,%eax
f0105be3:	74 11                	je     f0105bf6 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105be5:	c7 04 24 08 80 10 f0 	movl   $0xf0108008,(%esp)
f0105bec:	e8 3b e5 ff ff       	call   f010412c <cprintf>
f0105bf1:	e9 d3 01 00 00       	jmp    f0105dc9 <mp_init+0x2ef>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105bf6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105bfa:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105bfe:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105c01:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105c06:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c0b:	eb 0d                	jmp    f0105c1a <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f0105c0d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105c14:	f0 
f0105c15:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105c17:	83 c0 01             	add    $0x1,%eax
f0105c1a:	39 c7                	cmp    %eax,%edi
f0105c1c:	7f ef                	jg     f0105c0d <mp_init+0x133>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105c1e:	84 d2                	test   %dl,%dl
f0105c20:	74 11                	je     f0105c33 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105c22:	c7 04 24 3c 80 10 f0 	movl   $0xf010803c,(%esp)
f0105c29:	e8 fe e4 ff ff       	call   f010412c <cprintf>
f0105c2e:	e9 96 01 00 00       	jmp    f0105dc9 <mp_init+0x2ef>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105c33:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105c37:	3c 04                	cmp    $0x4,%al
f0105c39:	74 1f                	je     f0105c5a <mp_init+0x180>
f0105c3b:	3c 01                	cmp    $0x1,%al
f0105c3d:	8d 76 00             	lea    0x0(%esi),%esi
f0105c40:	74 18                	je     f0105c5a <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105c42:	0f b6 c0             	movzbl %al,%eax
f0105c45:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105c49:	c7 04 24 60 80 10 f0 	movl   $0xf0108060,(%esp)
f0105c50:	e8 d7 e4 ff ff       	call   f010412c <cprintf>
f0105c55:	e9 6f 01 00 00       	jmp    f0105dc9 <mp_init+0x2ef>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105c5a:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f0105c5e:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f0105c62:	01 df                	add    %ebx,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105c64:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105c69:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c6e:	eb 09                	jmp    f0105c79 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0105c70:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0105c74:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105c76:	83 c0 01             	add    $0x1,%eax
f0105c79:	39 c6                	cmp    %eax,%esi
f0105c7b:	7f f3                	jg     f0105c70 <mp_init+0x196>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105c7d:	02 53 2a             	add    0x2a(%ebx),%dl
f0105c80:	84 d2                	test   %dl,%dl
f0105c82:	74 11                	je     f0105c95 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105c84:	c7 04 24 80 80 10 f0 	movl   $0xf0108080,(%esp)
f0105c8b:	e8 9c e4 ff ff       	call   f010412c <cprintf>
f0105c90:	e9 34 01 00 00       	jmp    f0105dc9 <mp_init+0x2ef>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105c95:	85 db                	test   %ebx,%ebx
f0105c97:	0f 84 2c 01 00 00    	je     f0105dc9 <mp_init+0x2ef>
		return;
	ismp = 1;
f0105c9d:	c7 05 00 c0 22 f0 01 	movl   $0x1,0xf022c000
f0105ca4:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105ca7:	8b 43 24             	mov    0x24(%ebx),%eax
f0105caa:	a3 00 d0 26 f0       	mov    %eax,0xf026d000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105caf:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105cb2:	be 00 00 00 00       	mov    $0x0,%esi
f0105cb7:	e9 86 00 00 00       	jmp    f0105d42 <mp_init+0x268>
		switch (*p) {
f0105cbc:	0f b6 07             	movzbl (%edi),%eax
f0105cbf:	84 c0                	test   %al,%al
f0105cc1:	74 06                	je     f0105cc9 <mp_init+0x1ef>
f0105cc3:	3c 04                	cmp    $0x4,%al
f0105cc5:	77 57                	ja     f0105d1e <mp_init+0x244>
f0105cc7:	eb 50                	jmp    f0105d19 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105cc9:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105ccd:	8d 76 00             	lea    0x0(%esi),%esi
f0105cd0:	74 11                	je     f0105ce3 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f0105cd2:	6b 05 c4 c3 22 f0 74 	imul   $0x74,0xf022c3c4,%eax
f0105cd9:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0105cde:	a3 c0 c3 22 f0       	mov    %eax,0xf022c3c0
			if (ncpu < NCPU) {
f0105ce3:	a1 c4 c3 22 f0       	mov    0xf022c3c4,%eax
f0105ce8:	83 f8 07             	cmp    $0x7,%eax
f0105ceb:	7f 13                	jg     f0105d00 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f0105ced:	6b d0 74             	imul   $0x74,%eax,%edx
f0105cf0:	88 82 20 c0 22 f0    	mov    %al,-0xfdd3fe0(%edx)
				ncpu++;
f0105cf6:	83 c0 01             	add    $0x1,%eax
f0105cf9:	a3 c4 c3 22 f0       	mov    %eax,0xf022c3c4
f0105cfe:	eb 14                	jmp    f0105d14 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105d00:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105d04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105d08:	c7 04 24 b0 80 10 f0 	movl   $0xf01080b0,(%esp)
f0105d0f:	e8 18 e4 ff ff       	call   f010412c <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105d14:	83 c7 14             	add    $0x14,%edi
			continue;
f0105d17:	eb 26                	jmp    f0105d3f <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105d19:	83 c7 08             	add    $0x8,%edi
			continue;
f0105d1c:	eb 21                	jmp    f0105d3f <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105d1e:	0f b6 c0             	movzbl %al,%eax
f0105d21:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105d25:	c7 04 24 d8 80 10 f0 	movl   $0xf01080d8,(%esp)
f0105d2c:	e8 fb e3 ff ff       	call   f010412c <cprintf>
			ismp = 0;
f0105d31:	c7 05 00 c0 22 f0 00 	movl   $0x0,0xf022c000
f0105d38:	00 00 00 
			i = conf->entry;
f0105d3b:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105d3f:	83 c6 01             	add    $0x1,%esi
f0105d42:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105d46:	39 c6                	cmp    %eax,%esi
f0105d48:	0f 82 6e ff ff ff    	jb     f0105cbc <mp_init+0x1e2>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105d4e:	a1 c0 c3 22 f0       	mov    0xf022c3c0,%eax
f0105d53:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105d5a:	83 3d 00 c0 22 f0 00 	cmpl   $0x0,0xf022c000
f0105d61:	75 22                	jne    f0105d85 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105d63:	c7 05 c4 c3 22 f0 01 	movl   $0x1,0xf022c3c4
f0105d6a:	00 00 00 
		lapicaddr = 0;
f0105d6d:	c7 05 00 d0 26 f0 00 	movl   $0x0,0xf026d000
f0105d74:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105d77:	c7 04 24 f8 80 10 f0 	movl   $0xf01080f8,(%esp)
f0105d7e:	e8 a9 e3 ff ff       	call   f010412c <cprintf>
		return;
f0105d83:	eb 44                	jmp    f0105dc9 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105d85:	8b 15 c4 c3 22 f0    	mov    0xf022c3c4,%edx
f0105d8b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105d8f:	0f b6 00             	movzbl (%eax),%eax
f0105d92:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105d96:	c7 04 24 7f 81 10 f0 	movl   $0xf010817f,(%esp)
f0105d9d:	e8 8a e3 ff ff       	call   f010412c <cprintf>

	if (mp->imcrp) {
f0105da2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105da5:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105da9:	74 1e                	je     f0105dc9 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105dab:	c7 04 24 24 81 10 f0 	movl   $0xf0108124,(%esp)
f0105db2:	e8 75 e3 ff ff       	call   f010412c <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105db7:	ba 22 00 00 00       	mov    $0x22,%edx
f0105dbc:	b8 70 00 00 00       	mov    $0x70,%eax
f0105dc1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105dc2:	b2 23                	mov    $0x23,%dl
f0105dc4:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105dc5:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105dc8:	ee                   	out    %al,(%dx)
	}
}
f0105dc9:	83 c4 2c             	add    $0x2c,%esp
f0105dcc:	5b                   	pop    %ebx
f0105dcd:	5e                   	pop    %esi
f0105dce:	5f                   	pop    %edi
f0105dcf:	5d                   	pop    %ebp
f0105dd0:	c3                   	ret    

f0105dd1 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105dd1:	55                   	push   %ebp
f0105dd2:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105dd4:	8b 0d 04 d0 26 f0    	mov    0xf026d004,%ecx
f0105dda:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105ddd:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105ddf:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0105de4:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105de7:	5d                   	pop    %ebp
f0105de8:	c3                   	ret    

f0105de9 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105de9:	55                   	push   %ebp
f0105dea:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105dec:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0105df1:	85 c0                	test   %eax,%eax
f0105df3:	74 08                	je     f0105dfd <cpunum+0x14>
		return lapic[ID] >> 24;
f0105df5:	8b 40 20             	mov    0x20(%eax),%eax
f0105df8:	c1 e8 18             	shr    $0x18,%eax
f0105dfb:	eb 05                	jmp    f0105e02 <cpunum+0x19>
	return 0;
f0105dfd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105e02:	5d                   	pop    %ebp
f0105e03:	c3                   	ret    

f0105e04 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105e04:	a1 00 d0 26 f0       	mov    0xf026d000,%eax
f0105e09:	85 c0                	test   %eax,%eax
f0105e0b:	0f 84 23 01 00 00    	je     f0105f34 <lapic_init+0x130>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105e11:	55                   	push   %ebp
f0105e12:	89 e5                	mov    %esp,%ebp
f0105e14:	83 ec 18             	sub    $0x18,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105e17:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0105e1e:	00 
f0105e1f:	89 04 24             	mov    %eax,(%esp)
f0105e22:	e8 86 b7 ff ff       	call   f01015ad <mmio_map_region>
f0105e27:	a3 04 d0 26 f0       	mov    %eax,0xf026d004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105e2c:	ba 27 01 00 00       	mov    $0x127,%edx
f0105e31:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105e36:	e8 96 ff ff ff       	call   f0105dd1 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105e3b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105e40:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105e45:	e8 87 ff ff ff       	call   f0105dd1 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105e4a:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105e4f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105e54:	e8 78 ff ff ff       	call   f0105dd1 <lapicw>
	lapicw(TICR, 10000000); 
f0105e59:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105e5e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105e63:	e8 69 ff ff ff       	call   f0105dd1 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105e68:	e8 7c ff ff ff       	call   f0105de9 <cpunum>
f0105e6d:	6b c0 74             	imul   $0x74,%eax,%eax
f0105e70:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0105e75:	39 05 c0 c3 22 f0    	cmp    %eax,0xf022c3c0
f0105e7b:	74 0f                	je     f0105e8c <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f0105e7d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105e82:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105e87:	e8 45 ff ff ff       	call   f0105dd1 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105e8c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105e91:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105e96:	e8 36 ff ff ff       	call   f0105dd1 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105e9b:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0105ea0:	8b 40 30             	mov    0x30(%eax),%eax
f0105ea3:	c1 e8 10             	shr    $0x10,%eax
f0105ea6:	3c 03                	cmp    $0x3,%al
f0105ea8:	76 0f                	jbe    f0105eb9 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f0105eaa:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105eaf:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105eb4:	e8 18 ff ff ff       	call   f0105dd1 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105eb9:	ba 33 00 00 00       	mov    $0x33,%edx
f0105ebe:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105ec3:	e8 09 ff ff ff       	call   f0105dd1 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105ec8:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ecd:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105ed2:	e8 fa fe ff ff       	call   f0105dd1 <lapicw>
	lapicw(ESR, 0);
f0105ed7:	ba 00 00 00 00       	mov    $0x0,%edx
f0105edc:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105ee1:	e8 eb fe ff ff       	call   f0105dd1 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105ee6:	ba 00 00 00 00       	mov    $0x0,%edx
f0105eeb:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105ef0:	e8 dc fe ff ff       	call   f0105dd1 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105ef5:	ba 00 00 00 00       	mov    $0x0,%edx
f0105efa:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105eff:	e8 cd fe ff ff       	call   f0105dd1 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105f04:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105f09:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105f0e:	e8 be fe ff ff       	call   f0105dd1 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105f13:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f0105f19:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105f1f:	f6 c4 10             	test   $0x10,%ah
f0105f22:	75 f5                	jne    f0105f19 <lapic_init+0x115>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105f24:	ba 00 00 00 00       	mov    $0x0,%edx
f0105f29:	b8 20 00 00 00       	mov    $0x20,%eax
f0105f2e:	e8 9e fe ff ff       	call   f0105dd1 <lapicw>
}
f0105f33:	c9                   	leave  
f0105f34:	f3 c3                	repz ret 

f0105f36 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105f36:	83 3d 04 d0 26 f0 00 	cmpl   $0x0,0xf026d004
f0105f3d:	74 13                	je     f0105f52 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105f3f:	55                   	push   %ebp
f0105f40:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105f42:	ba 00 00 00 00       	mov    $0x0,%edx
f0105f47:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105f4c:	e8 80 fe ff ff       	call   f0105dd1 <lapicw>
}
f0105f51:	5d                   	pop    %ebp
f0105f52:	f3 c3                	repz ret 

f0105f54 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105f54:	55                   	push   %ebp
f0105f55:	89 e5                	mov    %esp,%ebp
f0105f57:	56                   	push   %esi
f0105f58:	53                   	push   %ebx
f0105f59:	83 ec 10             	sub    $0x10,%esp
f0105f5c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105f5f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105f62:	ba 70 00 00 00       	mov    $0x70,%edx
f0105f67:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105f6c:	ee                   	out    %al,(%dx)
f0105f6d:	b2 71                	mov    $0x71,%dl
f0105f6f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105f74:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105f75:	83 3d 88 be 22 f0 00 	cmpl   $0x0,0xf022be88
f0105f7c:	75 24                	jne    f0105fa2 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105f7e:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f0105f85:	00 
f0105f86:	c7 44 24 08 e4 64 10 	movl   $0xf01064e4,0x8(%esp)
f0105f8d:	f0 
f0105f8e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0105f95:	00 
f0105f96:	c7 04 24 9c 81 10 f0 	movl   $0xf010819c,(%esp)
f0105f9d:	e8 9e a0 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105fa2:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105fa9:	00 00 
	wrv[1] = addr >> 4;
f0105fab:	89 f0                	mov    %esi,%eax
f0105fad:	c1 e8 04             	shr    $0x4,%eax
f0105fb0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105fb6:	c1 e3 18             	shl    $0x18,%ebx
f0105fb9:	89 da                	mov    %ebx,%edx
f0105fbb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105fc0:	e8 0c fe ff ff       	call   f0105dd1 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105fc5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105fca:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105fcf:	e8 fd fd ff ff       	call   f0105dd1 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105fd4:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105fd9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105fde:	e8 ee fd ff ff       	call   f0105dd1 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105fe3:	c1 ee 0c             	shr    $0xc,%esi
f0105fe6:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105fec:	89 da                	mov    %ebx,%edx
f0105fee:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105ff3:	e8 d9 fd ff ff       	call   f0105dd1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105ff8:	89 f2                	mov    %esi,%edx
f0105ffa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105fff:	e8 cd fd ff ff       	call   f0105dd1 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0106004:	89 da                	mov    %ebx,%edx
f0106006:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010600b:	e8 c1 fd ff ff       	call   f0105dd1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0106010:	89 f2                	mov    %esi,%edx
f0106012:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106017:	e8 b5 fd ff ff       	call   f0105dd1 <lapicw>
		microdelay(200);
	}
}
f010601c:	83 c4 10             	add    $0x10,%esp
f010601f:	5b                   	pop    %ebx
f0106020:	5e                   	pop    %esi
f0106021:	5d                   	pop    %ebp
f0106022:	c3                   	ret    

f0106023 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0106023:	55                   	push   %ebp
f0106024:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0106026:	8b 55 08             	mov    0x8(%ebp),%edx
f0106029:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010602f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0106034:	e8 98 fd ff ff       	call   f0105dd1 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0106039:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f010603f:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0106045:	f6 c4 10             	test   $0x10,%ah
f0106048:	75 f5                	jne    f010603f <lapic_ipi+0x1c>
		;
}
f010604a:	5d                   	pop    %ebp
f010604b:	c3                   	ret    

f010604c <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010604c:	55                   	push   %ebp
f010604d:	89 e5                	mov    %esp,%ebp
f010604f:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0106052:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0106058:	8b 55 0c             	mov    0xc(%ebp),%edx
f010605b:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010605e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0106065:	5d                   	pop    %ebp
f0106066:	c3                   	ret    

f0106067 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0106067:	55                   	push   %ebp
f0106068:	89 e5                	mov    %esp,%ebp
f010606a:	56                   	push   %esi
f010606b:	53                   	push   %ebx
f010606c:	83 ec 20             	sub    $0x20,%esp
f010606f:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0106072:	83 3b 00             	cmpl   $0x0,(%ebx)
f0106075:	75 07                	jne    f010607e <spin_lock+0x17>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0106077:	ba 01 00 00 00       	mov    $0x1,%edx
f010607c:	eb 42                	jmp    f01060c0 <spin_lock+0x59>
f010607e:	8b 73 08             	mov    0x8(%ebx),%esi
f0106081:	e8 63 fd ff ff       	call   f0105de9 <cpunum>
f0106086:	6b c0 74             	imul   $0x74,%eax,%eax
f0106089:	05 20 c0 22 f0       	add    $0xf022c020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f010608e:	39 c6                	cmp    %eax,%esi
f0106090:	75 e5                	jne    f0106077 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0106092:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0106095:	e8 4f fd ff ff       	call   f0105de9 <cpunum>
f010609a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f010609e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01060a2:	c7 44 24 08 ac 81 10 	movl   $0xf01081ac,0x8(%esp)
f01060a9:	f0 
f01060aa:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f01060b1:	00 
f01060b2:	c7 04 24 10 82 10 f0 	movl   $0xf0108210,(%esp)
f01060b9:	e8 82 9f ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01060be:	f3 90                	pause  
f01060c0:	89 d0                	mov    %edx,%eax
f01060c2:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f01060c5:	85 c0                	test   %eax,%eax
f01060c7:	75 f5                	jne    f01060be <spin_lock+0x57>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f01060c9:	e8 1b fd ff ff       	call   f0105de9 <cpunum>
f01060ce:	6b c0 74             	imul   $0x74,%eax,%eax
f01060d1:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f01060d6:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f01060d9:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f01060dc:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f01060de:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01060e3:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01060e9:	76 12                	jbe    f01060fd <spin_lock+0x96>
			break;
		pcs[i] = ebp[1];          // saved %eip
f01060eb:	8b 4a 04             	mov    0x4(%edx),%ecx
f01060ee:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01060f1:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01060f3:	83 c0 01             	add    $0x1,%eax
f01060f6:	83 f8 0a             	cmp    $0xa,%eax
f01060f9:	75 e8                	jne    f01060e3 <spin_lock+0x7c>
f01060fb:	eb 0f                	jmp    f010610c <spin_lock+0xa5>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01060fd:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0106104:	83 c0 01             	add    $0x1,%eax
f0106107:	83 f8 09             	cmp    $0x9,%eax
f010610a:	7e f1                	jle    f01060fd <spin_lock+0x96>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010610c:	83 c4 20             	add    $0x20,%esp
f010610f:	5b                   	pop    %ebx
f0106110:	5e                   	pop    %esi
f0106111:	5d                   	pop    %ebp
f0106112:	c3                   	ret    

f0106113 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106113:	55                   	push   %ebp
f0106114:	89 e5                	mov    %esp,%ebp
f0106116:	57                   	push   %edi
f0106117:	56                   	push   %esi
f0106118:	53                   	push   %ebx
f0106119:	83 ec 6c             	sub    $0x6c,%esp
f010611c:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010611f:	83 3e 00             	cmpl   $0x0,(%esi)
f0106122:	74 18                	je     f010613c <spin_unlock+0x29>
f0106124:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106127:	e8 bd fc ff ff       	call   f0105de9 <cpunum>
f010612c:	6b c0 74             	imul   $0x74,%eax,%eax
f010612f:	05 20 c0 22 f0       	add    $0xf022c020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0106134:	39 c3                	cmp    %eax,%ebx
f0106136:	0f 84 ce 00 00 00    	je     f010620a <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010613c:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f0106143:	00 
f0106144:	8d 46 0c             	lea    0xc(%esi),%eax
f0106147:	89 44 24 04          	mov    %eax,0x4(%esp)
f010614b:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010614e:	89 1c 24             	mov    %ebx,(%esp)
f0106151:	e8 8e f6 ff ff       	call   f01057e4 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0106156:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0106159:	0f b6 38             	movzbl (%eax),%edi
f010615c:	8b 76 04             	mov    0x4(%esi),%esi
f010615f:	e8 85 fc ff ff       	call   f0105de9 <cpunum>
f0106164:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106168:	89 74 24 08          	mov    %esi,0x8(%esp)
f010616c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106170:	c7 04 24 d8 81 10 f0 	movl   $0xf01081d8,(%esp)
f0106177:	e8 b0 df ff ff       	call   f010412c <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010617c:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010617f:	eb 65                	jmp    f01061e6 <spin_unlock+0xd3>
f0106181:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106185:	89 04 24             	mov    %eax,(%esp)
f0106188:	e8 c9 ea ff ff       	call   f0104c56 <debuginfo_eip>
f010618d:	85 c0                	test   %eax,%eax
f010618f:	78 39                	js     f01061ca <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106191:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106193:	89 c2                	mov    %eax,%edx
f0106195:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106198:	89 54 24 18          	mov    %edx,0x18(%esp)
f010619c:	8b 55 b0             	mov    -0x50(%ebp),%edx
f010619f:	89 54 24 14          	mov    %edx,0x14(%esp)
f01061a3:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f01061a6:	89 54 24 10          	mov    %edx,0x10(%esp)
f01061aa:	8b 55 ac             	mov    -0x54(%ebp),%edx
f01061ad:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01061b1:	8b 55 a8             	mov    -0x58(%ebp),%edx
f01061b4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01061b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01061bc:	c7 04 24 20 82 10 f0 	movl   $0xf0108220,(%esp)
f01061c3:	e8 64 df ff ff       	call   f010412c <cprintf>
f01061c8:	eb 12                	jmp    f01061dc <spin_unlock+0xc9>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01061ca:	8b 06                	mov    (%esi),%eax
f01061cc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01061d0:	c7 04 24 37 82 10 f0 	movl   $0xf0108237,(%esp)
f01061d7:	e8 50 df ff ff       	call   f010412c <cprintf>
f01061dc:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01061df:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01061e2:	39 c3                	cmp    %eax,%ebx
f01061e4:	74 08                	je     f01061ee <spin_unlock+0xdb>
f01061e6:	89 de                	mov    %ebx,%esi
f01061e8:	8b 03                	mov    (%ebx),%eax
f01061ea:	85 c0                	test   %eax,%eax
f01061ec:	75 93                	jne    f0106181 <spin_unlock+0x6e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01061ee:	c7 44 24 08 3f 82 10 	movl   $0xf010823f,0x8(%esp)
f01061f5:	f0 
f01061f6:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f01061fd:	00 
f01061fe:	c7 04 24 10 82 10 f0 	movl   $0xf0108210,(%esp)
f0106205:	e8 36 9e ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f010620a:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106211:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0106218:	b8 00 00 00 00       	mov    $0x0,%eax
f010621d:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0106220:	83 c4 6c             	add    $0x6c,%esp
f0106223:	5b                   	pop    %ebx
f0106224:	5e                   	pop    %esi
f0106225:	5f                   	pop    %edi
f0106226:	5d                   	pop    %ebp
f0106227:	c3                   	ret    
f0106228:	66 90                	xchg   %ax,%ax
f010622a:	66 90                	xchg   %ax,%ax
f010622c:	66 90                	xchg   %ax,%ax
f010622e:	66 90                	xchg   %ax,%ax

f0106230 <__udivdi3>:
f0106230:	55                   	push   %ebp
f0106231:	57                   	push   %edi
f0106232:	56                   	push   %esi
f0106233:	83 ec 0c             	sub    $0xc,%esp
f0106236:	8b 44 24 28          	mov    0x28(%esp),%eax
f010623a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010623e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0106242:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106246:	85 c0                	test   %eax,%eax
f0106248:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010624c:	89 ea                	mov    %ebp,%edx
f010624e:	89 0c 24             	mov    %ecx,(%esp)
f0106251:	75 2d                	jne    f0106280 <__udivdi3+0x50>
f0106253:	39 e9                	cmp    %ebp,%ecx
f0106255:	77 61                	ja     f01062b8 <__udivdi3+0x88>
f0106257:	85 c9                	test   %ecx,%ecx
f0106259:	89 ce                	mov    %ecx,%esi
f010625b:	75 0b                	jne    f0106268 <__udivdi3+0x38>
f010625d:	b8 01 00 00 00       	mov    $0x1,%eax
f0106262:	31 d2                	xor    %edx,%edx
f0106264:	f7 f1                	div    %ecx
f0106266:	89 c6                	mov    %eax,%esi
f0106268:	31 d2                	xor    %edx,%edx
f010626a:	89 e8                	mov    %ebp,%eax
f010626c:	f7 f6                	div    %esi
f010626e:	89 c5                	mov    %eax,%ebp
f0106270:	89 f8                	mov    %edi,%eax
f0106272:	f7 f6                	div    %esi
f0106274:	89 ea                	mov    %ebp,%edx
f0106276:	83 c4 0c             	add    $0xc,%esp
f0106279:	5e                   	pop    %esi
f010627a:	5f                   	pop    %edi
f010627b:	5d                   	pop    %ebp
f010627c:	c3                   	ret    
f010627d:	8d 76 00             	lea    0x0(%esi),%esi
f0106280:	39 e8                	cmp    %ebp,%eax
f0106282:	77 24                	ja     f01062a8 <__udivdi3+0x78>
f0106284:	0f bd e8             	bsr    %eax,%ebp
f0106287:	83 f5 1f             	xor    $0x1f,%ebp
f010628a:	75 3c                	jne    f01062c8 <__udivdi3+0x98>
f010628c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0106290:	39 34 24             	cmp    %esi,(%esp)
f0106293:	0f 86 9f 00 00 00    	jbe    f0106338 <__udivdi3+0x108>
f0106299:	39 d0                	cmp    %edx,%eax
f010629b:	0f 82 97 00 00 00    	jb     f0106338 <__udivdi3+0x108>
f01062a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01062a8:	31 d2                	xor    %edx,%edx
f01062aa:	31 c0                	xor    %eax,%eax
f01062ac:	83 c4 0c             	add    $0xc,%esp
f01062af:	5e                   	pop    %esi
f01062b0:	5f                   	pop    %edi
f01062b1:	5d                   	pop    %ebp
f01062b2:	c3                   	ret    
f01062b3:	90                   	nop
f01062b4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01062b8:	89 f8                	mov    %edi,%eax
f01062ba:	f7 f1                	div    %ecx
f01062bc:	31 d2                	xor    %edx,%edx
f01062be:	83 c4 0c             	add    $0xc,%esp
f01062c1:	5e                   	pop    %esi
f01062c2:	5f                   	pop    %edi
f01062c3:	5d                   	pop    %ebp
f01062c4:	c3                   	ret    
f01062c5:	8d 76 00             	lea    0x0(%esi),%esi
f01062c8:	89 e9                	mov    %ebp,%ecx
f01062ca:	8b 3c 24             	mov    (%esp),%edi
f01062cd:	d3 e0                	shl    %cl,%eax
f01062cf:	89 c6                	mov    %eax,%esi
f01062d1:	b8 20 00 00 00       	mov    $0x20,%eax
f01062d6:	29 e8                	sub    %ebp,%eax
f01062d8:	89 c1                	mov    %eax,%ecx
f01062da:	d3 ef                	shr    %cl,%edi
f01062dc:	89 e9                	mov    %ebp,%ecx
f01062de:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01062e2:	8b 3c 24             	mov    (%esp),%edi
f01062e5:	09 74 24 08          	or     %esi,0x8(%esp)
f01062e9:	89 d6                	mov    %edx,%esi
f01062eb:	d3 e7                	shl    %cl,%edi
f01062ed:	89 c1                	mov    %eax,%ecx
f01062ef:	89 3c 24             	mov    %edi,(%esp)
f01062f2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01062f6:	d3 ee                	shr    %cl,%esi
f01062f8:	89 e9                	mov    %ebp,%ecx
f01062fa:	d3 e2                	shl    %cl,%edx
f01062fc:	89 c1                	mov    %eax,%ecx
f01062fe:	d3 ef                	shr    %cl,%edi
f0106300:	09 d7                	or     %edx,%edi
f0106302:	89 f2                	mov    %esi,%edx
f0106304:	89 f8                	mov    %edi,%eax
f0106306:	f7 74 24 08          	divl   0x8(%esp)
f010630a:	89 d6                	mov    %edx,%esi
f010630c:	89 c7                	mov    %eax,%edi
f010630e:	f7 24 24             	mull   (%esp)
f0106311:	39 d6                	cmp    %edx,%esi
f0106313:	89 14 24             	mov    %edx,(%esp)
f0106316:	72 30                	jb     f0106348 <__udivdi3+0x118>
f0106318:	8b 54 24 04          	mov    0x4(%esp),%edx
f010631c:	89 e9                	mov    %ebp,%ecx
f010631e:	d3 e2                	shl    %cl,%edx
f0106320:	39 c2                	cmp    %eax,%edx
f0106322:	73 05                	jae    f0106329 <__udivdi3+0xf9>
f0106324:	3b 34 24             	cmp    (%esp),%esi
f0106327:	74 1f                	je     f0106348 <__udivdi3+0x118>
f0106329:	89 f8                	mov    %edi,%eax
f010632b:	31 d2                	xor    %edx,%edx
f010632d:	e9 7a ff ff ff       	jmp    f01062ac <__udivdi3+0x7c>
f0106332:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106338:	31 d2                	xor    %edx,%edx
f010633a:	b8 01 00 00 00       	mov    $0x1,%eax
f010633f:	e9 68 ff ff ff       	jmp    f01062ac <__udivdi3+0x7c>
f0106344:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106348:	8d 47 ff             	lea    -0x1(%edi),%eax
f010634b:	31 d2                	xor    %edx,%edx
f010634d:	83 c4 0c             	add    $0xc,%esp
f0106350:	5e                   	pop    %esi
f0106351:	5f                   	pop    %edi
f0106352:	5d                   	pop    %ebp
f0106353:	c3                   	ret    
f0106354:	66 90                	xchg   %ax,%ax
f0106356:	66 90                	xchg   %ax,%ax
f0106358:	66 90                	xchg   %ax,%ax
f010635a:	66 90                	xchg   %ax,%ax
f010635c:	66 90                	xchg   %ax,%ax
f010635e:	66 90                	xchg   %ax,%ax

f0106360 <__umoddi3>:
f0106360:	55                   	push   %ebp
f0106361:	57                   	push   %edi
f0106362:	56                   	push   %esi
f0106363:	83 ec 14             	sub    $0x14,%esp
f0106366:	8b 44 24 28          	mov    0x28(%esp),%eax
f010636a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010636e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0106372:	89 c7                	mov    %eax,%edi
f0106374:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106378:	8b 44 24 30          	mov    0x30(%esp),%eax
f010637c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106380:	89 34 24             	mov    %esi,(%esp)
f0106383:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106387:	85 c0                	test   %eax,%eax
f0106389:	89 c2                	mov    %eax,%edx
f010638b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010638f:	75 17                	jne    f01063a8 <__umoddi3+0x48>
f0106391:	39 fe                	cmp    %edi,%esi
f0106393:	76 4b                	jbe    f01063e0 <__umoddi3+0x80>
f0106395:	89 c8                	mov    %ecx,%eax
f0106397:	89 fa                	mov    %edi,%edx
f0106399:	f7 f6                	div    %esi
f010639b:	89 d0                	mov    %edx,%eax
f010639d:	31 d2                	xor    %edx,%edx
f010639f:	83 c4 14             	add    $0x14,%esp
f01063a2:	5e                   	pop    %esi
f01063a3:	5f                   	pop    %edi
f01063a4:	5d                   	pop    %ebp
f01063a5:	c3                   	ret    
f01063a6:	66 90                	xchg   %ax,%ax
f01063a8:	39 f8                	cmp    %edi,%eax
f01063aa:	77 54                	ja     f0106400 <__umoddi3+0xa0>
f01063ac:	0f bd e8             	bsr    %eax,%ebp
f01063af:	83 f5 1f             	xor    $0x1f,%ebp
f01063b2:	75 5c                	jne    f0106410 <__umoddi3+0xb0>
f01063b4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01063b8:	39 3c 24             	cmp    %edi,(%esp)
f01063bb:	0f 87 e7 00 00 00    	ja     f01064a8 <__umoddi3+0x148>
f01063c1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01063c5:	29 f1                	sub    %esi,%ecx
f01063c7:	19 c7                	sbb    %eax,%edi
f01063c9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01063cd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01063d1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01063d5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01063d9:	83 c4 14             	add    $0x14,%esp
f01063dc:	5e                   	pop    %esi
f01063dd:	5f                   	pop    %edi
f01063de:	5d                   	pop    %ebp
f01063df:	c3                   	ret    
f01063e0:	85 f6                	test   %esi,%esi
f01063e2:	89 f5                	mov    %esi,%ebp
f01063e4:	75 0b                	jne    f01063f1 <__umoddi3+0x91>
f01063e6:	b8 01 00 00 00       	mov    $0x1,%eax
f01063eb:	31 d2                	xor    %edx,%edx
f01063ed:	f7 f6                	div    %esi
f01063ef:	89 c5                	mov    %eax,%ebp
f01063f1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01063f5:	31 d2                	xor    %edx,%edx
f01063f7:	f7 f5                	div    %ebp
f01063f9:	89 c8                	mov    %ecx,%eax
f01063fb:	f7 f5                	div    %ebp
f01063fd:	eb 9c                	jmp    f010639b <__umoddi3+0x3b>
f01063ff:	90                   	nop
f0106400:	89 c8                	mov    %ecx,%eax
f0106402:	89 fa                	mov    %edi,%edx
f0106404:	83 c4 14             	add    $0x14,%esp
f0106407:	5e                   	pop    %esi
f0106408:	5f                   	pop    %edi
f0106409:	5d                   	pop    %ebp
f010640a:	c3                   	ret    
f010640b:	90                   	nop
f010640c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106410:	8b 04 24             	mov    (%esp),%eax
f0106413:	be 20 00 00 00       	mov    $0x20,%esi
f0106418:	89 e9                	mov    %ebp,%ecx
f010641a:	29 ee                	sub    %ebp,%esi
f010641c:	d3 e2                	shl    %cl,%edx
f010641e:	89 f1                	mov    %esi,%ecx
f0106420:	d3 e8                	shr    %cl,%eax
f0106422:	89 e9                	mov    %ebp,%ecx
f0106424:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106428:	8b 04 24             	mov    (%esp),%eax
f010642b:	09 54 24 04          	or     %edx,0x4(%esp)
f010642f:	89 fa                	mov    %edi,%edx
f0106431:	d3 e0                	shl    %cl,%eax
f0106433:	89 f1                	mov    %esi,%ecx
f0106435:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106439:	8b 44 24 10          	mov    0x10(%esp),%eax
f010643d:	d3 ea                	shr    %cl,%edx
f010643f:	89 e9                	mov    %ebp,%ecx
f0106441:	d3 e7                	shl    %cl,%edi
f0106443:	89 f1                	mov    %esi,%ecx
f0106445:	d3 e8                	shr    %cl,%eax
f0106447:	89 e9                	mov    %ebp,%ecx
f0106449:	09 f8                	or     %edi,%eax
f010644b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010644f:	f7 74 24 04          	divl   0x4(%esp)
f0106453:	d3 e7                	shl    %cl,%edi
f0106455:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106459:	89 d7                	mov    %edx,%edi
f010645b:	f7 64 24 08          	mull   0x8(%esp)
f010645f:	39 d7                	cmp    %edx,%edi
f0106461:	89 c1                	mov    %eax,%ecx
f0106463:	89 14 24             	mov    %edx,(%esp)
f0106466:	72 2c                	jb     f0106494 <__umoddi3+0x134>
f0106468:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010646c:	72 22                	jb     f0106490 <__umoddi3+0x130>
f010646e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106472:	29 c8                	sub    %ecx,%eax
f0106474:	19 d7                	sbb    %edx,%edi
f0106476:	89 e9                	mov    %ebp,%ecx
f0106478:	89 fa                	mov    %edi,%edx
f010647a:	d3 e8                	shr    %cl,%eax
f010647c:	89 f1                	mov    %esi,%ecx
f010647e:	d3 e2                	shl    %cl,%edx
f0106480:	89 e9                	mov    %ebp,%ecx
f0106482:	d3 ef                	shr    %cl,%edi
f0106484:	09 d0                	or     %edx,%eax
f0106486:	89 fa                	mov    %edi,%edx
f0106488:	83 c4 14             	add    $0x14,%esp
f010648b:	5e                   	pop    %esi
f010648c:	5f                   	pop    %edi
f010648d:	5d                   	pop    %ebp
f010648e:	c3                   	ret    
f010648f:	90                   	nop
f0106490:	39 d7                	cmp    %edx,%edi
f0106492:	75 da                	jne    f010646e <__umoddi3+0x10e>
f0106494:	8b 14 24             	mov    (%esp),%edx
f0106497:	89 c1                	mov    %eax,%ecx
f0106499:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010649d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01064a1:	eb cb                	jmp    f010646e <__umoddi3+0x10e>
f01064a3:	90                   	nop
f01064a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01064a8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01064ac:	0f 82 0f ff ff ff    	jb     f01063c1 <__umoddi3+0x61>
f01064b2:	e9 1a ff ff ff       	jmp    f01063d1 <__umoddi3+0x71>
