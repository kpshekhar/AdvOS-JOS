
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
f010004b:	83 3d 00 bf 22 f0 00 	cmpl   $0x0,0xf022bf00
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 00 bf 22 f0    	mov    %esi,0xf022bf00

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 75 5c 00 00       	call   f0105cd9 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 c0 63 10 f0 	movl   $0xf01063c0,(%esp)
f010007d:	e8 8a 40 00 00       	call   f010410c <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 4b 40 00 00       	call   f01040d9 <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 32 7c 10 f0 	movl   $0xf0107c32,(%esp)
f0100095:	e8 72 40 00 00       	call   f010410c <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 df 08 00 00       	call   f0100985 <monitor>
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
f01000cc:	e8 b6 55 00 00       	call   f0105687 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000d1:	e8 a9 05 00 00       	call   f010067f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 2c 64 10 f0 	movl   $0xf010642c,(%esp)
f01000e5:	e8 22 40 00 00       	call   f010410c <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000ea:	e8 e6 14 00 00       	call   f01015d5 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000ef:	e8 bf 37 00 00       	call   f01038b3 <env_init>
	trap_init();
f01000f4:	e8 b8 40 00 00       	call   f01041b1 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000f9:	e8 cc 58 00 00       	call   f01059ca <mp_init>
	lapic_init();
f01000fe:	66 90                	xchg   %ax,%ax
f0100100:	e8 ef 5b 00 00       	call   f0105cf4 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f0100105:	e8 32 3f 00 00       	call   f010403c <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f010010a:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0100111:	e8 41 5e 00 00       	call   f0105f57 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100116:	83 3d 08 bf 22 f0 07 	cmpl   $0x7,0xf022bf08
f010011d:	77 24                	ja     f0100143 <i386_init+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010011f:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f0100126:	00 
f0100127:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f010012e:	f0 
f010012f:	c7 44 24 04 54 00 00 	movl   $0x54,0x4(%esp)
f0100136:	00 
f0100137:	c7 04 24 47 64 10 f0 	movl   $0xf0106447,(%esp)
f010013e:	e8 fd fe ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100143:	b8 02 59 10 f0       	mov    $0xf0105902,%eax
f0100148:	2d 88 58 10 f0       	sub    $0xf0105888,%eax
f010014d:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100151:	c7 44 24 04 88 58 10 	movl   $0xf0105888,0x4(%esp)
f0100158:	f0 
f0100159:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100160:	e8 6f 55 00 00       	call   f01056d4 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100165:	bb 20 c0 22 f0       	mov    $0xf022c020,%ebx
f010016a:	eb 4d                	jmp    f01001b9 <i386_init+0x111>
		if (c == cpus + cpunum())  // We've started already.
f010016c:	e8 68 5b 00 00       	call   f0105cd9 <cpunum>
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
f0100196:	a3 04 bf 22 f0       	mov    %eax,0xf022bf04
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010019b:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f01001a2:	00 
f01001a3:	0f b6 03             	movzbl (%ebx),%eax
f01001a6:	89 04 24             	mov    %eax,(%esp)
f01001a9:	e8 96 5c 00 00       	call   f0105e44 <lapic_startap>
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
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	// Touch all you want.
	ENV_CREATE(user_primes, ENV_TYPE_USER);
f01001c9:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001d0:	00 
f01001d1:	c7 04 24 fa 22 22 f0 	movl   $0xf02222fa,(%esp)
f01001d8:	e8 c9 38 00 00       	call   f0103aa6 <env_create>
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001dd:	e8 10 47 00 00       	call   f01048f2 <sched_yield>

f01001e2 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001e2:	55                   	push   %ebp
f01001e3:	89 e5                	mov    %esp,%ebp
f01001e5:	83 ec 18             	sub    $0x18,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001e8:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001ed:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001f2:	77 20                	ja     f0100214 <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001f8:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f01001ff:	f0 
f0100200:	c7 44 24 04 6b 00 00 	movl   $0x6b,0x4(%esp)
f0100207:	00 
f0100208:	c7 04 24 47 64 10 f0 	movl   $0xf0106447,(%esp)
f010020f:	e8 2c fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0100214:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0100219:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f010021c:	e8 b8 5a 00 00       	call   f0105cd9 <cpunum>
f0100221:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100225:	c7 04 24 53 64 10 f0 	movl   $0xf0106453,(%esp)
f010022c:	e8 db 3e 00 00       	call   f010410c <cprintf>

	lapic_init();
f0100231:	e8 be 5a 00 00       	call   f0105cf4 <lapic_init>
	env_init_percpu();
f0100236:	e8 4e 36 00 00       	call   f0103889 <env_init_percpu>
	trap_init_percpu();
f010023b:	90                   	nop
f010023c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100240:	e8 eb 3e 00 00       	call   f0104130 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100245:	e8 8f 5a 00 00       	call   f0105cd9 <cpunum>
f010024a:	6b d0 74             	imul   $0x74,%eax,%edx
f010024d:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100253:	b8 01 00 00 00       	mov    $0x1,%eax
f0100258:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010025c:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0100263:	e8 ef 5c 00 00       	call   f0105f57 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to run different envirenoments in all APs
f0100268:	e8 85 46 00 00       	call   f01048f2 <sched_yield>

f010026d <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010026d:	55                   	push   %ebp
f010026e:	89 e5                	mov    %esp,%ebp
f0100270:	53                   	push   %ebx
f0100271:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100274:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100277:	8b 45 0c             	mov    0xc(%ebp),%eax
f010027a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010027e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100281:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100285:	c7 04 24 69 64 10 f0 	movl   $0xf0106469,(%esp)
f010028c:	e8 7b 3e 00 00       	call   f010410c <cprintf>
	vcprintf(fmt, ap);
f0100291:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100295:	8b 45 10             	mov    0x10(%ebp),%eax
f0100298:	89 04 24             	mov    %eax,(%esp)
f010029b:	e8 39 3e 00 00       	call   f01040d9 <vcprintf>
	cprintf("\n");
f01002a0:	c7 04 24 32 7c 10 f0 	movl   $0xf0107c32,(%esp)
f01002a7:	e8 60 3e 00 00       	call   f010410c <cprintf>
	va_end(ap);
}
f01002ac:	83 c4 14             	add    $0x14,%esp
f01002af:	5b                   	pop    %ebx
f01002b0:	5d                   	pop    %ebp
f01002b1:	c3                   	ret    
f01002b2:	66 90                	xchg   %ax,%ax
f01002b4:	66 90                	xchg   %ax,%ax
f01002b6:	66 90                	xchg   %ax,%ax
f01002b8:	66 90                	xchg   %ax,%ax
f01002ba:	66 90                	xchg   %ax,%ax
f01002bc:	66 90                	xchg   %ax,%ax
f01002be:	66 90                	xchg   %ax,%ax

f01002c0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002c0:	55                   	push   %ebp
f01002c1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002c3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002c8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002c9:	a8 01                	test   $0x1,%al
f01002cb:	74 08                	je     f01002d5 <serial_proc_data+0x15>
f01002cd:	b2 f8                	mov    $0xf8,%dl
f01002cf:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002d0:	0f b6 c0             	movzbl %al,%eax
f01002d3:	eb 05                	jmp    f01002da <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002d5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002da:	5d                   	pop    %ebp
f01002db:	c3                   	ret    

f01002dc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002dc:	55                   	push   %ebp
f01002dd:	89 e5                	mov    %esp,%ebp
f01002df:	53                   	push   %ebx
f01002e0:	83 ec 04             	sub    $0x4,%esp
f01002e3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002e5:	eb 2a                	jmp    f0100311 <cons_intr+0x35>
		if (c == 0)
f01002e7:	85 d2                	test   %edx,%edx
f01002e9:	74 26                	je     f0100311 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002eb:	a1 24 b2 22 f0       	mov    0xf022b224,%eax
f01002f0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002f3:	89 0d 24 b2 22 f0    	mov    %ecx,0xf022b224
f01002f9:	88 90 20 b0 22 f0    	mov    %dl,-0xfdd4fe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002ff:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f0100305:	75 0a                	jne    f0100311 <cons_intr+0x35>
			cons.wpos = 0;
f0100307:	c7 05 24 b2 22 f0 00 	movl   $0x0,0xf022b224
f010030e:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f0100311:	ff d3                	call   *%ebx
f0100313:	89 c2                	mov    %eax,%edx
f0100315:	83 f8 ff             	cmp    $0xffffffff,%eax
f0100318:	75 cd                	jne    f01002e7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f010031a:	83 c4 04             	add    $0x4,%esp
f010031d:	5b                   	pop    %ebx
f010031e:	5d                   	pop    %ebp
f010031f:	c3                   	ret    

f0100320 <kbd_proc_data>:
f0100320:	ba 64 00 00 00       	mov    $0x64,%edx
f0100325:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100326:	a8 01                	test   $0x1,%al
f0100328:	0f 84 ef 00 00 00    	je     f010041d <kbd_proc_data+0xfd>
f010032e:	b2 60                	mov    $0x60,%dl
f0100330:	ec                   	in     (%dx),%al
f0100331:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100333:	3c e0                	cmp    $0xe0,%al
f0100335:	75 0d                	jne    f0100344 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100337:	83 0d 00 b0 22 f0 40 	orl    $0x40,0xf022b000
		return 0;
f010033e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100343:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100344:	55                   	push   %ebp
f0100345:	89 e5                	mov    %esp,%ebp
f0100347:	53                   	push   %ebx
f0100348:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010034b:	84 c0                	test   %al,%al
f010034d:	79 37                	jns    f0100386 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010034f:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f0100355:	89 cb                	mov    %ecx,%ebx
f0100357:	83 e3 40             	and    $0x40,%ebx
f010035a:	83 e0 7f             	and    $0x7f,%eax
f010035d:	85 db                	test   %ebx,%ebx
f010035f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100362:	0f b6 d2             	movzbl %dl,%edx
f0100365:	0f b6 82 e0 65 10 f0 	movzbl -0xfef9a20(%edx),%eax
f010036c:	83 c8 40             	or     $0x40,%eax
f010036f:	0f b6 c0             	movzbl %al,%eax
f0100372:	f7 d0                	not    %eax
f0100374:	21 c1                	and    %eax,%ecx
f0100376:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
		return 0;
f010037c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100381:	e9 9d 00 00 00       	jmp    f0100423 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100386:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f010038c:	f6 c1 40             	test   $0x40,%cl
f010038f:	74 0e                	je     f010039f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100391:	83 c8 80             	or     $0xffffff80,%eax
f0100394:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100396:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100399:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
	}

	shift |= shiftcode[data];
f010039f:	0f b6 d2             	movzbl %dl,%edx
f01003a2:	0f b6 82 e0 65 10 f0 	movzbl -0xfef9a20(%edx),%eax
f01003a9:	0b 05 00 b0 22 f0    	or     0xf022b000,%eax
	shift ^= togglecode[data];
f01003af:	0f b6 8a e0 64 10 f0 	movzbl -0xfef9b20(%edx),%ecx
f01003b6:	31 c8                	xor    %ecx,%eax
f01003b8:	a3 00 b0 22 f0       	mov    %eax,0xf022b000

	c = charcode[shift & (CTL | SHIFT)][data];
f01003bd:	89 c1                	mov    %eax,%ecx
f01003bf:	83 e1 03             	and    $0x3,%ecx
f01003c2:	8b 0c 8d c0 64 10 f0 	mov    -0xfef9b40(,%ecx,4),%ecx
f01003c9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003cd:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003d0:	a8 08                	test   $0x8,%al
f01003d2:	74 1b                	je     f01003ef <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01003d4:	89 da                	mov    %ebx,%edx
f01003d6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003d9:	83 f9 19             	cmp    $0x19,%ecx
f01003dc:	77 05                	ja     f01003e3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01003de:	83 eb 20             	sub    $0x20,%ebx
f01003e1:	eb 0c                	jmp    f01003ef <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01003e3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003e6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003e9:	83 fa 19             	cmp    $0x19,%edx
f01003ec:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003ef:	f7 d0                	not    %eax
f01003f1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003f5:	f6 c2 06             	test   $0x6,%dl
f01003f8:	75 29                	jne    f0100423 <kbd_proc_data+0x103>
f01003fa:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100400:	75 21                	jne    f0100423 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f0100402:	c7 04 24 83 64 10 f0 	movl   $0xf0106483,(%esp)
f0100409:	e8 fe 3c 00 00       	call   f010410c <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010040e:	ba 92 00 00 00       	mov    $0x92,%edx
f0100413:	b8 03 00 00 00       	mov    $0x3,%eax
f0100418:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f0100419:	89 d8                	mov    %ebx,%eax
f010041b:	eb 06                	jmp    f0100423 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f010041d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100422:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100423:	83 c4 14             	add    $0x14,%esp
f0100426:	5b                   	pop    %ebx
f0100427:	5d                   	pop    %ebp
f0100428:	c3                   	ret    

f0100429 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100429:	55                   	push   %ebp
f010042a:	89 e5                	mov    %esp,%ebp
f010042c:	57                   	push   %edi
f010042d:	56                   	push   %esi
f010042e:	53                   	push   %ebx
f010042f:	83 ec 1c             	sub    $0x1c,%esp
f0100432:	89 c7                	mov    %eax,%edi
f0100434:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100439:	be fd 03 00 00       	mov    $0x3fd,%esi
f010043e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100443:	eb 06                	jmp    f010044b <cons_putc+0x22>
f0100445:	89 ca                	mov    %ecx,%edx
f0100447:	ec                   	in     (%dx),%al
f0100448:	ec                   	in     (%dx),%al
f0100449:	ec                   	in     (%dx),%al
f010044a:	ec                   	in     (%dx),%al
f010044b:	89 f2                	mov    %esi,%edx
f010044d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010044e:	a8 20                	test   $0x20,%al
f0100450:	75 05                	jne    f0100457 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100452:	83 eb 01             	sub    $0x1,%ebx
f0100455:	75 ee                	jne    f0100445 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100457:	89 f8                	mov    %edi,%eax
f0100459:	0f b6 c0             	movzbl %al,%eax
f010045c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010045f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100464:	ee                   	out    %al,(%dx)
f0100465:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010046a:	be 79 03 00 00       	mov    $0x379,%esi
f010046f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100474:	eb 06                	jmp    f010047c <cons_putc+0x53>
f0100476:	89 ca                	mov    %ecx,%edx
f0100478:	ec                   	in     (%dx),%al
f0100479:	ec                   	in     (%dx),%al
f010047a:	ec                   	in     (%dx),%al
f010047b:	ec                   	in     (%dx),%al
f010047c:	89 f2                	mov    %esi,%edx
f010047e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010047f:	84 c0                	test   %al,%al
f0100481:	78 05                	js     f0100488 <cons_putc+0x5f>
f0100483:	83 eb 01             	sub    $0x1,%ebx
f0100486:	75 ee                	jne    f0100476 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100488:	ba 78 03 00 00       	mov    $0x378,%edx
f010048d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100491:	ee                   	out    %al,(%dx)
f0100492:	b2 7a                	mov    $0x7a,%dl
f0100494:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100499:	ee                   	out    %al,(%dx)
f010049a:	b8 08 00 00 00       	mov    $0x8,%eax
f010049f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f01004a0:	89 fa                	mov    %edi,%edx
f01004a2:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f01004a8:	89 f8                	mov    %edi,%eax
f01004aa:	80 cc 07             	or     $0x7,%ah
f01004ad:	85 d2                	test   %edx,%edx
f01004af:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f01004b2:	89 f8                	mov    %edi,%eax
f01004b4:	0f b6 c0             	movzbl %al,%eax
f01004b7:	83 f8 09             	cmp    $0x9,%eax
f01004ba:	74 76                	je     f0100532 <cons_putc+0x109>
f01004bc:	83 f8 09             	cmp    $0x9,%eax
f01004bf:	7f 0a                	jg     f01004cb <cons_putc+0xa2>
f01004c1:	83 f8 08             	cmp    $0x8,%eax
f01004c4:	74 16                	je     f01004dc <cons_putc+0xb3>
f01004c6:	e9 9b 00 00 00       	jmp    f0100566 <cons_putc+0x13d>
f01004cb:	83 f8 0a             	cmp    $0xa,%eax
f01004ce:	66 90                	xchg   %ax,%ax
f01004d0:	74 3a                	je     f010050c <cons_putc+0xe3>
f01004d2:	83 f8 0d             	cmp    $0xd,%eax
f01004d5:	74 3d                	je     f0100514 <cons_putc+0xeb>
f01004d7:	e9 8a 00 00 00       	jmp    f0100566 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01004dc:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f01004e3:	66 85 c0             	test   %ax,%ax
f01004e6:	0f 84 e5 00 00 00    	je     f01005d1 <cons_putc+0x1a8>
			crt_pos--;
f01004ec:	83 e8 01             	sub    $0x1,%eax
f01004ef:	66 a3 28 b2 22 f0    	mov    %ax,0xf022b228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004f5:	0f b7 c0             	movzwl %ax,%eax
f01004f8:	66 81 e7 00 ff       	and    $0xff00,%di
f01004fd:	83 cf 20             	or     $0x20,%edi
f0100500:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
f0100506:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f010050a:	eb 78                	jmp    f0100584 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010050c:	66 83 05 28 b2 22 f0 	addw   $0x50,0xf022b228
f0100513:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100514:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f010051b:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100521:	c1 e8 16             	shr    $0x16,%eax
f0100524:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100527:	c1 e0 04             	shl    $0x4,%eax
f010052a:	66 a3 28 b2 22 f0    	mov    %ax,0xf022b228
f0100530:	eb 52                	jmp    f0100584 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100532:	b8 20 00 00 00       	mov    $0x20,%eax
f0100537:	e8 ed fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f010053c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100541:	e8 e3 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100546:	b8 20 00 00 00       	mov    $0x20,%eax
f010054b:	e8 d9 fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f0100550:	b8 20 00 00 00       	mov    $0x20,%eax
f0100555:	e8 cf fe ff ff       	call   f0100429 <cons_putc>
		cons_putc(' ');
f010055a:	b8 20 00 00 00       	mov    $0x20,%eax
f010055f:	e8 c5 fe ff ff       	call   f0100429 <cons_putc>
f0100564:	eb 1e                	jmp    f0100584 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100566:	0f b7 05 28 b2 22 f0 	movzwl 0xf022b228,%eax
f010056d:	8d 50 01             	lea    0x1(%eax),%edx
f0100570:	66 89 15 28 b2 22 f0 	mov    %dx,0xf022b228
f0100577:	0f b7 c0             	movzwl %ax,%eax
f010057a:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
f0100580:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100584:	66 81 3d 28 b2 22 f0 	cmpw   $0x7cf,0xf022b228
f010058b:	cf 07 
f010058d:	76 42                	jbe    f01005d1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010058f:	a1 2c b2 22 f0       	mov    0xf022b22c,%eax
f0100594:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010059b:	00 
f010059c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f01005a2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01005a6:	89 04 24             	mov    %eax,(%esp)
f01005a9:	e8 26 51 00 00       	call   f01056d4 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f01005ae:	8b 15 2c b2 22 f0    	mov    0xf022b22c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005b4:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f01005b9:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f01005bf:	83 c0 01             	add    $0x1,%eax
f01005c2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005c7:	75 f0                	jne    f01005b9 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005c9:	66 83 2d 28 b2 22 f0 	subw   $0x50,0xf022b228
f01005d0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005d1:	8b 0d 30 b2 22 f0    	mov    0xf022b230,%ecx
f01005d7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005dc:	89 ca                	mov    %ecx,%edx
f01005de:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005df:	0f b7 1d 28 b2 22 f0 	movzwl 0xf022b228,%ebx
f01005e6:	8d 71 01             	lea    0x1(%ecx),%esi
f01005e9:	89 d8                	mov    %ebx,%eax
f01005eb:	66 c1 e8 08          	shr    $0x8,%ax
f01005ef:	89 f2                	mov    %esi,%edx
f01005f1:	ee                   	out    %al,(%dx)
f01005f2:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005f7:	89 ca                	mov    %ecx,%edx
f01005f9:	ee                   	out    %al,(%dx)
f01005fa:	89 d8                	mov    %ebx,%eax
f01005fc:	89 f2                	mov    %esi,%edx
f01005fe:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005ff:	83 c4 1c             	add    $0x1c,%esp
f0100602:	5b                   	pop    %ebx
f0100603:	5e                   	pop    %esi
f0100604:	5f                   	pop    %edi
f0100605:	5d                   	pop    %ebp
f0100606:	c3                   	ret    

f0100607 <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f0100607:	80 3d 34 b2 22 f0 00 	cmpb   $0x0,0xf022b234
f010060e:	74 11                	je     f0100621 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f0100610:	55                   	push   %ebp
f0100611:	89 e5                	mov    %esp,%ebp
f0100613:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f0100616:	b8 c0 02 10 f0       	mov    $0xf01002c0,%eax
f010061b:	e8 bc fc ff ff       	call   f01002dc <cons_intr>
}
f0100620:	c9                   	leave  
f0100621:	f3 c3                	repz ret 

f0100623 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f0100623:	55                   	push   %ebp
f0100624:	89 e5                	mov    %esp,%ebp
f0100626:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100629:	b8 20 03 10 f0       	mov    $0xf0100320,%eax
f010062e:	e8 a9 fc ff ff       	call   f01002dc <cons_intr>
}
f0100633:	c9                   	leave  
f0100634:	c3                   	ret    

f0100635 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100635:	55                   	push   %ebp
f0100636:	89 e5                	mov    %esp,%ebp
f0100638:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f010063b:	e8 c7 ff ff ff       	call   f0100607 <serial_intr>
	kbd_intr();
f0100640:	e8 de ff ff ff       	call   f0100623 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100645:	a1 20 b2 22 f0       	mov    0xf022b220,%eax
f010064a:	3b 05 24 b2 22 f0    	cmp    0xf022b224,%eax
f0100650:	74 26                	je     f0100678 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100652:	8d 50 01             	lea    0x1(%eax),%edx
f0100655:	89 15 20 b2 22 f0    	mov    %edx,0xf022b220
f010065b:	0f b6 88 20 b0 22 f0 	movzbl -0xfdd4fe0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100662:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100664:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010066a:	75 11                	jne    f010067d <cons_getc+0x48>
			cons.rpos = 0;
f010066c:	c7 05 20 b2 22 f0 00 	movl   $0x0,0xf022b220
f0100673:	00 00 00 
f0100676:	eb 05                	jmp    f010067d <cons_getc+0x48>
		return c;
	}
	return 0;
f0100678:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010067d:	c9                   	leave  
f010067e:	c3                   	ret    

f010067f <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f010067f:	55                   	push   %ebp
f0100680:	89 e5                	mov    %esp,%ebp
f0100682:	57                   	push   %edi
f0100683:	56                   	push   %esi
f0100684:	53                   	push   %ebx
f0100685:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f0100688:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f010068f:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f0100696:	5a a5 
	if (*cp != 0xA55A) {
f0100698:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f010069f:	66 3d 5a a5          	cmp    $0xa55a,%ax
f01006a3:	74 11                	je     f01006b6 <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f01006a5:	c7 05 30 b2 22 f0 b4 	movl   $0x3b4,0xf022b230
f01006ac:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f01006af:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f01006b4:	eb 16                	jmp    f01006cc <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f01006b6:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01006bd:	c7 05 30 b2 22 f0 d4 	movl   $0x3d4,0xf022b230
f01006c4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006c7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006cc:	8b 0d 30 b2 22 f0    	mov    0xf022b230,%ecx
f01006d2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006d7:	89 ca                	mov    %ecx,%edx
f01006d9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006da:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006dd:	89 da                	mov    %ebx,%edx
f01006df:	ec                   	in     (%dx),%al
f01006e0:	0f b6 f0             	movzbl %al,%esi
f01006e3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006e6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006eb:	89 ca                	mov    %ecx,%edx
f01006ed:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ee:	89 da                	mov    %ebx,%edx
f01006f0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006f1:	89 3d 2c b2 22 f0    	mov    %edi,0xf022b22c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006f7:	0f b6 d8             	movzbl %al,%ebx
f01006fa:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006fc:	66 89 35 28 b2 22 f0 	mov    %si,0xf022b228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f0100703:	e8 1b ff ff ff       	call   f0100623 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f0100708:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f010070f:	25 fd ff 00 00       	and    $0xfffd,%eax
f0100714:	89 04 24             	mov    %eax,(%esp)
f0100717:	e8 b1 38 00 00       	call   f0103fcd <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010071c:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100721:	b8 00 00 00 00       	mov    $0x0,%eax
f0100726:	89 f2                	mov    %esi,%edx
f0100728:	ee                   	out    %al,(%dx)
f0100729:	b2 fb                	mov    $0xfb,%dl
f010072b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100730:	ee                   	out    %al,(%dx)
f0100731:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100736:	b8 0c 00 00 00       	mov    $0xc,%eax
f010073b:	89 da                	mov    %ebx,%edx
f010073d:	ee                   	out    %al,(%dx)
f010073e:	b2 f9                	mov    $0xf9,%dl
f0100740:	b8 00 00 00 00       	mov    $0x0,%eax
f0100745:	ee                   	out    %al,(%dx)
f0100746:	b2 fb                	mov    $0xfb,%dl
f0100748:	b8 03 00 00 00       	mov    $0x3,%eax
f010074d:	ee                   	out    %al,(%dx)
f010074e:	b2 fc                	mov    $0xfc,%dl
f0100750:	b8 00 00 00 00       	mov    $0x0,%eax
f0100755:	ee                   	out    %al,(%dx)
f0100756:	b2 f9                	mov    $0xf9,%dl
f0100758:	b8 01 00 00 00       	mov    $0x1,%eax
f010075d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010075e:	b2 fd                	mov    $0xfd,%dl
f0100760:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100761:	3c ff                	cmp    $0xff,%al
f0100763:	0f 95 c1             	setne  %cl
f0100766:	88 0d 34 b2 22 f0    	mov    %cl,0xf022b234
f010076c:	89 f2                	mov    %esi,%edx
f010076e:	ec                   	in     (%dx),%al
f010076f:	89 da                	mov    %ebx,%edx
f0100771:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100772:	84 c9                	test   %cl,%cl
f0100774:	75 0c                	jne    f0100782 <cons_init+0x103>
		cprintf("Serial port does not exist!\n");
f0100776:	c7 04 24 8f 64 10 f0 	movl   $0xf010648f,(%esp)
f010077d:	e8 8a 39 00 00       	call   f010410c <cprintf>
}
f0100782:	83 c4 1c             	add    $0x1c,%esp
f0100785:	5b                   	pop    %ebx
f0100786:	5e                   	pop    %esi
f0100787:	5f                   	pop    %edi
f0100788:	5d                   	pop    %ebp
f0100789:	c3                   	ret    

f010078a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010078a:	55                   	push   %ebp
f010078b:	89 e5                	mov    %esp,%ebp
f010078d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100790:	8b 45 08             	mov    0x8(%ebp),%eax
f0100793:	e8 91 fc ff ff       	call   f0100429 <cons_putc>
}
f0100798:	c9                   	leave  
f0100799:	c3                   	ret    

f010079a <getchar>:

int
getchar(void)
{
f010079a:	55                   	push   %ebp
f010079b:	89 e5                	mov    %esp,%ebp
f010079d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f01007a0:	e8 90 fe ff ff       	call   f0100635 <cons_getc>
f01007a5:	85 c0                	test   %eax,%eax
f01007a7:	74 f7                	je     f01007a0 <getchar+0x6>
		/* do nothing */;
	return c;
}
f01007a9:	c9                   	leave  
f01007aa:	c3                   	ret    

f01007ab <iscons>:

int
iscons(int fdnum)
{
f01007ab:	55                   	push   %ebp
f01007ac:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f01007ae:	b8 01 00 00 00       	mov    $0x1,%eax
f01007b3:	5d                   	pop    %ebp
f01007b4:	c3                   	ret    
f01007b5:	66 90                	xchg   %ax,%ax
f01007b7:	66 90                	xchg   %ax,%ax
f01007b9:	66 90                	xchg   %ax,%ax
f01007bb:	66 90                	xchg   %ax,%ax
f01007bd:	66 90                	xchg   %ax,%ax
f01007bf:	90                   	nop

f01007c0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007c0:	55                   	push   %ebp
f01007c1:	89 e5                	mov    %esp,%ebp
f01007c3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007c6:	c7 44 24 08 e0 66 10 	movl   $0xf01066e0,0x8(%esp)
f01007cd:	f0 
f01007ce:	c7 44 24 04 fe 66 10 	movl   $0xf01066fe,0x4(%esp)
f01007d5:	f0 
f01007d6:	c7 04 24 03 67 10 f0 	movl   $0xf0106703,(%esp)
f01007dd:	e8 2a 39 00 00       	call   f010410c <cprintf>
f01007e2:	c7 44 24 08 a4 67 10 	movl   $0xf01067a4,0x8(%esp)
f01007e9:	f0 
f01007ea:	c7 44 24 04 0c 67 10 	movl   $0xf010670c,0x4(%esp)
f01007f1:	f0 
f01007f2:	c7 04 24 03 67 10 f0 	movl   $0xf0106703,(%esp)
f01007f9:	e8 0e 39 00 00       	call   f010410c <cprintf>
f01007fe:	c7 44 24 08 15 67 10 	movl   $0xf0106715,0x8(%esp)
f0100805:	f0 
f0100806:	c7 44 24 04 32 67 10 	movl   $0xf0106732,0x4(%esp)
f010080d:	f0 
f010080e:	c7 04 24 03 67 10 f0 	movl   $0xf0106703,(%esp)
f0100815:	e8 f2 38 00 00       	call   f010410c <cprintf>
	return 0;
}
f010081a:	b8 00 00 00 00       	mov    $0x0,%eax
f010081f:	c9                   	leave  
f0100820:	c3                   	ret    

f0100821 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100821:	55                   	push   %ebp
f0100822:	89 e5                	mov    %esp,%ebp
f0100824:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100827:	c7 04 24 3d 67 10 f0 	movl   $0xf010673d,(%esp)
f010082e:	e8 d9 38 00 00       	call   f010410c <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100833:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010083a:	00 
f010083b:	c7 04 24 cc 67 10 f0 	movl   $0xf01067cc,(%esp)
f0100842:	e8 c5 38 00 00       	call   f010410c <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100847:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010084e:	00 
f010084f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100856:	f0 
f0100857:	c7 04 24 f4 67 10 f0 	movl   $0xf01067f4,(%esp)
f010085e:	e8 a9 38 00 00       	call   f010410c <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100863:	c7 44 24 08 a7 63 10 	movl   $0x1063a7,0x8(%esp)
f010086a:	00 
f010086b:	c7 44 24 04 a7 63 10 	movl   $0xf01063a7,0x4(%esp)
f0100872:	f0 
f0100873:	c7 04 24 18 68 10 f0 	movl   $0xf0106818,(%esp)
f010087a:	e8 8d 38 00 00       	call   f010410c <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010087f:	c7 44 24 08 07 ad 22 	movl   $0x22ad07,0x8(%esp)
f0100886:	00 
f0100887:	c7 44 24 04 07 ad 22 	movl   $0xf022ad07,0x4(%esp)
f010088e:	f0 
f010088f:	c7 04 24 3c 68 10 f0 	movl   $0xf010683c,(%esp)
f0100896:	e8 71 38 00 00       	call   f010410c <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010089b:	c7 44 24 08 08 d0 26 	movl   $0x26d008,0x8(%esp)
f01008a2:	00 
f01008a3:	c7 44 24 04 08 d0 26 	movl   $0xf026d008,0x4(%esp)
f01008aa:	f0 
f01008ab:	c7 04 24 60 68 10 f0 	movl   $0xf0106860,(%esp)
f01008b2:	e8 55 38 00 00       	call   f010410c <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01008b7:	b8 07 d4 26 f0       	mov    $0xf026d407,%eax
f01008bc:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008c1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008c6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008cc:	85 c0                	test   %eax,%eax
f01008ce:	0f 48 c2             	cmovs  %edx,%eax
f01008d1:	c1 f8 0a             	sar    $0xa,%eax
f01008d4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008d8:	c7 04 24 84 68 10 f0 	movl   $0xf0106884,(%esp)
f01008df:	e8 28 38 00 00       	call   f010410c <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008e4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008e9:	c9                   	leave  
f01008ea:	c3                   	ret    

f01008eb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008eb:	55                   	push   %ebp
f01008ec:	89 e5                	mov    %esp,%ebp
f01008ee:	57                   	push   %edi
f01008ef:	56                   	push   %esi
f01008f0:	53                   	push   %ebx
f01008f1:	83 ec 6c             	sub    $0x6c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008f4:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01008f6:	c7 04 24 56 67 10 f0 	movl   $0xf0106756,(%esp)
f01008fd:	e8 0a 38 00 00       	call   f010410c <cprintf>
	
	while (ebp){
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f0100902:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100905:	eb 6d                	jmp    f0100974 <mon_backtrace+0x89>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f0100907:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f010090a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010090e:	89 34 24             	mov    %esi,(%esp)
f0100911:	e8 36 42 00 00       	call   f0104b4c <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f0100916:	89 f0                	mov    %esi,%eax
f0100918:	2b 45 e0             	sub    -0x20(%ebp),%eax
f010091b:	89 44 24 30          	mov    %eax,0x30(%esp)
f010091f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100922:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f0100926:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100929:	89 44 24 28          	mov    %eax,0x28(%esp)
f010092d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100930:	89 44 24 24          	mov    %eax,0x24(%esp)
f0100934:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100937:	89 44 24 20          	mov    %eax,0x20(%esp)
f010093b:	8b 43 18             	mov    0x18(%ebx),%eax
f010093e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100942:	8b 43 14             	mov    0x14(%ebx),%eax
f0100945:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100949:	8b 43 10             	mov    0x10(%ebx),%eax
f010094c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100950:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100953:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100957:	8b 43 08             	mov    0x8(%ebx),%eax
f010095a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010095e:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100962:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100966:	c7 04 24 b0 68 10 f0 	movl   $0xf01068b0,(%esp)
f010096d:	e8 9a 37 00 00       	call   f010410c <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f0100972:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100974:	85 db                	test   %ebx,%ebx
f0100976:	75 8f                	jne    f0100907 <mon_backtrace+0x1c>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100978:	b8 00 00 00 00       	mov    $0x0,%eax
f010097d:	83 c4 6c             	add    $0x6c,%esp
f0100980:	5b                   	pop    %ebx
f0100981:	5e                   	pop    %esi
f0100982:	5f                   	pop    %edi
f0100983:	5d                   	pop    %ebp
f0100984:	c3                   	ret    

f0100985 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100985:	55                   	push   %ebp
f0100986:	89 e5                	mov    %esp,%ebp
f0100988:	57                   	push   %edi
f0100989:	56                   	push   %esi
f010098a:	53                   	push   %ebx
f010098b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010098e:	c7 04 24 f4 68 10 f0 	movl   $0xf01068f4,(%esp)
f0100995:	e8 72 37 00 00       	call   f010410c <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010099a:	c7 04 24 18 69 10 f0 	movl   $0xf0106918,(%esp)
f01009a1:	e8 66 37 00 00       	call   f010410c <cprintf>

	if (tf != NULL)
f01009a6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f01009aa:	74 0b                	je     f01009b7 <monitor+0x32>
		print_trapframe(tf);
f01009ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01009af:	89 04 24             	mov    %eax,(%esp)
f01009b2:	e8 45 39 00 00       	call   f01042fc <print_trapframe>

	while (1) {
		buf = readline("K> ");
f01009b7:	c7 04 24 68 67 10 f0 	movl   $0xf0106768,(%esp)
f01009be:	e8 6d 4a 00 00       	call   f0105430 <readline>
f01009c3:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009c5:	85 c0                	test   %eax,%eax
f01009c7:	74 ee                	je     f01009b7 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009c9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009d0:	be 00 00 00 00       	mov    $0x0,%esi
f01009d5:	eb 0a                	jmp    f01009e1 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009d7:	c6 03 00             	movb   $0x0,(%ebx)
f01009da:	89 f7                	mov    %esi,%edi
f01009dc:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009df:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009e1:	0f b6 03             	movzbl (%ebx),%eax
f01009e4:	84 c0                	test   %al,%al
f01009e6:	74 63                	je     f0100a4b <monitor+0xc6>
f01009e8:	0f be c0             	movsbl %al,%eax
f01009eb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009ef:	c7 04 24 6c 67 10 f0 	movl   $0xf010676c,(%esp)
f01009f6:	e8 4f 4c 00 00       	call   f010564a <strchr>
f01009fb:	85 c0                	test   %eax,%eax
f01009fd:	75 d8                	jne    f01009d7 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f01009ff:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100a02:	74 47                	je     f0100a4b <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100a04:	83 fe 0f             	cmp    $0xf,%esi
f0100a07:	75 16                	jne    f0100a1f <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100a09:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100a10:	00 
f0100a11:	c7 04 24 71 67 10 f0 	movl   $0xf0106771,(%esp)
f0100a18:	e8 ef 36 00 00       	call   f010410c <cprintf>
f0100a1d:	eb 98                	jmp    f01009b7 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f0100a1f:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a22:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a26:	eb 03                	jmp    f0100a2b <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a28:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a2b:	0f b6 03             	movzbl (%ebx),%eax
f0100a2e:	84 c0                	test   %al,%al
f0100a30:	74 ad                	je     f01009df <monitor+0x5a>
f0100a32:	0f be c0             	movsbl %al,%eax
f0100a35:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a39:	c7 04 24 6c 67 10 f0 	movl   $0xf010676c,(%esp)
f0100a40:	e8 05 4c 00 00       	call   f010564a <strchr>
f0100a45:	85 c0                	test   %eax,%eax
f0100a47:	74 df                	je     f0100a28 <monitor+0xa3>
f0100a49:	eb 94                	jmp    f01009df <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100a4b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a52:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a53:	85 f6                	test   %esi,%esi
f0100a55:	0f 84 5c ff ff ff    	je     f01009b7 <monitor+0x32>
f0100a5b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a60:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a63:	8b 04 85 40 69 10 f0 	mov    -0xfef96c0(,%eax,4),%eax
f0100a6a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a6e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a71:	89 04 24             	mov    %eax,(%esp)
f0100a74:	e8 73 4b 00 00       	call   f01055ec <strcmp>
f0100a79:	85 c0                	test   %eax,%eax
f0100a7b:	75 24                	jne    f0100aa1 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100a7d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a80:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a83:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a87:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a8a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100a8e:	89 34 24             	mov    %esi,(%esp)
f0100a91:	ff 14 85 48 69 10 f0 	call   *-0xfef96b8(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a98:	85 c0                	test   %eax,%eax
f0100a9a:	78 25                	js     f0100ac1 <monitor+0x13c>
f0100a9c:	e9 16 ff ff ff       	jmp    f01009b7 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100aa1:	83 c3 01             	add    $0x1,%ebx
f0100aa4:	83 fb 03             	cmp    $0x3,%ebx
f0100aa7:	75 b7                	jne    f0100a60 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100aa9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100aac:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ab0:	c7 04 24 8e 67 10 f0 	movl   $0xf010678e,(%esp)
f0100ab7:	e8 50 36 00 00       	call   f010410c <cprintf>
f0100abc:	e9 f6 fe ff ff       	jmp    f01009b7 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100ac1:	83 c4 5c             	add    $0x5c,%esp
f0100ac4:	5b                   	pop    %ebx
f0100ac5:	5e                   	pop    %esi
f0100ac6:	5f                   	pop    %edi
f0100ac7:	5d                   	pop    %ebp
f0100ac8:	c3                   	ret    
f0100ac9:	66 90                	xchg   %ax,%ax
f0100acb:	66 90                	xchg   %ax,%ax
f0100acd:	66 90                	xchg   %ax,%ax
f0100acf:	90                   	nop

f0100ad0 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ad0:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f0100ad6:	c1 f8 03             	sar    $0x3,%eax
f0100ad9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100adc:	89 c2                	mov    %eax,%edx
f0100ade:	c1 ea 0c             	shr    $0xc,%edx
f0100ae1:	3b 15 08 bf 22 f0    	cmp    0xf022bf08,%edx
f0100ae7:	72 26                	jb     f0100b0f <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100ae9:	55                   	push   %ebp
f0100aea:	89 e5                	mov    %esp,%ebp
f0100aec:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100aef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100af3:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0100afa:	f0 
f0100afb:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100b02:	00 
f0100b03:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0100b0a:	e8 31 f5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100b0f:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));  //page2kva returns virtual address of the 
}
f0100b14:	c3                   	ret    

f0100b15 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100b15:	89 d1                	mov    %edx,%ecx
f0100b17:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100b1a:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100b1d:	a8 01                	test   $0x1,%al
f0100b1f:	74 5d                	je     f0100b7e <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b21:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b26:	89 c1                	mov    %eax,%ecx
f0100b28:	c1 e9 0c             	shr    $0xc,%ecx
f0100b2b:	3b 0d 08 bf 22 f0    	cmp    0xf022bf08,%ecx
f0100b31:	72 26                	jb     f0100b59 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b33:	55                   	push   %ebp
f0100b34:	89 e5                	mov    %esp,%ebp
f0100b36:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b39:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b3d:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0100b44:	f0 
f0100b45:	c7 44 24 04 10 04 00 	movl   $0x410,0x4(%esp)
f0100b4c:	00 
f0100b4d:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100b54:	e8 e7 f4 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b59:	c1 ea 0c             	shr    $0xc,%edx
f0100b5c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b62:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b69:	89 c2                	mov    %eax,%edx
f0100b6b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b73:	85 d2                	test   %edx,%edx
f0100b75:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b7a:	0f 44 c2             	cmove  %edx,%eax
f0100b7d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b7e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b83:	c3                   	ret    

f0100b84 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b84:	83 3d 3c b2 22 f0 00 	cmpl   $0x0,0xf022b23c
f0100b8b:	75 11                	jne    f0100b9e <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100b8d:	ba 07 e0 26 f0       	mov    $0xf026e007,%edx
f0100b92:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b98:	89 15 3c b2 22 f0    	mov    %edx,0xf022b23c
	}
	
	if (n==0){
f0100b9e:	85 c0                	test   %eax,%eax
f0100ba0:	75 06                	jne    f0100ba8 <boot_alloc+0x24>
	return nextfree;
f0100ba2:	a1 3c b2 22 f0       	mov    0xf022b23c,%eax
f0100ba7:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100ba8:	8b 0d 3c b2 22 f0    	mov    0xf022b23c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100bae:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100bb4:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bba:	01 ca                	add    %ecx,%edx
f0100bbc:	89 15 3c b2 22 f0    	mov    %edx,0xf022b23c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100bc2:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100bc8:	77 26                	ja     f0100bf0 <boot_alloc+0x6c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100bca:	55                   	push   %ebp
f0100bcb:	89 e5                	mov    %esp,%ebp
f0100bcd:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bd0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100bd4:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0100bdb:	f0 
f0100bdc:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f0100be3:	00 
f0100be4:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100beb:	e8 50 f4 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100bf0:	a1 08 bf 22 f0       	mov    0xf022bf08,%eax
f0100bf5:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100bf8:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
f0100bfe:	39 c2                	cmp    %eax,%edx
f0100c00:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c05:	0f 46 c1             	cmovbe %ecx,%eax
	}
	return result;
}
f0100c08:	c3                   	ret    

f0100c09 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100c09:	55                   	push   %ebp
f0100c0a:	89 e5                	mov    %esp,%ebp
f0100c0c:	57                   	push   %edi
f0100c0d:	56                   	push   %esi
f0100c0e:	53                   	push   %ebx
f0100c0f:	83 ec 4c             	sub    $0x4c,%esp
f0100c12:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c15:	84 c0                	test   %al,%al
f0100c17:	0f 85 47 03 00 00    	jne    f0100f64 <check_page_free_list+0x35b>
f0100c1d:	e9 54 03 00 00       	jmp    f0100f76 <check_page_free_list+0x36d>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100c22:	c7 44 24 08 64 69 10 	movl   $0xf0106964,0x8(%esp)
f0100c29:	f0 
f0100c2a:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f0100c31:	00 
f0100c32:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100c39:	e8 02 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100c3e:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100c41:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100c44:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100c47:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c4a:	89 c2                	mov    %eax,%edx
f0100c4c:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100c52:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100c58:	0f 95 c2             	setne  %dl
f0100c5b:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100c5e:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100c62:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100c64:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c68:	8b 00                	mov    (%eax),%eax
f0100c6a:	85 c0                	test   %eax,%eax
f0100c6c:	75 dc                	jne    f0100c4a <check_page_free_list+0x41>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100c6e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100c71:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100c77:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100c7a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100c7d:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100c7f:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100c82:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100c87:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100c8c:	8b 1d 44 b2 22 f0    	mov    0xf022b244,%ebx
f0100c92:	eb 63                	jmp    f0100cf7 <check_page_free_list+0xee>
f0100c94:	89 d8                	mov    %ebx,%eax
f0100c96:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f0100c9c:	c1 f8 03             	sar    $0x3,%eax
f0100c9f:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100ca2:	89 c2                	mov    %eax,%edx
f0100ca4:	c1 ea 16             	shr    $0x16,%edx
f0100ca7:	39 f2                	cmp    %esi,%edx
f0100ca9:	73 4a                	jae    f0100cf5 <check_page_free_list+0xec>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100cab:	89 c2                	mov    %eax,%edx
f0100cad:	c1 ea 0c             	shr    $0xc,%edx
f0100cb0:	3b 15 08 bf 22 f0    	cmp    0xf022bf08,%edx
f0100cb6:	72 20                	jb     f0100cd8 <check_page_free_list+0xcf>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100cb8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100cbc:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0100cc3:	f0 
f0100cc4:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100ccb:	00 
f0100ccc:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0100cd3:	e8 68 f3 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100cd8:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100cdf:	00 
f0100ce0:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100ce7:	00 
	return (void *)(pa + KERNBASE);
f0100ce8:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100ced:	89 04 24             	mov    %eax,(%esp)
f0100cf0:	e8 92 49 00 00       	call   f0105687 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100cf5:	8b 1b                	mov    (%ebx),%ebx
f0100cf7:	85 db                	test   %ebx,%ebx
f0100cf9:	75 99                	jne    f0100c94 <check_page_free_list+0x8b>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100cfb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d00:	e8 7f fe ff ff       	call   f0100b84 <boot_alloc>
f0100d05:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d08:	8b 15 44 b2 22 f0    	mov    0xf022b244,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d0e:	8b 0d 10 bf 22 f0    	mov    0xf022bf10,%ecx
		assert(pp < pages + npages);
f0100d14:	a1 08 bf 22 f0       	mov    0xf022bf08,%eax
f0100d19:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100d1c:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0100d1f:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d22:	89 4d cc             	mov    %ecx,-0x34(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100d25:	bf 00 00 00 00       	mov    $0x0,%edi
f0100d2a:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d2d:	e9 c4 01 00 00       	jmp    f0100ef6 <check_page_free_list+0x2ed>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100d32:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100d35:	73 24                	jae    f0100d5b <check_page_free_list+0x152>
f0100d37:	c7 44 24 0c 6f 73 10 	movl   $0xf010736f,0xc(%esp)
f0100d3e:	f0 
f0100d3f:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100d46:	f0 
f0100d47:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0100d4e:	00 
f0100d4f:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100d56:	e8 e5 f2 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100d5b:	3b 55 d0             	cmp    -0x30(%ebp),%edx
f0100d5e:	72 24                	jb     f0100d84 <check_page_free_list+0x17b>
f0100d60:	c7 44 24 0c 90 73 10 	movl   $0xf0107390,0xc(%esp)
f0100d67:	f0 
f0100d68:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100d6f:	f0 
f0100d70:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0100d77:	00 
f0100d78:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100d7f:	e8 bc f2 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100d84:	89 d0                	mov    %edx,%eax
f0100d86:	2b 45 cc             	sub    -0x34(%ebp),%eax
f0100d89:	a8 07                	test   $0x7,%al
f0100d8b:	74 24                	je     f0100db1 <check_page_free_list+0x1a8>
f0100d8d:	c7 44 24 0c 88 69 10 	movl   $0xf0106988,0xc(%esp)
f0100d94:	f0 
f0100d95:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100d9c:	f0 
f0100d9d:	c7 44 24 04 60 03 00 	movl   $0x360,0x4(%esp)
f0100da4:	00 
f0100da5:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100dac:	e8 8f f2 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100db1:	c1 f8 03             	sar    $0x3,%eax
f0100db4:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100db7:	85 c0                	test   %eax,%eax
f0100db9:	75 24                	jne    f0100ddf <check_page_free_list+0x1d6>
f0100dbb:	c7 44 24 0c a4 73 10 	movl   $0xf01073a4,0xc(%esp)
f0100dc2:	f0 
f0100dc3:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100dca:	f0 
f0100dcb:	c7 44 24 04 63 03 00 	movl   $0x363,0x4(%esp)
f0100dd2:	00 
f0100dd3:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100dda:	e8 61 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ddf:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100de4:	75 24                	jne    f0100e0a <check_page_free_list+0x201>
f0100de6:	c7 44 24 0c b5 73 10 	movl   $0xf01073b5,0xc(%esp)
f0100ded:	f0 
f0100dee:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100df5:	f0 
f0100df6:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0100dfd:	00 
f0100dfe:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100e05:	e8 36 f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100e0a:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100e0f:	75 24                	jne    f0100e35 <check_page_free_list+0x22c>
f0100e11:	c7 44 24 0c bc 69 10 	movl   $0xf01069bc,0xc(%esp)
f0100e18:	f0 
f0100e19:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100e20:	f0 
f0100e21:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f0100e28:	00 
f0100e29:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100e30:	e8 0b f2 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100e35:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100e3a:	75 24                	jne    f0100e60 <check_page_free_list+0x257>
f0100e3c:	c7 44 24 0c ce 73 10 	movl   $0xf01073ce,0xc(%esp)
f0100e43:	f0 
f0100e44:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100e4b:	f0 
f0100e4c:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f0100e53:	00 
f0100e54:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100e5b:	e8 e0 f1 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100e60:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100e65:	0f 86 32 01 00 00    	jbe    f0100f9d <check_page_free_list+0x394>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e6b:	89 c1                	mov    %eax,%ecx
f0100e6d:	c1 e9 0c             	shr    $0xc,%ecx
f0100e70:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f0100e73:	77 20                	ja     f0100e95 <check_page_free_list+0x28c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e75:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e79:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0100e80:	f0 
f0100e81:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100e88:	00 
f0100e89:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0100e90:	e8 ab f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100e95:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f0100e9b:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100e9e:	0f 86 e9 00 00 00    	jbe    f0100f8d <check_page_free_list+0x384>
f0100ea4:	c7 44 24 0c e0 69 10 	movl   $0xf01069e0,0xc(%esp)
f0100eab:	f0 
f0100eac:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100eb3:	f0 
f0100eb4:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0100ebb:	00 
f0100ebc:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100ec3:	e8 78 f1 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100ec8:	c7 44 24 0c e8 73 10 	movl   $0xf01073e8,0xc(%esp)
f0100ecf:	f0 
f0100ed0:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100ed7:	f0 
f0100ed8:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0100edf:	00 
f0100ee0:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100ee7:	e8 54 f1 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100eec:	83 c3 01             	add    $0x1,%ebx
f0100eef:	eb 03                	jmp    f0100ef4 <check_page_free_list+0x2eb>
		else
			++nfree_extmem;
f0100ef1:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ef4:	8b 12                	mov    (%edx),%edx
f0100ef6:	85 d2                	test   %edx,%edx
f0100ef8:	0f 85 34 fe ff ff    	jne    f0100d32 <check_page_free_list+0x129>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100efe:	85 db                	test   %ebx,%ebx
f0100f00:	7f 24                	jg     f0100f26 <check_page_free_list+0x31d>
f0100f02:	c7 44 24 0c 05 74 10 	movl   $0xf0107405,0xc(%esp)
f0100f09:	f0 
f0100f0a:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100f11:	f0 
f0100f12:	c7 44 24 04 71 03 00 	movl   $0x371,0x4(%esp)
f0100f19:	00 
f0100f1a:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100f21:	e8 1a f1 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100f26:	85 ff                	test   %edi,%edi
f0100f28:	7f 24                	jg     f0100f4e <check_page_free_list+0x345>
f0100f2a:	c7 44 24 0c 17 74 10 	movl   $0xf0107417,0xc(%esp)
f0100f31:	f0 
f0100f32:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0100f39:	f0 
f0100f3a:	c7 44 24 04 72 03 00 	movl   $0x372,0x4(%esp)
f0100f41:	00 
f0100f42:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0100f49:	e8 f2 f0 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100f4e:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100f52:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f56:	c7 04 24 28 6a 10 f0 	movl   $0xf0106a28,(%esp)
f0100f5d:	e8 aa 31 00 00       	call   f010410c <cprintf>
f0100f62:	eb 49                	jmp    f0100fad <check_page_free_list+0x3a4>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100f64:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0100f69:	85 c0                	test   %eax,%eax
f0100f6b:	0f 85 cd fc ff ff    	jne    f0100c3e <check_page_free_list+0x35>
f0100f71:	e9 ac fc ff ff       	jmp    f0100c22 <check_page_free_list+0x19>
f0100f76:	83 3d 44 b2 22 f0 00 	cmpl   $0x0,0xf022b244
f0100f7d:	0f 84 9f fc ff ff    	je     f0100c22 <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100f83:	be 00 04 00 00       	mov    $0x400,%esi
f0100f88:	e9 ff fc ff ff       	jmp    f0100c8c <check_page_free_list+0x83>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100f8d:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100f92:	0f 85 59 ff ff ff    	jne    f0100ef1 <check_page_free_list+0x2e8>
f0100f98:	e9 2b ff ff ff       	jmp    f0100ec8 <check_page_free_list+0x2bf>
f0100f9d:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100fa2:	0f 85 44 ff ff ff    	jne    f0100eec <check_page_free_list+0x2e3>
f0100fa8:	e9 1b ff ff ff       	jmp    f0100ec8 <check_page_free_list+0x2bf>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100fad:	83 c4 4c             	add    $0x4c,%esp
f0100fb0:	5b                   	pop    %ebx
f0100fb1:	5e                   	pop    %esi
f0100fb2:	5f                   	pop    %edi
f0100fb3:	5d                   	pop    %ebp
f0100fb4:	c3                   	ret    

f0100fb5 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100fb5:	b8 01 00 00 00       	mov    $0x1,%eax
f0100fba:	eb 18                	jmp    f0100fd4 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100fbc:	8b 15 10 bf 22 f0    	mov    0xf022bf10,%edx
f0100fc2:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100fc5:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100fcb:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100fd1:	83 c0 01             	add    $0x1,%eax
f0100fd4:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f0100fda:	72 e0                	jb     f0100fbc <page_init+0x7>
//


void
page_init(void)
{
f0100fdc:	55                   	push   %ebp
f0100fdd:	89 e5                	mov    %esp,%ebp
f0100fdf:	57                   	push   %edi
f0100fe0:	56                   	push   %esi
f0100fe1:	53                   	push   %ebx
f0100fe2:	83 ec 1c             	sub    $0x1c,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0100fe5:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f0100fec:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100fef:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0100ff4:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0100ff9:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100ffe:	eb 73                	jmp    f0101073 <page_init+0xbe>
		if (i == mpentyPg) {
f0101000:	83 fb 07             	cmp    $0x7,%ebx
f0101003:	75 16                	jne    f010101b <page_init+0x66>
			cprintf("Skipped this page %d\n", i);
f0101005:	c7 44 24 04 07 00 00 	movl   $0x7,0x4(%esp)
f010100c:	00 
f010100d:	c7 04 24 28 74 10 f0 	movl   $0xf0107428,(%esp)
f0101014:	e8 f3 30 00 00       	call   f010410c <cprintf>
			continue;	
f0101019:	eb 52                	jmp    f010106d <page_init+0xb8>
f010101b:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0101022:	8b 15 10 bf 22 f0    	mov    0xf022bf10,%edx
f0101028:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f010102f:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0101036:	83 3d 44 b2 22 f0 00 	cmpl   $0x0,0xf022b244
f010103d:	75 10                	jne    f010104f <page_init+0x9a>
			page_free_list = &pages[i];
f010103f:	89 c2                	mov    %eax,%edx
f0101041:	03 15 10 bf 22 f0    	add    0xf022bf10,%edx
f0101047:	89 15 44 b2 22 f0    	mov    %edx,0xf022b244
f010104d:	eb 16                	jmp    f0101065 <page_init+0xb0>
		} else {
			prev->pp_link = &pages[i];
f010104f:	89 c2                	mov    %eax,%edx
f0101051:	03 15 10 bf 22 f0    	add    0xf022bf10,%edx
f0101057:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0101059:	8b 15 10 bf 22 f0    	mov    0xf022bf10,%edx
f010105f:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0101062:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0101065:	03 05 10 bf 22 f0    	add    0xf022bf10,%eax
f010106b:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f010106d:	83 c3 01             	add    $0x1,%ebx
f0101070:	83 c6 08             	add    $0x8,%esi
f0101073:	3b 1d 48 b2 22 f0    	cmp    0xf022b248,%ebx
f0101079:	72 85                	jb     f0101000 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f010107b:	a1 10 bf 22 f0       	mov    0xf022bf10,%eax
f0101080:	8d 44 d8 f8          	lea    -0x8(%eax,%ebx,8),%eax
f0101084:	a3 38 b2 22 f0       	mov    %eax,0xf022b238
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0101089:	b8 00 00 00 00       	mov    $0x0,%eax
f010108e:	e8 f1 fa ff ff       	call   f0100b84 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101093:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101098:	77 20                	ja     f01010ba <page_init+0x105>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010109a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010109e:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f01010a5:	f0 
f01010a6:	c7 44 24 04 75 01 00 	movl   $0x175,0x4(%esp)
f01010ad:	00 
f01010ae:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01010b5:	e8 86 ef ff ff       	call   f0100040 <_panic>
f01010ba:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f01010bf:	c1 e8 0c             	shr    $0xc,%eax
f01010c2:	8b 1d 38 b2 22 f0    	mov    0xf022b238,%ebx
f01010c8:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f01010cf:	eb 2c                	jmp    f01010fd <page_init+0x148>
		pages[i].pp_ref = 0;
f01010d1:	89 d1                	mov    %edx,%ecx
f01010d3:	03 0d 10 bf 22 f0    	add    0xf022bf10,%ecx
f01010d9:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f01010df:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f01010e5:	89 d1                	mov    %edx,%ecx
f01010e7:	03 0d 10 bf 22 f0    	add    0xf022bf10,%ecx
f01010ed:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f01010ef:	89 d3                	mov    %edx,%ebx
f01010f1:	03 1d 10 bf 22 f0    	add    0xf022bf10,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f01010f7:	83 c0 01             	add    $0x1,%eax
f01010fa:	83 c2 08             	add    $0x8,%edx
f01010fd:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f0101103:	72 cc                	jb     f01010d1 <page_init+0x11c>
f0101105:	89 1d 38 b2 22 f0    	mov    %ebx,0xf022b238
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f010110b:	a1 10 bf 22 f0       	mov    0xf022bf10,%eax
f0101110:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101114:	c7 04 24 50 6a 10 f0 	movl   $0xf0106a50,(%esp)
f010111b:	e8 ec 2f 00 00       	call   f010410c <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0101120:	a1 10 bf 22 f0       	mov    0xf022bf10,%eax
f0101125:	8b 15 08 bf 22 f0    	mov    0xf022bf08,%edx
f010112b:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f010112f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101133:	c7 04 24 3e 74 10 f0 	movl   $0xf010743e,(%esp)
f010113a:	e8 cd 2f 00 00       	call   f010410c <cprintf>
}
f010113f:	83 c4 1c             	add    $0x1c,%esp
f0101142:	5b                   	pop    %ebx
f0101143:	5e                   	pop    %esi
f0101144:	5f                   	pop    %edi
f0101145:	5d                   	pop    %ebp
f0101146:	c3                   	ret    

f0101147 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0101147:	55                   	push   %ebp
f0101148:	89 e5                	mov    %esp,%ebp
f010114a:	53                   	push   %ebx
f010114b:	83 ec 14             	sub    $0x14,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f010114e:	8b 1d 44 b2 22 f0    	mov    0xf022b244,%ebx
f0101154:	85 db                	test   %ebx,%ebx
f0101156:	74 75                	je     f01011cd <page_alloc+0x86>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0101158:	8b 03                	mov    (%ebx),%eax
f010115a:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
	allocPage->pp_link = NULL;	//Break the link 
f010115f:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0101165:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0101169:	74 58                	je     f01011c3 <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010116b:	89 d8                	mov    %ebx,%eax
f010116d:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f0101173:	c1 f8 03             	sar    $0x3,%eax
f0101176:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101179:	89 c2                	mov    %eax,%edx
f010117b:	c1 ea 0c             	shr    $0xc,%edx
f010117e:	3b 15 08 bf 22 f0    	cmp    0xf022bf08,%edx
f0101184:	72 20                	jb     f01011a6 <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101186:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010118a:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0101191:	f0 
f0101192:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101199:	00 
f010119a:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f01011a1:	e8 9a ee ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f01011a6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01011ad:	00 
f01011ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01011b5:	00 
	return (void *)(pa + KERNBASE);
f01011b6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01011bb:	89 04 24             	mov    %eax,(%esp)
f01011be:	e8 c4 44 00 00       	call   f0105687 <memset>
	}
	
	allocPage->pp_ref = 0;
f01011c3:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
f01011c9:	89 d8                	mov    %ebx,%eax
f01011cb:	eb 05                	jmp    f01011d2 <page_alloc+0x8b>
page_alloc(int alloc_flags)
{
	// Check if there is a free_page available 
	if (!page_free_list)
	{ 
	return NULL;
f01011cd:	b8 00 00 00 00       	mov    $0x0,%eax
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
	}
	
	allocPage->pp_ref = 0;
	return allocPage;
}
f01011d2:	83 c4 14             	add    $0x14,%esp
f01011d5:	5b                   	pop    %ebx
f01011d6:	5d                   	pop    %ebp
f01011d7:	c3                   	ret    

f01011d8 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f01011d8:	55                   	push   %ebp
f01011d9:	89 e5                	mov    %esp,%ebp
f01011db:	83 ec 18             	sub    $0x18,%esp
f01011de:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f01011e1:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f01011e6:	74 1c                	je     f0101204 <page_free+0x2c>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f01011e8:	c7 44 24 08 7c 6a 10 	movl   $0xf0106a7c,0x8(%esp)
f01011ef:	f0 
f01011f0:	c7 44 24 04 ad 01 00 	movl   $0x1ad,0x4(%esp)
f01011f7:	00 
f01011f8:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01011ff:	e8 3c ee ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0101204:	85 c0                	test   %eax,%eax
f0101206:	75 1c                	jne    f0101224 <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f0101208:	c7 44 24 08 bc 6a 10 	movl   $0xf0106abc,0x8(%esp)
f010120f:	f0 
f0101210:	c7 44 24 04 b4 01 00 	movl   $0x1b4,0x4(%esp)
f0101217:	00 
f0101218:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010121f:	e8 1c ee ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0101224:	8b 15 44 b2 22 f0    	mov    0xf022b244,%edx
f010122a:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010122c:	a3 44 b2 22 f0       	mov    %eax,0xf022b244
	}


}
f0101231:	c9                   	leave  
f0101232:	c3                   	ret    

f0101233 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101233:	55                   	push   %ebp
f0101234:	89 e5                	mov    %esp,%ebp
f0101236:	83 ec 18             	sub    $0x18,%esp
f0101239:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010123c:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0101240:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0101243:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101247:	66 85 d2             	test   %dx,%dx
f010124a:	75 08                	jne    f0101254 <page_decref+0x21>
		page_free(pp);
f010124c:	89 04 24             	mov    %eax,(%esp)
f010124f:	e8 84 ff ff ff       	call   f01011d8 <page_free>
}
f0101254:	c9                   	leave  
f0101255:	c3                   	ret    

f0101256 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101256:	55                   	push   %ebp
f0101257:	89 e5                	mov    %esp,%ebp
f0101259:	57                   	push   %edi
f010125a:	56                   	push   %esi
f010125b:	53                   	push   %ebx
f010125c:	83 ec 1c             	sub    $0x1c,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f010125f:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101262:	c1 eb 16             	shr    $0x16,%ebx
f0101265:	c1 e3 02             	shl    $0x2,%ebx
f0101268:	03 5d 08             	add    0x8(%ebp),%ebx

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f010126b:	8b 3b                	mov    (%ebx),%edi
f010126d:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0101273:	74 3e                	je     f01012b3 <pgdir_walk+0x5d>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f0101275:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010127b:	89 f8                	mov    %edi,%eax
f010127d:	c1 e8 0c             	shr    $0xc,%eax
f0101280:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f0101286:	72 20                	jb     f01012a8 <pgdir_walk+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101288:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010128c:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0101293:	f0 
f0101294:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
f010129b:	00 
f010129c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01012a3:	e8 98 ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01012a8:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f01012ae:	e9 8f 00 00 00       	jmp    f0101342 <pgdir_walk+0xec>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f01012b3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01012b7:	0f 84 94 00 00 00    	je     f0101351 <pgdir_walk+0xfb>
f01012bd:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f01012c4:	e8 7e fe ff ff       	call   f0101147 <page_alloc>
f01012c9:	89 c6                	mov    %eax,%esi
f01012cb:	85 c0                	test   %eax,%eax
f01012cd:	0f 84 85 00 00 00    	je     f0101358 <pgdir_walk+0x102>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f01012d3:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012d8:	89 c7                	mov    %eax,%edi
f01012da:	2b 3d 10 bf 22 f0    	sub    0xf022bf10,%edi
f01012e0:	c1 ff 03             	sar    $0x3,%edi
f01012e3:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012e6:	89 f8                	mov    %edi,%eax
f01012e8:	c1 e8 0c             	shr    $0xc,%eax
f01012eb:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f01012f1:	72 20                	jb     f0101313 <pgdir_walk+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012f3:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01012f7:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f01012fe:	f0 
f01012ff:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101306:	00 
f0101307:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f010130e:	e8 2d ed ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101313:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f0101319:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101320:	00 
f0101321:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101328:	00 
f0101329:	89 3c 24             	mov    %edi,(%esp)
f010132c:	e8 56 43 00 00       	call   f0105687 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101331:	2b 35 10 bf 22 f0    	sub    0xf022bf10,%esi
f0101337:	c1 fe 03             	sar    $0x3,%esi
f010133a:	c1 e6 0c             	shl    $0xc,%esi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f010133d:	83 ce 07             	or     $0x7,%esi
f0101340:	89 33                	mov    %esi,(%ebx)
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f0101342:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101345:	c1 e8 0a             	shr    $0xa,%eax
f0101348:	25 fc 0f 00 00       	and    $0xffc,%eax
f010134d:	01 f8                	add    %edi,%eax
f010134f:	eb 0c                	jmp    f010135d <pgdir_walk+0x107>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0101351:	b8 00 00 00 00       	mov    $0x0,%eax
f0101356:	eb 05                	jmp    f010135d <pgdir_walk+0x107>
f0101358:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f010135d:	83 c4 1c             	add    $0x1c,%esp
f0101360:	5b                   	pop    %ebx
f0101361:	5e                   	pop    %esi
f0101362:	5f                   	pop    %edi
f0101363:	5d                   	pop    %ebp
f0101364:	c3                   	ret    

f0101365 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101365:	55                   	push   %ebp
f0101366:	89 e5                	mov    %esp,%ebp
f0101368:	57                   	push   %edi
f0101369:	56                   	push   %esi
f010136a:	53                   	push   %ebx
f010136b:	83 ec 2c             	sub    $0x2c,%esp
f010136e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f0101371:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f0101377:	8b 45 08             	mov    0x8(%ebp),%eax
f010137a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f010137f:	8d b1 ff 0f 00 00    	lea    0xfff(%ecx),%esi
f0101385:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f010138b:	89 d3                	mov    %edx,%ebx
f010138d:	29 d0                	sub    %edx,%eax
f010138f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f0101392:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101395:	83 c8 01             	or     $0x1,%eax
f0101398:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f010139b:	eb 48                	jmp    f01013e5 <boot_map_region+0x80>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f010139d:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01013a4:	00 
f01013a5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013a9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01013ac:	89 04 24             	mov    %eax,(%esp)
f01013af:	e8 a2 fe ff ff       	call   f0101256 <pgdir_walk>
f01013b4:	85 c0                	test   %eax,%eax
f01013b6:	75 1c                	jne    f01013d4 <boot_map_region+0x6f>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f01013b8:	c7 44 24 08 f0 6a 10 	movl   $0xf0106af0,0x8(%esp)
f01013bf:	f0 
f01013c0:	c7 44 24 04 2b 02 00 	movl   $0x22b,0x4(%esp)
f01013c7:	00 
f01013c8:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01013cf:	e8 6c ec ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f01013d4:	0b 7d dc             	or     -0x24(%ebp),%edi
f01013d7:	89 38                	mov    %edi,(%eax)
		vaBegin += PGSIZE;
f01013d9:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f01013df:	81 ee 00 10 00 00    	sub    $0x1000,%esi
f01013e5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01013e8:	8d 3c 18             	lea    (%eax,%ebx,1),%edi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01013eb:	85 f6                	test   %esi,%esi
f01013ed:	75 ae                	jne    f010139d <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f01013ef:	83 c4 2c             	add    $0x2c,%esp
f01013f2:	5b                   	pop    %ebx
f01013f3:	5e                   	pop    %esi
f01013f4:	5f                   	pop    %edi
f01013f5:	5d                   	pop    %ebp
f01013f6:	c3                   	ret    

f01013f7 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01013f7:	55                   	push   %ebp
f01013f8:	89 e5                	mov    %esp,%ebp
f01013fa:	53                   	push   %ebx
f01013fb:	83 ec 14             	sub    $0x14,%esp
f01013fe:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0101401:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101408:	00 
f0101409:	8b 45 0c             	mov    0xc(%ebp),%eax
f010140c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101410:	8b 45 08             	mov    0x8(%ebp),%eax
f0101413:	89 04 24             	mov    %eax,(%esp)
f0101416:	e8 3b fe ff ff       	call   f0101256 <pgdir_walk>
f010141b:	89 c2                	mov    %eax,%edx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f010141d:	85 c0                	test   %eax,%eax
f010141f:	74 1a                	je     f010143b <page_lookup+0x44>
f0101421:	8b 00                	mov    (%eax),%eax
f0101423:	a8 01                	test   $0x1,%al
f0101425:	74 1b                	je     f0101442 <page_lookup+0x4b>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f0101427:	c1 e8 0c             	shr    $0xc,%eax
f010142a:	8b 0d 10 bf 22 f0    	mov    0xf022bf10,%ecx
f0101430:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		if (pte_store) {
f0101433:	85 db                	test   %ebx,%ebx
f0101435:	74 10                	je     f0101447 <page_lookup+0x50>
			*pte_store = pgTbEty;
f0101437:	89 13                	mov    %edx,(%ebx)
f0101439:	eb 0c                	jmp    f0101447 <page_lookup+0x50>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f010143b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101440:	eb 05                	jmp    f0101447 <page_lookup+0x50>
f0101442:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f0101447:	83 c4 14             	add    $0x14,%esp
f010144a:	5b                   	pop    %ebx
f010144b:	5d                   	pop    %ebp
f010144c:	c3                   	ret    

f010144d <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010144d:	55                   	push   %ebp
f010144e:	89 e5                	mov    %esp,%ebp
f0101450:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101453:	e8 81 48 00 00       	call   f0105cd9 <cpunum>
f0101458:	6b c0 74             	imul   $0x74,%eax,%eax
f010145b:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0101462:	74 16                	je     f010147a <tlb_invalidate+0x2d>
f0101464:	e8 70 48 00 00       	call   f0105cd9 <cpunum>
f0101469:	6b c0 74             	imul   $0x74,%eax,%eax
f010146c:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0101472:	8b 55 08             	mov    0x8(%ebp),%edx
f0101475:	39 50 60             	cmp    %edx,0x60(%eax)
f0101478:	75 06                	jne    f0101480 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010147a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010147d:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0101480:	c9                   	leave  
f0101481:	c3                   	ret    

f0101482 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f0101482:	55                   	push   %ebp
f0101483:	89 e5                	mov    %esp,%ebp
f0101485:	56                   	push   %esi
f0101486:	53                   	push   %ebx
f0101487:	83 ec 20             	sub    $0x20,%esp
f010148a:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010148d:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f0101490:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101493:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101497:	89 74 24 04          	mov    %esi,0x4(%esp)
f010149b:	89 1c 24             	mov    %ebx,(%esp)
f010149e:	e8 54 ff ff ff       	call   f01013f7 <page_lookup>
f01014a3:	85 c0                	test   %eax,%eax
f01014a5:	74 1d                	je     f01014c4 <page_remove+0x42>
		return;
	}
	page_decref(remPage);
f01014a7:	89 04 24             	mov    %eax,(%esp)
f01014aa:	e8 84 fd ff ff       	call   f0101233 <page_decref>
	*pte = 0;
f01014af:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01014b2:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01014b8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01014bc:	89 1c 24             	mov    %ebx,(%esp)
f01014bf:	e8 89 ff ff ff       	call   f010144d <tlb_invalidate>
}
f01014c4:	83 c4 20             	add    $0x20,%esp
f01014c7:	5b                   	pop    %ebx
f01014c8:	5e                   	pop    %esi
f01014c9:	5d                   	pop    %ebp
f01014ca:	c3                   	ret    

f01014cb <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01014cb:	55                   	push   %ebp
f01014cc:	89 e5                	mov    %esp,%ebp
f01014ce:	57                   	push   %edi
f01014cf:	56                   	push   %esi
f01014d0:	53                   	push   %ebx
f01014d1:	83 ec 1c             	sub    $0x1c,%esp
f01014d4:	8b 75 0c             	mov    0xc(%ebp),%esi
f01014d7:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f01014da:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01014e1:	00 
f01014e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014e6:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e9:	89 04 24             	mov    %eax,(%esp)
f01014ec:	e8 65 fd ff ff       	call   f0101256 <pgdir_walk>
f01014f1:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f01014f3:	85 c0                	test   %eax,%eax
f01014f5:	0f 84 85 00 00 00    	je     f0101580 <page_insert+0xb5>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f01014fb:	8b 00                	mov    (%eax),%eax
f01014fd:	a8 01                	test   $0x1,%al
f01014ff:	74 5b                	je     f010155c <page_insert+0x91>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f0101501:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101506:	89 f2                	mov    %esi,%edx
f0101508:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
f010150e:	c1 fa 03             	sar    $0x3,%edx
f0101511:	c1 e2 0c             	shl    $0xc,%edx
f0101514:	39 d0                	cmp    %edx,%eax
f0101516:	75 11                	jne    f0101529 <page_insert+0x5e>
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f0101518:	8b 55 14             	mov    0x14(%ebp),%edx
f010151b:	83 ca 01             	or     $0x1,%edx
f010151e:	09 d0                	or     %edx,%eax
f0101520:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101522:	b8 00 00 00 00       	mov    $0x0,%eax
f0101527:	eb 5c                	jmp    f0101585 <page_insert+0xba>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f0101529:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010152d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101530:	89 04 24             	mov    %eax,(%esp)
f0101533:	e8 4a ff ff ff       	call   f0101482 <page_remove>
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f0101538:	8b 55 14             	mov    0x14(%ebp),%edx
f010153b:	83 ca 01             	or     $0x1,%edx
f010153e:	89 f0                	mov    %esi,%eax
f0101540:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f0101546:	c1 f8 03             	sar    $0x3,%eax
f0101549:	c1 e0 0c             	shl    $0xc,%eax
f010154c:	09 d0                	or     %edx,%eax
f010154e:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101550:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		}
		return 0;
f0101555:	b8 00 00 00 00       	mov    $0x0,%eax
f010155a:	eb 29                	jmp    f0101585 <page_insert+0xba>
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f010155c:	8b 55 14             	mov    0x14(%ebp),%edx
f010155f:	83 ca 01             	or     $0x1,%edx
f0101562:	89 f0                	mov    %esi,%eax
f0101564:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f010156a:	c1 f8 03             	sar    $0x3,%eax
f010156d:	c1 e0 0c             	shl    $0xc,%eax
f0101570:	09 d0                	or     %edx,%eax
f0101572:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f0101574:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f0101579:	b8 00 00 00 00       	mov    $0x0,%eax
f010157e:	eb 05                	jmp    f0101585 <page_insert+0xba>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f0101580:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f0101585:	83 c4 1c             	add    $0x1c,%esp
f0101588:	5b                   	pop    %ebx
f0101589:	5e                   	pop    %esi
f010158a:	5f                   	pop    %edi
f010158b:	5d                   	pop    %ebp
f010158c:	c3                   	ret    

f010158d <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f010158d:	55                   	push   %ebp
f010158e:	89 e5                	mov    %esp,%ebp
f0101590:	56                   	push   %esi
f0101591:	53                   	push   %ebx
f0101592:	83 ec 10             	sub    $0x10,%esp
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f0101595:	8b 1d 00 03 12 f0    	mov    0xf0120300,%ebx
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f010159b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010159e:	8d b0 ff 0f 00 00    	lea    0xfff(%eax),%esi
f01015a4:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f01015aa:	c7 44 24 04 1b 00 00 	movl   $0x1b,0x4(%esp)
f01015b1:	00 
f01015b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01015b5:	89 04 24             	mov    %eax,(%esp)
f01015b8:	89 f1                	mov    %esi,%ecx
f01015ba:	89 da                	mov    %ebx,%edx
f01015bc:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f01015c1:	e8 9f fd ff ff       	call   f0101365 <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f01015c6:	01 35 00 03 12 f0    	add    %esi,0xf0120300
	
	return save; 
	
}
f01015cc:	89 d8                	mov    %ebx,%eax
f01015ce:	83 c4 10             	add    $0x10,%esp
f01015d1:	5b                   	pop    %ebx
f01015d2:	5e                   	pop    %esi
f01015d3:	5d                   	pop    %ebp
f01015d4:	c3                   	ret    

f01015d5 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01015d5:	55                   	push   %ebp
f01015d6:	89 e5                	mov    %esp,%ebp
f01015d8:	57                   	push   %edi
f01015d9:	56                   	push   %esi
f01015da:	53                   	push   %ebx
f01015db:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01015de:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f01015e5:	e8 b9 29 00 00       	call   f0103fa3 <mc146818_read>
f01015ea:	89 c3                	mov    %eax,%ebx
f01015ec:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01015f3:	e8 ab 29 00 00       	call   f0103fa3 <mc146818_read>
f01015f8:	c1 e0 08             	shl    $0x8,%eax
f01015fb:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01015fd:	89 d8                	mov    %ebx,%eax
f01015ff:	c1 e0 0a             	shl    $0xa,%eax
f0101602:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101608:	85 c0                	test   %eax,%eax
f010160a:	0f 48 c2             	cmovs  %edx,%eax
f010160d:	c1 f8 0c             	sar    $0xc,%eax
f0101610:	a3 48 b2 22 f0       	mov    %eax,0xf022b248
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101615:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f010161c:	e8 82 29 00 00       	call   f0103fa3 <mc146818_read>
f0101621:	89 c3                	mov    %eax,%ebx
f0101623:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010162a:	e8 74 29 00 00       	call   f0103fa3 <mc146818_read>
f010162f:	c1 e0 08             	shl    $0x8,%eax
f0101632:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101634:	89 d8                	mov    %ebx,%eax
f0101636:	c1 e0 0a             	shl    $0xa,%eax
f0101639:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010163f:	85 c0                	test   %eax,%eax
f0101641:	0f 48 c2             	cmovs  %edx,%eax
f0101644:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101647:	85 c0                	test   %eax,%eax
f0101649:	74 0e                	je     f0101659 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f010164b:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101651:	89 15 08 bf 22 f0    	mov    %edx,0xf022bf08
f0101657:	eb 0c                	jmp    f0101665 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101659:	8b 15 48 b2 22 f0    	mov    0xf022b248,%edx
f010165f:	89 15 08 bf 22 f0    	mov    %edx,0xf022bf08

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101665:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101668:	c1 e8 0a             	shr    $0xa,%eax
f010166b:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f010166f:	a1 48 b2 22 f0       	mov    0xf022b248,%eax
f0101674:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101677:	c1 e8 0a             	shr    $0xa,%eax
f010167a:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f010167e:	a1 08 bf 22 f0       	mov    0xf022bf08,%eax
f0101683:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101686:	c1 e8 0a             	shr    $0xa,%eax
f0101689:	89 44 24 04          	mov    %eax,0x4(%esp)
f010168d:	c7 04 24 3c 6b 10 f0 	movl   $0xf0106b3c,(%esp)
f0101694:	e8 73 2a 00 00       	call   f010410c <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101699:	b8 00 10 00 00       	mov    $0x1000,%eax
f010169e:	e8 e1 f4 ff ff       	call   f0100b84 <boot_alloc>
f01016a3:	a3 0c bf 22 f0       	mov    %eax,0xf022bf0c
	memset(kern_pgdir, 0, PGSIZE);
f01016a8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01016af:	00 
f01016b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01016b7:	00 
f01016b8:	89 04 24             	mov    %eax,(%esp)
f01016bb:	e8 c7 3f 00 00       	call   f0105687 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01016c0:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01016c5:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01016ca:	77 20                	ja     f01016ec <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01016cc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016d0:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f01016d7:	f0 
f01016d8:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f01016df:	00 
f01016e0:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01016e7:	e8 54 e9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01016ec:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01016f2:	83 ca 05             	or     $0x5,%edx
f01016f5:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f01016fb:	a1 08 bf 22 f0       	mov    0xf022bf08,%eax
f0101700:	c1 e0 03             	shl    $0x3,%eax
f0101703:	e8 7c f4 ff ff       	call   f0100b84 <boot_alloc>
f0101708:	a3 10 bf 22 f0       	mov    %eax,0xf022bf10
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f010170d:	8b 0d 08 bf 22 f0    	mov    0xf022bf08,%ecx
f0101713:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010171a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010171e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101725:	00 
f0101726:	89 04 24             	mov    %eax,(%esp)
f0101729:	e8 59 3f 00 00       	call   f0105687 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f010172e:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f0101733:	e8 4c f4 ff ff       	call   f0100b84 <boot_alloc>
f0101738:	a3 4c b2 22 f0       	mov    %eax,0xf022b24c
	memset(envs,0,sizeof(struct Env)*NENV);
f010173d:	c7 44 24 08 00 f0 01 	movl   $0x1f000,0x8(%esp)
f0101744:	00 
f0101745:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010174c:	00 
f010174d:	89 04 24             	mov    %eax,(%esp)
f0101750:	e8 32 3f 00 00       	call   f0105687 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101755:	e8 5b f8 ff ff       	call   f0100fb5 <page_init>

	check_page_free_list(1);
f010175a:	b8 01 00 00 00       	mov    $0x1,%eax
f010175f:	e8 a5 f4 ff ff       	call   f0100c09 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101764:	83 3d 10 bf 22 f0 00 	cmpl   $0x0,0xf022bf10
f010176b:	75 1c                	jne    f0101789 <mem_init+0x1b4>
		panic("'pages' is a null pointer!");
f010176d:	c7 44 24 08 55 74 10 	movl   $0xf0107455,0x8(%esp)
f0101774:	f0 
f0101775:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f010177c:	00 
f010177d:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101784:	e8 b7 e8 ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101789:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f010178e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101793:	eb 05                	jmp    f010179a <mem_init+0x1c5>
		++nfree;
f0101795:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101798:	8b 00                	mov    (%eax),%eax
f010179a:	85 c0                	test   %eax,%eax
f010179c:	75 f7                	jne    f0101795 <mem_init+0x1c0>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010179e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017a5:	e8 9d f9 ff ff       	call   f0101147 <page_alloc>
f01017aa:	89 c7                	mov    %eax,%edi
f01017ac:	85 c0                	test   %eax,%eax
f01017ae:	75 24                	jne    f01017d4 <mem_init+0x1ff>
f01017b0:	c7 44 24 0c 70 74 10 	movl   $0xf0107470,0xc(%esp)
f01017b7:	f0 
f01017b8:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01017bf:	f0 
f01017c0:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f01017c7:	00 
f01017c8:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01017cf:	e8 6c e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01017d4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017db:	e8 67 f9 ff ff       	call   f0101147 <page_alloc>
f01017e0:	89 c6                	mov    %eax,%esi
f01017e2:	85 c0                	test   %eax,%eax
f01017e4:	75 24                	jne    f010180a <mem_init+0x235>
f01017e6:	c7 44 24 0c 86 74 10 	movl   $0xf0107486,0xc(%esp)
f01017ed:	f0 
f01017ee:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01017f5:	f0 
f01017f6:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f01017fd:	00 
f01017fe:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101805:	e8 36 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010180a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101811:	e8 31 f9 ff ff       	call   f0101147 <page_alloc>
f0101816:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101819:	85 c0                	test   %eax,%eax
f010181b:	75 24                	jne    f0101841 <mem_init+0x26c>
f010181d:	c7 44 24 0c 9c 74 10 	movl   $0xf010749c,0xc(%esp)
f0101824:	f0 
f0101825:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010182c:	f0 
f010182d:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0101834:	00 
f0101835:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010183c:	e8 ff e7 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101841:	39 f7                	cmp    %esi,%edi
f0101843:	75 24                	jne    f0101869 <mem_init+0x294>
f0101845:	c7 44 24 0c b2 74 10 	movl   $0xf01074b2,0xc(%esp)
f010184c:	f0 
f010184d:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101854:	f0 
f0101855:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f010185c:	00 
f010185d:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101864:	e8 d7 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101869:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010186c:	39 c6                	cmp    %eax,%esi
f010186e:	74 04                	je     f0101874 <mem_init+0x29f>
f0101870:	39 c7                	cmp    %eax,%edi
f0101872:	75 24                	jne    f0101898 <mem_init+0x2c3>
f0101874:	c7 44 24 0c 78 6b 10 	movl   $0xf0106b78,0xc(%esp)
f010187b:	f0 
f010187c:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101883:	f0 
f0101884:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f010188b:	00 
f010188c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101893:	e8 a8 e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101898:	8b 15 10 bf 22 f0    	mov    0xf022bf10,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010189e:	a1 08 bf 22 f0       	mov    0xf022bf08,%eax
f01018a3:	c1 e0 0c             	shl    $0xc,%eax
f01018a6:	89 f9                	mov    %edi,%ecx
f01018a8:	29 d1                	sub    %edx,%ecx
f01018aa:	c1 f9 03             	sar    $0x3,%ecx
f01018ad:	c1 e1 0c             	shl    $0xc,%ecx
f01018b0:	39 c1                	cmp    %eax,%ecx
f01018b2:	72 24                	jb     f01018d8 <mem_init+0x303>
f01018b4:	c7 44 24 0c c4 74 10 	movl   $0xf01074c4,0xc(%esp)
f01018bb:	f0 
f01018bc:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01018c3:	f0 
f01018c4:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01018cb:	00 
f01018cc:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01018d3:	e8 68 e7 ff ff       	call   f0100040 <_panic>
f01018d8:	89 f1                	mov    %esi,%ecx
f01018da:	29 d1                	sub    %edx,%ecx
f01018dc:	c1 f9 03             	sar    $0x3,%ecx
f01018df:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01018e2:	39 c8                	cmp    %ecx,%eax
f01018e4:	77 24                	ja     f010190a <mem_init+0x335>
f01018e6:	c7 44 24 0c e1 74 10 	movl   $0xf01074e1,0xc(%esp)
f01018ed:	f0 
f01018ee:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01018f5:	f0 
f01018f6:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f01018fd:	00 
f01018fe:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101905:	e8 36 e7 ff ff       	call   f0100040 <_panic>
f010190a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010190d:	29 d1                	sub    %edx,%ecx
f010190f:	89 ca                	mov    %ecx,%edx
f0101911:	c1 fa 03             	sar    $0x3,%edx
f0101914:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101917:	39 d0                	cmp    %edx,%eax
f0101919:	77 24                	ja     f010193f <mem_init+0x36a>
f010191b:	c7 44 24 0c fe 74 10 	movl   $0xf01074fe,0xc(%esp)
f0101922:	f0 
f0101923:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010192a:	f0 
f010192b:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0101932:	00 
f0101933:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010193a:	e8 01 e7 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010193f:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0101944:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101947:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f010194e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101951:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101958:	e8 ea f7 ff ff       	call   f0101147 <page_alloc>
f010195d:	85 c0                	test   %eax,%eax
f010195f:	74 24                	je     f0101985 <mem_init+0x3b0>
f0101961:	c7 44 24 0c 1b 75 10 	movl   $0xf010751b,0xc(%esp)
f0101968:	f0 
f0101969:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101970:	f0 
f0101971:	c7 44 24 04 9c 03 00 	movl   $0x39c,0x4(%esp)
f0101978:	00 
f0101979:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101980:	e8 bb e6 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101985:	89 3c 24             	mov    %edi,(%esp)
f0101988:	e8 4b f8 ff ff       	call   f01011d8 <page_free>
	page_free(pp1);
f010198d:	89 34 24             	mov    %esi,(%esp)
f0101990:	e8 43 f8 ff ff       	call   f01011d8 <page_free>
	page_free(pp2);
f0101995:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101998:	89 04 24             	mov    %eax,(%esp)
f010199b:	e8 38 f8 ff ff       	call   f01011d8 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01019a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019a7:	e8 9b f7 ff ff       	call   f0101147 <page_alloc>
f01019ac:	89 c6                	mov    %eax,%esi
f01019ae:	85 c0                	test   %eax,%eax
f01019b0:	75 24                	jne    f01019d6 <mem_init+0x401>
f01019b2:	c7 44 24 0c 70 74 10 	movl   $0xf0107470,0xc(%esp)
f01019b9:	f0 
f01019ba:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01019c1:	f0 
f01019c2:	c7 44 24 04 a3 03 00 	movl   $0x3a3,0x4(%esp)
f01019c9:	00 
f01019ca:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01019d1:	e8 6a e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01019d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019dd:	e8 65 f7 ff ff       	call   f0101147 <page_alloc>
f01019e2:	89 c7                	mov    %eax,%edi
f01019e4:	85 c0                	test   %eax,%eax
f01019e6:	75 24                	jne    f0101a0c <mem_init+0x437>
f01019e8:	c7 44 24 0c 86 74 10 	movl   $0xf0107486,0xc(%esp)
f01019ef:	f0 
f01019f0:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01019f7:	f0 
f01019f8:	c7 44 24 04 a4 03 00 	movl   $0x3a4,0x4(%esp)
f01019ff:	00 
f0101a00:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101a07:	e8 34 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101a0c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a13:	e8 2f f7 ff ff       	call   f0101147 <page_alloc>
f0101a18:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101a1b:	85 c0                	test   %eax,%eax
f0101a1d:	75 24                	jne    f0101a43 <mem_init+0x46e>
f0101a1f:	c7 44 24 0c 9c 74 10 	movl   $0xf010749c,0xc(%esp)
f0101a26:	f0 
f0101a27:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101a2e:	f0 
f0101a2f:	c7 44 24 04 a5 03 00 	movl   $0x3a5,0x4(%esp)
f0101a36:	00 
f0101a37:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101a3e:	e8 fd e5 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a43:	39 fe                	cmp    %edi,%esi
f0101a45:	75 24                	jne    f0101a6b <mem_init+0x496>
f0101a47:	c7 44 24 0c b2 74 10 	movl   $0xf01074b2,0xc(%esp)
f0101a4e:	f0 
f0101a4f:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101a56:	f0 
f0101a57:	c7 44 24 04 a7 03 00 	movl   $0x3a7,0x4(%esp)
f0101a5e:	00 
f0101a5f:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101a66:	e8 d5 e5 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a6b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a6e:	39 c7                	cmp    %eax,%edi
f0101a70:	74 04                	je     f0101a76 <mem_init+0x4a1>
f0101a72:	39 c6                	cmp    %eax,%esi
f0101a74:	75 24                	jne    f0101a9a <mem_init+0x4c5>
f0101a76:	c7 44 24 0c 78 6b 10 	movl   $0xf0106b78,0xc(%esp)
f0101a7d:	f0 
f0101a7e:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101a85:	f0 
f0101a86:	c7 44 24 04 a8 03 00 	movl   $0x3a8,0x4(%esp)
f0101a8d:	00 
f0101a8e:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101a95:	e8 a6 e5 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f0101a9a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101aa1:	e8 a1 f6 ff ff       	call   f0101147 <page_alloc>
f0101aa6:	85 c0                	test   %eax,%eax
f0101aa8:	74 24                	je     f0101ace <mem_init+0x4f9>
f0101aaa:	c7 44 24 0c 1b 75 10 	movl   $0xf010751b,0xc(%esp)
f0101ab1:	f0 
f0101ab2:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101ab9:	f0 
f0101aba:	c7 44 24 04 a9 03 00 	movl   $0x3a9,0x4(%esp)
f0101ac1:	00 
f0101ac2:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101ac9:	e8 72 e5 ff ff       	call   f0100040 <_panic>
f0101ace:	89 f0                	mov    %esi,%eax
f0101ad0:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f0101ad6:	c1 f8 03             	sar    $0x3,%eax
f0101ad9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101adc:	89 c2                	mov    %eax,%edx
f0101ade:	c1 ea 0c             	shr    $0xc,%edx
f0101ae1:	3b 15 08 bf 22 f0    	cmp    0xf022bf08,%edx
f0101ae7:	72 20                	jb     f0101b09 <mem_init+0x534>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ae9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101aed:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0101af4:	f0 
f0101af5:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101afc:	00 
f0101afd:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0101b04:	e8 37 e5 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101b09:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101b10:	00 
f0101b11:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101b18:	00 
	return (void *)(pa + KERNBASE);
f0101b19:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101b1e:	89 04 24             	mov    %eax,(%esp)
f0101b21:	e8 61 3b 00 00       	call   f0105687 <memset>
	page_free(pp0);
f0101b26:	89 34 24             	mov    %esi,(%esp)
f0101b29:	e8 aa f6 ff ff       	call   f01011d8 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101b2e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101b35:	e8 0d f6 ff ff       	call   f0101147 <page_alloc>
f0101b3a:	85 c0                	test   %eax,%eax
f0101b3c:	75 24                	jne    f0101b62 <mem_init+0x58d>
f0101b3e:	c7 44 24 0c 2a 75 10 	movl   $0xf010752a,0xc(%esp)
f0101b45:	f0 
f0101b46:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101b4d:	f0 
f0101b4e:	c7 44 24 04 ae 03 00 	movl   $0x3ae,0x4(%esp)
f0101b55:	00 
f0101b56:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101b5d:	e8 de e4 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101b62:	39 c6                	cmp    %eax,%esi
f0101b64:	74 24                	je     f0101b8a <mem_init+0x5b5>
f0101b66:	c7 44 24 0c 48 75 10 	movl   $0xf0107548,0xc(%esp)
f0101b6d:	f0 
f0101b6e:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101b75:	f0 
f0101b76:	c7 44 24 04 af 03 00 	movl   $0x3af,0x4(%esp)
f0101b7d:	00 
f0101b7e:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101b85:	e8 b6 e4 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b8a:	89 f0                	mov    %esi,%eax
f0101b8c:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f0101b92:	c1 f8 03             	sar    $0x3,%eax
f0101b95:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101b98:	89 c2                	mov    %eax,%edx
f0101b9a:	c1 ea 0c             	shr    $0xc,%edx
f0101b9d:	3b 15 08 bf 22 f0    	cmp    0xf022bf08,%edx
f0101ba3:	72 20                	jb     f0101bc5 <mem_init+0x5f0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101ba5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101ba9:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0101bb0:	f0 
f0101bb1:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0101bb8:	00 
f0101bb9:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0101bc0:	e8 7b e4 ff ff       	call   f0100040 <_panic>
f0101bc5:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f0101bcb:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f0101bd1:	80 38 00             	cmpb   $0x0,(%eax)
f0101bd4:	74 24                	je     f0101bfa <mem_init+0x625>
f0101bd6:	c7 44 24 0c 58 75 10 	movl   $0xf0107558,0xc(%esp)
f0101bdd:	f0 
f0101bde:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101be5:	f0 
f0101be6:	c7 44 24 04 b2 03 00 	movl   $0x3b2,0x4(%esp)
f0101bed:	00 
f0101bee:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101bf5:	e8 46 e4 ff ff       	call   f0100040 <_panic>
f0101bfa:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f0101bfd:	39 d0                	cmp    %edx,%eax
f0101bff:	75 d0                	jne    f0101bd1 <mem_init+0x5fc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101c01:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101c04:	a3 44 b2 22 f0       	mov    %eax,0xf022b244

	// free the pages we took
	page_free(pp0);
f0101c09:	89 34 24             	mov    %esi,(%esp)
f0101c0c:	e8 c7 f5 ff ff       	call   f01011d8 <page_free>
	page_free(pp1);
f0101c11:	89 3c 24             	mov    %edi,(%esp)
f0101c14:	e8 bf f5 ff ff       	call   f01011d8 <page_free>
	page_free(pp2);
f0101c19:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101c1c:	89 04 24             	mov    %eax,(%esp)
f0101c1f:	e8 b4 f5 ff ff       	call   f01011d8 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c24:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0101c29:	eb 05                	jmp    f0101c30 <mem_init+0x65b>
		--nfree;
f0101c2b:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101c2e:	8b 00                	mov    (%eax),%eax
f0101c30:	85 c0                	test   %eax,%eax
f0101c32:	75 f7                	jne    f0101c2b <mem_init+0x656>
		--nfree;
	assert(nfree == 0);
f0101c34:	85 db                	test   %ebx,%ebx
f0101c36:	74 24                	je     f0101c5c <mem_init+0x687>
f0101c38:	c7 44 24 0c 62 75 10 	movl   $0xf0107562,0xc(%esp)
f0101c3f:	f0 
f0101c40:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101c47:	f0 
f0101c48:	c7 44 24 04 bf 03 00 	movl   $0x3bf,0x4(%esp)
f0101c4f:	00 
f0101c50:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101c57:	e8 e4 e3 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101c5c:	c7 04 24 98 6b 10 f0 	movl   $0xf0106b98,(%esp)
f0101c63:	e8 a4 24 00 00       	call   f010410c <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101c68:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c6f:	e8 d3 f4 ff ff       	call   f0101147 <page_alloc>
f0101c74:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101c77:	85 c0                	test   %eax,%eax
f0101c79:	75 24                	jne    f0101c9f <mem_init+0x6ca>
f0101c7b:	c7 44 24 0c 70 74 10 	movl   $0xf0107470,0xc(%esp)
f0101c82:	f0 
f0101c83:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101c8a:	f0 
f0101c8b:	c7 44 24 04 25 04 00 	movl   $0x425,0x4(%esp)
f0101c92:	00 
f0101c93:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101c9a:	e8 a1 e3 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101c9f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ca6:	e8 9c f4 ff ff       	call   f0101147 <page_alloc>
f0101cab:	89 c3                	mov    %eax,%ebx
f0101cad:	85 c0                	test   %eax,%eax
f0101caf:	75 24                	jne    f0101cd5 <mem_init+0x700>
f0101cb1:	c7 44 24 0c 86 74 10 	movl   $0xf0107486,0xc(%esp)
f0101cb8:	f0 
f0101cb9:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101cc0:	f0 
f0101cc1:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f0101cc8:	00 
f0101cc9:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101cd0:	e8 6b e3 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101cd5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cdc:	e8 66 f4 ff ff       	call   f0101147 <page_alloc>
f0101ce1:	89 c6                	mov    %eax,%esi
f0101ce3:	85 c0                	test   %eax,%eax
f0101ce5:	75 24                	jne    f0101d0b <mem_init+0x736>
f0101ce7:	c7 44 24 0c 9c 74 10 	movl   $0xf010749c,0xc(%esp)
f0101cee:	f0 
f0101cef:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101cf6:	f0 
f0101cf7:	c7 44 24 04 27 04 00 	movl   $0x427,0x4(%esp)
f0101cfe:	00 
f0101cff:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101d06:	e8 35 e3 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101d0b:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0101d0e:	75 24                	jne    f0101d34 <mem_init+0x75f>
f0101d10:	c7 44 24 0c b2 74 10 	movl   $0xf01074b2,0xc(%esp)
f0101d17:	f0 
f0101d18:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101d1f:	f0 
f0101d20:	c7 44 24 04 2a 04 00 	movl   $0x42a,0x4(%esp)
f0101d27:	00 
f0101d28:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101d2f:	e8 0c e3 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101d34:	39 c3                	cmp    %eax,%ebx
f0101d36:	74 05                	je     f0101d3d <mem_init+0x768>
f0101d38:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101d3b:	75 24                	jne    f0101d61 <mem_init+0x78c>
f0101d3d:	c7 44 24 0c 78 6b 10 	movl   $0xf0106b78,0xc(%esp)
f0101d44:	f0 
f0101d45:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101d4c:	f0 
f0101d4d:	c7 44 24 04 2b 04 00 	movl   $0x42b,0x4(%esp)
f0101d54:	00 
f0101d55:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101d5c:	e8 df e2 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101d61:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0101d66:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101d69:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
f0101d70:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101d73:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d7a:	e8 c8 f3 ff ff       	call   f0101147 <page_alloc>
f0101d7f:	85 c0                	test   %eax,%eax
f0101d81:	74 24                	je     f0101da7 <mem_init+0x7d2>
f0101d83:	c7 44 24 0c 1b 75 10 	movl   $0xf010751b,0xc(%esp)
f0101d8a:	f0 
f0101d8b:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101d92:	f0 
f0101d93:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f0101d9a:	00 
f0101d9b:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101da2:	e8 99 e2 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101da7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101daa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101dae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101db5:	00 
f0101db6:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0101dbb:	89 04 24             	mov    %eax,(%esp)
f0101dbe:	e8 34 f6 ff ff       	call   f01013f7 <page_lookup>
f0101dc3:	85 c0                	test   %eax,%eax
f0101dc5:	74 24                	je     f0101deb <mem_init+0x816>
f0101dc7:	c7 44 24 0c b8 6b 10 	movl   $0xf0106bb8,0xc(%esp)
f0101dce:	f0 
f0101dcf:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101dd6:	f0 
f0101dd7:	c7 44 24 04 37 04 00 	movl   $0x437,0x4(%esp)
f0101dde:	00 
f0101ddf:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101de6:	e8 55 e2 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101deb:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101df2:	00 
f0101df3:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101dfa:	00 
f0101dfb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101dff:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0101e04:	89 04 24             	mov    %eax,(%esp)
f0101e07:	e8 bf f6 ff ff       	call   f01014cb <page_insert>
f0101e0c:	85 c0                	test   %eax,%eax
f0101e0e:	78 24                	js     f0101e34 <mem_init+0x85f>
f0101e10:	c7 44 24 0c f0 6b 10 	movl   $0xf0106bf0,0xc(%esp)
f0101e17:	f0 
f0101e18:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101e1f:	f0 
f0101e20:	c7 44 24 04 3a 04 00 	movl   $0x43a,0x4(%esp)
f0101e27:	00 
f0101e28:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101e2f:	e8 0c e2 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101e34:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101e37:	89 04 24             	mov    %eax,(%esp)
f0101e3a:	e8 99 f3 ff ff       	call   f01011d8 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101e3f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e46:	00 
f0101e47:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101e4e:	00 
f0101e4f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e53:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0101e58:	89 04 24             	mov    %eax,(%esp)
f0101e5b:	e8 6b f6 ff ff       	call   f01014cb <page_insert>
f0101e60:	85 c0                	test   %eax,%eax
f0101e62:	74 24                	je     f0101e88 <mem_init+0x8b3>
f0101e64:	c7 44 24 0c 20 6c 10 	movl   $0xf0106c20,0xc(%esp)
f0101e6b:	f0 
f0101e6c:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101e73:	f0 
f0101e74:	c7 44 24 04 3e 04 00 	movl   $0x43e,0x4(%esp)
f0101e7b:	00 
f0101e7c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101e83:	e8 b8 e1 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101e88:	8b 3d 0c bf 22 f0    	mov    0xf022bf0c,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101e8e:	a1 10 bf 22 f0       	mov    0xf022bf10,%eax
f0101e93:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101e96:	8b 17                	mov    (%edi),%edx
f0101e98:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101e9e:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ea1:	29 c1                	sub    %eax,%ecx
f0101ea3:	89 c8                	mov    %ecx,%eax
f0101ea5:	c1 f8 03             	sar    $0x3,%eax
f0101ea8:	c1 e0 0c             	shl    $0xc,%eax
f0101eab:	39 c2                	cmp    %eax,%edx
f0101ead:	74 24                	je     f0101ed3 <mem_init+0x8fe>
f0101eaf:	c7 44 24 0c 50 6c 10 	movl   $0xf0106c50,0xc(%esp)
f0101eb6:	f0 
f0101eb7:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101ebe:	f0 
f0101ebf:	c7 44 24 04 3f 04 00 	movl   $0x43f,0x4(%esp)
f0101ec6:	00 
f0101ec7:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101ece:	e8 6d e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101ed3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101ed8:	89 f8                	mov    %edi,%eax
f0101eda:	e8 36 ec ff ff       	call   f0100b15 <check_va2pa>
f0101edf:	89 da                	mov    %ebx,%edx
f0101ee1:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101ee4:	c1 fa 03             	sar    $0x3,%edx
f0101ee7:	c1 e2 0c             	shl    $0xc,%edx
f0101eea:	39 d0                	cmp    %edx,%eax
f0101eec:	74 24                	je     f0101f12 <mem_init+0x93d>
f0101eee:	c7 44 24 0c 78 6c 10 	movl   $0xf0106c78,0xc(%esp)
f0101ef5:	f0 
f0101ef6:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101efd:	f0 
f0101efe:	c7 44 24 04 40 04 00 	movl   $0x440,0x4(%esp)
f0101f05:	00 
f0101f06:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101f0d:	e8 2e e1 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101f12:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f17:	74 24                	je     f0101f3d <mem_init+0x968>
f0101f19:	c7 44 24 0c 6d 75 10 	movl   $0xf010756d,0xc(%esp)
f0101f20:	f0 
f0101f21:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101f28:	f0 
f0101f29:	c7 44 24 04 41 04 00 	movl   $0x441,0x4(%esp)
f0101f30:	00 
f0101f31:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101f38:	e8 03 e1 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101f3d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f40:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101f45:	74 24                	je     f0101f6b <mem_init+0x996>
f0101f47:	c7 44 24 0c 7e 75 10 	movl   $0xf010757e,0xc(%esp)
f0101f4e:	f0 
f0101f4f:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101f56:	f0 
f0101f57:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f0101f5e:	00 
f0101f5f:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101f66:	e8 d5 e0 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101f6b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101f72:	00 
f0101f73:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101f7a:	00 
f0101f7b:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101f7f:	89 3c 24             	mov    %edi,(%esp)
f0101f82:	e8 44 f5 ff ff       	call   f01014cb <page_insert>
f0101f87:	85 c0                	test   %eax,%eax
f0101f89:	74 24                	je     f0101faf <mem_init+0x9da>
f0101f8b:	c7 44 24 0c a8 6c 10 	movl   $0xf0106ca8,0xc(%esp)
f0101f92:	f0 
f0101f93:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101f9a:	f0 
f0101f9b:	c7 44 24 04 45 04 00 	movl   $0x445,0x4(%esp)
f0101fa2:	00 
f0101fa3:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101faa:	e8 91 e0 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101faf:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fb4:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0101fb9:	e8 57 eb ff ff       	call   f0100b15 <check_va2pa>
f0101fbe:	89 f2                	mov    %esi,%edx
f0101fc0:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
f0101fc6:	c1 fa 03             	sar    $0x3,%edx
f0101fc9:	c1 e2 0c             	shl    $0xc,%edx
f0101fcc:	39 d0                	cmp    %edx,%eax
f0101fce:	74 24                	je     f0101ff4 <mem_init+0xa1f>
f0101fd0:	c7 44 24 0c e4 6c 10 	movl   $0xf0106ce4,0xc(%esp)
f0101fd7:	f0 
f0101fd8:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0101fdf:	f0 
f0101fe0:	c7 44 24 04 47 04 00 	movl   $0x447,0x4(%esp)
f0101fe7:	00 
f0101fe8:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0101fef:	e8 4c e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ff4:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ff9:	74 24                	je     f010201f <mem_init+0xa4a>
f0101ffb:	c7 44 24 0c 8f 75 10 	movl   $0xf010758f,0xc(%esp)
f0102002:	f0 
f0102003:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010200a:	f0 
f010200b:	c7 44 24 04 48 04 00 	movl   $0x448,0x4(%esp)
f0102012:	00 
f0102013:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010201a:	e8 21 e0 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f010201f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102026:	e8 1c f1 ff ff       	call   f0101147 <page_alloc>
f010202b:	85 c0                	test   %eax,%eax
f010202d:	74 24                	je     f0102053 <mem_init+0xa7e>
f010202f:	c7 44 24 0c 1b 75 10 	movl   $0xf010751b,0xc(%esp)
f0102036:	f0 
f0102037:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010203e:	f0 
f010203f:	c7 44 24 04 4b 04 00 	movl   $0x44b,0x4(%esp)
f0102046:	00 
f0102047:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010204e:	e8 ed df ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102053:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010205a:	00 
f010205b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102062:	00 
f0102063:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102067:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f010206c:	89 04 24             	mov    %eax,(%esp)
f010206f:	e8 57 f4 ff ff       	call   f01014cb <page_insert>
f0102074:	85 c0                	test   %eax,%eax
f0102076:	74 24                	je     f010209c <mem_init+0xac7>
f0102078:	c7 44 24 0c a8 6c 10 	movl   $0xf0106ca8,0xc(%esp)
f010207f:	f0 
f0102080:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102087:	f0 
f0102088:	c7 44 24 04 4e 04 00 	movl   $0x44e,0x4(%esp)
f010208f:	00 
f0102090:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102097:	e8 a4 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010209c:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020a1:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f01020a6:	e8 6a ea ff ff       	call   f0100b15 <check_va2pa>
f01020ab:	89 f2                	mov    %esi,%edx
f01020ad:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
f01020b3:	c1 fa 03             	sar    $0x3,%edx
f01020b6:	c1 e2 0c             	shl    $0xc,%edx
f01020b9:	39 d0                	cmp    %edx,%eax
f01020bb:	74 24                	je     f01020e1 <mem_init+0xb0c>
f01020bd:	c7 44 24 0c e4 6c 10 	movl   $0xf0106ce4,0xc(%esp)
f01020c4:	f0 
f01020c5:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01020cc:	f0 
f01020cd:	c7 44 24 04 4f 04 00 	movl   $0x44f,0x4(%esp)
f01020d4:	00 
f01020d5:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01020dc:	e8 5f df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f01020e1:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01020e6:	74 24                	je     f010210c <mem_init+0xb37>
f01020e8:	c7 44 24 0c 8f 75 10 	movl   $0xf010758f,0xc(%esp)
f01020ef:	f0 
f01020f0:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01020f7:	f0 
f01020f8:	c7 44 24 04 50 04 00 	movl   $0x450,0x4(%esp)
f01020ff:	00 
f0102100:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102107:	e8 34 df ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010210c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102113:	e8 2f f0 ff ff       	call   f0101147 <page_alloc>
f0102118:	85 c0                	test   %eax,%eax
f010211a:	74 24                	je     f0102140 <mem_init+0xb6b>
f010211c:	c7 44 24 0c 1b 75 10 	movl   $0xf010751b,0xc(%esp)
f0102123:	f0 
f0102124:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010212b:	f0 
f010212c:	c7 44 24 04 54 04 00 	movl   $0x454,0x4(%esp)
f0102133:	00 
f0102134:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010213b:	e8 00 df ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0102140:	8b 15 0c bf 22 f0    	mov    0xf022bf0c,%edx
f0102146:	8b 02                	mov    (%edx),%eax
f0102148:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010214d:	89 c1                	mov    %eax,%ecx
f010214f:	c1 e9 0c             	shr    $0xc,%ecx
f0102152:	3b 0d 08 bf 22 f0    	cmp    0xf022bf08,%ecx
f0102158:	72 20                	jb     f010217a <mem_init+0xba5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010215a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010215e:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0102165:	f0 
f0102166:	c7 44 24 04 57 04 00 	movl   $0x457,0x4(%esp)
f010216d:	00 
f010216e:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102175:	e8 c6 de ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010217a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010217f:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0102182:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102189:	00 
f010218a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102191:	00 
f0102192:	89 14 24             	mov    %edx,(%esp)
f0102195:	e8 bc f0 ff ff       	call   f0101256 <pgdir_walk>
f010219a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010219d:	8d 51 04             	lea    0x4(%ecx),%edx
f01021a0:	39 d0                	cmp    %edx,%eax
f01021a2:	74 24                	je     f01021c8 <mem_init+0xbf3>
f01021a4:	c7 44 24 0c 14 6d 10 	movl   $0xf0106d14,0xc(%esp)
f01021ab:	f0 
f01021ac:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01021b3:	f0 
f01021b4:	c7 44 24 04 58 04 00 	movl   $0x458,0x4(%esp)
f01021bb:	00 
f01021bc:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01021c3:	e8 78 de ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01021c8:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01021cf:	00 
f01021d0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01021d7:	00 
f01021d8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021dc:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f01021e1:	89 04 24             	mov    %eax,(%esp)
f01021e4:	e8 e2 f2 ff ff       	call   f01014cb <page_insert>
f01021e9:	85 c0                	test   %eax,%eax
f01021eb:	74 24                	je     f0102211 <mem_init+0xc3c>
f01021ed:	c7 44 24 0c 54 6d 10 	movl   $0xf0106d54,0xc(%esp)
f01021f4:	f0 
f01021f5:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01021fc:	f0 
f01021fd:	c7 44 24 04 5b 04 00 	movl   $0x45b,0x4(%esp)
f0102204:	00 
f0102205:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010220c:	e8 2f de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102211:	8b 3d 0c bf 22 f0    	mov    0xf022bf0c,%edi
f0102217:	ba 00 10 00 00       	mov    $0x1000,%edx
f010221c:	89 f8                	mov    %edi,%eax
f010221e:	e8 f2 e8 ff ff       	call   f0100b15 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102223:	89 f2                	mov    %esi,%edx
f0102225:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
f010222b:	c1 fa 03             	sar    $0x3,%edx
f010222e:	c1 e2 0c             	shl    $0xc,%edx
f0102231:	39 d0                	cmp    %edx,%eax
f0102233:	74 24                	je     f0102259 <mem_init+0xc84>
f0102235:	c7 44 24 0c e4 6c 10 	movl   $0xf0106ce4,0xc(%esp)
f010223c:	f0 
f010223d:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102244:	f0 
f0102245:	c7 44 24 04 5c 04 00 	movl   $0x45c,0x4(%esp)
f010224c:	00 
f010224d:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102254:	e8 e7 dd ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102259:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010225e:	74 24                	je     f0102284 <mem_init+0xcaf>
f0102260:	c7 44 24 0c 8f 75 10 	movl   $0xf010758f,0xc(%esp)
f0102267:	f0 
f0102268:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010226f:	f0 
f0102270:	c7 44 24 04 5d 04 00 	movl   $0x45d,0x4(%esp)
f0102277:	00 
f0102278:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010227f:	e8 bc dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102284:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010228b:	00 
f010228c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102293:	00 
f0102294:	89 3c 24             	mov    %edi,(%esp)
f0102297:	e8 ba ef ff ff       	call   f0101256 <pgdir_walk>
f010229c:	f6 00 04             	testb  $0x4,(%eax)
f010229f:	75 24                	jne    f01022c5 <mem_init+0xcf0>
f01022a1:	c7 44 24 0c 94 6d 10 	movl   $0xf0106d94,0xc(%esp)
f01022a8:	f0 
f01022a9:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01022b0:	f0 
f01022b1:	c7 44 24 04 5e 04 00 	movl   $0x45e,0x4(%esp)
f01022b8:	00 
f01022b9:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01022c0:	e8 7b dd ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01022c5:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f01022ca:	f6 00 04             	testb  $0x4,(%eax)
f01022cd:	75 24                	jne    f01022f3 <mem_init+0xd1e>
f01022cf:	c7 44 24 0c a0 75 10 	movl   $0xf01075a0,0xc(%esp)
f01022d6:	f0 
f01022d7:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01022de:	f0 
f01022df:	c7 44 24 04 5f 04 00 	movl   $0x45f,0x4(%esp)
f01022e6:	00 
f01022e7:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01022ee:	e8 4d dd ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022f3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022fa:	00 
f01022fb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102302:	00 
f0102303:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102307:	89 04 24             	mov    %eax,(%esp)
f010230a:	e8 bc f1 ff ff       	call   f01014cb <page_insert>
f010230f:	85 c0                	test   %eax,%eax
f0102311:	74 24                	je     f0102337 <mem_init+0xd62>
f0102313:	c7 44 24 0c a8 6c 10 	movl   $0xf0106ca8,0xc(%esp)
f010231a:	f0 
f010231b:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102322:	f0 
f0102323:	c7 44 24 04 62 04 00 	movl   $0x462,0x4(%esp)
f010232a:	00 
f010232b:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102332:	e8 09 dd ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102337:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010233e:	00 
f010233f:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102346:	00 
f0102347:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f010234c:	89 04 24             	mov    %eax,(%esp)
f010234f:	e8 02 ef ff ff       	call   f0101256 <pgdir_walk>
f0102354:	f6 00 02             	testb  $0x2,(%eax)
f0102357:	75 24                	jne    f010237d <mem_init+0xda8>
f0102359:	c7 44 24 0c c8 6d 10 	movl   $0xf0106dc8,0xc(%esp)
f0102360:	f0 
f0102361:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102368:	f0 
f0102369:	c7 44 24 04 63 04 00 	movl   $0x463,0x4(%esp)
f0102370:	00 
f0102371:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102378:	e8 c3 dc ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010237d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102384:	00 
f0102385:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010238c:	00 
f010238d:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102392:	89 04 24             	mov    %eax,(%esp)
f0102395:	e8 bc ee ff ff       	call   f0101256 <pgdir_walk>
f010239a:	f6 00 04             	testb  $0x4,(%eax)
f010239d:	74 24                	je     f01023c3 <mem_init+0xdee>
f010239f:	c7 44 24 0c fc 6d 10 	movl   $0xf0106dfc,0xc(%esp)
f01023a6:	f0 
f01023a7:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01023ae:	f0 
f01023af:	c7 44 24 04 64 04 00 	movl   $0x464,0x4(%esp)
f01023b6:	00 
f01023b7:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01023be:	e8 7d dc ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01023c3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01023ca:	00 
f01023cb:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01023d2:	00 
f01023d3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023d6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01023da:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f01023df:	89 04 24             	mov    %eax,(%esp)
f01023e2:	e8 e4 f0 ff ff       	call   f01014cb <page_insert>
f01023e7:	85 c0                	test   %eax,%eax
f01023e9:	78 24                	js     f010240f <mem_init+0xe3a>
f01023eb:	c7 44 24 0c 34 6e 10 	movl   $0xf0106e34,0xc(%esp)
f01023f2:	f0 
f01023f3:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01023fa:	f0 
f01023fb:	c7 44 24 04 67 04 00 	movl   $0x467,0x4(%esp)
f0102402:	00 
f0102403:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010240a:	e8 31 dc ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010240f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102416:	00 
f0102417:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010241e:	00 
f010241f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102423:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102428:	89 04 24             	mov    %eax,(%esp)
f010242b:	e8 9b f0 ff ff       	call   f01014cb <page_insert>
f0102430:	85 c0                	test   %eax,%eax
f0102432:	74 24                	je     f0102458 <mem_init+0xe83>
f0102434:	c7 44 24 0c 6c 6e 10 	movl   $0xf0106e6c,0xc(%esp)
f010243b:	f0 
f010243c:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102443:	f0 
f0102444:	c7 44 24 04 6a 04 00 	movl   $0x46a,0x4(%esp)
f010244b:	00 
f010244c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102453:	e8 e8 db ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102458:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010245f:	00 
f0102460:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102467:	00 
f0102468:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f010246d:	89 04 24             	mov    %eax,(%esp)
f0102470:	e8 e1 ed ff ff       	call   f0101256 <pgdir_walk>
f0102475:	f6 00 04             	testb  $0x4,(%eax)
f0102478:	74 24                	je     f010249e <mem_init+0xec9>
f010247a:	c7 44 24 0c fc 6d 10 	movl   $0xf0106dfc,0xc(%esp)
f0102481:	f0 
f0102482:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102489:	f0 
f010248a:	c7 44 24 04 6b 04 00 	movl   $0x46b,0x4(%esp)
f0102491:	00 
f0102492:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102499:	e8 a2 db ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010249e:	8b 3d 0c bf 22 f0    	mov    0xf022bf0c,%edi
f01024a4:	ba 00 00 00 00       	mov    $0x0,%edx
f01024a9:	89 f8                	mov    %edi,%eax
f01024ab:	e8 65 e6 ff ff       	call   f0100b15 <check_va2pa>
f01024b0:	89 c1                	mov    %eax,%ecx
f01024b2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01024b5:	89 d8                	mov    %ebx,%eax
f01024b7:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f01024bd:	c1 f8 03             	sar    $0x3,%eax
f01024c0:	c1 e0 0c             	shl    $0xc,%eax
f01024c3:	39 c1                	cmp    %eax,%ecx
f01024c5:	74 24                	je     f01024eb <mem_init+0xf16>
f01024c7:	c7 44 24 0c a8 6e 10 	movl   $0xf0106ea8,0xc(%esp)
f01024ce:	f0 
f01024cf:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01024d6:	f0 
f01024d7:	c7 44 24 04 6e 04 00 	movl   $0x46e,0x4(%esp)
f01024de:	00 
f01024df:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01024e6:	e8 55 db ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01024eb:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024f0:	89 f8                	mov    %edi,%eax
f01024f2:	e8 1e e6 ff ff       	call   f0100b15 <check_va2pa>
f01024f7:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01024fa:	74 24                	je     f0102520 <mem_init+0xf4b>
f01024fc:	c7 44 24 0c d4 6e 10 	movl   $0xf0106ed4,0xc(%esp)
f0102503:	f0 
f0102504:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010250b:	f0 
f010250c:	c7 44 24 04 6f 04 00 	movl   $0x46f,0x4(%esp)
f0102513:	00 
f0102514:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010251b:	e8 20 db ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102520:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0102525:	74 24                	je     f010254b <mem_init+0xf76>
f0102527:	c7 44 24 0c b6 75 10 	movl   $0xf01075b6,0xc(%esp)
f010252e:	f0 
f010252f:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102536:	f0 
f0102537:	c7 44 24 04 71 04 00 	movl   $0x471,0x4(%esp)
f010253e:	00 
f010253f:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102546:	e8 f5 da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010254b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102550:	74 24                	je     f0102576 <mem_init+0xfa1>
f0102552:	c7 44 24 0c c7 75 10 	movl   $0xf01075c7,0xc(%esp)
f0102559:	f0 
f010255a:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102561:	f0 
f0102562:	c7 44 24 04 72 04 00 	movl   $0x472,0x4(%esp)
f0102569:	00 
f010256a:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102571:	e8 ca da ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102576:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010257d:	e8 c5 eb ff ff       	call   f0101147 <page_alloc>
f0102582:	85 c0                	test   %eax,%eax
f0102584:	74 04                	je     f010258a <mem_init+0xfb5>
f0102586:	39 c6                	cmp    %eax,%esi
f0102588:	74 24                	je     f01025ae <mem_init+0xfd9>
f010258a:	c7 44 24 0c 04 6f 10 	movl   $0xf0106f04,0xc(%esp)
f0102591:	f0 
f0102592:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102599:	f0 
f010259a:	c7 44 24 04 75 04 00 	movl   $0x475,0x4(%esp)
f01025a1:	00 
f01025a2:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01025a9:	e8 92 da ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01025ae:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01025b5:	00 
f01025b6:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f01025bb:	89 04 24             	mov    %eax,(%esp)
f01025be:	e8 bf ee ff ff       	call   f0101482 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01025c3:	8b 3d 0c bf 22 f0    	mov    0xf022bf0c,%edi
f01025c9:	ba 00 00 00 00       	mov    $0x0,%edx
f01025ce:	89 f8                	mov    %edi,%eax
f01025d0:	e8 40 e5 ff ff       	call   f0100b15 <check_va2pa>
f01025d5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025d8:	74 24                	je     f01025fe <mem_init+0x1029>
f01025da:	c7 44 24 0c 28 6f 10 	movl   $0xf0106f28,0xc(%esp)
f01025e1:	f0 
f01025e2:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01025e9:	f0 
f01025ea:	c7 44 24 04 79 04 00 	movl   $0x479,0x4(%esp)
f01025f1:	00 
f01025f2:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01025f9:	e8 42 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01025fe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102603:	89 f8                	mov    %edi,%eax
f0102605:	e8 0b e5 ff ff       	call   f0100b15 <check_va2pa>
f010260a:	89 da                	mov    %ebx,%edx
f010260c:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
f0102612:	c1 fa 03             	sar    $0x3,%edx
f0102615:	c1 e2 0c             	shl    $0xc,%edx
f0102618:	39 d0                	cmp    %edx,%eax
f010261a:	74 24                	je     f0102640 <mem_init+0x106b>
f010261c:	c7 44 24 0c d4 6e 10 	movl   $0xf0106ed4,0xc(%esp)
f0102623:	f0 
f0102624:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010262b:	f0 
f010262c:	c7 44 24 04 7a 04 00 	movl   $0x47a,0x4(%esp)
f0102633:	00 
f0102634:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010263b:	e8 00 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102640:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102645:	74 24                	je     f010266b <mem_init+0x1096>
f0102647:	c7 44 24 0c 6d 75 10 	movl   $0xf010756d,0xc(%esp)
f010264e:	f0 
f010264f:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102656:	f0 
f0102657:	c7 44 24 04 7b 04 00 	movl   $0x47b,0x4(%esp)
f010265e:	00 
f010265f:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102666:	e8 d5 d9 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010266b:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102670:	74 24                	je     f0102696 <mem_init+0x10c1>
f0102672:	c7 44 24 0c c7 75 10 	movl   $0xf01075c7,0xc(%esp)
f0102679:	f0 
f010267a:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102681:	f0 
f0102682:	c7 44 24 04 7c 04 00 	movl   $0x47c,0x4(%esp)
f0102689:	00 
f010268a:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102691:	e8 aa d9 ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102696:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010269d:	00 
f010269e:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01026a5:	00 
f01026a6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01026aa:	89 3c 24             	mov    %edi,(%esp)
f01026ad:	e8 19 ee ff ff       	call   f01014cb <page_insert>
f01026b2:	85 c0                	test   %eax,%eax
f01026b4:	74 24                	je     f01026da <mem_init+0x1105>
f01026b6:	c7 44 24 0c 4c 6f 10 	movl   $0xf0106f4c,0xc(%esp)
f01026bd:	f0 
f01026be:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01026c5:	f0 
f01026c6:	c7 44 24 04 7f 04 00 	movl   $0x47f,0x4(%esp)
f01026cd:	00 
f01026ce:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01026d5:	e8 66 d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01026da:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01026df:	75 24                	jne    f0102705 <mem_init+0x1130>
f01026e1:	c7 44 24 0c d8 75 10 	movl   $0xf01075d8,0xc(%esp)
f01026e8:	f0 
f01026e9:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01026f0:	f0 
f01026f1:	c7 44 24 04 80 04 00 	movl   $0x480,0x4(%esp)
f01026f8:	00 
f01026f9:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102700:	e8 3b d9 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102705:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102708:	74 24                	je     f010272e <mem_init+0x1159>
f010270a:	c7 44 24 0c e4 75 10 	movl   $0xf01075e4,0xc(%esp)
f0102711:	f0 
f0102712:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102719:	f0 
f010271a:	c7 44 24 04 81 04 00 	movl   $0x481,0x4(%esp)
f0102721:	00 
f0102722:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102729:	e8 12 d9 ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f010272e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102735:	00 
f0102736:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f010273b:	89 04 24             	mov    %eax,(%esp)
f010273e:	e8 3f ed ff ff       	call   f0101482 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102743:	8b 3d 0c bf 22 f0    	mov    0xf022bf0c,%edi
f0102749:	ba 00 00 00 00       	mov    $0x0,%edx
f010274e:	89 f8                	mov    %edi,%eax
f0102750:	e8 c0 e3 ff ff       	call   f0100b15 <check_va2pa>
f0102755:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102758:	74 24                	je     f010277e <mem_init+0x11a9>
f010275a:	c7 44 24 0c 28 6f 10 	movl   $0xf0106f28,0xc(%esp)
f0102761:	f0 
f0102762:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102769:	f0 
f010276a:	c7 44 24 04 85 04 00 	movl   $0x485,0x4(%esp)
f0102771:	00 
f0102772:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102779:	e8 c2 d8 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f010277e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102783:	89 f8                	mov    %edi,%eax
f0102785:	e8 8b e3 ff ff       	call   f0100b15 <check_va2pa>
f010278a:	83 f8 ff             	cmp    $0xffffffff,%eax
f010278d:	74 24                	je     f01027b3 <mem_init+0x11de>
f010278f:	c7 44 24 0c 84 6f 10 	movl   $0xf0106f84,0xc(%esp)
f0102796:	f0 
f0102797:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010279e:	f0 
f010279f:	c7 44 24 04 86 04 00 	movl   $0x486,0x4(%esp)
f01027a6:	00 
f01027a7:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01027ae:	e8 8d d8 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01027b3:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01027b8:	74 24                	je     f01027de <mem_init+0x1209>
f01027ba:	c7 44 24 0c f9 75 10 	movl   $0xf01075f9,0xc(%esp)
f01027c1:	f0 
f01027c2:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01027c9:	f0 
f01027ca:	c7 44 24 04 87 04 00 	movl   $0x487,0x4(%esp)
f01027d1:	00 
f01027d2:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01027d9:	e8 62 d8 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01027de:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01027e3:	74 24                	je     f0102809 <mem_init+0x1234>
f01027e5:	c7 44 24 0c c7 75 10 	movl   $0xf01075c7,0xc(%esp)
f01027ec:	f0 
f01027ed:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01027f4:	f0 
f01027f5:	c7 44 24 04 88 04 00 	movl   $0x488,0x4(%esp)
f01027fc:	00 
f01027fd:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102804:	e8 37 d8 ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102809:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102810:	e8 32 e9 ff ff       	call   f0101147 <page_alloc>
f0102815:	85 c0                	test   %eax,%eax
f0102817:	74 04                	je     f010281d <mem_init+0x1248>
f0102819:	39 c3                	cmp    %eax,%ebx
f010281b:	74 24                	je     f0102841 <mem_init+0x126c>
f010281d:	c7 44 24 0c ac 6f 10 	movl   $0xf0106fac,0xc(%esp)
f0102824:	f0 
f0102825:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010282c:	f0 
f010282d:	c7 44 24 04 8b 04 00 	movl   $0x48b,0x4(%esp)
f0102834:	00 
f0102835:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010283c:	e8 ff d7 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102841:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102848:	e8 fa e8 ff ff       	call   f0101147 <page_alloc>
f010284d:	85 c0                	test   %eax,%eax
f010284f:	74 24                	je     f0102875 <mem_init+0x12a0>
f0102851:	c7 44 24 0c 1b 75 10 	movl   $0xf010751b,0xc(%esp)
f0102858:	f0 
f0102859:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102860:	f0 
f0102861:	c7 44 24 04 8e 04 00 	movl   $0x48e,0x4(%esp)
f0102868:	00 
f0102869:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102870:	e8 cb d7 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102875:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f010287a:	8b 08                	mov    (%eax),%ecx
f010287c:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102882:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102885:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
f010288b:	c1 fa 03             	sar    $0x3,%edx
f010288e:	c1 e2 0c             	shl    $0xc,%edx
f0102891:	39 d1                	cmp    %edx,%ecx
f0102893:	74 24                	je     f01028b9 <mem_init+0x12e4>
f0102895:	c7 44 24 0c 50 6c 10 	movl   $0xf0106c50,0xc(%esp)
f010289c:	f0 
f010289d:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01028a4:	f0 
f01028a5:	c7 44 24 04 91 04 00 	movl   $0x491,0x4(%esp)
f01028ac:	00 
f01028ad:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01028b4:	e8 87 d7 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01028b9:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01028bf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028c2:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01028c7:	74 24                	je     f01028ed <mem_init+0x1318>
f01028c9:	c7 44 24 0c 7e 75 10 	movl   $0xf010757e,0xc(%esp)
f01028d0:	f0 
f01028d1:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01028d8:	f0 
f01028d9:	c7 44 24 04 93 04 00 	movl   $0x493,0x4(%esp)
f01028e0:	00 
f01028e1:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01028e8:	e8 53 d7 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01028ed:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028f0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01028f6:	89 04 24             	mov    %eax,(%esp)
f01028f9:	e8 da e8 ff ff       	call   f01011d8 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01028fe:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102905:	00 
f0102906:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010290d:	00 
f010290e:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102913:	89 04 24             	mov    %eax,(%esp)
f0102916:	e8 3b e9 ff ff       	call   f0101256 <pgdir_walk>
f010291b:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010291e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102921:	8b 15 0c bf 22 f0    	mov    0xf022bf0c,%edx
f0102927:	8b 7a 04             	mov    0x4(%edx),%edi
f010292a:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102930:	8b 0d 08 bf 22 f0    	mov    0xf022bf08,%ecx
f0102936:	89 f8                	mov    %edi,%eax
f0102938:	c1 e8 0c             	shr    $0xc,%eax
f010293b:	39 c8                	cmp    %ecx,%eax
f010293d:	72 20                	jb     f010295f <mem_init+0x138a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010293f:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102943:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f010294a:	f0 
f010294b:	c7 44 24 04 9a 04 00 	movl   $0x49a,0x4(%esp)
f0102952:	00 
f0102953:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010295a:	e8 e1 d6 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010295f:	81 ef fc ff ff 0f    	sub    $0xffffffc,%edi
f0102965:	39 7d cc             	cmp    %edi,-0x34(%ebp)
f0102968:	74 24                	je     f010298e <mem_init+0x13b9>
f010296a:	c7 44 24 0c 0a 76 10 	movl   $0xf010760a,0xc(%esp)
f0102971:	f0 
f0102972:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102979:	f0 
f010297a:	c7 44 24 04 9b 04 00 	movl   $0x49b,0x4(%esp)
f0102981:	00 
f0102982:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102989:	e8 b2 d6 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010298e:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102995:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102998:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010299e:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f01029a4:	c1 f8 03             	sar    $0x3,%eax
f01029a7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01029aa:	89 c2                	mov    %eax,%edx
f01029ac:	c1 ea 0c             	shr    $0xc,%edx
f01029af:	39 d1                	cmp    %edx,%ecx
f01029b1:	77 20                	ja     f01029d3 <mem_init+0x13fe>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01029b3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01029b7:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f01029be:	f0 
f01029bf:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01029c6:	00 
f01029c7:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f01029ce:	e8 6d d6 ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01029d3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01029da:	00 
f01029db:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01029e2:	00 
	return (void *)(pa + KERNBASE);
f01029e3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01029e8:	89 04 24             	mov    %eax,(%esp)
f01029eb:	e8 97 2c 00 00       	call   f0105687 <memset>
	page_free(pp0);
f01029f0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01029f3:	89 3c 24             	mov    %edi,(%esp)
f01029f6:	e8 dd e7 ff ff       	call   f01011d8 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01029fb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102a02:	00 
f0102a03:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102a0a:	00 
f0102a0b:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102a10:	89 04 24             	mov    %eax,(%esp)
f0102a13:	e8 3e e8 ff ff       	call   f0101256 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102a18:	89 fa                	mov    %edi,%edx
f0102a1a:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
f0102a20:	c1 fa 03             	sar    $0x3,%edx
f0102a23:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a26:	89 d0                	mov    %edx,%eax
f0102a28:	c1 e8 0c             	shr    $0xc,%eax
f0102a2b:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f0102a31:	72 20                	jb     f0102a53 <mem_init+0x147e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a33:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102a37:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0102a3e:	f0 
f0102a3f:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102a46:	00 
f0102a47:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0102a4e:	e8 ed d5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102a53:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102a59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102a5c:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102a62:	f6 00 01             	testb  $0x1,(%eax)
f0102a65:	74 24                	je     f0102a8b <mem_init+0x14b6>
f0102a67:	c7 44 24 0c 22 76 10 	movl   $0xf0107622,0xc(%esp)
f0102a6e:	f0 
f0102a6f:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102a76:	f0 
f0102a77:	c7 44 24 04 a5 04 00 	movl   $0x4a5,0x4(%esp)
f0102a7e:	00 
f0102a7f:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102a86:	e8 b5 d5 ff ff       	call   f0100040 <_panic>
f0102a8b:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102a8e:	39 d0                	cmp    %edx,%eax
f0102a90:	75 d0                	jne    f0102a62 <mem_init+0x148d>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102a92:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102a97:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102a9d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102aa0:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102aa6:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102aa9:	89 0d 44 b2 22 f0    	mov    %ecx,0xf022b244

	// free the pages we took
	page_free(pp0);
f0102aaf:	89 04 24             	mov    %eax,(%esp)
f0102ab2:	e8 21 e7 ff ff       	call   f01011d8 <page_free>
	page_free(pp1);
f0102ab7:	89 1c 24             	mov    %ebx,(%esp)
f0102aba:	e8 19 e7 ff ff       	call   f01011d8 <page_free>
	page_free(pp2);
f0102abf:	89 34 24             	mov    %esi,(%esp)
f0102ac2:	e8 11 e7 ff ff       	call   f01011d8 <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102ac7:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f0102ace:	00 
f0102acf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ad6:	e8 b2 ea ff ff       	call   f010158d <mmio_map_region>
f0102adb:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f0102add:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102ae4:	00 
f0102ae5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aec:	e8 9c ea ff ff       	call   f010158d <mmio_map_region>
f0102af1:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f0102af3:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f0102af9:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f0102afe:	77 08                	ja     f0102b08 <mem_init+0x1533>
f0102b00:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0102b06:	77 24                	ja     f0102b2c <mem_init+0x1557>
f0102b08:	c7 44 24 0c d0 6f 10 	movl   $0xf0106fd0,0xc(%esp)
f0102b0f:	f0 
f0102b10:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102b17:	f0 
f0102b18:	c7 44 24 04 b5 04 00 	movl   $0x4b5,0x4(%esp)
f0102b1f:	00 
f0102b20:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102b27:	e8 14 d5 ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f0102b2c:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102b32:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102b38:	77 08                	ja     f0102b42 <mem_init+0x156d>
f0102b3a:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102b40:	77 24                	ja     f0102b66 <mem_init+0x1591>
f0102b42:	c7 44 24 0c f8 6f 10 	movl   $0xf0106ff8,0xc(%esp)
f0102b49:	f0 
f0102b4a:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102b51:	f0 
f0102b52:	c7 44 24 04 b6 04 00 	movl   $0x4b6,0x4(%esp)
f0102b59:	00 
f0102b5a:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102b61:	e8 da d4 ff ff       	call   f0100040 <_panic>
f0102b66:	89 da                	mov    %ebx,%edx
f0102b68:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102b6a:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102b70:	74 24                	je     f0102b96 <mem_init+0x15c1>
f0102b72:	c7 44 24 0c 20 70 10 	movl   $0xf0107020,0xc(%esp)
f0102b79:	f0 
f0102b7a:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102b81:	f0 
f0102b82:	c7 44 24 04 b8 04 00 	movl   $0x4b8,0x4(%esp)
f0102b89:	00 
f0102b8a:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102b91:	e8 aa d4 ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102b96:	39 c6                	cmp    %eax,%esi
f0102b98:	73 24                	jae    f0102bbe <mem_init+0x15e9>
f0102b9a:	c7 44 24 0c 39 76 10 	movl   $0xf0107639,0xc(%esp)
f0102ba1:	f0 
f0102ba2:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102ba9:	f0 
f0102baa:	c7 44 24 04 ba 04 00 	movl   $0x4ba,0x4(%esp)
f0102bb1:	00 
f0102bb2:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102bb9:	e8 82 d4 ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102bbe:	8b 3d 0c bf 22 f0    	mov    0xf022bf0c,%edi
f0102bc4:	89 da                	mov    %ebx,%edx
f0102bc6:	89 f8                	mov    %edi,%eax
f0102bc8:	e8 48 df ff ff       	call   f0100b15 <check_va2pa>
f0102bcd:	85 c0                	test   %eax,%eax
f0102bcf:	74 24                	je     f0102bf5 <mem_init+0x1620>
f0102bd1:	c7 44 24 0c 48 70 10 	movl   $0xf0107048,0xc(%esp)
f0102bd8:	f0 
f0102bd9:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102be0:	f0 
f0102be1:	c7 44 24 04 bc 04 00 	movl   $0x4bc,0x4(%esp)
f0102be8:	00 
f0102be9:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102bf0:	e8 4b d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102bf5:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102bfb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102bfe:	89 c2                	mov    %eax,%edx
f0102c00:	89 f8                	mov    %edi,%eax
f0102c02:	e8 0e df ff ff       	call   f0100b15 <check_va2pa>
f0102c07:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102c0c:	74 24                	je     f0102c32 <mem_init+0x165d>
f0102c0e:	c7 44 24 0c 6c 70 10 	movl   $0xf010706c,0xc(%esp)
f0102c15:	f0 
f0102c16:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102c1d:	f0 
f0102c1e:	c7 44 24 04 bd 04 00 	movl   $0x4bd,0x4(%esp)
f0102c25:	00 
f0102c26:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102c2d:	e8 0e d4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f0102c32:	89 f2                	mov    %esi,%edx
f0102c34:	89 f8                	mov    %edi,%eax
f0102c36:	e8 da de ff ff       	call   f0100b15 <check_va2pa>
f0102c3b:	85 c0                	test   %eax,%eax
f0102c3d:	74 24                	je     f0102c63 <mem_init+0x168e>
f0102c3f:	c7 44 24 0c 9c 70 10 	movl   $0xf010709c,0xc(%esp)
f0102c46:	f0 
f0102c47:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102c4e:	f0 
f0102c4f:	c7 44 24 04 be 04 00 	movl   $0x4be,0x4(%esp)
f0102c56:	00 
f0102c57:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102c5e:	e8 dd d3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f0102c63:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f0102c69:	89 f8                	mov    %edi,%eax
f0102c6b:	e8 a5 de ff ff       	call   f0100b15 <check_va2pa>
f0102c70:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102c73:	74 24                	je     f0102c99 <mem_init+0x16c4>
f0102c75:	c7 44 24 0c c0 70 10 	movl   $0xf01070c0,0xc(%esp)
f0102c7c:	f0 
f0102c7d:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102c84:	f0 
f0102c85:	c7 44 24 04 bf 04 00 	movl   $0x4bf,0x4(%esp)
f0102c8c:	00 
f0102c8d:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102c94:	e8 a7 d3 ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f0102c99:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102ca0:	00 
f0102ca1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102ca5:	89 3c 24             	mov    %edi,(%esp)
f0102ca8:	e8 a9 e5 ff ff       	call   f0101256 <pgdir_walk>
f0102cad:	f6 00 1a             	testb  $0x1a,(%eax)
f0102cb0:	75 24                	jne    f0102cd6 <mem_init+0x1701>
f0102cb2:	c7 44 24 0c ec 70 10 	movl   $0xf01070ec,0xc(%esp)
f0102cb9:	f0 
f0102cba:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102cc1:	f0 
f0102cc2:	c7 44 24 04 c1 04 00 	movl   $0x4c1,0x4(%esp)
f0102cc9:	00 
f0102cca:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102cd1:	e8 6a d3 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102cd6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102cdd:	00 
f0102cde:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102ce2:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102ce7:	89 04 24             	mov    %eax,(%esp)
f0102cea:	e8 67 e5 ff ff       	call   f0101256 <pgdir_walk>
f0102cef:	f6 00 04             	testb  $0x4,(%eax)
f0102cf2:	74 24                	je     f0102d18 <mem_init+0x1743>
f0102cf4:	c7 44 24 0c 30 71 10 	movl   $0xf0107130,0xc(%esp)
f0102cfb:	f0 
f0102cfc:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102d03:	f0 
f0102d04:	c7 44 24 04 c2 04 00 	movl   $0x4c2,0x4(%esp)
f0102d0b:	00 
f0102d0c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102d13:	e8 28 d3 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102d18:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d1f:	00 
f0102d20:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102d24:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102d29:	89 04 24             	mov    %eax,(%esp)
f0102d2c:	e8 25 e5 ff ff       	call   f0101256 <pgdir_walk>
f0102d31:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102d37:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d3e:	00 
f0102d3f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102d42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d46:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102d4b:	89 04 24             	mov    %eax,(%esp)
f0102d4e:	e8 03 e5 ff ff       	call   f0101256 <pgdir_walk>
f0102d53:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102d59:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102d60:	00 
f0102d61:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102d65:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102d6a:	89 04 24             	mov    %eax,(%esp)
f0102d6d:	e8 e4 e4 ff ff       	call   f0101256 <pgdir_walk>
f0102d72:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f0102d78:	c7 04 24 4b 76 10 f0 	movl   $0xf010764b,(%esp)
f0102d7f:	e8 88 13 00 00       	call   f010410c <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102d84:	a1 10 bf 22 f0       	mov    0xf022bf10,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d89:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102d8e:	77 20                	ja     f0102db0 <mem_init+0x17db>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d90:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d94:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0102d9b:	f0 
f0102d9c:	c7 44 24 04 c5 00 00 	movl   $0xc5,0x4(%esp)
f0102da3:	00 
f0102da4:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102dab:	e8 90 d2 ff ff       	call   f0100040 <_panic>
f0102db0:	8b 15 08 bf 22 f0    	mov    0xf022bf08,%edx
f0102db6:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102dbd:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102dc3:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102dca:	00 
	return (physaddr_t)kva - KERNBASE;
f0102dcb:	05 00 00 00 10       	add    $0x10000000,%eax
f0102dd0:	89 04 24             	mov    %eax,(%esp)
f0102dd3:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102dd8:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102ddd:	e8 83 e5 ff ff       	call   f0101365 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f0102de2:	a1 4c b2 22 f0       	mov    0xf022b24c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102de7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dec:	77 20                	ja     f0102e0e <mem_init+0x1839>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dee:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102df2:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0102df9:	f0 
f0102dfa:	c7 44 24 04 cd 00 00 	movl   $0xcd,0x4(%esp)
f0102e01:	00 
f0102e02:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102e09:	e8 32 d2 ff ff       	call   f0100040 <_panic>
f0102e0e:	c7 44 24 04 04 00 00 	movl   $0x4,0x4(%esp)
f0102e15:	00 
	return (physaddr_t)kva - KERNBASE;
f0102e16:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e1b:	89 04 24             	mov    %eax,(%esp)
f0102e1e:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102e23:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102e28:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102e2d:	e8 33 e5 ff ff       	call   f0101365 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e32:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102e37:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e3c:	77 20                	ja     f0102e5e <mem_init+0x1889>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e3e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e42:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0102e49:	f0 
f0102e4a:	c7 44 24 04 d9 00 00 	movl   $0xd9,0x4(%esp)
f0102e51:	00 
f0102e52:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102e59:	e8 e2 d1 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102e5e:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e65:	00 
f0102e66:	c7 04 24 00 60 11 00 	movl   $0x116000,(%esp)
f0102e6d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e72:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e77:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102e7c:	e8 e4 e4 ff ff       	call   f0101365 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f0102e81:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102e88:	00 
f0102e89:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e90:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e95:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e9a:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102e9f:	e8 c1 e4 ff ff       	call   f0101365 <boot_map_region>
f0102ea4:	bf 00 d0 26 f0       	mov    $0xf026d000,%edi
f0102ea9:	bb 00 d0 22 f0       	mov    $0xf022d000,%ebx
f0102eae:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102eb3:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102eb9:	77 20                	ja     f0102edb <mem_init+0x1906>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ebb:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102ebf:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0102ec6:	f0 
f0102ec7:	c7 44 24 04 20 01 00 	movl   $0x120,0x4(%esp)
f0102ece:	00 
f0102ecf:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102ed6:	e8 65 d1 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f0102edb:	c7 44 24 04 03 00 00 	movl   $0x3,0x4(%esp)
f0102ee2:	00 
f0102ee3:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f0102ee9:	89 04 24             	mov    %eax,(%esp)
f0102eec:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102ef1:	89 f2                	mov    %esi,%edx
f0102ef3:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0102ef8:	e8 68 e4 ff ff       	call   f0101365 <boot_map_region>
f0102efd:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102f03:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f0102f09:	39 fb                	cmp    %edi,%ebx
f0102f0b:	75 a6                	jne    f0102eb3 <mem_init+0x18de>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102f0d:	8b 3d 0c bf 22 f0    	mov    0xf022bf0c,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102f13:	a1 08 bf 22 f0       	mov    0xf022bf08,%eax
f0102f18:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102f1b:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102f22:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102f27:	89 45 d0             	mov    %eax,-0x30(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102f2a:	8b 35 10 bf 22 f0    	mov    0xf022bf10,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f30:	89 75 cc             	mov    %esi,-0x34(%ebp)
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
	return (physaddr_t)kva - KERNBASE;
f0102f33:	8d 86 00 00 00 10    	lea    0x10000000(%esi),%eax
f0102f39:	89 45 c8             	mov    %eax,-0x38(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102f3c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0102f41:	eb 6a                	jmp    f0102fad <mem_init+0x19d8>
f0102f43:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102f49:	89 f8                	mov    %edi,%eax
f0102f4b:	e8 c5 db ff ff       	call   f0100b15 <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f50:	81 7d cc ff ff ff ef 	cmpl   $0xefffffff,-0x34(%ebp)
f0102f57:	77 20                	ja     f0102f79 <mem_init+0x19a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f59:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102f5d:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0102f64:	f0 
f0102f65:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102f6c:	00 
f0102f6d:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102f74:	e8 c7 d0 ff ff       	call   f0100040 <_panic>
f0102f79:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f0102f7c:	8d 14 0b             	lea    (%ebx,%ecx,1),%edx
f0102f7f:	39 d0                	cmp    %edx,%eax
f0102f81:	74 24                	je     f0102fa7 <mem_init+0x19d2>
f0102f83:	c7 44 24 0c 64 71 10 	movl   $0xf0107164,0xc(%esp)
f0102f8a:	f0 
f0102f8b:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0102f92:	f0 
f0102f93:	c7 44 24 04 d7 03 00 	movl   $0x3d7,0x4(%esp)
f0102f9a:	00 
f0102f9b:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102fa2:	e8 99 d0 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102fa7:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0102fad:	39 5d d0             	cmp    %ebx,-0x30(%ebp)
f0102fb0:	77 91                	ja     f0102f43 <mem_init+0x196e>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f0102fb2:	8b 1d 4c b2 22 f0    	mov    0xf022b24c,%ebx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fb8:	89 de                	mov    %ebx,%esi
f0102fba:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102fbf:	89 f8                	mov    %edi,%eax
f0102fc1:	e8 4f db ff ff       	call   f0100b15 <check_va2pa>
f0102fc6:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0102fcc:	77 20                	ja     f0102fee <mem_init+0x1a19>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102fce:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0102fd2:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0102fd9:	f0 
f0102fda:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0102fe1:	00 
f0102fe2:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0102fe9:	e8 52 d0 ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102fee:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f0102ff3:	81 c6 00 00 40 21    	add    $0x21400000,%esi
f0102ff9:	8d 14 1e             	lea    (%esi,%ebx,1),%edx
f0102ffc:	39 d0                	cmp    %edx,%eax
f0102ffe:	74 24                	je     f0103024 <mem_init+0x1a4f>
f0103000:	c7 44 24 0c 98 71 10 	movl   $0xf0107198,0xc(%esp)
f0103007:	f0 
f0103008:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010300f:	f0 
f0103010:	c7 44 24 04 dc 03 00 	movl   $0x3dc,0x4(%esp)
f0103017:	00 
f0103018:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010301f:	e8 1c d0 ff ff       	call   f0100040 <_panic>
f0103024:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010302a:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f0103030:	0f 85 a8 05 00 00    	jne    f01035de <mem_init+0x2009>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103036:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103039:	c1 e6 0c             	shl    $0xc,%esi
f010303c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0103041:	eb 3b                	jmp    f010307e <mem_init+0x1aa9>
f0103043:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0103049:	89 f8                	mov    %edi,%eax
f010304b:	e8 c5 da ff ff       	call   f0100b15 <check_va2pa>
f0103050:	39 c3                	cmp    %eax,%ebx
f0103052:	74 24                	je     f0103078 <mem_init+0x1aa3>
f0103054:	c7 44 24 0c cc 71 10 	movl   $0xf01071cc,0xc(%esp)
f010305b:	f0 
f010305c:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0103063:	f0 
f0103064:	c7 44 24 04 e0 03 00 	movl   $0x3e0,0x4(%esp)
f010306b:	00 
f010306c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0103073:	e8 c8 cf ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0103078:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010307e:	39 f3                	cmp    %esi,%ebx
f0103080:	72 c1                	jb     f0103043 <mem_init+0x1a6e>
f0103082:	c7 45 d0 00 d0 22 f0 	movl   $0xf022d000,-0x30(%ebp)
f0103089:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)
f0103090:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f0103095:	b8 00 d0 22 f0       	mov    $0xf022d000,%eax
f010309a:	05 00 80 00 20       	add    $0x20008000,%eax
f010309f:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01030a2:	8d 86 00 80 00 00    	lea    0x8000(%esi),%eax
f01030a8:	89 45 cc             	mov    %eax,-0x34(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01030ab:	89 f2                	mov    %esi,%edx
f01030ad:	89 f8                	mov    %edi,%eax
f01030af:	e8 61 da ff ff       	call   f0100b15 <check_va2pa>
f01030b4:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f01030b7:	81 f9 ff ff ff ef    	cmp    $0xefffffff,%ecx
f01030bd:	77 20                	ja     f01030df <mem_init+0x1b0a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030bf:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01030c3:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f01030ca:	f0 
f01030cb:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f01030d2:	00 
f01030d3:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01030da:	e8 61 cf ff ff       	call   f0100040 <_panic>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030df:	89 f3                	mov    %esi,%ebx
f01030e1:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01030e4:	03 4d d4             	add    -0x2c(%ebp),%ecx
f01030e7:	89 4d c8             	mov    %ecx,-0x38(%ebp)
f01030ea:	8b 4d c8             	mov    -0x38(%ebp),%ecx
f01030ed:	8d 14 19             	lea    (%ecx,%ebx,1),%edx
f01030f0:	39 c2                	cmp    %eax,%edx
f01030f2:	74 24                	je     f0103118 <mem_init+0x1b43>
f01030f4:	c7 44 24 0c f4 71 10 	movl   $0xf01071f4,0xc(%esp)
f01030fb:	f0 
f01030fc:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0103103:	f0 
f0103104:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f010310b:	00 
f010310c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0103113:	e8 28 cf ff ff       	call   f0100040 <_panic>
f0103118:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f010311e:	3b 5d cc             	cmp    -0x34(%ebp),%ebx
f0103121:	0f 85 a9 04 00 00    	jne    f01035d0 <mem_init+0x1ffb>
f0103127:	8d 9e 00 80 ff ff    	lea    -0x8000(%esi),%ebx
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f010312d:	89 da                	mov    %ebx,%edx
f010312f:	89 f8                	mov    %edi,%eax
f0103131:	e8 df d9 ff ff       	call   f0100b15 <check_va2pa>
f0103136:	83 f8 ff             	cmp    $0xffffffff,%eax
f0103139:	74 24                	je     f010315f <mem_init+0x1b8a>
f010313b:	c7 44 24 0c 3c 72 10 	movl   $0xf010723c,0xc(%esp)
f0103142:	f0 
f0103143:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010314a:	f0 
f010314b:	c7 44 24 04 ea 03 00 	movl   $0x3ea,0x4(%esp)
f0103152:	00 
f0103153:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010315a:	e8 e1 ce ff ff       	call   f0100040 <_panic>
f010315f:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0103165:	39 f3                	cmp    %esi,%ebx
f0103167:	75 c4                	jne    f010312d <mem_init+0x1b58>
f0103169:	81 ee 00 00 01 00    	sub    $0x10000,%esi
f010316f:	81 45 d4 00 80 01 00 	addl   $0x18000,-0x2c(%ebp)
f0103176:	81 45 d0 00 80 00 00 	addl   $0x8000,-0x30(%ebp)
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f010317d:	81 fe 00 80 f7 ef    	cmp    $0xeff78000,%esi
f0103183:	0f 85 19 ff ff ff    	jne    f01030a2 <mem_init+0x1acd>
f0103189:	b8 00 00 00 00       	mov    $0x0,%eax
f010318e:	e9 c2 00 00 00       	jmp    f0103255 <mem_init+0x1c80>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0103193:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0103199:	83 fa 04             	cmp    $0x4,%edx
f010319c:	77 2e                	ja     f01031cc <mem_init+0x1bf7>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f010319e:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f01031a2:	0f 85 aa 00 00 00    	jne    f0103252 <mem_init+0x1c7d>
f01031a8:	c7 44 24 0c 64 76 10 	movl   $0xf0107664,0xc(%esp)
f01031af:	f0 
f01031b0:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01031b7:	f0 
f01031b8:	c7 44 24 04 f5 03 00 	movl   $0x3f5,0x4(%esp)
f01031bf:	00 
f01031c0:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01031c7:	e8 74 ce ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f01031cc:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f01031d1:	76 55                	jbe    f0103228 <mem_init+0x1c53>
				assert(pgdir[i] & PTE_P);
f01031d3:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01031d6:	f6 c2 01             	test   $0x1,%dl
f01031d9:	75 24                	jne    f01031ff <mem_init+0x1c2a>
f01031db:	c7 44 24 0c 64 76 10 	movl   $0xf0107664,0xc(%esp)
f01031e2:	f0 
f01031e3:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01031ea:	f0 
f01031eb:	c7 44 24 04 f9 03 00 	movl   $0x3f9,0x4(%esp)
f01031f2:	00 
f01031f3:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01031fa:	e8 41 ce ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f01031ff:	f6 c2 02             	test   $0x2,%dl
f0103202:	75 4e                	jne    f0103252 <mem_init+0x1c7d>
f0103204:	c7 44 24 0c 75 76 10 	movl   $0xf0107675,0xc(%esp)
f010320b:	f0 
f010320c:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0103213:	f0 
f0103214:	c7 44 24 04 fa 03 00 	movl   $0x3fa,0x4(%esp)
f010321b:	00 
f010321c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0103223:	e8 18 ce ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0103228:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f010322c:	74 24                	je     f0103252 <mem_init+0x1c7d>
f010322e:	c7 44 24 0c 86 76 10 	movl   $0xf0107686,0xc(%esp)
f0103235:	f0 
f0103236:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010323d:	f0 
f010323e:	c7 44 24 04 fc 03 00 	movl   $0x3fc,0x4(%esp)
f0103245:	00 
f0103246:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010324d:	e8 ee cd ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0103252:	83 c0 01             	add    $0x1,%eax
f0103255:	3d 00 04 00 00       	cmp    $0x400,%eax
f010325a:	0f 85 33 ff ff ff    	jne    f0103193 <mem_init+0x1bbe>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0103260:	c7 04 24 60 72 10 f0 	movl   $0xf0107260,(%esp)
f0103267:	e8 a0 0e 00 00       	call   f010410c <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f010326c:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0103271:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103276:	77 20                	ja     f0103298 <mem_init+0x1cc3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103278:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010327c:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0103283:	f0 
f0103284:	c7 44 24 04 f2 00 00 	movl   $0xf2,0x4(%esp)
f010328b:	00 
f010328c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0103293:	e8 a8 cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103298:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010329d:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f01032a0:	b8 00 00 00 00       	mov    $0x0,%eax
f01032a5:	e8 5f d9 ff ff       	call   f0100c09 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f01032aa:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f01032ad:	83 e0 f3             	and    $0xfffffff3,%eax
f01032b0:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f01032b5:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01032b8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032bf:	e8 83 de ff ff       	call   f0101147 <page_alloc>
f01032c4:	89 c3                	mov    %eax,%ebx
f01032c6:	85 c0                	test   %eax,%eax
f01032c8:	75 24                	jne    f01032ee <mem_init+0x1d19>
f01032ca:	c7 44 24 0c 70 74 10 	movl   $0xf0107470,0xc(%esp)
f01032d1:	f0 
f01032d2:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01032d9:	f0 
f01032da:	c7 44 24 04 d7 04 00 	movl   $0x4d7,0x4(%esp)
f01032e1:	00 
f01032e2:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01032e9:	e8 52 cd ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01032ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01032f5:	e8 4d de ff ff       	call   f0101147 <page_alloc>
f01032fa:	89 c7                	mov    %eax,%edi
f01032fc:	85 c0                	test   %eax,%eax
f01032fe:	75 24                	jne    f0103324 <mem_init+0x1d4f>
f0103300:	c7 44 24 0c 86 74 10 	movl   $0xf0107486,0xc(%esp)
f0103307:	f0 
f0103308:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010330f:	f0 
f0103310:	c7 44 24 04 d8 04 00 	movl   $0x4d8,0x4(%esp)
f0103317:	00 
f0103318:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010331f:	e8 1c cd ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0103324:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010332b:	e8 17 de ff ff       	call   f0101147 <page_alloc>
f0103330:	89 c6                	mov    %eax,%esi
f0103332:	85 c0                	test   %eax,%eax
f0103334:	75 24                	jne    f010335a <mem_init+0x1d85>
f0103336:	c7 44 24 0c 9c 74 10 	movl   $0xf010749c,0xc(%esp)
f010333d:	f0 
f010333e:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0103345:	f0 
f0103346:	c7 44 24 04 d9 04 00 	movl   $0x4d9,0x4(%esp)
f010334d:	00 
f010334e:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0103355:	e8 e6 cc ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f010335a:	89 1c 24             	mov    %ebx,(%esp)
f010335d:	e8 76 de ff ff       	call   f01011d8 <page_free>
	memset(page2kva(pp1), 1, PGSIZE);
f0103362:	89 f8                	mov    %edi,%eax
f0103364:	e8 67 d7 ff ff       	call   f0100ad0 <page2kva>
f0103369:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103370:	00 
f0103371:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0103378:	00 
f0103379:	89 04 24             	mov    %eax,(%esp)
f010337c:	e8 06 23 00 00       	call   f0105687 <memset>
	memset(page2kva(pp2), 2, PGSIZE);
f0103381:	89 f0                	mov    %esi,%eax
f0103383:	e8 48 d7 ff ff       	call   f0100ad0 <page2kva>
f0103388:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010338f:	00 
f0103390:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103397:	00 
f0103398:	89 04 24             	mov    %eax,(%esp)
f010339b:	e8 e7 22 00 00       	call   f0105687 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f01033a0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01033a7:	00 
f01033a8:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01033af:	00 
f01033b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033b4:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f01033b9:	89 04 24             	mov    %eax,(%esp)
f01033bc:	e8 0a e1 ff ff       	call   f01014cb <page_insert>
	assert(pp1->pp_ref == 1);
f01033c1:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01033c6:	74 24                	je     f01033ec <mem_init+0x1e17>
f01033c8:	c7 44 24 0c 6d 75 10 	movl   $0xf010756d,0xc(%esp)
f01033cf:	f0 
f01033d0:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01033d7:	f0 
f01033d8:	c7 44 24 04 de 04 00 	movl   $0x4de,0x4(%esp)
f01033df:	00 
f01033e0:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01033e7:	e8 54 cc ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01033ec:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01033f3:	01 01 01 
f01033f6:	74 24                	je     f010341c <mem_init+0x1e47>
f01033f8:	c7 44 24 0c 80 72 10 	movl   $0xf0107280,0xc(%esp)
f01033ff:	f0 
f0103400:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0103407:	f0 
f0103408:	c7 44 24 04 df 04 00 	movl   $0x4df,0x4(%esp)
f010340f:	00 
f0103410:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0103417:	e8 24 cc ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010341c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103423:	00 
f0103424:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010342b:	00 
f010342c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103430:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0103435:	89 04 24             	mov    %eax,(%esp)
f0103438:	e8 8e e0 ff ff       	call   f01014cb <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010343d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103444:	02 02 02 
f0103447:	74 24                	je     f010346d <mem_init+0x1e98>
f0103449:	c7 44 24 0c a4 72 10 	movl   $0xf01072a4,0xc(%esp)
f0103450:	f0 
f0103451:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0103458:	f0 
f0103459:	c7 44 24 04 e1 04 00 	movl   $0x4e1,0x4(%esp)
f0103460:	00 
f0103461:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0103468:	e8 d3 cb ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010346d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103472:	74 24                	je     f0103498 <mem_init+0x1ec3>
f0103474:	c7 44 24 0c 8f 75 10 	movl   $0xf010758f,0xc(%esp)
f010347b:	f0 
f010347c:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0103483:	f0 
f0103484:	c7 44 24 04 e2 04 00 	movl   $0x4e2,0x4(%esp)
f010348b:	00 
f010348c:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f0103493:	e8 a8 cb ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0103498:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010349d:	74 24                	je     f01034c3 <mem_init+0x1eee>
f010349f:	c7 44 24 0c f9 75 10 	movl   $0xf01075f9,0xc(%esp)
f01034a6:	f0 
f01034a7:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01034ae:	f0 
f01034af:	c7 44 24 04 e3 04 00 	movl   $0x4e3,0x4(%esp)
f01034b6:	00 
f01034b7:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01034be:	e8 7d cb ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01034c3:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01034ca:	03 03 03 
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01034cd:	89 f0                	mov    %esi,%eax
f01034cf:	e8 fc d5 ff ff       	call   f0100ad0 <page2kva>
f01034d4:	81 38 03 03 03 03    	cmpl   $0x3030303,(%eax)
f01034da:	74 24                	je     f0103500 <mem_init+0x1f2b>
f01034dc:	c7 44 24 0c c8 72 10 	movl   $0xf01072c8,0xc(%esp)
f01034e3:	f0 
f01034e4:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01034eb:	f0 
f01034ec:	c7 44 24 04 e5 04 00 	movl   $0x4e5,0x4(%esp)
f01034f3:	00 
f01034f4:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01034fb:	e8 40 cb ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103500:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103507:	00 
f0103508:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f010350d:	89 04 24             	mov    %eax,(%esp)
f0103510:	e8 6d df ff ff       	call   f0101482 <page_remove>
	assert(pp2->pp_ref == 0);
f0103515:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010351a:	74 24                	je     f0103540 <mem_init+0x1f6b>
f010351c:	c7 44 24 0c c7 75 10 	movl   $0xf01075c7,0xc(%esp)
f0103523:	f0 
f0103524:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010352b:	f0 
f010352c:	c7 44 24 04 e7 04 00 	movl   $0x4e7,0x4(%esp)
f0103533:	00 
f0103534:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010353b:	e8 00 cb ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103540:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
f0103545:	8b 08                	mov    (%eax),%ecx
f0103547:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010354d:	89 da                	mov    %ebx,%edx
f010354f:	2b 15 10 bf 22 f0    	sub    0xf022bf10,%edx
f0103555:	c1 fa 03             	sar    $0x3,%edx
f0103558:	c1 e2 0c             	shl    $0xc,%edx
f010355b:	39 d1                	cmp    %edx,%ecx
f010355d:	74 24                	je     f0103583 <mem_init+0x1fae>
f010355f:	c7 44 24 0c 50 6c 10 	movl   $0xf0106c50,0xc(%esp)
f0103566:	f0 
f0103567:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010356e:	f0 
f010356f:	c7 44 24 04 ea 04 00 	movl   $0x4ea,0x4(%esp)
f0103576:	00 
f0103577:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f010357e:	e8 bd ca ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0103583:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103589:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010358e:	74 24                	je     f01035b4 <mem_init+0x1fdf>
f0103590:	c7 44 24 0c 7e 75 10 	movl   $0xf010757e,0xc(%esp)
f0103597:	f0 
f0103598:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f010359f:	f0 
f01035a0:	c7 44 24 04 ec 04 00 	movl   $0x4ec,0x4(%esp)
f01035a7:	00 
f01035a8:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01035af:	e8 8c ca ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01035b4:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f01035ba:	89 1c 24             	mov    %ebx,(%esp)
f01035bd:	e8 16 dc ff ff       	call   f01011d8 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01035c2:	c7 04 24 f4 72 10 f0 	movl   $0xf01072f4,(%esp)
f01035c9:	e8 3e 0b 00 00       	call   f010410c <cprintf>
f01035ce:	eb 1c                	jmp    f01035ec <mem_init+0x2017>
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f01035d0:	89 da                	mov    %ebx,%edx
f01035d2:	89 f8                	mov    %edi,%eax
f01035d4:	e8 3c d5 ff ff       	call   f0100b15 <check_va2pa>
f01035d9:	e9 0c fb ff ff       	jmp    f01030ea <mem_init+0x1b15>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01035de:	89 da                	mov    %ebx,%edx
f01035e0:	89 f8                	mov    %edi,%eax
f01035e2:	e8 2e d5 ff ff       	call   f0100b15 <check_va2pa>
f01035e7:	e9 0d fa ff ff       	jmp    f0102ff9 <mem_init+0x1a24>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01035ec:	83 c4 4c             	add    $0x4c,%esp
f01035ef:	5b                   	pop    %ebx
f01035f0:	5e                   	pop    %esi
f01035f1:	5f                   	pop    %edi
f01035f2:	5d                   	pop    %ebp
f01035f3:	c3                   	ret    

f01035f4 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f01035f4:	55                   	push   %ebp
f01035f5:	89 e5                	mov    %esp,%ebp
f01035f7:	57                   	push   %edi
f01035f8:	56                   	push   %esi
f01035f9:	53                   	push   %ebx
f01035fa:	83 ec 2c             	sub    $0x2c,%esp
f01035fd:	8b 75 08             	mov    0x8(%ebp),%esi
f0103600:	8b 4d 14             	mov    0x14(%ebp),%ecx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0103603:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103606:	03 5d 10             	add    0x10(%ebp),%ebx
  if (va_beg >= ULIM || va_end >= ULIM) {
f0103609:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f010360f:	77 09                	ja     f010361a <user_mem_check+0x26>
f0103611:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f0103618:	76 1f                	jbe    f0103639 <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f010361a:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0103621:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0103626:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f010362a:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
    return -E_FAULT;
f010362f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103634:	e9 b8 00 00 00       	jmp    f01036f1 <user_mem_check+0xfd>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f0103639:	8b 45 0c             	mov    0xc(%ebp),%eax
f010363c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0103641:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
f0103647:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010364d:	8b 15 08 bf 22 f0    	mov    0xf022bf08,%edx
f0103653:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103656:	89 75 08             	mov    %esi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0103659:	e9 86 00 00 00       	jmp    f01036e4 <user_mem_check+0xf0>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f010365e:	89 c7                	mov    %eax,%edi
f0103660:	c1 ef 16             	shr    $0x16,%edi
f0103663:	8b 75 08             	mov    0x8(%ebp),%esi
f0103666:	8b 56 60             	mov    0x60(%esi),%edx
f0103669:	8b 14 ba             	mov    (%edx,%edi,4),%edx
f010366c:	f6 c2 01             	test   $0x1,%dl
f010366f:	75 13                	jne    f0103684 <user_mem_check+0x90>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0103671:	3b 45 0c             	cmp    0xc(%ebp),%eax
f0103674:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f0103678:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
      return -E_FAULT;
f010367d:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0103682:	eb 6d                	jmp    f01036f1 <user_mem_check+0xfd>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0103684:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010368a:	89 d7                	mov    %edx,%edi
f010368c:	c1 ef 0c             	shr    $0xc,%edi
f010368f:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0103692:	72 20                	jb     f01036b4 <user_mem_check+0xc0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103694:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103698:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f010369f:	f0 
f01036a0:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f01036a7:	00 
f01036a8:	c7 04 24 63 73 10 f0 	movl   $0xf0107363,(%esp)
f01036af:	e8 8c c9 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f01036b4:	89 c7                	mov    %eax,%edi
f01036b6:	c1 ef 0c             	shr    $0xc,%edi
f01036b9:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
f01036bf:	89 ce                	mov    %ecx,%esi
f01036c1:	23 b4 ba 00 00 00 f0 	and    -0x10000000(%edx,%edi,4),%esi
f01036c8:	39 f1                	cmp    %esi,%ecx
f01036ca:	74 13                	je     f01036df <user_mem_check+0xeb>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f01036cc:	3b 45 0c             	cmp    0xc(%ebp),%eax
f01036cf:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f01036d3:	a3 40 b2 22 f0       	mov    %eax,0xf022b240
      return -E_FAULT;
f01036d8:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01036dd:	eb 12                	jmp    f01036f1 <user_mem_check+0xfd>
    }

    va_beg2 += PGSIZE;
f01036df:	05 00 10 00 00       	add    $0x1000,%eax
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f01036e4:	39 d8                	cmp    %ebx,%eax
f01036e6:	0f 82 72 ff ff ff    	jb     f010365e <user_mem_check+0x6a>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f01036ec:	b8 00 00 00 00       	mov    $0x0,%eax

}
f01036f1:	83 c4 2c             	add    $0x2c,%esp
f01036f4:	5b                   	pop    %ebx
f01036f5:	5e                   	pop    %esi
f01036f6:	5f                   	pop    %edi
f01036f7:	5d                   	pop    %ebp
f01036f8:	c3                   	ret    

f01036f9 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f01036f9:	55                   	push   %ebp
f01036fa:	89 e5                	mov    %esp,%ebp
f01036fc:	53                   	push   %ebx
f01036fd:	83 ec 14             	sub    $0x14,%esp
f0103700:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0103703:	8b 45 14             	mov    0x14(%ebp),%eax
f0103706:	83 c8 04             	or     $0x4,%eax
f0103709:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010370d:	8b 45 10             	mov    0x10(%ebp),%eax
f0103710:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103714:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103717:	89 44 24 04          	mov    %eax,0x4(%esp)
f010371b:	89 1c 24             	mov    %ebx,(%esp)
f010371e:	e8 d1 fe ff ff       	call   f01035f4 <user_mem_check>
f0103723:	85 c0                	test   %eax,%eax
f0103725:	79 24                	jns    f010374b <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f0103727:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f010372c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103730:	8b 43 48             	mov    0x48(%ebx),%eax
f0103733:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103737:	c7 04 24 20 73 10 f0 	movl   $0xf0107320,(%esp)
f010373e:	e8 c9 09 00 00       	call   f010410c <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0103743:	89 1c 24             	mov    %ebx,(%esp)
f0103746:	e8 e6 06 00 00       	call   f0103e31 <env_destroy>
	}
}
f010374b:	83 c4 14             	add    $0x14,%esp
f010374e:	5b                   	pop    %ebx
f010374f:	5d                   	pop    %ebp
f0103750:	c3                   	ret    

f0103751 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0103751:	55                   	push   %ebp
f0103752:	89 e5                	mov    %esp,%ebp
f0103754:	57                   	push   %edi
f0103755:	56                   	push   %esi
f0103756:	53                   	push   %ebx
f0103757:	83 ec 1c             	sub    $0x1c,%esp
f010375a:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f010375c:	89 d3                	mov    %edx,%ebx
f010375e:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0103764:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f010376b:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0103771:	eb 6d                	jmp    f01037e0 <region_alloc+0x8f>
		struct PageInfo *p = page_alloc(0);
f0103773:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010377a:	e8 c8 d9 ff ff       	call   f0101147 <page_alloc>
		if (p == NULL)
f010377f:	85 c0                	test   %eax,%eax
f0103781:	75 1c                	jne    f010379f <region_alloc+0x4e>
			panic("Page alloc failed!");
f0103783:	c7 44 24 08 94 76 10 	movl   $0xf0107694,0x8(%esp)
f010378a:	f0 
f010378b:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
f0103792:	00 
f0103793:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f010379a:	e8 a1 c8 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f010379f:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01037a6:	00 
f01037a7:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01037ab:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037af:	8b 47 60             	mov    0x60(%edi),%eax
f01037b2:	89 04 24             	mov    %eax,(%esp)
f01037b5:	e8 11 dd ff ff       	call   f01014cb <page_insert>
f01037ba:	85 c0                	test   %eax,%eax
f01037bc:	74 1c                	je     f01037da <region_alloc+0x89>
			panic("Page table couldn't be allocated!!");
f01037be:	c7 44 24 08 14 77 10 	movl   $0xf0107714,0x8(%esp)
f01037c5:	f0 
f01037c6:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f01037cd:	00 
f01037ce:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f01037d5:	e8 66 c8 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f01037da:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f01037e0:	39 f3                	cmp    %esi,%ebx
f01037e2:	72 8f                	jb     f0103773 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f01037e4:	83 c4 1c             	add    $0x1c,%esp
f01037e7:	5b                   	pop    %ebx
f01037e8:	5e                   	pop    %esi
f01037e9:	5f                   	pop    %edi
f01037ea:	5d                   	pop    %ebp
f01037eb:	c3                   	ret    

f01037ec <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f01037ec:	55                   	push   %ebp
f01037ed:	89 e5                	mov    %esp,%ebp
f01037ef:	56                   	push   %esi
f01037f0:	53                   	push   %ebx
f01037f1:	8b 45 08             	mov    0x8(%ebp),%eax
f01037f4:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f01037f7:	85 c0                	test   %eax,%eax
f01037f9:	75 1a                	jne    f0103815 <envid2env+0x29>
		*env_store = curenv;
f01037fb:	e8 d9 24 00 00       	call   f0105cd9 <cpunum>
f0103800:	6b c0 74             	imul   $0x74,%eax,%eax
f0103803:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103809:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010380c:	89 01                	mov    %eax,(%ecx)
		return 0;
f010380e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103813:	eb 70                	jmp    f0103885 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0103815:	89 c3                	mov    %eax,%ebx
f0103817:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f010381d:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0103820:	03 1d 4c b2 22 f0    	add    0xf022b24c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0103826:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f010382a:	74 05                	je     f0103831 <envid2env+0x45>
f010382c:	39 43 48             	cmp    %eax,0x48(%ebx)
f010382f:	74 10                	je     f0103841 <envid2env+0x55>
		*env_store = 0;
f0103831:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103834:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010383a:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010383f:	eb 44                	jmp    f0103885 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103841:	84 d2                	test   %dl,%dl
f0103843:	74 36                	je     f010387b <envid2env+0x8f>
f0103845:	e8 8f 24 00 00       	call   f0105cd9 <cpunum>
f010384a:	6b c0 74             	imul   $0x74,%eax,%eax
f010384d:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103853:	74 26                	je     f010387b <envid2env+0x8f>
f0103855:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103858:	e8 7c 24 00 00       	call   f0105cd9 <cpunum>
f010385d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103860:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103866:	3b 70 48             	cmp    0x48(%eax),%esi
f0103869:	74 10                	je     f010387b <envid2env+0x8f>
		*env_store = 0;
f010386b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010386e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103874:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103879:	eb 0a                	jmp    f0103885 <envid2env+0x99>
	}

	*env_store = e;
f010387b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010387e:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103880:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103885:	5b                   	pop    %ebx
f0103886:	5e                   	pop    %esi
f0103887:	5d                   	pop    %ebp
f0103888:	c3                   	ret    

f0103889 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103889:	55                   	push   %ebp
f010388a:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f010388c:	b8 20 03 12 f0       	mov    $0xf0120320,%eax
f0103891:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0103894:	b8 23 00 00 00       	mov    $0x23,%eax
f0103899:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f010389b:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f010389d:	b0 10                	mov    $0x10,%al
f010389f:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01038a1:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01038a3:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01038a5:	ea ac 38 10 f0 08 00 	ljmp   $0x8,$0xf01038ac
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01038ac:	b0 00                	mov    $0x0,%al
f01038ae:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01038b1:	5d                   	pop    %ebp
f01038b2:	c3                   	ret    

f01038b3 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01038b3:	8b 0d 50 b2 22 f0    	mov    0xf022b250,%ecx
f01038b9:	a1 4c b2 22 f0       	mov    0xf022b24c,%eax
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f01038be:	ba 00 04 00 00       	mov    $0x400,%edx
f01038c3:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f01038ca:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f01038d1:	85 c9                	test   %ecx,%ecx
f01038d3:	74 05                	je     f01038da <env_init+0x27>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f01038d5:	89 40 c8             	mov    %eax,-0x38(%eax)
f01038d8:	eb 02                	jmp    f01038dc <env_init+0x29>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f01038da:	89 c1                	mov    %eax,%ecx
f01038dc:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f01038df:	83 ea 01             	sub    $0x1,%edx
f01038e2:	75 df                	jne    f01038c3 <env_init+0x10>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01038e4:	55                   	push   %ebp
f01038e5:	89 e5                	mov    %esp,%ebp
f01038e7:	89 0d 50 b2 22 f0    	mov    %ecx,0xf022b250
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f01038ed:	e8 97 ff ff ff       	call   f0103889 <env_init_percpu>
}
f01038f2:	5d                   	pop    %ebp
f01038f3:	c3                   	ret    

f01038f4 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01038f4:	55                   	push   %ebp
f01038f5:	89 e5                	mov    %esp,%ebp
f01038f7:	53                   	push   %ebx
f01038f8:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f01038fb:	8b 1d 50 b2 22 f0    	mov    0xf022b250,%ebx
f0103901:	85 db                	test   %ebx,%ebx
f0103903:	0f 84 8b 01 00 00    	je     f0103a94 <env_alloc+0x1a0>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103909:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0103910:	e8 32 d8 ff ff       	call   f0101147 <page_alloc>
f0103915:	85 c0                	test   %eax,%eax
f0103917:	0f 84 7e 01 00 00    	je     f0103a9b <env_alloc+0x1a7>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f010391d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103922:	2b 05 10 bf 22 f0    	sub    0xf022bf10,%eax
f0103928:	c1 f8 03             	sar    $0x3,%eax
f010392b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010392e:	89 c2                	mov    %eax,%edx
f0103930:	c1 ea 0c             	shr    $0xc,%edx
f0103933:	3b 15 08 bf 22 f0    	cmp    0xf022bf08,%edx
f0103939:	72 20                	jb     f010395b <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010393b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010393f:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0103946:	f0 
f0103947:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f010394e:	00 
f010394f:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0103956:	e8 e5 c6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010395b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103960:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0103963:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0103968:	8b 15 0c bf 22 f0    	mov    0xf022bf0c,%edx
f010396e:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0103971:	8b 53 60             	mov    0x60(%ebx),%edx
f0103974:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103977:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f010397a:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010397f:	75 e7                	jne    f0103968 <env_alloc+0x74>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0103981:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103984:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103989:	77 20                	ja     f01039ab <env_alloc+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010398b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010398f:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0103996:	f0 
f0103997:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f010399e:	00 
f010399f:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f01039a6:	e8 95 c6 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01039ab:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01039b1:	83 ca 05             	or     $0x5,%edx
f01039b4:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01039ba:	8b 43 48             	mov    0x48(%ebx),%eax
f01039bd:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01039c2:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01039c7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01039cc:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01039cf:	89 da                	mov    %ebx,%edx
f01039d1:	2b 15 4c b2 22 f0    	sub    0xf022b24c,%edx
f01039d7:	c1 fa 02             	sar    $0x2,%edx
f01039da:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01039e0:	09 d0                	or     %edx,%eax
f01039e2:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01039e5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01039e8:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01039eb:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01039f2:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01039f9:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0103a00:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0103a07:	00 
f0103a08:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103a0f:	00 
f0103a10:	89 1c 24             	mov    %ebx,(%esp)
f0103a13:	e8 6f 1c 00 00       	call   f0105687 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0103a18:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103a1e:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0103a24:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103a2a:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103a31:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103a37:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0103a3e:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103a42:	8b 43 44             	mov    0x44(%ebx),%eax
f0103a45:	a3 50 b2 22 f0       	mov    %eax,0xf022b250
	*newenv_store = e;
f0103a4a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a4d:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103a4f:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103a52:	e8 82 22 00 00       	call   f0105cd9 <cpunum>
f0103a57:	6b d0 74             	imul   $0x74,%eax,%edx
f0103a5a:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a5f:	83 ba 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%edx)
f0103a66:	74 11                	je     f0103a79 <env_alloc+0x185>
f0103a68:	e8 6c 22 00 00       	call   f0105cd9 <cpunum>
f0103a6d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103a70:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103a76:	8b 40 48             	mov    0x48(%eax),%eax
f0103a79:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103a7d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a81:	c7 04 24 b2 76 10 f0 	movl   $0xf01076b2,(%esp)
f0103a88:	e8 7f 06 00 00       	call   f010410c <cprintf>
	return 0;
f0103a8d:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a92:	eb 0c                	jmp    f0103aa0 <env_alloc+0x1ac>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103a94:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0103a99:	eb 05                	jmp    f0103aa0 <env_alloc+0x1ac>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0103a9b:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103aa0:	83 c4 14             	add    $0x14,%esp
f0103aa3:	5b                   	pop    %ebx
f0103aa4:	5d                   	pop    %ebp
f0103aa5:	c3                   	ret    

f0103aa6 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103aa6:	55                   	push   %ebp
f0103aa7:	89 e5                	mov    %esp,%ebp
f0103aa9:	57                   	push   %edi
f0103aaa:	56                   	push   %esi
f0103aab:	53                   	push   %ebx
f0103aac:	83 ec 3c             	sub    $0x3c,%esp
f0103aaf:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0103ab2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103ab9:	00 
f0103aba:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103abd:	89 04 24             	mov    %eax,(%esp)
f0103ac0:	e8 2f fe ff ff       	call   f01038f4 <env_alloc>
	if (r){
f0103ac5:	85 c0                	test   %eax,%eax
f0103ac7:	74 20                	je     f0103ae9 <env_create+0x43>
	panic("env_alloc: %e", r);
f0103ac9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103acd:	c7 44 24 08 c7 76 10 	movl   $0xf01076c7,0x8(%esp)
f0103ad4:	f0 
f0103ad5:	c7 44 24 04 b1 01 00 	movl   $0x1b1,0x4(%esp)
f0103adc:	00 
f0103add:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103ae4:	e8 57 c5 ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f0103ae9:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103aec:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f0103aef:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103af5:	74 1c                	je     f0103b13 <env_create+0x6d>
	{
		panic ("Not a valid ELF binary image");
f0103af7:	c7 44 24 08 d5 76 10 	movl   $0xf01076d5,0x8(%esp)
f0103afe:	f0 
f0103aff:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
f0103b06:	00 
f0103b07:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103b0e:	e8 2d c5 ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f0103b13:	89 fb                	mov    %edi,%ebx
f0103b15:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f0103b18:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0103b1c:	c1 e6 05             	shl    $0x5,%esi
f0103b1f:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f0103b21:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103b24:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103b27:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103b2c:	77 20                	ja     f0103b4e <env_create+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103b2e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b32:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0103b39:	f0 
f0103b3a:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f0103b41:	00 
f0103b42:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103b49:	e8 f2 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103b4e:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103b53:	0f 22 d8             	mov    %eax,%cr3
f0103b56:	eb 71                	jmp    f0103bc9 <env_create+0x123>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f0103b58:	83 3b 01             	cmpl   $0x1,(%ebx)
f0103b5b:	75 69                	jne    f0103bc6 <env_create+0x120>
		
		if(ph->p_memsz < ph->p_filesz){
f0103b5d:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103b60:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103b63:	73 1c                	jae    f0103b81 <env_create+0xdb>
		panic ("Memory size is smaller than file size!!");
f0103b65:	c7 44 24 08 38 77 10 	movl   $0xf0107738,0x8(%esp)
f0103b6c:	f0 
f0103b6d:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f0103b74:	00 
f0103b75:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103b7c:	e8 bf c4 ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0103b81:	8b 53 08             	mov    0x8(%ebx),%edx
f0103b84:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103b87:	e8 c5 fb ff ff       	call   f0103751 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103b8c:	8b 43 10             	mov    0x10(%ebx),%eax
f0103b8f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103b93:	89 f8                	mov    %edi,%eax
f0103b95:	03 43 04             	add    0x4(%ebx),%eax
f0103b98:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103b9c:	8b 43 08             	mov    0x8(%ebx),%eax
f0103b9f:	89 04 24             	mov    %eax,(%esp)
f0103ba2:	e8 95 1b 00 00       	call   f010573c <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0103ba7:	8b 43 10             	mov    0x10(%ebx),%eax
f0103baa:	8b 53 14             	mov    0x14(%ebx),%edx
f0103bad:	29 c2                	sub    %eax,%edx
f0103baf:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103bb3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0103bba:	00 
f0103bbb:	03 43 08             	add    0x8(%ebx),%eax
f0103bbe:	89 04 24             	mov    %eax,(%esp)
f0103bc1:	e8 c1 1a 00 00       	call   f0105687 <memset>
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0103bc6:	83 c3 20             	add    $0x20,%ebx
f0103bc9:	39 de                	cmp    %ebx,%esi
f0103bcb:	77 8b                	ja     f0103b58 <env_create+0xb2>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0103bcd:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103bd2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103bd7:	77 20                	ja     f0103bf9 <env_create+0x153>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103bd9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103bdd:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0103be4:	f0 
f0103be5:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
f0103bec:	00 
f0103bed:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103bf4:	e8 47 c4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103bf9:	05 00 00 00 10       	add    $0x10000000,%eax
f0103bfe:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0103c01:	8b 47 18             	mov    0x18(%edi),%eax
f0103c04:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103c07:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0103c0a:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103c0f:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103c14:	89 f8                	mov    %edi,%eax
f0103c16:	e8 36 fb ff ff       	call   f0103751 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f0103c1b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103c1e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103c21:	89 50 50             	mov    %edx,0x50(%eax)
}
f0103c24:	83 c4 3c             	add    $0x3c,%esp
f0103c27:	5b                   	pop    %ebx
f0103c28:	5e                   	pop    %esi
f0103c29:	5f                   	pop    %edi
f0103c2a:	5d                   	pop    %ebp
f0103c2b:	c3                   	ret    

f0103c2c <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0103c2c:	55                   	push   %ebp
f0103c2d:	89 e5                	mov    %esp,%ebp
f0103c2f:	57                   	push   %edi
f0103c30:	56                   	push   %esi
f0103c31:	53                   	push   %ebx
f0103c32:	83 ec 2c             	sub    $0x2c,%esp
f0103c35:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0103c38:	e8 9c 20 00 00       	call   f0105cd9 <cpunum>
f0103c3d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c40:	39 b8 28 c0 22 f0    	cmp    %edi,-0xfdd3fd8(%eax)
f0103c46:	75 34                	jne    f0103c7c <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0103c48:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103c4d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103c52:	77 20                	ja     f0103c74 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103c54:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103c58:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0103c5f:	f0 
f0103c60:	c7 44 24 04 c7 01 00 	movl   $0x1c7,0x4(%esp)
f0103c67:	00 
f0103c68:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103c6f:	e8 cc c3 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103c74:	05 00 00 00 10       	add    $0x10000000,%eax
f0103c79:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103c7c:	8b 5f 48             	mov    0x48(%edi),%ebx
f0103c7f:	e8 55 20 00 00       	call   f0105cd9 <cpunum>
f0103c84:	6b d0 74             	imul   $0x74,%eax,%edx
f0103c87:	b8 00 00 00 00       	mov    $0x0,%eax
f0103c8c:	83 ba 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%edx)
f0103c93:	74 11                	je     f0103ca6 <env_free+0x7a>
f0103c95:	e8 3f 20 00 00       	call   f0105cd9 <cpunum>
f0103c9a:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c9d:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103ca3:	8b 40 48             	mov    0x48(%eax),%eax
f0103ca6:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103caa:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cae:	c7 04 24 f2 76 10 f0 	movl   $0xf01076f2,(%esp)
f0103cb5:	e8 52 04 00 00       	call   f010410c <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103cba:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103cc1:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0103cc4:	89 c8                	mov    %ecx,%eax
f0103cc6:	c1 e0 02             	shl    $0x2,%eax
f0103cc9:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103ccc:	8b 47 60             	mov    0x60(%edi),%eax
f0103ccf:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0103cd2:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103cd8:	0f 84 b7 00 00 00    	je     f0103d95 <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103cde:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103ce4:	89 f0                	mov    %esi,%eax
f0103ce6:	c1 e8 0c             	shr    $0xc,%eax
f0103ce9:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0103cec:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f0103cf2:	72 20                	jb     f0103d14 <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103cf4:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103cf8:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0103cff:	f0 
f0103d00:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
f0103d07:	00 
f0103d08:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103d0f:	e8 2c c3 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103d14:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d17:	c1 e0 16             	shl    $0x16,%eax
f0103d1a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103d1d:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0103d22:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103d29:	01 
f0103d2a:	74 17                	je     f0103d43 <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103d2c:	89 d8                	mov    %ebx,%eax
f0103d2e:	c1 e0 0c             	shl    $0xc,%eax
f0103d31:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103d34:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d38:	8b 47 60             	mov    0x60(%edi),%eax
f0103d3b:	89 04 24             	mov    %eax,(%esp)
f0103d3e:	e8 3f d7 ff ff       	call   f0101482 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103d43:	83 c3 01             	add    $0x1,%ebx
f0103d46:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103d4c:	75 d4                	jne    f0103d22 <env_free+0xf6>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103d4e:	8b 47 60             	mov    0x60(%edi),%eax
f0103d51:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103d54:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103d5b:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0103d5e:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f0103d64:	72 1c                	jb     f0103d82 <env_free+0x156>
		panic("pa2page called with invalid pa");
f0103d66:	c7 44 24 08 60 77 10 	movl   $0xf0107760,0x8(%esp)
f0103d6d:	f0 
f0103d6e:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103d75:	00 
f0103d76:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0103d7d:	e8 be c2 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103d82:	a1 10 bf 22 f0       	mov    0xf022bf10,%eax
f0103d87:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103d8a:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f0103d8d:	89 04 24             	mov    %eax,(%esp)
f0103d90:	e8 9e d4 ff ff       	call   f0101233 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103d95:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103d99:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103da0:	0f 85 1b ff ff ff    	jne    f0103cc1 <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103da6:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103da9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103dae:	77 20                	ja     f0103dd0 <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103db0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103db4:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0103dbb:	f0 
f0103dbc:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
f0103dc3:	00 
f0103dc4:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103dcb:	e8 70 c2 ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103dd0:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103dd7:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103ddc:	c1 e8 0c             	shr    $0xc,%eax
f0103ddf:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f0103de5:	72 1c                	jb     f0103e03 <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103de7:	c7 44 24 08 60 77 10 	movl   $0xf0107760,0x8(%esp)
f0103dee:	f0 
f0103def:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103df6:	00 
f0103df7:	c7 04 24 55 73 10 f0 	movl   $0xf0107355,(%esp)
f0103dfe:	e8 3d c2 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103e03:	8b 15 10 bf 22 f0    	mov    0xf022bf10,%edx
f0103e09:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f0103e0c:	89 04 24             	mov    %eax,(%esp)
f0103e0f:	e8 1f d4 ff ff       	call   f0101233 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103e14:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103e1b:	a1 50 b2 22 f0       	mov    0xf022b250,%eax
f0103e20:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103e23:	89 3d 50 b2 22 f0    	mov    %edi,0xf022b250
}
f0103e29:	83 c4 2c             	add    $0x2c,%esp
f0103e2c:	5b                   	pop    %ebx
f0103e2d:	5e                   	pop    %esi
f0103e2e:	5f                   	pop    %edi
f0103e2f:	5d                   	pop    %ebp
f0103e30:	c3                   	ret    

f0103e31 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103e31:	55                   	push   %ebp
f0103e32:	89 e5                	mov    %esp,%ebp
f0103e34:	53                   	push   %ebx
f0103e35:	83 ec 14             	sub    $0x14,%esp
f0103e38:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103e3b:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103e3f:	75 19                	jne    f0103e5a <env_destroy+0x29>
f0103e41:	e8 93 1e 00 00       	call   f0105cd9 <cpunum>
f0103e46:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e49:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103e4f:	74 09                	je     f0103e5a <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103e51:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f0103e58:	eb 2f                	jmp    f0103e89 <env_destroy+0x58>
	}

	env_free(e);
f0103e5a:	89 1c 24             	mov    %ebx,(%esp)
f0103e5d:	e8 ca fd ff ff       	call   f0103c2c <env_free>

	if (curenv == e) {
f0103e62:	e8 72 1e 00 00       	call   f0105cd9 <cpunum>
f0103e67:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e6a:	39 98 28 c0 22 f0    	cmp    %ebx,-0xfdd3fd8(%eax)
f0103e70:	75 17                	jne    f0103e89 <env_destroy+0x58>
		curenv = NULL;
f0103e72:	e8 62 1e 00 00       	call   f0105cd9 <cpunum>
f0103e77:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e7a:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f0103e81:	00 00 00 
		sched_yield();
f0103e84:	e8 69 0a 00 00       	call   f01048f2 <sched_yield>
	}
}
f0103e89:	83 c4 14             	add    $0x14,%esp
f0103e8c:	5b                   	pop    %ebx
f0103e8d:	5d                   	pop    %ebp
f0103e8e:	c3                   	ret    

f0103e8f <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103e8f:	55                   	push   %ebp
f0103e90:	89 e5                	mov    %esp,%ebp
f0103e92:	53                   	push   %ebx
f0103e93:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103e96:	e8 3e 1e 00 00       	call   f0105cd9 <cpunum>
f0103e9b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e9e:	8b 98 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%ebx
f0103ea4:	e8 30 1e 00 00       	call   f0105cd9 <cpunum>
f0103ea9:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f0103eac:	8b 65 08             	mov    0x8(%ebp),%esp
f0103eaf:	61                   	popa   
f0103eb0:	07                   	pop    %es
f0103eb1:	1f                   	pop    %ds
f0103eb2:	83 c4 08             	add    $0x8,%esp
f0103eb5:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103eb6:	c7 44 24 08 08 77 10 	movl   $0xf0107708,0x8(%esp)
f0103ebd:	f0 
f0103ebe:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
f0103ec5:	00 
f0103ec6:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103ecd:	e8 6e c1 ff ff       	call   f0100040 <_panic>

f0103ed2 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103ed2:	55                   	push   %ebp
f0103ed3:	89 e5                	mov    %esp,%ebp
f0103ed5:	53                   	push   %ebx
f0103ed6:	83 ec 14             	sub    $0x14,%esp
f0103ed9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103edc:	e8 f8 1d 00 00       	call   f0105cd9 <cpunum>
f0103ee1:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ee4:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0103eeb:	75 10                	jne    f0103efd <env_run+0x2b>
	curenv = e;
f0103eed:	e8 e7 1d 00 00       	call   f0105cd9 <cpunum>
f0103ef2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ef5:	89 98 28 c0 22 f0    	mov    %ebx,-0xfdd3fd8(%eax)
f0103efb:	eb 29                	jmp    f0103f26 <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103efd:	e8 d7 1d 00 00       	call   f0105cd9 <cpunum>
f0103f02:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f05:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f0b:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103f0f:	75 15                	jne    f0103f26 <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f0103f11:	e8 c3 1d 00 00       	call   f0105cd9 <cpunum>
f0103f16:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f19:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f1f:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f0103f26:	e8 ae 1d 00 00       	call   f0105cd9 <cpunum>
f0103f2b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f2e:	89 98 28 c0 22 f0    	mov    %ebx,-0xfdd3fd8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103f34:	e8 a0 1d 00 00       	call   f0105cd9 <cpunum>
f0103f39:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f3c:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f42:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f0103f49:	e8 8b 1d 00 00       	call   f0105cd9 <cpunum>
f0103f4e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103f51:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0103f57:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f0103f5b:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103f5e:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103f63:	77 20                	ja     f0103f85 <env_run+0xb3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103f65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103f69:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0103f70:	f0 
f0103f71:	c7 44 24 04 46 02 00 	movl   $0x246,0x4(%esp)
f0103f78:	00 
f0103f79:	c7 04 24 a7 76 10 f0 	movl   $0xf01076a7,(%esp)
f0103f80:	e8 bb c0 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103f85:	05 00 00 00 10       	add    $0x10000000,%eax
f0103f8a:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103f8d:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0103f94:	e8 6a 20 00 00       	call   f0106003 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103f99:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f0103f9b:	89 1c 24             	mov    %ebx,(%esp)
f0103f9e:	e8 ec fe ff ff       	call   f0103e8f <env_pop_tf>

f0103fa3 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103fa3:	55                   	push   %ebp
f0103fa4:	89 e5                	mov    %esp,%ebp
f0103fa6:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103faa:	ba 70 00 00 00       	mov    $0x70,%edx
f0103faf:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103fb0:	b2 71                	mov    $0x71,%dl
f0103fb2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103fb3:	0f b6 c0             	movzbl %al,%eax
}
f0103fb6:	5d                   	pop    %ebp
f0103fb7:	c3                   	ret    

f0103fb8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103fb8:	55                   	push   %ebp
f0103fb9:	89 e5                	mov    %esp,%ebp
f0103fbb:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103fbf:	ba 70 00 00 00       	mov    $0x70,%edx
f0103fc4:	ee                   	out    %al,(%dx)
f0103fc5:	b2 71                	mov    $0x71,%dl
f0103fc7:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fca:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103fcb:	5d                   	pop    %ebp
f0103fcc:	c3                   	ret    

f0103fcd <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103fcd:	55                   	push   %ebp
f0103fce:	89 e5                	mov    %esp,%ebp
f0103fd0:	56                   	push   %esi
f0103fd1:	53                   	push   %ebx
f0103fd2:	83 ec 10             	sub    $0x10,%esp
f0103fd5:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103fd8:	66 a3 a8 03 12 f0    	mov    %ax,0xf01203a8
	if (!didinit)
f0103fde:	80 3d 54 b2 22 f0 00 	cmpb   $0x0,0xf022b254
f0103fe5:	74 4e                	je     f0104035 <irq_setmask_8259A+0x68>
f0103fe7:	89 c6                	mov    %eax,%esi
f0103fe9:	ba 21 00 00 00       	mov    $0x21,%edx
f0103fee:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103fef:	66 c1 e8 08          	shr    $0x8,%ax
f0103ff3:	b2 a1                	mov    $0xa1,%dl
f0103ff5:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103ff6:	c7 04 24 7f 77 10 f0 	movl   $0xf010777f,(%esp)
f0103ffd:	e8 0a 01 00 00       	call   f010410c <cprintf>
	for (i = 0; i < 16; i++)
f0104002:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0104007:	0f b7 f6             	movzwl %si,%esi
f010400a:	f7 d6                	not    %esi
f010400c:	0f a3 de             	bt     %ebx,%esi
f010400f:	73 10                	jae    f0104021 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0104011:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104015:	c7 04 24 6a 7c 10 f0 	movl   $0xf0107c6a,(%esp)
f010401c:	e8 eb 00 00 00       	call   f010410c <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0104021:	83 c3 01             	add    $0x1,%ebx
f0104024:	83 fb 10             	cmp    $0x10,%ebx
f0104027:	75 e3                	jne    f010400c <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0104029:	c7 04 24 32 7c 10 f0 	movl   $0xf0107c32,(%esp)
f0104030:	e8 d7 00 00 00       	call   f010410c <cprintf>
}
f0104035:	83 c4 10             	add    $0x10,%esp
f0104038:	5b                   	pop    %ebx
f0104039:	5e                   	pop    %esi
f010403a:	5d                   	pop    %ebp
f010403b:	c3                   	ret    

f010403c <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010403c:	c6 05 54 b2 22 f0 01 	movb   $0x1,0xf022b254
f0104043:	ba 21 00 00 00       	mov    $0x21,%edx
f0104048:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010404d:	ee                   	out    %al,(%dx)
f010404e:	b2 a1                	mov    $0xa1,%dl
f0104050:	ee                   	out    %al,(%dx)
f0104051:	b2 20                	mov    $0x20,%dl
f0104053:	b8 11 00 00 00       	mov    $0x11,%eax
f0104058:	ee                   	out    %al,(%dx)
f0104059:	b2 21                	mov    $0x21,%dl
f010405b:	b8 20 00 00 00       	mov    $0x20,%eax
f0104060:	ee                   	out    %al,(%dx)
f0104061:	b8 04 00 00 00       	mov    $0x4,%eax
f0104066:	ee                   	out    %al,(%dx)
f0104067:	b8 03 00 00 00       	mov    $0x3,%eax
f010406c:	ee                   	out    %al,(%dx)
f010406d:	b2 a0                	mov    $0xa0,%dl
f010406f:	b8 11 00 00 00       	mov    $0x11,%eax
f0104074:	ee                   	out    %al,(%dx)
f0104075:	b2 a1                	mov    $0xa1,%dl
f0104077:	b8 28 00 00 00       	mov    $0x28,%eax
f010407c:	ee                   	out    %al,(%dx)
f010407d:	b8 02 00 00 00       	mov    $0x2,%eax
f0104082:	ee                   	out    %al,(%dx)
f0104083:	b8 01 00 00 00       	mov    $0x1,%eax
f0104088:	ee                   	out    %al,(%dx)
f0104089:	b2 20                	mov    $0x20,%dl
f010408b:	b8 68 00 00 00       	mov    $0x68,%eax
f0104090:	ee                   	out    %al,(%dx)
f0104091:	b8 0a 00 00 00       	mov    $0xa,%eax
f0104096:	ee                   	out    %al,(%dx)
f0104097:	b2 a0                	mov    $0xa0,%dl
f0104099:	b8 68 00 00 00       	mov    $0x68,%eax
f010409e:	ee                   	out    %al,(%dx)
f010409f:	b8 0a 00 00 00       	mov    $0xa,%eax
f01040a4:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01040a5:	0f b7 05 a8 03 12 f0 	movzwl 0xf01203a8,%eax
f01040ac:	66 83 f8 ff          	cmp    $0xffff,%ax
f01040b0:	74 12                	je     f01040c4 <pic_init+0x88>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01040b2:	55                   	push   %ebp
f01040b3:	89 e5                	mov    %esp,%ebp
f01040b5:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01040b8:	0f b7 c0             	movzwl %ax,%eax
f01040bb:	89 04 24             	mov    %eax,(%esp)
f01040be:	e8 0a ff ff ff       	call   f0103fcd <irq_setmask_8259A>
}
f01040c3:	c9                   	leave  
f01040c4:	f3 c3                	repz ret 

f01040c6 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01040c6:	55                   	push   %ebp
f01040c7:	89 e5                	mov    %esp,%ebp
f01040c9:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01040cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01040cf:	89 04 24             	mov    %eax,(%esp)
f01040d2:	e8 b3 c6 ff ff       	call   f010078a <cputchar>
	*cnt++;
}
f01040d7:	c9                   	leave  
f01040d8:	c3                   	ret    

f01040d9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01040d9:	55                   	push   %ebp
f01040da:	89 e5                	mov    %esp,%ebp
f01040dc:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01040df:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01040e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01040ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01040f0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040f4:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01040f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040fb:	c7 04 24 c6 40 10 f0 	movl   $0xf01040c6,(%esp)
f0104102:	e8 c7 0e 00 00       	call   f0104fce <vprintfmt>
	return cnt;
}
f0104107:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010410a:	c9                   	leave  
f010410b:	c3                   	ret    

f010410c <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010410c:	55                   	push   %ebp
f010410d:	89 e5                	mov    %esp,%ebp
f010410f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0104112:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0104115:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104119:	8b 45 08             	mov    0x8(%ebp),%eax
f010411c:	89 04 24             	mov    %eax,(%esp)
f010411f:	e8 b5 ff ff ff       	call   f01040d9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0104124:	c9                   	leave  
f0104125:	c3                   	ret    
f0104126:	66 90                	xchg   %ax,%ax
f0104128:	66 90                	xchg   %ax,%ax
f010412a:	66 90                	xchg   %ax,%ax
f010412c:	66 90                	xchg   %ax,%ax
f010412e:	66 90                	xchg   %ax,%ax

f0104130 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0104130:	55                   	push   %ebp
f0104131:	89 e5                	mov    %esp,%ebp
f0104133:	53                   	push   %ebx
f0104134:	83 ec 04             	sub    $0x4,%esp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f0104137:	e8 9d 1b 00 00       	call   f0105cd9 <cpunum>
f010413c:	89 c3                	mov    %eax,%ebx
f010413e:	e8 96 1b 00 00       	call   f0105cd9 <cpunum>
f0104143:	6b db 74             	imul   $0x74,%ebx,%ebx
f0104146:	c1 e0 0f             	shl    $0xf,%eax
f0104149:	8d 80 00 50 23 f0    	lea    -0xfdcb000(%eax),%eax
f010414f:	89 83 30 c0 22 f0    	mov    %eax,-0xfdd3fd0(%ebx)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0104155:	e8 7f 1b 00 00       	call   f0105cd9 <cpunum>
f010415a:	6b c0 74             	imul   $0x74,%eax,%eax
f010415d:	66 c7 80 34 c0 22 f0 	movw   $0x10,-0xfdd3fcc(%eax)
f0104164:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f0104166:	66 c7 05 68 03 12 f0 	movw   $0x67,0xf0120368
f010416d:	67 00 
f010416f:	b8 80 ba 22 f0       	mov    $0xf022ba80,%eax
f0104174:	66 a3 6a 03 12 f0    	mov    %ax,0xf012036a
f010417a:	89 c2                	mov    %eax,%edx
f010417c:	c1 ea 10             	shr    $0x10,%edx
f010417f:	88 15 6c 03 12 f0    	mov    %dl,0xf012036c
f0104185:	c6 05 6e 03 12 f0 40 	movb   $0x40,0xf012036e
f010418c:	c1 e8 18             	shr    $0x18,%eax
f010418f:	a2 6f 03 12 f0       	mov    %al,0xf012036f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f0104194:	c6 05 6d 03 12 f0 89 	movb   $0x89,0xf012036d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f010419b:	b8 28 00 00 00       	mov    $0x28,%eax
f01041a0:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01041a3:	b8 aa 03 12 f0       	mov    $0xf01203aa,%eax
f01041a8:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f01041ab:	83 c4 04             	add    $0x4,%esp
f01041ae:	5b                   	pop    %ebx
f01041af:	5d                   	pop    %ebp
f01041b0:	c3                   	ret    

f01041b1 <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f01041b1:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f01041b6:	8b 14 85 b0 03 12 f0 	mov    -0xfedfc50(,%eax,4),%edx
f01041bd:	66 89 14 c5 60 b2 22 	mov    %dx,-0xfdd4da0(,%eax,8)
f01041c4:	f0 
f01041c5:	66 c7 04 c5 62 b2 22 	movw   $0x8,-0xfdd4d9e(,%eax,8)
f01041cc:	f0 08 00 
f01041cf:	c6 04 c5 64 b2 22 f0 	movb   $0x0,-0xfdd4d9c(,%eax,8)
f01041d6:	00 
f01041d7:	c6 04 c5 65 b2 22 f0 	movb   $0x8e,-0xfdd4d9b(,%eax,8)
f01041de:	8e 
f01041df:	c1 ea 10             	shr    $0x10,%edx
f01041e2:	66 89 14 c5 66 b2 22 	mov    %dx,-0xfdd4d9a(,%eax,8)
f01041e9:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f01041ea:	83 c0 01             	add    $0x1,%eax
f01041ed:	83 f8 14             	cmp    $0x14,%eax
f01041f0:	75 c4                	jne    f01041b6 <trap_init+0x5>
}


void
trap_init(void)
{
f01041f2:	55                   	push   %ebp
f01041f3:	89 e5                	mov    %esp,%ebp
f01041f5:	83 ec 08             	sub    $0x8,%esp
	for (i=0; i<= T_SIMDERR;i++){
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f01041f8:	a1 bc 03 12 f0       	mov    0xf01203bc,%eax
f01041fd:	66 a3 78 b2 22 f0    	mov    %ax,0xf022b278
f0104203:	66 c7 05 7a b2 22 f0 	movw   $0x8,0xf022b27a
f010420a:	08 00 
f010420c:	c6 05 7c b2 22 f0 00 	movb   $0x0,0xf022b27c
f0104213:	c6 05 7d b2 22 f0 ee 	movb   $0xee,0xf022b27d
f010421a:	c1 e8 10             	shr    $0x10,%eax
f010421d:	66 a3 7e b2 22 f0    	mov    %ax,0xf022b27e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f0104223:	a1 70 04 12 f0       	mov    0xf0120470,%eax
f0104228:	66 a3 e0 b3 22 f0    	mov    %ax,0xf022b3e0
f010422e:	66 c7 05 e2 b3 22 f0 	movw   $0x8,0xf022b3e2
f0104235:	08 00 
f0104237:	c6 05 e4 b3 22 f0 00 	movb   $0x0,0xf022b3e4
f010423e:	c6 05 e5 b3 22 f0 ee 	movb   $0xee,0xf022b3e5
f0104245:	c1 e8 10             	shr    $0x10,%eax
f0104248:	66 a3 e6 b3 22 f0    	mov    %ax,0xf022b3e6

	// Per-CPU setup 
	trap_init_percpu();
f010424e:	e8 dd fe ff ff       	call   f0104130 <trap_init_percpu>
}
f0104253:	c9                   	leave  
f0104254:	c3                   	ret    

f0104255 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f0104255:	55                   	push   %ebp
f0104256:	89 e5                	mov    %esp,%ebp
f0104258:	53                   	push   %ebx
f0104259:	83 ec 14             	sub    $0x14,%esp
f010425c:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f010425f:	8b 03                	mov    (%ebx),%eax
f0104261:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104265:	c7 04 24 93 77 10 f0 	movl   $0xf0107793,(%esp)
f010426c:	e8 9b fe ff ff       	call   f010410c <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f0104271:	8b 43 04             	mov    0x4(%ebx),%eax
f0104274:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104278:	c7 04 24 a2 77 10 f0 	movl   $0xf01077a2,(%esp)
f010427f:	e8 88 fe ff ff       	call   f010410c <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f0104284:	8b 43 08             	mov    0x8(%ebx),%eax
f0104287:	89 44 24 04          	mov    %eax,0x4(%esp)
f010428b:	c7 04 24 b1 77 10 f0 	movl   $0xf01077b1,(%esp)
f0104292:	e8 75 fe ff ff       	call   f010410c <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f0104297:	8b 43 0c             	mov    0xc(%ebx),%eax
f010429a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010429e:	c7 04 24 c0 77 10 f0 	movl   $0xf01077c0,(%esp)
f01042a5:	e8 62 fe ff ff       	call   f010410c <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01042aa:	8b 43 10             	mov    0x10(%ebx),%eax
f01042ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042b1:	c7 04 24 cf 77 10 f0 	movl   $0xf01077cf,(%esp)
f01042b8:	e8 4f fe ff ff       	call   f010410c <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01042bd:	8b 43 14             	mov    0x14(%ebx),%eax
f01042c0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042c4:	c7 04 24 de 77 10 f0 	movl   $0xf01077de,(%esp)
f01042cb:	e8 3c fe ff ff       	call   f010410c <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f01042d0:	8b 43 18             	mov    0x18(%ebx),%eax
f01042d3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042d7:	c7 04 24 ed 77 10 f0 	movl   $0xf01077ed,(%esp)
f01042de:	e8 29 fe ff ff       	call   f010410c <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f01042e3:	8b 43 1c             	mov    0x1c(%ebx),%eax
f01042e6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01042ea:	c7 04 24 fc 77 10 f0 	movl   $0xf01077fc,(%esp)
f01042f1:	e8 16 fe ff ff       	call   f010410c <cprintf>
}
f01042f6:	83 c4 14             	add    $0x14,%esp
f01042f9:	5b                   	pop    %ebx
f01042fa:	5d                   	pop    %ebp
f01042fb:	c3                   	ret    

f01042fc <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f01042fc:	55                   	push   %ebp
f01042fd:	89 e5                	mov    %esp,%ebp
f01042ff:	56                   	push   %esi
f0104300:	53                   	push   %ebx
f0104301:	83 ec 10             	sub    $0x10,%esp
f0104304:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0104307:	e8 cd 19 00 00       	call   f0105cd9 <cpunum>
f010430c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104310:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104314:	c7 04 24 60 78 10 f0 	movl   $0xf0107860,(%esp)
f010431b:	e8 ec fd ff ff       	call   f010410c <cprintf>
	print_regs(&tf->tf_regs);
f0104320:	89 1c 24             	mov    %ebx,(%esp)
f0104323:	e8 2d ff ff ff       	call   f0104255 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0104328:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f010432c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104330:	c7 04 24 7e 78 10 f0 	movl   $0xf010787e,(%esp)
f0104337:	e8 d0 fd ff ff       	call   f010410c <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f010433c:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0104340:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104344:	c7 04 24 91 78 10 f0 	movl   $0xf0107891,(%esp)
f010434b:	e8 bc fd ff ff       	call   f010410c <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104350:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0104353:	83 f8 13             	cmp    $0x13,%eax
f0104356:	77 09                	ja     f0104361 <print_trapframe+0x65>
		return excnames[trapno];
f0104358:	8b 14 85 60 7b 10 f0 	mov    -0xfef84a0(,%eax,4),%edx
f010435f:	eb 1f                	jmp    f0104380 <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f0104361:	83 f8 30             	cmp    $0x30,%eax
f0104364:	74 15                	je     f010437b <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0104366:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f0104369:	83 fa 0f             	cmp    $0xf,%edx
f010436c:	ba 17 78 10 f0       	mov    $0xf0107817,%edx
f0104371:	b9 2a 78 10 f0       	mov    $0xf010782a,%ecx
f0104376:	0f 47 d1             	cmova  %ecx,%edx
f0104379:	eb 05                	jmp    f0104380 <print_trapframe+0x84>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f010437b:	ba 0b 78 10 f0       	mov    $0xf010780b,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0104380:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104384:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104388:	c7 04 24 a4 78 10 f0 	movl   $0xf01078a4,(%esp)
f010438f:	e8 78 fd ff ff       	call   f010410c <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0104394:	3b 1d 60 ba 22 f0    	cmp    0xf022ba60,%ebx
f010439a:	75 19                	jne    f01043b5 <print_trapframe+0xb9>
f010439c:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01043a0:	75 13                	jne    f01043b5 <print_trapframe+0xb9>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01043a2:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01043a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043a9:	c7 04 24 b6 78 10 f0 	movl   $0xf01078b6,(%esp)
f01043b0:	e8 57 fd ff ff       	call   f010410c <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f01043b5:	8b 43 2c             	mov    0x2c(%ebx),%eax
f01043b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043bc:	c7 04 24 c5 78 10 f0 	movl   $0xf01078c5,(%esp)
f01043c3:	e8 44 fd ff ff       	call   f010410c <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f01043c8:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01043cc:	75 51                	jne    f010441f <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f01043ce:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f01043d1:	89 c2                	mov    %eax,%edx
f01043d3:	83 e2 01             	and    $0x1,%edx
f01043d6:	ba 39 78 10 f0       	mov    $0xf0107839,%edx
f01043db:	b9 44 78 10 f0       	mov    $0xf0107844,%ecx
f01043e0:	0f 45 ca             	cmovne %edx,%ecx
f01043e3:	89 c2                	mov    %eax,%edx
f01043e5:	83 e2 02             	and    $0x2,%edx
f01043e8:	ba 50 78 10 f0       	mov    $0xf0107850,%edx
f01043ed:	be 56 78 10 f0       	mov    $0xf0107856,%esi
f01043f2:	0f 44 d6             	cmove  %esi,%edx
f01043f5:	83 e0 04             	and    $0x4,%eax
f01043f8:	b8 5b 78 10 f0       	mov    $0xf010785b,%eax
f01043fd:	be ac 79 10 f0       	mov    $0xf01079ac,%esi
f0104402:	0f 44 c6             	cmove  %esi,%eax
f0104405:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104409:	89 54 24 08          	mov    %edx,0x8(%esp)
f010440d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104411:	c7 04 24 d3 78 10 f0 	movl   $0xf01078d3,(%esp)
f0104418:	e8 ef fc ff ff       	call   f010410c <cprintf>
f010441d:	eb 0c                	jmp    f010442b <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f010441f:	c7 04 24 32 7c 10 f0 	movl   $0xf0107c32,(%esp)
f0104426:	e8 e1 fc ff ff       	call   f010410c <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f010442b:	8b 43 30             	mov    0x30(%ebx),%eax
f010442e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104432:	c7 04 24 e2 78 10 f0 	movl   $0xf01078e2,(%esp)
f0104439:	e8 ce fc ff ff       	call   f010410c <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f010443e:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0104442:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104446:	c7 04 24 f1 78 10 f0 	movl   $0xf01078f1,(%esp)
f010444d:	e8 ba fc ff ff       	call   f010410c <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0104452:	8b 43 38             	mov    0x38(%ebx),%eax
f0104455:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104459:	c7 04 24 04 79 10 f0 	movl   $0xf0107904,(%esp)
f0104460:	e8 a7 fc ff ff       	call   f010410c <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0104465:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0104469:	74 27                	je     f0104492 <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f010446b:	8b 43 3c             	mov    0x3c(%ebx),%eax
f010446e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104472:	c7 04 24 13 79 10 f0 	movl   $0xf0107913,(%esp)
f0104479:	e8 8e fc ff ff       	call   f010410c <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f010447e:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0104482:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104486:	c7 04 24 22 79 10 f0 	movl   $0xf0107922,(%esp)
f010448d:	e8 7a fc ff ff       	call   f010410c <cprintf>
	}
}
f0104492:	83 c4 10             	add    $0x10,%esp
f0104495:	5b                   	pop    %ebx
f0104496:	5e                   	pop    %esi
f0104497:	5d                   	pop    %ebp
f0104498:	c3                   	ret    

f0104499 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0104499:	55                   	push   %ebp
f010449a:	89 e5                	mov    %esp,%ebp
f010449c:	57                   	push   %edi
f010449d:	56                   	push   %esi
f010449e:	53                   	push   %ebx
f010449f:	83 ec 1c             	sub    $0x1c,%esp
f01044a2:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01044a5:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f01044a8:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f01044ac:	75 20                	jne    f01044ce <page_fault_handler+0x35>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f01044ae:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01044b2:	c7 44 24 08 f8 7a 10 	movl   $0xf0107af8,0x8(%esp)
f01044b9:	f0 
f01044ba:	c7 44 24 04 37 01 00 	movl   $0x137,0x4(%esp)
f01044c1:	00 
f01044c2:	c7 04 24 35 79 10 f0 	movl   $0xf0107935,(%esp)
f01044c9:	e8 72 bb ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01044ce:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f01044d1:	e8 03 18 00 00       	call   f0105cd9 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01044d6:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01044da:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f01044de:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f01044e1:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01044e7:	8b 40 48             	mov    0x48(%eax),%eax
f01044ea:	89 44 24 04          	mov    %eax,0x4(%esp)
f01044ee:	c7 04 24 20 7b 10 f0 	movl   $0xf0107b20,(%esp)
f01044f5:	e8 12 fc ff ff       	call   f010410c <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f01044fa:	89 1c 24             	mov    %ebx,(%esp)
f01044fd:	e8 fa fd ff ff       	call   f01042fc <print_trapframe>
	env_destroy(curenv);
f0104502:	e8 d2 17 00 00       	call   f0105cd9 <cpunum>
f0104507:	6b c0 74             	imul   $0x74,%eax,%eax
f010450a:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104510:	89 04 24             	mov    %eax,(%esp)
f0104513:	e8 19 f9 ff ff       	call   f0103e31 <env_destroy>
}
f0104518:	83 c4 1c             	add    $0x1c,%esp
f010451b:	5b                   	pop    %ebx
f010451c:	5e                   	pop    %esi
f010451d:	5f                   	pop    %edi
f010451e:	5d                   	pop    %ebp
f010451f:	c3                   	ret    

f0104520 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0104520:	55                   	push   %ebp
f0104521:	89 e5                	mov    %esp,%ebp
f0104523:	57                   	push   %edi
f0104524:	56                   	push   %esi
f0104525:	83 ec 20             	sub    $0x20,%esp
f0104528:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f010452b:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f010452c:	83 3d 00 bf 22 f0 00 	cmpl   $0x0,0xf022bf00
f0104533:	74 01                	je     f0104536 <trap+0x16>
		asm volatile("hlt");
f0104535:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0104536:	e8 9e 17 00 00       	call   f0105cd9 <cpunum>
f010453b:	6b d0 74             	imul   $0x74,%eax,%edx
f010453e:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104544:	b8 01 00 00 00       	mov    $0x1,%eax
f0104549:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010454d:	83 f8 02             	cmp    $0x2,%eax
f0104550:	75 0c                	jne    f010455e <trap+0x3e>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0104552:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f0104559:	e8 f9 19 00 00       	call   f0105f57 <spin_lock>

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f010455e:	9c                   	pushf  
f010455f:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0104560:	f6 c4 02             	test   $0x2,%ah
f0104563:	74 24                	je     f0104589 <trap+0x69>
f0104565:	c7 44 24 0c 41 79 10 	movl   $0xf0107941,0xc(%esp)
f010456c:	f0 
f010456d:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f0104574:	f0 
f0104575:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
f010457c:	00 
f010457d:	c7 04 24 35 79 10 f0 	movl   $0xf0107935,(%esp)
f0104584:	e8 b7 ba ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0104589:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f010458d:	83 e0 03             	and    $0x3,%eax
f0104590:	66 83 f8 03          	cmp    $0x3,%ax
f0104594:	0f 85 a7 00 00 00    	jne    f0104641 <trap+0x121>
f010459a:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f01045a1:	e8 b1 19 00 00       	call   f0105f57 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel();
		assert(curenv);
f01045a6:	e8 2e 17 00 00       	call   f0105cd9 <cpunum>
f01045ab:	6b c0 74             	imul   $0x74,%eax,%eax
f01045ae:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f01045b5:	75 24                	jne    f01045db <trap+0xbb>
f01045b7:	c7 44 24 0c 5a 79 10 	movl   $0xf010795a,0xc(%esp)
f01045be:	f0 
f01045bf:	c7 44 24 08 7b 73 10 	movl   $0xf010737b,0x8(%esp)
f01045c6:	f0 
f01045c7:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
f01045ce:	00 
f01045cf:	c7 04 24 35 79 10 f0 	movl   $0xf0107935,(%esp)
f01045d6:	e8 65 ba ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f01045db:	e8 f9 16 00 00       	call   f0105cd9 <cpunum>
f01045e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01045e3:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01045e9:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f01045ed:	75 2d                	jne    f010461c <trap+0xfc>
			env_free(curenv);
f01045ef:	e8 e5 16 00 00       	call   f0105cd9 <cpunum>
f01045f4:	6b c0 74             	imul   $0x74,%eax,%eax
f01045f7:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01045fd:	89 04 24             	mov    %eax,(%esp)
f0104600:	e8 27 f6 ff ff       	call   f0103c2c <env_free>
			curenv = NULL;
f0104605:	e8 cf 16 00 00       	call   f0105cd9 <cpunum>
f010460a:	6b c0 74             	imul   $0x74,%eax,%eax
f010460d:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f0104614:	00 00 00 
			sched_yield();
f0104617:	e8 d6 02 00 00       	call   f01048f2 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f010461c:	e8 b8 16 00 00       	call   f0105cd9 <cpunum>
f0104621:	6b c0 74             	imul   $0x74,%eax,%eax
f0104624:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010462a:	b9 11 00 00 00       	mov    $0x11,%ecx
f010462f:	89 c7                	mov    %eax,%edi
f0104631:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0104633:	e8 a1 16 00 00       	call   f0105cd9 <cpunum>
f0104638:	6b c0 74             	imul   $0x74,%eax,%eax
f010463b:	8b b0 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0104641:	89 35 60 ba 22 f0    	mov    %esi,0xf022ba60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0104647:	8b 46 28             	mov    0x28(%esi),%eax
f010464a:	83 f8 0e             	cmp    $0xe,%eax
f010464d:	74 20                	je     f010466f <trap+0x14f>
f010464f:	83 f8 30             	cmp    $0x30,%eax
f0104652:	74 25                	je     f0104679 <trap+0x159>
f0104654:	83 f8 03             	cmp    $0x3,%eax
f0104657:	75 52                	jne    f01046ab <trap+0x18b>
		case T_BRKPT:
			monitor(tf);
f0104659:	89 34 24             	mov    %esi,(%esp)
f010465c:	e8 24 c3 ff ff       	call   f0100985 <monitor>
			cprintf("return from breakpoint....\n");
f0104661:	c7 04 24 61 79 10 f0 	movl   $0xf0107961,(%esp)
f0104668:	e8 9f fa ff ff       	call   f010410c <cprintf>
f010466d:	eb 3c                	jmp    f01046ab <trap+0x18b>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f010466f:	89 34 24             	mov    %esi,(%esp)
f0104672:	e8 22 fe ff ff       	call   f0104499 <page_fault_handler>
f0104677:	eb 32                	jmp    f01046ab <trap+0x18b>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0104679:	8b 46 04             	mov    0x4(%esi),%eax
f010467c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0104680:	8b 06                	mov    (%esi),%eax
f0104682:	89 44 24 10          	mov    %eax,0x10(%esp)
f0104686:	8b 46 10             	mov    0x10(%esi),%eax
f0104689:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010468d:	8b 46 18             	mov    0x18(%esi),%eax
f0104690:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104694:	8b 46 14             	mov    0x14(%esi),%eax
f0104697:	89 44 24 04          	mov    %eax,0x4(%esp)
f010469b:	8b 46 1c             	mov    0x1c(%esi),%eax
f010469e:	89 04 24             	mov    %eax,(%esp)
f01046a1:	e8 5a 02 00 00       	call   f0104900 <syscall>
f01046a6:	89 46 1c             	mov    %eax,0x1c(%esi)
f01046a9:	eb 5d                	jmp    f0104708 <trap+0x1e8>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01046ab:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f01046af:	75 16                	jne    f01046c7 <trap+0x1a7>
		cprintf("Spurious interrupt on irq 7\n");
f01046b1:	c7 04 24 7d 79 10 f0 	movl   $0xf010797d,(%esp)
f01046b8:	e8 4f fa ff ff       	call   f010410c <cprintf>
		print_trapframe(tf);
f01046bd:	89 34 24             	mov    %esi,(%esp)
f01046c0:	e8 37 fc ff ff       	call   f01042fc <print_trapframe>
f01046c5:	eb 41                	jmp    f0104708 <trap+0x1e8>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f01046c7:	89 34 24             	mov    %esi,(%esp)
f01046ca:	e8 2d fc ff ff       	call   f01042fc <print_trapframe>
	if (tf->tf_cs == GD_KT){
f01046cf:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f01046d4:	75 1c                	jne    f01046f2 <trap+0x1d2>
		panic("unhandled trap in kernel");
f01046d6:	c7 44 24 08 9a 79 10 	movl   $0xf010799a,0x8(%esp)
f01046dd:	f0 
f01046de:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
f01046e5:	00 
f01046e6:	c7 04 24 35 79 10 f0 	movl   $0xf0107935,(%esp)
f01046ed:	e8 4e b9 ff ff       	call   f0100040 <_panic>
	}
	else {
		env_destroy(curenv);
f01046f2:	e8 e2 15 00 00       	call   f0105cd9 <cpunum>
f01046f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01046fa:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104700:	89 04 24             	mov    %eax,(%esp)
f0104703:	e8 29 f7 ff ff       	call   f0103e31 <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0104708:	e8 cc 15 00 00       	call   f0105cd9 <cpunum>
f010470d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104710:	83 b8 28 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fd8(%eax)
f0104717:	74 2a                	je     f0104743 <trap+0x223>
f0104719:	e8 bb 15 00 00       	call   f0105cd9 <cpunum>
f010471e:	6b c0 74             	imul   $0x74,%eax,%eax
f0104721:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104727:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010472b:	75 16                	jne    f0104743 <trap+0x223>
		env_run(curenv);
f010472d:	e8 a7 15 00 00       	call   f0105cd9 <cpunum>
f0104732:	6b c0 74             	imul   $0x74,%eax,%eax
f0104735:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010473b:	89 04 24             	mov    %eax,(%esp)
f010473e:	e8 8f f7 ff ff       	call   f0103ed2 <env_run>
	else
		sched_yield();
f0104743:	e8 aa 01 00 00       	call   f01048f2 <sched_yield>

f0104748 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0104748:	6a 00                	push   $0x0
f010474a:	6a 00                	push   $0x0
f010474c:	e9 ba 00 00 00       	jmp    f010480b <_alltraps>
f0104751:	90                   	nop

f0104752 <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0104752:	6a 00                	push   $0x0
f0104754:	6a 01                	push   $0x1
f0104756:	e9 b0 00 00 00       	jmp    f010480b <_alltraps>
f010475b:	90                   	nop

f010475c <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f010475c:	6a 00                	push   $0x0
f010475e:	6a 02                	push   $0x2
f0104760:	e9 a6 00 00 00       	jmp    f010480b <_alltraps>
f0104765:	90                   	nop

f0104766 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0104766:	6a 00                	push   $0x0
f0104768:	6a 03                	push   $0x3
f010476a:	e9 9c 00 00 00       	jmp    f010480b <_alltraps>
f010476f:	90                   	nop

f0104770 <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0104770:	6a 00                	push   $0x0
f0104772:	6a 04                	push   $0x4
f0104774:	e9 92 00 00 00       	jmp    f010480b <_alltraps>
f0104779:	90                   	nop

f010477a <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f010477a:	6a 00                	push   $0x0
f010477c:	6a 05                	push   $0x5
f010477e:	e9 88 00 00 00       	jmp    f010480b <_alltraps>
f0104783:	90                   	nop

f0104784 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0104784:	6a 00                	push   $0x0
f0104786:	6a 06                	push   $0x6
f0104788:	e9 7e 00 00 00       	jmp    f010480b <_alltraps>
f010478d:	90                   	nop

f010478e <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f010478e:	6a 00                	push   $0x0
f0104790:	6a 07                	push   $0x7
f0104792:	e9 74 00 00 00       	jmp    f010480b <_alltraps>
f0104797:	90                   	nop

f0104798 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0104798:	6a 08                	push   $0x8
f010479a:	e9 6c 00 00 00       	jmp    f010480b <_alltraps>
f010479f:	90                   	nop

f01047a0 <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f01047a0:	6a 00                	push   $0x0
f01047a2:	6a 09                	push   $0x9
f01047a4:	e9 62 00 00 00       	jmp    f010480b <_alltraps>
f01047a9:	90                   	nop

f01047aa <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f01047aa:	6a 0a                	push   $0xa
f01047ac:	e9 5a 00 00 00       	jmp    f010480b <_alltraps>
f01047b1:	90                   	nop

f01047b2 <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f01047b2:	6a 0b                	push   $0xb
f01047b4:	e9 52 00 00 00       	jmp    f010480b <_alltraps>
f01047b9:	90                   	nop

f01047ba <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f01047ba:	6a 0c                	push   $0xc
f01047bc:	e9 4a 00 00 00       	jmp    f010480b <_alltraps>
f01047c1:	90                   	nop

f01047c2 <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f01047c2:	6a 0d                	push   $0xd
f01047c4:	e9 42 00 00 00       	jmp    f010480b <_alltraps>
f01047c9:	90                   	nop

f01047ca <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f01047ca:	6a 0e                	push   $0xe
f01047cc:	e9 3a 00 00 00       	jmp    f010480b <_alltraps>
f01047d1:	90                   	nop

f01047d2 <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f01047d2:	6a 00                	push   $0x0
f01047d4:	6a 0f                	push   $0xf
f01047d6:	e9 30 00 00 00       	jmp    f010480b <_alltraps>
f01047db:	90                   	nop

f01047dc <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f01047dc:	6a 00                	push   $0x0
f01047de:	6a 10                	push   $0x10
f01047e0:	e9 26 00 00 00       	jmp    f010480b <_alltraps>
f01047e5:	90                   	nop

f01047e6 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f01047e6:	6a 11                	push   $0x11
f01047e8:	e9 1e 00 00 00       	jmp    f010480b <_alltraps>
f01047ed:	90                   	nop

f01047ee <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f01047ee:	6a 00                	push   $0x0
f01047f0:	6a 12                	push   $0x12
f01047f2:	e9 14 00 00 00       	jmp    f010480b <_alltraps>
f01047f7:	90                   	nop

f01047f8 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f01047f8:	6a 00                	push   $0x0
f01047fa:	6a 13                	push   $0x13
f01047fc:	e9 0a 00 00 00       	jmp    f010480b <_alltraps>
f0104801:	90                   	nop

f0104802 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f0104802:	6a 00                	push   $0x0
f0104804:	6a 30                	push   $0x30
f0104806:	e9 00 00 00 00       	jmp    f010480b <_alltraps>

f010480b <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f010480b:	1e                   	push   %ds
	push %es
f010480c:	06                   	push   %es
	pushal
f010480d:	60                   	pusha  

	
	movw $GD_KD, %ax
f010480e:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0104812:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0104814:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f0104816:	54                   	push   %esp
	call trap
f0104817:	e8 04 fd ff ff       	call   f0104520 <trap>

f010481c <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f010481c:	55                   	push   %ebp
f010481d:	89 e5                	mov    %esp,%ebp
f010481f:	83 ec 18             	sub    $0x18,%esp
f0104822:	8b 15 4c b2 22 f0    	mov    0xf022b24c,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104828:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f010482d:	8b 4a 54             	mov    0x54(%edx),%ecx
f0104830:	83 e9 01             	sub    $0x1,%ecx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0104833:	83 f9 02             	cmp    $0x2,%ecx
f0104836:	76 0f                	jbe    f0104847 <sched_halt+0x2b>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0104838:	83 c0 01             	add    $0x1,%eax
f010483b:	83 c2 7c             	add    $0x7c,%edx
f010483e:	3d 00 04 00 00       	cmp    $0x400,%eax
f0104843:	75 e8                	jne    f010482d <sched_halt+0x11>
f0104845:	eb 07                	jmp    f010484e <sched_halt+0x32>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0104847:	3d 00 04 00 00       	cmp    $0x400,%eax
f010484c:	75 1a                	jne    f0104868 <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f010484e:	c7 04 24 b0 7b 10 f0 	movl   $0xf0107bb0,(%esp)
f0104855:	e8 b2 f8 ff ff       	call   f010410c <cprintf>
		while (1)
			monitor(NULL);
f010485a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0104861:	e8 1f c1 ff ff       	call   f0100985 <monitor>
f0104866:	eb f2                	jmp    f010485a <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104868:	e8 6c 14 00 00       	call   f0105cd9 <cpunum>
f010486d:	6b c0 74             	imul   $0x74,%eax,%eax
f0104870:	c7 80 28 c0 22 f0 00 	movl   $0x0,-0xfdd3fd8(%eax)
f0104877:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f010487a:	a1 0c bf 22 f0       	mov    0xf022bf0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010487f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104884:	77 20                	ja     f01048a6 <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104886:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010488a:	c7 44 24 08 08 64 10 	movl   $0xf0106408,0x8(%esp)
f0104891:	f0 
f0104892:	c7 44 24 04 3d 00 00 	movl   $0x3d,0x4(%esp)
f0104899:	00 
f010489a:	c7 04 24 d9 7b 10 f0 	movl   $0xf0107bd9,(%esp)
f01048a1:	e8 9a b7 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01048a6:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01048ab:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f01048ae:	e8 26 14 00 00       	call   f0105cd9 <cpunum>
f01048b3:	6b d0 74             	imul   $0x74,%eax,%edx
f01048b6:	81 c2 20 c0 22 f0    	add    $0xf022c020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01048bc:	b8 02 00 00 00       	mov    $0x2,%eax
f01048c1:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01048c5:	c7 04 24 80 04 12 f0 	movl   $0xf0120480,(%esp)
f01048cc:	e8 32 17 00 00       	call   f0106003 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01048d1:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f01048d3:	e8 01 14 00 00       	call   f0105cd9 <cpunum>
f01048d8:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f01048db:	8b 80 30 c0 22 f0    	mov    -0xfdd3fd0(%eax),%eax
f01048e1:	bd 00 00 00 00       	mov    $0x0,%ebp
f01048e6:	89 c4                	mov    %eax,%esp
f01048e8:	6a 00                	push   $0x0
f01048ea:	6a 00                	push   $0x0
f01048ec:	fb                   	sti    
f01048ed:	f4                   	hlt    
f01048ee:	eb fd                	jmp    f01048ed <sched_halt+0xd1>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f01048f0:	c9                   	leave  
f01048f1:	c3                   	ret    

f01048f2 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01048f2:	55                   	push   %ebp
f01048f3:	89 e5                	mov    %esp,%ebp
f01048f5:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f01048f8:	e8 1f ff ff ff       	call   f010481c <sched_halt>
}
f01048fd:	c9                   	leave  
f01048fe:	c3                   	ret    
f01048ff:	90                   	nop

f0104900 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104900:	55                   	push   %ebp
f0104901:	89 e5                	mov    %esp,%ebp
f0104903:	53                   	push   %ebx
f0104904:	83 ec 24             	sub    $0x24,%esp
f0104907:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f010490a:	83 f8 01             	cmp    $0x1,%eax
f010490d:	74 66                	je     f0104975 <syscall+0x75>
f010490f:	83 f8 01             	cmp    $0x1,%eax
f0104912:	72 11                	jb     f0104925 <syscall+0x25>
f0104914:	83 f8 02             	cmp    $0x2,%eax
f0104917:	74 66                	je     f010497f <syscall+0x7f>
f0104919:	83 f8 03             	cmp    $0x3,%eax
f010491c:	74 78                	je     f0104996 <syscall+0x96>
f010491e:	66 90                	xchg   %ax,%ax
f0104920:	e9 03 01 00 00       	jmp    f0104a28 <syscall+0x128>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f0104925:	e8 af 13 00 00       	call   f0105cd9 <cpunum>
f010492a:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104931:	00 
f0104932:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0104935:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104939:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010493c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104940:	6b c0 74             	imul   $0x74,%eax,%eax
f0104943:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104949:	89 04 24             	mov    %eax,(%esp)
f010494c:	e8 a8 ed ff ff       	call   f01036f9 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104951:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104954:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104958:	8b 45 10             	mov    0x10(%ebp),%eax
f010495b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010495f:	c7 04 24 e6 7b 10 f0 	movl   $0xf0107be6,(%esp)
f0104966:	e8 a1 f7 ff ff       	call   f010410c <cprintf>

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f010496b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104970:	e9 cf 00 00 00       	jmp    f0104a44 <syscall+0x144>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0104975:	e8 bb bc ff ff       	call   f0100635 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f010497a:	e9 c5 00 00 00       	jmp    f0104a44 <syscall+0x144>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f010497f:	90                   	nop
f0104980:	e8 54 13 00 00       	call   f0105cd9 <cpunum>
f0104985:	6b c0 74             	imul   $0x74,%eax,%eax
f0104988:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f010498e:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0104991:	e9 ae 00 00 00       	jmp    f0104a44 <syscall+0x144>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0104996:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010499d:	00 
f010499e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01049a1:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049a5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01049a8:	89 04 24             	mov    %eax,(%esp)
f01049ab:	e8 3c ee ff ff       	call   f01037ec <envid2env>
		return r;
f01049b0:	89 c2                	mov    %eax,%edx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01049b2:	85 c0                	test   %eax,%eax
f01049b4:	78 6e                	js     f0104a24 <syscall+0x124>
		return r;
	if (e == curenv)
f01049b6:	e8 1e 13 00 00       	call   f0105cd9 <cpunum>
f01049bb:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01049be:	6b c0 74             	imul   $0x74,%eax,%eax
f01049c1:	39 90 28 c0 22 f0    	cmp    %edx,-0xfdd3fd8(%eax)
f01049c7:	75 23                	jne    f01049ec <syscall+0xec>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f01049c9:	e8 0b 13 00 00       	call   f0105cd9 <cpunum>
f01049ce:	6b c0 74             	imul   $0x74,%eax,%eax
f01049d1:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f01049d7:	8b 40 48             	mov    0x48(%eax),%eax
f01049da:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049de:	c7 04 24 eb 7b 10 f0 	movl   $0xf0107beb,(%esp)
f01049e5:	e8 22 f7 ff ff       	call   f010410c <cprintf>
f01049ea:	eb 28                	jmp    f0104a14 <syscall+0x114>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f01049ec:	8b 5a 48             	mov    0x48(%edx),%ebx
f01049ef:	e8 e5 12 00 00       	call   f0105cd9 <cpunum>
f01049f4:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01049f8:	6b c0 74             	imul   $0x74,%eax,%eax
f01049fb:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104a01:	8b 40 48             	mov    0x48(%eax),%eax
f0104a04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104a08:	c7 04 24 06 7c 10 f0 	movl   $0xf0107c06,(%esp)
f0104a0f:	e8 f8 f6 ff ff       	call   f010410c <cprintf>
	env_destroy(e);
f0104a14:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104a17:	89 04 24             	mov    %eax,(%esp)
f0104a1a:	e8 12 f4 ff ff       	call   f0103e31 <env_destroy>
	return 0;
f0104a1f:	ba 00 00 00 00       	mov    $0x0,%edx
		
	case SYS_getenvid:
		return sys_getenvid();
		
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f0104a24:	89 d0                	mov    %edx,%eax
f0104a26:	eb 1c                	jmp    f0104a44 <syscall+0x144>
		
	default:
		panic("Invalid System Call \n");
f0104a28:	c7 44 24 08 1e 7c 10 	movl   $0xf0107c1e,0x8(%esp)
f0104a2f:	f0 
f0104a30:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
f0104a37:	00 
f0104a38:	c7 04 24 34 7c 10 f0 	movl   $0xf0107c34,(%esp)
f0104a3f:	e8 fc b5 ff ff       	call   f0100040 <_panic>
		return -E_INVAL;
	}
}
f0104a44:	83 c4 24             	add    $0x24,%esp
f0104a47:	5b                   	pop    %ebx
f0104a48:	5d                   	pop    %ebp
f0104a49:	c3                   	ret    

f0104a4a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104a4a:	55                   	push   %ebp
f0104a4b:	89 e5                	mov    %esp,%ebp
f0104a4d:	57                   	push   %edi
f0104a4e:	56                   	push   %esi
f0104a4f:	53                   	push   %ebx
f0104a50:	83 ec 14             	sub    $0x14,%esp
f0104a53:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104a56:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104a59:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104a5c:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104a5f:	8b 1a                	mov    (%edx),%ebx
f0104a61:	8b 01                	mov    (%ecx),%eax
f0104a63:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104a66:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104a6d:	e9 88 00 00 00       	jmp    f0104afa <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0104a72:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0104a75:	01 d8                	add    %ebx,%eax
f0104a77:	89 c7                	mov    %eax,%edi
f0104a79:	c1 ef 1f             	shr    $0x1f,%edi
f0104a7c:	01 c7                	add    %eax,%edi
f0104a7e:	d1 ff                	sar    %edi
f0104a80:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0104a83:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104a86:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104a89:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104a8b:	eb 03                	jmp    f0104a90 <stab_binsearch+0x46>
			m--;
f0104a8d:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104a90:	39 c3                	cmp    %eax,%ebx
f0104a92:	7f 1f                	jg     f0104ab3 <stab_binsearch+0x69>
f0104a94:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104a98:	83 ea 0c             	sub    $0xc,%edx
f0104a9b:	39 f1                	cmp    %esi,%ecx
f0104a9d:	75 ee                	jne    f0104a8d <stab_binsearch+0x43>
f0104a9f:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0104aa2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104aa5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104aa8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104aac:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104aaf:	76 18                	jbe    f0104ac9 <stab_binsearch+0x7f>
f0104ab1:	eb 05                	jmp    f0104ab8 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0104ab3:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0104ab6:	eb 42                	jmp    f0104afa <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104ab8:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104abb:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104abd:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104ac0:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104ac7:	eb 31                	jmp    f0104afa <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0104ac9:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104acc:	73 17                	jae    f0104ae5 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0104ace:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104ad1:	83 e8 01             	sub    $0x1,%eax
f0104ad4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104ad7:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104ada:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104adc:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104ae3:	eb 15                	jmp    f0104afa <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104ae5:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ae8:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0104aeb:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0104aed:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104af1:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104af3:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0104afa:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0104afd:	0f 8e 6f ff ff ff    	jle    f0104a72 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104b03:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104b07:	75 0f                	jne    f0104b18 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0104b09:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104b0c:	8b 00                	mov    (%eax),%eax
f0104b0e:	83 e8 01             	sub    $0x1,%eax
f0104b11:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0104b14:	89 07                	mov    %eax,(%edi)
f0104b16:	eb 2c                	jmp    f0104b44 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b18:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104b1b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0104b1d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b20:	8b 0f                	mov    (%edi),%ecx
f0104b22:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104b25:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0104b28:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b2b:	eb 03                	jmp    f0104b30 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104b2d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104b30:	39 c8                	cmp    %ecx,%eax
f0104b32:	7e 0b                	jle    f0104b3f <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104b34:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104b38:	83 ea 0c             	sub    $0xc,%edx
f0104b3b:	39 f3                	cmp    %esi,%ebx
f0104b3d:	75 ee                	jne    f0104b2d <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104b3f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b42:	89 07                	mov    %eax,(%edi)
	}
}
f0104b44:	83 c4 14             	add    $0x14,%esp
f0104b47:	5b                   	pop    %ebx
f0104b48:	5e                   	pop    %esi
f0104b49:	5f                   	pop    %edi
f0104b4a:	5d                   	pop    %ebp
f0104b4b:	c3                   	ret    

f0104b4c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104b4c:	55                   	push   %ebp
f0104b4d:	89 e5                	mov    %esp,%ebp
f0104b4f:	57                   	push   %edi
f0104b50:	56                   	push   %esi
f0104b51:	53                   	push   %ebx
f0104b52:	83 ec 4c             	sub    $0x4c,%esp
f0104b55:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0104b58:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104b5b:	c7 07 43 7c 10 f0    	movl   $0xf0107c43,(%edi)
	info->eip_line = 0;
f0104b61:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0104b68:	c7 47 08 43 7c 10 f0 	movl   $0xf0107c43,0x8(%edi)
	info->eip_fn_namelen = 9;
f0104b6f:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0104b76:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0104b79:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104b80:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0104b86:	0f 87 cf 00 00 00    	ja     f0104c5b <debuginfo_eip+0x10f>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f0104b8c:	e8 48 11 00 00       	call   f0105cd9 <cpunum>
f0104b91:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104b98:	00 
f0104b99:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0104ba0:	00 
f0104ba1:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0104ba8:	00 
f0104ba9:	6b c0 74             	imul   $0x74,%eax,%eax
f0104bac:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104bb2:	89 04 24             	mov    %eax,(%esp)
f0104bb5:	e8 3a ea ff ff       	call   f01035f4 <user_mem_check>
f0104bba:	85 c0                	test   %eax,%eax
f0104bbc:	0f 88 5f 02 00 00    	js     f0104e21 <debuginfo_eip+0x2d5>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f0104bc2:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0104bc7:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0104bcd:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104bd3:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104bd6:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0104bdc:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f0104bdf:	89 f2                	mov    %esi,%edx
f0104be1:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0104be4:	29 c2                	sub    %eax,%edx
f0104be6:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104be9:	e8 eb 10 00 00       	call   f0105cd9 <cpunum>
f0104bee:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104bf5:	00 
f0104bf6:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104bf9:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104bfd:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104c00:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104c04:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c07:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104c0d:	89 04 24             	mov    %eax,(%esp)
f0104c10:	e8 df e9 ff ff       	call   f01035f4 <user_mem_check>
f0104c15:	85 c0                	test   %eax,%eax
f0104c17:	0f 88 0b 02 00 00    	js     f0104e28 <debuginfo_eip+0x2dc>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f0104c1d:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104c20:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104c23:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104c26:	e8 ae 10 00 00       	call   f0105cd9 <cpunum>
f0104c2b:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0104c32:	00 
f0104c33:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104c36:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104c3a:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0104c3d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104c41:	6b c0 74             	imul   $0x74,%eax,%eax
f0104c44:	8b 80 28 c0 22 f0    	mov    -0xfdd3fd8(%eax),%eax
f0104c4a:	89 04 24             	mov    %eax,(%esp)
f0104c4d:	e8 a2 e9 ff ff       	call   f01035f4 <user_mem_check>
f0104c52:	85 c0                	test   %eax,%eax
f0104c54:	79 1f                	jns    f0104c75 <debuginfo_eip+0x129>
f0104c56:	e9 d4 01 00 00       	jmp    f0104e2f <debuginfo_eip+0x2e3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104c5b:	c7 45 bc dc 56 11 f0 	movl   $0xf01156dc,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104c62:	c7 45 c0 5d 20 11 f0 	movl   $0xf011205d,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104c69:	be 5c 20 11 f0       	mov    $0xf011205c,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104c6e:	c7 45 c4 38 81 10 f0 	movl   $0xf0108138,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104c75:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104c78:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104c7b:	0f 83 b5 01 00 00    	jae    f0104e36 <debuginfo_eip+0x2ea>
f0104c81:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104c85:	0f 85 b2 01 00 00    	jne    f0104e3d <debuginfo_eip+0x2f1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104c8b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0104c92:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f0104c95:	c1 fe 02             	sar    $0x2,%esi
f0104c98:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0104c9e:	83 e8 01             	sub    $0x1,%eax
f0104ca1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104ca4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104ca8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0104caf:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0104cb2:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104cb5:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104cb8:	89 f0                	mov    %esi,%eax
f0104cba:	e8 8b fd ff ff       	call   f0104a4a <stab_binsearch>
	if (lfile == 0)
f0104cbf:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104cc2:	85 c0                	test   %eax,%eax
f0104cc4:	0f 84 7a 01 00 00    	je     f0104e44 <debuginfo_eip+0x2f8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104cca:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104ccd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104cd0:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0104cd3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104cd7:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0104cde:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104ce1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0104ce4:	89 f0                	mov    %esi,%eax
f0104ce6:	e8 5f fd ff ff       	call   f0104a4a <stab_binsearch>

	if (lfun <= rfun) {
f0104ceb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104cee:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0104cf1:	39 f0                	cmp    %esi,%eax
f0104cf3:	7f 32                	jg     f0104d27 <debuginfo_eip+0x1db>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104cf5:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104cf8:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104cfb:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f0104cfe:	8b 0a                	mov    (%edx),%ecx
f0104d00:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f0104d03:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0104d06:	2b 4d c0             	sub    -0x40(%ebp),%ecx
f0104d09:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f0104d0c:	73 09                	jae    f0104d17 <debuginfo_eip+0x1cb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104d0e:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0104d11:	03 4d c0             	add    -0x40(%ebp),%ecx
f0104d14:	89 4f 08             	mov    %ecx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104d17:	8b 52 08             	mov    0x8(%edx),%edx
f0104d1a:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0104d1d:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f0104d1f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104d22:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0104d25:	eb 0f                	jmp    f0104d36 <debuginfo_eip+0x1ea>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104d27:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0104d2a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d2d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104d30:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d33:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104d36:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0104d3d:	00 
f0104d3e:	8b 47 08             	mov    0x8(%edi),%eax
f0104d41:	89 04 24             	mov    %eax,(%esp)
f0104d44:	e8 22 09 00 00       	call   f010566b <strfind>
f0104d49:	2b 47 08             	sub    0x8(%edi),%eax
f0104d4c:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0104d4f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0104d53:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0104d5a:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104d5d:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104d60:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104d63:	89 f0                	mov    %esi,%eax
f0104d65:	e8 e0 fc ff ff       	call   f0104a4a <stab_binsearch>
	if (lline > rline) {
f0104d6a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104d6d:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104d70:	0f 8f d5 00 00 00    	jg     f0104e4b <debuginfo_eip+0x2ff>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104d76:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104d79:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0104d7e:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104d81:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104d84:	89 c3                	mov    %eax,%ebx
f0104d86:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104d89:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104d8c:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104d8f:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0104d92:	89 df                	mov    %ebx,%edi
f0104d94:	eb 06                	jmp    f0104d9c <debuginfo_eip+0x250>
f0104d96:	83 e8 01             	sub    $0x1,%eax
f0104d99:	83 ea 0c             	sub    $0xc,%edx
f0104d9c:	89 c6                	mov    %eax,%esi
f0104d9e:	39 c7                	cmp    %eax,%edi
f0104da0:	7f 3c                	jg     f0104dde <debuginfo_eip+0x292>
	       && stabs[lline].n_type != N_SOL
f0104da2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104da6:	80 f9 84             	cmp    $0x84,%cl
f0104da9:	75 08                	jne    f0104db3 <debuginfo_eip+0x267>
f0104dab:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104dae:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104db1:	eb 11                	jmp    f0104dc4 <debuginfo_eip+0x278>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104db3:	80 f9 64             	cmp    $0x64,%cl
f0104db6:	75 de                	jne    f0104d96 <debuginfo_eip+0x24a>
f0104db8:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104dbc:	74 d8                	je     f0104d96 <debuginfo_eip+0x24a>
f0104dbe:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104dc1:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104dc4:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104dc7:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104dca:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f0104dcd:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104dd0:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104dd3:	39 d0                	cmp    %edx,%eax
f0104dd5:	73 0a                	jae    f0104de1 <debuginfo_eip+0x295>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104dd7:	03 45 c0             	add    -0x40(%ebp),%eax
f0104dda:	89 07                	mov    %eax,(%edi)
f0104ddc:	eb 03                	jmp    f0104de1 <debuginfo_eip+0x295>
f0104dde:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104de1:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104de4:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104de7:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104dec:	39 da                	cmp    %ebx,%edx
f0104dee:	7d 67                	jge    f0104e57 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
f0104df0:	83 c2 01             	add    $0x1,%edx
f0104df3:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104df6:	89 d0                	mov    %edx,%eax
f0104df8:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104dfb:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0104dfe:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104e01:	eb 04                	jmp    f0104e07 <debuginfo_eip+0x2bb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104e03:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104e07:	39 c3                	cmp    %eax,%ebx
f0104e09:	7e 47                	jle    f0104e52 <debuginfo_eip+0x306>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104e0b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104e0f:	83 c0 01             	add    $0x1,%eax
f0104e12:	83 c2 0c             	add    $0xc,%edx
f0104e15:	80 f9 a0             	cmp    $0xa0,%cl
f0104e18:	74 e9                	je     f0104e03 <debuginfo_eip+0x2b7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104e1a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e1f:	eb 36                	jmp    f0104e57 <debuginfo_eip+0x30b>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104e21:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e26:	eb 2f                	jmp    f0104e57 <debuginfo_eip+0x30b>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104e28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e2d:	eb 28                	jmp    f0104e57 <debuginfo_eip+0x30b>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0104e2f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e34:	eb 21                	jmp    f0104e57 <debuginfo_eip+0x30b>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104e36:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e3b:	eb 1a                	jmp    f0104e57 <debuginfo_eip+0x30b>
f0104e3d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e42:	eb 13                	jmp    f0104e57 <debuginfo_eip+0x30b>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104e44:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e49:	eb 0c                	jmp    f0104e57 <debuginfo_eip+0x30b>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0104e4b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104e50:	eb 05                	jmp    f0104e57 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104e52:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104e57:	83 c4 4c             	add    $0x4c,%esp
f0104e5a:	5b                   	pop    %ebx
f0104e5b:	5e                   	pop    %esi
f0104e5c:	5f                   	pop    %edi
f0104e5d:	5d                   	pop    %ebp
f0104e5e:	c3                   	ret    
f0104e5f:	90                   	nop

f0104e60 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104e60:	55                   	push   %ebp
f0104e61:	89 e5                	mov    %esp,%ebp
f0104e63:	57                   	push   %edi
f0104e64:	56                   	push   %esi
f0104e65:	53                   	push   %ebx
f0104e66:	83 ec 3c             	sub    $0x3c,%esp
f0104e69:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104e6c:	89 d7                	mov    %edx,%edi
f0104e6e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104e71:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e74:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104e77:	89 c3                	mov    %eax,%ebx
f0104e79:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104e7c:	8b 45 10             	mov    0x10(%ebp),%eax
f0104e7f:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104e82:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104e87:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104e8a:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104e8d:	39 d9                	cmp    %ebx,%ecx
f0104e8f:	72 05                	jb     f0104e96 <printnum+0x36>
f0104e91:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0104e94:	77 69                	ja     f0104eff <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104e96:	8b 4d 18             	mov    0x18(%ebp),%ecx
f0104e99:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0104e9d:	83 ee 01             	sub    $0x1,%esi
f0104ea0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104ea4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104ea8:	8b 44 24 08          	mov    0x8(%esp),%eax
f0104eac:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104eb0:	89 c3                	mov    %eax,%ebx
f0104eb2:	89 d6                	mov    %edx,%esi
f0104eb4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104eb7:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f0104eba:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104ebe:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104ec2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ec5:	89 04 24             	mov    %eax,(%esp)
f0104ec8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104ecb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ecf:	e8 4c 12 00 00       	call   f0106120 <__udivdi3>
f0104ed4:	89 d9                	mov    %ebx,%ecx
f0104ed6:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0104eda:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104ede:	89 04 24             	mov    %eax,(%esp)
f0104ee1:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104ee5:	89 fa                	mov    %edi,%edx
f0104ee7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104eea:	e8 71 ff ff ff       	call   f0104e60 <printnum>
f0104eef:	eb 1b                	jmp    f0104f0c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104ef1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104ef5:	8b 45 18             	mov    0x18(%ebp),%eax
f0104ef8:	89 04 24             	mov    %eax,(%esp)
f0104efb:	ff d3                	call   *%ebx
f0104efd:	eb 03                	jmp    f0104f02 <printnum+0xa2>
f0104eff:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104f02:	83 ee 01             	sub    $0x1,%esi
f0104f05:	85 f6                	test   %esi,%esi
f0104f07:	7f e8                	jg     f0104ef1 <printnum+0x91>
f0104f09:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104f0c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104f10:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104f14:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104f17:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104f1a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104f1e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104f22:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104f25:	89 04 24             	mov    %eax,(%esp)
f0104f28:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104f2b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104f2f:	e8 1c 13 00 00       	call   f0106250 <__umoddi3>
f0104f34:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104f38:	0f be 80 4d 7c 10 f0 	movsbl -0xfef83b3(%eax),%eax
f0104f3f:	89 04 24             	mov    %eax,(%esp)
f0104f42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104f45:	ff d0                	call   *%eax
}
f0104f47:	83 c4 3c             	add    $0x3c,%esp
f0104f4a:	5b                   	pop    %ebx
f0104f4b:	5e                   	pop    %esi
f0104f4c:	5f                   	pop    %edi
f0104f4d:	5d                   	pop    %ebp
f0104f4e:	c3                   	ret    

f0104f4f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104f4f:	55                   	push   %ebp
f0104f50:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104f52:	83 fa 01             	cmp    $0x1,%edx
f0104f55:	7e 0e                	jle    f0104f65 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104f57:	8b 10                	mov    (%eax),%edx
f0104f59:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104f5c:	89 08                	mov    %ecx,(%eax)
f0104f5e:	8b 02                	mov    (%edx),%eax
f0104f60:	8b 52 04             	mov    0x4(%edx),%edx
f0104f63:	eb 22                	jmp    f0104f87 <getuint+0x38>
	else if (lflag)
f0104f65:	85 d2                	test   %edx,%edx
f0104f67:	74 10                	je     f0104f79 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104f69:	8b 10                	mov    (%eax),%edx
f0104f6b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104f6e:	89 08                	mov    %ecx,(%eax)
f0104f70:	8b 02                	mov    (%edx),%eax
f0104f72:	ba 00 00 00 00       	mov    $0x0,%edx
f0104f77:	eb 0e                	jmp    f0104f87 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104f79:	8b 10                	mov    (%eax),%edx
f0104f7b:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104f7e:	89 08                	mov    %ecx,(%eax)
f0104f80:	8b 02                	mov    (%edx),%eax
f0104f82:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104f87:	5d                   	pop    %ebp
f0104f88:	c3                   	ret    

f0104f89 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104f89:	55                   	push   %ebp
f0104f8a:	89 e5                	mov    %esp,%ebp
f0104f8c:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104f8f:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104f93:	8b 10                	mov    (%eax),%edx
f0104f95:	3b 50 04             	cmp    0x4(%eax),%edx
f0104f98:	73 0a                	jae    f0104fa4 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104f9a:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104f9d:	89 08                	mov    %ecx,(%eax)
f0104f9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fa2:	88 02                	mov    %al,(%edx)
}
f0104fa4:	5d                   	pop    %ebp
f0104fa5:	c3                   	ret    

f0104fa6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104fa6:	55                   	push   %ebp
f0104fa7:	89 e5                	mov    %esp,%ebp
f0104fa9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0104fac:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104faf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104fb3:	8b 45 10             	mov    0x10(%ebp),%eax
f0104fb6:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104fba:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104fbd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104fc1:	8b 45 08             	mov    0x8(%ebp),%eax
f0104fc4:	89 04 24             	mov    %eax,(%esp)
f0104fc7:	e8 02 00 00 00       	call   f0104fce <vprintfmt>
	va_end(ap);
}
f0104fcc:	c9                   	leave  
f0104fcd:	c3                   	ret    

f0104fce <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104fce:	55                   	push   %ebp
f0104fcf:	89 e5                	mov    %esp,%ebp
f0104fd1:	57                   	push   %edi
f0104fd2:	56                   	push   %esi
f0104fd3:	53                   	push   %ebx
f0104fd4:	83 ec 3c             	sub    $0x3c,%esp
f0104fd7:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104fda:	8b 5d 10             	mov    0x10(%ebp),%ebx
f0104fdd:	eb 14                	jmp    f0104ff3 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104fdf:	85 c0                	test   %eax,%eax
f0104fe1:	0f 84 b3 03 00 00    	je     f010539a <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104fe7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104feb:	89 04 24             	mov    %eax,(%esp)
f0104fee:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104ff1:	89 f3                	mov    %esi,%ebx
f0104ff3:	8d 73 01             	lea    0x1(%ebx),%esi
f0104ff6:	0f b6 03             	movzbl (%ebx),%eax
f0104ff9:	83 f8 25             	cmp    $0x25,%eax
f0104ffc:	75 e1                	jne    f0104fdf <vprintfmt+0x11>
f0104ffe:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0105002:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0105009:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0105010:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0105017:	ba 00 00 00 00       	mov    $0x0,%edx
f010501c:	eb 1d                	jmp    f010503b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010501e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0105020:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0105024:	eb 15                	jmp    f010503b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105026:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0105028:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010502c:	eb 0d                	jmp    f010503b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010502e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0105031:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105034:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010503b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010503e:	0f b6 0e             	movzbl (%esi),%ecx
f0105041:	0f b6 c1             	movzbl %cl,%eax
f0105044:	83 e9 23             	sub    $0x23,%ecx
f0105047:	80 f9 55             	cmp    $0x55,%cl
f010504a:	0f 87 2a 03 00 00    	ja     f010537a <vprintfmt+0x3ac>
f0105050:	0f b6 c9             	movzbl %cl,%ecx
f0105053:	ff 24 8d 20 7d 10 f0 	jmp    *-0xfef82e0(,%ecx,4)
f010505a:	89 de                	mov    %ebx,%esi
f010505c:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0105061:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f0105064:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f0105068:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010506b:	8d 58 d0             	lea    -0x30(%eax),%ebx
f010506e:	83 fb 09             	cmp    $0x9,%ebx
f0105071:	77 36                	ja     f01050a9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0105073:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0105076:	eb e9                	jmp    f0105061 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0105078:	8b 45 14             	mov    0x14(%ebp),%eax
f010507b:	8d 48 04             	lea    0x4(%eax),%ecx
f010507e:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0105081:	8b 00                	mov    (%eax),%eax
f0105083:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105086:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0105088:	eb 22                	jmp    f01050ac <vprintfmt+0xde>
f010508a:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010508d:	85 c9                	test   %ecx,%ecx
f010508f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105094:	0f 49 c1             	cmovns %ecx,%eax
f0105097:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010509a:	89 de                	mov    %ebx,%esi
f010509c:	eb 9d                	jmp    f010503b <vprintfmt+0x6d>
f010509e:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01050a0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01050a7:	eb 92                	jmp    f010503b <vprintfmt+0x6d>
f01050a9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01050ac:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01050b0:	79 89                	jns    f010503b <vprintfmt+0x6d>
f01050b2:	e9 77 ff ff ff       	jmp    f010502e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01050b7:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01050ba:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01050bc:	e9 7a ff ff ff       	jmp    f010503b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01050c1:	8b 45 14             	mov    0x14(%ebp),%eax
f01050c4:	8d 50 04             	lea    0x4(%eax),%edx
f01050c7:	89 55 14             	mov    %edx,0x14(%ebp)
f01050ca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01050ce:	8b 00                	mov    (%eax),%eax
f01050d0:	89 04 24             	mov    %eax,(%esp)
f01050d3:	ff 55 08             	call   *0x8(%ebp)
			break;
f01050d6:	e9 18 ff ff ff       	jmp    f0104ff3 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01050db:	8b 45 14             	mov    0x14(%ebp),%eax
f01050de:	8d 50 04             	lea    0x4(%eax),%edx
f01050e1:	89 55 14             	mov    %edx,0x14(%ebp)
f01050e4:	8b 00                	mov    (%eax),%eax
f01050e6:	99                   	cltd   
f01050e7:	31 d0                	xor    %edx,%eax
f01050e9:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01050eb:	83 f8 09             	cmp    $0x9,%eax
f01050ee:	7f 0b                	jg     f01050fb <vprintfmt+0x12d>
f01050f0:	8b 14 85 80 7e 10 f0 	mov    -0xfef8180(,%eax,4),%edx
f01050f7:	85 d2                	test   %edx,%edx
f01050f9:	75 20                	jne    f010511b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f01050fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01050ff:	c7 44 24 08 65 7c 10 	movl   $0xf0107c65,0x8(%esp)
f0105106:	f0 
f0105107:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010510b:	8b 45 08             	mov    0x8(%ebp),%eax
f010510e:	89 04 24             	mov    %eax,(%esp)
f0105111:	e8 90 fe ff ff       	call   f0104fa6 <printfmt>
f0105116:	e9 d8 fe ff ff       	jmp    f0104ff3 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010511b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010511f:	c7 44 24 08 8d 73 10 	movl   $0xf010738d,0x8(%esp)
f0105126:	f0 
f0105127:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010512b:	8b 45 08             	mov    0x8(%ebp),%eax
f010512e:	89 04 24             	mov    %eax,(%esp)
f0105131:	e8 70 fe ff ff       	call   f0104fa6 <printfmt>
f0105136:	e9 b8 fe ff ff       	jmp    f0104ff3 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010513b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010513e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0105141:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0105144:	8b 45 14             	mov    0x14(%ebp),%eax
f0105147:	8d 50 04             	lea    0x4(%eax),%edx
f010514a:	89 55 14             	mov    %edx,0x14(%ebp)
f010514d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010514f:	85 f6                	test   %esi,%esi
f0105151:	b8 5e 7c 10 f0       	mov    $0xf0107c5e,%eax
f0105156:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f0105159:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010515d:	0f 84 97 00 00 00    	je     f01051fa <vprintfmt+0x22c>
f0105163:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f0105167:	0f 8e 9b 00 00 00    	jle    f0105208 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f010516d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0105171:	89 34 24             	mov    %esi,(%esp)
f0105174:	e8 9f 03 00 00       	call   f0105518 <strnlen>
f0105179:	8b 55 d0             	mov    -0x30(%ebp),%edx
f010517c:	29 c2                	sub    %eax,%edx
f010517e:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f0105181:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0105185:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0105188:	89 75 d8             	mov    %esi,-0x28(%ebp)
f010518b:	8b 75 08             	mov    0x8(%ebp),%esi
f010518e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105191:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0105193:	eb 0f                	jmp    f01051a4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0105195:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105199:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010519c:	89 04 24             	mov    %eax,(%esp)
f010519f:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01051a1:	83 eb 01             	sub    $0x1,%ebx
f01051a4:	85 db                	test   %ebx,%ebx
f01051a6:	7f ed                	jg     f0105195 <vprintfmt+0x1c7>
f01051a8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01051ab:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01051ae:	85 d2                	test   %edx,%edx
f01051b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01051b5:	0f 49 c2             	cmovns %edx,%eax
f01051b8:	29 c2                	sub    %eax,%edx
f01051ba:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01051bd:	89 d7                	mov    %edx,%edi
f01051bf:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f01051c2:	eb 50                	jmp    f0105214 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f01051c4:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f01051c8:	74 1e                	je     f01051e8 <vprintfmt+0x21a>
f01051ca:	0f be d2             	movsbl %dl,%edx
f01051cd:	83 ea 20             	sub    $0x20,%edx
f01051d0:	83 fa 5e             	cmp    $0x5e,%edx
f01051d3:	76 13                	jbe    f01051e8 <vprintfmt+0x21a>
					putch('?', putdat);
f01051d5:	8b 45 0c             	mov    0xc(%ebp),%eax
f01051d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01051dc:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01051e3:	ff 55 08             	call   *0x8(%ebp)
f01051e6:	eb 0d                	jmp    f01051f5 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f01051e8:	8b 55 0c             	mov    0xc(%ebp),%edx
f01051eb:	89 54 24 04          	mov    %edx,0x4(%esp)
f01051ef:	89 04 24             	mov    %eax,(%esp)
f01051f2:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01051f5:	83 ef 01             	sub    $0x1,%edi
f01051f8:	eb 1a                	jmp    f0105214 <vprintfmt+0x246>
f01051fa:	89 7d 0c             	mov    %edi,0xc(%ebp)
f01051fd:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0105200:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105203:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105206:	eb 0c                	jmp    f0105214 <vprintfmt+0x246>
f0105208:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010520b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010520e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0105211:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0105214:	83 c6 01             	add    $0x1,%esi
f0105217:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010521b:	0f be c2             	movsbl %dl,%eax
f010521e:	85 c0                	test   %eax,%eax
f0105220:	74 27                	je     f0105249 <vprintfmt+0x27b>
f0105222:	85 db                	test   %ebx,%ebx
f0105224:	78 9e                	js     f01051c4 <vprintfmt+0x1f6>
f0105226:	83 eb 01             	sub    $0x1,%ebx
f0105229:	79 99                	jns    f01051c4 <vprintfmt+0x1f6>
f010522b:	89 f8                	mov    %edi,%eax
f010522d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105230:	8b 75 08             	mov    0x8(%ebp),%esi
f0105233:	89 c3                	mov    %eax,%ebx
f0105235:	eb 1a                	jmp    f0105251 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0105237:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010523b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0105242:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0105244:	83 eb 01             	sub    $0x1,%ebx
f0105247:	eb 08                	jmp    f0105251 <vprintfmt+0x283>
f0105249:	89 fb                	mov    %edi,%ebx
f010524b:	8b 75 08             	mov    0x8(%ebp),%esi
f010524e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0105251:	85 db                	test   %ebx,%ebx
f0105253:	7f e2                	jg     f0105237 <vprintfmt+0x269>
f0105255:	89 75 08             	mov    %esi,0x8(%ebp)
f0105258:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010525b:	e9 93 fd ff ff       	jmp    f0104ff3 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0105260:	83 fa 01             	cmp    $0x1,%edx
f0105263:	7e 16                	jle    f010527b <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f0105265:	8b 45 14             	mov    0x14(%ebp),%eax
f0105268:	8d 50 08             	lea    0x8(%eax),%edx
f010526b:	89 55 14             	mov    %edx,0x14(%ebp)
f010526e:	8b 50 04             	mov    0x4(%eax),%edx
f0105271:	8b 00                	mov    (%eax),%eax
f0105273:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0105276:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0105279:	eb 32                	jmp    f01052ad <vprintfmt+0x2df>
	else if (lflag)
f010527b:	85 d2                	test   %edx,%edx
f010527d:	74 18                	je     f0105297 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f010527f:	8b 45 14             	mov    0x14(%ebp),%eax
f0105282:	8d 50 04             	lea    0x4(%eax),%edx
f0105285:	89 55 14             	mov    %edx,0x14(%ebp)
f0105288:	8b 30                	mov    (%eax),%esi
f010528a:	89 75 e0             	mov    %esi,-0x20(%ebp)
f010528d:	89 f0                	mov    %esi,%eax
f010528f:	c1 f8 1f             	sar    $0x1f,%eax
f0105292:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105295:	eb 16                	jmp    f01052ad <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f0105297:	8b 45 14             	mov    0x14(%ebp),%eax
f010529a:	8d 50 04             	lea    0x4(%eax),%edx
f010529d:	89 55 14             	mov    %edx,0x14(%ebp)
f01052a0:	8b 30                	mov    (%eax),%esi
f01052a2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01052a5:	89 f0                	mov    %esi,%eax
f01052a7:	c1 f8 1f             	sar    $0x1f,%eax
f01052aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01052ad:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01052b0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01052b3:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01052b8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01052bc:	0f 89 80 00 00 00    	jns    f0105342 <vprintfmt+0x374>
				putch('-', putdat);
f01052c2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01052c6:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01052cd:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01052d0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01052d3:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01052d6:	f7 d8                	neg    %eax
f01052d8:	83 d2 00             	adc    $0x0,%edx
f01052db:	f7 da                	neg    %edx
			}
			base = 10;
f01052dd:	b9 0a 00 00 00       	mov    $0xa,%ecx
f01052e2:	eb 5e                	jmp    f0105342 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01052e4:	8d 45 14             	lea    0x14(%ebp),%eax
f01052e7:	e8 63 fc ff ff       	call   f0104f4f <getuint>
			base = 10;
f01052ec:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f01052f1:	eb 4f                	jmp    f0105342 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f01052f3:	8d 45 14             	lea    0x14(%ebp),%eax
f01052f6:	e8 54 fc ff ff       	call   f0104f4f <getuint>
			base = 8;
f01052fb:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0105300:	eb 40                	jmp    f0105342 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0105302:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105306:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010530d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0105310:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105314:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010531b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010531e:	8b 45 14             	mov    0x14(%ebp),%eax
f0105321:	8d 50 04             	lea    0x4(%eax),%edx
f0105324:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0105327:	8b 00                	mov    (%eax),%eax
f0105329:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010532e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0105333:	eb 0d                	jmp    f0105342 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0105335:	8d 45 14             	lea    0x14(%ebp),%eax
f0105338:	e8 12 fc ff ff       	call   f0104f4f <getuint>
			base = 16;
f010533d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0105342:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0105346:	89 74 24 10          	mov    %esi,0x10(%esp)
f010534a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010534d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105351:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0105355:	89 04 24             	mov    %eax,(%esp)
f0105358:	89 54 24 04          	mov    %edx,0x4(%esp)
f010535c:	89 fa                	mov    %edi,%edx
f010535e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105361:	e8 fa fa ff ff       	call   f0104e60 <printnum>
			break;
f0105366:	e9 88 fc ff ff       	jmp    f0104ff3 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f010536b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010536f:	89 04 24             	mov    %eax,(%esp)
f0105372:	ff 55 08             	call   *0x8(%ebp)
			break;
f0105375:	e9 79 fc ff ff       	jmp    f0104ff3 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f010537a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010537e:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0105385:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105388:	89 f3                	mov    %esi,%ebx
f010538a:	eb 03                	jmp    f010538f <vprintfmt+0x3c1>
f010538c:	83 eb 01             	sub    $0x1,%ebx
f010538f:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f0105393:	75 f7                	jne    f010538c <vprintfmt+0x3be>
f0105395:	e9 59 fc ff ff       	jmp    f0104ff3 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f010539a:	83 c4 3c             	add    $0x3c,%esp
f010539d:	5b                   	pop    %ebx
f010539e:	5e                   	pop    %esi
f010539f:	5f                   	pop    %edi
f01053a0:	5d                   	pop    %ebp
f01053a1:	c3                   	ret    

f01053a2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01053a2:	55                   	push   %ebp
f01053a3:	89 e5                	mov    %esp,%ebp
f01053a5:	83 ec 28             	sub    $0x28,%esp
f01053a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01053ab:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01053ae:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01053b1:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01053b5:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01053b8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01053bf:	85 c0                	test   %eax,%eax
f01053c1:	74 30                	je     f01053f3 <vsnprintf+0x51>
f01053c3:	85 d2                	test   %edx,%edx
f01053c5:	7e 2c                	jle    f01053f3 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01053c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01053ca:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01053ce:	8b 45 10             	mov    0x10(%ebp),%eax
f01053d1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01053d5:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01053d8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01053dc:	c7 04 24 89 4f 10 f0 	movl   $0xf0104f89,(%esp)
f01053e3:	e8 e6 fb ff ff       	call   f0104fce <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f01053e8:	8b 45 ec             	mov    -0x14(%ebp),%eax
f01053eb:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f01053ee:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01053f1:	eb 05                	jmp    f01053f8 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f01053f3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f01053f8:	c9                   	leave  
f01053f9:	c3                   	ret    

f01053fa <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f01053fa:	55                   	push   %ebp
f01053fb:	89 e5                	mov    %esp,%ebp
f01053fd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0105400:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0105403:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105407:	8b 45 10             	mov    0x10(%ebp),%eax
f010540a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010540e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105411:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105415:	8b 45 08             	mov    0x8(%ebp),%eax
f0105418:	89 04 24             	mov    %eax,(%esp)
f010541b:	e8 82 ff ff ff       	call   f01053a2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0105420:	c9                   	leave  
f0105421:	c3                   	ret    
f0105422:	66 90                	xchg   %ax,%ax
f0105424:	66 90                	xchg   %ax,%ax
f0105426:	66 90                	xchg   %ax,%ax
f0105428:	66 90                	xchg   %ax,%ax
f010542a:	66 90                	xchg   %ax,%ax
f010542c:	66 90                	xchg   %ax,%ax
f010542e:	66 90                	xchg   %ax,%ax

f0105430 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0105430:	55                   	push   %ebp
f0105431:	89 e5                	mov    %esp,%ebp
f0105433:	57                   	push   %edi
f0105434:	56                   	push   %esi
f0105435:	53                   	push   %ebx
f0105436:	83 ec 1c             	sub    $0x1c,%esp
f0105439:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010543c:	85 c0                	test   %eax,%eax
f010543e:	74 10                	je     f0105450 <readline+0x20>
		cprintf("%s", prompt);
f0105440:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105444:	c7 04 24 8d 73 10 f0 	movl   $0xf010738d,(%esp)
f010544b:	e8 bc ec ff ff       	call   f010410c <cprintf>

	i = 0;
	echoing = iscons(0);
f0105450:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0105457:	e8 4f b3 ff ff       	call   f01007ab <iscons>
f010545c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010545e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0105463:	e8 32 b3 ff ff       	call   f010079a <getchar>
f0105468:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010546a:	85 c0                	test   %eax,%eax
f010546c:	79 17                	jns    f0105485 <readline+0x55>
			cprintf("read error: %e\n", c);
f010546e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105472:	c7 04 24 a8 7e 10 f0 	movl   $0xf0107ea8,(%esp)
f0105479:	e8 8e ec ff ff       	call   f010410c <cprintf>
			return NULL;
f010547e:	b8 00 00 00 00       	mov    $0x0,%eax
f0105483:	eb 6d                	jmp    f01054f2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0105485:	83 f8 7f             	cmp    $0x7f,%eax
f0105488:	74 05                	je     f010548f <readline+0x5f>
f010548a:	83 f8 08             	cmp    $0x8,%eax
f010548d:	75 19                	jne    f01054a8 <readline+0x78>
f010548f:	85 f6                	test   %esi,%esi
f0105491:	7e 15                	jle    f01054a8 <readline+0x78>
			if (echoing)
f0105493:	85 ff                	test   %edi,%edi
f0105495:	74 0c                	je     f01054a3 <readline+0x73>
				cputchar('\b');
f0105497:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010549e:	e8 e7 b2 ff ff       	call   f010078a <cputchar>
			i--;
f01054a3:	83 ee 01             	sub    $0x1,%esi
f01054a6:	eb bb                	jmp    f0105463 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01054a8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01054ae:	7f 1c                	jg     f01054cc <readline+0x9c>
f01054b0:	83 fb 1f             	cmp    $0x1f,%ebx
f01054b3:	7e 17                	jle    f01054cc <readline+0x9c>
			if (echoing)
f01054b5:	85 ff                	test   %edi,%edi
f01054b7:	74 08                	je     f01054c1 <readline+0x91>
				cputchar(c);
f01054b9:	89 1c 24             	mov    %ebx,(%esp)
f01054bc:	e8 c9 b2 ff ff       	call   f010078a <cputchar>
			buf[i++] = c;
f01054c1:	88 9e 00 bb 22 f0    	mov    %bl,-0xfdd4500(%esi)
f01054c7:	8d 76 01             	lea    0x1(%esi),%esi
f01054ca:	eb 97                	jmp    f0105463 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01054cc:	83 fb 0d             	cmp    $0xd,%ebx
f01054cf:	74 05                	je     f01054d6 <readline+0xa6>
f01054d1:	83 fb 0a             	cmp    $0xa,%ebx
f01054d4:	75 8d                	jne    f0105463 <readline+0x33>
			if (echoing)
f01054d6:	85 ff                	test   %edi,%edi
f01054d8:	74 0c                	je     f01054e6 <readline+0xb6>
				cputchar('\n');
f01054da:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f01054e1:	e8 a4 b2 ff ff       	call   f010078a <cputchar>
			buf[i] = 0;
f01054e6:	c6 86 00 bb 22 f0 00 	movb   $0x0,-0xfdd4500(%esi)
			return buf;
f01054ed:	b8 00 bb 22 f0       	mov    $0xf022bb00,%eax
		}
	}
}
f01054f2:	83 c4 1c             	add    $0x1c,%esp
f01054f5:	5b                   	pop    %ebx
f01054f6:	5e                   	pop    %esi
f01054f7:	5f                   	pop    %edi
f01054f8:	5d                   	pop    %ebp
f01054f9:	c3                   	ret    
f01054fa:	66 90                	xchg   %ax,%ax
f01054fc:	66 90                	xchg   %ax,%ax
f01054fe:	66 90                	xchg   %ax,%ax

f0105500 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0105500:	55                   	push   %ebp
f0105501:	89 e5                	mov    %esp,%ebp
f0105503:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0105506:	b8 00 00 00 00       	mov    $0x0,%eax
f010550b:	eb 03                	jmp    f0105510 <strlen+0x10>
		n++;
f010550d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0105510:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0105514:	75 f7                	jne    f010550d <strlen+0xd>
		n++;
	return n;
}
f0105516:	5d                   	pop    %ebp
f0105517:	c3                   	ret    

f0105518 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0105518:	55                   	push   %ebp
f0105519:	89 e5                	mov    %esp,%ebp
f010551b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010551e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0105521:	b8 00 00 00 00       	mov    $0x0,%eax
f0105526:	eb 03                	jmp    f010552b <strnlen+0x13>
		n++;
f0105528:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010552b:	39 d0                	cmp    %edx,%eax
f010552d:	74 06                	je     f0105535 <strnlen+0x1d>
f010552f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0105533:	75 f3                	jne    f0105528 <strnlen+0x10>
		n++;
	return n;
}
f0105535:	5d                   	pop    %ebp
f0105536:	c3                   	ret    

f0105537 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0105537:	55                   	push   %ebp
f0105538:	89 e5                	mov    %esp,%ebp
f010553a:	53                   	push   %ebx
f010553b:	8b 45 08             	mov    0x8(%ebp),%eax
f010553e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0105541:	89 c2                	mov    %eax,%edx
f0105543:	83 c2 01             	add    $0x1,%edx
f0105546:	83 c1 01             	add    $0x1,%ecx
f0105549:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010554d:	88 5a ff             	mov    %bl,-0x1(%edx)
f0105550:	84 db                	test   %bl,%bl
f0105552:	75 ef                	jne    f0105543 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0105554:	5b                   	pop    %ebx
f0105555:	5d                   	pop    %ebp
f0105556:	c3                   	ret    

f0105557 <strcat>:

char *
strcat(char *dst, const char *src)
{
f0105557:	55                   	push   %ebp
f0105558:	89 e5                	mov    %esp,%ebp
f010555a:	53                   	push   %ebx
f010555b:	83 ec 08             	sub    $0x8,%esp
f010555e:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105561:	89 1c 24             	mov    %ebx,(%esp)
f0105564:	e8 97 ff ff ff       	call   f0105500 <strlen>
	strcpy(dst + len, src);
f0105569:	8b 55 0c             	mov    0xc(%ebp),%edx
f010556c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0105570:	01 d8                	add    %ebx,%eax
f0105572:	89 04 24             	mov    %eax,(%esp)
f0105575:	e8 bd ff ff ff       	call   f0105537 <strcpy>
	return dst;
}
f010557a:	89 d8                	mov    %ebx,%eax
f010557c:	83 c4 08             	add    $0x8,%esp
f010557f:	5b                   	pop    %ebx
f0105580:	5d                   	pop    %ebp
f0105581:	c3                   	ret    

f0105582 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105582:	55                   	push   %ebp
f0105583:	89 e5                	mov    %esp,%ebp
f0105585:	56                   	push   %esi
f0105586:	53                   	push   %ebx
f0105587:	8b 75 08             	mov    0x8(%ebp),%esi
f010558a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010558d:	89 f3                	mov    %esi,%ebx
f010558f:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105592:	89 f2                	mov    %esi,%edx
f0105594:	eb 0f                	jmp    f01055a5 <strncpy+0x23>
		*dst++ = *src;
f0105596:	83 c2 01             	add    $0x1,%edx
f0105599:	0f b6 01             	movzbl (%ecx),%eax
f010559c:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010559f:	80 39 01             	cmpb   $0x1,(%ecx)
f01055a2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01055a5:	39 da                	cmp    %ebx,%edx
f01055a7:	75 ed                	jne    f0105596 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01055a9:	89 f0                	mov    %esi,%eax
f01055ab:	5b                   	pop    %ebx
f01055ac:	5e                   	pop    %esi
f01055ad:	5d                   	pop    %ebp
f01055ae:	c3                   	ret    

f01055af <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01055af:	55                   	push   %ebp
f01055b0:	89 e5                	mov    %esp,%ebp
f01055b2:	56                   	push   %esi
f01055b3:	53                   	push   %ebx
f01055b4:	8b 75 08             	mov    0x8(%ebp),%esi
f01055b7:	8b 55 0c             	mov    0xc(%ebp),%edx
f01055ba:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01055bd:	89 f0                	mov    %esi,%eax
f01055bf:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f01055c3:	85 c9                	test   %ecx,%ecx
f01055c5:	75 0b                	jne    f01055d2 <strlcpy+0x23>
f01055c7:	eb 1d                	jmp    f01055e6 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f01055c9:	83 c0 01             	add    $0x1,%eax
f01055cc:	83 c2 01             	add    $0x1,%edx
f01055cf:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f01055d2:	39 d8                	cmp    %ebx,%eax
f01055d4:	74 0b                	je     f01055e1 <strlcpy+0x32>
f01055d6:	0f b6 0a             	movzbl (%edx),%ecx
f01055d9:	84 c9                	test   %cl,%cl
f01055db:	75 ec                	jne    f01055c9 <strlcpy+0x1a>
f01055dd:	89 c2                	mov    %eax,%edx
f01055df:	eb 02                	jmp    f01055e3 <strlcpy+0x34>
f01055e1:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f01055e3:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f01055e6:	29 f0                	sub    %esi,%eax
}
f01055e8:	5b                   	pop    %ebx
f01055e9:	5e                   	pop    %esi
f01055ea:	5d                   	pop    %ebp
f01055eb:	c3                   	ret    

f01055ec <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01055ec:	55                   	push   %ebp
f01055ed:	89 e5                	mov    %esp,%ebp
f01055ef:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01055f2:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01055f5:	eb 06                	jmp    f01055fd <strcmp+0x11>
		p++, q++;
f01055f7:	83 c1 01             	add    $0x1,%ecx
f01055fa:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01055fd:	0f b6 01             	movzbl (%ecx),%eax
f0105600:	84 c0                	test   %al,%al
f0105602:	74 04                	je     f0105608 <strcmp+0x1c>
f0105604:	3a 02                	cmp    (%edx),%al
f0105606:	74 ef                	je     f01055f7 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105608:	0f b6 c0             	movzbl %al,%eax
f010560b:	0f b6 12             	movzbl (%edx),%edx
f010560e:	29 d0                	sub    %edx,%eax
}
f0105610:	5d                   	pop    %ebp
f0105611:	c3                   	ret    

f0105612 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0105612:	55                   	push   %ebp
f0105613:	89 e5                	mov    %esp,%ebp
f0105615:	53                   	push   %ebx
f0105616:	8b 45 08             	mov    0x8(%ebp),%eax
f0105619:	8b 55 0c             	mov    0xc(%ebp),%edx
f010561c:	89 c3                	mov    %eax,%ebx
f010561e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0105621:	eb 06                	jmp    f0105629 <strncmp+0x17>
		n--, p++, q++;
f0105623:	83 c0 01             	add    $0x1,%eax
f0105626:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105629:	39 d8                	cmp    %ebx,%eax
f010562b:	74 15                	je     f0105642 <strncmp+0x30>
f010562d:	0f b6 08             	movzbl (%eax),%ecx
f0105630:	84 c9                	test   %cl,%cl
f0105632:	74 04                	je     f0105638 <strncmp+0x26>
f0105634:	3a 0a                	cmp    (%edx),%cl
f0105636:	74 eb                	je     f0105623 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105638:	0f b6 00             	movzbl (%eax),%eax
f010563b:	0f b6 12             	movzbl (%edx),%edx
f010563e:	29 d0                	sub    %edx,%eax
f0105640:	eb 05                	jmp    f0105647 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0105642:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105647:	5b                   	pop    %ebx
f0105648:	5d                   	pop    %ebp
f0105649:	c3                   	ret    

f010564a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010564a:	55                   	push   %ebp
f010564b:	89 e5                	mov    %esp,%ebp
f010564d:	8b 45 08             	mov    0x8(%ebp),%eax
f0105650:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105654:	eb 07                	jmp    f010565d <strchr+0x13>
		if (*s == c)
f0105656:	38 ca                	cmp    %cl,%dl
f0105658:	74 0f                	je     f0105669 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010565a:	83 c0 01             	add    $0x1,%eax
f010565d:	0f b6 10             	movzbl (%eax),%edx
f0105660:	84 d2                	test   %dl,%dl
f0105662:	75 f2                	jne    f0105656 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105664:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105669:	5d                   	pop    %ebp
f010566a:	c3                   	ret    

f010566b <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010566b:	55                   	push   %ebp
f010566c:	89 e5                	mov    %esp,%ebp
f010566e:	8b 45 08             	mov    0x8(%ebp),%eax
f0105671:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105675:	eb 07                	jmp    f010567e <strfind+0x13>
		if (*s == c)
f0105677:	38 ca                	cmp    %cl,%dl
f0105679:	74 0a                	je     f0105685 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f010567b:	83 c0 01             	add    $0x1,%eax
f010567e:	0f b6 10             	movzbl (%eax),%edx
f0105681:	84 d2                	test   %dl,%dl
f0105683:	75 f2                	jne    f0105677 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f0105685:	5d                   	pop    %ebp
f0105686:	c3                   	ret    

f0105687 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105687:	55                   	push   %ebp
f0105688:	89 e5                	mov    %esp,%ebp
f010568a:	57                   	push   %edi
f010568b:	56                   	push   %esi
f010568c:	53                   	push   %ebx
f010568d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0105690:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0105693:	85 c9                	test   %ecx,%ecx
f0105695:	74 36                	je     f01056cd <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105697:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010569d:	75 28                	jne    f01056c7 <memset+0x40>
f010569f:	f6 c1 03             	test   $0x3,%cl
f01056a2:	75 23                	jne    f01056c7 <memset+0x40>
		c &= 0xFF;
f01056a4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01056a8:	89 d3                	mov    %edx,%ebx
f01056aa:	c1 e3 08             	shl    $0x8,%ebx
f01056ad:	89 d6                	mov    %edx,%esi
f01056af:	c1 e6 18             	shl    $0x18,%esi
f01056b2:	89 d0                	mov    %edx,%eax
f01056b4:	c1 e0 10             	shl    $0x10,%eax
f01056b7:	09 f0                	or     %esi,%eax
f01056b9:	09 c2                	or     %eax,%edx
f01056bb:	89 d0                	mov    %edx,%eax
f01056bd:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01056bf:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01056c2:	fc                   	cld    
f01056c3:	f3 ab                	rep stos %eax,%es:(%edi)
f01056c5:	eb 06                	jmp    f01056cd <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01056c7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01056ca:	fc                   	cld    
f01056cb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01056cd:	89 f8                	mov    %edi,%eax
f01056cf:	5b                   	pop    %ebx
f01056d0:	5e                   	pop    %esi
f01056d1:	5f                   	pop    %edi
f01056d2:	5d                   	pop    %ebp
f01056d3:	c3                   	ret    

f01056d4 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01056d4:	55                   	push   %ebp
f01056d5:	89 e5                	mov    %esp,%ebp
f01056d7:	57                   	push   %edi
f01056d8:	56                   	push   %esi
f01056d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01056dc:	8b 75 0c             	mov    0xc(%ebp),%esi
f01056df:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01056e2:	39 c6                	cmp    %eax,%esi
f01056e4:	73 35                	jae    f010571b <memmove+0x47>
f01056e6:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01056e9:	39 d0                	cmp    %edx,%eax
f01056eb:	73 2e                	jae    f010571b <memmove+0x47>
		s += n;
		d += n;
f01056ed:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f01056f0:	89 d6                	mov    %edx,%esi
f01056f2:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01056f4:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01056fa:	75 13                	jne    f010570f <memmove+0x3b>
f01056fc:	f6 c1 03             	test   $0x3,%cl
f01056ff:	75 0e                	jne    f010570f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0105701:	83 ef 04             	sub    $0x4,%edi
f0105704:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105707:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010570a:	fd                   	std    
f010570b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010570d:	eb 09                	jmp    f0105718 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010570f:	83 ef 01             	sub    $0x1,%edi
f0105712:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105715:	fd                   	std    
f0105716:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105718:	fc                   	cld    
f0105719:	eb 1d                	jmp    f0105738 <memmove+0x64>
f010571b:	89 f2                	mov    %esi,%edx
f010571d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010571f:	f6 c2 03             	test   $0x3,%dl
f0105722:	75 0f                	jne    f0105733 <memmove+0x5f>
f0105724:	f6 c1 03             	test   $0x3,%cl
f0105727:	75 0a                	jne    f0105733 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105729:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010572c:	89 c7                	mov    %eax,%edi
f010572e:	fc                   	cld    
f010572f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105731:	eb 05                	jmp    f0105738 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0105733:	89 c7                	mov    %eax,%edi
f0105735:	fc                   	cld    
f0105736:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105738:	5e                   	pop    %esi
f0105739:	5f                   	pop    %edi
f010573a:	5d                   	pop    %ebp
f010573b:	c3                   	ret    

f010573c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010573c:	55                   	push   %ebp
f010573d:	89 e5                	mov    %esp,%ebp
f010573f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0105742:	8b 45 10             	mov    0x10(%ebp),%eax
f0105745:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105749:	8b 45 0c             	mov    0xc(%ebp),%eax
f010574c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105750:	8b 45 08             	mov    0x8(%ebp),%eax
f0105753:	89 04 24             	mov    %eax,(%esp)
f0105756:	e8 79 ff ff ff       	call   f01056d4 <memmove>
}
f010575b:	c9                   	leave  
f010575c:	c3                   	ret    

f010575d <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010575d:	55                   	push   %ebp
f010575e:	89 e5                	mov    %esp,%ebp
f0105760:	56                   	push   %esi
f0105761:	53                   	push   %ebx
f0105762:	8b 55 08             	mov    0x8(%ebp),%edx
f0105765:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105768:	89 d6                	mov    %edx,%esi
f010576a:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010576d:	eb 1a                	jmp    f0105789 <memcmp+0x2c>
		if (*s1 != *s2)
f010576f:	0f b6 02             	movzbl (%edx),%eax
f0105772:	0f b6 19             	movzbl (%ecx),%ebx
f0105775:	38 d8                	cmp    %bl,%al
f0105777:	74 0a                	je     f0105783 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105779:	0f b6 c0             	movzbl %al,%eax
f010577c:	0f b6 db             	movzbl %bl,%ebx
f010577f:	29 d8                	sub    %ebx,%eax
f0105781:	eb 0f                	jmp    f0105792 <memcmp+0x35>
		s1++, s2++;
f0105783:	83 c2 01             	add    $0x1,%edx
f0105786:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105789:	39 f2                	cmp    %esi,%edx
f010578b:	75 e2                	jne    f010576f <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010578d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105792:	5b                   	pop    %ebx
f0105793:	5e                   	pop    %esi
f0105794:	5d                   	pop    %ebp
f0105795:	c3                   	ret    

f0105796 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105796:	55                   	push   %ebp
f0105797:	89 e5                	mov    %esp,%ebp
f0105799:	8b 45 08             	mov    0x8(%ebp),%eax
f010579c:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010579f:	89 c2                	mov    %eax,%edx
f01057a1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01057a4:	eb 07                	jmp    f01057ad <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01057a6:	38 08                	cmp    %cl,(%eax)
f01057a8:	74 07                	je     f01057b1 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01057aa:	83 c0 01             	add    $0x1,%eax
f01057ad:	39 d0                	cmp    %edx,%eax
f01057af:	72 f5                	jb     f01057a6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01057b1:	5d                   	pop    %ebp
f01057b2:	c3                   	ret    

f01057b3 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01057b3:	55                   	push   %ebp
f01057b4:	89 e5                	mov    %esp,%ebp
f01057b6:	57                   	push   %edi
f01057b7:	56                   	push   %esi
f01057b8:	53                   	push   %ebx
f01057b9:	8b 55 08             	mov    0x8(%ebp),%edx
f01057bc:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01057bf:	eb 03                	jmp    f01057c4 <strtol+0x11>
		s++;
f01057c1:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01057c4:	0f b6 0a             	movzbl (%edx),%ecx
f01057c7:	80 f9 09             	cmp    $0x9,%cl
f01057ca:	74 f5                	je     f01057c1 <strtol+0xe>
f01057cc:	80 f9 20             	cmp    $0x20,%cl
f01057cf:	74 f0                	je     f01057c1 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01057d1:	80 f9 2b             	cmp    $0x2b,%cl
f01057d4:	75 0a                	jne    f01057e0 <strtol+0x2d>
		s++;
f01057d6:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01057d9:	bf 00 00 00 00       	mov    $0x0,%edi
f01057de:	eb 11                	jmp    f01057f1 <strtol+0x3e>
f01057e0:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01057e5:	80 f9 2d             	cmp    $0x2d,%cl
f01057e8:	75 07                	jne    f01057f1 <strtol+0x3e>
		s++, neg = 1;
f01057ea:	8d 52 01             	lea    0x1(%edx),%edx
f01057ed:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01057f1:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f01057f6:	75 15                	jne    f010580d <strtol+0x5a>
f01057f8:	80 3a 30             	cmpb   $0x30,(%edx)
f01057fb:	75 10                	jne    f010580d <strtol+0x5a>
f01057fd:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0105801:	75 0a                	jne    f010580d <strtol+0x5a>
		s += 2, base = 16;
f0105803:	83 c2 02             	add    $0x2,%edx
f0105806:	b8 10 00 00 00       	mov    $0x10,%eax
f010580b:	eb 10                	jmp    f010581d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f010580d:	85 c0                	test   %eax,%eax
f010580f:	75 0c                	jne    f010581d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105811:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105813:	80 3a 30             	cmpb   $0x30,(%edx)
f0105816:	75 05                	jne    f010581d <strtol+0x6a>
		s++, base = 8;
f0105818:	83 c2 01             	add    $0x1,%edx
f010581b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f010581d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0105822:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0105825:	0f b6 0a             	movzbl (%edx),%ecx
f0105828:	8d 71 d0             	lea    -0x30(%ecx),%esi
f010582b:	89 f0                	mov    %esi,%eax
f010582d:	3c 09                	cmp    $0x9,%al
f010582f:	77 08                	ja     f0105839 <strtol+0x86>
			dig = *s - '0';
f0105831:	0f be c9             	movsbl %cl,%ecx
f0105834:	83 e9 30             	sub    $0x30,%ecx
f0105837:	eb 20                	jmp    f0105859 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0105839:	8d 71 9f             	lea    -0x61(%ecx),%esi
f010583c:	89 f0                	mov    %esi,%eax
f010583e:	3c 19                	cmp    $0x19,%al
f0105840:	77 08                	ja     f010584a <strtol+0x97>
			dig = *s - 'a' + 10;
f0105842:	0f be c9             	movsbl %cl,%ecx
f0105845:	83 e9 57             	sub    $0x57,%ecx
f0105848:	eb 0f                	jmp    f0105859 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f010584a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f010584d:	89 f0                	mov    %esi,%eax
f010584f:	3c 19                	cmp    $0x19,%al
f0105851:	77 16                	ja     f0105869 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0105853:	0f be c9             	movsbl %cl,%ecx
f0105856:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0105859:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f010585c:	7d 0f                	jge    f010586d <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f010585e:	83 c2 01             	add    $0x1,%edx
f0105861:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0105865:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0105867:	eb bc                	jmp    f0105825 <strtol+0x72>
f0105869:	89 d8                	mov    %ebx,%eax
f010586b:	eb 02                	jmp    f010586f <strtol+0xbc>
f010586d:	89 d8                	mov    %ebx,%eax

	if (endptr)
f010586f:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105873:	74 05                	je     f010587a <strtol+0xc7>
		*endptr = (char *) s;
f0105875:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105878:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f010587a:	f7 d8                	neg    %eax
f010587c:	85 ff                	test   %edi,%edi
f010587e:	0f 44 c3             	cmove  %ebx,%eax
}
f0105881:	5b                   	pop    %ebx
f0105882:	5e                   	pop    %esi
f0105883:	5f                   	pop    %edi
f0105884:	5d                   	pop    %ebp
f0105885:	c3                   	ret    
f0105886:	66 90                	xchg   %ax,%ax

f0105888 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0105888:	fa                   	cli    

	xorw    %ax, %ax
f0105889:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010588b:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f010588d:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f010588f:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105891:	0f 01 16             	lgdtl  (%esi)
f0105894:	74 70                	je     f0105906 <mpentry_end+0x4>
	movl    %cr0, %eax
f0105896:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0105899:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f010589d:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01058a0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01058a6:	08 00                	or     %al,(%eax)

f01058a8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01058a8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01058ac:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01058ae:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01058b0:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01058b2:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01058b6:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01058b8:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01058ba:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f01058bf:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01058c2:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01058c5:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01058ca:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01058cd:	8b 25 04 bf 22 f0    	mov    0xf022bf04,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01058d3:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01058d8:	b8 e2 01 10 f0       	mov    $0xf01001e2,%eax
	call    *%eax
f01058dd:	ff d0                	call   *%eax

f01058df <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f01058df:	eb fe                	jmp    f01058df <spin>
f01058e1:	8d 76 00             	lea    0x0(%esi),%esi

f01058e4 <gdt>:
	...
f01058ec:	ff                   	(bad)  
f01058ed:	ff 00                	incl   (%eax)
f01058ef:	00 00                	add    %al,(%eax)
f01058f1:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f01058f8:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f01058fc <gdtdesc>:
f01058fc:	17                   	pop    %ss
f01058fd:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105902 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105902:	90                   	nop
f0105903:	66 90                	xchg   %ax,%ax
f0105905:	66 90                	xchg   %ax,%ax
f0105907:	66 90                	xchg   %ax,%ax
f0105909:	66 90                	xchg   %ax,%ax
f010590b:	66 90                	xchg   %ax,%ax
f010590d:	66 90                	xchg   %ax,%ax
f010590f:	90                   	nop

f0105910 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105910:	55                   	push   %ebp
f0105911:	89 e5                	mov    %esp,%ebp
f0105913:	56                   	push   %esi
f0105914:	53                   	push   %ebx
f0105915:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105918:	8b 0d 08 bf 22 f0    	mov    0xf022bf08,%ecx
f010591e:	89 c3                	mov    %eax,%ebx
f0105920:	c1 eb 0c             	shr    $0xc,%ebx
f0105923:	39 cb                	cmp    %ecx,%ebx
f0105925:	72 20                	jb     f0105947 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105927:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010592b:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0105932:	f0 
f0105933:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f010593a:	00 
f010593b:	c7 04 24 45 80 10 f0 	movl   $0xf0108045,(%esp)
f0105942:	e8 f9 a6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105947:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f010594d:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010594f:	89 c2                	mov    %eax,%edx
f0105951:	c1 ea 0c             	shr    $0xc,%edx
f0105954:	39 d1                	cmp    %edx,%ecx
f0105956:	77 20                	ja     f0105978 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105958:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010595c:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0105963:	f0 
f0105964:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f010596b:	00 
f010596c:	c7 04 24 45 80 10 f0 	movl   $0xf0108045,(%esp)
f0105973:	e8 c8 a6 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105978:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010597e:	eb 36                	jmp    f01059b6 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105980:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105987:	00 
f0105988:	c7 44 24 04 55 80 10 	movl   $0xf0108055,0x4(%esp)
f010598f:	f0 
f0105990:	89 1c 24             	mov    %ebx,(%esp)
f0105993:	e8 c5 fd ff ff       	call   f010575d <memcmp>
f0105998:	85 c0                	test   %eax,%eax
f010599a:	75 17                	jne    f01059b3 <mpsearch1+0xa3>
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010599c:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f01059a1:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01059a5:	01 c8                	add    %ecx,%eax
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01059a7:	83 c2 01             	add    $0x1,%edx
f01059aa:	83 fa 10             	cmp    $0x10,%edx
f01059ad:	75 f2                	jne    f01059a1 <mpsearch1+0x91>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01059af:	84 c0                	test   %al,%al
f01059b1:	74 0e                	je     f01059c1 <mpsearch1+0xb1>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01059b3:	83 c3 10             	add    $0x10,%ebx
f01059b6:	39 f3                	cmp    %esi,%ebx
f01059b8:	72 c6                	jb     f0105980 <mpsearch1+0x70>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01059ba:	b8 00 00 00 00       	mov    $0x0,%eax
f01059bf:	eb 02                	jmp    f01059c3 <mpsearch1+0xb3>
f01059c1:	89 d8                	mov    %ebx,%eax
}
f01059c3:	83 c4 10             	add    $0x10,%esp
f01059c6:	5b                   	pop    %ebx
f01059c7:	5e                   	pop    %esi
f01059c8:	5d                   	pop    %ebp
f01059c9:	c3                   	ret    

f01059ca <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01059ca:	55                   	push   %ebp
f01059cb:	89 e5                	mov    %esp,%ebp
f01059cd:	57                   	push   %edi
f01059ce:	56                   	push   %esi
f01059cf:	53                   	push   %ebx
f01059d0:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01059d3:	c7 05 c0 c3 22 f0 20 	movl   $0xf022c020,0xf022c3c0
f01059da:	c0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01059dd:	83 3d 08 bf 22 f0 00 	cmpl   $0x0,0xf022bf08
f01059e4:	75 24                	jne    f0105a0a <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01059e6:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f01059ed:	00 
f01059ee:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f01059f5:	f0 
f01059f6:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f01059fd:	00 
f01059fe:	c7 04 24 45 80 10 f0 	movl   $0xf0108045,(%esp)
f0105a05:	e8 36 a6 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105a0a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105a11:	85 c0                	test   %eax,%eax
f0105a13:	74 16                	je     f0105a2b <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0105a15:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105a18:	ba 00 04 00 00       	mov    $0x400,%edx
f0105a1d:	e8 ee fe ff ff       	call   f0105910 <mpsearch1>
f0105a22:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105a25:	85 c0                	test   %eax,%eax
f0105a27:	75 3c                	jne    f0105a65 <mp_init+0x9b>
f0105a29:	eb 20                	jmp    f0105a4b <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105a2b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0105a32:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0105a35:	2d 00 04 00 00       	sub    $0x400,%eax
f0105a3a:	ba 00 04 00 00       	mov    $0x400,%edx
f0105a3f:	e8 cc fe ff ff       	call   f0105910 <mpsearch1>
f0105a44:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0105a47:	85 c0                	test   %eax,%eax
f0105a49:	75 1a                	jne    f0105a65 <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105a4b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a50:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0105a55:	e8 b6 fe ff ff       	call   f0105910 <mpsearch1>
f0105a5a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105a5d:	85 c0                	test   %eax,%eax
f0105a5f:	0f 84 54 02 00 00    	je     f0105cb9 <mp_init+0x2ef>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0105a65:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105a68:	8b 70 04             	mov    0x4(%eax),%esi
f0105a6b:	85 f6                	test   %esi,%esi
f0105a6d:	74 06                	je     f0105a75 <mp_init+0xab>
f0105a6f:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0105a73:	74 11                	je     f0105a86 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0105a75:	c7 04 24 b8 7e 10 f0 	movl   $0xf0107eb8,(%esp)
f0105a7c:	e8 8b e6 ff ff       	call   f010410c <cprintf>
f0105a81:	e9 33 02 00 00       	jmp    f0105cb9 <mp_init+0x2ef>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105a86:	89 f0                	mov    %esi,%eax
f0105a88:	c1 e8 0c             	shr    $0xc,%eax
f0105a8b:	3b 05 08 bf 22 f0    	cmp    0xf022bf08,%eax
f0105a91:	72 20                	jb     f0105ab3 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105a93:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0105a97:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0105a9e:	f0 
f0105a9f:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0105aa6:	00 
f0105aa7:	c7 04 24 45 80 10 f0 	movl   $0xf0108045,(%esp)
f0105aae:	e8 8d a5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105ab3:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0105ab9:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0105ac0:	00 
f0105ac1:	c7 44 24 04 5a 80 10 	movl   $0xf010805a,0x4(%esp)
f0105ac8:	f0 
f0105ac9:	89 1c 24             	mov    %ebx,(%esp)
f0105acc:	e8 8c fc ff ff       	call   f010575d <memcmp>
f0105ad1:	85 c0                	test   %eax,%eax
f0105ad3:	74 11                	je     f0105ae6 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105ad5:	c7 04 24 e8 7e 10 f0 	movl   $0xf0107ee8,(%esp)
f0105adc:	e8 2b e6 ff ff       	call   f010410c <cprintf>
f0105ae1:	e9 d3 01 00 00       	jmp    f0105cb9 <mp_init+0x2ef>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105ae6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0105aea:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0105aee:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105af1:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105af6:	b8 00 00 00 00       	mov    $0x0,%eax
f0105afb:	eb 0d                	jmp    f0105b0a <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f0105afd:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105b04:	f0 
f0105b05:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105b07:	83 c0 01             	add    $0x1,%eax
f0105b0a:	39 c7                	cmp    %eax,%edi
f0105b0c:	7f ef                	jg     f0105afd <mp_init+0x133>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105b0e:	84 d2                	test   %dl,%dl
f0105b10:	74 11                	je     f0105b23 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105b12:	c7 04 24 1c 7f 10 f0 	movl   $0xf0107f1c,(%esp)
f0105b19:	e8 ee e5 ff ff       	call   f010410c <cprintf>
f0105b1e:	e9 96 01 00 00       	jmp    f0105cb9 <mp_init+0x2ef>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105b23:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0105b27:	3c 04                	cmp    $0x4,%al
f0105b29:	74 1f                	je     f0105b4a <mp_init+0x180>
f0105b2b:	3c 01                	cmp    $0x1,%al
f0105b2d:	8d 76 00             	lea    0x0(%esi),%esi
f0105b30:	74 18                	je     f0105b4a <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105b32:	0f b6 c0             	movzbl %al,%eax
f0105b35:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105b39:	c7 04 24 40 7f 10 f0 	movl   $0xf0107f40,(%esp)
f0105b40:	e8 c7 e5 ff ff       	call   f010410c <cprintf>
f0105b45:	e9 6f 01 00 00       	jmp    f0105cb9 <mp_init+0x2ef>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105b4a:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f0105b4e:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f0105b52:	01 df                	add    %ebx,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105b54:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105b59:	b8 00 00 00 00       	mov    $0x0,%eax
f0105b5e:	eb 09                	jmp    f0105b69 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0105b60:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0105b64:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105b66:	83 c0 01             	add    $0x1,%eax
f0105b69:	39 c6                	cmp    %eax,%esi
f0105b6b:	7f f3                	jg     f0105b60 <mp_init+0x196>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105b6d:	02 53 2a             	add    0x2a(%ebx),%dl
f0105b70:	84 d2                	test   %dl,%dl
f0105b72:	74 11                	je     f0105b85 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0105b74:	c7 04 24 60 7f 10 f0 	movl   $0xf0107f60,(%esp)
f0105b7b:	e8 8c e5 ff ff       	call   f010410c <cprintf>
f0105b80:	e9 34 01 00 00       	jmp    f0105cb9 <mp_init+0x2ef>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0105b85:	85 db                	test   %ebx,%ebx
f0105b87:	0f 84 2c 01 00 00    	je     f0105cb9 <mp_init+0x2ef>
		return;
	ismp = 1;
f0105b8d:	c7 05 00 c0 22 f0 01 	movl   $0x1,0xf022c000
f0105b94:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105b97:	8b 43 24             	mov    0x24(%ebx),%eax
f0105b9a:	a3 00 d0 26 f0       	mov    %eax,0xf026d000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105b9f:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0105ba2:	be 00 00 00 00       	mov    $0x0,%esi
f0105ba7:	e9 86 00 00 00       	jmp    f0105c32 <mp_init+0x268>
		switch (*p) {
f0105bac:	0f b6 07             	movzbl (%edi),%eax
f0105baf:	84 c0                	test   %al,%al
f0105bb1:	74 06                	je     f0105bb9 <mp_init+0x1ef>
f0105bb3:	3c 04                	cmp    $0x4,%al
f0105bb5:	77 57                	ja     f0105c0e <mp_init+0x244>
f0105bb7:	eb 50                	jmp    f0105c09 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105bb9:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105bbd:	8d 76 00             	lea    0x0(%esi),%esi
f0105bc0:	74 11                	je     f0105bd3 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f0105bc2:	6b 05 c4 c3 22 f0 74 	imul   $0x74,0xf022c3c4,%eax
f0105bc9:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0105bce:	a3 c0 c3 22 f0       	mov    %eax,0xf022c3c0
			if (ncpu < NCPU) {
f0105bd3:	a1 c4 c3 22 f0       	mov    0xf022c3c4,%eax
f0105bd8:	83 f8 07             	cmp    $0x7,%eax
f0105bdb:	7f 13                	jg     f0105bf0 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f0105bdd:	6b d0 74             	imul   $0x74,%eax,%edx
f0105be0:	88 82 20 c0 22 f0    	mov    %al,-0xfdd3fe0(%edx)
				ncpu++;
f0105be6:	83 c0 01             	add    $0x1,%eax
f0105be9:	a3 c4 c3 22 f0       	mov    %eax,0xf022c3c4
f0105bee:	eb 14                	jmp    f0105c04 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105bf0:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0105bf4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105bf8:	c7 04 24 90 7f 10 f0 	movl   $0xf0107f90,(%esp)
f0105bff:	e8 08 e5 ff ff       	call   f010410c <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0105c04:	83 c7 14             	add    $0x14,%edi
			continue;
f0105c07:	eb 26                	jmp    f0105c2f <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105c09:	83 c7 08             	add    $0x8,%edi
			continue;
f0105c0c:	eb 21                	jmp    f0105c2f <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105c0e:	0f b6 c0             	movzbl %al,%eax
f0105c11:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105c15:	c7 04 24 b8 7f 10 f0 	movl   $0xf0107fb8,(%esp)
f0105c1c:	e8 eb e4 ff ff       	call   f010410c <cprintf>
			ismp = 0;
f0105c21:	c7 05 00 c0 22 f0 00 	movl   $0x0,0xf022c000
f0105c28:	00 00 00 
			i = conf->entry;
f0105c2b:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105c2f:	83 c6 01             	add    $0x1,%esi
f0105c32:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0105c36:	39 c6                	cmp    %eax,%esi
f0105c38:	0f 82 6e ff ff ff    	jb     f0105bac <mp_init+0x1e2>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105c3e:	a1 c0 c3 22 f0       	mov    0xf022c3c0,%eax
f0105c43:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105c4a:	83 3d 00 c0 22 f0 00 	cmpl   $0x0,0xf022c000
f0105c51:	75 22                	jne    f0105c75 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0105c53:	c7 05 c4 c3 22 f0 01 	movl   $0x1,0xf022c3c4
f0105c5a:	00 00 00 
		lapicaddr = 0;
f0105c5d:	c7 05 00 d0 26 f0 00 	movl   $0x0,0xf026d000
f0105c64:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105c67:	c7 04 24 d8 7f 10 f0 	movl   $0xf0107fd8,(%esp)
f0105c6e:	e8 99 e4 ff ff       	call   f010410c <cprintf>
		return;
f0105c73:	eb 44                	jmp    f0105cb9 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105c75:	8b 15 c4 c3 22 f0    	mov    0xf022c3c4,%edx
f0105c7b:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105c7f:	0f b6 00             	movzbl (%eax),%eax
f0105c82:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105c86:	c7 04 24 5f 80 10 f0 	movl   $0xf010805f,(%esp)
f0105c8d:	e8 7a e4 ff ff       	call   f010410c <cprintf>

	if (mp->imcrp) {
f0105c92:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105c95:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105c99:	74 1e                	je     f0105cb9 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105c9b:	c7 04 24 04 80 10 f0 	movl   $0xf0108004,(%esp)
f0105ca2:	e8 65 e4 ff ff       	call   f010410c <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105ca7:	ba 22 00 00 00       	mov    $0x22,%edx
f0105cac:	b8 70 00 00 00       	mov    $0x70,%eax
f0105cb1:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0105cb2:	b2 23                	mov    $0x23,%dl
f0105cb4:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105cb5:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105cb8:	ee                   	out    %al,(%dx)
	}
}
f0105cb9:	83 c4 2c             	add    $0x2c,%esp
f0105cbc:	5b                   	pop    %ebx
f0105cbd:	5e                   	pop    %esi
f0105cbe:	5f                   	pop    %edi
f0105cbf:	5d                   	pop    %ebp
f0105cc0:	c3                   	ret    

f0105cc1 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0105cc1:	55                   	push   %ebp
f0105cc2:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105cc4:	8b 0d 04 d0 26 f0    	mov    0xf026d004,%ecx
f0105cca:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0105ccd:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0105ccf:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0105cd4:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105cd7:	5d                   	pop    %ebp
f0105cd8:	c3                   	ret    

f0105cd9 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105cd9:	55                   	push   %ebp
f0105cda:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0105cdc:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0105ce1:	85 c0                	test   %eax,%eax
f0105ce3:	74 08                	je     f0105ced <cpunum+0x14>
		return lapic[ID] >> 24;
f0105ce5:	8b 40 20             	mov    0x20(%eax),%eax
f0105ce8:	c1 e8 18             	shr    $0x18,%eax
f0105ceb:	eb 05                	jmp    f0105cf2 <cpunum+0x19>
	return 0;
f0105ced:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105cf2:	5d                   	pop    %ebp
f0105cf3:	c3                   	ret    

f0105cf4 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105cf4:	a1 00 d0 26 f0       	mov    0xf026d000,%eax
f0105cf9:	85 c0                	test   %eax,%eax
f0105cfb:	0f 84 23 01 00 00    	je     f0105e24 <lapic_init+0x130>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0105d01:	55                   	push   %ebp
f0105d02:	89 e5                	mov    %esp,%ebp
f0105d04:	83 ec 18             	sub    $0x18,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105d07:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0105d0e:	00 
f0105d0f:	89 04 24             	mov    %eax,(%esp)
f0105d12:	e8 76 b8 ff ff       	call   f010158d <mmio_map_region>
f0105d17:	a3 04 d0 26 f0       	mov    %eax,0xf026d004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105d1c:	ba 27 01 00 00       	mov    $0x127,%edx
f0105d21:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0105d26:	e8 96 ff ff ff       	call   f0105cc1 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105d2b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105d30:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0105d35:	e8 87 ff ff ff       	call   f0105cc1 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105d3a:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105d3f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0105d44:	e8 78 ff ff ff       	call   f0105cc1 <lapicw>
	lapicw(TICR, 10000000); 
f0105d49:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105d4e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0105d53:	e8 69 ff ff ff       	call   f0105cc1 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105d58:	e8 7c ff ff ff       	call   f0105cd9 <cpunum>
f0105d5d:	6b c0 74             	imul   $0x74,%eax,%eax
f0105d60:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0105d65:	39 05 c0 c3 22 f0    	cmp    %eax,0xf022c3c0
f0105d6b:	74 0f                	je     f0105d7c <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f0105d6d:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105d72:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105d77:	e8 45 ff ff ff       	call   f0105cc1 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105d7c:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105d81:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105d86:	e8 36 ff ff ff       	call   f0105cc1 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105d8b:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f0105d90:	8b 40 30             	mov    0x30(%eax),%eax
f0105d93:	c1 e8 10             	shr    $0x10,%eax
f0105d96:	3c 03                	cmp    $0x3,%al
f0105d98:	76 0f                	jbe    f0105da9 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f0105d9a:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105d9f:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105da4:	e8 18 ff ff ff       	call   f0105cc1 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105da9:	ba 33 00 00 00       	mov    $0x33,%edx
f0105dae:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105db3:	e8 09 ff ff ff       	call   f0105cc1 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105db8:	ba 00 00 00 00       	mov    $0x0,%edx
f0105dbd:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105dc2:	e8 fa fe ff ff       	call   f0105cc1 <lapicw>
	lapicw(ESR, 0);
f0105dc7:	ba 00 00 00 00       	mov    $0x0,%edx
f0105dcc:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105dd1:	e8 eb fe ff ff       	call   f0105cc1 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105dd6:	ba 00 00 00 00       	mov    $0x0,%edx
f0105ddb:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105de0:	e8 dc fe ff ff       	call   f0105cc1 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105de5:	ba 00 00 00 00       	mov    $0x0,%edx
f0105dea:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105def:	e8 cd fe ff ff       	call   f0105cc1 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105df4:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105df9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105dfe:	e8 be fe ff ff       	call   f0105cc1 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105e03:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f0105e09:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105e0f:	f6 c4 10             	test   $0x10,%ah
f0105e12:	75 f5                	jne    f0105e09 <lapic_init+0x115>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105e14:	ba 00 00 00 00       	mov    $0x0,%edx
f0105e19:	b8 20 00 00 00       	mov    $0x20,%eax
f0105e1e:	e8 9e fe ff ff       	call   f0105cc1 <lapicw>
}
f0105e23:	c9                   	leave  
f0105e24:	f3 c3                	repz ret 

f0105e26 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105e26:	83 3d 04 d0 26 f0 00 	cmpl   $0x0,0xf026d004
f0105e2d:	74 13                	je     f0105e42 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105e2f:	55                   	push   %ebp
f0105e30:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105e32:	ba 00 00 00 00       	mov    $0x0,%edx
f0105e37:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105e3c:	e8 80 fe ff ff       	call   f0105cc1 <lapicw>
}
f0105e41:	5d                   	pop    %ebp
f0105e42:	f3 c3                	repz ret 

f0105e44 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105e44:	55                   	push   %ebp
f0105e45:	89 e5                	mov    %esp,%ebp
f0105e47:	56                   	push   %esi
f0105e48:	53                   	push   %ebx
f0105e49:	83 ec 10             	sub    $0x10,%esp
f0105e4c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0105e4f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105e52:	ba 70 00 00 00       	mov    $0x70,%edx
f0105e57:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105e5c:	ee                   	out    %al,(%dx)
f0105e5d:	b2 71                	mov    $0x71,%dl
f0105e5f:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105e64:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105e65:	83 3d 08 bf 22 f0 00 	cmpl   $0x0,0xf022bf08
f0105e6c:	75 24                	jne    f0105e92 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105e6e:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f0105e75:	00 
f0105e76:	c7 44 24 08 e4 63 10 	movl   $0xf01063e4,0x8(%esp)
f0105e7d:	f0 
f0105e7e:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f0105e85:	00 
f0105e86:	c7 04 24 7c 80 10 f0 	movl   $0xf010807c,(%esp)
f0105e8d:	e8 ae a1 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105e92:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105e99:	00 00 
	wrv[1] = addr >> 4;
f0105e9b:	89 f0                	mov    %esi,%eax
f0105e9d:	c1 e8 04             	shr    $0x4,%eax
f0105ea0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105ea6:	c1 e3 18             	shl    $0x18,%ebx
f0105ea9:	89 da                	mov    %ebx,%edx
f0105eab:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105eb0:	e8 0c fe ff ff       	call   f0105cc1 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105eb5:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105eba:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105ebf:	e8 fd fd ff ff       	call   f0105cc1 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105ec4:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105ec9:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105ece:	e8 ee fd ff ff       	call   f0105cc1 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105ed3:	c1 ee 0c             	shr    $0xc,%esi
f0105ed6:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105edc:	89 da                	mov    %ebx,%edx
f0105ede:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105ee3:	e8 d9 fd ff ff       	call   f0105cc1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105ee8:	89 f2                	mov    %esi,%edx
f0105eea:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105eef:	e8 cd fd ff ff       	call   f0105cc1 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105ef4:	89 da                	mov    %ebx,%edx
f0105ef6:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105efb:	e8 c1 fd ff ff       	call   f0105cc1 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105f00:	89 f2                	mov    %esi,%edx
f0105f02:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105f07:	e8 b5 fd ff ff       	call   f0105cc1 <lapicw>
		microdelay(200);
	}
}
f0105f0c:	83 c4 10             	add    $0x10,%esp
f0105f0f:	5b                   	pop    %ebx
f0105f10:	5e                   	pop    %esi
f0105f11:	5d                   	pop    %ebp
f0105f12:	c3                   	ret    

f0105f13 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105f13:	55                   	push   %ebp
f0105f14:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105f16:	8b 55 08             	mov    0x8(%ebp),%edx
f0105f19:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105f1f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105f24:	e8 98 fd ff ff       	call   f0105cc1 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105f29:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f0105f2f:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105f35:	f6 c4 10             	test   $0x10,%ah
f0105f38:	75 f5                	jne    f0105f2f <lapic_ipi+0x1c>
		;
}
f0105f3a:	5d                   	pop    %ebp
f0105f3b:	c3                   	ret    

f0105f3c <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105f3c:	55                   	push   %ebp
f0105f3d:	89 e5                	mov    %esp,%ebp
f0105f3f:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105f42:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105f48:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105f4b:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105f4e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105f55:	5d                   	pop    %ebp
f0105f56:	c3                   	ret    

f0105f57 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105f57:	55                   	push   %ebp
f0105f58:	89 e5                	mov    %esp,%ebp
f0105f5a:	56                   	push   %esi
f0105f5b:	53                   	push   %ebx
f0105f5c:	83 ec 20             	sub    $0x20,%esp
f0105f5f:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105f62:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105f65:	75 07                	jne    f0105f6e <spin_lock+0x17>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105f67:	ba 01 00 00 00       	mov    $0x1,%edx
f0105f6c:	eb 42                	jmp    f0105fb0 <spin_lock+0x59>
f0105f6e:	8b 73 08             	mov    0x8(%ebx),%esi
f0105f71:	e8 63 fd ff ff       	call   f0105cd9 <cpunum>
f0105f76:	6b c0 74             	imul   $0x74,%eax,%eax
f0105f79:	05 20 c0 22 f0       	add    $0xf022c020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105f7e:	39 c6                	cmp    %eax,%esi
f0105f80:	75 e5                	jne    f0105f67 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105f82:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105f85:	e8 4f fd ff ff       	call   f0105cd9 <cpunum>
f0105f8a:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f0105f8e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105f92:	c7 44 24 08 8c 80 10 	movl   $0xf010808c,0x8(%esp)
f0105f99:	f0 
f0105f9a:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f0105fa1:	00 
f0105fa2:	c7 04 24 f0 80 10 f0 	movl   $0xf01080f0,(%esp)
f0105fa9:	e8 92 a0 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105fae:	f3 90                	pause  
f0105fb0:	89 d0                	mov    %edx,%eax
f0105fb2:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105fb5:	85 c0                	test   %eax,%eax
f0105fb7:	75 f5                	jne    f0105fae <spin_lock+0x57>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105fb9:	e8 1b fd ff ff       	call   f0105cd9 <cpunum>
f0105fbe:	6b c0 74             	imul   $0x74,%eax,%eax
f0105fc1:	05 20 c0 22 f0       	add    $0xf022c020,%eax
f0105fc6:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105fc9:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0105fcc:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105fce:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105fd3:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105fd9:	76 12                	jbe    f0105fed <spin_lock+0x96>
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105fdb:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105fde:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105fe1:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105fe3:	83 c0 01             	add    $0x1,%eax
f0105fe6:	83 f8 0a             	cmp    $0xa,%eax
f0105fe9:	75 e8                	jne    f0105fd3 <spin_lock+0x7c>
f0105feb:	eb 0f                	jmp    f0105ffc <spin_lock+0xa5>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105fed:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105ff4:	83 c0 01             	add    $0x1,%eax
f0105ff7:	83 f8 09             	cmp    $0x9,%eax
f0105ffa:	7e f1                	jle    f0105fed <spin_lock+0x96>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105ffc:	83 c4 20             	add    $0x20,%esp
f0105fff:	5b                   	pop    %ebx
f0106000:	5e                   	pop    %esi
f0106001:	5d                   	pop    %ebp
f0106002:	c3                   	ret    

f0106003 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0106003:	55                   	push   %ebp
f0106004:	89 e5                	mov    %esp,%ebp
f0106006:	57                   	push   %edi
f0106007:	56                   	push   %esi
f0106008:	53                   	push   %ebx
f0106009:	83 ec 6c             	sub    $0x6c,%esp
f010600c:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010600f:	83 3e 00             	cmpl   $0x0,(%esi)
f0106012:	74 18                	je     f010602c <spin_unlock+0x29>
f0106014:	8b 5e 08             	mov    0x8(%esi),%ebx
f0106017:	e8 bd fc ff ff       	call   f0105cd9 <cpunum>
f010601c:	6b c0 74             	imul   $0x74,%eax,%eax
f010601f:	05 20 c0 22 f0       	add    $0xf022c020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0106024:	39 c3                	cmp    %eax,%ebx
f0106026:	0f 84 ce 00 00 00    	je     f01060fa <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010602c:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f0106033:	00 
f0106034:	8d 46 0c             	lea    0xc(%esi),%eax
f0106037:	89 44 24 04          	mov    %eax,0x4(%esp)
f010603b:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010603e:	89 1c 24             	mov    %ebx,(%esp)
f0106041:	e8 8e f6 ff ff       	call   f01056d4 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0106046:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0106049:	0f b6 38             	movzbl (%eax),%edi
f010604c:	8b 76 04             	mov    0x4(%esi),%esi
f010604f:	e8 85 fc ff ff       	call   f0105cd9 <cpunum>
f0106054:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106058:	89 74 24 08          	mov    %esi,0x8(%esp)
f010605c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106060:	c7 04 24 b8 80 10 f0 	movl   $0xf01080b8,(%esp)
f0106067:	e8 a0 e0 ff ff       	call   f010410c <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f010606c:	8d 7d a8             	lea    -0x58(%ebp),%edi
f010606f:	eb 65                	jmp    f01060d6 <spin_unlock+0xd3>
f0106071:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0106075:	89 04 24             	mov    %eax,(%esp)
f0106078:	e8 cf ea ff ff       	call   f0104b4c <debuginfo_eip>
f010607d:	85 c0                	test   %eax,%eax
f010607f:	78 39                	js     f01060ba <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0106081:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0106083:	89 c2                	mov    %eax,%edx
f0106085:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0106088:	89 54 24 18          	mov    %edx,0x18(%esp)
f010608c:	8b 55 b0             	mov    -0x50(%ebp),%edx
f010608f:	89 54 24 14          	mov    %edx,0x14(%esp)
f0106093:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f0106096:	89 54 24 10          	mov    %edx,0x10(%esp)
f010609a:	8b 55 ac             	mov    -0x54(%ebp),%edx
f010609d:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01060a1:	8b 55 a8             	mov    -0x58(%ebp),%edx
f01060a4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01060a8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01060ac:	c7 04 24 00 81 10 f0 	movl   $0xf0108100,(%esp)
f01060b3:	e8 54 e0 ff ff       	call   f010410c <cprintf>
f01060b8:	eb 12                	jmp    f01060cc <spin_unlock+0xc9>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f01060ba:	8b 06                	mov    (%esi),%eax
f01060bc:	89 44 24 04          	mov    %eax,0x4(%esp)
f01060c0:	c7 04 24 17 81 10 f0 	movl   $0xf0108117,(%esp)
f01060c7:	e8 40 e0 ff ff       	call   f010410c <cprintf>
f01060cc:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f01060cf:	8d 45 e8             	lea    -0x18(%ebp),%eax
f01060d2:	39 c3                	cmp    %eax,%ebx
f01060d4:	74 08                	je     f01060de <spin_unlock+0xdb>
f01060d6:	89 de                	mov    %ebx,%esi
f01060d8:	8b 03                	mov    (%ebx),%eax
f01060da:	85 c0                	test   %eax,%eax
f01060dc:	75 93                	jne    f0106071 <spin_unlock+0x6e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f01060de:	c7 44 24 08 1f 81 10 	movl   $0xf010811f,0x8(%esp)
f01060e5:	f0 
f01060e6:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f01060ed:	00 
f01060ee:	c7 04 24 f0 80 10 f0 	movl   $0xf01080f0,(%esp)
f01060f5:	e8 46 9f ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f01060fa:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0106101:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0106108:	b8 00 00 00 00       	mov    $0x0,%eax
f010610d:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0106110:	83 c4 6c             	add    $0x6c,%esp
f0106113:	5b                   	pop    %ebx
f0106114:	5e                   	pop    %esi
f0106115:	5f                   	pop    %edi
f0106116:	5d                   	pop    %ebp
f0106117:	c3                   	ret    
f0106118:	66 90                	xchg   %ax,%ax
f010611a:	66 90                	xchg   %ax,%ax
f010611c:	66 90                	xchg   %ax,%ax
f010611e:	66 90                	xchg   %ax,%ax

f0106120 <__udivdi3>:
f0106120:	55                   	push   %ebp
f0106121:	57                   	push   %edi
f0106122:	56                   	push   %esi
f0106123:	83 ec 0c             	sub    $0xc,%esp
f0106126:	8b 44 24 28          	mov    0x28(%esp),%eax
f010612a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010612e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0106132:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0106136:	85 c0                	test   %eax,%eax
f0106138:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010613c:	89 ea                	mov    %ebp,%edx
f010613e:	89 0c 24             	mov    %ecx,(%esp)
f0106141:	75 2d                	jne    f0106170 <__udivdi3+0x50>
f0106143:	39 e9                	cmp    %ebp,%ecx
f0106145:	77 61                	ja     f01061a8 <__udivdi3+0x88>
f0106147:	85 c9                	test   %ecx,%ecx
f0106149:	89 ce                	mov    %ecx,%esi
f010614b:	75 0b                	jne    f0106158 <__udivdi3+0x38>
f010614d:	b8 01 00 00 00       	mov    $0x1,%eax
f0106152:	31 d2                	xor    %edx,%edx
f0106154:	f7 f1                	div    %ecx
f0106156:	89 c6                	mov    %eax,%esi
f0106158:	31 d2                	xor    %edx,%edx
f010615a:	89 e8                	mov    %ebp,%eax
f010615c:	f7 f6                	div    %esi
f010615e:	89 c5                	mov    %eax,%ebp
f0106160:	89 f8                	mov    %edi,%eax
f0106162:	f7 f6                	div    %esi
f0106164:	89 ea                	mov    %ebp,%edx
f0106166:	83 c4 0c             	add    $0xc,%esp
f0106169:	5e                   	pop    %esi
f010616a:	5f                   	pop    %edi
f010616b:	5d                   	pop    %ebp
f010616c:	c3                   	ret    
f010616d:	8d 76 00             	lea    0x0(%esi),%esi
f0106170:	39 e8                	cmp    %ebp,%eax
f0106172:	77 24                	ja     f0106198 <__udivdi3+0x78>
f0106174:	0f bd e8             	bsr    %eax,%ebp
f0106177:	83 f5 1f             	xor    $0x1f,%ebp
f010617a:	75 3c                	jne    f01061b8 <__udivdi3+0x98>
f010617c:	8b 74 24 04          	mov    0x4(%esp),%esi
f0106180:	39 34 24             	cmp    %esi,(%esp)
f0106183:	0f 86 9f 00 00 00    	jbe    f0106228 <__udivdi3+0x108>
f0106189:	39 d0                	cmp    %edx,%eax
f010618b:	0f 82 97 00 00 00    	jb     f0106228 <__udivdi3+0x108>
f0106191:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0106198:	31 d2                	xor    %edx,%edx
f010619a:	31 c0                	xor    %eax,%eax
f010619c:	83 c4 0c             	add    $0xc,%esp
f010619f:	5e                   	pop    %esi
f01061a0:	5f                   	pop    %edi
f01061a1:	5d                   	pop    %ebp
f01061a2:	c3                   	ret    
f01061a3:	90                   	nop
f01061a4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01061a8:	89 f8                	mov    %edi,%eax
f01061aa:	f7 f1                	div    %ecx
f01061ac:	31 d2                	xor    %edx,%edx
f01061ae:	83 c4 0c             	add    $0xc,%esp
f01061b1:	5e                   	pop    %esi
f01061b2:	5f                   	pop    %edi
f01061b3:	5d                   	pop    %ebp
f01061b4:	c3                   	ret    
f01061b5:	8d 76 00             	lea    0x0(%esi),%esi
f01061b8:	89 e9                	mov    %ebp,%ecx
f01061ba:	8b 3c 24             	mov    (%esp),%edi
f01061bd:	d3 e0                	shl    %cl,%eax
f01061bf:	89 c6                	mov    %eax,%esi
f01061c1:	b8 20 00 00 00       	mov    $0x20,%eax
f01061c6:	29 e8                	sub    %ebp,%eax
f01061c8:	89 c1                	mov    %eax,%ecx
f01061ca:	d3 ef                	shr    %cl,%edi
f01061cc:	89 e9                	mov    %ebp,%ecx
f01061ce:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01061d2:	8b 3c 24             	mov    (%esp),%edi
f01061d5:	09 74 24 08          	or     %esi,0x8(%esp)
f01061d9:	89 d6                	mov    %edx,%esi
f01061db:	d3 e7                	shl    %cl,%edi
f01061dd:	89 c1                	mov    %eax,%ecx
f01061df:	89 3c 24             	mov    %edi,(%esp)
f01061e2:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01061e6:	d3 ee                	shr    %cl,%esi
f01061e8:	89 e9                	mov    %ebp,%ecx
f01061ea:	d3 e2                	shl    %cl,%edx
f01061ec:	89 c1                	mov    %eax,%ecx
f01061ee:	d3 ef                	shr    %cl,%edi
f01061f0:	09 d7                	or     %edx,%edi
f01061f2:	89 f2                	mov    %esi,%edx
f01061f4:	89 f8                	mov    %edi,%eax
f01061f6:	f7 74 24 08          	divl   0x8(%esp)
f01061fa:	89 d6                	mov    %edx,%esi
f01061fc:	89 c7                	mov    %eax,%edi
f01061fe:	f7 24 24             	mull   (%esp)
f0106201:	39 d6                	cmp    %edx,%esi
f0106203:	89 14 24             	mov    %edx,(%esp)
f0106206:	72 30                	jb     f0106238 <__udivdi3+0x118>
f0106208:	8b 54 24 04          	mov    0x4(%esp),%edx
f010620c:	89 e9                	mov    %ebp,%ecx
f010620e:	d3 e2                	shl    %cl,%edx
f0106210:	39 c2                	cmp    %eax,%edx
f0106212:	73 05                	jae    f0106219 <__udivdi3+0xf9>
f0106214:	3b 34 24             	cmp    (%esp),%esi
f0106217:	74 1f                	je     f0106238 <__udivdi3+0x118>
f0106219:	89 f8                	mov    %edi,%eax
f010621b:	31 d2                	xor    %edx,%edx
f010621d:	e9 7a ff ff ff       	jmp    f010619c <__udivdi3+0x7c>
f0106222:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0106228:	31 d2                	xor    %edx,%edx
f010622a:	b8 01 00 00 00       	mov    $0x1,%eax
f010622f:	e9 68 ff ff ff       	jmp    f010619c <__udivdi3+0x7c>
f0106234:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106238:	8d 47 ff             	lea    -0x1(%edi),%eax
f010623b:	31 d2                	xor    %edx,%edx
f010623d:	83 c4 0c             	add    $0xc,%esp
f0106240:	5e                   	pop    %esi
f0106241:	5f                   	pop    %edi
f0106242:	5d                   	pop    %ebp
f0106243:	c3                   	ret    
f0106244:	66 90                	xchg   %ax,%ax
f0106246:	66 90                	xchg   %ax,%ax
f0106248:	66 90                	xchg   %ax,%ax
f010624a:	66 90                	xchg   %ax,%ax
f010624c:	66 90                	xchg   %ax,%ax
f010624e:	66 90                	xchg   %ax,%ax

f0106250 <__umoddi3>:
f0106250:	55                   	push   %ebp
f0106251:	57                   	push   %edi
f0106252:	56                   	push   %esi
f0106253:	83 ec 14             	sub    $0x14,%esp
f0106256:	8b 44 24 28          	mov    0x28(%esp),%eax
f010625a:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f010625e:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f0106262:	89 c7                	mov    %eax,%edi
f0106264:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106268:	8b 44 24 30          	mov    0x30(%esp),%eax
f010626c:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0106270:	89 34 24             	mov    %esi,(%esp)
f0106273:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0106277:	85 c0                	test   %eax,%eax
f0106279:	89 c2                	mov    %eax,%edx
f010627b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010627f:	75 17                	jne    f0106298 <__umoddi3+0x48>
f0106281:	39 fe                	cmp    %edi,%esi
f0106283:	76 4b                	jbe    f01062d0 <__umoddi3+0x80>
f0106285:	89 c8                	mov    %ecx,%eax
f0106287:	89 fa                	mov    %edi,%edx
f0106289:	f7 f6                	div    %esi
f010628b:	89 d0                	mov    %edx,%eax
f010628d:	31 d2                	xor    %edx,%edx
f010628f:	83 c4 14             	add    $0x14,%esp
f0106292:	5e                   	pop    %esi
f0106293:	5f                   	pop    %edi
f0106294:	5d                   	pop    %ebp
f0106295:	c3                   	ret    
f0106296:	66 90                	xchg   %ax,%ax
f0106298:	39 f8                	cmp    %edi,%eax
f010629a:	77 54                	ja     f01062f0 <__umoddi3+0xa0>
f010629c:	0f bd e8             	bsr    %eax,%ebp
f010629f:	83 f5 1f             	xor    $0x1f,%ebp
f01062a2:	75 5c                	jne    f0106300 <__umoddi3+0xb0>
f01062a4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01062a8:	39 3c 24             	cmp    %edi,(%esp)
f01062ab:	0f 87 e7 00 00 00    	ja     f0106398 <__umoddi3+0x148>
f01062b1:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01062b5:	29 f1                	sub    %esi,%ecx
f01062b7:	19 c7                	sbb    %eax,%edi
f01062b9:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01062bd:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01062c1:	8b 44 24 08          	mov    0x8(%esp),%eax
f01062c5:	8b 54 24 0c          	mov    0xc(%esp),%edx
f01062c9:	83 c4 14             	add    $0x14,%esp
f01062cc:	5e                   	pop    %esi
f01062cd:	5f                   	pop    %edi
f01062ce:	5d                   	pop    %ebp
f01062cf:	c3                   	ret    
f01062d0:	85 f6                	test   %esi,%esi
f01062d2:	89 f5                	mov    %esi,%ebp
f01062d4:	75 0b                	jne    f01062e1 <__umoddi3+0x91>
f01062d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01062db:	31 d2                	xor    %edx,%edx
f01062dd:	f7 f6                	div    %esi
f01062df:	89 c5                	mov    %eax,%ebp
f01062e1:	8b 44 24 04          	mov    0x4(%esp),%eax
f01062e5:	31 d2                	xor    %edx,%edx
f01062e7:	f7 f5                	div    %ebp
f01062e9:	89 c8                	mov    %ecx,%eax
f01062eb:	f7 f5                	div    %ebp
f01062ed:	eb 9c                	jmp    f010628b <__umoddi3+0x3b>
f01062ef:	90                   	nop
f01062f0:	89 c8                	mov    %ecx,%eax
f01062f2:	89 fa                	mov    %edi,%edx
f01062f4:	83 c4 14             	add    $0x14,%esp
f01062f7:	5e                   	pop    %esi
f01062f8:	5f                   	pop    %edi
f01062f9:	5d                   	pop    %ebp
f01062fa:	c3                   	ret    
f01062fb:	90                   	nop
f01062fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106300:	8b 04 24             	mov    (%esp),%eax
f0106303:	be 20 00 00 00       	mov    $0x20,%esi
f0106308:	89 e9                	mov    %ebp,%ecx
f010630a:	29 ee                	sub    %ebp,%esi
f010630c:	d3 e2                	shl    %cl,%edx
f010630e:	89 f1                	mov    %esi,%ecx
f0106310:	d3 e8                	shr    %cl,%eax
f0106312:	89 e9                	mov    %ebp,%ecx
f0106314:	89 44 24 04          	mov    %eax,0x4(%esp)
f0106318:	8b 04 24             	mov    (%esp),%eax
f010631b:	09 54 24 04          	or     %edx,0x4(%esp)
f010631f:	89 fa                	mov    %edi,%edx
f0106321:	d3 e0                	shl    %cl,%eax
f0106323:	89 f1                	mov    %esi,%ecx
f0106325:	89 44 24 08          	mov    %eax,0x8(%esp)
f0106329:	8b 44 24 10          	mov    0x10(%esp),%eax
f010632d:	d3 ea                	shr    %cl,%edx
f010632f:	89 e9                	mov    %ebp,%ecx
f0106331:	d3 e7                	shl    %cl,%edi
f0106333:	89 f1                	mov    %esi,%ecx
f0106335:	d3 e8                	shr    %cl,%eax
f0106337:	89 e9                	mov    %ebp,%ecx
f0106339:	09 f8                	or     %edi,%eax
f010633b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010633f:	f7 74 24 04          	divl   0x4(%esp)
f0106343:	d3 e7                	shl    %cl,%edi
f0106345:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0106349:	89 d7                	mov    %edx,%edi
f010634b:	f7 64 24 08          	mull   0x8(%esp)
f010634f:	39 d7                	cmp    %edx,%edi
f0106351:	89 c1                	mov    %eax,%ecx
f0106353:	89 14 24             	mov    %edx,(%esp)
f0106356:	72 2c                	jb     f0106384 <__umoddi3+0x134>
f0106358:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f010635c:	72 22                	jb     f0106380 <__umoddi3+0x130>
f010635e:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0106362:	29 c8                	sub    %ecx,%eax
f0106364:	19 d7                	sbb    %edx,%edi
f0106366:	89 e9                	mov    %ebp,%ecx
f0106368:	89 fa                	mov    %edi,%edx
f010636a:	d3 e8                	shr    %cl,%eax
f010636c:	89 f1                	mov    %esi,%ecx
f010636e:	d3 e2                	shl    %cl,%edx
f0106370:	89 e9                	mov    %ebp,%ecx
f0106372:	d3 ef                	shr    %cl,%edi
f0106374:	09 d0                	or     %edx,%eax
f0106376:	89 fa                	mov    %edi,%edx
f0106378:	83 c4 14             	add    $0x14,%esp
f010637b:	5e                   	pop    %esi
f010637c:	5f                   	pop    %edi
f010637d:	5d                   	pop    %ebp
f010637e:	c3                   	ret    
f010637f:	90                   	nop
f0106380:	39 d7                	cmp    %edx,%edi
f0106382:	75 da                	jne    f010635e <__umoddi3+0x10e>
f0106384:	8b 14 24             	mov    (%esp),%edx
f0106387:	89 c1                	mov    %eax,%ecx
f0106389:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f010638d:	1b 54 24 04          	sbb    0x4(%esp),%edx
f0106391:	eb cb                	jmp    f010635e <__umoddi3+0x10e>
f0106393:	90                   	nop
f0106394:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0106398:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f010639c:	0f 82 0f ff ff ff    	jb     f01062b1 <__umoddi3+0x61>
f01063a2:	e9 1a ff ff ff       	jmp    f01062c1 <__umoddi3+0x71>
