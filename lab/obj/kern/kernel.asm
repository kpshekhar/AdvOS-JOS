
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
f0100015:	b8 00 c0 11 00       	mov    $0x11c000,%eax
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
f0100034:	bc 00 c0 11 f0       	mov    $0xf011c000,%esp

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
f010004b:	83 3d 00 9f 22 f0 00 	cmpl   $0x0,0xf0229f00
f0100052:	75 46                	jne    f010009a <_panic+0x5a>
		goto dead;
	panicstr = fmt;
f0100054:	89 35 00 9f 22 f0    	mov    %esi,0xf0229f00

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f010005a:	fa                   	cli    
f010005b:	fc                   	cld    

	va_start(ap, fmt);
f010005c:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005f:	e8 c5 4e 00 00       	call   f0104f29 <cpunum>
f0100064:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100067:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010006b:	8b 55 08             	mov    0x8(%ebp),%edx
f010006e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100072:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100076:	c7 04 24 00 56 10 f0 	movl   $0xf0105600,(%esp)
f010007d:	e8 0e 33 00 00       	call   f0103390 <cprintf>
	vcprintf(fmt, ap);
f0100082:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100086:	89 34 24             	mov    %esi,(%esp)
f0100089:	e8 cf 32 00 00       	call   f010335d <vcprintf>
	cprintf("\n");
f010008e:	c7 04 24 72 6a 10 f0 	movl   $0xf0106a72,(%esp)
f0100095:	e8 f6 32 00 00       	call   f0103390 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010009a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000a1:	e8 bf 08 00 00       	call   f0100965 <monitor>
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
f01000af:	b8 08 b0 26 f0       	mov    $0xf026b008,%eax
f01000b4:	2d e7 8c 22 f0       	sub    $0xf0228ce7,%eax
f01000b9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000c4:	00 
f01000c5:	c7 04 24 e7 8c 22 f0 	movl   $0xf0228ce7,(%esp)
f01000cc:	e8 06 48 00 00       	call   f01048d7 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000d1:	e8 89 05 00 00       	call   f010065f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000d6:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000dd:	00 
f01000de:	c7 04 24 6c 56 10 f0 	movl   $0xf010566c,(%esp)
f01000e5:	e8 a6 32 00 00       	call   f0103390 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000ea:	e8 22 10 00 00       	call   f0101111 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000ef:	e8 51 2a 00 00       	call   f0102b45 <env_init>
	trap_init();
f01000f4:	e8 14 33 00 00       	call   f010340d <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000f9:	e8 1c 4b 00 00       	call   f0104c1a <mp_init>
	lapic_init();
f01000fe:	66 90                	xchg   %ax,%ax
f0100100:	e8 3f 4e 00 00       	call   f0104f44 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f0100105:	e8 b6 31 00 00       	call   f01032c0 <pic_init>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010010a:	83 3d 08 9f 22 f0 07 	cmpl   $0x7,0xf0229f08
f0100111:	77 24                	ja     f0100137 <i386_init+0x8f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100113:	c7 44 24 0c 00 70 00 	movl   $0x7000,0xc(%esp)
f010011a:	00 
f010011b:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0100122:	f0 
f0100123:	c7 44 24 04 53 00 00 	movl   $0x53,0x4(%esp)
f010012a:	00 
f010012b:	c7 04 24 87 56 10 f0 	movl   $0xf0105687,(%esp)
f0100132:	e8 09 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f0100137:	b8 52 4b 10 f0       	mov    $0xf0104b52,%eax
f010013c:	2d d8 4a 10 f0       	sub    $0xf0104ad8,%eax
f0100141:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100145:	c7 44 24 04 d8 4a 10 	movl   $0xf0104ad8,0x4(%esp)
f010014c:	f0 
f010014d:	c7 04 24 00 70 00 f0 	movl   $0xf0007000,(%esp)
f0100154:	e8 cb 47 00 00       	call   f0104924 <memmove>

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f0100159:	bb 20 a0 22 f0       	mov    $0xf022a020,%ebx
f010015e:	eb 4d                	jmp    f01001ad <i386_init+0x105>
		if (c == cpus + cpunum())  // We've started already.
f0100160:	e8 c4 4d 00 00       	call   f0104f29 <cpunum>
f0100165:	6b c0 74             	imul   $0x74,%eax,%eax
f0100168:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f010016d:	39 c3                	cmp    %eax,%ebx
f010016f:	74 39                	je     f01001aa <i386_init+0x102>
f0100171:	89 d8                	mov    %ebx,%eax
f0100173:	2d 20 a0 22 f0       	sub    $0xf022a020,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f0100178:	c1 f8 02             	sar    $0x2,%eax
f010017b:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100181:	c1 e0 0f             	shl    $0xf,%eax
f0100184:	8d 80 00 30 23 f0    	lea    -0xfdcd000(%eax),%eax
f010018a:	a3 04 9f 22 f0       	mov    %eax,0xf0229f04
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f010018f:	c7 44 24 04 00 70 00 	movl   $0x7000,0x4(%esp)
f0100196:	00 
f0100197:	0f b6 03             	movzbl (%ebx),%eax
f010019a:	89 04 24             	mov    %eax,(%esp)
f010019d:	e8 f2 4e 00 00       	call   f0105094 <lapic_startap>
		// Wait for the CPU to finish some basic setup in mp_main()
		while(c->cpu_status != CPU_STARTED)
f01001a2:	8b 43 04             	mov    0x4(%ebx),%eax
f01001a5:	83 f8 01             	cmp    $0x1,%eax
f01001a8:	75 f8                	jne    f01001a2 <i386_init+0xfa>
	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f01001aa:	83 c3 74             	add    $0x74,%ebx
f01001ad:	6b 05 c4 a3 22 f0 74 	imul   $0x74,0xf022a3c4,%eax
f01001b4:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f01001b9:	39 c3                	cmp    %eax,%ebx
f01001bb:	72 a3                	jb     f0100160 <i386_init+0xb8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001bd:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01001c4:	00 
f01001c5:	c7 04 24 da 02 22 f0 	movl   $0xf02202da,(%esp)
f01001cc:	e8 67 2b 00 00       	call   f0102d38 <env_create>
	// Touch all you want.
	ENV_CREATE(user_primes, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001d1:	e8 6a 39 00 00       	call   f0103b40 <sched_yield>

f01001d6 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001d6:	55                   	push   %ebp
f01001d7:	89 e5                	mov    %esp,%ebp
f01001d9:	83 ec 18             	sub    $0x18,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001dc:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001e1:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001e6:	77 20                	ja     f0100208 <mp_main+0x32>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001e8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01001ec:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f01001f3:	f0 
f01001f4:	c7 44 24 04 6a 00 00 	movl   $0x6a,0x4(%esp)
f01001fb:	00 
f01001fc:	c7 04 24 87 56 10 f0 	movl   $0xf0105687,(%esp)
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
f0100210:	e8 14 4d 00 00       	call   f0104f29 <cpunum>
f0100215:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100219:	c7 04 24 93 56 10 f0 	movl   $0xf0105693,(%esp)
f0100220:	e8 6b 31 00 00       	call   f0103390 <cprintf>

	lapic_init();
f0100225:	e8 1a 4d 00 00       	call   f0104f44 <lapic_init>
	env_init_percpu();
f010022a:	e8 ec 28 00 00       	call   f0102b1b <env_init_percpu>
	trap_init_percpu();
f010022f:	90                   	nop
f0100230:	e8 7b 31 00 00       	call   f01033b0 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100235:	e8 ef 4c 00 00       	call   f0104f29 <cpunum>
f010023a:	6b d0 74             	imul   $0x74,%eax,%edx
f010023d:	81 c2 20 a0 22 f0    	add    $0xf022a020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100243:	b8 01 00 00 00       	mov    $0x1,%eax
f0100248:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010024c:	eb fe                	jmp    f010024c <mp_main+0x76>

f010024e <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010024e:	55                   	push   %ebp
f010024f:	89 e5                	mov    %esp,%ebp
f0100251:	53                   	push   %ebx
f0100252:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f0100255:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100258:	8b 45 0c             	mov    0xc(%ebp),%eax
f010025b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010025f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100262:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100266:	c7 04 24 a9 56 10 f0 	movl   $0xf01056a9,(%esp)
f010026d:	e8 1e 31 00 00       	call   f0103390 <cprintf>
	vcprintf(fmt, ap);
f0100272:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100276:	8b 45 10             	mov    0x10(%ebp),%eax
f0100279:	89 04 24             	mov    %eax,(%esp)
f010027c:	e8 dc 30 00 00       	call   f010335d <vcprintf>
	cprintf("\n");
f0100281:	c7 04 24 72 6a 10 f0 	movl   $0xf0106a72,(%esp)
f0100288:	e8 03 31 00 00       	call   f0103390 <cprintf>
	va_end(ap);
}
f010028d:	83 c4 14             	add    $0x14,%esp
f0100290:	5b                   	pop    %ebx
f0100291:	5d                   	pop    %ebp
f0100292:	c3                   	ret    
f0100293:	66 90                	xchg   %ax,%ax
f0100295:	66 90                	xchg   %ax,%ax
f0100297:	66 90                	xchg   %ax,%ax
f0100299:	66 90                	xchg   %ax,%ax
f010029b:	66 90                	xchg   %ax,%ax
f010029d:	66 90                	xchg   %ax,%ax
f010029f:	90                   	nop

f01002a0 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01002a0:	55                   	push   %ebp
f01002a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01002a3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01002a8:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01002a9:	a8 01                	test   $0x1,%al
f01002ab:	74 08                	je     f01002b5 <serial_proc_data+0x15>
f01002ad:	b2 f8                	mov    $0xf8,%dl
f01002af:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01002b0:	0f b6 c0             	movzbl %al,%eax
f01002b3:	eb 05                	jmp    f01002ba <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01002b5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f01002ba:	5d                   	pop    %ebp
f01002bb:	c3                   	ret    

f01002bc <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01002bc:	55                   	push   %ebp
f01002bd:	89 e5                	mov    %esp,%ebp
f01002bf:	53                   	push   %ebx
f01002c0:	83 ec 04             	sub    $0x4,%esp
f01002c3:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01002c5:	eb 2a                	jmp    f01002f1 <cons_intr+0x35>
		if (c == 0)
f01002c7:	85 d2                	test   %edx,%edx
f01002c9:	74 26                	je     f01002f1 <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f01002cb:	a1 24 92 22 f0       	mov    0xf0229224,%eax
f01002d0:	8d 48 01             	lea    0x1(%eax),%ecx
f01002d3:	89 0d 24 92 22 f0    	mov    %ecx,0xf0229224
f01002d9:	88 90 20 90 22 f0    	mov    %dl,-0xfdd6fe0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002df:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002e5:	75 0a                	jne    f01002f1 <cons_intr+0x35>
			cons.wpos = 0;
f01002e7:	c7 05 24 92 22 f0 00 	movl   $0x0,0xf0229224
f01002ee:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002f1:	ff d3                	call   *%ebx
f01002f3:	89 c2                	mov    %eax,%edx
f01002f5:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002f8:	75 cd                	jne    f01002c7 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002fa:	83 c4 04             	add    $0x4,%esp
f01002fd:	5b                   	pop    %ebx
f01002fe:	5d                   	pop    %ebp
f01002ff:	c3                   	ret    

f0100300 <kbd_proc_data>:
f0100300:	ba 64 00 00 00       	mov    $0x64,%edx
f0100305:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f0100306:	a8 01                	test   $0x1,%al
f0100308:	0f 84 ef 00 00 00    	je     f01003fd <kbd_proc_data+0xfd>
f010030e:	b2 60                	mov    $0x60,%dl
f0100310:	ec                   	in     (%dx),%al
f0100311:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100313:	3c e0                	cmp    $0xe0,%al
f0100315:	75 0d                	jne    f0100324 <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f0100317:	83 0d 00 90 22 f0 40 	orl    $0x40,0xf0229000
		return 0;
f010031e:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100323:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100324:	55                   	push   %ebp
f0100325:	89 e5                	mov    %esp,%ebp
f0100327:	53                   	push   %ebx
f0100328:	83 ec 14             	sub    $0x14,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f010032b:	84 c0                	test   %al,%al
f010032d:	79 37                	jns    f0100366 <kbd_proc_data+0x66>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f010032f:	8b 0d 00 90 22 f0    	mov    0xf0229000,%ecx
f0100335:	89 cb                	mov    %ecx,%ebx
f0100337:	83 e3 40             	and    $0x40,%ebx
f010033a:	83 e0 7f             	and    $0x7f,%eax
f010033d:	85 db                	test   %ebx,%ebx
f010033f:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100342:	0f b6 d2             	movzbl %dl,%edx
f0100345:	0f b6 82 20 58 10 f0 	movzbl -0xfefa7e0(%edx),%eax
f010034c:	83 c8 40             	or     $0x40,%eax
f010034f:	0f b6 c0             	movzbl %al,%eax
f0100352:	f7 d0                	not    %eax
f0100354:	21 c1                	and    %eax,%ecx
f0100356:	89 0d 00 90 22 f0    	mov    %ecx,0xf0229000
		return 0;
f010035c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100361:	e9 9d 00 00 00       	jmp    f0100403 <kbd_proc_data+0x103>
	} else if (shift & E0ESC) {
f0100366:	8b 0d 00 90 22 f0    	mov    0xf0229000,%ecx
f010036c:	f6 c1 40             	test   $0x40,%cl
f010036f:	74 0e                	je     f010037f <kbd_proc_data+0x7f>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100371:	83 c8 80             	or     $0xffffff80,%eax
f0100374:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100376:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100379:	89 0d 00 90 22 f0    	mov    %ecx,0xf0229000
	}

	shift |= shiftcode[data];
f010037f:	0f b6 d2             	movzbl %dl,%edx
f0100382:	0f b6 82 20 58 10 f0 	movzbl -0xfefa7e0(%edx),%eax
f0100389:	0b 05 00 90 22 f0    	or     0xf0229000,%eax
	shift ^= togglecode[data];
f010038f:	0f b6 8a 20 57 10 f0 	movzbl -0xfefa8e0(%edx),%ecx
f0100396:	31 c8                	xor    %ecx,%eax
f0100398:	a3 00 90 22 f0       	mov    %eax,0xf0229000

	c = charcode[shift & (CTL | SHIFT)][data];
f010039d:	89 c1                	mov    %eax,%ecx
f010039f:	83 e1 03             	and    $0x3,%ecx
f01003a2:	8b 0c 8d 00 57 10 f0 	mov    -0xfefa900(,%ecx,4),%ecx
f01003a9:	0f b6 14 11          	movzbl (%ecx,%edx,1),%edx
f01003ad:	0f b6 da             	movzbl %dl,%ebx
	if (shift & CAPSLOCK) {
f01003b0:	a8 08                	test   $0x8,%al
f01003b2:	74 1b                	je     f01003cf <kbd_proc_data+0xcf>
		if ('a' <= c && c <= 'z')
f01003b4:	89 da                	mov    %ebx,%edx
f01003b6:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f01003b9:	83 f9 19             	cmp    $0x19,%ecx
f01003bc:	77 05                	ja     f01003c3 <kbd_proc_data+0xc3>
			c += 'A' - 'a';
f01003be:	83 eb 20             	sub    $0x20,%ebx
f01003c1:	eb 0c                	jmp    f01003cf <kbd_proc_data+0xcf>
		else if ('A' <= c && c <= 'Z')
f01003c3:	83 ea 41             	sub    $0x41,%edx
			c += 'a' - 'A';
f01003c6:	8d 4b 20             	lea    0x20(%ebx),%ecx
f01003c9:	83 fa 19             	cmp    $0x19,%edx
f01003cc:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003cf:	f7 d0                	not    %eax
f01003d1:	89 c2                	mov    %eax,%edx
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003d3:	89 d8                	mov    %ebx,%eax
			c += 'a' - 'A';
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01003d5:	f6 c2 06             	test   $0x6,%dl
f01003d8:	75 29                	jne    f0100403 <kbd_proc_data+0x103>
f01003da:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01003e0:	75 21                	jne    f0100403 <kbd_proc_data+0x103>
		cprintf("Rebooting!\n");
f01003e2:	c7 04 24 c3 56 10 f0 	movl   $0xf01056c3,(%esp)
f01003e9:	e8 a2 2f 00 00       	call   f0103390 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003ee:	ba 92 00 00 00       	mov    $0x92,%edx
f01003f3:	b8 03 00 00 00       	mov    $0x3,%eax
f01003f8:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003f9:	89 d8                	mov    %ebx,%eax
f01003fb:	eb 06                	jmp    f0100403 <kbd_proc_data+0x103>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003fd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100402:	c3                   	ret    
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100403:	83 c4 14             	add    $0x14,%esp
f0100406:	5b                   	pop    %ebx
f0100407:	5d                   	pop    %ebp
f0100408:	c3                   	ret    

f0100409 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100409:	55                   	push   %ebp
f010040a:	89 e5                	mov    %esp,%ebp
f010040c:	57                   	push   %edi
f010040d:	56                   	push   %esi
f010040e:	53                   	push   %ebx
f010040f:	83 ec 1c             	sub    $0x1c,%esp
f0100412:	89 c7                	mov    %eax,%edi
f0100414:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100419:	be fd 03 00 00       	mov    $0x3fd,%esi
f010041e:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100423:	eb 06                	jmp    f010042b <cons_putc+0x22>
f0100425:	89 ca                	mov    %ecx,%edx
f0100427:	ec                   	in     (%dx),%al
f0100428:	ec                   	in     (%dx),%al
f0100429:	ec                   	in     (%dx),%al
f010042a:	ec                   	in     (%dx),%al
f010042b:	89 f2                	mov    %esi,%edx
f010042d:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010042e:	a8 20                	test   $0x20,%al
f0100430:	75 05                	jne    f0100437 <cons_putc+0x2e>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100432:	83 eb 01             	sub    $0x1,%ebx
f0100435:	75 ee                	jne    f0100425 <cons_putc+0x1c>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100437:	89 f8                	mov    %edi,%eax
f0100439:	0f b6 c0             	movzbl %al,%eax
f010043c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010043f:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100444:	ee                   	out    %al,(%dx)
f0100445:	bb 01 32 00 00       	mov    $0x3201,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010044a:	be 79 03 00 00       	mov    $0x379,%esi
f010044f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100454:	eb 06                	jmp    f010045c <cons_putc+0x53>
f0100456:	89 ca                	mov    %ecx,%edx
f0100458:	ec                   	in     (%dx),%al
f0100459:	ec                   	in     (%dx),%al
f010045a:	ec                   	in     (%dx),%al
f010045b:	ec                   	in     (%dx),%al
f010045c:	89 f2                	mov    %esi,%edx
f010045e:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010045f:	84 c0                	test   %al,%al
f0100461:	78 05                	js     f0100468 <cons_putc+0x5f>
f0100463:	83 eb 01             	sub    $0x1,%ebx
f0100466:	75 ee                	jne    f0100456 <cons_putc+0x4d>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100468:	ba 78 03 00 00       	mov    $0x378,%edx
f010046d:	0f b6 45 e4          	movzbl -0x1c(%ebp),%eax
f0100471:	ee                   	out    %al,(%dx)
f0100472:	b2 7a                	mov    $0x7a,%dl
f0100474:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100479:	ee                   	out    %al,(%dx)
f010047a:	b8 08 00 00 00       	mov    $0x8,%eax
f010047f:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100480:	89 fa                	mov    %edi,%edx
f0100482:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f0100488:	89 f8                	mov    %edi,%eax
f010048a:	80 cc 07             	or     $0x7,%ah
f010048d:	85 d2                	test   %edx,%edx
f010048f:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100492:	89 f8                	mov    %edi,%eax
f0100494:	0f b6 c0             	movzbl %al,%eax
f0100497:	83 f8 09             	cmp    $0x9,%eax
f010049a:	74 76                	je     f0100512 <cons_putc+0x109>
f010049c:	83 f8 09             	cmp    $0x9,%eax
f010049f:	7f 0a                	jg     f01004ab <cons_putc+0xa2>
f01004a1:	83 f8 08             	cmp    $0x8,%eax
f01004a4:	74 16                	je     f01004bc <cons_putc+0xb3>
f01004a6:	e9 9b 00 00 00       	jmp    f0100546 <cons_putc+0x13d>
f01004ab:	83 f8 0a             	cmp    $0xa,%eax
f01004ae:	66 90                	xchg   %ax,%ax
f01004b0:	74 3a                	je     f01004ec <cons_putc+0xe3>
f01004b2:	83 f8 0d             	cmp    $0xd,%eax
f01004b5:	74 3d                	je     f01004f4 <cons_putc+0xeb>
f01004b7:	e9 8a 00 00 00       	jmp    f0100546 <cons_putc+0x13d>
	case '\b':
		if (crt_pos > 0) {
f01004bc:	0f b7 05 28 92 22 f0 	movzwl 0xf0229228,%eax
f01004c3:	66 85 c0             	test   %ax,%ax
f01004c6:	0f 84 e5 00 00 00    	je     f01005b1 <cons_putc+0x1a8>
			crt_pos--;
f01004cc:	83 e8 01             	sub    $0x1,%eax
f01004cf:	66 a3 28 92 22 f0    	mov    %ax,0xf0229228
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004d5:	0f b7 c0             	movzwl %ax,%eax
f01004d8:	66 81 e7 00 ff       	and    $0xff00,%di
f01004dd:	83 cf 20             	or     $0x20,%edi
f01004e0:	8b 15 2c 92 22 f0    	mov    0xf022922c,%edx
f01004e6:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004ea:	eb 78                	jmp    f0100564 <cons_putc+0x15b>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004ec:	66 83 05 28 92 22 f0 	addw   $0x50,0xf0229228
f01004f3:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004f4:	0f b7 05 28 92 22 f0 	movzwl 0xf0229228,%eax
f01004fb:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100501:	c1 e8 16             	shr    $0x16,%eax
f0100504:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0100507:	c1 e0 04             	shl    $0x4,%eax
f010050a:	66 a3 28 92 22 f0    	mov    %ax,0xf0229228
f0100510:	eb 52                	jmp    f0100564 <cons_putc+0x15b>
		break;
	case '\t':
		cons_putc(' ');
f0100512:	b8 20 00 00 00       	mov    $0x20,%eax
f0100517:	e8 ed fe ff ff       	call   f0100409 <cons_putc>
		cons_putc(' ');
f010051c:	b8 20 00 00 00       	mov    $0x20,%eax
f0100521:	e8 e3 fe ff ff       	call   f0100409 <cons_putc>
		cons_putc(' ');
f0100526:	b8 20 00 00 00       	mov    $0x20,%eax
f010052b:	e8 d9 fe ff ff       	call   f0100409 <cons_putc>
		cons_putc(' ');
f0100530:	b8 20 00 00 00       	mov    $0x20,%eax
f0100535:	e8 cf fe ff ff       	call   f0100409 <cons_putc>
		cons_putc(' ');
f010053a:	b8 20 00 00 00       	mov    $0x20,%eax
f010053f:	e8 c5 fe ff ff       	call   f0100409 <cons_putc>
f0100544:	eb 1e                	jmp    f0100564 <cons_putc+0x15b>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100546:	0f b7 05 28 92 22 f0 	movzwl 0xf0229228,%eax
f010054d:	8d 50 01             	lea    0x1(%eax),%edx
f0100550:	66 89 15 28 92 22 f0 	mov    %dx,0xf0229228
f0100557:	0f b7 c0             	movzwl %ax,%eax
f010055a:	8b 15 2c 92 22 f0    	mov    0xf022922c,%edx
f0100560:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100564:	66 81 3d 28 92 22 f0 	cmpw   $0x7cf,0xf0229228
f010056b:	cf 07 
f010056d:	76 42                	jbe    f01005b1 <cons_putc+0x1a8>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010056f:	a1 2c 92 22 f0       	mov    0xf022922c,%eax
f0100574:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010057b:	00 
f010057c:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100582:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100586:	89 04 24             	mov    %eax,(%esp)
f0100589:	e8 96 43 00 00       	call   f0104924 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010058e:	8b 15 2c 92 22 f0    	mov    0xf022922c,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100594:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f0100599:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010059f:	83 c0 01             	add    $0x1,%eax
f01005a2:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f01005a7:	75 f0                	jne    f0100599 <cons_putc+0x190>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f01005a9:	66 83 2d 28 92 22 f0 	subw   $0x50,0xf0229228
f01005b0:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01005b1:	8b 0d 30 92 22 f0    	mov    0xf0229230,%ecx
f01005b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005bc:	89 ca                	mov    %ecx,%edx
f01005be:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01005bf:	0f b7 1d 28 92 22 f0 	movzwl 0xf0229228,%ebx
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
f01005df:	83 c4 1c             	add    $0x1c,%esp
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
f01005e7:	80 3d 34 92 22 f0 00 	cmpb   $0x0,0xf0229234
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
f01005f6:	b8 a0 02 10 f0       	mov    $0xf01002a0,%eax
f01005fb:	e8 bc fc ff ff       	call   f01002bc <cons_intr>
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
f0100609:	b8 00 03 10 f0       	mov    $0xf0100300,%eax
f010060e:	e8 a9 fc ff ff       	call   f01002bc <cons_intr>
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
f0100625:	a1 20 92 22 f0       	mov    0xf0229220,%eax
f010062a:	3b 05 24 92 22 f0    	cmp    0xf0229224,%eax
f0100630:	74 26                	je     f0100658 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100632:	8d 50 01             	lea    0x1(%eax),%edx
f0100635:	89 15 20 92 22 f0    	mov    %edx,0xf0229220
f010063b:	0f b6 88 20 90 22 f0 	movzbl -0xfdd6fe0(%eax),%ecx
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
f010064c:	c7 05 20 92 22 f0 00 	movl   $0x0,0xf0229220
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
f0100665:	83 ec 1c             	sub    $0x1c,%esp
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
f0100685:	c7 05 30 92 22 f0 b4 	movl   $0x3b4,0xf0229230
f010068c:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f010068f:	bf 00 00 0b f0       	mov    $0xf00b0000,%edi
f0100694:	eb 16                	jmp    f01006ac <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f0100696:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f010069d:	c7 05 30 92 22 f0 d4 	movl   $0x3d4,0xf0229230
f01006a4:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01006a7:	bf 00 80 0b f0       	mov    $0xf00b8000,%edi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01006ac:	8b 0d 30 92 22 f0    	mov    0xf0229230,%ecx
f01006b2:	b8 0e 00 00 00       	mov    $0xe,%eax
f01006b7:	89 ca                	mov    %ecx,%edx
f01006b9:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01006ba:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006bd:	89 da                	mov    %ebx,%edx
f01006bf:	ec                   	in     (%dx),%al
f01006c0:	0f b6 f0             	movzbl %al,%esi
f01006c3:	c1 e6 08             	shl    $0x8,%esi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006c6:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006cb:	89 ca                	mov    %ecx,%edx
f01006cd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006ce:	89 da                	mov    %ebx,%edx
f01006d0:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006d1:	89 3d 2c 92 22 f0    	mov    %edi,0xf022922c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006d7:	0f b6 d8             	movzbl %al,%ebx
f01006da:	09 de                	or     %ebx,%esi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006dc:	66 89 35 28 92 22 f0 	mov    %si,0xf0229228

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006e3:	e8 1b ff ff ff       	call   f0100603 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006e8:	0f b7 05 88 e3 11 f0 	movzwl 0xf011e388,%eax
f01006ef:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006f4:	89 04 24             	mov    %eax,(%esp)
f01006f7:	e8 55 2b 00 00       	call   f0103251 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006fc:	be fa 03 00 00       	mov    $0x3fa,%esi
f0100701:	b8 00 00 00 00       	mov    $0x0,%eax
f0100706:	89 f2                	mov    %esi,%edx
f0100708:	ee                   	out    %al,(%dx)
f0100709:	b2 fb                	mov    $0xfb,%dl
f010070b:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f0100710:	ee                   	out    %al,(%dx)
f0100711:	bb f8 03 00 00       	mov    $0x3f8,%ebx
f0100716:	b8 0c 00 00 00       	mov    $0xc,%eax
f010071b:	89 da                	mov    %ebx,%edx
f010071d:	ee                   	out    %al,(%dx)
f010071e:	b2 f9                	mov    $0xf9,%dl
f0100720:	b8 00 00 00 00       	mov    $0x0,%eax
f0100725:	ee                   	out    %al,(%dx)
f0100726:	b2 fb                	mov    $0xfb,%dl
f0100728:	b8 03 00 00 00       	mov    $0x3,%eax
f010072d:	ee                   	out    %al,(%dx)
f010072e:	b2 fc                	mov    $0xfc,%dl
f0100730:	b8 00 00 00 00       	mov    $0x0,%eax
f0100735:	ee                   	out    %al,(%dx)
f0100736:	b2 f9                	mov    $0xf9,%dl
f0100738:	b8 01 00 00 00       	mov    $0x1,%eax
f010073d:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010073e:	b2 fd                	mov    $0xfd,%dl
f0100740:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f0100741:	3c ff                	cmp    $0xff,%al
f0100743:	0f 95 c1             	setne  %cl
f0100746:	88 0d 34 92 22 f0    	mov    %cl,0xf0229234
f010074c:	89 f2                	mov    %esi,%edx
f010074e:	ec                   	in     (%dx),%al
f010074f:	89 da                	mov    %ebx,%edx
f0100751:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100752:	84 c9                	test   %cl,%cl
f0100754:	75 0c                	jne    f0100762 <cons_init+0x103>
		cprintf("Serial port does not exist!\n");
f0100756:	c7 04 24 cf 56 10 f0 	movl   $0xf01056cf,(%esp)
f010075d:	e8 2e 2c 00 00       	call   f0103390 <cprintf>
}
f0100762:	83 c4 1c             	add    $0x1c,%esp
f0100765:	5b                   	pop    %ebx
f0100766:	5e                   	pop    %esi
f0100767:	5f                   	pop    %edi
f0100768:	5d                   	pop    %ebp
f0100769:	c3                   	ret    

f010076a <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010076a:	55                   	push   %ebp
f010076b:	89 e5                	mov    %esp,%ebp
f010076d:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100770:	8b 45 08             	mov    0x8(%ebp),%eax
f0100773:	e8 91 fc ff ff       	call   f0100409 <cons_putc>
}
f0100778:	c9                   	leave  
f0100779:	c3                   	ret    

f010077a <getchar>:

int
getchar(void)
{
f010077a:	55                   	push   %ebp
f010077b:	89 e5                	mov    %esp,%ebp
f010077d:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100780:	e8 90 fe ff ff       	call   f0100615 <cons_getc>
f0100785:	85 c0                	test   %eax,%eax
f0100787:	74 f7                	je     f0100780 <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100789:	c9                   	leave  
f010078a:	c3                   	ret    

f010078b <iscons>:

int
iscons(int fdnum)
{
f010078b:	55                   	push   %ebp
f010078c:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010078e:	b8 01 00 00 00       	mov    $0x1,%eax
f0100793:	5d                   	pop    %ebp
f0100794:	c3                   	ret    
f0100795:	66 90                	xchg   %ax,%ax
f0100797:	66 90                	xchg   %ax,%ax
f0100799:	66 90                	xchg   %ax,%ax
f010079b:	66 90                	xchg   %ax,%ax
f010079d:	66 90                	xchg   %ax,%ax
f010079f:	90                   	nop

f01007a0 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01007a0:	55                   	push   %ebp
f01007a1:	89 e5                	mov    %esp,%ebp
f01007a3:	83 ec 18             	sub    $0x18,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f01007a6:	c7 44 24 08 20 59 10 	movl   $0xf0105920,0x8(%esp)
f01007ad:	f0 
f01007ae:	c7 44 24 04 3e 59 10 	movl   $0xf010593e,0x4(%esp)
f01007b5:	f0 
f01007b6:	c7 04 24 43 59 10 f0 	movl   $0xf0105943,(%esp)
f01007bd:	e8 ce 2b 00 00       	call   f0103390 <cprintf>
f01007c2:	c7 44 24 08 e4 59 10 	movl   $0xf01059e4,0x8(%esp)
f01007c9:	f0 
f01007ca:	c7 44 24 04 4c 59 10 	movl   $0xf010594c,0x4(%esp)
f01007d1:	f0 
f01007d2:	c7 04 24 43 59 10 f0 	movl   $0xf0105943,(%esp)
f01007d9:	e8 b2 2b 00 00       	call   f0103390 <cprintf>
f01007de:	c7 44 24 08 55 59 10 	movl   $0xf0105955,0x8(%esp)
f01007e5:	f0 
f01007e6:	c7 44 24 04 72 59 10 	movl   $0xf0105972,0x4(%esp)
f01007ed:	f0 
f01007ee:	c7 04 24 43 59 10 f0 	movl   $0xf0105943,(%esp)
f01007f5:	e8 96 2b 00 00       	call   f0103390 <cprintf>
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
f0100804:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100807:	c7 04 24 7d 59 10 f0 	movl   $0xf010597d,(%esp)
f010080e:	e8 7d 2b 00 00       	call   f0103390 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100813:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f010081a:	00 
f010081b:	c7 04 24 0c 5a 10 f0 	movl   $0xf0105a0c,(%esp)
f0100822:	e8 69 2b 00 00       	call   f0103390 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100827:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010082e:	00 
f010082f:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100836:	f0 
f0100837:	c7 04 24 34 5a 10 f0 	movl   $0xf0105a34,(%esp)
f010083e:	e8 4d 2b 00 00       	call   f0103390 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100843:	c7 44 24 08 f7 55 10 	movl   $0x1055f7,0x8(%esp)
f010084a:	00 
f010084b:	c7 44 24 04 f7 55 10 	movl   $0xf01055f7,0x4(%esp)
f0100852:	f0 
f0100853:	c7 04 24 58 5a 10 f0 	movl   $0xf0105a58,(%esp)
f010085a:	e8 31 2b 00 00       	call   f0103390 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010085f:	c7 44 24 08 e7 8c 22 	movl   $0x228ce7,0x8(%esp)
f0100866:	00 
f0100867:	c7 44 24 04 e7 8c 22 	movl   $0xf0228ce7,0x4(%esp)
f010086e:	f0 
f010086f:	c7 04 24 7c 5a 10 f0 	movl   $0xf0105a7c,(%esp)
f0100876:	e8 15 2b 00 00       	call   f0103390 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010087b:	c7 44 24 08 08 b0 26 	movl   $0x26b008,0x8(%esp)
f0100882:	00 
f0100883:	c7 44 24 04 08 b0 26 	movl   $0xf026b008,0x4(%esp)
f010088a:	f0 
f010088b:	c7 04 24 a0 5a 10 f0 	movl   $0xf0105aa0,(%esp)
f0100892:	e8 f9 2a 00 00       	call   f0103390 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100897:	b8 07 b4 26 f0       	mov    $0xf026b407,%eax
f010089c:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01008a1:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01008a6:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01008ac:	85 c0                	test   %eax,%eax
f01008ae:	0f 48 c2             	cmovs  %edx,%eax
f01008b1:	c1 f8 0a             	sar    $0xa,%eax
f01008b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01008b8:	c7 04 24 c4 5a 10 f0 	movl   $0xf0105ac4,(%esp)
f01008bf:	e8 cc 2a 00 00       	call   f0103390 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01008c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01008c9:	c9                   	leave  
f01008ca:	c3                   	ret    

f01008cb <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f01008cb:	55                   	push   %ebp
f01008cc:	89 e5                	mov    %esp,%ebp
f01008ce:	57                   	push   %edi
f01008cf:	56                   	push   %esi
f01008d0:	53                   	push   %ebx
f01008d1:	83 ec 6c             	sub    $0x6c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01008d4:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01008d6:	c7 04 24 96 59 10 f0 	movl   $0xf0105996,(%esp)
f01008dd:	e8 ae 2a 00 00       	call   f0103390 <cprintf>
	
	while (ebp){
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f01008e2:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01008e5:	eb 6d                	jmp    f0100954 <mon_backtrace+0x89>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f01008e7:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f01008ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01008ee:	89 34 24             	mov    %esi,(%esp)
f01008f1:	e8 a6 34 00 00       	call   f0103d9c <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f01008f6:	89 f0                	mov    %esi,%eax
f01008f8:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008fb:	89 44 24 30          	mov    %eax,0x30(%esp)
f01008ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100902:	89 44 24 2c          	mov    %eax,0x2c(%esp)
f0100906:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100909:	89 44 24 28          	mov    %eax,0x28(%esp)
f010090d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100910:	89 44 24 24          	mov    %eax,0x24(%esp)
f0100914:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0100917:	89 44 24 20          	mov    %eax,0x20(%esp)
f010091b:	8b 43 18             	mov    0x18(%ebx),%eax
f010091e:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100922:	8b 43 14             	mov    0x14(%ebx),%eax
f0100925:	89 44 24 18          	mov    %eax,0x18(%esp)
f0100929:	8b 43 10             	mov    0x10(%ebx),%eax
f010092c:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100930:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100933:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100937:	8b 43 08             	mov    0x8(%ebx),%eax
f010093a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010093e:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100942:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100946:	c7 04 24 f0 5a 10 f0 	movl   $0xf0105af0,(%esp)
f010094d:	e8 3e 2a 00 00       	call   f0103390 <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f0100952:	8b 1b                	mov    (%ebx),%ebx
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f0100954:	85 db                	test   %ebx,%ebx
f0100956:	75 8f                	jne    f01008e7 <mon_backtrace+0x1c>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f0100958:	b8 00 00 00 00       	mov    $0x0,%eax
f010095d:	83 c4 6c             	add    $0x6c,%esp
f0100960:	5b                   	pop    %ebx
f0100961:	5e                   	pop    %esi
f0100962:	5f                   	pop    %edi
f0100963:	5d                   	pop    %ebp
f0100964:	c3                   	ret    

f0100965 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100965:	55                   	push   %ebp
f0100966:	89 e5                	mov    %esp,%ebp
f0100968:	57                   	push   %edi
f0100969:	56                   	push   %esi
f010096a:	53                   	push   %ebx
f010096b:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010096e:	c7 04 24 34 5b 10 f0 	movl   $0xf0105b34,(%esp)
f0100975:	e8 16 2a 00 00       	call   f0103390 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f010097a:	c7 04 24 58 5b 10 f0 	movl   $0xf0105b58,(%esp)
f0100981:	e8 0a 2a 00 00       	call   f0103390 <cprintf>

	if (tf != NULL)
f0100986:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010098a:	74 0b                	je     f0100997 <monitor+0x32>
		print_trapframe(tf);
f010098c:	8b 45 08             	mov    0x8(%ebp),%eax
f010098f:	89 04 24             	mov    %eax,(%esp)
f0100992:	e8 be 2b 00 00       	call   f0103555 <print_trapframe>

	while (1) {
		buf = readline("K> ");
f0100997:	c7 04 24 a8 59 10 f0 	movl   $0xf01059a8,(%esp)
f010099e:	e8 dd 3c 00 00       	call   f0104680 <readline>
f01009a3:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f01009a5:	85 c0                	test   %eax,%eax
f01009a7:	74 ee                	je     f0100997 <monitor+0x32>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f01009a9:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f01009b0:	be 00 00 00 00       	mov    $0x0,%esi
f01009b5:	eb 0a                	jmp    f01009c1 <monitor+0x5c>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f01009b7:	c6 03 00             	movb   $0x0,(%ebx)
f01009ba:	89 f7                	mov    %esi,%edi
f01009bc:	8d 5b 01             	lea    0x1(%ebx),%ebx
f01009bf:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f01009c1:	0f b6 03             	movzbl (%ebx),%eax
f01009c4:	84 c0                	test   %al,%al
f01009c6:	74 63                	je     f0100a2b <monitor+0xc6>
f01009c8:	0f be c0             	movsbl %al,%eax
f01009cb:	89 44 24 04          	mov    %eax,0x4(%esp)
f01009cf:	c7 04 24 ac 59 10 f0 	movl   $0xf01059ac,(%esp)
f01009d6:	e8 bf 3e 00 00       	call   f010489a <strchr>
f01009db:	85 c0                	test   %eax,%eax
f01009dd:	75 d8                	jne    f01009b7 <monitor+0x52>
			*buf++ = 0;
		if (*buf == 0)
f01009df:	80 3b 00             	cmpb   $0x0,(%ebx)
f01009e2:	74 47                	je     f0100a2b <monitor+0xc6>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f01009e4:	83 fe 0f             	cmp    $0xf,%esi
f01009e7:	75 16                	jne    f01009ff <monitor+0x9a>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f01009e9:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f01009f0:	00 
f01009f1:	c7 04 24 b1 59 10 f0 	movl   $0xf01059b1,(%esp)
f01009f8:	e8 93 29 00 00       	call   f0103390 <cprintf>
f01009fd:	eb 98                	jmp    f0100997 <monitor+0x32>
			return 0;
		}
		argv[argc++] = buf;
f01009ff:	8d 7e 01             	lea    0x1(%esi),%edi
f0100a02:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100a06:	eb 03                	jmp    f0100a0b <monitor+0xa6>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f0100a08:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100a0b:	0f b6 03             	movzbl (%ebx),%eax
f0100a0e:	84 c0                	test   %al,%al
f0100a10:	74 ad                	je     f01009bf <monitor+0x5a>
f0100a12:	0f be c0             	movsbl %al,%eax
f0100a15:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a19:	c7 04 24 ac 59 10 f0 	movl   $0xf01059ac,(%esp)
f0100a20:	e8 75 3e 00 00       	call   f010489a <strchr>
f0100a25:	85 c0                	test   %eax,%eax
f0100a27:	74 df                	je     f0100a08 <monitor+0xa3>
f0100a29:	eb 94                	jmp    f01009bf <monitor+0x5a>
			buf++;
	}
	argv[argc] = 0;
f0100a2b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100a32:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100a33:	85 f6                	test   %esi,%esi
f0100a35:	0f 84 5c ff ff ff    	je     f0100997 <monitor+0x32>
f0100a3b:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100a40:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100a43:	8b 04 85 80 5b 10 f0 	mov    -0xfefa480(,%eax,4),%eax
f0100a4a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a4e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a51:	89 04 24             	mov    %eax,(%esp)
f0100a54:	e8 e3 3d 00 00       	call   f010483c <strcmp>
f0100a59:	85 c0                	test   %eax,%eax
f0100a5b:	75 24                	jne    f0100a81 <monitor+0x11c>
			return commands[i].func(argc, argv, tf);
f0100a5d:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a60:	8b 55 08             	mov    0x8(%ebp),%edx
f0100a63:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100a67:	8d 4d a8             	lea    -0x58(%ebp),%ecx
f0100a6a:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0100a6e:	89 34 24             	mov    %esi,(%esp)
f0100a71:	ff 14 85 88 5b 10 f0 	call   *-0xfefa478(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a78:	85 c0                	test   %eax,%eax
f0100a7a:	78 25                	js     f0100aa1 <monitor+0x13c>
f0100a7c:	e9 16 ff ff ff       	jmp    f0100997 <monitor+0x32>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a81:	83 c3 01             	add    $0x1,%ebx
f0100a84:	83 fb 03             	cmp    $0x3,%ebx
f0100a87:	75 b7                	jne    f0100a40 <monitor+0xdb>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a89:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100a8c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100a90:	c7 04 24 ce 59 10 f0 	movl   $0xf01059ce,(%esp)
f0100a97:	e8 f4 28 00 00       	call   f0103390 <cprintf>
f0100a9c:	e9 f6 fe ff ff       	jmp    f0100997 <monitor+0x32>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100aa1:	83 c4 5c             	add    $0x5c,%esp
f0100aa4:	5b                   	pop    %ebx
f0100aa5:	5e                   	pop    %esi
f0100aa6:	5f                   	pop    %edi
f0100aa7:	5d                   	pop    %ebp
f0100aa8:	c3                   	ret    
f0100aa9:	66 90                	xchg   %ax,%ax
f0100aab:	66 90                	xchg   %ax,%ax
f0100aad:	66 90                	xchg   %ax,%ax
f0100aaf:	90                   	nop

f0100ab0 <page2kva>:
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ab0:	2b 05 10 9f 22 f0    	sub    0xf0229f10,%eax
f0100ab6:	c1 f8 03             	sar    $0x3,%eax
f0100ab9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100abc:	89 c2                	mov    %eax,%edx
f0100abe:	c1 ea 0c             	shr    $0xc,%edx
f0100ac1:	3b 15 08 9f 22 f0    	cmp    0xf0229f08,%edx
f0100ac7:	72 26                	jb     f0100aef <page2kva+0x3f>
	return &pages[PGNUM(pa)];
}

static inline void*
page2kva(struct PageInfo *pp)
{
f0100ac9:	55                   	push   %ebp
f0100aca:	89 e5                	mov    %esp,%ebp
f0100acc:	83 ec 18             	sub    $0x18,%esp

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100acf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ad3:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0100ada:	f0 
f0100adb:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100ae2:	00 
f0100ae3:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f0100aea:	e8 51 f5 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100aef:	2d 00 00 00 10       	sub    $0x10000000,%eax

static inline void*
page2kva(struct PageInfo *pp)
{
	return KADDR(page2pa(pp));  //page2kva returns virtual address of the 
}
f0100af4:	c3                   	ret    

f0100af5 <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100af5:	89 d1                	mov    %edx,%ecx
f0100af7:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100afa:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100afd:	a8 01                	test   $0x1,%al
f0100aff:	74 5d                	je     f0100b5e <check_va2pa+0x69>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100b01:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100b06:	89 c1                	mov    %eax,%ecx
f0100b08:	c1 e9 0c             	shr    $0xc,%ecx
f0100b0b:	3b 0d 08 9f 22 f0    	cmp    0xf0229f08,%ecx
f0100b11:	72 26                	jb     f0100b39 <check_va2pa+0x44>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100b13:	55                   	push   %ebp
f0100b14:	89 e5                	mov    %esp,%ebp
f0100b16:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100b19:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100b1d:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0100b24:	f0 
f0100b25:	c7 44 24 04 e8 03 00 	movl   $0x3e8,0x4(%esp)
f0100b2c:	00 
f0100b2d:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0100b34:	e8 07 f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100b39:	c1 ea 0c             	shr    $0xc,%edx
f0100b3c:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100b42:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100b49:	89 c2                	mov    %eax,%edx
f0100b4b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100b4e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100b53:	85 d2                	test   %edx,%edx
f0100b55:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100b5a:	0f 44 c2             	cmove  %edx,%eax
f0100b5d:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100b5e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100b63:	c3                   	ret    

f0100b64 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100b64:	83 3d 3c 92 22 f0 00 	cmpl   $0x0,0xf022923c
f0100b6b:	75 11                	jne    f0100b7e <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100b6d:	ba 07 c0 26 f0       	mov    $0xf026c007,%edx
f0100b72:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b78:	89 15 3c 92 22 f0    	mov    %edx,0xf022923c
	}
	
	if (n==0){
f0100b7e:	85 c0                	test   %eax,%eax
f0100b80:	75 06                	jne    f0100b88 <boot_alloc+0x24>
	return nextfree;
f0100b82:	a1 3c 92 22 f0       	mov    0xf022923c,%eax
f0100b87:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100b88:	8b 0d 3c 92 22 f0    	mov    0xf022923c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100b8e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100b94:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100b9a:	01 ca                	add    %ecx,%edx
f0100b9c:	89 15 3c 92 22 f0    	mov    %edx,0xf022923c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100ba2:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100ba8:	77 26                	ja     f0100bd0 <boot_alloc+0x6c>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100baa:	55                   	push   %ebp
f0100bab:	89 e5                	mov    %esp,%ebp
f0100bad:	83 ec 18             	sub    $0x18,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100bb0:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100bb4:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0100bbb:	f0 
f0100bbc:	c7 44 24 04 71 00 00 	movl   $0x71,0x4(%esp)
f0100bc3:	00 
f0100bc4:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0100bcb:	e8 70 f4 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100bd0:	a1 08 9f 22 f0       	mov    0xf0229f08,%eax
f0100bd5:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100bd8:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
f0100bde:	39 c2                	cmp    %eax,%edx
f0100be0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100be5:	0f 46 c1             	cmovbe %ecx,%eax
	}
	return result;
}
f0100be8:	c3                   	ret    

f0100be9 <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100be9:	b8 01 00 00 00       	mov    $0x1,%eax
f0100bee:	eb 18                	jmp    f0100c08 <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100bf0:	8b 15 10 9f 22 f0    	mov    0xf0229f10,%edx
f0100bf6:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100bf9:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100bff:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100c05:	83 c0 01             	add    $0x1,%eax
f0100c08:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0100c0e:	72 e0                	jb     f0100bf0 <page_init+0x7>
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100c10:	55                   	push   %ebp
f0100c11:	89 e5                	mov    %esp,%ebp
f0100c13:	57                   	push   %edi
f0100c14:	56                   	push   %esi
f0100c15:	53                   	push   %ebx
f0100c16:	83 ec 1c             	sub    $0x1c,%esp

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100c19:	8b 35 48 92 22 f0    	mov    0xf0229248,%esi
f0100c1f:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100c24:	b8 01 00 00 00       	mov    $0x1,%eax
f0100c29:	eb 39                	jmp    f0100c64 <page_init+0x7b>
f0100c2b:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
		pages[i].pp_ref = 0;
f0100c32:	8b 0d 10 9f 22 f0    	mov    0xf0229f10,%ecx
f0100c38:	66 c7 44 11 04 00 00 	movw   $0x0,0x4(%ecx,%edx,1)
		pages[i].pp_link = 0;
f0100c3f:	c7 04 c1 00 00 00 00 	movl   $0x0,(%ecx,%eax,8)

		if (!page_free_list){		
f0100c46:	85 db                	test   %ebx,%ebx
f0100c48:	75 0a                	jne    f0100c54 <page_init+0x6b>
		page_free_list = &pages[i];	// if page_free_list is 0 then point to current page
f0100c4a:	89 d3                	mov    %edx,%ebx
f0100c4c:	03 1d 10 9f 22 f0    	add    0xf0229f10,%ebx
f0100c52:	eb 0d                	jmp    f0100c61 <page_init+0x78>
		}
		else{
		pages[i-1].pp_link = &pages[i];
f0100c54:	8b 0d 10 9f 22 f0    	mov    0xf0229f10,%ecx
f0100c5a:	8d 3c 11             	lea    (%ecx,%edx,1),%edi
f0100c5d:	89 7c 11 f8          	mov    %edi,-0x8(%ecx,%edx,1)

	
	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	for (i = 1; i < npages_basemem; i++) {
f0100c61:	83 c0 01             	add    $0x1,%eax
f0100c64:	39 f0                	cmp    %esi,%eax
f0100c66:	72 c3                	jb     f0100c2b <page_init+0x42>
f0100c68:	89 1d 44 92 22 f0    	mov    %ebx,0xf0229244
		}	//Previous page is linked to this current page
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100c6e:	8b 15 10 9f 22 f0    	mov    0xf0229f10,%edx
f0100c74:	8d 44 c2 f8          	lea    -0x8(%edx,%eax,8),%eax
f0100c78:	a3 38 92 22 f0       	mov    %eax,0xf0229238
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100c7d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c82:	e8 dd fe ff ff       	call   f0100b64 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c87:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100c8c:	77 20                	ja     f0100cae <page_init+0xc5>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c8e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c92:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0100c99:	f0 
f0100c9a:	c7 44 24 04 5c 01 00 	movl   $0x15c,0x4(%esp)
f0100ca1:	00 
f0100ca2:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0100ca9:	e8 92 f3 ff ff       	call   f0100040 <_panic>
f0100cae:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100cb3:	c1 e8 0c             	shr    $0xc,%eax
f0100cb6:	8b 1d 38 92 22 f0    	mov    0xf0229238,%ebx
f0100cbc:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100cc3:	eb 2c                	jmp    f0100cf1 <page_init+0x108>
		pages[i].pp_ref = 0;
f0100cc5:	89 d1                	mov    %edx,%ecx
f0100cc7:	03 0d 10 9f 22 f0    	add    0xf0229f10,%ecx
f0100ccd:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100cd3:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100cd9:	89 d1                	mov    %edx,%ecx
f0100cdb:	03 0d 10 9f 22 f0    	add    0xf0229f10,%ecx
f0100ce1:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100ce3:	89 d3                	mov    %edx,%ebx
f0100ce5:	03 1d 10 9f 22 f0    	add    0xf0229f10,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100ceb:	83 c0 01             	add    $0x1,%eax
f0100cee:	83 c2 08             	add    $0x8,%edx
f0100cf1:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0100cf7:	72 cc                	jb     f0100cc5 <page_init+0xdc>
f0100cf9:	89 1d 38 92 22 f0    	mov    %ebx,0xf0229238
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100cff:	a1 10 9f 22 f0       	mov    0xf0229f10,%eax
f0100d04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d08:	c7 04 24 a4 5b 10 f0 	movl   $0xf0105ba4,(%esp)
f0100d0f:	e8 7c 26 00 00       	call   f0103390 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100d14:	a1 10 9f 22 f0       	mov    0xf0229f10,%eax
f0100d19:	8b 15 08 9f 22 f0    	mov    0xf0229f08,%edx
f0100d1f:	8d 44 d0 f8          	lea    -0x8(%eax,%edx,8),%eax
f0100d23:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d27:	c7 04 24 33 62 10 f0 	movl   $0xf0106233,(%esp)
f0100d2e:	e8 5d 26 00 00       	call   f0103390 <cprintf>
}
f0100d33:	83 c4 1c             	add    $0x1c,%esp
f0100d36:	5b                   	pop    %ebx
f0100d37:	5e                   	pop    %esi
f0100d38:	5f                   	pop    %edi
f0100d39:	5d                   	pop    %ebp
f0100d3a:	c3                   	ret    

f0100d3b <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d3b:	55                   	push   %ebp
f0100d3c:	89 e5                	mov    %esp,%ebp
f0100d3e:	53                   	push   %ebx
f0100d3f:	83 ec 14             	sub    $0x14,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100d42:	8b 1d 44 92 22 f0    	mov    0xf0229244,%ebx
f0100d48:	85 db                	test   %ebx,%ebx
f0100d4a:	74 75                	je     f0100dc1 <page_alloc+0x86>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100d4c:	8b 03                	mov    (%ebx),%eax
f0100d4e:	a3 44 92 22 f0       	mov    %eax,0xf0229244
	allocPage->pp_link = NULL;	//Break the link 
f0100d53:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100d59:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100d5d:	74 58                	je     f0100db7 <page_alloc+0x7c>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d5f:	89 d8                	mov    %ebx,%eax
f0100d61:	2b 05 10 9f 22 f0    	sub    0xf0229f10,%eax
f0100d67:	c1 f8 03             	sar    $0x3,%eax
f0100d6a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d6d:	89 c2                	mov    %eax,%edx
f0100d6f:	c1 ea 0c             	shr    $0xc,%edx
f0100d72:	3b 15 08 9f 22 f0    	cmp    0xf0229f08,%edx
f0100d78:	72 20                	jb     f0100d9a <page_alloc+0x5f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d7a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d7e:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0100d85:	f0 
f0100d86:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100d8d:	00 
f0100d8e:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f0100d95:	e8 a6 f2 ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100d9a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100da1:	00 
f0100da2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100da9:	00 
	return (void *)(pa + KERNBASE);
f0100daa:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100daf:	89 04 24             	mov    %eax,(%esp)
f0100db2:	e8 20 3b 00 00       	call   f01048d7 <memset>
	}
	
	allocPage->pp_ref = 0;
f0100db7:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
f0100dbd:	89 d8                	mov    %ebx,%eax
f0100dbf:	eb 05                	jmp    f0100dc6 <page_alloc+0x8b>
page_alloc(int alloc_flags)
{
	// Check if there is a free_page available 
	if (!page_free_list)
	{ 
	return NULL;
f0100dc1:	b8 00 00 00 00       	mov    $0x0,%eax
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
	}
	
	allocPage->pp_ref = 0;
	return allocPage;
}
f0100dc6:	83 c4 14             	add    $0x14,%esp
f0100dc9:	5b                   	pop    %ebx
f0100dca:	5d                   	pop    %ebp
f0100dcb:	c3                   	ret    

f0100dcc <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100dcc:	55                   	push   %ebp
f0100dcd:	89 e5                	mov    %esp,%ebp
f0100dcf:	83 ec 18             	sub    $0x18,%esp
f0100dd2:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0100dd5:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f0100dda:	74 1c                	je     f0100df8 <page_free+0x2c>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f0100ddc:	c7 44 24 08 d0 5b 10 	movl   $0xf0105bd0,0x8(%esp)
f0100de3:	f0 
f0100de4:	c7 44 24 04 94 01 00 	movl   $0x194,0x4(%esp)
f0100deb:	00 
f0100dec:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0100df3:	e8 48 f2 ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0100df8:	85 c0                	test   %eax,%eax
f0100dfa:	75 1c                	jne    f0100e18 <page_free+0x4c>
	{
	panic("Page cannot be returned to free list as it is Null");
f0100dfc:	c7 44 24 08 10 5c 10 	movl   $0xf0105c10,0x8(%esp)
f0100e03:	f0 
f0100e04:	c7 44 24 04 9b 01 00 	movl   $0x19b,0x4(%esp)
f0100e0b:	00 
f0100e0c:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0100e13:	e8 28 f2 ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0100e18:	8b 15 44 92 22 f0    	mov    0xf0229244,%edx
f0100e1e:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100e20:	a3 44 92 22 f0       	mov    %eax,0xf0229244
	}


}
f0100e25:	c9                   	leave  
f0100e26:	c3                   	ret    

f0100e27 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100e27:	55                   	push   %ebp
f0100e28:	89 e5                	mov    %esp,%ebp
f0100e2a:	83 ec 18             	sub    $0x18,%esp
f0100e2d:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100e30:	0f b7 48 04          	movzwl 0x4(%eax),%ecx
f0100e34:	8d 51 ff             	lea    -0x1(%ecx),%edx
f0100e37:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100e3b:	66 85 d2             	test   %dx,%dx
f0100e3e:	75 08                	jne    f0100e48 <page_decref+0x21>
		page_free(pp);
f0100e40:	89 04 24             	mov    %eax,(%esp)
f0100e43:	e8 84 ff ff ff       	call   f0100dcc <page_free>
}
f0100e48:	c9                   	leave  
f0100e49:	c3                   	ret    

f0100e4a <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100e4a:	55                   	push   %ebp
f0100e4b:	89 e5                	mov    %esp,%ebp
f0100e4d:	57                   	push   %edi
f0100e4e:	56                   	push   %esi
f0100e4f:	53                   	push   %ebx
f0100e50:	83 ec 1c             	sub    $0x1c,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f0100e53:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0100e56:	c1 eb 16             	shr    $0x16,%ebx
f0100e59:	c1 e3 02             	shl    $0x2,%ebx
f0100e5c:	03 5d 08             	add    0x8(%ebp),%ebx

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f0100e5f:	8b 3b                	mov    (%ebx),%edi
f0100e61:	f7 c7 01 00 00 00    	test   $0x1,%edi
f0100e67:	74 3e                	je     f0100ea7 <pgdir_walk+0x5d>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f0100e69:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100e6f:	89 f8                	mov    %edi,%eax
f0100e71:	c1 e8 0c             	shr    $0xc,%eax
f0100e74:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0100e7a:	72 20                	jb     f0100e9c <pgdir_walk+0x52>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100e7c:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100e80:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0100e87:	f0 
f0100e88:	c7 44 24 04 dc 01 00 	movl   $0x1dc,0x4(%esp)
f0100e8f:	00 
f0100e90:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0100e97:	e8 a4 f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100e9c:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
f0100ea2:	e9 8f 00 00 00       	jmp    f0100f36 <pgdir_walk+0xec>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f0100ea7:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0100eab:	0f 84 94 00 00 00    	je     f0100f45 <pgdir_walk+0xfb>
f0100eb1:	c7 04 24 00 10 00 00 	movl   $0x1000,(%esp)
f0100eb8:	e8 7e fe ff ff       	call   f0100d3b <page_alloc>
f0100ebd:	89 c6                	mov    %eax,%esi
f0100ebf:	85 c0                	test   %eax,%eax
f0100ec1:	0f 84 85 00 00 00    	je     f0100f4c <pgdir_walk+0x102>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f0100ec7:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100ecc:	89 c7                	mov    %eax,%edi
f0100ece:	2b 3d 10 9f 22 f0    	sub    0xf0229f10,%edi
f0100ed4:	c1 ff 03             	sar    $0x3,%edi
f0100ed7:	c1 e7 0c             	shl    $0xc,%edi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100eda:	89 f8                	mov    %edi,%eax
f0100edc:	c1 e8 0c             	shr    $0xc,%eax
f0100edf:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0100ee5:	72 20                	jb     f0100f07 <pgdir_walk+0xbd>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100ee7:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0100eeb:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0100ef2:	f0 
f0100ef3:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0100efa:	00 
f0100efb:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f0100f02:	e8 39 f1 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100f07:	81 ef 00 00 00 10    	sub    $0x10000000,%edi
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f0100f0d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100f14:	00 
f0100f15:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100f1c:	00 
f0100f1d:	89 3c 24             	mov    %edi,(%esp)
f0100f20:	e8 b2 39 00 00       	call   f01048d7 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100f25:	2b 35 10 9f 22 f0    	sub    0xf0229f10,%esi
f0100f2b:	c1 fe 03             	sar    $0x3,%esi
f0100f2e:	c1 e6 0c             	shl    $0xc,%esi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0100f31:	83 ce 07             	or     $0x7,%esi
f0100f34:	89 33                	mov    %esi,(%ebx)
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f0100f36:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f39:	c1 e8 0a             	shr    $0xa,%eax
f0100f3c:	25 fc 0f 00 00       	and    $0xffc,%eax
f0100f41:	01 f8                	add    %edi,%eax
f0100f43:	eb 0c                	jmp    f0100f51 <pgdir_walk+0x107>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f0100f45:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f4a:	eb 05                	jmp    f0100f51 <pgdir_walk+0x107>
f0100f4c:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f0100f51:	83 c4 1c             	add    $0x1c,%esp
f0100f54:	5b                   	pop    %ebx
f0100f55:	5e                   	pop    %esi
f0100f56:	5f                   	pop    %edi
f0100f57:	5d                   	pop    %ebp
f0100f58:	c3                   	ret    

f0100f59 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100f59:	55                   	push   %ebp
f0100f5a:	89 e5                	mov    %esp,%ebp
f0100f5c:	53                   	push   %ebx
f0100f5d:	83 ec 14             	sub    $0x14,%esp
f0100f60:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0100f63:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100f6a:	00 
f0100f6b:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100f6e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f72:	8b 45 08             	mov    0x8(%ebp),%eax
f0100f75:	89 04 24             	mov    %eax,(%esp)
f0100f78:	e8 cd fe ff ff       	call   f0100e4a <pgdir_walk>
f0100f7d:	89 c2                	mov    %eax,%edx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f0100f7f:	85 c0                	test   %eax,%eax
f0100f81:	74 1a                	je     f0100f9d <page_lookup+0x44>
f0100f83:	8b 00                	mov    (%eax),%eax
f0100f85:	a8 01                	test   $0x1,%al
f0100f87:	74 1b                	je     f0100fa4 <page_lookup+0x4b>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f0100f89:	c1 e8 0c             	shr    $0xc,%eax
f0100f8c:	8b 0d 10 9f 22 f0    	mov    0xf0229f10,%ecx
f0100f92:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
		if (pte_store) {
f0100f95:	85 db                	test   %ebx,%ebx
f0100f97:	74 10                	je     f0100fa9 <page_lookup+0x50>
			*pte_store = pgTbEty;
f0100f99:	89 13                	mov    %edx,(%ebx)
f0100f9b:	eb 0c                	jmp    f0100fa9 <page_lookup+0x50>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f0100f9d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fa2:	eb 05                	jmp    f0100fa9 <page_lookup+0x50>
f0100fa4:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f0100fa9:	83 c4 14             	add    $0x14,%esp
f0100fac:	5b                   	pop    %ebx
f0100fad:	5d                   	pop    %ebp
f0100fae:	c3                   	ret    

f0100faf <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100faf:	55                   	push   %ebp
f0100fb0:	89 e5                	mov    %esp,%ebp
f0100fb2:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0100fb5:	e8 6f 3f 00 00       	call   f0104f29 <cpunum>
f0100fba:	6b c0 74             	imul   $0x74,%eax,%eax
f0100fbd:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f0100fc4:	74 16                	je     f0100fdc <tlb_invalidate+0x2d>
f0100fc6:	e8 5e 3f 00 00       	call   f0104f29 <cpunum>
f0100fcb:	6b c0 74             	imul   $0x74,%eax,%eax
f0100fce:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0100fd4:	8b 55 08             	mov    0x8(%ebp),%edx
f0100fd7:	39 50 60             	cmp    %edx,0x60(%eax)
f0100fda:	75 06                	jne    f0100fe2 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100fdc:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100fdf:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f0100fe2:	c9                   	leave  
f0100fe3:	c3                   	ret    

f0100fe4 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f0100fe4:	55                   	push   %ebp
f0100fe5:	89 e5                	mov    %esp,%ebp
f0100fe7:	56                   	push   %esi
f0100fe8:	53                   	push   %ebx
f0100fe9:	83 ec 20             	sub    $0x20,%esp
f0100fec:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100fef:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f0100ff2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ff5:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100ff9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ffd:	89 1c 24             	mov    %ebx,(%esp)
f0101000:	e8 54 ff ff ff       	call   f0100f59 <page_lookup>
f0101005:	85 c0                	test   %eax,%eax
f0101007:	74 1d                	je     f0101026 <page_remove+0x42>
		return;
	}
	page_decref(remPage);
f0101009:	89 04 24             	mov    %eax,(%esp)
f010100c:	e8 16 fe ff ff       	call   f0100e27 <page_decref>
	*pte = 0;
f0101011:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101014:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f010101a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010101e:	89 1c 24             	mov    %ebx,(%esp)
f0101021:	e8 89 ff ff ff       	call   f0100faf <tlb_invalidate>
}
f0101026:	83 c4 20             	add    $0x20,%esp
f0101029:	5b                   	pop    %ebx
f010102a:	5e                   	pop    %esi
f010102b:	5d                   	pop    %ebp
f010102c:	c3                   	ret    

f010102d <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010102d:	55                   	push   %ebp
f010102e:	89 e5                	mov    %esp,%ebp
f0101030:	57                   	push   %edi
f0101031:	56                   	push   %esi
f0101032:	53                   	push   %ebx
f0101033:	83 ec 1c             	sub    $0x1c,%esp
f0101036:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101039:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f010103c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101043:	00 
f0101044:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101048:	8b 45 08             	mov    0x8(%ebp),%eax
f010104b:	89 04 24             	mov    %eax,(%esp)
f010104e:	e8 f7 fd ff ff       	call   f0100e4a <pgdir_walk>
f0101053:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f0101055:	85 c0                	test   %eax,%eax
f0101057:	0f 84 85 00 00 00    	je     f01010e2 <page_insert+0xb5>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f010105d:	8b 00                	mov    (%eax),%eax
f010105f:	a8 01                	test   $0x1,%al
f0101061:	74 5b                	je     f01010be <page_insert+0x91>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f0101063:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101068:	89 f2                	mov    %esi,%edx
f010106a:	2b 15 10 9f 22 f0    	sub    0xf0229f10,%edx
f0101070:	c1 fa 03             	sar    $0x3,%edx
f0101073:	c1 e2 0c             	shl    $0xc,%edx
f0101076:	39 d0                	cmp    %edx,%eax
f0101078:	75 11                	jne    f010108b <page_insert+0x5e>
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f010107a:	8b 55 14             	mov    0x14(%ebp),%edx
f010107d:	83 ca 01             	or     $0x1,%edx
f0101080:	09 d0                	or     %edx,%eax
f0101082:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f0101084:	b8 00 00 00 00       	mov    $0x0,%eax
f0101089:	eb 5c                	jmp    f01010e7 <page_insert+0xba>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f010108b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010108f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101092:	89 04 24             	mov    %eax,(%esp)
f0101095:	e8 4a ff ff ff       	call   f0100fe4 <page_remove>
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f010109a:	8b 55 14             	mov    0x14(%ebp),%edx
f010109d:	83 ca 01             	or     $0x1,%edx
f01010a0:	89 f0                	mov    %esi,%eax
f01010a2:	2b 05 10 9f 22 f0    	sub    0xf0229f10,%eax
f01010a8:	c1 f8 03             	sar    $0x3,%eax
f01010ab:	c1 e0 0c             	shl    $0xc,%eax
f01010ae:	09 d0                	or     %edx,%eax
f01010b0:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f01010b2:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
		}
		return 0;
f01010b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01010bc:	eb 29                	jmp    f01010e7 <page_insert+0xba>
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f01010be:	8b 55 14             	mov    0x14(%ebp),%edx
f01010c1:	83 ca 01             	or     $0x1,%edx
f01010c4:	89 f0                	mov    %esi,%eax
f01010c6:	2b 05 10 9f 22 f0    	sub    0xf0229f10,%eax
f01010cc:	c1 f8 03             	sar    $0x3,%eax
f01010cf:	c1 e0 0c             	shl    $0xc,%eax
f01010d2:	09 d0                	or     %edx,%eax
f01010d4:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f01010d6:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f01010db:	b8 00 00 00 00       	mov    $0x0,%eax
f01010e0:	eb 05                	jmp    f01010e7 <page_insert+0xba>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f01010e2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f01010e7:	83 c4 1c             	add    $0x1c,%esp
f01010ea:	5b                   	pop    %ebx
f01010eb:	5e                   	pop    %esi
f01010ec:	5f                   	pop    %edi
f01010ed:	5d                   	pop    %ebp
f01010ee:	c3                   	ret    

f01010ef <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01010ef:	55                   	push   %ebp
f01010f0:	89 e5                	mov    %esp,%ebp
f01010f2:	83 ec 18             	sub    $0x18,%esp
	// okay to simply panic if this happens).
	//
	// Hint: The staff solution uses boot_map_region.
	//
	// Your code here:
	panic("mmio_map_region not implemented");
f01010f5:	c7 44 24 08 44 5c 10 	movl   $0xf0105c44,0x8(%esp)
f01010fc:	f0 
f01010fd:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f0101104:	00 
f0101105:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010110c:	e8 2f ef ff ff       	call   f0100040 <_panic>

f0101111 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101111:	55                   	push   %ebp
f0101112:	89 e5                	mov    %esp,%ebp
f0101114:	57                   	push   %edi
f0101115:	56                   	push   %esi
f0101116:	53                   	push   %ebx
f0101117:	83 ec 4c             	sub    $0x4c,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010111a:	c7 04 24 15 00 00 00 	movl   $0x15,(%esp)
f0101121:	e8 01 21 00 00       	call   f0103227 <mc146818_read>
f0101126:	89 c3                	mov    %eax,%ebx
f0101128:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f010112f:	e8 f3 20 00 00       	call   f0103227 <mc146818_read>
f0101134:	c1 e0 08             	shl    $0x8,%eax
f0101137:	09 c3                	or     %eax,%ebx
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101139:	89 d8                	mov    %ebx,%eax
f010113b:	c1 e0 0a             	shl    $0xa,%eax
f010113e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101144:	85 c0                	test   %eax,%eax
f0101146:	0f 48 c2             	cmovs  %edx,%eax
f0101149:	c1 f8 0c             	sar    $0xc,%eax
f010114c:	a3 48 92 22 f0       	mov    %eax,0xf0229248
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0101151:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101158:	e8 ca 20 00 00       	call   f0103227 <mc146818_read>
f010115d:	89 c3                	mov    %eax,%ebx
f010115f:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101166:	e8 bc 20 00 00       	call   f0103227 <mc146818_read>
f010116b:	c1 e0 08             	shl    $0x8,%eax
f010116e:	09 c3                	or     %eax,%ebx
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101170:	89 d8                	mov    %ebx,%eax
f0101172:	c1 e0 0a             	shl    $0xa,%eax
f0101175:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f010117b:	85 c0                	test   %eax,%eax
f010117d:	0f 48 c2             	cmovs  %edx,%eax
f0101180:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101183:	85 c0                	test   %eax,%eax
f0101185:	74 0e                	je     f0101195 <mem_init+0x84>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101187:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010118d:	89 15 08 9f 22 f0    	mov    %edx,0xf0229f08
f0101193:	eb 0c                	jmp    f01011a1 <mem_init+0x90>
	else
		npages = npages_basemem;
f0101195:	8b 15 48 92 22 f0    	mov    0xf0229248,%edx
f010119b:	89 15 08 9f 22 f0    	mov    %edx,0xf0229f08

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01011a1:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01011a4:	c1 e8 0a             	shr    $0xa,%eax
f01011a7:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01011ab:	a1 48 92 22 f0       	mov    0xf0229248,%eax
f01011b0:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01011b3:	c1 e8 0a             	shr    $0xa,%eax
f01011b6:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01011ba:	a1 08 9f 22 f0       	mov    0xf0229f08,%eax
f01011bf:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01011c2:	c1 e8 0a             	shr    $0xa,%eax
f01011c5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011c9:	c7 04 24 64 5c 10 f0 	movl   $0xf0105c64,(%esp)
f01011d0:	e8 bb 21 00 00       	call   f0103390 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01011d5:	b8 00 10 00 00       	mov    $0x1000,%eax
f01011da:	e8 85 f9 ff ff       	call   f0100b64 <boot_alloc>
f01011df:	a3 0c 9f 22 f0       	mov    %eax,0xf0229f0c
	memset(kern_pgdir, 0, PGSIZE);
f01011e4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01011eb:	00 
f01011ec:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01011f3:	00 
f01011f4:	89 04 24             	mov    %eax,(%esp)
f01011f7:	e8 db 36 00 00       	call   f01048d7 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01011fc:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101201:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101206:	77 20                	ja     f0101228 <mem_init+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101208:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010120c:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0101213:	f0 
f0101214:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f010121b:	00 
f010121c:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101223:	e8 18 ee ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101228:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010122e:	83 ca 05             	or     $0x5,%edx
f0101231:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f0101237:	a1 08 9f 22 f0       	mov    0xf0229f08,%eax
f010123c:	c1 e0 03             	shl    $0x3,%eax
f010123f:	e8 20 f9 ff ff       	call   f0100b64 <boot_alloc>
f0101244:	a3 10 9f 22 f0       	mov    %eax,0xf0229f10
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f0101249:	8b 3d 08 9f 22 f0    	mov    0xf0229f08,%edi
f010124f:	8d 14 fd 00 00 00 00 	lea    0x0(,%edi,8),%edx
f0101256:	89 54 24 08          	mov    %edx,0x8(%esp)
f010125a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101261:	00 
f0101262:	89 04 24             	mov    %eax,(%esp)
f0101265:	e8 6d 36 00 00       	call   f01048d7 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f010126a:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f010126f:	e8 f0 f8 ff ff       	call   f0100b64 <boot_alloc>
f0101274:	a3 4c 92 22 f0       	mov    %eax,0xf022924c
	memset(envs,0,sizeof(struct Env)*NENV);
f0101279:	c7 44 24 08 00 f0 01 	movl   $0x1f000,0x8(%esp)
f0101280:	00 
f0101281:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101288:	00 
f0101289:	89 04 24             	mov    %eax,(%esp)
f010128c:	e8 46 36 00 00       	call   f01048d7 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101291:	e8 53 f9 ff ff       	call   f0100be9 <page_init>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101296:	a1 44 92 22 f0       	mov    0xf0229244,%eax
f010129b:	85 c0                	test   %eax,%eax
f010129d:	75 1c                	jne    f01012bb <mem_init+0x1aa>
		panic("'page_free_list' is a null pointer!");
f010129f:	c7 44 24 08 a0 5c 10 	movl   $0xf0105ca0,0x8(%esp)
f01012a6:	f0 
f01012a7:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f01012ae:	00 
f01012af:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01012b6:	e8 85 ed ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f01012bb:	8d 55 d8             	lea    -0x28(%ebp),%edx
f01012be:	89 55 e0             	mov    %edx,-0x20(%ebp)
f01012c1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01012c4:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01012c7:	89 c2                	mov    %eax,%edx
f01012c9:	2b 15 10 9f 22 f0    	sub    0xf0229f10,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01012cf:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f01012d5:	0f 95 c2             	setne  %dl
f01012d8:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f01012db:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f01012df:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f01012e1:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01012e5:	8b 00                	mov    (%eax),%eax
f01012e7:	85 c0                	test   %eax,%eax
f01012e9:	75 dc                	jne    f01012c7 <mem_init+0x1b6>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01012eb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012ee:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01012f4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01012f7:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01012fa:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01012fc:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f01012ff:	89 1d 44 92 22 f0    	mov    %ebx,0xf0229244
f0101305:	eb 64                	jmp    f010136b <mem_init+0x25a>
f0101307:	89 d8                	mov    %ebx,%eax
f0101309:	2b 05 10 9f 22 f0    	sub    0xf0229f10,%eax
f010130f:	c1 f8 03             	sar    $0x3,%eax
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
f0101312:	89 c2                	mov    %eax,%edx
f0101314:	c1 e2 0c             	shl    $0xc,%edx
f0101317:	a9 00 fc 0f 00       	test   $0xffc00,%eax
f010131c:	75 4b                	jne    f0101369 <mem_init+0x258>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010131e:	89 d0                	mov    %edx,%eax
f0101320:	c1 e8 0c             	shr    $0xc,%eax
f0101323:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0101329:	72 20                	jb     f010134b <mem_init+0x23a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010132b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010132f:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0101336:	f0 
f0101337:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f010133e:	00 
f010133f:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f0101346:	e8 f5 ec ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f010134b:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0101352:	00 
f0101353:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f010135a:	00 
	return (void *)(pa + KERNBASE);
f010135b:	81 ea 00 00 00 10    	sub    $0x10000000,%edx
f0101361:	89 14 24             	mov    %edx,(%esp)
f0101364:	e8 6e 35 00 00       	call   f01048d7 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101369:	8b 1b                	mov    (%ebx),%ebx
f010136b:	85 db                	test   %ebx,%ebx
f010136d:	75 98                	jne    f0101307 <mem_init+0x1f6>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f010136f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101374:	e8 eb f7 ff ff       	call   f0100b64 <boot_alloc>
f0101379:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f010137c:	8b 15 44 92 22 f0    	mov    0xf0229244,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101382:	8b 0d 10 9f 22 f0    	mov    0xf0229f10,%ecx
		assert(pp < pages + npages);
f0101388:	a1 08 9f 22 f0       	mov    0xf0229f08,%eax
f010138d:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0101390:	8d 04 c1             	lea    (%ecx,%eax,8),%eax
f0101393:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101396:	89 4d cc             	mov    %ecx,-0x34(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101399:	bf 00 00 00 00       	mov    $0x0,%edi
f010139e:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f01013a1:	e9 c4 01 00 00       	jmp    f010156a <mem_init+0x459>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01013a6:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01013a9:	76 24                	jbe    f01013cf <mem_init+0x2be>
f01013ab:	c7 44 24 0c 4a 62 10 	movl   $0xf010624a,0xc(%esp)
f01013b2:	f0 
f01013b3:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01013ba:	f0 
f01013bb:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f01013c2:	00 
f01013c3:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01013ca:	e8 71 ec ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f01013cf:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f01013d2:	72 24                	jb     f01013f8 <mem_init+0x2e7>
f01013d4:	c7 44 24 0c 6b 62 10 	movl   $0xf010626b,0xc(%esp)
f01013db:	f0 
f01013dc:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01013e3:	f0 
f01013e4:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f01013eb:	00 
f01013ec:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01013f3:	e8 48 ec ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f01013f8:	89 d0                	mov    %edx,%eax
f01013fa:	2b 45 cc             	sub    -0x34(%ebp),%eax
f01013fd:	a8 07                	test   $0x7,%al
f01013ff:	74 24                	je     f0101425 <mem_init+0x314>
f0101401:	c7 44 24 0c c4 5c 10 	movl   $0xf0105cc4,0xc(%esp)
f0101408:	f0 
f0101409:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101410:	f0 
f0101411:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0101418:	00 
f0101419:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101420:	e8 1b ec ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101425:	c1 f8 03             	sar    $0x3,%eax
f0101428:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f010142b:	85 c0                	test   %eax,%eax
f010142d:	75 24                	jne    f0101453 <mem_init+0x342>
f010142f:	c7 44 24 0c 7f 62 10 	movl   $0xf010627f,0xc(%esp)
f0101436:	f0 
f0101437:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010143e:	f0 
f010143f:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f0101446:	00 
f0101447:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010144e:	e8 ed eb ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101453:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101458:	75 24                	jne    f010147e <mem_init+0x36d>
f010145a:	c7 44 24 0c 90 62 10 	movl   $0xf0106290,0xc(%esp)
f0101461:	f0 
f0101462:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101469:	f0 
f010146a:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f0101471:	00 
f0101472:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101479:	e8 c2 eb ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010147e:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101483:	75 24                	jne    f01014a9 <mem_init+0x398>
f0101485:	c7 44 24 0c f8 5c 10 	movl   $0xf0105cf8,0xc(%esp)
f010148c:	f0 
f010148d:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101494:	f0 
f0101495:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f010149c:	00 
f010149d:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01014a4:	e8 97 eb ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01014a9:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01014ae:	75 24                	jne    f01014d4 <mem_init+0x3c3>
f01014b0:	c7 44 24 0c a9 62 10 	movl   $0xf01062a9,0xc(%esp)
f01014b7:	f0 
f01014b8:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01014bf:	f0 
f01014c0:	c7 44 24 04 3e 03 00 	movl   $0x33e,0x4(%esp)
f01014c7:	00 
f01014c8:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01014cf:	e8 6c eb ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01014d4:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01014d9:	0f 86 87 13 00 00    	jbe    f0102866 <mem_init+0x1755>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014df:	89 c1                	mov    %eax,%ecx
f01014e1:	c1 e9 0c             	shr    $0xc,%ecx
f01014e4:	39 4d c4             	cmp    %ecx,-0x3c(%ebp)
f01014e7:	77 20                	ja     f0101509 <mem_init+0x3f8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014e9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014ed:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f01014f4:	f0 
f01014f5:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f01014fc:	00 
f01014fd:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f0101504:	e8 37 eb ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101509:	8d 88 00 00 00 f0    	lea    -0x10000000(%eax),%ecx
f010150f:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0101512:	0f 86 5e 13 00 00    	jbe    f0102876 <mem_init+0x1765>
f0101518:	c7 44 24 0c 1c 5d 10 	movl   $0xf0105d1c,0xc(%esp)
f010151f:	f0 
f0101520:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101527:	f0 
f0101528:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f010152f:	00 
f0101530:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101537:	e8 04 eb ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f010153c:	c7 44 24 0c c3 62 10 	movl   $0xf01062c3,0xc(%esp)
f0101543:	f0 
f0101544:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010154b:	f0 
f010154c:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0101553:	00 
f0101554:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010155b:	e8 e0 ea ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0101560:	83 c3 01             	add    $0x1,%ebx
f0101563:	eb 03                	jmp    f0101568 <mem_init+0x457>
		else
			++nfree_extmem;
f0101565:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101568:	8b 12                	mov    (%edx),%edx
f010156a:	85 d2                	test   %edx,%edx
f010156c:	0f 85 34 fe ff ff    	jne    f01013a6 <mem_init+0x295>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0101572:	85 db                	test   %ebx,%ebx
f0101574:	7f 24                	jg     f010159a <mem_init+0x489>
f0101576:	c7 44 24 0c e0 62 10 	movl   $0xf01062e0,0xc(%esp)
f010157d:	f0 
f010157e:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101585:	f0 
f0101586:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f010158d:	00 
f010158e:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101595:	e8 a6 ea ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f010159a:	85 ff                	test   %edi,%edi
f010159c:	7f 24                	jg     f01015c2 <mem_init+0x4b1>
f010159e:	c7 44 24 0c f2 62 10 	movl   $0xf01062f2,0xc(%esp)
f01015a5:	f0 
f01015a6:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01015ad:	f0 
f01015ae:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f01015b5:	00 
f01015b6:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01015bd:	e8 7e ea ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f01015c2:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f01015c9:	00 
f01015ca:	c7 04 24 64 5d 10 f0 	movl   $0xf0105d64,(%esp)
f01015d1:	e8 ba 1d 00 00       	call   f0103390 <cprintf>

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015d6:	a1 44 92 22 f0       	mov    0xf0229244,%eax
f01015db:	bb 00 00 00 00       	mov    $0x0,%ebx
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01015e0:	83 3d 10 9f 22 f0 00 	cmpl   $0x0,0xf0229f10
f01015e7:	75 21                	jne    f010160a <mem_init+0x4f9>
		panic("'pages' is a null pointer!");
f01015e9:	c7 44 24 08 03 63 10 	movl   $0xf0106303,0x8(%esp)
f01015f0:	f0 
f01015f1:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f01015f8:	00 
f01015f9:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101600:	e8 3b ea ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
		++nfree;
f0101605:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101608:	8b 00                	mov    (%eax),%eax
f010160a:	85 c0                	test   %eax,%eax
f010160c:	75 f7                	jne    f0101605 <mem_init+0x4f4>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010160e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101615:	e8 21 f7 ff ff       	call   f0100d3b <page_alloc>
f010161a:	89 c7                	mov    %eax,%edi
f010161c:	85 c0                	test   %eax,%eax
f010161e:	75 24                	jne    f0101644 <mem_init+0x533>
f0101620:	c7 44 24 0c 1e 63 10 	movl   $0xf010631e,0xc(%esp)
f0101627:	f0 
f0101628:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010162f:	f0 
f0101630:	c7 44 24 04 64 03 00 	movl   $0x364,0x4(%esp)
f0101637:	00 
f0101638:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010163f:	e8 fc e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101644:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010164b:	e8 eb f6 ff ff       	call   f0100d3b <page_alloc>
f0101650:	89 c6                	mov    %eax,%esi
f0101652:	85 c0                	test   %eax,%eax
f0101654:	75 24                	jne    f010167a <mem_init+0x569>
f0101656:	c7 44 24 0c 34 63 10 	movl   $0xf0106334,0xc(%esp)
f010165d:	f0 
f010165e:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101665:	f0 
f0101666:	c7 44 24 04 65 03 00 	movl   $0x365,0x4(%esp)
f010166d:	00 
f010166e:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101675:	e8 c6 e9 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010167a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101681:	e8 b5 f6 ff ff       	call   f0100d3b <page_alloc>
f0101686:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101689:	85 c0                	test   %eax,%eax
f010168b:	75 24                	jne    f01016b1 <mem_init+0x5a0>
f010168d:	c7 44 24 0c 4a 63 10 	movl   $0xf010634a,0xc(%esp)
f0101694:	f0 
f0101695:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010169c:	f0 
f010169d:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f01016a4:	00 
f01016a5:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01016ac:	e8 8f e9 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01016b1:	39 f7                	cmp    %esi,%edi
f01016b3:	75 24                	jne    f01016d9 <mem_init+0x5c8>
f01016b5:	c7 44 24 0c 60 63 10 	movl   $0xf0106360,0xc(%esp)
f01016bc:	f0 
f01016bd:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01016c4:	f0 
f01016c5:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f01016cc:	00 
f01016cd:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01016d4:	e8 67 e9 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01016d9:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016dc:	39 c6                	cmp    %eax,%esi
f01016de:	74 04                	je     f01016e4 <mem_init+0x5d3>
f01016e0:	39 c7                	cmp    %eax,%edi
f01016e2:	75 24                	jne    f0101708 <mem_init+0x5f7>
f01016e4:	c7 44 24 0c 8c 5d 10 	movl   $0xf0105d8c,0xc(%esp)
f01016eb:	f0 
f01016ec:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01016f3:	f0 
f01016f4:	c7 44 24 04 6a 03 00 	movl   $0x36a,0x4(%esp)
f01016fb:	00 
f01016fc:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101703:	e8 38 e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101708:	8b 15 10 9f 22 f0    	mov    0xf0229f10,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010170e:	a1 08 9f 22 f0       	mov    0xf0229f08,%eax
f0101713:	c1 e0 0c             	shl    $0xc,%eax
f0101716:	89 f9                	mov    %edi,%ecx
f0101718:	29 d1                	sub    %edx,%ecx
f010171a:	c1 f9 03             	sar    $0x3,%ecx
f010171d:	c1 e1 0c             	shl    $0xc,%ecx
f0101720:	39 c1                	cmp    %eax,%ecx
f0101722:	72 24                	jb     f0101748 <mem_init+0x637>
f0101724:	c7 44 24 0c 72 63 10 	movl   $0xf0106372,0xc(%esp)
f010172b:	f0 
f010172c:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101733:	f0 
f0101734:	c7 44 24 04 6b 03 00 	movl   $0x36b,0x4(%esp)
f010173b:	00 
f010173c:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101743:	e8 f8 e8 ff ff       	call   f0100040 <_panic>
f0101748:	89 f1                	mov    %esi,%ecx
f010174a:	29 d1                	sub    %edx,%ecx
f010174c:	c1 f9 03             	sar    $0x3,%ecx
f010174f:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101752:	39 c8                	cmp    %ecx,%eax
f0101754:	77 24                	ja     f010177a <mem_init+0x669>
f0101756:	c7 44 24 0c 8f 63 10 	movl   $0xf010638f,0xc(%esp)
f010175d:	f0 
f010175e:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101765:	f0 
f0101766:	c7 44 24 04 6c 03 00 	movl   $0x36c,0x4(%esp)
f010176d:	00 
f010176e:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101775:	e8 c6 e8 ff ff       	call   f0100040 <_panic>
f010177a:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010177d:	29 d1                	sub    %edx,%ecx
f010177f:	89 ca                	mov    %ecx,%edx
f0101781:	c1 fa 03             	sar    $0x3,%edx
f0101784:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101787:	39 d0                	cmp    %edx,%eax
f0101789:	77 24                	ja     f01017af <mem_init+0x69e>
f010178b:	c7 44 24 0c ac 63 10 	movl   $0xf01063ac,0xc(%esp)
f0101792:	f0 
f0101793:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010179a:	f0 
f010179b:	c7 44 24 04 6d 03 00 	movl   $0x36d,0x4(%esp)
f01017a2:	00 
f01017a3:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01017aa:	e8 91 e8 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01017af:	a1 44 92 22 f0       	mov    0xf0229244,%eax
f01017b4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01017b7:	c7 05 44 92 22 f0 00 	movl   $0x0,0xf0229244
f01017be:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01017c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c8:	e8 6e f5 ff ff       	call   f0100d3b <page_alloc>
f01017cd:	85 c0                	test   %eax,%eax
f01017cf:	74 24                	je     f01017f5 <mem_init+0x6e4>
f01017d1:	c7 44 24 0c c9 63 10 	movl   $0xf01063c9,0xc(%esp)
f01017d8:	f0 
f01017d9:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01017e0:	f0 
f01017e1:	c7 44 24 04 74 03 00 	movl   $0x374,0x4(%esp)
f01017e8:	00 
f01017e9:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01017f0:	e8 4b e8 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01017f5:	89 3c 24             	mov    %edi,(%esp)
f01017f8:	e8 cf f5 ff ff       	call   f0100dcc <page_free>
	page_free(pp1);
f01017fd:	89 34 24             	mov    %esi,(%esp)
f0101800:	e8 c7 f5 ff ff       	call   f0100dcc <page_free>
	page_free(pp2);
f0101805:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101808:	89 04 24             	mov    %eax,(%esp)
f010180b:	e8 bc f5 ff ff       	call   f0100dcc <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101810:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101817:	e8 1f f5 ff ff       	call   f0100d3b <page_alloc>
f010181c:	89 c6                	mov    %eax,%esi
f010181e:	85 c0                	test   %eax,%eax
f0101820:	75 24                	jne    f0101846 <mem_init+0x735>
f0101822:	c7 44 24 0c 1e 63 10 	movl   $0xf010631e,0xc(%esp)
f0101829:	f0 
f010182a:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101831:	f0 
f0101832:	c7 44 24 04 7b 03 00 	movl   $0x37b,0x4(%esp)
f0101839:	00 
f010183a:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101841:	e8 fa e7 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101846:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010184d:	e8 e9 f4 ff ff       	call   f0100d3b <page_alloc>
f0101852:	89 c7                	mov    %eax,%edi
f0101854:	85 c0                	test   %eax,%eax
f0101856:	75 24                	jne    f010187c <mem_init+0x76b>
f0101858:	c7 44 24 0c 34 63 10 	movl   $0xf0106334,0xc(%esp)
f010185f:	f0 
f0101860:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101867:	f0 
f0101868:	c7 44 24 04 7c 03 00 	movl   $0x37c,0x4(%esp)
f010186f:	00 
f0101870:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101877:	e8 c4 e7 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f010187c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101883:	e8 b3 f4 ff ff       	call   f0100d3b <page_alloc>
f0101888:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010188b:	85 c0                	test   %eax,%eax
f010188d:	75 24                	jne    f01018b3 <mem_init+0x7a2>
f010188f:	c7 44 24 0c 4a 63 10 	movl   $0xf010634a,0xc(%esp)
f0101896:	f0 
f0101897:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010189e:	f0 
f010189f:	c7 44 24 04 7d 03 00 	movl   $0x37d,0x4(%esp)
f01018a6:	00 
f01018a7:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01018ae:	e8 8d e7 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01018b3:	39 fe                	cmp    %edi,%esi
f01018b5:	75 24                	jne    f01018db <mem_init+0x7ca>
f01018b7:	c7 44 24 0c 60 63 10 	movl   $0xf0106360,0xc(%esp)
f01018be:	f0 
f01018bf:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01018c6:	f0 
f01018c7:	c7 44 24 04 7f 03 00 	movl   $0x37f,0x4(%esp)
f01018ce:	00 
f01018cf:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01018d6:	e8 65 e7 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018db:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01018de:	39 c7                	cmp    %eax,%edi
f01018e0:	74 04                	je     f01018e6 <mem_init+0x7d5>
f01018e2:	39 c6                	cmp    %eax,%esi
f01018e4:	75 24                	jne    f010190a <mem_init+0x7f9>
f01018e6:	c7 44 24 0c 8c 5d 10 	movl   $0xf0105d8c,0xc(%esp)
f01018ed:	f0 
f01018ee:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01018f5:	f0 
f01018f6:	c7 44 24 04 80 03 00 	movl   $0x380,0x4(%esp)
f01018fd:	00 
f01018fe:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101905:	e8 36 e7 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f010190a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101911:	e8 25 f4 ff ff       	call   f0100d3b <page_alloc>
f0101916:	85 c0                	test   %eax,%eax
f0101918:	74 24                	je     f010193e <mem_init+0x82d>
f010191a:	c7 44 24 0c c9 63 10 	movl   $0xf01063c9,0xc(%esp)
f0101921:	f0 
f0101922:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101929:	f0 
f010192a:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0101931:	00 
f0101932:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101939:	e8 02 e7 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010193e:	89 f0                	mov    %esi,%eax
f0101940:	e8 6b f1 ff ff       	call   f0100ab0 <page2kva>
f0101945:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010194c:	00 
f010194d:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101954:	00 
f0101955:	89 04 24             	mov    %eax,(%esp)
f0101958:	e8 7a 2f 00 00       	call   f01048d7 <memset>
	page_free(pp0);
f010195d:	89 34 24             	mov    %esi,(%esp)
f0101960:	e8 67 f4 ff ff       	call   f0100dcc <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101965:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010196c:	e8 ca f3 ff ff       	call   f0100d3b <page_alloc>
f0101971:	85 c0                	test   %eax,%eax
f0101973:	75 24                	jne    f0101999 <mem_init+0x888>
f0101975:	c7 44 24 0c d8 63 10 	movl   $0xf01063d8,0xc(%esp)
f010197c:	f0 
f010197d:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101984:	f0 
f0101985:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f010198c:	00 
f010198d:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101994:	e8 a7 e6 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101999:	39 c6                	cmp    %eax,%esi
f010199b:	74 24                	je     f01019c1 <mem_init+0x8b0>
f010199d:	c7 44 24 0c f6 63 10 	movl   $0xf01063f6,0xc(%esp)
f01019a4:	f0 
f01019a5:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01019ac:	f0 
f01019ad:	c7 44 24 04 87 03 00 	movl   $0x387,0x4(%esp)
f01019b4:	00 
f01019b5:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01019bc:	e8 7f e6 ff ff       	call   f0100040 <_panic>
	c = page2kva(pp);
f01019c1:	89 f0                	mov    %esi,%eax
f01019c3:	e8 e8 f0 ff ff       	call   f0100ab0 <page2kva>
	for (i = 0; i < PGSIZE; i++)
f01019c8:	ba 00 00 00 00       	mov    $0x0,%edx
		assert(c[i] == 0);
f01019cd:	80 3c 10 00          	cmpb   $0x0,(%eax,%edx,1)
f01019d1:	74 24                	je     f01019f7 <mem_init+0x8e6>
f01019d3:	c7 44 24 0c 06 64 10 	movl   $0xf0106406,0xc(%esp)
f01019da:	f0 
f01019db:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01019e2:	f0 
f01019e3:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f01019ea:	00 
f01019eb:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01019f2:	e8 49 e6 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01019f7:	83 c2 01             	add    $0x1,%edx
f01019fa:	81 fa 00 10 00 00    	cmp    $0x1000,%edx
f0101a00:	75 cb                	jne    f01019cd <mem_init+0x8bc>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101a02:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101a05:	a3 44 92 22 f0       	mov    %eax,0xf0229244

	// free the pages we took
	page_free(pp0);
f0101a0a:	89 34 24             	mov    %esi,(%esp)
f0101a0d:	e8 ba f3 ff ff       	call   f0100dcc <page_free>
	page_free(pp1);
f0101a12:	89 3c 24             	mov    %edi,(%esp)
f0101a15:	e8 b2 f3 ff ff       	call   f0100dcc <page_free>
	page_free(pp2);
f0101a1a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a1d:	89 04 24             	mov    %eax,(%esp)
f0101a20:	e8 a7 f3 ff ff       	call   f0100dcc <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a25:	a1 44 92 22 f0       	mov    0xf0229244,%eax
f0101a2a:	eb 05                	jmp    f0101a31 <mem_init+0x920>
		--nfree;
f0101a2c:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a2f:	8b 00                	mov    (%eax),%eax
f0101a31:	85 c0                	test   %eax,%eax
f0101a33:	75 f7                	jne    f0101a2c <mem_init+0x91b>
		--nfree;
	assert(nfree == 0);
f0101a35:	85 db                	test   %ebx,%ebx
f0101a37:	74 24                	je     f0101a5d <mem_init+0x94c>
f0101a39:	c7 44 24 0c 10 64 10 	movl   $0xf0106410,0xc(%esp)
f0101a40:	f0 
f0101a41:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101a48:	f0 
f0101a49:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0101a50:	00 
f0101a51:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101a58:	e8 e3 e5 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101a5d:	c7 04 24 ac 5d 10 f0 	movl   $0xf0105dac,(%esp)
f0101a64:	e8 27 19 00 00       	call   f0103390 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a69:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a70:	e8 c6 f2 ff ff       	call   f0100d3b <page_alloc>
f0101a75:	89 c3                	mov    %eax,%ebx
f0101a77:	85 c0                	test   %eax,%eax
f0101a79:	75 24                	jne    f0101a9f <mem_init+0x98e>
f0101a7b:	c7 44 24 0c 1e 63 10 	movl   $0xf010631e,0xc(%esp)
f0101a82:	f0 
f0101a83:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101a8a:	f0 
f0101a8b:	c7 44 24 04 fd 03 00 	movl   $0x3fd,0x4(%esp)
f0101a92:	00 
f0101a93:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101a9a:	e8 a1 e5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a9f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101aa6:	e8 90 f2 ff ff       	call   f0100d3b <page_alloc>
f0101aab:	89 c6                	mov    %eax,%esi
f0101aad:	85 c0                	test   %eax,%eax
f0101aaf:	75 24                	jne    f0101ad5 <mem_init+0x9c4>
f0101ab1:	c7 44 24 0c 34 63 10 	movl   $0xf0106334,0xc(%esp)
f0101ab8:	f0 
f0101ab9:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101ac0:	f0 
f0101ac1:	c7 44 24 04 fe 03 00 	movl   $0x3fe,0x4(%esp)
f0101ac8:	00 
f0101ac9:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101ad0:	e8 6b e5 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101ad5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101adc:	e8 5a f2 ff ff       	call   f0100d3b <page_alloc>
f0101ae1:	89 c7                	mov    %eax,%edi
f0101ae3:	85 c0                	test   %eax,%eax
f0101ae5:	75 24                	jne    f0101b0b <mem_init+0x9fa>
f0101ae7:	c7 44 24 0c 4a 63 10 	movl   $0xf010634a,0xc(%esp)
f0101aee:	f0 
f0101aef:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101af6:	f0 
f0101af7:	c7 44 24 04 ff 03 00 	movl   $0x3ff,0x4(%esp)
f0101afe:	00 
f0101aff:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101b06:	e8 35 e5 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b0b:	39 f3                	cmp    %esi,%ebx
f0101b0d:	75 24                	jne    f0101b33 <mem_init+0xa22>
f0101b0f:	c7 44 24 0c 60 63 10 	movl   $0xf0106360,0xc(%esp)
f0101b16:	f0 
f0101b17:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101b1e:	f0 
f0101b1f:	c7 44 24 04 02 04 00 	movl   $0x402,0x4(%esp)
f0101b26:	00 
f0101b27:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101b2e:	e8 0d e5 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b33:	39 c6                	cmp    %eax,%esi
f0101b35:	74 04                	je     f0101b3b <mem_init+0xa2a>
f0101b37:	39 c3                	cmp    %eax,%ebx
f0101b39:	75 24                	jne    f0101b5f <mem_init+0xa4e>
f0101b3b:	c7 44 24 0c 8c 5d 10 	movl   $0xf0105d8c,0xc(%esp)
f0101b42:	f0 
f0101b43:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101b4a:	f0 
f0101b4b:	c7 44 24 04 03 04 00 	movl   $0x403,0x4(%esp)
f0101b52:	00 
f0101b53:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101b5a:	e8 e1 e4 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b5f:	a1 44 92 22 f0       	mov    0xf0229244,%eax
f0101b64:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	page_free_list = 0;
f0101b67:	c7 05 44 92 22 f0 00 	movl   $0x0,0xf0229244
f0101b6e:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b71:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b78:	e8 be f1 ff ff       	call   f0100d3b <page_alloc>
f0101b7d:	85 c0                	test   %eax,%eax
f0101b7f:	74 24                	je     f0101ba5 <mem_init+0xa94>
f0101b81:	c7 44 24 0c c9 63 10 	movl   $0xf01063c9,0xc(%esp)
f0101b88:	f0 
f0101b89:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101b90:	f0 
f0101b91:	c7 44 24 04 0b 04 00 	movl   $0x40b,0x4(%esp)
f0101b98:	00 
f0101b99:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101ba0:	e8 9b e4 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101ba5:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101ba8:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101bac:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101bb3:	00 
f0101bb4:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0101bb9:	89 04 24             	mov    %eax,(%esp)
f0101bbc:	e8 98 f3 ff ff       	call   f0100f59 <page_lookup>
f0101bc1:	85 c0                	test   %eax,%eax
f0101bc3:	74 24                	je     f0101be9 <mem_init+0xad8>
f0101bc5:	c7 44 24 0c cc 5d 10 	movl   $0xf0105dcc,0xc(%esp)
f0101bcc:	f0 
f0101bcd:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101bd4:	f0 
f0101bd5:	c7 44 24 04 0f 04 00 	movl   $0x40f,0x4(%esp)
f0101bdc:	00 
f0101bdd:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101be4:	e8 57 e4 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101be9:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bf0:	00 
f0101bf1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101bf8:	00 
f0101bf9:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101bfd:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0101c02:	89 04 24             	mov    %eax,(%esp)
f0101c05:	e8 23 f4 ff ff       	call   f010102d <page_insert>
f0101c0a:	85 c0                	test   %eax,%eax
f0101c0c:	78 24                	js     f0101c32 <mem_init+0xb21>
f0101c0e:	c7 44 24 0c 04 5e 10 	movl   $0xf0105e04,0xc(%esp)
f0101c15:	f0 
f0101c16:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101c1d:	f0 
f0101c1e:	c7 44 24 04 12 04 00 	movl   $0x412,0x4(%esp)
f0101c25:	00 
f0101c26:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101c2d:	e8 0e e4 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101c32:	89 1c 24             	mov    %ebx,(%esp)
f0101c35:	e8 92 f1 ff ff       	call   f0100dcc <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101c3a:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c41:	00 
f0101c42:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c49:	00 
f0101c4a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101c4e:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0101c53:	89 04 24             	mov    %eax,(%esp)
f0101c56:	e8 d2 f3 ff ff       	call   f010102d <page_insert>
f0101c5b:	85 c0                	test   %eax,%eax
f0101c5d:	74 24                	je     f0101c83 <mem_init+0xb72>
f0101c5f:	c7 44 24 0c 34 5e 10 	movl   $0xf0105e34,0xc(%esp)
f0101c66:	f0 
f0101c67:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101c6e:	f0 
f0101c6f:	c7 44 24 04 16 04 00 	movl   $0x416,0x4(%esp)
f0101c76:	00 
f0101c77:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101c7e:	e8 bd e3 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101c83:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0101c88:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101c8b:	8b 0d 10 9f 22 f0    	mov    0xf0229f10,%ecx
f0101c91:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0101c94:	8b 00                	mov    (%eax),%eax
f0101c96:	89 45 c8             	mov    %eax,-0x38(%ebp)
f0101c99:	89 c2                	mov    %eax,%edx
f0101c9b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101ca1:	89 d8                	mov    %ebx,%eax
f0101ca3:	29 c8                	sub    %ecx,%eax
f0101ca5:	c1 f8 03             	sar    $0x3,%eax
f0101ca8:	c1 e0 0c             	shl    $0xc,%eax
f0101cab:	39 c2                	cmp    %eax,%edx
f0101cad:	74 24                	je     f0101cd3 <mem_init+0xbc2>
f0101caf:	c7 44 24 0c 64 5e 10 	movl   $0xf0105e64,0xc(%esp)
f0101cb6:	f0 
f0101cb7:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101cbe:	f0 
f0101cbf:	c7 44 24 04 17 04 00 	movl   $0x417,0x4(%esp)
f0101cc6:	00 
f0101cc7:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101cce:	e8 6d e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101cd3:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cd8:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101cdb:	e8 15 ee ff ff       	call   f0100af5 <check_va2pa>
f0101ce0:	89 f2                	mov    %esi,%edx
f0101ce2:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101ce5:	c1 fa 03             	sar    $0x3,%edx
f0101ce8:	c1 e2 0c             	shl    $0xc,%edx
f0101ceb:	39 d0                	cmp    %edx,%eax
f0101ced:	74 24                	je     f0101d13 <mem_init+0xc02>
f0101cef:	c7 44 24 0c 8c 5e 10 	movl   $0xf0105e8c,0xc(%esp)
f0101cf6:	f0 
f0101cf7:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101cfe:	f0 
f0101cff:	c7 44 24 04 18 04 00 	movl   $0x418,0x4(%esp)
f0101d06:	00 
f0101d07:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101d0e:	e8 2d e3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101d13:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d18:	74 24                	je     f0101d3e <mem_init+0xc2d>
f0101d1a:	c7 44 24 0c 1b 64 10 	movl   $0xf010641b,0xc(%esp)
f0101d21:	f0 
f0101d22:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101d29:	f0 
f0101d2a:	c7 44 24 04 19 04 00 	movl   $0x419,0x4(%esp)
f0101d31:	00 
f0101d32:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101d39:	e8 02 e3 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101d3e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101d43:	74 24                	je     f0101d69 <mem_init+0xc58>
f0101d45:	c7 44 24 0c 2c 64 10 	movl   $0xf010642c,0xc(%esp)
f0101d4c:	f0 
f0101d4d:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101d54:	f0 
f0101d55:	c7 44 24 04 1a 04 00 	movl   $0x41a,0x4(%esp)
f0101d5c:	00 
f0101d5d:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101d64:	e8 d7 e2 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d69:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d70:	00 
f0101d71:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d78:	00 
f0101d79:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101d7d:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101d80:	89 04 24             	mov    %eax,(%esp)
f0101d83:	e8 a5 f2 ff ff       	call   f010102d <page_insert>
f0101d88:	85 c0                	test   %eax,%eax
f0101d8a:	74 24                	je     f0101db0 <mem_init+0xc9f>
f0101d8c:	c7 44 24 0c bc 5e 10 	movl   $0xf0105ebc,0xc(%esp)
f0101d93:	f0 
f0101d94:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101d9b:	f0 
f0101d9c:	c7 44 24 04 1d 04 00 	movl   $0x41d,0x4(%esp)
f0101da3:	00 
f0101da4:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101dab:	e8 90 e2 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101db0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101db5:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0101dba:	e8 36 ed ff ff       	call   f0100af5 <check_va2pa>
f0101dbf:	89 fa                	mov    %edi,%edx
f0101dc1:	2b 15 10 9f 22 f0    	sub    0xf0229f10,%edx
f0101dc7:	c1 fa 03             	sar    $0x3,%edx
f0101dca:	c1 e2 0c             	shl    $0xc,%edx
f0101dcd:	39 d0                	cmp    %edx,%eax
f0101dcf:	74 24                	je     f0101df5 <mem_init+0xce4>
f0101dd1:	c7 44 24 0c f8 5e 10 	movl   $0xf0105ef8,0xc(%esp)
f0101dd8:	f0 
f0101dd9:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101de0:	f0 
f0101de1:	c7 44 24 04 1f 04 00 	movl   $0x41f,0x4(%esp)
f0101de8:	00 
f0101de9:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101df0:	e8 4b e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101df5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101dfa:	74 24                	je     f0101e20 <mem_init+0xd0f>
f0101dfc:	c7 44 24 0c 3d 64 10 	movl   $0xf010643d,0xc(%esp)
f0101e03:	f0 
f0101e04:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101e0b:	f0 
f0101e0c:	c7 44 24 04 20 04 00 	movl   $0x420,0x4(%esp)
f0101e13:	00 
f0101e14:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101e1b:	e8 20 e2 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101e20:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e27:	e8 0f ef ff ff       	call   f0100d3b <page_alloc>
f0101e2c:	85 c0                	test   %eax,%eax
f0101e2e:	74 24                	je     f0101e54 <mem_init+0xd43>
f0101e30:	c7 44 24 0c c9 63 10 	movl   $0xf01063c9,0xc(%esp)
f0101e37:	f0 
f0101e38:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101e3f:	f0 
f0101e40:	c7 44 24 04 23 04 00 	movl   $0x423,0x4(%esp)
f0101e47:	00 
f0101e48:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101e4f:	e8 ec e1 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e54:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e5b:	00 
f0101e5c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e63:	00 
f0101e64:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101e68:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0101e6d:	89 04 24             	mov    %eax,(%esp)
f0101e70:	e8 b8 f1 ff ff       	call   f010102d <page_insert>
f0101e75:	85 c0                	test   %eax,%eax
f0101e77:	74 24                	je     f0101e9d <mem_init+0xd8c>
f0101e79:	c7 44 24 0c bc 5e 10 	movl   $0xf0105ebc,0xc(%esp)
f0101e80:	f0 
f0101e81:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101e88:	f0 
f0101e89:	c7 44 24 04 26 04 00 	movl   $0x426,0x4(%esp)
f0101e90:	00 
f0101e91:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101e98:	e8 a3 e1 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e9d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ea2:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0101ea7:	e8 49 ec ff ff       	call   f0100af5 <check_va2pa>
f0101eac:	89 fa                	mov    %edi,%edx
f0101eae:	2b 15 10 9f 22 f0    	sub    0xf0229f10,%edx
f0101eb4:	c1 fa 03             	sar    $0x3,%edx
f0101eb7:	c1 e2 0c             	shl    $0xc,%edx
f0101eba:	39 d0                	cmp    %edx,%eax
f0101ebc:	74 24                	je     f0101ee2 <mem_init+0xdd1>
f0101ebe:	c7 44 24 0c f8 5e 10 	movl   $0xf0105ef8,0xc(%esp)
f0101ec5:	f0 
f0101ec6:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101ecd:	f0 
f0101ece:	c7 44 24 04 27 04 00 	movl   $0x427,0x4(%esp)
f0101ed5:	00 
f0101ed6:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101edd:	e8 5e e1 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ee2:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101ee7:	74 24                	je     f0101f0d <mem_init+0xdfc>
f0101ee9:	c7 44 24 0c 3d 64 10 	movl   $0xf010643d,0xc(%esp)
f0101ef0:	f0 
f0101ef1:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101ef8:	f0 
f0101ef9:	c7 44 24 04 28 04 00 	movl   $0x428,0x4(%esp)
f0101f00:	00 
f0101f01:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101f08:	e8 33 e1 ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101f0d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f14:	e8 22 ee ff ff       	call   f0100d3b <page_alloc>
f0101f19:	85 c0                	test   %eax,%eax
f0101f1b:	74 24                	je     f0101f41 <mem_init+0xe30>
f0101f1d:	c7 44 24 0c c9 63 10 	movl   $0xf01063c9,0xc(%esp)
f0101f24:	f0 
f0101f25:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101f2c:	f0 
f0101f2d:	c7 44 24 04 2c 04 00 	movl   $0x42c,0x4(%esp)
f0101f34:	00 
f0101f35:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101f3c:	e8 ff e0 ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101f41:	8b 15 0c 9f 22 f0    	mov    0xf0229f0c,%edx
f0101f47:	8b 02                	mov    (%edx),%eax
f0101f49:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f4e:	89 c1                	mov    %eax,%ecx
f0101f50:	c1 e9 0c             	shr    $0xc,%ecx
f0101f53:	3b 0d 08 9f 22 f0    	cmp    0xf0229f08,%ecx
f0101f59:	72 20                	jb     f0101f7b <mem_init+0xe6a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f5f:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0101f66:	f0 
f0101f67:	c7 44 24 04 2f 04 00 	movl   $0x42f,0x4(%esp)
f0101f6e:	00 
f0101f6f:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101f76:	e8 c5 e0 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101f7b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f80:	89 45 e0             	mov    %eax,-0x20(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101f83:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f8a:	00 
f0101f8b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f92:	00 
f0101f93:	89 14 24             	mov    %edx,(%esp)
f0101f96:	e8 af ee ff ff       	call   f0100e4a <pgdir_walk>
f0101f9b:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0101f9e:	8d 51 04             	lea    0x4(%ecx),%edx
f0101fa1:	39 d0                	cmp    %edx,%eax
f0101fa3:	74 24                	je     f0101fc9 <mem_init+0xeb8>
f0101fa5:	c7 44 24 0c 28 5f 10 	movl   $0xf0105f28,0xc(%esp)
f0101fac:	f0 
f0101fad:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101fb4:	f0 
f0101fb5:	c7 44 24 04 30 04 00 	movl   $0x430,0x4(%esp)
f0101fbc:	00 
f0101fbd:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0101fc4:	e8 77 e0 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101fc9:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101fd0:	00 
f0101fd1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fd8:	00 
f0101fd9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101fdd:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0101fe2:	89 04 24             	mov    %eax,(%esp)
f0101fe5:	e8 43 f0 ff ff       	call   f010102d <page_insert>
f0101fea:	85 c0                	test   %eax,%eax
f0101fec:	74 24                	je     f0102012 <mem_init+0xf01>
f0101fee:	c7 44 24 0c 68 5f 10 	movl   $0xf0105f68,0xc(%esp)
f0101ff5:	f0 
f0101ff6:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0101ffd:	f0 
f0101ffe:	c7 44 24 04 33 04 00 	movl   $0x433,0x4(%esp)
f0102005:	00 
f0102006:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010200d:	e8 2e e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102012:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0102017:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010201a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010201f:	e8 d1 ea ff ff       	call   f0100af5 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102024:	89 fa                	mov    %edi,%edx
f0102026:	2b 15 10 9f 22 f0    	sub    0xf0229f10,%edx
f010202c:	c1 fa 03             	sar    $0x3,%edx
f010202f:	c1 e2 0c             	shl    $0xc,%edx
f0102032:	39 d0                	cmp    %edx,%eax
f0102034:	74 24                	je     f010205a <mem_init+0xf49>
f0102036:	c7 44 24 0c f8 5e 10 	movl   $0xf0105ef8,0xc(%esp)
f010203d:	f0 
f010203e:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102045:	f0 
f0102046:	c7 44 24 04 34 04 00 	movl   $0x434,0x4(%esp)
f010204d:	00 
f010204e:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102055:	e8 e6 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f010205a:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010205f:	74 24                	je     f0102085 <mem_init+0xf74>
f0102061:	c7 44 24 0c 3d 64 10 	movl   $0xf010643d,0xc(%esp)
f0102068:	f0 
f0102069:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102070:	f0 
f0102071:	c7 44 24 04 35 04 00 	movl   $0x435,0x4(%esp)
f0102078:	00 
f0102079:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102080:	e8 bb df ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102085:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010208c:	00 
f010208d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102094:	00 
f0102095:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102098:	89 04 24             	mov    %eax,(%esp)
f010209b:	e8 aa ed ff ff       	call   f0100e4a <pgdir_walk>
f01020a0:	f6 00 04             	testb  $0x4,(%eax)
f01020a3:	75 24                	jne    f01020c9 <mem_init+0xfb8>
f01020a5:	c7 44 24 0c a8 5f 10 	movl   $0xf0105fa8,0xc(%esp)
f01020ac:	f0 
f01020ad:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01020b4:	f0 
f01020b5:	c7 44 24 04 36 04 00 	movl   $0x436,0x4(%esp)
f01020bc:	00 
f01020bd:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01020c4:	e8 77 df ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01020c9:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f01020ce:	f6 00 04             	testb  $0x4,(%eax)
f01020d1:	75 24                	jne    f01020f7 <mem_init+0xfe6>
f01020d3:	c7 44 24 0c 4e 64 10 	movl   $0xf010644e,0xc(%esp)
f01020da:	f0 
f01020db:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01020e2:	f0 
f01020e3:	c7 44 24 04 37 04 00 	movl   $0x437,0x4(%esp)
f01020ea:	00 
f01020eb:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01020f2:	e8 49 df ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01020f7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020fe:	00 
f01020ff:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102106:	00 
f0102107:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010210b:	89 04 24             	mov    %eax,(%esp)
f010210e:	e8 1a ef ff ff       	call   f010102d <page_insert>
f0102113:	85 c0                	test   %eax,%eax
f0102115:	74 24                	je     f010213b <mem_init+0x102a>
f0102117:	c7 44 24 0c bc 5e 10 	movl   $0xf0105ebc,0xc(%esp)
f010211e:	f0 
f010211f:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102126:	f0 
f0102127:	c7 44 24 04 3a 04 00 	movl   $0x43a,0x4(%esp)
f010212e:	00 
f010212f:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102136:	e8 05 df ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f010213b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102142:	00 
f0102143:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010214a:	00 
f010214b:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0102150:	89 04 24             	mov    %eax,(%esp)
f0102153:	e8 f2 ec ff ff       	call   f0100e4a <pgdir_walk>
f0102158:	f6 00 02             	testb  $0x2,(%eax)
f010215b:	75 24                	jne    f0102181 <mem_init+0x1070>
f010215d:	c7 44 24 0c dc 5f 10 	movl   $0xf0105fdc,0xc(%esp)
f0102164:	f0 
f0102165:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010216c:	f0 
f010216d:	c7 44 24 04 3b 04 00 	movl   $0x43b,0x4(%esp)
f0102174:	00 
f0102175:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010217c:	e8 bf de ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102181:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102188:	00 
f0102189:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102190:	00 
f0102191:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0102196:	89 04 24             	mov    %eax,(%esp)
f0102199:	e8 ac ec ff ff       	call   f0100e4a <pgdir_walk>
f010219e:	f6 00 04             	testb  $0x4,(%eax)
f01021a1:	74 24                	je     f01021c7 <mem_init+0x10b6>
f01021a3:	c7 44 24 0c 10 60 10 	movl   $0xf0106010,0xc(%esp)
f01021aa:	f0 
f01021ab:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01021b2:	f0 
f01021b3:	c7 44 24 04 3c 04 00 	movl   $0x43c,0x4(%esp)
f01021ba:	00 
f01021bb:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01021c2:	e8 79 de ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01021c7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021ce:	00 
f01021cf:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01021d6:	00 
f01021d7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01021db:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f01021e0:	89 04 24             	mov    %eax,(%esp)
f01021e3:	e8 45 ee ff ff       	call   f010102d <page_insert>
f01021e8:	85 c0                	test   %eax,%eax
f01021ea:	78 24                	js     f0102210 <mem_init+0x10ff>
f01021ec:	c7 44 24 0c 48 60 10 	movl   $0xf0106048,0xc(%esp)
f01021f3:	f0 
f01021f4:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01021fb:	f0 
f01021fc:	c7 44 24 04 3f 04 00 	movl   $0x43f,0x4(%esp)
f0102203:	00 
f0102204:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010220b:	e8 30 de ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102210:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102217:	00 
f0102218:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010221f:	00 
f0102220:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102224:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0102229:	89 04 24             	mov    %eax,(%esp)
f010222c:	e8 fc ed ff ff       	call   f010102d <page_insert>
f0102231:	85 c0                	test   %eax,%eax
f0102233:	74 24                	je     f0102259 <mem_init+0x1148>
f0102235:	c7 44 24 0c 80 60 10 	movl   $0xf0106080,0xc(%esp)
f010223c:	f0 
f010223d:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102244:	f0 
f0102245:	c7 44 24 04 42 04 00 	movl   $0x442,0x4(%esp)
f010224c:	00 
f010224d:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102254:	e8 e7 dd ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102259:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102260:	00 
f0102261:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102268:	00 
f0102269:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f010226e:	89 04 24             	mov    %eax,(%esp)
f0102271:	e8 d4 eb ff ff       	call   f0100e4a <pgdir_walk>
f0102276:	f6 00 04             	testb  $0x4,(%eax)
f0102279:	74 24                	je     f010229f <mem_init+0x118e>
f010227b:	c7 44 24 0c 10 60 10 	movl   $0xf0106010,0xc(%esp)
f0102282:	f0 
f0102283:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010228a:	f0 
f010228b:	c7 44 24 04 43 04 00 	movl   $0x443,0x4(%esp)
f0102292:	00 
f0102293:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010229a:	e8 a1 dd ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010229f:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f01022a4:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01022a7:	ba 00 00 00 00       	mov    $0x0,%edx
f01022ac:	e8 44 e8 ff ff       	call   f0100af5 <check_va2pa>
f01022b1:	89 c1                	mov    %eax,%ecx
f01022b3:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01022b6:	89 f0                	mov    %esi,%eax
f01022b8:	2b 05 10 9f 22 f0    	sub    0xf0229f10,%eax
f01022be:	c1 f8 03             	sar    $0x3,%eax
f01022c1:	c1 e0 0c             	shl    $0xc,%eax
f01022c4:	39 c1                	cmp    %eax,%ecx
f01022c6:	74 24                	je     f01022ec <mem_init+0x11db>
f01022c8:	c7 44 24 0c bc 60 10 	movl   $0xf01060bc,0xc(%esp)
f01022cf:	f0 
f01022d0:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01022d7:	f0 
f01022d8:	c7 44 24 04 46 04 00 	movl   $0x446,0x4(%esp)
f01022df:	00 
f01022e0:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01022e7:	e8 54 dd ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01022ec:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022f1:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01022f4:	e8 fc e7 ff ff       	call   f0100af5 <check_va2pa>
f01022f9:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01022fc:	74 24                	je     f0102322 <mem_init+0x1211>
f01022fe:	c7 44 24 0c e8 60 10 	movl   $0xf01060e8,0xc(%esp)
f0102305:	f0 
f0102306:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010230d:	f0 
f010230e:	c7 44 24 04 47 04 00 	movl   $0x447,0x4(%esp)
f0102315:	00 
f0102316:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010231d:	e8 1e dd ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0102322:	66 83 7e 04 02       	cmpw   $0x2,0x4(%esi)
f0102327:	74 24                	je     f010234d <mem_init+0x123c>
f0102329:	c7 44 24 0c 64 64 10 	movl   $0xf0106464,0xc(%esp)
f0102330:	f0 
f0102331:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102338:	f0 
f0102339:	c7 44 24 04 49 04 00 	movl   $0x449,0x4(%esp)
f0102340:	00 
f0102341:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102348:	e8 f3 dc ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010234d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102352:	74 24                	je     f0102378 <mem_init+0x1267>
f0102354:	c7 44 24 0c 75 64 10 	movl   $0xf0106475,0xc(%esp)
f010235b:	f0 
f010235c:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102363:	f0 
f0102364:	c7 44 24 04 4a 04 00 	movl   $0x44a,0x4(%esp)
f010236b:	00 
f010236c:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102373:	e8 c8 dc ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102378:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010237f:	e8 b7 e9 ff ff       	call   f0100d3b <page_alloc>
f0102384:	85 c0                	test   %eax,%eax
f0102386:	74 04                	je     f010238c <mem_init+0x127b>
f0102388:	39 c7                	cmp    %eax,%edi
f010238a:	74 24                	je     f01023b0 <mem_init+0x129f>
f010238c:	c7 44 24 0c 18 61 10 	movl   $0xf0106118,0xc(%esp)
f0102393:	f0 
f0102394:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010239b:	f0 
f010239c:	c7 44 24 04 4d 04 00 	movl   $0x44d,0x4(%esp)
f01023a3:	00 
f01023a4:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01023ab:	e8 90 dc ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01023b0:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01023b7:	00 
f01023b8:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f01023bd:	89 04 24             	mov    %eax,(%esp)
f01023c0:	e8 1f ec ff ff       	call   f0100fe4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01023c5:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f01023ca:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01023cd:	ba 00 00 00 00       	mov    $0x0,%edx
f01023d2:	e8 1e e7 ff ff       	call   f0100af5 <check_va2pa>
f01023d7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023da:	74 24                	je     f0102400 <mem_init+0x12ef>
f01023dc:	c7 44 24 0c 3c 61 10 	movl   $0xf010613c,0xc(%esp)
f01023e3:	f0 
f01023e4:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01023eb:	f0 
f01023ec:	c7 44 24 04 51 04 00 	movl   $0x451,0x4(%esp)
f01023f3:	00 
f01023f4:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01023fb:	e8 40 dc ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102400:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102405:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0102408:	e8 e8 e6 ff ff       	call   f0100af5 <check_va2pa>
f010240d:	89 f2                	mov    %esi,%edx
f010240f:	2b 15 10 9f 22 f0    	sub    0xf0229f10,%edx
f0102415:	c1 fa 03             	sar    $0x3,%edx
f0102418:	c1 e2 0c             	shl    $0xc,%edx
f010241b:	39 d0                	cmp    %edx,%eax
f010241d:	74 24                	je     f0102443 <mem_init+0x1332>
f010241f:	c7 44 24 0c e8 60 10 	movl   $0xf01060e8,0xc(%esp)
f0102426:	f0 
f0102427:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010242e:	f0 
f010242f:	c7 44 24 04 52 04 00 	movl   $0x452,0x4(%esp)
f0102436:	00 
f0102437:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010243e:	e8 fd db ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102443:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102448:	74 24                	je     f010246e <mem_init+0x135d>
f010244a:	c7 44 24 0c 1b 64 10 	movl   $0xf010641b,0xc(%esp)
f0102451:	f0 
f0102452:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102459:	f0 
f010245a:	c7 44 24 04 53 04 00 	movl   $0x453,0x4(%esp)
f0102461:	00 
f0102462:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102469:	e8 d2 db ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010246e:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102473:	74 24                	je     f0102499 <mem_init+0x1388>
f0102475:	c7 44 24 0c 75 64 10 	movl   $0xf0106475,0xc(%esp)
f010247c:	f0 
f010247d:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102484:	f0 
f0102485:	c7 44 24 04 54 04 00 	movl   $0x454,0x4(%esp)
f010248c:	00 
f010248d:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102494:	e8 a7 db ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102499:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01024a0:	00 
f01024a1:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024a8:	00 
f01024a9:	89 74 24 04          	mov    %esi,0x4(%esp)
f01024ad:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01024b0:	89 04 24             	mov    %eax,(%esp)
f01024b3:	e8 75 eb ff ff       	call   f010102d <page_insert>
f01024b8:	85 c0                	test   %eax,%eax
f01024ba:	74 24                	je     f01024e0 <mem_init+0x13cf>
f01024bc:	c7 44 24 0c 60 61 10 	movl   $0xf0106160,0xc(%esp)
f01024c3:	f0 
f01024c4:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01024cb:	f0 
f01024cc:	c7 44 24 04 57 04 00 	movl   $0x457,0x4(%esp)
f01024d3:	00 
f01024d4:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01024db:	e8 60 db ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f01024e0:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01024e5:	75 24                	jne    f010250b <mem_init+0x13fa>
f01024e7:	c7 44 24 0c 86 64 10 	movl   $0xf0106486,0xc(%esp)
f01024ee:	f0 
f01024ef:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01024f6:	f0 
f01024f7:	c7 44 24 04 58 04 00 	movl   $0x458,0x4(%esp)
f01024fe:	00 
f01024ff:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102506:	e8 35 db ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f010250b:	83 3e 00             	cmpl   $0x0,(%esi)
f010250e:	74 24                	je     f0102534 <mem_init+0x1423>
f0102510:	c7 44 24 0c 92 64 10 	movl   $0xf0106492,0xc(%esp)
f0102517:	f0 
f0102518:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010251f:	f0 
f0102520:	c7 44 24 04 59 04 00 	movl   $0x459,0x4(%esp)
f0102527:	00 
f0102528:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010252f:	e8 0c db ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102534:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010253b:	00 
f010253c:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0102541:	89 04 24             	mov    %eax,(%esp)
f0102544:	e8 9b ea ff ff       	call   f0100fe4 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102549:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f010254e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102551:	ba 00 00 00 00       	mov    $0x0,%edx
f0102556:	e8 9a e5 ff ff       	call   f0100af5 <check_va2pa>
f010255b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010255e:	74 24                	je     f0102584 <mem_init+0x1473>
f0102560:	c7 44 24 0c 3c 61 10 	movl   $0xf010613c,0xc(%esp)
f0102567:	f0 
f0102568:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f010256f:	f0 
f0102570:	c7 44 24 04 5d 04 00 	movl   $0x45d,0x4(%esp)
f0102577:	00 
f0102578:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010257f:	e8 bc da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102584:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102589:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010258c:	e8 64 e5 ff ff       	call   f0100af5 <check_va2pa>
f0102591:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102594:	74 24                	je     f01025ba <mem_init+0x14a9>
f0102596:	c7 44 24 0c 98 61 10 	movl   $0xf0106198,0xc(%esp)
f010259d:	f0 
f010259e:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01025a5:	f0 
f01025a6:	c7 44 24 04 5e 04 00 	movl   $0x45e,0x4(%esp)
f01025ad:	00 
f01025ae:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01025b5:	e8 86 da ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01025ba:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f01025bf:	74 24                	je     f01025e5 <mem_init+0x14d4>
f01025c1:	c7 44 24 0c a7 64 10 	movl   $0xf01064a7,0xc(%esp)
f01025c8:	f0 
f01025c9:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01025d0:	f0 
f01025d1:	c7 44 24 04 5f 04 00 	movl   $0x45f,0x4(%esp)
f01025d8:	00 
f01025d9:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01025e0:	e8 5b da ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01025e5:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01025ea:	74 24                	je     f0102610 <mem_init+0x14ff>
f01025ec:	c7 44 24 0c 75 64 10 	movl   $0xf0106475,0xc(%esp)
f01025f3:	f0 
f01025f4:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01025fb:	f0 
f01025fc:	c7 44 24 04 60 04 00 	movl   $0x460,0x4(%esp)
f0102603:	00 
f0102604:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f010260b:	e8 30 da ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102610:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102617:	e8 1f e7 ff ff       	call   f0100d3b <page_alloc>
f010261c:	85 c0                	test   %eax,%eax
f010261e:	74 04                	je     f0102624 <mem_init+0x1513>
f0102620:	39 c6                	cmp    %eax,%esi
f0102622:	74 24                	je     f0102648 <mem_init+0x1537>
f0102624:	c7 44 24 0c c0 61 10 	movl   $0xf01061c0,0xc(%esp)
f010262b:	f0 
f010262c:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102633:	f0 
f0102634:	c7 44 24 04 63 04 00 	movl   $0x463,0x4(%esp)
f010263b:	00 
f010263c:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102643:	e8 f8 d9 ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102648:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010264f:	e8 e7 e6 ff ff       	call   f0100d3b <page_alloc>
f0102654:	85 c0                	test   %eax,%eax
f0102656:	74 24                	je     f010267c <mem_init+0x156b>
f0102658:	c7 44 24 0c c9 63 10 	movl   $0xf01063c9,0xc(%esp)
f010265f:	f0 
f0102660:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102667:	f0 
f0102668:	c7 44 24 04 66 04 00 	movl   $0x466,0x4(%esp)
f010266f:	00 
f0102670:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102677:	e8 c4 d9 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010267c:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0102681:	8b 08                	mov    (%eax),%ecx
f0102683:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102689:	89 da                	mov    %ebx,%edx
f010268b:	2b 15 10 9f 22 f0    	sub    0xf0229f10,%edx
f0102691:	c1 fa 03             	sar    $0x3,%edx
f0102694:	c1 e2 0c             	shl    $0xc,%edx
f0102697:	39 d1                	cmp    %edx,%ecx
f0102699:	74 24                	je     f01026bf <mem_init+0x15ae>
f010269b:	c7 44 24 0c 64 5e 10 	movl   $0xf0105e64,0xc(%esp)
f01026a2:	f0 
f01026a3:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01026aa:	f0 
f01026ab:	c7 44 24 04 69 04 00 	movl   $0x469,0x4(%esp)
f01026b2:	00 
f01026b3:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01026ba:	e8 81 d9 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01026bf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01026c5:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01026ca:	74 24                	je     f01026f0 <mem_init+0x15df>
f01026cc:	c7 44 24 0c 2c 64 10 	movl   $0xf010642c,0xc(%esp)
f01026d3:	f0 
f01026d4:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01026db:	f0 
f01026dc:	c7 44 24 04 6b 04 00 	movl   $0x46b,0x4(%esp)
f01026e3:	00 
f01026e4:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f01026eb:	e8 50 d9 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f01026f0:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f01026f6:	89 1c 24             	mov    %ebx,(%esp)
f01026f9:	e8 ce e6 ff ff       	call   f0100dcc <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f01026fe:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102705:	00 
f0102706:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010270d:	00 
f010270e:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0102713:	89 04 24             	mov    %eax,(%esp)
f0102716:	e8 2f e7 ff ff       	call   f0100e4a <pgdir_walk>
f010271b:	89 45 d0             	mov    %eax,-0x30(%ebp)
f010271e:	89 45 e0             	mov    %eax,-0x20(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102721:	8b 15 0c 9f 22 f0    	mov    0xf0229f0c,%edx
f0102727:	8b 4a 04             	mov    0x4(%edx),%ecx
f010272a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102730:	89 c8                	mov    %ecx,%eax
f0102732:	c1 e8 0c             	shr    $0xc,%eax
f0102735:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f010273b:	72 20                	jb     f010275d <mem_init+0x164c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010273d:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102741:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0102748:	f0 
f0102749:	c7 44 24 04 72 04 00 	movl   $0x472,0x4(%esp)
f0102750:	00 
f0102751:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102758:	e8 e3 d8 ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010275d:	81 e9 fc ff ff 0f    	sub    $0xffffffc,%ecx
f0102763:	39 4d d0             	cmp    %ecx,-0x30(%ebp)
f0102766:	74 24                	je     f010278c <mem_init+0x167b>
f0102768:	c7 44 24 0c b8 64 10 	movl   $0xf01064b8,0xc(%esp)
f010276f:	f0 
f0102770:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102777:	f0 
f0102778:	c7 44 24 04 73 04 00 	movl   $0x473,0x4(%esp)
f010277f:	00 
f0102780:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102787:	e8 b4 d8 ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010278c:	c7 42 04 00 00 00 00 	movl   $0x0,0x4(%edx)
	pp0->pp_ref = 0;
f0102793:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102799:	89 d8                	mov    %ebx,%eax
f010279b:	e8 10 e3 ff ff       	call   f0100ab0 <page2kva>
f01027a0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01027a7:	00 
f01027a8:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f01027af:	00 
f01027b0:	89 04 24             	mov    %eax,(%esp)
f01027b3:	e8 1f 21 00 00       	call   f01048d7 <memset>
	page_free(pp0);
f01027b8:	89 1c 24             	mov    %ebx,(%esp)
f01027bb:	e8 0c e6 ff ff       	call   f0100dcc <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01027c0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01027c7:	00 
f01027c8:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01027cf:	00 
f01027d0:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f01027d5:	89 04 24             	mov    %eax,(%esp)
f01027d8:	e8 6d e6 ff ff       	call   f0100e4a <pgdir_walk>
	ptep = (pte_t *) page2kva(pp0);
f01027dd:	89 d8                	mov    %ebx,%eax
f01027df:	e8 cc e2 ff ff       	call   f0100ab0 <page2kva>
f01027e4:	89 45 e0             	mov    %eax,-0x20(%ebp)
	for(i=0; i<NPTENTRIES; i++)
f01027e7:	ba 00 00 00 00       	mov    $0x0,%edx
		assert((ptep[i] & PTE_P) == 0);
f01027ec:	f6 04 90 01          	testb  $0x1,(%eax,%edx,4)
f01027f0:	74 24                	je     f0102816 <mem_init+0x1705>
f01027f2:	c7 44 24 0c d0 64 10 	movl   $0xf01064d0,0xc(%esp)
f01027f9:	f0 
f01027fa:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0102801:	f0 
f0102802:	c7 44 24 04 7d 04 00 	movl   $0x47d,0x4(%esp)
f0102809:	00 
f010280a:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102811:	e8 2a d8 ff ff       	call   f0100040 <_panic>
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102816:	83 c2 01             	add    $0x1,%edx
f0102819:	81 fa 00 04 00 00    	cmp    $0x400,%edx
f010281f:	75 cb                	jne    f01027ec <mem_init+0x16db>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102821:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
f0102826:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010282c:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// give free list back
	page_free_list = fl;
f0102832:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102835:	a3 44 92 22 f0       	mov    %eax,0xf0229244

	// free the pages we took
	page_free(pp0);
f010283a:	89 1c 24             	mov    %ebx,(%esp)
f010283d:	e8 8a e5 ff ff       	call   f0100dcc <page_free>
	page_free(pp1);
f0102842:	89 34 24             	mov    %esi,(%esp)
f0102845:	e8 82 e5 ff ff       	call   f0100dcc <page_free>
	page_free(pp2);
f010284a:	89 3c 24             	mov    %edi,(%esp)
f010284d:	e8 7a e5 ff ff       	call   f0100dcc <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f0102852:	c7 44 24 04 01 10 00 	movl   $0x1001,0x4(%esp)
f0102859:	00 
f010285a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102861:	e8 89 e8 ff ff       	call   f01010ef <mmio_map_region>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0102866:	3d 00 70 00 00       	cmp    $0x7000,%eax
f010286b:	0f 85 ef ec ff ff    	jne    f0101560 <mem_init+0x44f>
f0102871:	e9 c6 ec ff ff       	jmp    f010153c <mem_init+0x42b>
f0102876:	3d 00 70 00 00       	cmp    $0x7000,%eax
f010287b:	0f 85 e4 ec ff ff    	jne    f0101565 <mem_init+0x454>
f0102881:	e9 b6 ec ff ff       	jmp    f010153c <mem_init+0x42b>

f0102886 <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102886:	55                   	push   %ebp
f0102887:	89 e5                	mov    %esp,%ebp
f0102889:	57                   	push   %edi
f010288a:	56                   	push   %esi
f010288b:	53                   	push   %ebx
f010288c:	83 ec 2c             	sub    $0x2c,%esp
f010288f:	8b 75 08             	mov    0x8(%ebp),%esi
f0102892:	8b 4d 14             	mov    0x14(%ebp),%ecx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0102895:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102898:	03 5d 10             	add    0x10(%ebp),%ebx
  if (va_beg >= ULIM || va_end >= ULIM) {
f010289b:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01028a1:	77 09                	ja     f01028ac <user_mem_check+0x26>
f01028a3:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f01028aa:	76 1f                	jbe    f01028cb <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f01028ac:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f01028b3:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f01028b8:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f01028bc:	a3 40 92 22 f0       	mov    %eax,0xf0229240
    return -E_FAULT;
f01028c1:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f01028c6:	e9 b8 00 00 00       	jmp    f0102983 <user_mem_check+0xfd>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f01028cb:	8b 45 0c             	mov    0xc(%ebp),%eax
f01028ce:	25 00 f0 ff ff       	and    $0xfffff000,%eax
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f01028d3:	81 c3 ff 0f 00 00    	add    $0xfff,%ebx
f01028d9:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01028df:	8b 15 08 9f 22 f0    	mov    0xf0229f08,%edx
f01028e5:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01028e8:	89 75 08             	mov    %esi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f01028eb:	e9 86 00 00 00       	jmp    f0102976 <user_mem_check+0xf0>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f01028f0:	89 c7                	mov    %eax,%edi
f01028f2:	c1 ef 16             	shr    $0x16,%edi
f01028f5:	8b 75 08             	mov    0x8(%ebp),%esi
f01028f8:	8b 56 60             	mov    0x60(%esi),%edx
f01028fb:	8b 14 ba             	mov    (%edx,%edi,4),%edx
f01028fe:	f6 c2 01             	test   $0x1,%dl
f0102901:	75 13                	jne    f0102916 <user_mem_check+0x90>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102903:	3b 45 0c             	cmp    0xc(%ebp),%eax
f0102906:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f010290a:	a3 40 92 22 f0       	mov    %eax,0xf0229240
      return -E_FAULT;
f010290f:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102914:	eb 6d                	jmp    f0102983 <user_mem_check+0xfd>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0102916:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010291c:	89 d7                	mov    %edx,%edi
f010291e:	c1 ef 0c             	shr    $0xc,%edi
f0102921:	3b 7d e4             	cmp    -0x1c(%ebp),%edi
f0102924:	72 20                	jb     f0102946 <user_mem_check+0xc0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102926:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010292a:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0102931:	f0 
f0102932:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f0102939:	00 
f010293a:	c7 04 24 27 62 10 f0 	movl   $0xf0106227,(%esp)
f0102941:	e8 fa d6 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0102946:	89 c7                	mov    %eax,%edi
f0102948:	c1 ef 0c             	shr    $0xc,%edi
f010294b:	81 e7 ff 03 00 00    	and    $0x3ff,%edi
f0102951:	89 ce                	mov    %ecx,%esi
f0102953:	23 b4 ba 00 00 00 f0 	and    -0x10000000(%edx,%edi,4),%esi
f010295a:	39 f1                	cmp    %esi,%ecx
f010295c:	74 13                	je     f0102971 <user_mem_check+0xeb>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f010295e:	3b 45 0c             	cmp    0xc(%ebp),%eax
f0102961:	0f 42 45 0c          	cmovb  0xc(%ebp),%eax
f0102965:	a3 40 92 22 f0       	mov    %eax,0xf0229240
      return -E_FAULT;
f010296a:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f010296f:	eb 12                	jmp    f0102983 <user_mem_check+0xfd>
    }

    va_beg2 += PGSIZE;
f0102971:	05 00 10 00 00       	add    $0x1000,%eax
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0102976:	39 d8                	cmp    %ebx,%eax
f0102978:	0f 82 72 ff ff ff    	jb     f01028f0 <user_mem_check+0x6a>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f010297e:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0102983:	83 c4 2c             	add    $0x2c,%esp
f0102986:	5b                   	pop    %ebx
f0102987:	5e                   	pop    %esi
f0102988:	5f                   	pop    %edi
f0102989:	5d                   	pop    %ebp
f010298a:	c3                   	ret    

f010298b <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f010298b:	55                   	push   %ebp
f010298c:	89 e5                	mov    %esp,%ebp
f010298e:	53                   	push   %ebx
f010298f:	83 ec 14             	sub    $0x14,%esp
f0102992:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102995:	8b 45 14             	mov    0x14(%ebp),%eax
f0102998:	83 c8 04             	or     $0x4,%eax
f010299b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010299f:	8b 45 10             	mov    0x10(%ebp),%eax
f01029a2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01029a6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01029a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01029ad:	89 1c 24             	mov    %ebx,(%esp)
f01029b0:	e8 d1 fe ff ff       	call   f0102886 <user_mem_check>
f01029b5:	85 c0                	test   %eax,%eax
f01029b7:	79 24                	jns    f01029dd <user_mem_assert+0x52>
		cprintf("[%08x] user_mem_check assertion failure for "
f01029b9:	a1 40 92 22 f0       	mov    0xf0229240,%eax
f01029be:	89 44 24 08          	mov    %eax,0x8(%esp)
f01029c2:	8b 43 48             	mov    0x48(%ebx),%eax
f01029c5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01029c9:	c7 04 24 e4 61 10 f0 	movl   $0xf01061e4,(%esp)
f01029d0:	e8 bb 09 00 00       	call   f0103390 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f01029d5:	89 1c 24             	mov    %ebx,(%esp)
f01029d8:	e8 e6 06 00 00       	call   f01030c3 <env_destroy>
	}
}
f01029dd:	83 c4 14             	add    $0x14,%esp
f01029e0:	5b                   	pop    %ebx
f01029e1:	5d                   	pop    %ebp
f01029e2:	c3                   	ret    

f01029e3 <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f01029e3:	55                   	push   %ebp
f01029e4:	89 e5                	mov    %esp,%ebp
f01029e6:	57                   	push   %edi
f01029e7:	56                   	push   %esi
f01029e8:	53                   	push   %ebx
f01029e9:	83 ec 1c             	sub    $0x1c,%esp
f01029ec:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f01029ee:	89 d3                	mov    %edx,%ebx
f01029f0:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f01029f6:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f01029fd:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0102a03:	eb 6d                	jmp    f0102a72 <region_alloc+0x8f>
		struct PageInfo *p = page_alloc(0);
f0102a05:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102a0c:	e8 2a e3 ff ff       	call   f0100d3b <page_alloc>
		if (p == NULL)
f0102a11:	85 c0                	test   %eax,%eax
f0102a13:	75 1c                	jne    f0102a31 <region_alloc+0x4e>
			panic("Page alloc failed!");
f0102a15:	c7 44 24 08 e7 64 10 	movl   $0xf01064e7,0x8(%esp)
f0102a1c:	f0 
f0102a1d:	c7 44 24 04 34 01 00 	movl   $0x134,0x4(%esp)
f0102a24:	00 
f0102a25:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102a2c:	e8 0f d6 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f0102a31:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102a38:	00 
f0102a39:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102a3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102a41:	8b 47 60             	mov    0x60(%edi),%eax
f0102a44:	89 04 24             	mov    %eax,(%esp)
f0102a47:	e8 e1 e5 ff ff       	call   f010102d <page_insert>
f0102a4c:	85 c0                	test   %eax,%eax
f0102a4e:	74 1c                	je     f0102a6c <region_alloc+0x89>
			panic("Page table couldn't be allocated!!");
f0102a50:	c7 44 24 08 68 65 10 	movl   $0xf0106568,0x8(%esp)
f0102a57:	f0 
f0102a58:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f0102a5f:	00 
f0102a60:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102a67:	e8 d4 d5 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f0102a6c:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0102a72:	39 f3                	cmp    %esi,%ebx
f0102a74:	72 8f                	jb     f0102a05 <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0102a76:	83 c4 1c             	add    $0x1c,%esp
f0102a79:	5b                   	pop    %ebx
f0102a7a:	5e                   	pop    %esi
f0102a7b:	5f                   	pop    %edi
f0102a7c:	5d                   	pop    %ebp
f0102a7d:	c3                   	ret    

f0102a7e <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102a7e:	55                   	push   %ebp
f0102a7f:	89 e5                	mov    %esp,%ebp
f0102a81:	56                   	push   %esi
f0102a82:	53                   	push   %ebx
f0102a83:	8b 45 08             	mov    0x8(%ebp),%eax
f0102a86:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102a89:	85 c0                	test   %eax,%eax
f0102a8b:	75 1a                	jne    f0102aa7 <envid2env+0x29>
		*env_store = curenv;
f0102a8d:	e8 97 24 00 00       	call   f0104f29 <cpunum>
f0102a92:	6b c0 74             	imul   $0x74,%eax,%eax
f0102a95:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0102a9b:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0102a9e:	89 01                	mov    %eax,(%ecx)
		return 0;
f0102aa0:	b8 00 00 00 00       	mov    $0x0,%eax
f0102aa5:	eb 70                	jmp    f0102b17 <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f0102aa7:	89 c3                	mov    %eax,%ebx
f0102aa9:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0102aaf:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0102ab2:	03 1d 4c 92 22 f0    	add    0xf022924c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f0102ab8:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0102abc:	74 05                	je     f0102ac3 <envid2env+0x45>
f0102abe:	39 43 48             	cmp    %eax,0x48(%ebx)
f0102ac1:	74 10                	je     f0102ad3 <envid2env+0x55>
		*env_store = 0;
f0102ac3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102ac6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102acc:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102ad1:	eb 44                	jmp    f0102b17 <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0102ad3:	84 d2                	test   %dl,%dl
f0102ad5:	74 36                	je     f0102b0d <envid2env+0x8f>
f0102ad7:	e8 4d 24 00 00       	call   f0104f29 <cpunum>
f0102adc:	6b c0 74             	imul   $0x74,%eax,%eax
f0102adf:	39 98 28 a0 22 f0    	cmp    %ebx,-0xfdd5fd8(%eax)
f0102ae5:	74 26                	je     f0102b0d <envid2env+0x8f>
f0102ae7:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0102aea:	e8 3a 24 00 00       	call   f0104f29 <cpunum>
f0102aef:	6b c0 74             	imul   $0x74,%eax,%eax
f0102af2:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0102af8:	3b 70 48             	cmp    0x48(%eax),%esi
f0102afb:	74 10                	je     f0102b0d <envid2env+0x8f>
		*env_store = 0;
f0102afd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b00:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0102b06:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0102b0b:	eb 0a                	jmp    f0102b17 <envid2env+0x99>
	}

	*env_store = e;
f0102b0d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b10:	89 18                	mov    %ebx,(%eax)
	return 0;
f0102b12:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102b17:	5b                   	pop    %ebx
f0102b18:	5e                   	pop    %esi
f0102b19:	5d                   	pop    %ebp
f0102b1a:	c3                   	ret    

f0102b1b <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0102b1b:	55                   	push   %ebp
f0102b1c:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0102b1e:	b8 00 e3 11 f0       	mov    $0xf011e300,%eax
f0102b23:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f0102b26:	b8 23 00 00 00       	mov    $0x23,%eax
f0102b2b:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f0102b2d:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f0102b2f:	b0 10                	mov    $0x10,%al
f0102b31:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f0102b33:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f0102b35:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f0102b37:	ea 3e 2b 10 f0 08 00 	ljmp   $0x8,$0xf0102b3e
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f0102b3e:	b0 00                	mov    $0x0,%al
f0102b40:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f0102b43:	5d                   	pop    %ebp
f0102b44:	c3                   	ret    

f0102b45 <env_init>:
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102b45:	8b 0d 50 92 22 f0    	mov    0xf0229250,%ecx
f0102b4b:	a1 4c 92 22 f0       	mov    0xf022924c,%eax
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f0102b50:	ba 00 04 00 00       	mov    $0x400,%edx
f0102b55:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f0102b5c:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f0102b63:	85 c9                	test   %ecx,%ecx
f0102b65:	74 05                	je     f0102b6c <env_init+0x27>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f0102b67:	89 40 c8             	mov    %eax,-0x38(%eax)
f0102b6a:	eb 02                	jmp    f0102b6e <env_init+0x29>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f0102b6c:	89 c1                	mov    %eax,%ecx
f0102b6e:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f0102b71:	83 ea 01             	sub    $0x1,%edx
f0102b74:	75 df                	jne    f0102b55 <env_init+0x10>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f0102b76:	55                   	push   %ebp
f0102b77:	89 e5                	mov    %esp,%ebp
f0102b79:	89 0d 50 92 22 f0    	mov    %ecx,0xf0229250
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f0102b7f:	e8 97 ff ff ff       	call   f0102b1b <env_init_percpu>
}
f0102b84:	5d                   	pop    %ebp
f0102b85:	c3                   	ret    

f0102b86 <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f0102b86:	55                   	push   %ebp
f0102b87:	89 e5                	mov    %esp,%ebp
f0102b89:	53                   	push   %ebx
f0102b8a:	83 ec 14             	sub    $0x14,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0102b8d:	8b 1d 50 92 22 f0    	mov    0xf0229250,%ebx
f0102b93:	85 db                	test   %ebx,%ebx
f0102b95:	0f 84 8b 01 00 00    	je     f0102d26 <env_alloc+0x1a0>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0102b9b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0102ba2:	e8 94 e1 ff ff       	call   f0100d3b <page_alloc>
f0102ba7:	85 c0                	test   %eax,%eax
f0102ba9:	0f 84 7e 01 00 00    	je     f0102d2d <env_alloc+0x1a7>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0102baf:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bb4:	2b 05 10 9f 22 f0    	sub    0xf0229f10,%eax
f0102bba:	c1 f8 03             	sar    $0x3,%eax
f0102bbd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bc0:	89 c2                	mov    %eax,%edx
f0102bc2:	c1 ea 0c             	shr    $0xc,%edx
f0102bc5:	3b 15 08 9f 22 f0    	cmp    0xf0229f08,%edx
f0102bcb:	72 20                	jb     f0102bed <env_alloc+0x67>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bcd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bd1:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0102bd8:	f0 
f0102bd9:	c7 44 24 04 58 00 00 	movl   $0x58,0x4(%esp)
f0102be0:	00 
f0102be1:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f0102be8:	e8 53 d4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0102bed:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bf2:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0102bf5:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0102bfa:	8b 15 0c 9f 22 f0    	mov    0xf0229f0c,%edx
f0102c00:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f0102c03:	8b 53 60             	mov    0x60(%ebx),%edx
f0102c06:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0102c09:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f0102c0c:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102c11:	75 e7                	jne    f0102bfa <env_alloc+0x74>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f0102c13:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c16:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c1b:	77 20                	ja     f0102c3d <env_alloc+0xb7>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c1d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c21:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0102c28:	f0 
f0102c29:	c7 44 24 04 d0 00 00 	movl   $0xd0,0x4(%esp)
f0102c30:	00 
f0102c31:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102c38:	e8 03 d4 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102c3d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0102c43:	83 ca 05             	or     $0x5,%edx
f0102c46:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f0102c4c:	8b 43 48             	mov    0x48(%ebx),%eax
f0102c4f:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f0102c54:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f0102c59:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102c5e:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f0102c61:	89 da                	mov    %ebx,%edx
f0102c63:	2b 15 4c 92 22 f0    	sub    0xf022924c,%edx
f0102c69:	c1 fa 02             	sar    $0x2,%edx
f0102c6c:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f0102c72:	09 d0                	or     %edx,%eax
f0102c74:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f0102c77:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102c7a:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f0102c7d:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f0102c84:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f0102c8b:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f0102c92:	c7 44 24 08 44 00 00 	movl   $0x44,0x8(%esp)
f0102c99:	00 
f0102c9a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102ca1:	00 
f0102ca2:	89 1c 24             	mov    %ebx,(%esp)
f0102ca5:	e8 2d 1c 00 00       	call   f01048d7 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f0102caa:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0102cb0:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f0102cb6:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0102cbc:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0102cc3:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0102cc9:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f0102cd0:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0102cd4:	8b 43 44             	mov    0x44(%ebx),%eax
f0102cd7:	a3 50 92 22 f0       	mov    %eax,0xf0229250
	*newenv_store = e;
f0102cdc:	8b 45 08             	mov    0x8(%ebp),%eax
f0102cdf:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102ce1:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0102ce4:	e8 40 22 00 00       	call   f0104f29 <cpunum>
f0102ce9:	6b d0 74             	imul   $0x74,%eax,%edx
f0102cec:	b8 00 00 00 00       	mov    $0x0,%eax
f0102cf1:	83 ba 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%edx)
f0102cf8:	74 11                	je     f0102d0b <env_alloc+0x185>
f0102cfa:	e8 2a 22 00 00       	call   f0104f29 <cpunum>
f0102cff:	6b c0 74             	imul   $0x74,%eax,%eax
f0102d02:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0102d08:	8b 40 48             	mov    0x48(%eax),%eax
f0102d0b:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102d0f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d13:	c7 04 24 05 65 10 f0 	movl   $0xf0106505,(%esp)
f0102d1a:	e8 71 06 00 00       	call   f0103390 <cprintf>
	return 0;
f0102d1f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d24:	eb 0c                	jmp    f0102d32 <env_alloc+0x1ac>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0102d26:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f0102d2b:	eb 05                	jmp    f0102d32 <env_alloc+0x1ac>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f0102d2d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0102d32:	83 c4 14             	add    $0x14,%esp
f0102d35:	5b                   	pop    %ebx
f0102d36:	5d                   	pop    %ebp
f0102d37:	c3                   	ret    

f0102d38 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0102d38:	55                   	push   %ebp
f0102d39:	89 e5                	mov    %esp,%ebp
f0102d3b:	57                   	push   %edi
f0102d3c:	56                   	push   %esi
f0102d3d:	53                   	push   %ebx
f0102d3e:	83 ec 3c             	sub    $0x3c,%esp
f0102d41:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0102d44:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102d4b:	00 
f0102d4c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102d4f:	89 04 24             	mov    %eax,(%esp)
f0102d52:	e8 2f fe ff ff       	call   f0102b86 <env_alloc>
	if (r){
f0102d57:	85 c0                	test   %eax,%eax
f0102d59:	74 20                	je     f0102d7b <env_create+0x43>
	panic("env_alloc: %e", r);
f0102d5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d5f:	c7 44 24 08 1a 65 10 	movl   $0xf010651a,0x8(%esp)
f0102d66:	f0 
f0102d67:	c7 44 24 04 b1 01 00 	movl   $0x1b1,0x4(%esp)
f0102d6e:	00 
f0102d6f:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102d76:	e8 c5 d2 ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f0102d7b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102d7e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f0102d81:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0102d87:	74 1c                	je     f0102da5 <env_create+0x6d>
	{
		panic ("Not a valid ELF binary image");
f0102d89:	c7 44 24 08 28 65 10 	movl   $0xf0106528,0x8(%esp)
f0102d90:	f0 
f0102d91:	c7 44 24 04 80 01 00 	movl   $0x180,0x4(%esp)
f0102d98:	00 
f0102d99:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102da0:	e8 9b d2 ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f0102da5:	89 fb                	mov    %edi,%ebx
f0102da7:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f0102daa:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f0102dae:	c1 e6 05             	shl    $0x5,%esi
f0102db1:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f0102db3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102db6:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102db9:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dbe:	77 20                	ja     f0102de0 <env_create+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dc0:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dc4:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0102dcb:	f0 
f0102dcc:	c7 44 24 04 87 01 00 	movl   $0x187,0x4(%esp)
f0102dd3:	00 
f0102dd4:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102ddb:	e8 60 d2 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102de0:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102de5:	0f 22 d8             	mov    %eax,%cr3
f0102de8:	eb 71                	jmp    f0102e5b <env_create+0x123>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f0102dea:	83 3b 01             	cmpl   $0x1,(%ebx)
f0102ded:	75 69                	jne    f0102e58 <env_create+0x120>
		
		if(ph->p_memsz < ph->p_filesz){
f0102def:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0102df2:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0102df5:	73 1c                	jae    f0102e13 <env_create+0xdb>
		panic ("Memory size is smaller than file size!!");
f0102df7:	c7 44 24 08 8c 65 10 	movl   $0xf010658c,0x8(%esp)
f0102dfe:	f0 
f0102dff:	c7 44 24 04 8d 01 00 	movl   $0x18d,0x4(%esp)
f0102e06:	00 
f0102e07:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102e0e:	e8 2d d2 ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f0102e13:	8b 53 08             	mov    0x8(%ebx),%edx
f0102e16:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102e19:	e8 c5 fb ff ff       	call   f01029e3 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0102e1e:	8b 43 10             	mov    0x10(%ebx),%eax
f0102e21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102e25:	89 f8                	mov    %edi,%eax
f0102e27:	03 43 04             	add    0x4(%ebx),%eax
f0102e2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102e2e:	8b 43 08             	mov    0x8(%ebx),%eax
f0102e31:	89 04 24             	mov    %eax,(%esp)
f0102e34:	e8 53 1b 00 00       	call   f010498c <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f0102e39:	8b 43 10             	mov    0x10(%ebx),%eax
f0102e3c:	8b 53 14             	mov    0x14(%ebx),%edx
f0102e3f:	29 c2                	sub    %eax,%edx
f0102e41:	89 54 24 08          	mov    %edx,0x8(%esp)
f0102e45:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102e4c:	00 
f0102e4d:	03 43 08             	add    0x8(%ebx),%eax
f0102e50:	89 04 24             	mov    %eax,(%esp)
f0102e53:	e8 7f 1a 00 00       	call   f01048d7 <memset>
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0102e58:	83 c3 20             	add    $0x20,%ebx
f0102e5b:	39 de                	cmp    %ebx,%esi
f0102e5d:	77 8b                	ja     f0102dea <env_create+0xb2>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f0102e5f:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e64:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102e69:	77 20                	ja     f0102e8b <env_create+0x153>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e6b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e6f:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0102e76:	f0 
f0102e77:	c7 44 24 04 9a 01 00 	movl   $0x19a,0x4(%esp)
f0102e7e:	00 
f0102e7f:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102e86:	e8 b5 d1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102e8b:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e90:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0102e93:	8b 47 18             	mov    0x18(%edi),%eax
f0102e96:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102e99:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0102e9c:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0102ea1:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0102ea6:	89 f8                	mov    %edi,%eax
f0102ea8:	e8 36 fb ff ff       	call   f01029e3 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f0102ead:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102eb0:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102eb3:	89 50 50             	mov    %edx,0x50(%eax)
}
f0102eb6:	83 c4 3c             	add    $0x3c,%esp
f0102eb9:	5b                   	pop    %ebx
f0102eba:	5e                   	pop    %esi
f0102ebb:	5f                   	pop    %edi
f0102ebc:	5d                   	pop    %ebp
f0102ebd:	c3                   	ret    

f0102ebe <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f0102ebe:	55                   	push   %ebp
f0102ebf:	89 e5                	mov    %esp,%ebp
f0102ec1:	57                   	push   %edi
f0102ec2:	56                   	push   %esi
f0102ec3:	53                   	push   %ebx
f0102ec4:	83 ec 2c             	sub    $0x2c,%esp
f0102ec7:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f0102eca:	e8 5a 20 00 00       	call   f0104f29 <cpunum>
f0102ecf:	6b c0 74             	imul   $0x74,%eax,%eax
f0102ed2:	39 b8 28 a0 22 f0    	cmp    %edi,-0xfdd5fd8(%eax)
f0102ed8:	75 34                	jne    f0102f0e <env_free+0x50>
		lcr3(PADDR(kern_pgdir));
f0102eda:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102edf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102ee4:	77 20                	ja     f0102f06 <env_free+0x48>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ee6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102eea:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0102ef1:	f0 
f0102ef2:	c7 44 24 04 c7 01 00 	movl   $0x1c7,0x4(%esp)
f0102ef9:	00 
f0102efa:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102f01:	e8 3a d1 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102f06:	05 00 00 00 10       	add    $0x10000000,%eax
f0102f0b:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0102f0e:	8b 5f 48             	mov    0x48(%edi),%ebx
f0102f11:	e8 13 20 00 00       	call   f0104f29 <cpunum>
f0102f16:	6b d0 74             	imul   $0x74,%eax,%edx
f0102f19:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f1e:	83 ba 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%edx)
f0102f25:	74 11                	je     f0102f38 <env_free+0x7a>
f0102f27:	e8 fd 1f 00 00       	call   f0104f29 <cpunum>
f0102f2c:	6b c0 74             	imul   $0x74,%eax,%eax
f0102f2f:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0102f35:	8b 40 48             	mov    0x48(%eax),%eax
f0102f38:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102f3c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f40:	c7 04 24 45 65 10 f0 	movl   $0xf0106545,(%esp)
f0102f47:	e8 44 04 00 00       	call   f0103390 <cprintf>

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0102f4c:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0102f53:	8b 4d e0             	mov    -0x20(%ebp),%ecx
f0102f56:	89 c8                	mov    %ecx,%eax
f0102f58:	c1 e0 02             	shl    $0x2,%eax
f0102f5b:	89 45 dc             	mov    %eax,-0x24(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0102f5e:	8b 47 60             	mov    0x60(%edi),%eax
f0102f61:	8b 34 88             	mov    (%eax,%ecx,4),%esi
f0102f64:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0102f6a:	0f 84 b7 00 00 00    	je     f0103027 <env_free+0x169>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0102f70:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102f76:	89 f0                	mov    %esi,%eax
f0102f78:	c1 e8 0c             	shr    $0xc,%eax
f0102f7b:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0102f7e:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0102f84:	72 20                	jb     f0102fa6 <env_free+0xe8>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102f86:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102f8a:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0102f91:	f0 
f0102f92:	c7 44 24 04 d6 01 00 	movl   $0x1d6,0x4(%esp)
f0102f99:	00 
f0102f9a:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0102fa1:	e8 9a d0 ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102fa6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102fa9:	c1 e0 16             	shl    $0x16,%eax
f0102fac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102faf:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f0102fb4:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0102fbb:	01 
f0102fbc:	74 17                	je     f0102fd5 <env_free+0x117>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0102fbe:	89 d8                	mov    %ebx,%eax
f0102fc0:	c1 e0 0c             	shl    $0xc,%eax
f0102fc3:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0102fc6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102fca:	8b 47 60             	mov    0x60(%edi),%eax
f0102fcd:	89 04 24             	mov    %eax,(%esp)
f0102fd0:	e8 0f e0 ff ff       	call   f0100fe4 <page_remove>
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0102fd5:	83 c3 01             	add    $0x1,%ebx
f0102fd8:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0102fde:	75 d4                	jne    f0102fb4 <env_free+0xf6>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0102fe0:	8b 47 60             	mov    0x60(%edi),%eax
f0102fe3:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102fe6:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102fed:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0102ff0:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0102ff6:	72 1c                	jb     f0103014 <env_free+0x156>
		panic("pa2page called with invalid pa");
f0102ff8:	c7 44 24 08 b4 65 10 	movl   $0xf01065b4,0x8(%esp)
f0102fff:	f0 
f0103000:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103007:	00 
f0103008:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f010300f:	e8 2c d0 ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103014:	a1 10 9f 22 f0       	mov    0xf0229f10,%eax
f0103019:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010301c:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		page_decref(pa2page(pa));
f010301f:	89 04 24             	mov    %eax,(%esp)
f0103022:	e8 00 de ff ff       	call   f0100e27 <page_decref>
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103027:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f010302b:	81 7d e0 bb 03 00 00 	cmpl   $0x3bb,-0x20(%ebp)
f0103032:	0f 85 1b ff ff ff    	jne    f0102f53 <env_free+0x95>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103038:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010303b:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103040:	77 20                	ja     f0103062 <env_free+0x1a4>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103042:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103046:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f010304d:	f0 
f010304e:	c7 44 24 04 e4 01 00 	movl   $0x1e4,0x4(%esp)
f0103055:	00 
f0103056:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f010305d:	e8 de cf ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f0103062:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103069:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010306e:	c1 e8 0c             	shr    $0xc,%eax
f0103071:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0103077:	72 1c                	jb     f0103095 <env_free+0x1d7>
		panic("pa2page called with invalid pa");
f0103079:	c7 44 24 08 b4 65 10 	movl   $0xf01065b4,0x8(%esp)
f0103080:	f0 
f0103081:	c7 44 24 04 51 00 00 	movl   $0x51,0x4(%esp)
f0103088:	00 
f0103089:	c7 04 24 19 62 10 f0 	movl   $0xf0106219,(%esp)
f0103090:	e8 ab cf ff ff       	call   f0100040 <_panic>
	return &pages[PGNUM(pa)];
f0103095:	8b 15 10 9f 22 f0    	mov    0xf0229f10,%edx
f010309b:	8d 04 c2             	lea    (%edx,%eax,8),%eax
	page_decref(pa2page(pa));
f010309e:	89 04 24             	mov    %eax,(%esp)
f01030a1:	e8 81 dd ff ff       	call   f0100e27 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f01030a6:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f01030ad:	a1 50 92 22 f0       	mov    0xf0229250,%eax
f01030b2:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f01030b5:	89 3d 50 92 22 f0    	mov    %edi,0xf0229250
}
f01030bb:	83 c4 2c             	add    $0x2c,%esp
f01030be:	5b                   	pop    %ebx
f01030bf:	5e                   	pop    %esi
f01030c0:	5f                   	pop    %edi
f01030c1:	5d                   	pop    %ebp
f01030c2:	c3                   	ret    

f01030c3 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f01030c3:	55                   	push   %ebp
f01030c4:	89 e5                	mov    %esp,%ebp
f01030c6:	53                   	push   %ebx
f01030c7:	83 ec 14             	sub    $0x14,%esp
f01030ca:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f01030cd:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f01030d1:	75 19                	jne    f01030ec <env_destroy+0x29>
f01030d3:	e8 51 1e 00 00       	call   f0104f29 <cpunum>
f01030d8:	6b c0 74             	imul   $0x74,%eax,%eax
f01030db:	39 98 28 a0 22 f0    	cmp    %ebx,-0xfdd5fd8(%eax)
f01030e1:	74 09                	je     f01030ec <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01030e3:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01030ea:	eb 2f                	jmp    f010311b <env_destroy+0x58>
	}

	env_free(e);
f01030ec:	89 1c 24             	mov    %ebx,(%esp)
f01030ef:	e8 ca fd ff ff       	call   f0102ebe <env_free>

	if (curenv == e) {
f01030f4:	e8 30 1e 00 00       	call   f0104f29 <cpunum>
f01030f9:	6b c0 74             	imul   $0x74,%eax,%eax
f01030fc:	39 98 28 a0 22 f0    	cmp    %ebx,-0xfdd5fd8(%eax)
f0103102:	75 17                	jne    f010311b <env_destroy+0x58>
		curenv = NULL;
f0103104:	e8 20 1e 00 00       	call   f0104f29 <cpunum>
f0103109:	6b c0 74             	imul   $0x74,%eax,%eax
f010310c:	c7 80 28 a0 22 f0 00 	movl   $0x0,-0xfdd5fd8(%eax)
f0103113:	00 00 00 
		sched_yield();
f0103116:	e8 25 0a 00 00       	call   f0103b40 <sched_yield>
	}
}
f010311b:	83 c4 14             	add    $0x14,%esp
f010311e:	5b                   	pop    %ebx
f010311f:	5d                   	pop    %ebp
f0103120:	c3                   	ret    

f0103121 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f0103121:	55                   	push   %ebp
f0103122:	89 e5                	mov    %esp,%ebp
f0103124:	53                   	push   %ebx
f0103125:	83 ec 14             	sub    $0x14,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f0103128:	e8 fc 1d 00 00       	call   f0104f29 <cpunum>
f010312d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103130:	8b 98 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%ebx
f0103136:	e8 ee 1d 00 00       	call   f0104f29 <cpunum>
f010313b:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f010313e:	8b 65 08             	mov    0x8(%ebp),%esp
f0103141:	61                   	popa   
f0103142:	07                   	pop    %es
f0103143:	1f                   	pop    %ds
f0103144:	83 c4 08             	add    $0x8,%esp
f0103147:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103148:	c7 44 24 08 5b 65 10 	movl   $0xf010655b,0x8(%esp)
f010314f:	f0 
f0103150:	c7 44 24 04 1a 02 00 	movl   $0x21a,0x4(%esp)
f0103157:	00 
f0103158:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f010315f:	e8 dc ce ff ff       	call   f0100040 <_panic>

f0103164 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f0103164:	55                   	push   %ebp
f0103165:	89 e5                	mov    %esp,%ebp
f0103167:	53                   	push   %ebx
f0103168:	83 ec 14             	sub    $0x14,%esp
f010316b:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f010316e:	e8 b6 1d 00 00       	call   f0104f29 <cpunum>
f0103173:	6b c0 74             	imul   $0x74,%eax,%eax
f0103176:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f010317d:	75 10                	jne    f010318f <env_run+0x2b>
	curenv = e;
f010317f:	e8 a5 1d 00 00       	call   f0104f29 <cpunum>
f0103184:	6b c0 74             	imul   $0x74,%eax,%eax
f0103187:	89 98 28 a0 22 f0    	mov    %ebx,-0xfdd5fd8(%eax)
f010318d:	eb 29                	jmp    f01031b8 <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f010318f:	e8 95 1d 00 00       	call   f0104f29 <cpunum>
f0103194:	6b c0 74             	imul   $0x74,%eax,%eax
f0103197:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f010319d:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f01031a1:	75 15                	jne    f01031b8 <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f01031a3:	e8 81 1d 00 00       	call   f0104f29 <cpunum>
f01031a8:	6b c0 74             	imul   $0x74,%eax,%eax
f01031ab:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f01031b1:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f01031b8:	e8 6c 1d 00 00       	call   f0104f29 <cpunum>
f01031bd:	6b c0 74             	imul   $0x74,%eax,%eax
f01031c0:	89 98 28 a0 22 f0    	mov    %ebx,-0xfdd5fd8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f01031c6:	e8 5e 1d 00 00       	call   f0104f29 <cpunum>
f01031cb:	6b c0 74             	imul   $0x74,%eax,%eax
f01031ce:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f01031d4:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f01031db:	e8 49 1d 00 00       	call   f0104f29 <cpunum>
f01031e0:	6b c0 74             	imul   $0x74,%eax,%eax
f01031e3:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f01031e9:	83 40 58 01          	addl   $0x1,0x58(%eax)
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f01031ed:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01031f0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01031f5:	77 20                	ja     f0103217 <env_run+0xb3>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01031f7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031fb:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0103202:	f0 
f0103203:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
f010320a:	00 
f010320b:	c7 04 24 fa 64 10 f0 	movl   $0xf01064fa,(%esp)
f0103212:	e8 29 ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103217:	05 00 00 00 10       	add    $0x10000000,%eax
f010321c:	0f 22 d8             	mov    %eax,%cr3

	env_pop_tf(&e->env_tf);
f010321f:	89 1c 24             	mov    %ebx,(%esp)
f0103222:	e8 fa fe ff ff       	call   f0103121 <env_pop_tf>

f0103227 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103227:	55                   	push   %ebp
f0103228:	89 e5                	mov    %esp,%ebp
f010322a:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010322e:	ba 70 00 00 00       	mov    $0x70,%edx
f0103233:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103234:	b2 71                	mov    $0x71,%dl
f0103236:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103237:	0f b6 c0             	movzbl %al,%eax
}
f010323a:	5d                   	pop    %ebp
f010323b:	c3                   	ret    

f010323c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010323c:	55                   	push   %ebp
f010323d:	89 e5                	mov    %esp,%ebp
f010323f:	0f b6 45 08          	movzbl 0x8(%ebp),%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103243:	ba 70 00 00 00       	mov    $0x70,%edx
f0103248:	ee                   	out    %al,(%dx)
f0103249:	b2 71                	mov    $0x71,%dl
f010324b:	8b 45 0c             	mov    0xc(%ebp),%eax
f010324e:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010324f:	5d                   	pop    %ebp
f0103250:	c3                   	ret    

f0103251 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f0103251:	55                   	push   %ebp
f0103252:	89 e5                	mov    %esp,%ebp
f0103254:	56                   	push   %esi
f0103255:	53                   	push   %ebx
f0103256:	83 ec 10             	sub    $0x10,%esp
f0103259:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f010325c:	66 a3 88 e3 11 f0    	mov    %ax,0xf011e388
	if (!didinit)
f0103262:	80 3d 54 92 22 f0 00 	cmpb   $0x0,0xf0229254
f0103269:	74 4e                	je     f01032b9 <irq_setmask_8259A+0x68>
f010326b:	89 c6                	mov    %eax,%esi
f010326d:	ba 21 00 00 00       	mov    $0x21,%edx
f0103272:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103273:	66 c1 e8 08          	shr    $0x8,%ax
f0103277:	b2 a1                	mov    $0xa1,%dl
f0103279:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f010327a:	c7 04 24 d3 65 10 f0 	movl   $0xf01065d3,(%esp)
f0103281:	e8 0a 01 00 00       	call   f0103390 <cprintf>
	for (i = 0; i < 16; i++)
f0103286:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f010328b:	0f b7 f6             	movzwl %si,%esi
f010328e:	f7 d6                	not    %esi
f0103290:	0f a3 de             	bt     %ebx,%esi
f0103293:	73 10                	jae    f01032a5 <irq_setmask_8259A+0x54>
			cprintf(" %d", i);
f0103295:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103299:	c7 04 24 aa 6a 10 f0 	movl   $0xf0106aaa,(%esp)
f01032a0:	e8 eb 00 00 00       	call   f0103390 <cprintf>
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f01032a5:	83 c3 01             	add    $0x1,%ebx
f01032a8:	83 fb 10             	cmp    $0x10,%ebx
f01032ab:	75 e3                	jne    f0103290 <irq_setmask_8259A+0x3f>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f01032ad:	c7 04 24 72 6a 10 f0 	movl   $0xf0106a72,(%esp)
f01032b4:	e8 d7 00 00 00       	call   f0103390 <cprintf>
}
f01032b9:	83 c4 10             	add    $0x10,%esp
f01032bc:	5b                   	pop    %ebx
f01032bd:	5e                   	pop    %esi
f01032be:	5d                   	pop    %ebp
f01032bf:	c3                   	ret    

f01032c0 <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f01032c0:	c6 05 54 92 22 f0 01 	movb   $0x1,0xf0229254
f01032c7:	ba 21 00 00 00       	mov    $0x21,%edx
f01032cc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032d1:	ee                   	out    %al,(%dx)
f01032d2:	b2 a1                	mov    $0xa1,%dl
f01032d4:	ee                   	out    %al,(%dx)
f01032d5:	b2 20                	mov    $0x20,%dl
f01032d7:	b8 11 00 00 00       	mov    $0x11,%eax
f01032dc:	ee                   	out    %al,(%dx)
f01032dd:	b2 21                	mov    $0x21,%dl
f01032df:	b8 20 00 00 00       	mov    $0x20,%eax
f01032e4:	ee                   	out    %al,(%dx)
f01032e5:	b8 04 00 00 00       	mov    $0x4,%eax
f01032ea:	ee                   	out    %al,(%dx)
f01032eb:	b8 03 00 00 00       	mov    $0x3,%eax
f01032f0:	ee                   	out    %al,(%dx)
f01032f1:	b2 a0                	mov    $0xa0,%dl
f01032f3:	b8 11 00 00 00       	mov    $0x11,%eax
f01032f8:	ee                   	out    %al,(%dx)
f01032f9:	b2 a1                	mov    $0xa1,%dl
f01032fb:	b8 28 00 00 00       	mov    $0x28,%eax
f0103300:	ee                   	out    %al,(%dx)
f0103301:	b8 02 00 00 00       	mov    $0x2,%eax
f0103306:	ee                   	out    %al,(%dx)
f0103307:	b8 01 00 00 00       	mov    $0x1,%eax
f010330c:	ee                   	out    %al,(%dx)
f010330d:	b2 20                	mov    $0x20,%dl
f010330f:	b8 68 00 00 00       	mov    $0x68,%eax
f0103314:	ee                   	out    %al,(%dx)
f0103315:	b8 0a 00 00 00       	mov    $0xa,%eax
f010331a:	ee                   	out    %al,(%dx)
f010331b:	b2 a0                	mov    $0xa0,%dl
f010331d:	b8 68 00 00 00       	mov    $0x68,%eax
f0103322:	ee                   	out    %al,(%dx)
f0103323:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103328:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f0103329:	0f b7 05 88 e3 11 f0 	movzwl 0xf011e388,%eax
f0103330:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103334:	74 12                	je     f0103348 <pic_init+0x88>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103336:	55                   	push   %ebp
f0103337:	89 e5                	mov    %esp,%ebp
f0103339:	83 ec 18             	sub    $0x18,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010333c:	0f b7 c0             	movzwl %ax,%eax
f010333f:	89 04 24             	mov    %eax,(%esp)
f0103342:	e8 0a ff ff ff       	call   f0103251 <irq_setmask_8259A>
}
f0103347:	c9                   	leave  
f0103348:	f3 c3                	repz ret 

f010334a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010334a:	55                   	push   %ebp
f010334b:	89 e5                	mov    %esp,%ebp
f010334d:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103350:	8b 45 08             	mov    0x8(%ebp),%eax
f0103353:	89 04 24             	mov    %eax,(%esp)
f0103356:	e8 0f d4 ff ff       	call   f010076a <cputchar>
	*cnt++;
}
f010335b:	c9                   	leave  
f010335c:	c3                   	ret    

f010335d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010335d:	55                   	push   %ebp
f010335e:	89 e5                	mov    %esp,%ebp
f0103360:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103363:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010336a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010336d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103371:	8b 45 08             	mov    0x8(%ebp),%eax
f0103374:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103378:	8d 45 f4             	lea    -0xc(%ebp),%eax
f010337b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010337f:	c7 04 24 4a 33 10 f0 	movl   $0xf010334a,(%esp)
f0103386:	e8 93 0e 00 00       	call   f010421e <vprintfmt>
	return cnt;
}
f010338b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010338e:	c9                   	leave  
f010338f:	c3                   	ret    

f0103390 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103390:	55                   	push   %ebp
f0103391:	89 e5                	mov    %esp,%ebp
f0103393:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103396:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103399:	89 44 24 04          	mov    %eax,0x4(%esp)
f010339d:	8b 45 08             	mov    0x8(%ebp),%eax
f01033a0:	89 04 24             	mov    %eax,(%esp)
f01033a3:	e8 b5 ff ff ff       	call   f010335d <vcprintf>
	va_end(ap);

	return cnt;
}
f01033a8:	c9                   	leave  
f01033a9:	c3                   	ret    
f01033aa:	66 90                	xchg   %ax,%ax
f01033ac:	66 90                	xchg   %ax,%ax
f01033ae:	66 90                	xchg   %ax,%ax

f01033b0 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f01033b0:	55                   	push   %ebp
f01033b1:	89 e5                	mov    %esp,%ebp
	//
	// LAB 4: Your code here:

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	ts.ts_esp0 = KSTACKTOP;
f01033b3:	c7 05 84 9a 22 f0 00 	movl   $0xf0000000,0xf0229a84
f01033ba:	00 00 f0 
	ts.ts_ss0 = GD_KD;
f01033bd:	66 c7 05 88 9a 22 f0 	movw   $0x10,0xf0229a88
f01033c4:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[GD_TSS0 >> 3] = SEG16(STS_T32A, (uint32_t) (&ts),
f01033c6:	66 c7 05 48 e3 11 f0 	movw   $0x67,0xf011e348
f01033cd:	67 00 
f01033cf:	b8 80 9a 22 f0       	mov    $0xf0229a80,%eax
f01033d4:	66 a3 4a e3 11 f0    	mov    %ax,0xf011e34a
f01033da:	89 c2                	mov    %eax,%edx
f01033dc:	c1 ea 10             	shr    $0x10,%edx
f01033df:	88 15 4c e3 11 f0    	mov    %dl,0xf011e34c
f01033e5:	c6 05 4e e3 11 f0 40 	movb   $0x40,0xf011e34e
f01033ec:	c1 e8 18             	shr    $0x18,%eax
f01033ef:	a2 4f e3 11 f0       	mov    %al,0xf011e34f
					sizeof(struct Taskstate) - 1, 0);
	gdt[GD_TSS0 >> 3].sd_s = 0;
f01033f4:	c6 05 4d e3 11 f0 89 	movb   $0x89,0xf011e34d
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01033fb:	b8 28 00 00 00       	mov    $0x28,%eax
f0103400:	0f 00 d8             	ltr    %ax
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f0103403:	b8 8a e3 11 f0       	mov    $0xf011e38a,%eax
f0103408:	0f 01 18             	lidtl  (%eax)
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);

	// Load the IDT
	lidt(&idt_pd);
}
f010340b:	5d                   	pop    %ebp
f010340c:	c3                   	ret    

f010340d <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f010340d:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f0103412:	8b 14 85 90 e3 11 f0 	mov    -0xfee1c70(,%eax,4),%edx
f0103419:	66 89 14 c5 60 92 22 	mov    %dx,-0xfdd6da0(,%eax,8)
f0103420:	f0 
f0103421:	66 c7 04 c5 62 92 22 	movw   $0x8,-0xfdd6d9e(,%eax,8)
f0103428:	f0 08 00 
f010342b:	c6 04 c5 64 92 22 f0 	movb   $0x0,-0xfdd6d9c(,%eax,8)
f0103432:	00 
f0103433:	c6 04 c5 65 92 22 f0 	movb   $0x8e,-0xfdd6d9b(,%eax,8)
f010343a:	8e 
f010343b:	c1 ea 10             	shr    $0x10,%edx
f010343e:	66 89 14 c5 66 92 22 	mov    %dx,-0xfdd6d9a(,%eax,8)
f0103445:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f0103446:	83 c0 01             	add    $0x1,%eax
f0103449:	83 f8 14             	cmp    $0x14,%eax
f010344c:	75 c4                	jne    f0103412 <trap_init+0x5>
}


void
trap_init(void)
{
f010344e:	55                   	push   %ebp
f010344f:	89 e5                	mov    %esp,%ebp
	for (i=0; i<= T_SIMDERR;i++){
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f0103451:	a1 9c e3 11 f0       	mov    0xf011e39c,%eax
f0103456:	66 a3 78 92 22 f0    	mov    %ax,0xf0229278
f010345c:	66 c7 05 7a 92 22 f0 	movw   $0x8,0xf022927a
f0103463:	08 00 
f0103465:	c6 05 7c 92 22 f0 00 	movb   $0x0,0xf022927c
f010346c:	c6 05 7d 92 22 f0 ee 	movb   $0xee,0xf022927d
f0103473:	c1 e8 10             	shr    $0x10,%eax
f0103476:	66 a3 7e 92 22 f0    	mov    %ax,0xf022927e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f010347c:	a1 50 e4 11 f0       	mov    0xf011e450,%eax
f0103481:	66 a3 e0 93 22 f0    	mov    %ax,0xf02293e0
f0103487:	66 c7 05 e2 93 22 f0 	movw   $0x8,0xf02293e2
f010348e:	08 00 
f0103490:	c6 05 e4 93 22 f0 00 	movb   $0x0,0xf02293e4
f0103497:	c6 05 e5 93 22 f0 ee 	movb   $0xee,0xf02293e5
f010349e:	c1 e8 10             	shr    $0x10,%eax
f01034a1:	66 a3 e6 93 22 f0    	mov    %ax,0xf02293e6

	// Per-CPU setup 
	trap_init_percpu();
f01034a7:	e8 04 ff ff ff       	call   f01033b0 <trap_init_percpu>
}
f01034ac:	5d                   	pop    %ebp
f01034ad:	c3                   	ret    

f01034ae <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01034ae:	55                   	push   %ebp
f01034af:	89 e5                	mov    %esp,%ebp
f01034b1:	53                   	push   %ebx
f01034b2:	83 ec 14             	sub    $0x14,%esp
f01034b5:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01034b8:	8b 03                	mov    (%ebx),%eax
f01034ba:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034be:	c7 04 24 e7 65 10 f0 	movl   $0xf01065e7,(%esp)
f01034c5:	e8 c6 fe ff ff       	call   f0103390 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01034ca:	8b 43 04             	mov    0x4(%ebx),%eax
f01034cd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034d1:	c7 04 24 f6 65 10 f0 	movl   $0xf01065f6,(%esp)
f01034d8:	e8 b3 fe ff ff       	call   f0103390 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01034dd:	8b 43 08             	mov    0x8(%ebx),%eax
f01034e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034e4:	c7 04 24 05 66 10 f0 	movl   $0xf0106605,(%esp)
f01034eb:	e8 a0 fe ff ff       	call   f0103390 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01034f0:	8b 43 0c             	mov    0xc(%ebx),%eax
f01034f3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034f7:	c7 04 24 14 66 10 f0 	movl   $0xf0106614,(%esp)
f01034fe:	e8 8d fe ff ff       	call   f0103390 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f0103503:	8b 43 10             	mov    0x10(%ebx),%eax
f0103506:	89 44 24 04          	mov    %eax,0x4(%esp)
f010350a:	c7 04 24 23 66 10 f0 	movl   $0xf0106623,(%esp)
f0103511:	e8 7a fe ff ff       	call   f0103390 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f0103516:	8b 43 14             	mov    0x14(%ebx),%eax
f0103519:	89 44 24 04          	mov    %eax,0x4(%esp)
f010351d:	c7 04 24 32 66 10 f0 	movl   $0xf0106632,(%esp)
f0103524:	e8 67 fe ff ff       	call   f0103390 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103529:	8b 43 18             	mov    0x18(%ebx),%eax
f010352c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103530:	c7 04 24 41 66 10 f0 	movl   $0xf0106641,(%esp)
f0103537:	e8 54 fe ff ff       	call   f0103390 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f010353c:	8b 43 1c             	mov    0x1c(%ebx),%eax
f010353f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103543:	c7 04 24 50 66 10 f0 	movl   $0xf0106650,(%esp)
f010354a:	e8 41 fe ff ff       	call   f0103390 <cprintf>
}
f010354f:	83 c4 14             	add    $0x14,%esp
f0103552:	5b                   	pop    %ebx
f0103553:	5d                   	pop    %ebp
f0103554:	c3                   	ret    

f0103555 <print_trapframe>:
	lidt(&idt_pd);
}

void
print_trapframe(struct Trapframe *tf)
{
f0103555:	55                   	push   %ebp
f0103556:	89 e5                	mov    %esp,%ebp
f0103558:	56                   	push   %esi
f0103559:	53                   	push   %ebx
f010355a:	83 ec 10             	sub    $0x10,%esp
f010355d:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103560:	e8 c4 19 00 00       	call   f0104f29 <cpunum>
f0103565:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103569:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010356d:	c7 04 24 b4 66 10 f0 	movl   $0xf01066b4,(%esp)
f0103574:	e8 17 fe ff ff       	call   f0103390 <cprintf>
	print_regs(&tf->tf_regs);
f0103579:	89 1c 24             	mov    %ebx,(%esp)
f010357c:	e8 2d ff ff ff       	call   f01034ae <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103581:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103585:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103589:	c7 04 24 d2 66 10 f0 	movl   $0xf01066d2,(%esp)
f0103590:	e8 fb fd ff ff       	call   f0103390 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103595:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103599:	89 44 24 04          	mov    %eax,0x4(%esp)
f010359d:	c7 04 24 e5 66 10 f0 	movl   $0xf01066e5,(%esp)
f01035a4:	e8 e7 fd ff ff       	call   f0103390 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01035a9:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f01035ac:	83 f8 13             	cmp    $0x13,%eax
f01035af:	77 09                	ja     f01035ba <print_trapframe+0x65>
		return excnames[trapno];
f01035b1:	8b 14 85 a0 69 10 f0 	mov    -0xfef9660(,%eax,4),%edx
f01035b8:	eb 1f                	jmp    f01035d9 <print_trapframe+0x84>
	if (trapno == T_SYSCALL)
f01035ba:	83 f8 30             	cmp    $0x30,%eax
f01035bd:	74 15                	je     f01035d4 <print_trapframe+0x7f>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f01035bf:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
f01035c2:	83 fa 0f             	cmp    $0xf,%edx
f01035c5:	ba 6b 66 10 f0       	mov    $0xf010666b,%edx
f01035ca:	b9 7e 66 10 f0       	mov    $0xf010667e,%ecx
f01035cf:	0f 47 d1             	cmova  %ecx,%edx
f01035d2:	eb 05                	jmp    f01035d9 <print_trapframe+0x84>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f01035d4:	ba 5f 66 10 f0       	mov    $0xf010665f,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f01035d9:	89 54 24 08          	mov    %edx,0x8(%esp)
f01035dd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01035e1:	c7 04 24 f8 66 10 f0 	movl   $0xf01066f8,(%esp)
f01035e8:	e8 a3 fd ff ff       	call   f0103390 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f01035ed:	3b 1d 60 9a 22 f0    	cmp    0xf0229a60,%ebx
f01035f3:	75 19                	jne    f010360e <print_trapframe+0xb9>
f01035f5:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f01035f9:	75 13                	jne    f010360e <print_trapframe+0xb9>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f01035fb:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f01035fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103602:	c7 04 24 0a 67 10 f0 	movl   $0xf010670a,(%esp)
f0103609:	e8 82 fd ff ff       	call   f0103390 <cprintf>
	cprintf("  err  0x%08x", tf->tf_err);
f010360e:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103611:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103615:	c7 04 24 19 67 10 f0 	movl   $0xf0106719,(%esp)
f010361c:	e8 6f fd ff ff       	call   f0103390 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103621:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103625:	75 51                	jne    f0103678 <print_trapframe+0x123>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103627:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f010362a:	89 c2                	mov    %eax,%edx
f010362c:	83 e2 01             	and    $0x1,%edx
f010362f:	ba 8d 66 10 f0       	mov    $0xf010668d,%edx
f0103634:	b9 98 66 10 f0       	mov    $0xf0106698,%ecx
f0103639:	0f 45 ca             	cmovne %edx,%ecx
f010363c:	89 c2                	mov    %eax,%edx
f010363e:	83 e2 02             	and    $0x2,%edx
f0103641:	ba a4 66 10 f0       	mov    $0xf01066a4,%edx
f0103646:	be aa 66 10 f0       	mov    $0xf01066aa,%esi
f010364b:	0f 44 d6             	cmove  %esi,%edx
f010364e:	83 e0 04             	and    $0x4,%eax
f0103651:	b8 af 66 10 f0       	mov    $0xf01066af,%eax
f0103656:	be 00 68 10 f0       	mov    $0xf0106800,%esi
f010365b:	0f 44 c6             	cmove  %esi,%eax
f010365e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0103662:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103666:	89 44 24 04          	mov    %eax,0x4(%esp)
f010366a:	c7 04 24 27 67 10 f0 	movl   $0xf0106727,(%esp)
f0103671:	e8 1a fd ff ff       	call   f0103390 <cprintf>
f0103676:	eb 0c                	jmp    f0103684 <print_trapframe+0x12f>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103678:	c7 04 24 72 6a 10 f0 	movl   $0xf0106a72,(%esp)
f010367f:	e8 0c fd ff ff       	call   f0103390 <cprintf>
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103684:	8b 43 30             	mov    0x30(%ebx),%eax
f0103687:	89 44 24 04          	mov    %eax,0x4(%esp)
f010368b:	c7 04 24 36 67 10 f0 	movl   $0xf0106736,(%esp)
f0103692:	e8 f9 fc ff ff       	call   f0103390 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103697:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f010369b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010369f:	c7 04 24 45 67 10 f0 	movl   $0xf0106745,(%esp)
f01036a6:	e8 e5 fc ff ff       	call   f0103390 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f01036ab:	8b 43 38             	mov    0x38(%ebx),%eax
f01036ae:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036b2:	c7 04 24 58 67 10 f0 	movl   $0xf0106758,(%esp)
f01036b9:	e8 d2 fc ff ff       	call   f0103390 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f01036be:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f01036c2:	74 27                	je     f01036eb <print_trapframe+0x196>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f01036c4:	8b 43 3c             	mov    0x3c(%ebx),%eax
f01036c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036cb:	c7 04 24 67 67 10 f0 	movl   $0xf0106767,(%esp)
f01036d2:	e8 b9 fc ff ff       	call   f0103390 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f01036d7:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f01036db:	89 44 24 04          	mov    %eax,0x4(%esp)
f01036df:	c7 04 24 76 67 10 f0 	movl   $0xf0106776,(%esp)
f01036e6:	e8 a5 fc ff ff       	call   f0103390 <cprintf>
	}
}
f01036eb:	83 c4 10             	add    $0x10,%esp
f01036ee:	5b                   	pop    %ebx
f01036ef:	5e                   	pop    %esi
f01036f0:	5d                   	pop    %ebp
f01036f1:	c3                   	ret    

f01036f2 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f01036f2:	55                   	push   %ebp
f01036f3:	89 e5                	mov    %esp,%ebp
f01036f5:	57                   	push   %edi
f01036f6:	56                   	push   %esi
f01036f7:	53                   	push   %ebx
f01036f8:	83 ec 1c             	sub    $0x1c,%esp
f01036fb:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01036fe:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103701:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103705:	75 20                	jne    f0103727 <page_fault_handler+0x35>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103707:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010370b:	c7 44 24 08 4c 69 10 	movl   $0xf010694c,0x8(%esp)
f0103712:	f0 
f0103713:	c7 44 24 04 36 01 00 	movl   $0x136,0x4(%esp)
f010371a:	00 
f010371b:	c7 04 24 89 67 10 f0 	movl   $0xf0106789,(%esp)
f0103722:	e8 19 c9 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f0103727:	8b 7b 30             	mov    0x30(%ebx),%edi
		curenv->env_id, fault_va, tf->tf_eip);
f010372a:	e8 fa 17 00 00       	call   f0104f29 <cpunum>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010372f:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103733:	89 74 24 08          	mov    %esi,0x8(%esp)
		curenv->env_id, fault_va, tf->tf_eip);
f0103737:	6b c0 74             	imul   $0x74,%eax,%eax
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	// Destroy the environment that caused the fault.
	cprintf("[%08x] user fault va %08x ip %08x\n",
f010373a:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103740:	8b 40 48             	mov    0x48(%eax),%eax
f0103743:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103747:	c7 04 24 74 69 10 f0 	movl   $0xf0106974,(%esp)
f010374e:	e8 3d fc ff ff       	call   f0103390 <cprintf>
		curenv->env_id, fault_va, tf->tf_eip);
	print_trapframe(tf);
f0103753:	89 1c 24             	mov    %ebx,(%esp)
f0103756:	e8 fa fd ff ff       	call   f0103555 <print_trapframe>
	env_destroy(curenv);
f010375b:	e8 c9 17 00 00       	call   f0104f29 <cpunum>
f0103760:	6b c0 74             	imul   $0x74,%eax,%eax
f0103763:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103769:	89 04 24             	mov    %eax,(%esp)
f010376c:	e8 52 f9 ff ff       	call   f01030c3 <env_destroy>
}
f0103771:	83 c4 1c             	add    $0x1c,%esp
f0103774:	5b                   	pop    %ebx
f0103775:	5e                   	pop    %esi
f0103776:	5f                   	pop    %edi
f0103777:	5d                   	pop    %ebp
f0103778:	c3                   	ret    

f0103779 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103779:	55                   	push   %ebp
f010377a:	89 e5                	mov    %esp,%ebp
f010377c:	57                   	push   %edi
f010377d:	56                   	push   %esi
f010377e:	83 ec 20             	sub    $0x20,%esp
f0103781:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103784:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103785:	83 3d 00 9f 22 f0 00 	cmpl   $0x0,0xf0229f00
f010378c:	74 01                	je     f010378f <trap+0x16>
		asm volatile("hlt");
f010378e:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f010378f:	e8 95 17 00 00       	call   f0104f29 <cpunum>
f0103794:	6b d0 74             	imul   $0x74,%eax,%edx
f0103797:	81 c2 20 a0 22 f0    	add    $0xf022a020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f010379d:	b8 01 00 00 00       	mov    $0x1,%eax
f01037a2:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f01037a6:	83 f8 02             	cmp    $0x2,%eax
f01037a9:	75 0c                	jne    f01037b7 <trap+0x3e>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01037ab:	c7 04 24 60 e4 11 f0 	movl   $0xf011e460,(%esp)
f01037b2:	e8 f0 19 00 00       	call   f01051a7 <spin_lock>

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f01037b7:	9c                   	pushf  
f01037b8:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f01037b9:	f6 c4 02             	test   $0x2,%ah
f01037bc:	74 24                	je     f01037e2 <trap+0x69>
f01037be:	c7 44 24 0c 95 67 10 	movl   $0xf0106795,0xc(%esp)
f01037c5:	f0 
f01037c6:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f01037cd:	f0 
f01037ce:	c7 44 24 04 fd 00 00 	movl   $0xfd,0x4(%esp)
f01037d5:	00 
f01037d6:	c7 04 24 89 67 10 f0 	movl   $0xf0106789,(%esp)
f01037dd:	e8 5e c8 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f01037e2:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f01037e6:	83 e0 03             	and    $0x3,%eax
f01037e9:	66 83 f8 03          	cmp    $0x3,%ax
f01037ed:	0f 85 9b 00 00 00    	jne    f010388e <trap+0x115>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		assert(curenv);
f01037f3:	e8 31 17 00 00       	call   f0104f29 <cpunum>
f01037f8:	6b c0 74             	imul   $0x74,%eax,%eax
f01037fb:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f0103802:	75 24                	jne    f0103828 <trap+0xaf>
f0103804:	c7 44 24 0c ae 67 10 	movl   $0xf01067ae,0xc(%esp)
f010380b:	f0 
f010380c:	c7 44 24 08 56 62 10 	movl   $0xf0106256,0x8(%esp)
f0103813:	f0 
f0103814:	c7 44 24 04 04 01 00 	movl   $0x104,0x4(%esp)
f010381b:	00 
f010381c:	c7 04 24 89 67 10 f0 	movl   $0xf0106789,(%esp)
f0103823:	e8 18 c8 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103828:	e8 fc 16 00 00       	call   f0104f29 <cpunum>
f010382d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103830:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103836:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f010383a:	75 2d                	jne    f0103869 <trap+0xf0>
			env_free(curenv);
f010383c:	e8 e8 16 00 00       	call   f0104f29 <cpunum>
f0103841:	6b c0 74             	imul   $0x74,%eax,%eax
f0103844:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f010384a:	89 04 24             	mov    %eax,(%esp)
f010384d:	e8 6c f6 ff ff       	call   f0102ebe <env_free>
			curenv = NULL;
f0103852:	e8 d2 16 00 00       	call   f0104f29 <cpunum>
f0103857:	6b c0 74             	imul   $0x74,%eax,%eax
f010385a:	c7 80 28 a0 22 f0 00 	movl   $0x0,-0xfdd5fd8(%eax)
f0103861:	00 00 00 
			sched_yield();
f0103864:	e8 d7 02 00 00       	call   f0103b40 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103869:	e8 bb 16 00 00       	call   f0104f29 <cpunum>
f010386e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103871:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103877:	b9 11 00 00 00       	mov    $0x11,%ecx
f010387c:	89 c7                	mov    %eax,%edi
f010387e:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103880:	e8 a4 16 00 00       	call   f0104f29 <cpunum>
f0103885:	6b c0 74             	imul   $0x74,%eax,%eax
f0103888:	8b b0 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f010388e:	89 35 60 9a 22 f0    	mov    %esi,0xf0229a60
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103894:	8b 46 28             	mov    0x28(%esi),%eax
f0103897:	83 f8 0e             	cmp    $0xe,%eax
f010389a:	74 20                	je     f01038bc <trap+0x143>
f010389c:	83 f8 30             	cmp    $0x30,%eax
f010389f:	74 25                	je     f01038c6 <trap+0x14d>
f01038a1:	83 f8 03             	cmp    $0x3,%eax
f01038a4:	75 52                	jne    f01038f8 <trap+0x17f>
		case T_BRKPT:
			monitor(tf);
f01038a6:	89 34 24             	mov    %esi,(%esp)
f01038a9:	e8 b7 d0 ff ff       	call   f0100965 <monitor>
			cprintf("return from breakpoint....\n");
f01038ae:	c7 04 24 b5 67 10 f0 	movl   $0xf01067b5,(%esp)
f01038b5:	e8 d6 fa ff ff       	call   f0103390 <cprintf>
f01038ba:	eb 3c                	jmp    f01038f8 <trap+0x17f>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f01038bc:	89 34 24             	mov    %esi,(%esp)
f01038bf:	e8 2e fe ff ff       	call   f01036f2 <page_fault_handler>
f01038c4:	eb 32                	jmp    f01038f8 <trap+0x17f>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f01038c6:	8b 46 04             	mov    0x4(%esi),%eax
f01038c9:	89 44 24 14          	mov    %eax,0x14(%esp)
f01038cd:	8b 06                	mov    (%esi),%eax
f01038cf:	89 44 24 10          	mov    %eax,0x10(%esp)
f01038d3:	8b 46 10             	mov    0x10(%esi),%eax
f01038d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038da:	8b 46 18             	mov    0x18(%esi),%eax
f01038dd:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038e1:	8b 46 14             	mov    0x14(%esi),%eax
f01038e4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038e8:	8b 46 1c             	mov    0x1c(%esi),%eax
f01038eb:	89 04 24             	mov    %eax,(%esp)
f01038ee:	e8 5d 02 00 00       	call   f0103b50 <syscall>
f01038f3:	89 46 1c             	mov    %eax,0x1c(%esi)
f01038f6:	eb 5d                	jmp    f0103955 <trap+0x1dc>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f01038f8:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f01038fc:	75 16                	jne    f0103914 <trap+0x19b>
		cprintf("Spurious interrupt on irq 7\n");
f01038fe:	c7 04 24 d1 67 10 f0 	movl   $0xf01067d1,(%esp)
f0103905:	e8 86 fa ff ff       	call   f0103390 <cprintf>
		print_trapframe(tf);
f010390a:	89 34 24             	mov    %esi,(%esp)
f010390d:	e8 43 fc ff ff       	call   f0103555 <print_trapframe>
f0103912:	eb 41                	jmp    f0103955 <trap+0x1dc>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103914:	89 34 24             	mov    %esi,(%esp)
f0103917:	e8 39 fc ff ff       	call   f0103555 <print_trapframe>
	if (tf->tf_cs == GD_KT){
f010391c:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103921:	75 1c                	jne    f010393f <trap+0x1c6>
		panic("unhandled trap in kernel");
f0103923:	c7 44 24 08 ee 67 10 	movl   $0xf01067ee,0x8(%esp)
f010392a:	f0 
f010392b:	c7 44 24 04 e2 00 00 	movl   $0xe2,0x4(%esp)
f0103932:	00 
f0103933:	c7 04 24 89 67 10 f0 	movl   $0xf0106789,(%esp)
f010393a:	e8 01 c7 ff ff       	call   f0100040 <_panic>
	}
	else {
		env_destroy(curenv);
f010393f:	e8 e5 15 00 00       	call   f0104f29 <cpunum>
f0103944:	6b c0 74             	imul   $0x74,%eax,%eax
f0103947:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f010394d:	89 04 24             	mov    %eax,(%esp)
f0103950:	e8 6e f7 ff ff       	call   f01030c3 <env_destroy>
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103955:	e8 cf 15 00 00       	call   f0104f29 <cpunum>
f010395a:	6b c0 74             	imul   $0x74,%eax,%eax
f010395d:	83 b8 28 a0 22 f0 00 	cmpl   $0x0,-0xfdd5fd8(%eax)
f0103964:	74 2a                	je     f0103990 <trap+0x217>
f0103966:	e8 be 15 00 00       	call   f0104f29 <cpunum>
f010396b:	6b c0 74             	imul   $0x74,%eax,%eax
f010396e:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103974:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103978:	75 16                	jne    f0103990 <trap+0x217>
		env_run(curenv);
f010397a:	e8 aa 15 00 00       	call   f0104f29 <cpunum>
f010397f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103982:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103988:	89 04 24             	mov    %eax,(%esp)
f010398b:	e8 d4 f7 ff ff       	call   f0103164 <env_run>
	else
		sched_yield();
f0103990:	e8 ab 01 00 00       	call   f0103b40 <sched_yield>
f0103995:	90                   	nop

f0103996 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103996:	6a 00                	push   $0x0
f0103998:	6a 00                	push   $0x0
f010399a:	e9 ba 00 00 00       	jmp    f0103a59 <_alltraps>
f010399f:	90                   	nop

f01039a0 <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f01039a0:	6a 00                	push   $0x0
f01039a2:	6a 01                	push   $0x1
f01039a4:	e9 b0 00 00 00       	jmp    f0103a59 <_alltraps>
f01039a9:	90                   	nop

f01039aa <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f01039aa:	6a 00                	push   $0x0
f01039ac:	6a 02                	push   $0x2
f01039ae:	e9 a6 00 00 00       	jmp    f0103a59 <_alltraps>
f01039b3:	90                   	nop

f01039b4 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f01039b4:	6a 00                	push   $0x0
f01039b6:	6a 03                	push   $0x3
f01039b8:	e9 9c 00 00 00       	jmp    f0103a59 <_alltraps>
f01039bd:	90                   	nop

f01039be <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f01039be:	6a 00                	push   $0x0
f01039c0:	6a 04                	push   $0x4
f01039c2:	e9 92 00 00 00       	jmp    f0103a59 <_alltraps>
f01039c7:	90                   	nop

f01039c8 <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f01039c8:	6a 00                	push   $0x0
f01039ca:	6a 05                	push   $0x5
f01039cc:	e9 88 00 00 00       	jmp    f0103a59 <_alltraps>
f01039d1:	90                   	nop

f01039d2 <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f01039d2:	6a 00                	push   $0x0
f01039d4:	6a 06                	push   $0x6
f01039d6:	e9 7e 00 00 00       	jmp    f0103a59 <_alltraps>
f01039db:	90                   	nop

f01039dc <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f01039dc:	6a 00                	push   $0x0
f01039de:	6a 07                	push   $0x7
f01039e0:	e9 74 00 00 00       	jmp    f0103a59 <_alltraps>
f01039e5:	90                   	nop

f01039e6 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f01039e6:	6a 08                	push   $0x8
f01039e8:	e9 6c 00 00 00       	jmp    f0103a59 <_alltraps>
f01039ed:	90                   	nop

f01039ee <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f01039ee:	6a 00                	push   $0x0
f01039f0:	6a 09                	push   $0x9
f01039f2:	e9 62 00 00 00       	jmp    f0103a59 <_alltraps>
f01039f7:	90                   	nop

f01039f8 <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f01039f8:	6a 0a                	push   $0xa
f01039fa:	e9 5a 00 00 00       	jmp    f0103a59 <_alltraps>
f01039ff:	90                   	nop

f0103a00 <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103a00:	6a 0b                	push   $0xb
f0103a02:	e9 52 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a07:	90                   	nop

f0103a08 <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103a08:	6a 0c                	push   $0xc
f0103a0a:	e9 4a 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a0f:	90                   	nop

f0103a10 <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103a10:	6a 0d                	push   $0xd
f0103a12:	e9 42 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a17:	90                   	nop

f0103a18 <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103a18:	6a 0e                	push   $0xe
f0103a1a:	e9 3a 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a1f:	90                   	nop

f0103a20 <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103a20:	6a 00                	push   $0x0
f0103a22:	6a 0f                	push   $0xf
f0103a24:	e9 30 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a29:	90                   	nop

f0103a2a <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103a2a:	6a 00                	push   $0x0
f0103a2c:	6a 10                	push   $0x10
f0103a2e:	e9 26 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a33:	90                   	nop

f0103a34 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103a34:	6a 11                	push   $0x11
f0103a36:	e9 1e 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a3b:	90                   	nop

f0103a3c <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103a3c:	6a 00                	push   $0x0
f0103a3e:	6a 12                	push   $0x12
f0103a40:	e9 14 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a45:	90                   	nop

f0103a46 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103a46:	6a 00                	push   $0x0
f0103a48:	6a 13                	push   $0x13
f0103a4a:	e9 0a 00 00 00       	jmp    f0103a59 <_alltraps>
f0103a4f:	90                   	nop

f0103a50 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f0103a50:	6a 00                	push   $0x0
f0103a52:	6a 30                	push   $0x30
f0103a54:	e9 00 00 00 00       	jmp    f0103a59 <_alltraps>

f0103a59 <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f0103a59:	1e                   	push   %ds
	push %es
f0103a5a:	06                   	push   %es
	pushal
f0103a5b:	60                   	pusha  

	
	movw $GD_KD, %ax
f0103a5c:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103a60:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0103a62:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f0103a64:	54                   	push   %esp
	call trap
f0103a65:	e8 0f fd ff ff       	call   f0103779 <trap>

f0103a6a <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103a6a:	55                   	push   %ebp
f0103a6b:	89 e5                	mov    %esp,%ebp
f0103a6d:	83 ec 18             	sub    $0x18,%esp
f0103a70:	8b 15 4c 92 22 f0    	mov    0xf022924c,%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103a76:	b8 00 00 00 00       	mov    $0x0,%eax
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0103a7b:	8b 4a 54             	mov    0x54(%edx),%ecx
f0103a7e:	83 e9 01             	sub    $0x1,%ecx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103a81:	83 f9 02             	cmp    $0x2,%ecx
f0103a84:	76 0f                	jbe    f0103a95 <sched_halt+0x2b>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103a86:	83 c0 01             	add    $0x1,%eax
f0103a89:	83 c2 7c             	add    $0x7c,%edx
f0103a8c:	3d 00 04 00 00       	cmp    $0x400,%eax
f0103a91:	75 e8                	jne    f0103a7b <sched_halt+0x11>
f0103a93:	eb 07                	jmp    f0103a9c <sched_halt+0x32>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103a95:	3d 00 04 00 00       	cmp    $0x400,%eax
f0103a9a:	75 1a                	jne    f0103ab6 <sched_halt+0x4c>
		cprintf("No runnable environments in the system!\n");
f0103a9c:	c7 04 24 f0 69 10 f0 	movl   $0xf01069f0,(%esp)
f0103aa3:	e8 e8 f8 ff ff       	call   f0103390 <cprintf>
		while (1)
			monitor(NULL);
f0103aa8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103aaf:	e8 b1 ce ff ff       	call   f0100965 <monitor>
f0103ab4:	eb f2                	jmp    f0103aa8 <sched_halt+0x3e>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103ab6:	e8 6e 14 00 00       	call   f0104f29 <cpunum>
f0103abb:	6b c0 74             	imul   $0x74,%eax,%eax
f0103abe:	c7 80 28 a0 22 f0 00 	movl   $0x0,-0xfdd5fd8(%eax)
f0103ac5:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0103ac8:	a1 0c 9f 22 f0       	mov    0xf0229f0c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103acd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103ad2:	77 20                	ja     f0103af4 <sched_halt+0x8a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103ad4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ad8:	c7 44 24 08 48 56 10 	movl   $0xf0105648,0x8(%esp)
f0103adf:	f0 
f0103ae0:	c7 44 24 04 3d 00 00 	movl   $0x3d,0x4(%esp)
f0103ae7:	00 
f0103ae8:	c7 04 24 19 6a 10 f0 	movl   $0xf0106a19,(%esp)
f0103aef:	e8 4c c5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103af4:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103af9:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0103afc:	e8 28 14 00 00       	call   f0104f29 <cpunum>
f0103b01:	6b d0 74             	imul   $0x74,%eax,%edx
f0103b04:	81 c2 20 a0 22 f0    	add    $0xf022a020,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103b0a:	b8 02 00 00 00       	mov    $0x2,%eax
f0103b0f:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103b13:	c7 04 24 60 e4 11 f0 	movl   $0xf011e460,(%esp)
f0103b1a:	e8 34 17 00 00       	call   f0105253 <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0103b1f:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0103b21:	e8 03 14 00 00       	call   f0104f29 <cpunum>
f0103b26:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0103b29:	8b 80 30 a0 22 f0    	mov    -0xfdd5fd0(%eax),%eax
f0103b2f:	bd 00 00 00 00       	mov    $0x0,%ebp
f0103b34:	89 c4                	mov    %eax,%esp
f0103b36:	6a 00                	push   $0x0
f0103b38:	6a 00                	push   $0x0
f0103b3a:	fb                   	sti    
f0103b3b:	f4                   	hlt    
f0103b3c:	eb fd                	jmp    f0103b3b <sched_halt+0xd1>
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0103b3e:	c9                   	leave  
f0103b3f:	c3                   	ret    

f0103b40 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f0103b40:	55                   	push   %ebp
f0103b41:	89 e5                	mov    %esp,%ebp
f0103b43:	83 ec 08             	sub    $0x8,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.

	// sched_halt never returns
	sched_halt();
f0103b46:	e8 1f ff ff ff       	call   f0103a6a <sched_halt>
}
f0103b4b:	c9                   	leave  
f0103b4c:	c3                   	ret    
f0103b4d:	66 90                	xchg   %ax,%ax
f0103b4f:	90                   	nop

f0103b50 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0103b50:	55                   	push   %ebp
f0103b51:	89 e5                	mov    %esp,%ebp
f0103b53:	53                   	push   %ebx
f0103b54:	83 ec 24             	sub    $0x24,%esp
f0103b57:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f0103b5a:	83 f8 01             	cmp    $0x1,%eax
f0103b5d:	74 66                	je     f0103bc5 <syscall+0x75>
f0103b5f:	83 f8 01             	cmp    $0x1,%eax
f0103b62:	72 11                	jb     f0103b75 <syscall+0x25>
f0103b64:	83 f8 02             	cmp    $0x2,%eax
f0103b67:	74 66                	je     f0103bcf <syscall+0x7f>
f0103b69:	83 f8 03             	cmp    $0x3,%eax
f0103b6c:	74 78                	je     f0103be6 <syscall+0x96>
f0103b6e:	66 90                	xchg   %ax,%ax
f0103b70:	e9 03 01 00 00       	jmp    f0103c78 <syscall+0x128>
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f0103b75:	e8 af 13 00 00       	call   f0104f29 <cpunum>
f0103b7a:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0103b81:	00 
f0103b82:	8b 4d 10             	mov    0x10(%ebp),%ecx
f0103b85:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f0103b89:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b8c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b90:	6b c0 74             	imul   $0x74,%eax,%eax
f0103b93:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103b99:	89 04 24             	mov    %eax,(%esp)
f0103b9c:	e8 ea ed ff ff       	call   f010298b <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0103ba1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ba4:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ba8:	8b 45 10             	mov    0x10(%ebp),%eax
f0103bab:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103baf:	c7 04 24 26 6a 10 f0 	movl   $0xf0106a26,(%esp)
f0103bb6:	e8 d5 f7 ff ff       	call   f0103390 <cprintf>

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f0103bbb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bc0:	e9 cf 00 00 00       	jmp    f0103c94 <syscall+0x144>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f0103bc5:	e8 4b ca ff ff       	call   f0100615 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f0103bca:	e9 c5 00 00 00       	jmp    f0103c94 <syscall+0x144>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f0103bcf:	90                   	nop
f0103bd0:	e8 54 13 00 00       	call   f0104f29 <cpunum>
f0103bd5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103bd8:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103bde:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f0103be1:	e9 ae 00 00 00       	jmp    f0103c94 <syscall+0x144>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103be6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0103bed:	00 
f0103bee:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103bf1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103bf5:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103bf8:	89 04 24             	mov    %eax,(%esp)
f0103bfb:	e8 7e ee ff ff       	call   f0102a7e <envid2env>
		return r;
f0103c00:	89 c2                	mov    %eax,%edx
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f0103c02:	85 c0                	test   %eax,%eax
f0103c04:	78 6e                	js     f0103c74 <syscall+0x124>
		return r;
	if (e == curenv)
f0103c06:	e8 1e 13 00 00       	call   f0104f29 <cpunum>
f0103c0b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0103c0e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c11:	39 90 28 a0 22 f0    	cmp    %edx,-0xfdd5fd8(%eax)
f0103c17:	75 23                	jne    f0103c3c <syscall+0xec>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0103c19:	e8 0b 13 00 00       	call   f0104f29 <cpunum>
f0103c1e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c21:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103c27:	8b 40 48             	mov    0x48(%eax),%eax
f0103c2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c2e:	c7 04 24 2b 6a 10 f0 	movl   $0xf0106a2b,(%esp)
f0103c35:	e8 56 f7 ff ff       	call   f0103390 <cprintf>
f0103c3a:	eb 28                	jmp    f0103c64 <syscall+0x114>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0103c3c:	8b 5a 48             	mov    0x48(%edx),%ebx
f0103c3f:	e8 e5 12 00 00       	call   f0104f29 <cpunum>
f0103c44:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103c48:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c4b:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103c51:	8b 40 48             	mov    0x48(%eax),%eax
f0103c54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c58:	c7 04 24 46 6a 10 f0 	movl   $0xf0106a46,(%esp)
f0103c5f:	e8 2c f7 ff ff       	call   f0103390 <cprintf>
	env_destroy(e);
f0103c64:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103c67:	89 04 24             	mov    %eax,(%esp)
f0103c6a:	e8 54 f4 ff ff       	call   f01030c3 <env_destroy>
	return 0;
f0103c6f:	ba 00 00 00 00       	mov    $0x0,%edx
		
	case SYS_getenvid:
		return sys_getenvid();
		
	case SYS_env_destroy:
		return sys_env_destroy(a1);
f0103c74:	89 d0                	mov    %edx,%eax
f0103c76:	eb 1c                	jmp    f0103c94 <syscall+0x144>
		
	default:
		panic("Invalid System Call \n");
f0103c78:	c7 44 24 08 5e 6a 10 	movl   $0xf0106a5e,0x8(%esp)
f0103c7f:	f0 
f0103c80:	c7 44 24 04 24 01 00 	movl   $0x124,0x4(%esp)
f0103c87:	00 
f0103c88:	c7 04 24 74 6a 10 f0 	movl   $0xf0106a74,(%esp)
f0103c8f:	e8 ac c3 ff ff       	call   f0100040 <_panic>
		return -E_INVAL;
	}
}
f0103c94:	83 c4 24             	add    $0x24,%esp
f0103c97:	5b                   	pop    %ebx
f0103c98:	5d                   	pop    %ebp
f0103c99:	c3                   	ret    

f0103c9a <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103c9a:	55                   	push   %ebp
f0103c9b:	89 e5                	mov    %esp,%ebp
f0103c9d:	57                   	push   %edi
f0103c9e:	56                   	push   %esi
f0103c9f:	53                   	push   %ebx
f0103ca0:	83 ec 14             	sub    $0x14,%esp
f0103ca3:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103ca6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103ca9:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0103cac:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103caf:	8b 1a                	mov    (%edx),%ebx
f0103cb1:	8b 01                	mov    (%ecx),%eax
f0103cb3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103cb6:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0103cbd:	e9 88 00 00 00       	jmp    f0103d4a <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f0103cc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103cc5:	01 d8                	add    %ebx,%eax
f0103cc7:	89 c7                	mov    %eax,%edi
f0103cc9:	c1 ef 1f             	shr    $0x1f,%edi
f0103ccc:	01 c7                	add    %eax,%edi
f0103cce:	d1 ff                	sar    %edi
f0103cd0:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0103cd3:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103cd6:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0103cd9:	89 f8                	mov    %edi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103cdb:	eb 03                	jmp    f0103ce0 <stab_binsearch+0x46>
			m--;
f0103cdd:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103ce0:	39 c3                	cmp    %eax,%ebx
f0103ce2:	7f 1f                	jg     f0103d03 <stab_binsearch+0x69>
f0103ce4:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103ce8:	83 ea 0c             	sub    $0xc,%edx
f0103ceb:	39 f1                	cmp    %esi,%ecx
f0103ced:	75 ee                	jne    f0103cdd <stab_binsearch+0x43>
f0103cef:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103cf2:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103cf5:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0103cf8:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0103cfc:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103cff:	76 18                	jbe    f0103d19 <stab_binsearch+0x7f>
f0103d01:	eb 05                	jmp    f0103d08 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103d03:	8d 5f 01             	lea    0x1(%edi),%ebx
			continue;
f0103d06:	eb 42                	jmp    f0103d4a <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103d08:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0103d0b:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0103d0d:	8d 5f 01             	lea    0x1(%edi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103d10:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103d17:	eb 31                	jmp    f0103d4a <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103d19:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0103d1c:	73 17                	jae    f0103d35 <stab_binsearch+0x9b>
			*region_right = m - 1;
f0103d1e:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0103d21:	83 e8 01             	sub    $0x1,%eax
f0103d24:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103d27:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103d2a:	89 07                	mov    %eax,(%edi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103d2c:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0103d33:	eb 15                	jmp    f0103d4a <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103d35:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d38:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f0103d3b:	89 1f                	mov    %ebx,(%edi)
			l = m;
			addr++;
f0103d3d:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0103d41:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103d43:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103d4a:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f0103d4d:	0f 8e 6f ff ff ff    	jle    f0103cc2 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103d53:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0103d57:	75 0f                	jne    f0103d68 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f0103d59:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103d5c:	8b 00                	mov    (%eax),%eax
f0103d5e:	83 e8 01             	sub    $0x1,%eax
f0103d61:	8b 7d e0             	mov    -0x20(%ebp),%edi
f0103d64:	89 07                	mov    %eax,(%edi)
f0103d66:	eb 2c                	jmp    f0103d94 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103d68:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103d6b:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103d6d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d70:	8b 0f                	mov    (%edi),%ecx
f0103d72:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103d75:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103d78:	8d 14 97             	lea    (%edi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103d7b:	eb 03                	jmp    f0103d80 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103d7d:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103d80:	39 c8                	cmp    %ecx,%eax
f0103d82:	7e 0b                	jle    f0103d8f <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0103d84:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0103d88:	83 ea 0c             	sub    $0xc,%edx
f0103d8b:	39 f3                	cmp    %esi,%ebx
f0103d8d:	75 ee                	jne    f0103d7d <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103d8f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0103d92:	89 07                	mov    %eax,(%edi)
	}
}
f0103d94:	83 c4 14             	add    $0x14,%esp
f0103d97:	5b                   	pop    %ebx
f0103d98:	5e                   	pop    %esi
f0103d99:	5f                   	pop    %edi
f0103d9a:	5d                   	pop    %ebp
f0103d9b:	c3                   	ret    

f0103d9c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103d9c:	55                   	push   %ebp
f0103d9d:	89 e5                	mov    %esp,%ebp
f0103d9f:	57                   	push   %edi
f0103da0:	56                   	push   %esi
f0103da1:	53                   	push   %ebx
f0103da2:	83 ec 4c             	sub    $0x4c,%esp
f0103da5:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103da8:	8b 7d 0c             	mov    0xc(%ebp),%edi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103dab:	c7 07 83 6a 10 f0    	movl   $0xf0106a83,(%edi)
	info->eip_line = 0;
f0103db1:	c7 47 04 00 00 00 00 	movl   $0x0,0x4(%edi)
	info->eip_fn_name = "<unknown>";
f0103db8:	c7 47 08 83 6a 10 f0 	movl   $0xf0106a83,0x8(%edi)
	info->eip_fn_namelen = 9;
f0103dbf:	c7 47 0c 09 00 00 00 	movl   $0x9,0xc(%edi)
	info->eip_fn_addr = addr;
f0103dc6:	89 5f 10             	mov    %ebx,0x10(%edi)
	info->eip_fn_narg = 0;
f0103dc9:	c7 47 14 00 00 00 00 	movl   $0x0,0x14(%edi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103dd0:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f0103dd6:	0f 87 cf 00 00 00    	ja     f0103eab <debuginfo_eip+0x10f>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f0103ddc:	e8 48 11 00 00       	call   f0104f29 <cpunum>
f0103de1:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0103de8:	00 
f0103de9:	c7 44 24 08 10 00 00 	movl   $0x10,0x8(%esp)
f0103df0:	00 
f0103df1:	c7 44 24 04 00 00 20 	movl   $0x200000,0x4(%esp)
f0103df8:	00 
f0103df9:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dfc:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103e02:	89 04 24             	mov    %eax,(%esp)
f0103e05:	e8 7c ea ff ff       	call   f0102886 <user_mem_check>
f0103e0a:	85 c0                	test   %eax,%eax
f0103e0c:	0f 88 5f 02 00 00    	js     f0104071 <debuginfo_eip+0x2d5>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f0103e12:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0103e17:	8b 35 04 00 20 00    	mov    0x200004,%esi
		stabstr = usd->stabstr;
f0103e1d:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0103e23:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0103e26:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f0103e2c:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f0103e2f:	89 f2                	mov    %esi,%edx
f0103e31:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0103e34:	29 c2                	sub    %eax,%edx
f0103e36:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0103e39:	e8 eb 10 00 00       	call   f0104f29 <cpunum>
f0103e3e:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0103e45:	00 
f0103e46:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103e49:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e4d:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103e50:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103e54:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e57:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103e5d:	89 04 24             	mov    %eax,(%esp)
f0103e60:	e8 21 ea ff ff       	call   f0102886 <user_mem_check>
f0103e65:	85 c0                	test   %eax,%eax
f0103e67:	0f 88 0b 02 00 00    	js     f0104078 <debuginfo_eip+0x2dc>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f0103e6d:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0103e70:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0103e73:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0103e76:	e8 ae 10 00 00       	call   f0104f29 <cpunum>
f0103e7b:	c7 44 24 0c 05 00 00 	movl   $0x5,0xc(%esp)
f0103e82:	00 
f0103e83:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0103e86:	89 54 24 08          	mov    %edx,0x8(%esp)
f0103e8a:	8b 4d c0             	mov    -0x40(%ebp),%ecx
f0103e8d:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103e91:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e94:	8b 80 28 a0 22 f0    	mov    -0xfdd5fd8(%eax),%eax
f0103e9a:	89 04 24             	mov    %eax,(%esp)
f0103e9d:	e8 e4 e9 ff ff       	call   f0102886 <user_mem_check>
f0103ea2:	85 c0                	test   %eax,%eax
f0103ea4:	79 1f                	jns    f0103ec5 <debuginfo_eip+0x129>
f0103ea6:	e9 d4 01 00 00       	jmp    f010407f <debuginfo_eip+0x2e3>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0103eab:	c7 45 bc 5e 38 11 f0 	movl   $0xf011385e,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0103eb2:	c7 45 c0 79 02 11 f0 	movl   $0xf0110279,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0103eb9:	be 78 02 11 f0       	mov    $0xf0110278,%esi
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0103ebe:	c7 45 c4 78 6f 10 f0 	movl   $0xf0106f78,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103ec5:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0103ec8:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0103ecb:	0f 83 b5 01 00 00    	jae    f0104086 <debuginfo_eip+0x2ea>
f0103ed1:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0103ed5:	0f 85 b2 01 00 00    	jne    f010408d <debuginfo_eip+0x2f1>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103edb:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103ee2:	2b 75 c4             	sub    -0x3c(%ebp),%esi
f0103ee5:	c1 fe 02             	sar    $0x2,%esi
f0103ee8:	69 c6 ab aa aa aa    	imul   $0xaaaaaaab,%esi,%eax
f0103eee:	83 e8 01             	sub    $0x1,%eax
f0103ef1:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103ef4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103ef8:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103eff:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103f02:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103f05:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103f08:	89 f0                	mov    %esi,%eax
f0103f0a:	e8 8b fd ff ff       	call   f0103c9a <stab_binsearch>
	if (lfile == 0)
f0103f0f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103f12:	85 c0                	test   %eax,%eax
f0103f14:	0f 84 7a 01 00 00    	je     f0104094 <debuginfo_eip+0x2f8>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103f1a:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0103f1d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f20:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103f23:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103f27:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103f2e:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103f31:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103f34:	89 f0                	mov    %esi,%eax
f0103f36:	e8 5f fd ff ff       	call   f0103c9a <stab_binsearch>

	if (lfun <= rfun) {
f0103f3b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103f3e:	8b 75 d8             	mov    -0x28(%ebp),%esi
f0103f41:	39 f0                	cmp    %esi,%eax
f0103f43:	7f 32                	jg     f0103f77 <debuginfo_eip+0x1db>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103f45:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103f48:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0103f4b:	8d 14 91             	lea    (%ecx,%edx,4),%edx
f0103f4e:	8b 0a                	mov    (%edx),%ecx
f0103f50:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f0103f53:	8b 4d bc             	mov    -0x44(%ebp),%ecx
f0103f56:	2b 4d c0             	sub    -0x40(%ebp),%ecx
f0103f59:	39 4d b8             	cmp    %ecx,-0x48(%ebp)
f0103f5c:	73 09                	jae    f0103f67 <debuginfo_eip+0x1cb>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103f5e:	8b 4d b8             	mov    -0x48(%ebp),%ecx
f0103f61:	03 4d c0             	add    -0x40(%ebp),%ecx
f0103f64:	89 4f 08             	mov    %ecx,0x8(%edi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103f67:	8b 52 08             	mov    0x8(%edx),%edx
f0103f6a:	89 57 10             	mov    %edx,0x10(%edi)
		addr -= info->eip_fn_addr;
f0103f6d:	29 d3                	sub    %edx,%ebx
		// Search within the function definition for the line number.
		lline = lfun;
f0103f6f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103f72:	89 75 d0             	mov    %esi,-0x30(%ebp)
f0103f75:	eb 0f                	jmp    f0103f86 <debuginfo_eip+0x1ea>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103f77:	89 5f 10             	mov    %ebx,0x10(%edi)
		lline = lfile;
f0103f7a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103f7d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103f80:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103f83:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0103f86:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103f8d:	00 
f0103f8e:	8b 47 08             	mov    0x8(%edi),%eax
f0103f91:	89 04 24             	mov    %eax,(%esp)
f0103f94:	e8 22 09 00 00       	call   f01048bb <strfind>
f0103f99:	2b 47 08             	sub    0x8(%edi),%eax
f0103f9c:	89 47 0c             	mov    %eax,0xc(%edi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0103f9f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103fa3:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103faa:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103fad:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103fb0:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0103fb3:	89 f0                	mov    %esi,%eax
f0103fb5:	e8 e0 fc ff ff       	call   f0103c9a <stab_binsearch>
	if (lline > rline) {
f0103fba:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103fbd:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103fc0:	0f 8f d5 00 00 00    	jg     f010409b <debuginfo_eip+0x2ff>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0103fc6:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0103fc9:	0f b7 44 86 06       	movzwl 0x6(%esi,%eax,4),%eax
f0103fce:	89 47 04             	mov    %eax,0x4(%edi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103fd1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103fd4:	89 c3                	mov    %eax,%ebx
f0103fd6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103fd9:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0103fdc:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0103fdf:	89 7d 0c             	mov    %edi,0xc(%ebp)
f0103fe2:	89 df                	mov    %ebx,%edi
f0103fe4:	eb 06                	jmp    f0103fec <debuginfo_eip+0x250>
f0103fe6:	83 e8 01             	sub    $0x1,%eax
f0103fe9:	83 ea 0c             	sub    $0xc,%edx
f0103fec:	89 c6                	mov    %eax,%esi
f0103fee:	39 c7                	cmp    %eax,%edi
f0103ff0:	7f 3c                	jg     f010402e <debuginfo_eip+0x292>
	       && stabs[lline].n_type != N_SOL
f0103ff2:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0103ff6:	80 f9 84             	cmp    $0x84,%cl
f0103ff9:	75 08                	jne    f0104003 <debuginfo_eip+0x267>
f0103ffb:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0103ffe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104001:	eb 11                	jmp    f0104014 <debuginfo_eip+0x278>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104003:	80 f9 64             	cmp    $0x64,%cl
f0104006:	75 de                	jne    f0103fe6 <debuginfo_eip+0x24a>
f0104008:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010400c:	74 d8                	je     f0103fe6 <debuginfo_eip+0x24a>
f010400e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104011:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104014:	8d 04 76             	lea    (%esi,%esi,2),%eax
f0104017:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f010401a:	8b 04 83             	mov    (%ebx,%eax,4),%eax
f010401d:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104020:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104023:	39 d0                	cmp    %edx,%eax
f0104025:	73 0a                	jae    f0104031 <debuginfo_eip+0x295>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104027:	03 45 c0             	add    -0x40(%ebp),%eax
f010402a:	89 07                	mov    %eax,(%edi)
f010402c:	eb 03                	jmp    f0104031 <debuginfo_eip+0x295>
f010402e:	8b 7d 0c             	mov    0xc(%ebp),%edi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104031:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104034:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104037:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010403c:	39 da                	cmp    %ebx,%edx
f010403e:	7d 67                	jge    f01040a7 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
f0104040:	83 c2 01             	add    $0x1,%edx
f0104043:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104046:	89 d0                	mov    %edx,%eax
f0104048:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010404b:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f010404e:	8d 14 96             	lea    (%esi,%edx,4),%edx
f0104051:	eb 04                	jmp    f0104057 <debuginfo_eip+0x2bb>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104053:	83 47 14 01          	addl   $0x1,0x14(%edi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104057:	39 c3                	cmp    %eax,%ebx
f0104059:	7e 47                	jle    f01040a2 <debuginfo_eip+0x306>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010405b:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010405f:	83 c0 01             	add    $0x1,%eax
f0104062:	83 c2 0c             	add    $0xc,%edx
f0104065:	80 f9 a0             	cmp    $0xa0,%cl
f0104068:	74 e9                	je     f0104053 <debuginfo_eip+0x2b7>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010406a:	b8 00 00 00 00       	mov    $0x0,%eax
f010406f:	eb 36                	jmp    f01040a7 <debuginfo_eip+0x30b>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104071:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104076:	eb 2f                	jmp    f01040a7 <debuginfo_eip+0x30b>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104078:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010407d:	eb 28                	jmp    f01040a7 <debuginfo_eip+0x30b>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f010407f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104084:	eb 21                	jmp    f01040a7 <debuginfo_eip+0x30b>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104086:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010408b:	eb 1a                	jmp    f01040a7 <debuginfo_eip+0x30b>
f010408d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104092:	eb 13                	jmp    f01040a7 <debuginfo_eip+0x30b>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104094:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104099:	eb 0c                	jmp    f01040a7 <debuginfo_eip+0x30b>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f010409b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01040a0:	eb 05                	jmp    f01040a7 <debuginfo_eip+0x30b>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01040a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01040a7:	83 c4 4c             	add    $0x4c,%esp
f01040aa:	5b                   	pop    %ebx
f01040ab:	5e                   	pop    %esi
f01040ac:	5f                   	pop    %edi
f01040ad:	5d                   	pop    %ebp
f01040ae:	c3                   	ret    
f01040af:	90                   	nop

f01040b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01040b0:	55                   	push   %ebp
f01040b1:	89 e5                	mov    %esp,%ebp
f01040b3:	57                   	push   %edi
f01040b4:	56                   	push   %esi
f01040b5:	53                   	push   %ebx
f01040b6:	83 ec 3c             	sub    $0x3c,%esp
f01040b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01040bc:	89 d7                	mov    %edx,%edi
f01040be:	8b 45 08             	mov    0x8(%ebp),%eax
f01040c1:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01040c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040c7:	89 c3                	mov    %eax,%ebx
f01040c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01040cc:	8b 45 10             	mov    0x10(%ebp),%eax
f01040cf:	8b 75 14             	mov    0x14(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01040d2:	b9 00 00 00 00       	mov    $0x0,%ecx
f01040d7:	89 45 d8             	mov    %eax,-0x28(%ebp)
f01040da:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f01040dd:	39 d9                	cmp    %ebx,%ecx
f01040df:	72 05                	jb     f01040e6 <printnum+0x36>
f01040e1:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01040e4:	77 69                	ja     f010414f <printnum+0x9f>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01040e6:	8b 4d 18             	mov    0x18(%ebp),%ecx
f01040e9:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01040ed:	83 ee 01             	sub    $0x1,%esi
f01040f0:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01040f4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040f8:	8b 44 24 08          	mov    0x8(%esp),%eax
f01040fc:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0104100:	89 c3                	mov    %eax,%ebx
f0104102:	89 d6                	mov    %edx,%esi
f0104104:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0104107:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f010410a:	89 54 24 08          	mov    %edx,0x8(%esp)
f010410e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0104112:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104115:	89 04 24             	mov    %eax,(%esp)
f0104118:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010411b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010411f:	e8 4c 12 00 00       	call   f0105370 <__udivdi3>
f0104124:	89 d9                	mov    %ebx,%ecx
f0104126:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010412a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f010412e:	89 04 24             	mov    %eax,(%esp)
f0104131:	89 54 24 04          	mov    %edx,0x4(%esp)
f0104135:	89 fa                	mov    %edi,%edx
f0104137:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010413a:	e8 71 ff ff ff       	call   f01040b0 <printnum>
f010413f:	eb 1b                	jmp    f010415c <printnum+0xac>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104141:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104145:	8b 45 18             	mov    0x18(%ebp),%eax
f0104148:	89 04 24             	mov    %eax,(%esp)
f010414b:	ff d3                	call   *%ebx
f010414d:	eb 03                	jmp    f0104152 <printnum+0xa2>
f010414f:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104152:	83 ee 01             	sub    $0x1,%esi
f0104155:	85 f6                	test   %esi,%esi
f0104157:	7f e8                	jg     f0104141 <printnum+0x91>
f0104159:	89 5d e4             	mov    %ebx,-0x1c(%ebp)
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010415c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104160:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0104164:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104167:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010416a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010416e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104172:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104175:	89 04 24             	mov    %eax,(%esp)
f0104178:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010417b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010417f:	e8 1c 13 00 00       	call   f01054a0 <__umoddi3>
f0104184:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104188:	0f be 80 8d 6a 10 f0 	movsbl -0xfef9573(%eax),%eax
f010418f:	89 04 24             	mov    %eax,(%esp)
f0104192:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104195:	ff d0                	call   *%eax
}
f0104197:	83 c4 3c             	add    $0x3c,%esp
f010419a:	5b                   	pop    %ebx
f010419b:	5e                   	pop    %esi
f010419c:	5f                   	pop    %edi
f010419d:	5d                   	pop    %ebp
f010419e:	c3                   	ret    

f010419f <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010419f:	55                   	push   %ebp
f01041a0:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01041a2:	83 fa 01             	cmp    $0x1,%edx
f01041a5:	7e 0e                	jle    f01041b5 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01041a7:	8b 10                	mov    (%eax),%edx
f01041a9:	8d 4a 08             	lea    0x8(%edx),%ecx
f01041ac:	89 08                	mov    %ecx,(%eax)
f01041ae:	8b 02                	mov    (%edx),%eax
f01041b0:	8b 52 04             	mov    0x4(%edx),%edx
f01041b3:	eb 22                	jmp    f01041d7 <getuint+0x38>
	else if (lflag)
f01041b5:	85 d2                	test   %edx,%edx
f01041b7:	74 10                	je     f01041c9 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01041b9:	8b 10                	mov    (%eax),%edx
f01041bb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01041be:	89 08                	mov    %ecx,(%eax)
f01041c0:	8b 02                	mov    (%edx),%eax
f01041c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01041c7:	eb 0e                	jmp    f01041d7 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01041c9:	8b 10                	mov    (%eax),%edx
f01041cb:	8d 4a 04             	lea    0x4(%edx),%ecx
f01041ce:	89 08                	mov    %ecx,(%eax)
f01041d0:	8b 02                	mov    (%edx),%eax
f01041d2:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01041d7:	5d                   	pop    %ebp
f01041d8:	c3                   	ret    

f01041d9 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01041d9:	55                   	push   %ebp
f01041da:	89 e5                	mov    %esp,%ebp
f01041dc:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01041df:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01041e3:	8b 10                	mov    (%eax),%edx
f01041e5:	3b 50 04             	cmp    0x4(%eax),%edx
f01041e8:	73 0a                	jae    f01041f4 <sprintputch+0x1b>
		*b->buf++ = ch;
f01041ea:	8d 4a 01             	lea    0x1(%edx),%ecx
f01041ed:	89 08                	mov    %ecx,(%eax)
f01041ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01041f2:	88 02                	mov    %al,(%edx)
}
f01041f4:	5d                   	pop    %ebp
f01041f5:	c3                   	ret    

f01041f6 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01041f6:	55                   	push   %ebp
f01041f7:	89 e5                	mov    %esp,%ebp
f01041f9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01041fc:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01041ff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104203:	8b 45 10             	mov    0x10(%ebp),%eax
f0104206:	89 44 24 08          	mov    %eax,0x8(%esp)
f010420a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010420d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104211:	8b 45 08             	mov    0x8(%ebp),%eax
f0104214:	89 04 24             	mov    %eax,(%esp)
f0104217:	e8 02 00 00 00       	call   f010421e <vprintfmt>
	va_end(ap);
}
f010421c:	c9                   	leave  
f010421d:	c3                   	ret    

f010421e <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010421e:	55                   	push   %ebp
f010421f:	89 e5                	mov    %esp,%ebp
f0104221:	57                   	push   %edi
f0104222:	56                   	push   %esi
f0104223:	53                   	push   %ebx
f0104224:	83 ec 3c             	sub    $0x3c,%esp
f0104227:	8b 7d 0c             	mov    0xc(%ebp),%edi
f010422a:	8b 5d 10             	mov    0x10(%ebp),%ebx
f010422d:	eb 14                	jmp    f0104243 <vprintfmt+0x25>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010422f:	85 c0                	test   %eax,%eax
f0104231:	0f 84 b3 03 00 00    	je     f01045ea <vprintfmt+0x3cc>
				return;
			putch(ch, putdat);
f0104237:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010423b:	89 04 24             	mov    %eax,(%esp)
f010423e:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104241:	89 f3                	mov    %esi,%ebx
f0104243:	8d 73 01             	lea    0x1(%ebx),%esi
f0104246:	0f b6 03             	movzbl (%ebx),%eax
f0104249:	83 f8 25             	cmp    $0x25,%eax
f010424c:	75 e1                	jne    f010422f <vprintfmt+0x11>
f010424e:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0104252:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0104259:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
f0104260:	c7 45 dc ff ff ff ff 	movl   $0xffffffff,-0x24(%ebp)
f0104267:	ba 00 00 00 00       	mov    $0x0,%edx
f010426c:	eb 1d                	jmp    f010428b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010426e:	89 de                	mov    %ebx,%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104270:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0104274:	eb 15                	jmp    f010428b <vprintfmt+0x6d>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104276:	89 de                	mov    %ebx,%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104278:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f010427c:	eb 0d                	jmp    f010428b <vprintfmt+0x6d>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f010427e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104281:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0104284:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010428b:	8d 5e 01             	lea    0x1(%esi),%ebx
f010428e:	0f b6 0e             	movzbl (%esi),%ecx
f0104291:	0f b6 c1             	movzbl %cl,%eax
f0104294:	83 e9 23             	sub    $0x23,%ecx
f0104297:	80 f9 55             	cmp    $0x55,%cl
f010429a:	0f 87 2a 03 00 00    	ja     f01045ca <vprintfmt+0x3ac>
f01042a0:	0f b6 c9             	movzbl %cl,%ecx
f01042a3:	ff 24 8d 60 6b 10 f0 	jmp    *-0xfef94a0(,%ecx,4)
f01042aa:	89 de                	mov    %ebx,%esi
f01042ac:	b9 00 00 00 00       	mov    $0x0,%ecx
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01042b1:	8d 0c 89             	lea    (%ecx,%ecx,4),%ecx
f01042b4:	8d 4c 48 d0          	lea    -0x30(%eax,%ecx,2),%ecx
				ch = *fmt;
f01042b8:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01042bb:	8d 58 d0             	lea    -0x30(%eax),%ebx
f01042be:	83 fb 09             	cmp    $0x9,%ebx
f01042c1:	77 36                	ja     f01042f9 <vprintfmt+0xdb>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01042c3:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f01042c6:	eb e9                	jmp    f01042b1 <vprintfmt+0x93>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01042c8:	8b 45 14             	mov    0x14(%ebp),%eax
f01042cb:	8d 48 04             	lea    0x4(%eax),%ecx
f01042ce:	89 4d 14             	mov    %ecx,0x14(%ebp)
f01042d1:	8b 00                	mov    (%eax),%eax
f01042d3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042d6:	89 de                	mov    %ebx,%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01042d8:	eb 22                	jmp    f01042fc <vprintfmt+0xde>
f01042da:	8b 4d dc             	mov    -0x24(%ebp),%ecx
f01042dd:	85 c9                	test   %ecx,%ecx
f01042df:	b8 00 00 00 00       	mov    $0x0,%eax
f01042e4:	0f 49 c1             	cmovns %ecx,%eax
f01042e7:	89 45 dc             	mov    %eax,-0x24(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01042ea:	89 de                	mov    %ebx,%esi
f01042ec:	eb 9d                	jmp    f010428b <vprintfmt+0x6d>
f01042ee:	89 de                	mov    %ebx,%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01042f0:	c7 45 e0 01 00 00 00 	movl   $0x1,-0x20(%ebp)
			goto reswitch;
f01042f7:	eb 92                	jmp    f010428b <vprintfmt+0x6d>
f01042f9:	89 4d d4             	mov    %ecx,-0x2c(%ebp)

		process_precision:
			if (width < 0)
f01042fc:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104300:	79 89                	jns    f010428b <vprintfmt+0x6d>
f0104302:	e9 77 ff ff ff       	jmp    f010427e <vprintfmt+0x60>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104307:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010430a:	89 de                	mov    %ebx,%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f010430c:	e9 7a ff ff ff       	jmp    f010428b <vprintfmt+0x6d>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104311:	8b 45 14             	mov    0x14(%ebp),%eax
f0104314:	8d 50 04             	lea    0x4(%eax),%edx
f0104317:	89 55 14             	mov    %edx,0x14(%ebp)
f010431a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010431e:	8b 00                	mov    (%eax),%eax
f0104320:	89 04 24             	mov    %eax,(%esp)
f0104323:	ff 55 08             	call   *0x8(%ebp)
			break;
f0104326:	e9 18 ff ff ff       	jmp    f0104243 <vprintfmt+0x25>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010432b:	8b 45 14             	mov    0x14(%ebp),%eax
f010432e:	8d 50 04             	lea    0x4(%eax),%edx
f0104331:	89 55 14             	mov    %edx,0x14(%ebp)
f0104334:	8b 00                	mov    (%eax),%eax
f0104336:	99                   	cltd   
f0104337:	31 d0                	xor    %edx,%eax
f0104339:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010433b:	83 f8 09             	cmp    $0x9,%eax
f010433e:	7f 0b                	jg     f010434b <vprintfmt+0x12d>
f0104340:	8b 14 85 c0 6c 10 f0 	mov    -0xfef9340(,%eax,4),%edx
f0104347:	85 d2                	test   %edx,%edx
f0104349:	75 20                	jne    f010436b <vprintfmt+0x14d>
				printfmt(putch, putdat, "error %d", err);
f010434b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010434f:	c7 44 24 08 a5 6a 10 	movl   $0xf0106aa5,0x8(%esp)
f0104356:	f0 
f0104357:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010435b:	8b 45 08             	mov    0x8(%ebp),%eax
f010435e:	89 04 24             	mov    %eax,(%esp)
f0104361:	e8 90 fe ff ff       	call   f01041f6 <printfmt>
f0104366:	e9 d8 fe ff ff       	jmp    f0104243 <vprintfmt+0x25>
			else
				printfmt(putch, putdat, "%s", p);
f010436b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010436f:	c7 44 24 08 68 62 10 	movl   $0xf0106268,0x8(%esp)
f0104376:	f0 
f0104377:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010437b:	8b 45 08             	mov    0x8(%ebp),%eax
f010437e:	89 04 24             	mov    %eax,(%esp)
f0104381:	e8 70 fe ff ff       	call   f01041f6 <printfmt>
f0104386:	e9 b8 fe ff ff       	jmp    f0104243 <vprintfmt+0x25>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010438b:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010438e:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104391:	89 45 d0             	mov    %eax,-0x30(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104394:	8b 45 14             	mov    0x14(%ebp),%eax
f0104397:	8d 50 04             	lea    0x4(%eax),%edx
f010439a:	89 55 14             	mov    %edx,0x14(%ebp)
f010439d:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f010439f:	85 f6                	test   %esi,%esi
f01043a1:	b8 9e 6a 10 f0       	mov    $0xf0106a9e,%eax
f01043a6:	0f 44 f0             	cmove  %eax,%esi
			if (width > 0 && padc != '-')
f01043a9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01043ad:	0f 84 97 00 00 00    	je     f010444a <vprintfmt+0x22c>
f01043b3:	83 7d d0 00          	cmpl   $0x0,-0x30(%ebp)
f01043b7:	0f 8e 9b 00 00 00    	jle    f0104458 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f01043bd:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01043c1:	89 34 24             	mov    %esi,(%esp)
f01043c4:	e8 9f 03 00 00       	call   f0104768 <strnlen>
f01043c9:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01043cc:	29 c2                	sub    %eax,%edx
f01043ce:	89 55 d0             	mov    %edx,-0x30(%ebp)
					putch(padc, putdat);
f01043d1:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01043d5:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01043d8:	89 75 d8             	mov    %esi,-0x28(%ebp)
f01043db:	8b 75 08             	mov    0x8(%ebp),%esi
f01043de:	89 5d 10             	mov    %ebx,0x10(%ebp)
f01043e1:	89 d3                	mov    %edx,%ebx
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01043e3:	eb 0f                	jmp    f01043f4 <vprintfmt+0x1d6>
					putch(padc, putdat);
f01043e5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01043e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01043ec:	89 04 24             	mov    %eax,(%esp)
f01043ef:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01043f1:	83 eb 01             	sub    $0x1,%ebx
f01043f4:	85 db                	test   %ebx,%ebx
f01043f6:	7f ed                	jg     f01043e5 <vprintfmt+0x1c7>
f01043f8:	8b 75 d8             	mov    -0x28(%ebp),%esi
f01043fb:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01043fe:	85 d2                	test   %edx,%edx
f0104400:	b8 00 00 00 00       	mov    $0x0,%eax
f0104405:	0f 49 c2             	cmovns %edx,%eax
f0104408:	29 c2                	sub    %eax,%edx
f010440a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010440d:	89 d7                	mov    %edx,%edi
f010440f:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104412:	eb 50                	jmp    f0104464 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104414:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104418:	74 1e                	je     f0104438 <vprintfmt+0x21a>
f010441a:	0f be d2             	movsbl %dl,%edx
f010441d:	83 ea 20             	sub    $0x20,%edx
f0104420:	83 fa 5e             	cmp    $0x5e,%edx
f0104423:	76 13                	jbe    f0104438 <vprintfmt+0x21a>
					putch('?', putdat);
f0104425:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104428:	89 44 24 04          	mov    %eax,0x4(%esp)
f010442c:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0104433:	ff 55 08             	call   *0x8(%ebp)
f0104436:	eb 0d                	jmp    f0104445 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104438:	8b 55 0c             	mov    0xc(%ebp),%edx
f010443b:	89 54 24 04          	mov    %edx,0x4(%esp)
f010443f:	89 04 24             	mov    %eax,(%esp)
f0104442:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104445:	83 ef 01             	sub    $0x1,%edi
f0104448:	eb 1a                	jmp    f0104464 <vprintfmt+0x246>
f010444a:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010444d:	8b 7d dc             	mov    -0x24(%ebp),%edi
f0104450:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104453:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104456:	eb 0c                	jmp    f0104464 <vprintfmt+0x246>
f0104458:	89 7d 0c             	mov    %edi,0xc(%ebp)
f010445b:	8b 7d dc             	mov    -0x24(%ebp),%edi
f010445e:	89 5d 10             	mov    %ebx,0x10(%ebp)
f0104461:	8b 5d d4             	mov    -0x2c(%ebp),%ebx
f0104464:	83 c6 01             	add    $0x1,%esi
f0104467:	0f b6 56 ff          	movzbl -0x1(%esi),%edx
f010446b:	0f be c2             	movsbl %dl,%eax
f010446e:	85 c0                	test   %eax,%eax
f0104470:	74 27                	je     f0104499 <vprintfmt+0x27b>
f0104472:	85 db                	test   %ebx,%ebx
f0104474:	78 9e                	js     f0104414 <vprintfmt+0x1f6>
f0104476:	83 eb 01             	sub    $0x1,%ebx
f0104479:	79 99                	jns    f0104414 <vprintfmt+0x1f6>
f010447b:	89 f8                	mov    %edi,%eax
f010447d:	8b 7d 0c             	mov    0xc(%ebp),%edi
f0104480:	8b 75 08             	mov    0x8(%ebp),%esi
f0104483:	89 c3                	mov    %eax,%ebx
f0104485:	eb 1a                	jmp    f01044a1 <vprintfmt+0x283>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104487:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010448b:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0104492:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104494:	83 eb 01             	sub    $0x1,%ebx
f0104497:	eb 08                	jmp    f01044a1 <vprintfmt+0x283>
f0104499:	89 fb                	mov    %edi,%ebx
f010449b:	8b 75 08             	mov    0x8(%ebp),%esi
f010449e:	8b 7d 0c             	mov    0xc(%ebp),%edi
f01044a1:	85 db                	test   %ebx,%ebx
f01044a3:	7f e2                	jg     f0104487 <vprintfmt+0x269>
f01044a5:	89 75 08             	mov    %esi,0x8(%ebp)
f01044a8:	8b 5d 10             	mov    0x10(%ebp),%ebx
f01044ab:	e9 93 fd ff ff       	jmp    f0104243 <vprintfmt+0x25>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01044b0:	83 fa 01             	cmp    $0x1,%edx
f01044b3:	7e 16                	jle    f01044cb <vprintfmt+0x2ad>
		return va_arg(*ap, long long);
f01044b5:	8b 45 14             	mov    0x14(%ebp),%eax
f01044b8:	8d 50 08             	lea    0x8(%eax),%edx
f01044bb:	89 55 14             	mov    %edx,0x14(%ebp)
f01044be:	8b 50 04             	mov    0x4(%eax),%edx
f01044c1:	8b 00                	mov    (%eax),%eax
f01044c3:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01044c6:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01044c9:	eb 32                	jmp    f01044fd <vprintfmt+0x2df>
	else if (lflag)
f01044cb:	85 d2                	test   %edx,%edx
f01044cd:	74 18                	je     f01044e7 <vprintfmt+0x2c9>
		return va_arg(*ap, long);
f01044cf:	8b 45 14             	mov    0x14(%ebp),%eax
f01044d2:	8d 50 04             	lea    0x4(%eax),%edx
f01044d5:	89 55 14             	mov    %edx,0x14(%ebp)
f01044d8:	8b 30                	mov    (%eax),%esi
f01044da:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01044dd:	89 f0                	mov    %esi,%eax
f01044df:	c1 f8 1f             	sar    $0x1f,%eax
f01044e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01044e5:	eb 16                	jmp    f01044fd <vprintfmt+0x2df>
	else
		return va_arg(*ap, int);
f01044e7:	8b 45 14             	mov    0x14(%ebp),%eax
f01044ea:	8d 50 04             	lea    0x4(%eax),%edx
f01044ed:	89 55 14             	mov    %edx,0x14(%ebp)
f01044f0:	8b 30                	mov    (%eax),%esi
f01044f2:	89 75 e0             	mov    %esi,-0x20(%ebp)
f01044f5:	89 f0                	mov    %esi,%eax
f01044f7:	c1 f8 1f             	sar    $0x1f,%eax
f01044fa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f01044fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104500:	8b 55 e4             	mov    -0x1c(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104503:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104508:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010450c:	0f 89 80 00 00 00    	jns    f0104592 <vprintfmt+0x374>
				putch('-', putdat);
f0104512:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104516:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f010451d:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0104520:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104523:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104526:	f7 d8                	neg    %eax
f0104528:	83 d2 00             	adc    $0x0,%edx
f010452b:	f7 da                	neg    %edx
			}
			base = 10;
f010452d:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104532:	eb 5e                	jmp    f0104592 <vprintfmt+0x374>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104534:	8d 45 14             	lea    0x14(%ebp),%eax
f0104537:	e8 63 fc ff ff       	call   f010419f <getuint>
			base = 10;
f010453c:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104541:	eb 4f                	jmp    f0104592 <vprintfmt+0x374>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104543:	8d 45 14             	lea    0x14(%ebp),%eax
f0104546:	e8 54 fc ff ff       	call   f010419f <getuint>
			base = 8;
f010454b:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104550:	eb 40                	jmp    f0104592 <vprintfmt+0x374>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0104552:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104556:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010455d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0104560:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0104564:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010456b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010456e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104571:	8d 50 04             	lea    0x4(%eax),%edx
f0104574:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104577:	8b 00                	mov    (%eax),%eax
f0104579:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010457e:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104583:	eb 0d                	jmp    f0104592 <vprintfmt+0x374>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104585:	8d 45 14             	lea    0x14(%ebp),%eax
f0104588:	e8 12 fc ff ff       	call   f010419f <getuint>
			base = 16;
f010458d:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104592:	0f be 75 d8          	movsbl -0x28(%ebp),%esi
f0104596:	89 74 24 10          	mov    %esi,0x10(%esp)
f010459a:	8b 75 dc             	mov    -0x24(%ebp),%esi
f010459d:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01045a1:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01045a5:	89 04 24             	mov    %eax,(%esp)
f01045a8:	89 54 24 04          	mov    %edx,0x4(%esp)
f01045ac:	89 fa                	mov    %edi,%edx
f01045ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01045b1:	e8 fa fa ff ff       	call   f01040b0 <printnum>
			break;
f01045b6:	e9 88 fc ff ff       	jmp    f0104243 <vprintfmt+0x25>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01045bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01045bf:	89 04 24             	mov    %eax,(%esp)
f01045c2:	ff 55 08             	call   *0x8(%ebp)
			break;
f01045c5:	e9 79 fc ff ff       	jmp    f0104243 <vprintfmt+0x25>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01045ca:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01045ce:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01045d5:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01045d8:	89 f3                	mov    %esi,%ebx
f01045da:	eb 03                	jmp    f01045df <vprintfmt+0x3c1>
f01045dc:	83 eb 01             	sub    $0x1,%ebx
f01045df:	80 7b ff 25          	cmpb   $0x25,-0x1(%ebx)
f01045e3:	75 f7                	jne    f01045dc <vprintfmt+0x3be>
f01045e5:	e9 59 fc ff ff       	jmp    f0104243 <vprintfmt+0x25>
				/* do nothing */;
			break;
		}
	}
}
f01045ea:	83 c4 3c             	add    $0x3c,%esp
f01045ed:	5b                   	pop    %ebx
f01045ee:	5e                   	pop    %esi
f01045ef:	5f                   	pop    %edi
f01045f0:	5d                   	pop    %ebp
f01045f1:	c3                   	ret    

f01045f2 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01045f2:	55                   	push   %ebp
f01045f3:	89 e5                	mov    %esp,%ebp
f01045f5:	83 ec 28             	sub    $0x28,%esp
f01045f8:	8b 45 08             	mov    0x8(%ebp),%eax
f01045fb:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01045fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104601:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104605:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104608:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f010460f:	85 c0                	test   %eax,%eax
f0104611:	74 30                	je     f0104643 <vsnprintf+0x51>
f0104613:	85 d2                	test   %edx,%edx
f0104615:	7e 2c                	jle    f0104643 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104617:	8b 45 14             	mov    0x14(%ebp),%eax
f010461a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010461e:	8b 45 10             	mov    0x10(%ebp),%eax
f0104621:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104625:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104628:	89 44 24 04          	mov    %eax,0x4(%esp)
f010462c:	c7 04 24 d9 41 10 f0 	movl   $0xf01041d9,(%esp)
f0104633:	e8 e6 fb ff ff       	call   f010421e <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104638:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010463b:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010463e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104641:	eb 05                	jmp    f0104648 <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104643:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104648:	c9                   	leave  
f0104649:	c3                   	ret    

f010464a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010464a:	55                   	push   %ebp
f010464b:	89 e5                	mov    %esp,%ebp
f010464d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104650:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104653:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104657:	8b 45 10             	mov    0x10(%ebp),%eax
f010465a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010465e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104661:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104665:	8b 45 08             	mov    0x8(%ebp),%eax
f0104668:	89 04 24             	mov    %eax,(%esp)
f010466b:	e8 82 ff ff ff       	call   f01045f2 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104670:	c9                   	leave  
f0104671:	c3                   	ret    
f0104672:	66 90                	xchg   %ax,%ax
f0104674:	66 90                	xchg   %ax,%ax
f0104676:	66 90                	xchg   %ax,%ax
f0104678:	66 90                	xchg   %ax,%ax
f010467a:	66 90                	xchg   %ax,%ax
f010467c:	66 90                	xchg   %ax,%ax
f010467e:	66 90                	xchg   %ax,%ax

f0104680 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104680:	55                   	push   %ebp
f0104681:	89 e5                	mov    %esp,%ebp
f0104683:	57                   	push   %edi
f0104684:	56                   	push   %esi
f0104685:	53                   	push   %ebx
f0104686:	83 ec 1c             	sub    $0x1c,%esp
f0104689:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010468c:	85 c0                	test   %eax,%eax
f010468e:	74 10                	je     f01046a0 <readline+0x20>
		cprintf("%s", prompt);
f0104690:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104694:	c7 04 24 68 62 10 f0 	movl   $0xf0106268,(%esp)
f010469b:	e8 f0 ec ff ff       	call   f0103390 <cprintf>

	i = 0;
	echoing = iscons(0);
f01046a0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01046a7:	e8 df c0 ff ff       	call   f010078b <iscons>
f01046ac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01046ae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01046b3:	e8 c2 c0 ff ff       	call   f010077a <getchar>
f01046b8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01046ba:	85 c0                	test   %eax,%eax
f01046bc:	79 17                	jns    f01046d5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01046be:	89 44 24 04          	mov    %eax,0x4(%esp)
f01046c2:	c7 04 24 e8 6c 10 f0 	movl   $0xf0106ce8,(%esp)
f01046c9:	e8 c2 ec ff ff       	call   f0103390 <cprintf>
			return NULL;
f01046ce:	b8 00 00 00 00       	mov    $0x0,%eax
f01046d3:	eb 6d                	jmp    f0104742 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01046d5:	83 f8 7f             	cmp    $0x7f,%eax
f01046d8:	74 05                	je     f01046df <readline+0x5f>
f01046da:	83 f8 08             	cmp    $0x8,%eax
f01046dd:	75 19                	jne    f01046f8 <readline+0x78>
f01046df:	85 f6                	test   %esi,%esi
f01046e1:	7e 15                	jle    f01046f8 <readline+0x78>
			if (echoing)
f01046e3:	85 ff                	test   %edi,%edi
f01046e5:	74 0c                	je     f01046f3 <readline+0x73>
				cputchar('\b');
f01046e7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01046ee:	e8 77 c0 ff ff       	call   f010076a <cputchar>
			i--;
f01046f3:	83 ee 01             	sub    $0x1,%esi
f01046f6:	eb bb                	jmp    f01046b3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01046f8:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01046fe:	7f 1c                	jg     f010471c <readline+0x9c>
f0104700:	83 fb 1f             	cmp    $0x1f,%ebx
f0104703:	7e 17                	jle    f010471c <readline+0x9c>
			if (echoing)
f0104705:	85 ff                	test   %edi,%edi
f0104707:	74 08                	je     f0104711 <readline+0x91>
				cputchar(c);
f0104709:	89 1c 24             	mov    %ebx,(%esp)
f010470c:	e8 59 c0 ff ff       	call   f010076a <cputchar>
			buf[i++] = c;
f0104711:	88 9e 00 9b 22 f0    	mov    %bl,-0xfdd6500(%esi)
f0104717:	8d 76 01             	lea    0x1(%esi),%esi
f010471a:	eb 97                	jmp    f01046b3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010471c:	83 fb 0d             	cmp    $0xd,%ebx
f010471f:	74 05                	je     f0104726 <readline+0xa6>
f0104721:	83 fb 0a             	cmp    $0xa,%ebx
f0104724:	75 8d                	jne    f01046b3 <readline+0x33>
			if (echoing)
f0104726:	85 ff                	test   %edi,%edi
f0104728:	74 0c                	je     f0104736 <readline+0xb6>
				cputchar('\n');
f010472a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0104731:	e8 34 c0 ff ff       	call   f010076a <cputchar>
			buf[i] = 0;
f0104736:	c6 86 00 9b 22 f0 00 	movb   $0x0,-0xfdd6500(%esi)
			return buf;
f010473d:	b8 00 9b 22 f0       	mov    $0xf0229b00,%eax
		}
	}
}
f0104742:	83 c4 1c             	add    $0x1c,%esp
f0104745:	5b                   	pop    %ebx
f0104746:	5e                   	pop    %esi
f0104747:	5f                   	pop    %edi
f0104748:	5d                   	pop    %ebp
f0104749:	c3                   	ret    
f010474a:	66 90                	xchg   %ax,%ax
f010474c:	66 90                	xchg   %ax,%ax
f010474e:	66 90                	xchg   %ax,%ax

f0104750 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104750:	55                   	push   %ebp
f0104751:	89 e5                	mov    %esp,%ebp
f0104753:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104756:	b8 00 00 00 00       	mov    $0x0,%eax
f010475b:	eb 03                	jmp    f0104760 <strlen+0x10>
		n++;
f010475d:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104760:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104764:	75 f7                	jne    f010475d <strlen+0xd>
		n++;
	return n;
}
f0104766:	5d                   	pop    %ebp
f0104767:	c3                   	ret    

f0104768 <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104768:	55                   	push   %ebp
f0104769:	89 e5                	mov    %esp,%ebp
f010476b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010476e:	8b 55 0c             	mov    0xc(%ebp),%edx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104771:	b8 00 00 00 00       	mov    $0x0,%eax
f0104776:	eb 03                	jmp    f010477b <strnlen+0x13>
		n++;
f0104778:	83 c0 01             	add    $0x1,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010477b:	39 d0                	cmp    %edx,%eax
f010477d:	74 06                	je     f0104785 <strnlen+0x1d>
f010477f:	80 3c 01 00          	cmpb   $0x0,(%ecx,%eax,1)
f0104783:	75 f3                	jne    f0104778 <strnlen+0x10>
		n++;
	return n;
}
f0104785:	5d                   	pop    %ebp
f0104786:	c3                   	ret    

f0104787 <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104787:	55                   	push   %ebp
f0104788:	89 e5                	mov    %esp,%ebp
f010478a:	53                   	push   %ebx
f010478b:	8b 45 08             	mov    0x8(%ebp),%eax
f010478e:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104791:	89 c2                	mov    %eax,%edx
f0104793:	83 c2 01             	add    $0x1,%edx
f0104796:	83 c1 01             	add    $0x1,%ecx
f0104799:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f010479d:	88 5a ff             	mov    %bl,-0x1(%edx)
f01047a0:	84 db                	test   %bl,%bl
f01047a2:	75 ef                	jne    f0104793 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01047a4:	5b                   	pop    %ebx
f01047a5:	5d                   	pop    %ebp
f01047a6:	c3                   	ret    

f01047a7 <strcat>:

char *
strcat(char *dst, const char *src)
{
f01047a7:	55                   	push   %ebp
f01047a8:	89 e5                	mov    %esp,%ebp
f01047aa:	53                   	push   %ebx
f01047ab:	83 ec 08             	sub    $0x8,%esp
f01047ae:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01047b1:	89 1c 24             	mov    %ebx,(%esp)
f01047b4:	e8 97 ff ff ff       	call   f0104750 <strlen>
	strcpy(dst + len, src);
f01047b9:	8b 55 0c             	mov    0xc(%ebp),%edx
f01047bc:	89 54 24 04          	mov    %edx,0x4(%esp)
f01047c0:	01 d8                	add    %ebx,%eax
f01047c2:	89 04 24             	mov    %eax,(%esp)
f01047c5:	e8 bd ff ff ff       	call   f0104787 <strcpy>
	return dst;
}
f01047ca:	89 d8                	mov    %ebx,%eax
f01047cc:	83 c4 08             	add    $0x8,%esp
f01047cf:	5b                   	pop    %ebx
f01047d0:	5d                   	pop    %ebp
f01047d1:	c3                   	ret    

f01047d2 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01047d2:	55                   	push   %ebp
f01047d3:	89 e5                	mov    %esp,%ebp
f01047d5:	56                   	push   %esi
f01047d6:	53                   	push   %ebx
f01047d7:	8b 75 08             	mov    0x8(%ebp),%esi
f01047da:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01047dd:	89 f3                	mov    %esi,%ebx
f01047df:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01047e2:	89 f2                	mov    %esi,%edx
f01047e4:	eb 0f                	jmp    f01047f5 <strncpy+0x23>
		*dst++ = *src;
f01047e6:	83 c2 01             	add    $0x1,%edx
f01047e9:	0f b6 01             	movzbl (%ecx),%eax
f01047ec:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01047ef:	80 39 01             	cmpb   $0x1,(%ecx)
f01047f2:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01047f5:	39 da                	cmp    %ebx,%edx
f01047f7:	75 ed                	jne    f01047e6 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01047f9:	89 f0                	mov    %esi,%eax
f01047fb:	5b                   	pop    %ebx
f01047fc:	5e                   	pop    %esi
f01047fd:	5d                   	pop    %ebp
f01047fe:	c3                   	ret    

f01047ff <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01047ff:	55                   	push   %ebp
f0104800:	89 e5                	mov    %esp,%ebp
f0104802:	56                   	push   %esi
f0104803:	53                   	push   %ebx
f0104804:	8b 75 08             	mov    0x8(%ebp),%esi
f0104807:	8b 55 0c             	mov    0xc(%ebp),%edx
f010480a:	8b 4d 10             	mov    0x10(%ebp),%ecx
f010480d:	89 f0                	mov    %esi,%eax
f010480f:	8d 5c 0e ff          	lea    -0x1(%esi,%ecx,1),%ebx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104813:	85 c9                	test   %ecx,%ecx
f0104815:	75 0b                	jne    f0104822 <strlcpy+0x23>
f0104817:	eb 1d                	jmp    f0104836 <strlcpy+0x37>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104819:	83 c0 01             	add    $0x1,%eax
f010481c:	83 c2 01             	add    $0x1,%edx
f010481f:	88 48 ff             	mov    %cl,-0x1(%eax)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104822:	39 d8                	cmp    %ebx,%eax
f0104824:	74 0b                	je     f0104831 <strlcpy+0x32>
f0104826:	0f b6 0a             	movzbl (%edx),%ecx
f0104829:	84 c9                	test   %cl,%cl
f010482b:	75 ec                	jne    f0104819 <strlcpy+0x1a>
f010482d:	89 c2                	mov    %eax,%edx
f010482f:	eb 02                	jmp    f0104833 <strlcpy+0x34>
f0104831:	89 c2                	mov    %eax,%edx
			*dst++ = *src++;
		*dst = '\0';
f0104833:	c6 02 00             	movb   $0x0,(%edx)
	}
	return dst - dst_in;
f0104836:	29 f0                	sub    %esi,%eax
}
f0104838:	5b                   	pop    %ebx
f0104839:	5e                   	pop    %esi
f010483a:	5d                   	pop    %ebp
f010483b:	c3                   	ret    

f010483c <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010483c:	55                   	push   %ebp
f010483d:	89 e5                	mov    %esp,%ebp
f010483f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104842:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104845:	eb 06                	jmp    f010484d <strcmp+0x11>
		p++, q++;
f0104847:	83 c1 01             	add    $0x1,%ecx
f010484a:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f010484d:	0f b6 01             	movzbl (%ecx),%eax
f0104850:	84 c0                	test   %al,%al
f0104852:	74 04                	je     f0104858 <strcmp+0x1c>
f0104854:	3a 02                	cmp    (%edx),%al
f0104856:	74 ef                	je     f0104847 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104858:	0f b6 c0             	movzbl %al,%eax
f010485b:	0f b6 12             	movzbl (%edx),%edx
f010485e:	29 d0                	sub    %edx,%eax
}
f0104860:	5d                   	pop    %ebp
f0104861:	c3                   	ret    

f0104862 <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0104862:	55                   	push   %ebp
f0104863:	89 e5                	mov    %esp,%ebp
f0104865:	53                   	push   %ebx
f0104866:	8b 45 08             	mov    0x8(%ebp),%eax
f0104869:	8b 55 0c             	mov    0xc(%ebp),%edx
f010486c:	89 c3                	mov    %eax,%ebx
f010486e:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f0104871:	eb 06                	jmp    f0104879 <strncmp+0x17>
		n--, p++, q++;
f0104873:	83 c0 01             	add    $0x1,%eax
f0104876:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0104879:	39 d8                	cmp    %ebx,%eax
f010487b:	74 15                	je     f0104892 <strncmp+0x30>
f010487d:	0f b6 08             	movzbl (%eax),%ecx
f0104880:	84 c9                	test   %cl,%cl
f0104882:	74 04                	je     f0104888 <strncmp+0x26>
f0104884:	3a 0a                	cmp    (%edx),%cl
f0104886:	74 eb                	je     f0104873 <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0104888:	0f b6 00             	movzbl (%eax),%eax
f010488b:	0f b6 12             	movzbl (%edx),%edx
f010488e:	29 d0                	sub    %edx,%eax
f0104890:	eb 05                	jmp    f0104897 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104892:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0104897:	5b                   	pop    %ebx
f0104898:	5d                   	pop    %ebp
f0104899:	c3                   	ret    

f010489a <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f010489a:	55                   	push   %ebp
f010489b:	89 e5                	mov    %esp,%ebp
f010489d:	8b 45 08             	mov    0x8(%ebp),%eax
f01048a0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01048a4:	eb 07                	jmp    f01048ad <strchr+0x13>
		if (*s == c)
f01048a6:	38 ca                	cmp    %cl,%dl
f01048a8:	74 0f                	je     f01048b9 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01048aa:	83 c0 01             	add    $0x1,%eax
f01048ad:	0f b6 10             	movzbl (%eax),%edx
f01048b0:	84 d2                	test   %dl,%dl
f01048b2:	75 f2                	jne    f01048a6 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f01048b4:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01048b9:	5d                   	pop    %ebp
f01048ba:	c3                   	ret    

f01048bb <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01048bb:	55                   	push   %ebp
f01048bc:	89 e5                	mov    %esp,%ebp
f01048be:	8b 45 08             	mov    0x8(%ebp),%eax
f01048c1:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01048c5:	eb 07                	jmp    f01048ce <strfind+0x13>
		if (*s == c)
f01048c7:	38 ca                	cmp    %cl,%dl
f01048c9:	74 0a                	je     f01048d5 <strfind+0x1a>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f01048cb:	83 c0 01             	add    $0x1,%eax
f01048ce:	0f b6 10             	movzbl (%eax),%edx
f01048d1:	84 d2                	test   %dl,%dl
f01048d3:	75 f2                	jne    f01048c7 <strfind+0xc>
		if (*s == c)
			break;
	return (char *) s;
}
f01048d5:	5d                   	pop    %ebp
f01048d6:	c3                   	ret    

f01048d7 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01048d7:	55                   	push   %ebp
f01048d8:	89 e5                	mov    %esp,%ebp
f01048da:	57                   	push   %edi
f01048db:	56                   	push   %esi
f01048dc:	53                   	push   %ebx
f01048dd:	8b 7d 08             	mov    0x8(%ebp),%edi
f01048e0:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01048e3:	85 c9                	test   %ecx,%ecx
f01048e5:	74 36                	je     f010491d <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01048e7:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01048ed:	75 28                	jne    f0104917 <memset+0x40>
f01048ef:	f6 c1 03             	test   $0x3,%cl
f01048f2:	75 23                	jne    f0104917 <memset+0x40>
		c &= 0xFF;
f01048f4:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01048f8:	89 d3                	mov    %edx,%ebx
f01048fa:	c1 e3 08             	shl    $0x8,%ebx
f01048fd:	89 d6                	mov    %edx,%esi
f01048ff:	c1 e6 18             	shl    $0x18,%esi
f0104902:	89 d0                	mov    %edx,%eax
f0104904:	c1 e0 10             	shl    $0x10,%eax
f0104907:	09 f0                	or     %esi,%eax
f0104909:	09 c2                	or     %eax,%edx
f010490b:	89 d0                	mov    %edx,%eax
f010490d:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010490f:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104912:	fc                   	cld    
f0104913:	f3 ab                	rep stos %eax,%es:(%edi)
f0104915:	eb 06                	jmp    f010491d <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0104917:	8b 45 0c             	mov    0xc(%ebp),%eax
f010491a:	fc                   	cld    
f010491b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010491d:	89 f8                	mov    %edi,%eax
f010491f:	5b                   	pop    %ebx
f0104920:	5e                   	pop    %esi
f0104921:	5f                   	pop    %edi
f0104922:	5d                   	pop    %ebp
f0104923:	c3                   	ret    

f0104924 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0104924:	55                   	push   %ebp
f0104925:	89 e5                	mov    %esp,%ebp
f0104927:	57                   	push   %edi
f0104928:	56                   	push   %esi
f0104929:	8b 45 08             	mov    0x8(%ebp),%eax
f010492c:	8b 75 0c             	mov    0xc(%ebp),%esi
f010492f:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104932:	39 c6                	cmp    %eax,%esi
f0104934:	73 35                	jae    f010496b <memmove+0x47>
f0104936:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104939:	39 d0                	cmp    %edx,%eax
f010493b:	73 2e                	jae    f010496b <memmove+0x47>
		s += n;
		d += n;
f010493d:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f0104940:	89 d6                	mov    %edx,%esi
f0104942:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0104944:	f7 c6 03 00 00 00    	test   $0x3,%esi
f010494a:	75 13                	jne    f010495f <memmove+0x3b>
f010494c:	f6 c1 03             	test   $0x3,%cl
f010494f:	75 0e                	jne    f010495f <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104951:	83 ef 04             	sub    $0x4,%edi
f0104954:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104957:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010495a:	fd                   	std    
f010495b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010495d:	eb 09                	jmp    f0104968 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010495f:	83 ef 01             	sub    $0x1,%edi
f0104962:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104965:	fd                   	std    
f0104966:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104968:	fc                   	cld    
f0104969:	eb 1d                	jmp    f0104988 <memmove+0x64>
f010496b:	89 f2                	mov    %esi,%edx
f010496d:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010496f:	f6 c2 03             	test   $0x3,%dl
f0104972:	75 0f                	jne    f0104983 <memmove+0x5f>
f0104974:	f6 c1 03             	test   $0x3,%cl
f0104977:	75 0a                	jne    f0104983 <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0104979:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010497c:	89 c7                	mov    %eax,%edi
f010497e:	fc                   	cld    
f010497f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104981:	eb 05                	jmp    f0104988 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104983:	89 c7                	mov    %eax,%edi
f0104985:	fc                   	cld    
f0104986:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0104988:	5e                   	pop    %esi
f0104989:	5f                   	pop    %edi
f010498a:	5d                   	pop    %ebp
f010498b:	c3                   	ret    

f010498c <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f010498c:	55                   	push   %ebp
f010498d:	89 e5                	mov    %esp,%ebp
f010498f:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0104992:	8b 45 10             	mov    0x10(%ebp),%eax
f0104995:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104999:	8b 45 0c             	mov    0xc(%ebp),%eax
f010499c:	89 44 24 04          	mov    %eax,0x4(%esp)
f01049a0:	8b 45 08             	mov    0x8(%ebp),%eax
f01049a3:	89 04 24             	mov    %eax,(%esp)
f01049a6:	e8 79 ff ff ff       	call   f0104924 <memmove>
}
f01049ab:	c9                   	leave  
f01049ac:	c3                   	ret    

f01049ad <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01049ad:	55                   	push   %ebp
f01049ae:	89 e5                	mov    %esp,%ebp
f01049b0:	56                   	push   %esi
f01049b1:	53                   	push   %ebx
f01049b2:	8b 55 08             	mov    0x8(%ebp),%edx
f01049b5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f01049b8:	89 d6                	mov    %edx,%esi
f01049ba:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01049bd:	eb 1a                	jmp    f01049d9 <memcmp+0x2c>
		if (*s1 != *s2)
f01049bf:	0f b6 02             	movzbl (%edx),%eax
f01049c2:	0f b6 19             	movzbl (%ecx),%ebx
f01049c5:	38 d8                	cmp    %bl,%al
f01049c7:	74 0a                	je     f01049d3 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f01049c9:	0f b6 c0             	movzbl %al,%eax
f01049cc:	0f b6 db             	movzbl %bl,%ebx
f01049cf:	29 d8                	sub    %ebx,%eax
f01049d1:	eb 0f                	jmp    f01049e2 <memcmp+0x35>
		s1++, s2++;
f01049d3:	83 c2 01             	add    $0x1,%edx
f01049d6:	83 c1 01             	add    $0x1,%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01049d9:	39 f2                	cmp    %esi,%edx
f01049db:	75 e2                	jne    f01049bf <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01049dd:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01049e2:	5b                   	pop    %ebx
f01049e3:	5e                   	pop    %esi
f01049e4:	5d                   	pop    %ebp
f01049e5:	c3                   	ret    

f01049e6 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01049e6:	55                   	push   %ebp
f01049e7:	89 e5                	mov    %esp,%ebp
f01049e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01049ec:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01049ef:	89 c2                	mov    %eax,%edx
f01049f1:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01049f4:	eb 07                	jmp    f01049fd <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01049f6:	38 08                	cmp    %cl,(%eax)
f01049f8:	74 07                	je     f0104a01 <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01049fa:	83 c0 01             	add    $0x1,%eax
f01049fd:	39 d0                	cmp    %edx,%eax
f01049ff:	72 f5                	jb     f01049f6 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104a01:	5d                   	pop    %ebp
f0104a02:	c3                   	ret    

f0104a03 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104a03:	55                   	push   %ebp
f0104a04:	89 e5                	mov    %esp,%ebp
f0104a06:	57                   	push   %edi
f0104a07:	56                   	push   %esi
f0104a08:	53                   	push   %ebx
f0104a09:	8b 55 08             	mov    0x8(%ebp),%edx
f0104a0c:	8b 45 10             	mov    0x10(%ebp),%eax
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104a0f:	eb 03                	jmp    f0104a14 <strtol+0x11>
		s++;
f0104a11:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104a14:	0f b6 0a             	movzbl (%edx),%ecx
f0104a17:	80 f9 09             	cmp    $0x9,%cl
f0104a1a:	74 f5                	je     f0104a11 <strtol+0xe>
f0104a1c:	80 f9 20             	cmp    $0x20,%cl
f0104a1f:	74 f0                	je     f0104a11 <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104a21:	80 f9 2b             	cmp    $0x2b,%cl
f0104a24:	75 0a                	jne    f0104a30 <strtol+0x2d>
		s++;
f0104a26:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104a29:	bf 00 00 00 00       	mov    $0x0,%edi
f0104a2e:	eb 11                	jmp    f0104a41 <strtol+0x3e>
f0104a30:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0104a35:	80 f9 2d             	cmp    $0x2d,%cl
f0104a38:	75 07                	jne    f0104a41 <strtol+0x3e>
		s++, neg = 1;
f0104a3a:	8d 52 01             	lea    0x1(%edx),%edx
f0104a3d:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104a41:	a9 ef ff ff ff       	test   $0xffffffef,%eax
f0104a46:	75 15                	jne    f0104a5d <strtol+0x5a>
f0104a48:	80 3a 30             	cmpb   $0x30,(%edx)
f0104a4b:	75 10                	jne    f0104a5d <strtol+0x5a>
f0104a4d:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0104a51:	75 0a                	jne    f0104a5d <strtol+0x5a>
		s += 2, base = 16;
f0104a53:	83 c2 02             	add    $0x2,%edx
f0104a56:	b8 10 00 00 00       	mov    $0x10,%eax
f0104a5b:	eb 10                	jmp    f0104a6d <strtol+0x6a>
	else if (base == 0 && s[0] == '0')
f0104a5d:	85 c0                	test   %eax,%eax
f0104a5f:	75 0c                	jne    f0104a6d <strtol+0x6a>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0104a61:	b0 0a                	mov    $0xa,%al
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104a63:	80 3a 30             	cmpb   $0x30,(%edx)
f0104a66:	75 05                	jne    f0104a6d <strtol+0x6a>
		s++, base = 8;
f0104a68:	83 c2 01             	add    $0x1,%edx
f0104a6b:	b0 08                	mov    $0x8,%al
	else if (base == 0)
		base = 10;
f0104a6d:	bb 00 00 00 00       	mov    $0x0,%ebx
f0104a72:	89 45 10             	mov    %eax,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104a75:	0f b6 0a             	movzbl (%edx),%ecx
f0104a78:	8d 71 d0             	lea    -0x30(%ecx),%esi
f0104a7b:	89 f0                	mov    %esi,%eax
f0104a7d:	3c 09                	cmp    $0x9,%al
f0104a7f:	77 08                	ja     f0104a89 <strtol+0x86>
			dig = *s - '0';
f0104a81:	0f be c9             	movsbl %cl,%ecx
f0104a84:	83 e9 30             	sub    $0x30,%ecx
f0104a87:	eb 20                	jmp    f0104aa9 <strtol+0xa6>
		else if (*s >= 'a' && *s <= 'z')
f0104a89:	8d 71 9f             	lea    -0x61(%ecx),%esi
f0104a8c:	89 f0                	mov    %esi,%eax
f0104a8e:	3c 19                	cmp    $0x19,%al
f0104a90:	77 08                	ja     f0104a9a <strtol+0x97>
			dig = *s - 'a' + 10;
f0104a92:	0f be c9             	movsbl %cl,%ecx
f0104a95:	83 e9 57             	sub    $0x57,%ecx
f0104a98:	eb 0f                	jmp    f0104aa9 <strtol+0xa6>
		else if (*s >= 'A' && *s <= 'Z')
f0104a9a:	8d 71 bf             	lea    -0x41(%ecx),%esi
f0104a9d:	89 f0                	mov    %esi,%eax
f0104a9f:	3c 19                	cmp    $0x19,%al
f0104aa1:	77 16                	ja     f0104ab9 <strtol+0xb6>
			dig = *s - 'A' + 10;
f0104aa3:	0f be c9             	movsbl %cl,%ecx
f0104aa6:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104aa9:	3b 4d 10             	cmp    0x10(%ebp),%ecx
f0104aac:	7d 0f                	jge    f0104abd <strtol+0xba>
			break;
		s++, val = (val * base) + dig;
f0104aae:	83 c2 01             	add    $0x1,%edx
f0104ab1:	0f af 5d 10          	imul   0x10(%ebp),%ebx
f0104ab5:	01 cb                	add    %ecx,%ebx
		// we don't properly detect overflow!
	}
f0104ab7:	eb bc                	jmp    f0104a75 <strtol+0x72>
f0104ab9:	89 d8                	mov    %ebx,%eax
f0104abb:	eb 02                	jmp    f0104abf <strtol+0xbc>
f0104abd:	89 d8                	mov    %ebx,%eax

	if (endptr)
f0104abf:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0104ac3:	74 05                	je     f0104aca <strtol+0xc7>
		*endptr = (char *) s;
f0104ac5:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104ac8:	89 16                	mov    %edx,(%esi)
	return (neg ? -val : val);
f0104aca:	f7 d8                	neg    %eax
f0104acc:	85 ff                	test   %edi,%edi
f0104ace:	0f 44 c3             	cmove  %ebx,%eax
}
f0104ad1:	5b                   	pop    %ebx
f0104ad2:	5e                   	pop    %esi
f0104ad3:	5f                   	pop    %edi
f0104ad4:	5d                   	pop    %ebp
f0104ad5:	c3                   	ret    
f0104ad6:	66 90                	xchg   %ax,%ax

f0104ad8 <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f0104ad8:	fa                   	cli    

	xorw    %ax, %ax
f0104ad9:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f0104adb:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104add:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104adf:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0104ae1:	0f 01 16             	lgdtl  (%esi)
f0104ae4:	74 70                	je     f0104b56 <mpentry_end+0x4>
	movl    %cr0, %eax
f0104ae6:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f0104ae9:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0104aed:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0104af0:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f0104af6:	08 00                	or     %al,(%eax)

f0104af8 <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f0104af8:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0104afc:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0104afe:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0104b00:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0104b02:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f0104b06:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f0104b08:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f0104b0a:	b8 00 c0 11 00       	mov    $0x11c000,%eax
	movl    %eax, %cr3
f0104b0f:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0104b12:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0104b15:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f0104b1a:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0104b1d:	8b 25 04 9f 22 f0    	mov    0xf0229f04,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0104b23:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f0104b28:	b8 d6 01 10 f0       	mov    $0xf01001d6,%eax
	call    *%eax
f0104b2d:	ff d0                	call   *%eax

f0104b2f <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0104b2f:	eb fe                	jmp    f0104b2f <spin>
f0104b31:	8d 76 00             	lea    0x0(%esi),%esi

f0104b34 <gdt>:
	...
f0104b3c:	ff                   	(bad)  
f0104b3d:	ff 00                	incl   (%eax)
f0104b3f:	00 00                	add    %al,(%eax)
f0104b41:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f0104b48:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0104b4c <gdtdesc>:
f0104b4c:	17                   	pop    %ss
f0104b4d:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0104b52 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0104b52:	90                   	nop
f0104b53:	66 90                	xchg   %ax,%ax
f0104b55:	66 90                	xchg   %ax,%ax
f0104b57:	66 90                	xchg   %ax,%ax
f0104b59:	66 90                	xchg   %ax,%ax
f0104b5b:	66 90                	xchg   %ax,%ax
f0104b5d:	66 90                	xchg   %ax,%ax
f0104b5f:	90                   	nop

f0104b60 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0104b60:	55                   	push   %ebp
f0104b61:	89 e5                	mov    %esp,%ebp
f0104b63:	56                   	push   %esi
f0104b64:	53                   	push   %ebx
f0104b65:	83 ec 10             	sub    $0x10,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104b68:	8b 0d 08 9f 22 f0    	mov    0xf0229f08,%ecx
f0104b6e:	89 c3                	mov    %eax,%ebx
f0104b70:	c1 eb 0c             	shr    $0xc,%ebx
f0104b73:	39 cb                	cmp    %ecx,%ebx
f0104b75:	72 20                	jb     f0104b97 <mpsearch1+0x37>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104b77:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104b7b:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0104b82:	f0 
f0104b83:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0104b8a:	00 
f0104b8b:	c7 04 24 85 6e 10 f0 	movl   $0xf0106e85,(%esp)
f0104b92:	e8 a9 b4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104b97:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0104b9d:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104b9f:	89 c2                	mov    %eax,%edx
f0104ba1:	c1 ea 0c             	shr    $0xc,%edx
f0104ba4:	39 d1                	cmp    %edx,%ecx
f0104ba6:	77 20                	ja     f0104bc8 <mpsearch1+0x68>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104ba8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0104bac:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0104bb3:	f0 
f0104bb4:	c7 44 24 04 57 00 00 	movl   $0x57,0x4(%esp)
f0104bbb:	00 
f0104bbc:	c7 04 24 85 6e 10 f0 	movl   $0xf0106e85,(%esp)
f0104bc3:	e8 78 b4 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104bc8:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f0104bce:	eb 36                	jmp    f0104c06 <mpsearch1+0xa6>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104bd0:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0104bd7:	00 
f0104bd8:	c7 44 24 04 95 6e 10 	movl   $0xf0106e95,0x4(%esp)
f0104bdf:	f0 
f0104be0:	89 1c 24             	mov    %ebx,(%esp)
f0104be3:	e8 c5 fd ff ff       	call   f01049ad <memcmp>
f0104be8:	85 c0                	test   %eax,%eax
f0104bea:	75 17                	jne    f0104c03 <mpsearch1+0xa3>
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104bec:	ba 00 00 00 00       	mov    $0x0,%edx
		sum += ((uint8_t *)addr)[i];
f0104bf1:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0104bf5:	01 c8                	add    %ecx,%eax
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104bf7:	83 c2 01             	add    $0x1,%edx
f0104bfa:	83 fa 10             	cmp    $0x10,%edx
f0104bfd:	75 f2                	jne    f0104bf1 <mpsearch1+0x91>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0104bff:	84 c0                	test   %al,%al
f0104c01:	74 0e                	je     f0104c11 <mpsearch1+0xb1>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0104c03:	83 c3 10             	add    $0x10,%ebx
f0104c06:	39 f3                	cmp    %esi,%ebx
f0104c08:	72 c6                	jb     f0104bd0 <mpsearch1+0x70>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f0104c0a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c0f:	eb 02                	jmp    f0104c13 <mpsearch1+0xb3>
f0104c11:	89 d8                	mov    %ebx,%eax
}
f0104c13:	83 c4 10             	add    $0x10,%esp
f0104c16:	5b                   	pop    %ebx
f0104c17:	5e                   	pop    %esi
f0104c18:	5d                   	pop    %ebp
f0104c19:	c3                   	ret    

f0104c1a <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0104c1a:	55                   	push   %ebp
f0104c1b:	89 e5                	mov    %esp,%ebp
f0104c1d:	57                   	push   %edi
f0104c1e:	56                   	push   %esi
f0104c1f:	53                   	push   %ebx
f0104c20:	83 ec 2c             	sub    $0x2c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0104c23:	c7 05 c0 a3 22 f0 20 	movl   $0xf022a020,0xf022a3c0
f0104c2a:	a0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104c2d:	83 3d 08 9f 22 f0 00 	cmpl   $0x0,0xf0229f08
f0104c34:	75 24                	jne    f0104c5a <mp_init+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104c36:	c7 44 24 0c 00 04 00 	movl   $0x400,0xc(%esp)
f0104c3d:	00 
f0104c3e:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0104c45:	f0 
f0104c46:	c7 44 24 04 6f 00 00 	movl   $0x6f,0x4(%esp)
f0104c4d:	00 
f0104c4e:	c7 04 24 85 6e 10 f0 	movl   $0xf0106e85,(%esp)
f0104c55:	e8 e6 b3 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0104c5a:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0104c61:	85 c0                	test   %eax,%eax
f0104c63:	74 16                	je     f0104c7b <mp_init+0x61>
		p <<= 4;	// Translate from segment to PA
f0104c65:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0104c68:	ba 00 04 00 00       	mov    $0x400,%edx
f0104c6d:	e8 ee fe ff ff       	call   f0104b60 <mpsearch1>
f0104c72:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104c75:	85 c0                	test   %eax,%eax
f0104c77:	75 3c                	jne    f0104cb5 <mp_init+0x9b>
f0104c79:	eb 20                	jmp    f0104c9b <mp_init+0x81>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0104c7b:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f0104c82:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f0104c85:	2d 00 04 00 00       	sub    $0x400,%eax
f0104c8a:	ba 00 04 00 00       	mov    $0x400,%edx
f0104c8f:	e8 cc fe ff ff       	call   f0104b60 <mpsearch1>
f0104c94:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104c97:	85 c0                	test   %eax,%eax
f0104c99:	75 1a                	jne    f0104cb5 <mp_init+0x9b>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0104c9b:	ba 00 00 01 00       	mov    $0x10000,%edx
f0104ca0:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f0104ca5:	e8 b6 fe ff ff       	call   f0104b60 <mpsearch1>
f0104caa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0104cad:	85 c0                	test   %eax,%eax
f0104caf:	0f 84 54 02 00 00    	je     f0104f09 <mp_init+0x2ef>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f0104cb5:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104cb8:	8b 70 04             	mov    0x4(%eax),%esi
f0104cbb:	85 f6                	test   %esi,%esi
f0104cbd:	74 06                	je     f0104cc5 <mp_init+0xab>
f0104cbf:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f0104cc3:	74 11                	je     f0104cd6 <mp_init+0xbc>
		cprintf("SMP: Default configurations not implemented\n");
f0104cc5:	c7 04 24 f8 6c 10 f0 	movl   $0xf0106cf8,(%esp)
f0104ccc:	e8 bf e6 ff ff       	call   f0103390 <cprintf>
f0104cd1:	e9 33 02 00 00       	jmp    f0104f09 <mp_init+0x2ef>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0104cd6:	89 f0                	mov    %esi,%eax
f0104cd8:	c1 e8 0c             	shr    $0xc,%eax
f0104cdb:	3b 05 08 9f 22 f0    	cmp    0xf0229f08,%eax
f0104ce1:	72 20                	jb     f0104d03 <mp_init+0xe9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0104ce3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0104ce7:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f0104cee:	f0 
f0104cef:	c7 44 24 04 90 00 00 	movl   $0x90,0x4(%esp)
f0104cf6:	00 
f0104cf7:	c7 04 24 85 6e 10 f0 	movl   $0xf0106e85,(%esp)
f0104cfe:	e8 3d b3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0104d03:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f0104d09:	c7 44 24 08 04 00 00 	movl   $0x4,0x8(%esp)
f0104d10:	00 
f0104d11:	c7 44 24 04 9a 6e 10 	movl   $0xf0106e9a,0x4(%esp)
f0104d18:	f0 
f0104d19:	89 1c 24             	mov    %ebx,(%esp)
f0104d1c:	e8 8c fc ff ff       	call   f01049ad <memcmp>
f0104d21:	85 c0                	test   %eax,%eax
f0104d23:	74 11                	je     f0104d36 <mp_init+0x11c>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0104d25:	c7 04 24 28 6d 10 f0 	movl   $0xf0106d28,(%esp)
f0104d2c:	e8 5f e6 ff ff       	call   f0103390 <cprintf>
f0104d31:	e9 d3 01 00 00       	jmp    f0104f09 <mp_init+0x2ef>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0104d36:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f0104d3a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f0104d3e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0104d41:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0104d46:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d4b:	eb 0d                	jmp    f0104d5a <mp_init+0x140>
		sum += ((uint8_t *)addr)[i];
f0104d4d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0104d54:	f0 
f0104d55:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104d57:	83 c0 01             	add    $0x1,%eax
f0104d5a:	39 c7                	cmp    %eax,%edi
f0104d5c:	7f ef                	jg     f0104d4d <mp_init+0x133>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0104d5e:	84 d2                	test   %dl,%dl
f0104d60:	74 11                	je     f0104d73 <mp_init+0x159>
		cprintf("SMP: Bad MP configuration checksum\n");
f0104d62:	c7 04 24 5c 6d 10 f0 	movl   $0xf0106d5c,(%esp)
f0104d69:	e8 22 e6 ff ff       	call   f0103390 <cprintf>
f0104d6e:	e9 96 01 00 00       	jmp    f0104f09 <mp_init+0x2ef>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0104d73:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f0104d77:	3c 04                	cmp    $0x4,%al
f0104d79:	74 1f                	je     f0104d9a <mp_init+0x180>
f0104d7b:	3c 01                	cmp    $0x1,%al
f0104d7d:	8d 76 00             	lea    0x0(%esi),%esi
f0104d80:	74 18                	je     f0104d9a <mp_init+0x180>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0104d82:	0f b6 c0             	movzbl %al,%eax
f0104d85:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104d89:	c7 04 24 80 6d 10 f0 	movl   $0xf0106d80,(%esp)
f0104d90:	e8 fb e5 ff ff       	call   f0103390 <cprintf>
f0104d95:	e9 6f 01 00 00       	jmp    f0104f09 <mp_init+0x2ef>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0104d9a:	0f b7 73 28          	movzwl 0x28(%ebx),%esi
f0104d9e:	0f b7 7d e2          	movzwl -0x1e(%ebp),%edi
f0104da2:	01 df                	add    %ebx,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0104da4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0104da9:	b8 00 00 00 00       	mov    $0x0,%eax
f0104dae:	eb 09                	jmp    f0104db9 <mp_init+0x19f>
		sum += ((uint8_t *)addr)[i];
f0104db0:	0f b6 0c 07          	movzbl (%edi,%eax,1),%ecx
f0104db4:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0104db6:	83 c0 01             	add    $0x1,%eax
f0104db9:	39 c6                	cmp    %eax,%esi
f0104dbb:	7f f3                	jg     f0104db0 <mp_init+0x196>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0104dbd:	02 53 2a             	add    0x2a(%ebx),%dl
f0104dc0:	84 d2                	test   %dl,%dl
f0104dc2:	74 11                	je     f0104dd5 <mp_init+0x1bb>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f0104dc4:	c7 04 24 a0 6d 10 f0 	movl   $0xf0106da0,(%esp)
f0104dcb:	e8 c0 e5 ff ff       	call   f0103390 <cprintf>
f0104dd0:	e9 34 01 00 00       	jmp    f0104f09 <mp_init+0x2ef>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f0104dd5:	85 db                	test   %ebx,%ebx
f0104dd7:	0f 84 2c 01 00 00    	je     f0104f09 <mp_init+0x2ef>
		return;
	ismp = 1;
f0104ddd:	c7 05 00 a0 22 f0 01 	movl   $0x1,0xf022a000
f0104de4:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0104de7:	8b 43 24             	mov    0x24(%ebx),%eax
f0104dea:	a3 00 b0 26 f0       	mov    %eax,0xf026b000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0104def:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f0104df2:	be 00 00 00 00       	mov    $0x0,%esi
f0104df7:	e9 86 00 00 00       	jmp    f0104e82 <mp_init+0x268>
		switch (*p) {
f0104dfc:	0f b6 07             	movzbl (%edi),%eax
f0104dff:	84 c0                	test   %al,%al
f0104e01:	74 06                	je     f0104e09 <mp_init+0x1ef>
f0104e03:	3c 04                	cmp    $0x4,%al
f0104e05:	77 57                	ja     f0104e5e <mp_init+0x244>
f0104e07:	eb 50                	jmp    f0104e59 <mp_init+0x23f>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0104e09:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0104e0d:	8d 76 00             	lea    0x0(%esi),%esi
f0104e10:	74 11                	je     f0104e23 <mp_init+0x209>
				bootcpu = &cpus[ncpu];
f0104e12:	6b 05 c4 a3 22 f0 74 	imul   $0x74,0xf022a3c4,%eax
f0104e19:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f0104e1e:	a3 c0 a3 22 f0       	mov    %eax,0xf022a3c0
			if (ncpu < NCPU) {
f0104e23:	a1 c4 a3 22 f0       	mov    0xf022a3c4,%eax
f0104e28:	83 f8 07             	cmp    $0x7,%eax
f0104e2b:	7f 13                	jg     f0104e40 <mp_init+0x226>
				cpus[ncpu].cpu_id = ncpu;
f0104e2d:	6b d0 74             	imul   $0x74,%eax,%edx
f0104e30:	88 82 20 a0 22 f0    	mov    %al,-0xfdd5fe0(%edx)
				ncpu++;
f0104e36:	83 c0 01             	add    $0x1,%eax
f0104e39:	a3 c4 a3 22 f0       	mov    %eax,0xf022a3c4
f0104e3e:	eb 14                	jmp    f0104e54 <mp_init+0x23a>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0104e40:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f0104e44:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e48:	c7 04 24 d0 6d 10 f0 	movl   $0xf0106dd0,(%esp)
f0104e4f:	e8 3c e5 ff ff       	call   f0103390 <cprintf>
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f0104e54:	83 c7 14             	add    $0x14,%edi
			continue;
f0104e57:	eb 26                	jmp    f0104e7f <mp_init+0x265>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0104e59:	83 c7 08             	add    $0x8,%edi
			continue;
f0104e5c:	eb 21                	jmp    f0104e7f <mp_init+0x265>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0104e5e:	0f b6 c0             	movzbl %al,%eax
f0104e61:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104e65:	c7 04 24 f8 6d 10 f0 	movl   $0xf0106df8,(%esp)
f0104e6c:	e8 1f e5 ff ff       	call   f0103390 <cprintf>
			ismp = 0;
f0104e71:	c7 05 00 a0 22 f0 00 	movl   $0x0,0xf022a000
f0104e78:	00 00 00 
			i = conf->entry;
f0104e7b:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0104e7f:	83 c6 01             	add    $0x1,%esi
f0104e82:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f0104e86:	39 c6                	cmp    %eax,%esi
f0104e88:	0f 82 6e ff ff ff    	jb     f0104dfc <mp_init+0x1e2>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0104e8e:	a1 c0 a3 22 f0       	mov    0xf022a3c0,%eax
f0104e93:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0104e9a:	83 3d 00 a0 22 f0 00 	cmpl   $0x0,0xf022a000
f0104ea1:	75 22                	jne    f0104ec5 <mp_init+0x2ab>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f0104ea3:	c7 05 c4 a3 22 f0 01 	movl   $0x1,0xf022a3c4
f0104eaa:	00 00 00 
		lapicaddr = 0;
f0104ead:	c7 05 00 b0 26 f0 00 	movl   $0x0,0xf026b000
f0104eb4:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0104eb7:	c7 04 24 18 6e 10 f0 	movl   $0xf0106e18,(%esp)
f0104ebe:	e8 cd e4 ff ff       	call   f0103390 <cprintf>
		return;
f0104ec3:	eb 44                	jmp    f0104f09 <mp_init+0x2ef>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0104ec5:	8b 15 c4 a3 22 f0    	mov    0xf022a3c4,%edx
f0104ecb:	89 54 24 08          	mov    %edx,0x8(%esp)
f0104ecf:	0f b6 00             	movzbl (%eax),%eax
f0104ed2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104ed6:	c7 04 24 9f 6e 10 f0 	movl   $0xf0106e9f,(%esp)
f0104edd:	e8 ae e4 ff ff       	call   f0103390 <cprintf>

	if (mp->imcrp) {
f0104ee2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104ee5:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0104ee9:	74 1e                	je     f0104f09 <mp_init+0x2ef>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0104eeb:	c7 04 24 44 6e 10 f0 	movl   $0xf0106e44,(%esp)
f0104ef2:	e8 99 e4 ff ff       	call   f0103390 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0104ef7:	ba 22 00 00 00       	mov    $0x22,%edx
f0104efc:	b8 70 00 00 00       	mov    $0x70,%eax
f0104f01:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0104f02:	b2 23                	mov    $0x23,%dl
f0104f04:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0104f05:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0104f08:	ee                   	out    %al,(%dx)
	}
}
f0104f09:	83 c4 2c             	add    $0x2c,%esp
f0104f0c:	5b                   	pop    %ebx
f0104f0d:	5e                   	pop    %esi
f0104f0e:	5f                   	pop    %edi
f0104f0f:	5d                   	pop    %ebp
f0104f10:	c3                   	ret    

f0104f11 <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f0104f11:	55                   	push   %ebp
f0104f12:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0104f14:	8b 0d 04 b0 26 f0    	mov    0xf026b004,%ecx
f0104f1a:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f0104f1d:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f0104f1f:	a1 04 b0 26 f0       	mov    0xf026b004,%eax
f0104f24:	8b 40 20             	mov    0x20(%eax),%eax
}
f0104f27:	5d                   	pop    %ebp
f0104f28:	c3                   	ret    

f0104f29 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0104f29:	55                   	push   %ebp
f0104f2a:	89 e5                	mov    %esp,%ebp
	if (lapic)
f0104f2c:	a1 04 b0 26 f0       	mov    0xf026b004,%eax
f0104f31:	85 c0                	test   %eax,%eax
f0104f33:	74 08                	je     f0104f3d <cpunum+0x14>
		return lapic[ID] >> 24;
f0104f35:	8b 40 20             	mov    0x20(%eax),%eax
f0104f38:	c1 e8 18             	shr    $0x18,%eax
f0104f3b:	eb 05                	jmp    f0104f42 <cpunum+0x19>
	return 0;
f0104f3d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104f42:	5d                   	pop    %ebp
f0104f43:	c3                   	ret    

f0104f44 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0104f44:	a1 00 b0 26 f0       	mov    0xf026b000,%eax
f0104f49:	85 c0                	test   %eax,%eax
f0104f4b:	0f 84 23 01 00 00    	je     f0105074 <lapic_init+0x130>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f0104f51:	55                   	push   %ebp
f0104f52:	89 e5                	mov    %esp,%ebp
f0104f54:	83 ec 18             	sub    $0x18,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0104f57:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0104f5e:	00 
f0104f5f:	89 04 24             	mov    %eax,(%esp)
f0104f62:	e8 88 c1 ff ff       	call   f01010ef <mmio_map_region>
f0104f67:	a3 04 b0 26 f0       	mov    %eax,0xf026b004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0104f6c:	ba 27 01 00 00       	mov    $0x127,%edx
f0104f71:	b8 3c 00 00 00       	mov    $0x3c,%eax
f0104f76:	e8 96 ff ff ff       	call   f0104f11 <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0104f7b:	ba 0b 00 00 00       	mov    $0xb,%edx
f0104f80:	b8 f8 00 00 00       	mov    $0xf8,%eax
f0104f85:	e8 87 ff ff ff       	call   f0104f11 <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0104f8a:	ba 20 00 02 00       	mov    $0x20020,%edx
f0104f8f:	b8 c8 00 00 00       	mov    $0xc8,%eax
f0104f94:	e8 78 ff ff ff       	call   f0104f11 <lapicw>
	lapicw(TICR, 10000000); 
f0104f99:	ba 80 96 98 00       	mov    $0x989680,%edx
f0104f9e:	b8 e0 00 00 00       	mov    $0xe0,%eax
f0104fa3:	e8 69 ff ff ff       	call   f0104f11 <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0104fa8:	e8 7c ff ff ff       	call   f0104f29 <cpunum>
f0104fad:	6b c0 74             	imul   $0x74,%eax,%eax
f0104fb0:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f0104fb5:	39 05 c0 a3 22 f0    	cmp    %eax,0xf022a3c0
f0104fbb:	74 0f                	je     f0104fcc <lapic_init+0x88>
		lapicw(LINT0, MASKED);
f0104fbd:	ba 00 00 01 00       	mov    $0x10000,%edx
f0104fc2:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0104fc7:	e8 45 ff ff ff       	call   f0104f11 <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0104fcc:	ba 00 00 01 00       	mov    $0x10000,%edx
f0104fd1:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0104fd6:	e8 36 ff ff ff       	call   f0104f11 <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0104fdb:	a1 04 b0 26 f0       	mov    0xf026b004,%eax
f0104fe0:	8b 40 30             	mov    0x30(%eax),%eax
f0104fe3:	c1 e8 10             	shr    $0x10,%eax
f0104fe6:	3c 03                	cmp    $0x3,%al
f0104fe8:	76 0f                	jbe    f0104ff9 <lapic_init+0xb5>
		lapicw(PCINT, MASKED);
f0104fea:	ba 00 00 01 00       	mov    $0x10000,%edx
f0104fef:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0104ff4:	e8 18 ff ff ff       	call   f0104f11 <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0104ff9:	ba 33 00 00 00       	mov    $0x33,%edx
f0104ffe:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105003:	e8 09 ff ff ff       	call   f0104f11 <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105008:	ba 00 00 00 00       	mov    $0x0,%edx
f010500d:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105012:	e8 fa fe ff ff       	call   f0104f11 <lapicw>
	lapicw(ESR, 0);
f0105017:	ba 00 00 00 00       	mov    $0x0,%edx
f010501c:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105021:	e8 eb fe ff ff       	call   f0104f11 <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105026:	ba 00 00 00 00       	mov    $0x0,%edx
f010502b:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105030:	e8 dc fe ff ff       	call   f0104f11 <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105035:	ba 00 00 00 00       	mov    $0x0,%edx
f010503a:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010503f:	e8 cd fe ff ff       	call   f0104f11 <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105044:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105049:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010504e:	e8 be fe ff ff       	call   f0104f11 <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105053:	8b 15 04 b0 26 f0    	mov    0xf026b004,%edx
f0105059:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f010505f:	f6 c4 10             	test   $0x10,%ah
f0105062:	75 f5                	jne    f0105059 <lapic_init+0x115>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105064:	ba 00 00 00 00       	mov    $0x0,%edx
f0105069:	b8 20 00 00 00       	mov    $0x20,%eax
f010506e:	e8 9e fe ff ff       	call   f0104f11 <lapicw>
}
f0105073:	c9                   	leave  
f0105074:	f3 c3                	repz ret 

f0105076 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105076:	83 3d 04 b0 26 f0 00 	cmpl   $0x0,0xf026b004
f010507d:	74 13                	je     f0105092 <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010507f:	55                   	push   %ebp
f0105080:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105082:	ba 00 00 00 00       	mov    $0x0,%edx
f0105087:	b8 2c 00 00 00       	mov    $0x2c,%eax
f010508c:	e8 80 fe ff ff       	call   f0104f11 <lapicw>
}
f0105091:	5d                   	pop    %ebp
f0105092:	f3 c3                	repz ret 

f0105094 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105094:	55                   	push   %ebp
f0105095:	89 e5                	mov    %esp,%ebp
f0105097:	56                   	push   %esi
f0105098:	53                   	push   %ebx
f0105099:	83 ec 10             	sub    $0x10,%esp
f010509c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010509f:	8b 75 0c             	mov    0xc(%ebp),%esi
f01050a2:	ba 70 00 00 00       	mov    $0x70,%edx
f01050a7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01050ac:	ee                   	out    %al,(%dx)
f01050ad:	b2 71                	mov    $0x71,%dl
f01050af:	b8 0a 00 00 00       	mov    $0xa,%eax
f01050b4:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01050b5:	83 3d 08 9f 22 f0 00 	cmpl   $0x0,0xf0229f08
f01050bc:	75 24                	jne    f01050e2 <lapic_startap+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01050be:	c7 44 24 0c 67 04 00 	movl   $0x467,0xc(%esp)
f01050c5:	00 
f01050c6:	c7 44 24 08 24 56 10 	movl   $0xf0105624,0x8(%esp)
f01050cd:	f0 
f01050ce:	c7 44 24 04 98 00 00 	movl   $0x98,0x4(%esp)
f01050d5:	00 
f01050d6:	c7 04 24 bc 6e 10 f0 	movl   $0xf0106ebc,(%esp)
f01050dd:	e8 5e af ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f01050e2:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f01050e9:	00 00 
	wrv[1] = addr >> 4;
f01050eb:	89 f0                	mov    %esi,%eax
f01050ed:	c1 e8 04             	shr    $0x4,%eax
f01050f0:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f01050f6:	c1 e3 18             	shl    $0x18,%ebx
f01050f9:	89 da                	mov    %ebx,%edx
f01050fb:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105100:	e8 0c fe ff ff       	call   f0104f11 <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105105:	ba 00 c5 00 00       	mov    $0xc500,%edx
f010510a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010510f:	e8 fd fd ff ff       	call   f0104f11 <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105114:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105119:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010511e:	e8 ee fd ff ff       	call   f0104f11 <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105123:	c1 ee 0c             	shr    $0xc,%esi
f0105126:	81 ce 00 06 00 00    	or     $0x600,%esi
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f010512c:	89 da                	mov    %ebx,%edx
f010512e:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105133:	e8 d9 fd ff ff       	call   f0104f11 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105138:	89 f2                	mov    %esi,%edx
f010513a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010513f:	e8 cd fd ff ff       	call   f0104f11 <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105144:	89 da                	mov    %ebx,%edx
f0105146:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010514b:	e8 c1 fd ff ff       	call   f0104f11 <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105150:	89 f2                	mov    %esi,%edx
f0105152:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105157:	e8 b5 fd ff ff       	call   f0104f11 <lapicw>
		microdelay(200);
	}
}
f010515c:	83 c4 10             	add    $0x10,%esp
f010515f:	5b                   	pop    %ebx
f0105160:	5e                   	pop    %esi
f0105161:	5d                   	pop    %ebp
f0105162:	c3                   	ret    

f0105163 <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105163:	55                   	push   %ebp
f0105164:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105166:	8b 55 08             	mov    0x8(%ebp),%edx
f0105169:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f010516f:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105174:	e8 98 fd ff ff       	call   f0104f11 <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105179:	8b 15 04 b0 26 f0    	mov    0xf026b004,%edx
f010517f:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105185:	f6 c4 10             	test   $0x10,%ah
f0105188:	75 f5                	jne    f010517f <lapic_ipi+0x1c>
		;
}
f010518a:	5d                   	pop    %ebp
f010518b:	c3                   	ret    

f010518c <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f010518c:	55                   	push   %ebp
f010518d:	89 e5                	mov    %esp,%ebp
f010518f:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105192:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105198:	8b 55 0c             	mov    0xc(%ebp),%edx
f010519b:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f010519e:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f01051a5:	5d                   	pop    %ebp
f01051a6:	c3                   	ret    

f01051a7 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f01051a7:	55                   	push   %ebp
f01051a8:	89 e5                	mov    %esp,%ebp
f01051aa:	56                   	push   %esi
f01051ab:	53                   	push   %ebx
f01051ac:	83 ec 20             	sub    $0x20,%esp
f01051af:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01051b2:	83 3b 00             	cmpl   $0x0,(%ebx)
f01051b5:	75 07                	jne    f01051be <spin_lock+0x17>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f01051b7:	ba 01 00 00 00       	mov    $0x1,%edx
f01051bc:	eb 42                	jmp    f0105200 <spin_lock+0x59>
f01051be:	8b 73 08             	mov    0x8(%ebx),%esi
f01051c1:	e8 63 fd ff ff       	call   f0104f29 <cpunum>
f01051c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01051c9:	05 20 a0 22 f0       	add    $0xf022a020,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f01051ce:	39 c6                	cmp    %eax,%esi
f01051d0:	75 e5                	jne    f01051b7 <spin_lock+0x10>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f01051d2:	8b 5b 04             	mov    0x4(%ebx),%ebx
f01051d5:	e8 4f fd ff ff       	call   f0104f29 <cpunum>
f01051da:	89 5c 24 10          	mov    %ebx,0x10(%esp)
f01051de:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01051e2:	c7 44 24 08 cc 6e 10 	movl   $0xf0106ecc,0x8(%esp)
f01051e9:	f0 
f01051ea:	c7 44 24 04 41 00 00 	movl   $0x41,0x4(%esp)
f01051f1:	00 
f01051f2:	c7 04 24 30 6f 10 f0 	movl   $0xf0106f30,(%esp)
f01051f9:	e8 42 ae ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f01051fe:	f3 90                	pause  
f0105200:	89 d0                	mov    %edx,%eax
f0105202:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105205:	85 c0                	test   %eax,%eax
f0105207:	75 f5                	jne    f01051fe <spin_lock+0x57>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105209:	e8 1b fd ff ff       	call   f0104f29 <cpunum>
f010520e:	6b c0 74             	imul   $0x74,%eax,%eax
f0105211:	05 20 a0 22 f0       	add    $0xf022a020,%eax
f0105216:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105219:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f010521c:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f010521e:	b8 00 00 00 00       	mov    $0x0,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105223:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105229:	76 12                	jbe    f010523d <spin_lock+0x96>
			break;
		pcs[i] = ebp[1];          // saved %eip
f010522b:	8b 4a 04             	mov    0x4(%edx),%ecx
f010522e:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105231:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105233:	83 c0 01             	add    $0x1,%eax
f0105236:	83 f8 0a             	cmp    $0xa,%eax
f0105239:	75 e8                	jne    f0105223 <spin_lock+0x7c>
f010523b:	eb 0f                	jmp    f010524c <spin_lock+0xa5>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f010523d:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105244:	83 c0 01             	add    $0x1,%eax
f0105247:	83 f8 09             	cmp    $0x9,%eax
f010524a:	7e f1                	jle    f010523d <spin_lock+0x96>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f010524c:	83 c4 20             	add    $0x20,%esp
f010524f:	5b                   	pop    %ebx
f0105250:	5e                   	pop    %esi
f0105251:	5d                   	pop    %ebp
f0105252:	c3                   	ret    

f0105253 <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105253:	55                   	push   %ebp
f0105254:	89 e5                	mov    %esp,%ebp
f0105256:	57                   	push   %edi
f0105257:	56                   	push   %esi
f0105258:	53                   	push   %ebx
f0105259:	83 ec 6c             	sub    $0x6c,%esp
f010525c:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010525f:	83 3e 00             	cmpl   $0x0,(%esi)
f0105262:	74 18                	je     f010527c <spin_unlock+0x29>
f0105264:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105267:	e8 bd fc ff ff       	call   f0104f29 <cpunum>
f010526c:	6b c0 74             	imul   $0x74,%eax,%eax
f010526f:	05 20 a0 22 f0       	add    $0xf022a020,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105274:	39 c3                	cmp    %eax,%ebx
f0105276:	0f 84 ce 00 00 00    	je     f010534a <spin_unlock+0xf7>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f010527c:	c7 44 24 08 28 00 00 	movl   $0x28,0x8(%esp)
f0105283:	00 
f0105284:	8d 46 0c             	lea    0xc(%esi),%eax
f0105287:	89 44 24 04          	mov    %eax,0x4(%esp)
f010528b:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f010528e:	89 1c 24             	mov    %ebx,(%esp)
f0105291:	e8 8e f6 ff ff       	call   f0104924 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105296:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105299:	0f b6 38             	movzbl (%eax),%edi
f010529c:	8b 76 04             	mov    0x4(%esi),%esi
f010529f:	e8 85 fc ff ff       	call   f0104f29 <cpunum>
f01052a4:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01052a8:	89 74 24 08          	mov    %esi,0x8(%esp)
f01052ac:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052b0:	c7 04 24 f8 6e 10 f0 	movl   $0xf0106ef8,(%esp)
f01052b7:	e8 d4 e0 ff ff       	call   f0103390 <cprintf>
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f01052bc:	8d 7d a8             	lea    -0x58(%ebp),%edi
f01052bf:	eb 65                	jmp    f0105326 <spin_unlock+0xd3>
f01052c1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01052c5:	89 04 24             	mov    %eax,(%esp)
f01052c8:	e8 cf ea ff ff       	call   f0103d9c <debuginfo_eip>
f01052cd:	85 c0                	test   %eax,%eax
f01052cf:	78 39                	js     f010530a <spin_unlock+0xb7>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f01052d1:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f01052d3:	89 c2                	mov    %eax,%edx
f01052d5:	2b 55 b8             	sub    -0x48(%ebp),%edx
f01052d8:	89 54 24 18          	mov    %edx,0x18(%esp)
f01052dc:	8b 55 b0             	mov    -0x50(%ebp),%edx
f01052df:	89 54 24 14          	mov    %edx,0x14(%esp)
f01052e3:	8b 55 b4             	mov    -0x4c(%ebp),%edx
f01052e6:	89 54 24 10          	mov    %edx,0x10(%esp)
f01052ea:	8b 55 ac             	mov    -0x54(%ebp),%edx
f01052ed:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01052f1:	8b 55 a8             	mov    -0x58(%ebp),%edx
f01052f4:	89 54 24 08          	mov    %edx,0x8(%esp)
f01052f8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01052fc:	c7 04 24 40 6f 10 f0 	movl   $0xf0106f40,(%esp)
f0105303:	e8 88 e0 ff ff       	call   f0103390 <cprintf>
f0105308:	eb 12                	jmp    f010531c <spin_unlock+0xc9>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f010530a:	8b 06                	mov    (%esi),%eax
f010530c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105310:	c7 04 24 57 6f 10 f0 	movl   $0xf0106f57,(%esp)
f0105317:	e8 74 e0 ff ff       	call   f0103390 <cprintf>
f010531c:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f010531f:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105322:	39 c3                	cmp    %eax,%ebx
f0105324:	74 08                	je     f010532e <spin_unlock+0xdb>
f0105326:	89 de                	mov    %ebx,%esi
f0105328:	8b 03                	mov    (%ebx),%eax
f010532a:	85 c0                	test   %eax,%eax
f010532c:	75 93                	jne    f01052c1 <spin_unlock+0x6e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f010532e:	c7 44 24 08 5f 6f 10 	movl   $0xf0106f5f,0x8(%esp)
f0105335:	f0 
f0105336:	c7 44 24 04 67 00 00 	movl   $0x67,0x4(%esp)
f010533d:	00 
f010533e:	c7 04 24 30 6f 10 f0 	movl   $0xf0106f30,(%esp)
f0105345:	e8 f6 ac ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f010534a:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105351:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0105358:	b8 00 00 00 00       	mov    $0x0,%eax
f010535d:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105360:	83 c4 6c             	add    $0x6c,%esp
f0105363:	5b                   	pop    %ebx
f0105364:	5e                   	pop    %esi
f0105365:	5f                   	pop    %edi
f0105366:	5d                   	pop    %ebp
f0105367:	c3                   	ret    
f0105368:	66 90                	xchg   %ax,%ax
f010536a:	66 90                	xchg   %ax,%ax
f010536c:	66 90                	xchg   %ax,%ax
f010536e:	66 90                	xchg   %ax,%ax

f0105370 <__udivdi3>:
f0105370:	55                   	push   %ebp
f0105371:	57                   	push   %edi
f0105372:	56                   	push   %esi
f0105373:	83 ec 0c             	sub    $0xc,%esp
f0105376:	8b 44 24 28          	mov    0x28(%esp),%eax
f010537a:	8b 7c 24 1c          	mov    0x1c(%esp),%edi
f010537e:	8b 6c 24 20          	mov    0x20(%esp),%ebp
f0105382:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f0105386:	85 c0                	test   %eax,%eax
f0105388:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010538c:	89 ea                	mov    %ebp,%edx
f010538e:	89 0c 24             	mov    %ecx,(%esp)
f0105391:	75 2d                	jne    f01053c0 <__udivdi3+0x50>
f0105393:	39 e9                	cmp    %ebp,%ecx
f0105395:	77 61                	ja     f01053f8 <__udivdi3+0x88>
f0105397:	85 c9                	test   %ecx,%ecx
f0105399:	89 ce                	mov    %ecx,%esi
f010539b:	75 0b                	jne    f01053a8 <__udivdi3+0x38>
f010539d:	b8 01 00 00 00       	mov    $0x1,%eax
f01053a2:	31 d2                	xor    %edx,%edx
f01053a4:	f7 f1                	div    %ecx
f01053a6:	89 c6                	mov    %eax,%esi
f01053a8:	31 d2                	xor    %edx,%edx
f01053aa:	89 e8                	mov    %ebp,%eax
f01053ac:	f7 f6                	div    %esi
f01053ae:	89 c5                	mov    %eax,%ebp
f01053b0:	89 f8                	mov    %edi,%eax
f01053b2:	f7 f6                	div    %esi
f01053b4:	89 ea                	mov    %ebp,%edx
f01053b6:	83 c4 0c             	add    $0xc,%esp
f01053b9:	5e                   	pop    %esi
f01053ba:	5f                   	pop    %edi
f01053bb:	5d                   	pop    %ebp
f01053bc:	c3                   	ret    
f01053bd:	8d 76 00             	lea    0x0(%esi),%esi
f01053c0:	39 e8                	cmp    %ebp,%eax
f01053c2:	77 24                	ja     f01053e8 <__udivdi3+0x78>
f01053c4:	0f bd e8             	bsr    %eax,%ebp
f01053c7:	83 f5 1f             	xor    $0x1f,%ebp
f01053ca:	75 3c                	jne    f0105408 <__udivdi3+0x98>
f01053cc:	8b 74 24 04          	mov    0x4(%esp),%esi
f01053d0:	39 34 24             	cmp    %esi,(%esp)
f01053d3:	0f 86 9f 00 00 00    	jbe    f0105478 <__udivdi3+0x108>
f01053d9:	39 d0                	cmp    %edx,%eax
f01053db:	0f 82 97 00 00 00    	jb     f0105478 <__udivdi3+0x108>
f01053e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01053e8:	31 d2                	xor    %edx,%edx
f01053ea:	31 c0                	xor    %eax,%eax
f01053ec:	83 c4 0c             	add    $0xc,%esp
f01053ef:	5e                   	pop    %esi
f01053f0:	5f                   	pop    %edi
f01053f1:	5d                   	pop    %ebp
f01053f2:	c3                   	ret    
f01053f3:	90                   	nop
f01053f4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01053f8:	89 f8                	mov    %edi,%eax
f01053fa:	f7 f1                	div    %ecx
f01053fc:	31 d2                	xor    %edx,%edx
f01053fe:	83 c4 0c             	add    $0xc,%esp
f0105401:	5e                   	pop    %esi
f0105402:	5f                   	pop    %edi
f0105403:	5d                   	pop    %ebp
f0105404:	c3                   	ret    
f0105405:	8d 76 00             	lea    0x0(%esi),%esi
f0105408:	89 e9                	mov    %ebp,%ecx
f010540a:	8b 3c 24             	mov    (%esp),%edi
f010540d:	d3 e0                	shl    %cl,%eax
f010540f:	89 c6                	mov    %eax,%esi
f0105411:	b8 20 00 00 00       	mov    $0x20,%eax
f0105416:	29 e8                	sub    %ebp,%eax
f0105418:	89 c1                	mov    %eax,%ecx
f010541a:	d3 ef                	shr    %cl,%edi
f010541c:	89 e9                	mov    %ebp,%ecx
f010541e:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0105422:	8b 3c 24             	mov    (%esp),%edi
f0105425:	09 74 24 08          	or     %esi,0x8(%esp)
f0105429:	89 d6                	mov    %edx,%esi
f010542b:	d3 e7                	shl    %cl,%edi
f010542d:	89 c1                	mov    %eax,%ecx
f010542f:	89 3c 24             	mov    %edi,(%esp)
f0105432:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105436:	d3 ee                	shr    %cl,%esi
f0105438:	89 e9                	mov    %ebp,%ecx
f010543a:	d3 e2                	shl    %cl,%edx
f010543c:	89 c1                	mov    %eax,%ecx
f010543e:	d3 ef                	shr    %cl,%edi
f0105440:	09 d7                	or     %edx,%edi
f0105442:	89 f2                	mov    %esi,%edx
f0105444:	89 f8                	mov    %edi,%eax
f0105446:	f7 74 24 08          	divl   0x8(%esp)
f010544a:	89 d6                	mov    %edx,%esi
f010544c:	89 c7                	mov    %eax,%edi
f010544e:	f7 24 24             	mull   (%esp)
f0105451:	39 d6                	cmp    %edx,%esi
f0105453:	89 14 24             	mov    %edx,(%esp)
f0105456:	72 30                	jb     f0105488 <__udivdi3+0x118>
f0105458:	8b 54 24 04          	mov    0x4(%esp),%edx
f010545c:	89 e9                	mov    %ebp,%ecx
f010545e:	d3 e2                	shl    %cl,%edx
f0105460:	39 c2                	cmp    %eax,%edx
f0105462:	73 05                	jae    f0105469 <__udivdi3+0xf9>
f0105464:	3b 34 24             	cmp    (%esp),%esi
f0105467:	74 1f                	je     f0105488 <__udivdi3+0x118>
f0105469:	89 f8                	mov    %edi,%eax
f010546b:	31 d2                	xor    %edx,%edx
f010546d:	e9 7a ff ff ff       	jmp    f01053ec <__udivdi3+0x7c>
f0105472:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0105478:	31 d2                	xor    %edx,%edx
f010547a:	b8 01 00 00 00       	mov    $0x1,%eax
f010547f:	e9 68 ff ff ff       	jmp    f01053ec <__udivdi3+0x7c>
f0105484:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105488:	8d 47 ff             	lea    -0x1(%edi),%eax
f010548b:	31 d2                	xor    %edx,%edx
f010548d:	83 c4 0c             	add    $0xc,%esp
f0105490:	5e                   	pop    %esi
f0105491:	5f                   	pop    %edi
f0105492:	5d                   	pop    %ebp
f0105493:	c3                   	ret    
f0105494:	66 90                	xchg   %ax,%ax
f0105496:	66 90                	xchg   %ax,%ax
f0105498:	66 90                	xchg   %ax,%ax
f010549a:	66 90                	xchg   %ax,%ax
f010549c:	66 90                	xchg   %ax,%ax
f010549e:	66 90                	xchg   %ax,%ax

f01054a0 <__umoddi3>:
f01054a0:	55                   	push   %ebp
f01054a1:	57                   	push   %edi
f01054a2:	56                   	push   %esi
f01054a3:	83 ec 14             	sub    $0x14,%esp
f01054a6:	8b 44 24 28          	mov    0x28(%esp),%eax
f01054aa:	8b 4c 24 24          	mov    0x24(%esp),%ecx
f01054ae:	8b 74 24 2c          	mov    0x2c(%esp),%esi
f01054b2:	89 c7                	mov    %eax,%edi
f01054b4:	89 44 24 04          	mov    %eax,0x4(%esp)
f01054b8:	8b 44 24 30          	mov    0x30(%esp),%eax
f01054bc:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f01054c0:	89 34 24             	mov    %esi,(%esp)
f01054c3:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f01054c7:	85 c0                	test   %eax,%eax
f01054c9:	89 c2                	mov    %eax,%edx
f01054cb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01054cf:	75 17                	jne    f01054e8 <__umoddi3+0x48>
f01054d1:	39 fe                	cmp    %edi,%esi
f01054d3:	76 4b                	jbe    f0105520 <__umoddi3+0x80>
f01054d5:	89 c8                	mov    %ecx,%eax
f01054d7:	89 fa                	mov    %edi,%edx
f01054d9:	f7 f6                	div    %esi
f01054db:	89 d0                	mov    %edx,%eax
f01054dd:	31 d2                	xor    %edx,%edx
f01054df:	83 c4 14             	add    $0x14,%esp
f01054e2:	5e                   	pop    %esi
f01054e3:	5f                   	pop    %edi
f01054e4:	5d                   	pop    %ebp
f01054e5:	c3                   	ret    
f01054e6:	66 90                	xchg   %ax,%ax
f01054e8:	39 f8                	cmp    %edi,%eax
f01054ea:	77 54                	ja     f0105540 <__umoddi3+0xa0>
f01054ec:	0f bd e8             	bsr    %eax,%ebp
f01054ef:	83 f5 1f             	xor    $0x1f,%ebp
f01054f2:	75 5c                	jne    f0105550 <__umoddi3+0xb0>
f01054f4:	8b 7c 24 08          	mov    0x8(%esp),%edi
f01054f8:	39 3c 24             	cmp    %edi,(%esp)
f01054fb:	0f 87 e7 00 00 00    	ja     f01055e8 <__umoddi3+0x148>
f0105501:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0105505:	29 f1                	sub    %esi,%ecx
f0105507:	19 c7                	sbb    %eax,%edi
f0105509:	89 4c 24 08          	mov    %ecx,0x8(%esp)
f010550d:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105511:	8b 44 24 08          	mov    0x8(%esp),%eax
f0105515:	8b 54 24 0c          	mov    0xc(%esp),%edx
f0105519:	83 c4 14             	add    $0x14,%esp
f010551c:	5e                   	pop    %esi
f010551d:	5f                   	pop    %edi
f010551e:	5d                   	pop    %ebp
f010551f:	c3                   	ret    
f0105520:	85 f6                	test   %esi,%esi
f0105522:	89 f5                	mov    %esi,%ebp
f0105524:	75 0b                	jne    f0105531 <__umoddi3+0x91>
f0105526:	b8 01 00 00 00       	mov    $0x1,%eax
f010552b:	31 d2                	xor    %edx,%edx
f010552d:	f7 f6                	div    %esi
f010552f:	89 c5                	mov    %eax,%ebp
f0105531:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105535:	31 d2                	xor    %edx,%edx
f0105537:	f7 f5                	div    %ebp
f0105539:	89 c8                	mov    %ecx,%eax
f010553b:	f7 f5                	div    %ebp
f010553d:	eb 9c                	jmp    f01054db <__umoddi3+0x3b>
f010553f:	90                   	nop
f0105540:	89 c8                	mov    %ecx,%eax
f0105542:	89 fa                	mov    %edi,%edx
f0105544:	83 c4 14             	add    $0x14,%esp
f0105547:	5e                   	pop    %esi
f0105548:	5f                   	pop    %edi
f0105549:	5d                   	pop    %ebp
f010554a:	c3                   	ret    
f010554b:	90                   	nop
f010554c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105550:	8b 04 24             	mov    (%esp),%eax
f0105553:	be 20 00 00 00       	mov    $0x20,%esi
f0105558:	89 e9                	mov    %ebp,%ecx
f010555a:	29 ee                	sub    %ebp,%esi
f010555c:	d3 e2                	shl    %cl,%edx
f010555e:	89 f1                	mov    %esi,%ecx
f0105560:	d3 e8                	shr    %cl,%eax
f0105562:	89 e9                	mov    %ebp,%ecx
f0105564:	89 44 24 04          	mov    %eax,0x4(%esp)
f0105568:	8b 04 24             	mov    (%esp),%eax
f010556b:	09 54 24 04          	or     %edx,0x4(%esp)
f010556f:	89 fa                	mov    %edi,%edx
f0105571:	d3 e0                	shl    %cl,%eax
f0105573:	89 f1                	mov    %esi,%ecx
f0105575:	89 44 24 08          	mov    %eax,0x8(%esp)
f0105579:	8b 44 24 10          	mov    0x10(%esp),%eax
f010557d:	d3 ea                	shr    %cl,%edx
f010557f:	89 e9                	mov    %ebp,%ecx
f0105581:	d3 e7                	shl    %cl,%edi
f0105583:	89 f1                	mov    %esi,%ecx
f0105585:	d3 e8                	shr    %cl,%eax
f0105587:	89 e9                	mov    %ebp,%ecx
f0105589:	09 f8                	or     %edi,%eax
f010558b:	8b 7c 24 10          	mov    0x10(%esp),%edi
f010558f:	f7 74 24 04          	divl   0x4(%esp)
f0105593:	d3 e7                	shl    %cl,%edi
f0105595:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105599:	89 d7                	mov    %edx,%edi
f010559b:	f7 64 24 08          	mull   0x8(%esp)
f010559f:	39 d7                	cmp    %edx,%edi
f01055a1:	89 c1                	mov    %eax,%ecx
f01055a3:	89 14 24             	mov    %edx,(%esp)
f01055a6:	72 2c                	jb     f01055d4 <__umoddi3+0x134>
f01055a8:	39 44 24 0c          	cmp    %eax,0xc(%esp)
f01055ac:	72 22                	jb     f01055d0 <__umoddi3+0x130>
f01055ae:	8b 44 24 0c          	mov    0xc(%esp),%eax
f01055b2:	29 c8                	sub    %ecx,%eax
f01055b4:	19 d7                	sbb    %edx,%edi
f01055b6:	89 e9                	mov    %ebp,%ecx
f01055b8:	89 fa                	mov    %edi,%edx
f01055ba:	d3 e8                	shr    %cl,%eax
f01055bc:	89 f1                	mov    %esi,%ecx
f01055be:	d3 e2                	shl    %cl,%edx
f01055c0:	89 e9                	mov    %ebp,%ecx
f01055c2:	d3 ef                	shr    %cl,%edi
f01055c4:	09 d0                	or     %edx,%eax
f01055c6:	89 fa                	mov    %edi,%edx
f01055c8:	83 c4 14             	add    $0x14,%esp
f01055cb:	5e                   	pop    %esi
f01055cc:	5f                   	pop    %edi
f01055cd:	5d                   	pop    %ebp
f01055ce:	c3                   	ret    
f01055cf:	90                   	nop
f01055d0:	39 d7                	cmp    %edx,%edi
f01055d2:	75 da                	jne    f01055ae <__umoddi3+0x10e>
f01055d4:	8b 14 24             	mov    (%esp),%edx
f01055d7:	89 c1                	mov    %eax,%ecx
f01055d9:	2b 4c 24 08          	sub    0x8(%esp),%ecx
f01055dd:	1b 54 24 04          	sbb    0x4(%esp),%edx
f01055e1:	eb cb                	jmp    f01055ae <__umoddi3+0x10e>
f01055e3:	90                   	nop
f01055e4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01055e8:	3b 44 24 0c          	cmp    0xc(%esp),%eax
f01055ec:	0f 82 0f ff ff ff    	jb     f0105501 <__umoddi3+0x61>
f01055f2:	e9 1a ff ff ff       	jmp    f0105511 <__umoddi3+0x71>
