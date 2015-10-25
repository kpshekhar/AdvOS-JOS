
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
f0100048:	83 3d c0 be 22 f0 00 	cmpl   $0x0,0xf022bec0
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 c0 be 22 f0    	mov    %esi,0xf022bec0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 66 56 00 00       	call   f01056c7 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 80 5d 10 f0       	push   $0xf0105d80
f010006d:	e8 e1 37 00 00       	call   f0103853 <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 b1 37 00 00       	call   f010382d <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 12 76 10 f0 	movl   $0xf0107612,(%esp)
f0100083:	e8 cb 37 00 00       	call   f0103853 <cprintf>
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
f01000a1:	b8 08 d0 26 f0       	mov    $0xf026d008,%eax
f01000a6:	2d 08 ac 22 f0       	sub    $0xf022ac08,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 08 ac 22 f0       	push   $0xf022ac08
f01000b3:	e8 ea 4f 00 00       	call   f01050a2 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 72 05 00 00       	call   f010062f <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 ec 5d 10 f0       	push   $0xf0105dec
f01000ca:	e8 84 37 00 00       	call   f0103853 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 ec 12 00 00       	call   f01013c0 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 bb 2f 00 00       	call   f0103094 <env_init>
	trap_init();
f01000d9:	e8 1e 38 00 00       	call   f01038fc <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 dd 52 00 00       	call   f01053c0 <mp_init>
	lapic_init();
f01000e3:	e8 fa 55 00 00       	call   f01056e2 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 a2 36 00 00       	call   f010378f <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f01000f4:	e8 39 58 00 00       	call   f0105932 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d c8 be 22 f0 07 	cmpl   $0x7,0xf022bec8
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 a4 5d 10 f0       	push   $0xf0105da4
f010010f:	6a 59                	push   $0x59
f0100111:	68 07 5e 10 f0       	push   $0xf0105e07
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 26 53 10 f0       	mov    $0xf0105326,%eax
f0100123:	2d ac 52 10 f0       	sub    $0xf01052ac,%eax
f0100128:	50                   	push   %eax
f0100129:	68 ac 52 10 f0       	push   $0xf01052ac
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 b7 4f 00 00       	call   f01050ef <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 40 c0 22 f0       	mov    $0xf022c040,%ebx
f0100140:	eb 4e                	jmp    f0100190 <i386_init+0xf6>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 80 55 00 00       	call   f01056c7 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 40 c0 22 f0       	add    $0xf022c040,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 3a                	je     f010018d <i386_init+0xf3>
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 40 c0 22 f0       	sub    $0xf022c040,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	8d 80 00 50 23 f0    	lea    -0xfdcb000(%eax),%eax
f010016c:	a3 c4 be 22 f0       	mov    %eax,0xf022bec4
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100171:	83 ec 08             	sub    $0x8,%esp
f0100174:	68 00 70 00 00       	push   $0x7000
f0100179:	0f b6 03             	movzbl (%ebx),%eax
f010017c:	50                   	push   %eax
f010017d:	e8 ae 56 00 00       	call   f0105830 <lapic_startap>
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
f0100190:	6b 05 e4 c3 22 f0 74 	imul   $0x74,0xf022c3e4,%eax
f0100197:	05 40 c0 22 f0       	add    $0xf022c040,%eax
f010019c:	39 c3                	cmp    %eax,%ebx
f010019e:	72 a2                	jb     f0100142 <i386_init+0xa8>
	// Starting non-boot CPUs
	boot_aps();

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001a0:	83 ec 08             	sub    $0x8,%esp
f01001a3:	6a 00                	push   $0x0
f01001a5:	68 08 22 22 f0       	push   $0xf0222208
f01001aa:	e8 b8 30 00 00       	call   f0103267 <env_create>

	//ENV_CREATE(user_yield, ENV_TYPE_USER);
#endif // TEST*

	// Schedule and run the first user environment!
	sched_yield();
f01001af:	e8 c6 3e 00 00       	call   f010407a <sched_yield>

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
f01001ba:	a1 cc be 22 f0       	mov    0xf022becc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001bf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c4:	77 12                	ja     f01001d8 <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001c6:	50                   	push   %eax
f01001c7:	68 c8 5d 10 f0       	push   $0xf0105dc8
f01001cc:	6a 70                	push   $0x70
f01001ce:	68 07 5e 10 f0       	push   $0xf0105e07
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
f01001e0:	e8 e2 54 00 00       	call   f01056c7 <cpunum>
f01001e5:	83 ec 08             	sub    $0x8,%esp
f01001e8:	50                   	push   %eax
f01001e9:	68 13 5e 10 f0       	push   $0xf0105e13
f01001ee:	e8 60 36 00 00       	call   f0103853 <cprintf>

	lapic_init();
f01001f3:	e8 ea 54 00 00       	call   f01056e2 <lapic_init>
	env_init_percpu();
f01001f8:	e8 6d 2e 00 00       	call   f010306a <env_init_percpu>
	trap_init_percpu();
f01001fd:	e8 65 36 00 00       	call   f0103867 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100202:	e8 c0 54 00 00       	call   f01056c7 <cpunum>
f0100207:	6b d0 74             	imul   $0x74,%eax,%edx
f010020a:	81 c2 40 c0 22 f0    	add    $0xf022c040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100210:	b8 01 00 00 00       	mov    $0x1,%eax
f0100215:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0100219:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f0100220:	e8 0d 57 00 00       	call   f0105932 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f0100225:	e8 50 3e 00 00       	call   f010407a <sched_yield>

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
f010023a:	68 29 5e 10 f0       	push   $0xf0105e29
f010023f:	e8 0f 36 00 00       	call   f0103853 <cprintf>
	vcprintf(fmt, ap);
f0100244:	83 c4 08             	add    $0x8,%esp
f0100247:	53                   	push   %ebx
f0100248:	ff 75 10             	pushl  0x10(%ebp)
f010024b:	e8 dd 35 00 00       	call   f010382d <vcprintf>
	cprintf("\n");
f0100250:	c7 04 24 12 76 10 f0 	movl   $0xf0107612,(%esp)
f0100257:	e8 f7 35 00 00       	call   f0103853 <cprintf>
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
f010028f:	a1 44 b2 22 f0       	mov    0xf022b244,%eax
f0100294:	8d 48 01             	lea    0x1(%eax),%ecx
f0100297:	89 0d 44 b2 22 f0    	mov    %ecx,0xf022b244
f010029d:	88 90 40 b0 22 f0    	mov    %dl,-0xfdd4fc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002a3:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002a9:	75 0a                	jne    f01002b5 <cons_intr+0x35>
			cons.wpos = 0;
f01002ab:	c7 05 44 b2 22 f0 00 	movl   $0x0,0xf022b244
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
f01002db:	83 0d 00 b0 22 f0 40 	orl    $0x40,0xf022b000
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
f01002f3:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f01002f9:	89 cb                	mov    %ecx,%ebx
f01002fb:	83 e3 40             	and    $0x40,%ebx
f01002fe:	83 e0 7f             	and    $0x7f,%eax
f0100301:	85 db                	test   %ebx,%ebx
f0100303:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100306:	0f b6 d2             	movzbl %dl,%edx
f0100309:	0f b6 82 c0 5f 10 f0 	movzbl -0xfefa040(%edx),%eax
f0100310:	83 c8 40             	or     $0x40,%eax
f0100313:	0f b6 c0             	movzbl %al,%eax
f0100316:	f7 d0                	not    %eax
f0100318:	21 c8                	and    %ecx,%eax
f010031a:	a3 00 b0 22 f0       	mov    %eax,0xf022b000
		return 0;
f010031f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100324:	e9 a1 00 00 00       	jmp    f01003ca <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f0100329:	8b 0d 00 b0 22 f0    	mov    0xf022b000,%ecx
f010032f:	f6 c1 40             	test   $0x40,%cl
f0100332:	74 0e                	je     f0100342 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100334:	83 c8 80             	or     $0xffffff80,%eax
f0100337:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f0100339:	83 e1 bf             	and    $0xffffffbf,%ecx
f010033c:	89 0d 00 b0 22 f0    	mov    %ecx,0xf022b000
	}

	shift |= shiftcode[data];
f0100342:	0f b6 c2             	movzbl %dl,%eax
f0100345:	0f b6 90 c0 5f 10 f0 	movzbl -0xfefa040(%eax),%edx
f010034c:	0b 15 00 b0 22 f0    	or     0xf022b000,%edx
	shift ^= togglecode[data];
f0100352:	0f b6 88 c0 5e 10 f0 	movzbl -0xfefa140(%eax),%ecx
f0100359:	31 ca                	xor    %ecx,%edx
f010035b:	89 15 00 b0 22 f0    	mov    %edx,0xf022b000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100361:	89 d1                	mov    %edx,%ecx
f0100363:	83 e1 03             	and    $0x3,%ecx
f0100366:	8b 0c 8d 80 5e 10 f0 	mov    -0xfefa180(,%ecx,4),%ecx
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
f01003a6:	68 43 5e 10 f0       	push   $0xf0105e43
f01003ab:	e8 a3 34 00 00       	call   f0103853 <cprintf>
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
f010048b:	0f b7 05 48 b2 22 f0 	movzwl 0xf022b248,%eax
f0100492:	66 85 c0             	test   %ax,%ax
f0100495:	0f 84 e6 00 00 00    	je     f0100581 <cons_putc+0x1b2>
			crt_pos--;
f010049b:	83 e8 01             	sub    $0x1,%eax
f010049e:	66 a3 48 b2 22 f0    	mov    %ax,0xf022b248
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a4:	0f b7 c0             	movzwl %ax,%eax
f01004a7:	66 81 e7 00 ff       	and    $0xff00,%di
f01004ac:	83 cf 20             	or     $0x20,%edi
f01004af:	8b 15 4c b2 22 f0    	mov    0xf022b24c,%edx
f01004b5:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004b9:	eb 78                	jmp    f0100533 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004bb:	66 83 05 48 b2 22 f0 	addw   $0x50,0xf022b248
f01004c2:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004c3:	0f b7 05 48 b2 22 f0 	movzwl 0xf022b248,%eax
f01004ca:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004d0:	c1 e8 16             	shr    $0x16,%eax
f01004d3:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004d6:	c1 e0 04             	shl    $0x4,%eax
f01004d9:	66 a3 48 b2 22 f0    	mov    %ax,0xf022b248
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
f0100515:	0f b7 05 48 b2 22 f0 	movzwl 0xf022b248,%eax
f010051c:	8d 50 01             	lea    0x1(%eax),%edx
f010051f:	66 89 15 48 b2 22 f0 	mov    %dx,0xf022b248
f0100526:	0f b7 c0             	movzwl %ax,%eax
f0100529:	8b 15 4c b2 22 f0    	mov    0xf022b24c,%edx
f010052f:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100533:	66 81 3d 48 b2 22 f0 	cmpw   $0x7cf,0xf022b248
f010053a:	cf 07 
f010053c:	76 43                	jbe    f0100581 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f010053e:	a1 4c b2 22 f0       	mov    0xf022b24c,%eax
f0100543:	83 ec 04             	sub    $0x4,%esp
f0100546:	68 00 0f 00 00       	push   $0xf00
f010054b:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100551:	52                   	push   %edx
f0100552:	50                   	push   %eax
f0100553:	e8 97 4b 00 00       	call   f01050ef <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100558:	8b 15 4c b2 22 f0    	mov    0xf022b24c,%edx
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
f0100579:	66 83 2d 48 b2 22 f0 	subw   $0x50,0xf022b248
f0100580:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100581:	8b 0d 50 b2 22 f0    	mov    0xf022b250,%ecx
f0100587:	b8 0e 00 00 00       	mov    $0xe,%eax
f010058c:	89 ca                	mov    %ecx,%edx
f010058e:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f010058f:	0f b7 1d 48 b2 22 f0 	movzwl 0xf022b248,%ebx
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
f01005b7:	80 3d 54 b2 22 f0 00 	cmpb   $0x0,0xf022b254
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
f01005f5:	a1 40 b2 22 f0       	mov    0xf022b240,%eax
f01005fa:	3b 05 44 b2 22 f0    	cmp    0xf022b244,%eax
f0100600:	74 26                	je     f0100628 <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100602:	8d 50 01             	lea    0x1(%eax),%edx
f0100605:	89 15 40 b2 22 f0    	mov    %edx,0xf022b240
f010060b:	0f b6 88 40 b0 22 f0 	movzbl -0xfdd4fc0(%eax),%ecx
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
f010061c:	c7 05 40 b2 22 f0 00 	movl   $0x0,0xf022b240
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
f0100655:	c7 05 50 b2 22 f0 b4 	movl   $0x3b4,0xf022b250
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
f010066d:	c7 05 50 b2 22 f0 d4 	movl   $0x3d4,0xf022b250
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
f010067c:	8b 3d 50 b2 22 f0    	mov    0xf022b250,%edi
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
f01006a3:	89 35 4c b2 22 f0    	mov    %esi,0xf022b24c

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
f01006b0:	66 a3 48 b2 22 f0    	mov    %ax,0xf022b248

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
f01006cb:	e8 4a 30 00 00       	call   f010371a <irq_setmask_8259A>
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
f010071d:	88 0d 54 b2 22 f0    	mov    %cl,0xf022b254
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
f0100730:	68 4f 5e 10 f0       	push   $0xf0105e4f
f0100735:	e8 19 31 00 00       	call   f0103853 <cprintf>
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
f0100776:	68 c0 60 10 f0       	push   $0xf01060c0
f010077b:	68 de 60 10 f0       	push   $0xf01060de
f0100780:	68 e3 60 10 f0       	push   $0xf01060e3
f0100785:	e8 c9 30 00 00       	call   f0103853 <cprintf>
f010078a:	83 c4 0c             	add    $0xc,%esp
f010078d:	68 84 61 10 f0       	push   $0xf0106184
f0100792:	68 ec 60 10 f0       	push   $0xf01060ec
f0100797:	68 e3 60 10 f0       	push   $0xf01060e3
f010079c:	e8 b2 30 00 00       	call   f0103853 <cprintf>
f01007a1:	83 c4 0c             	add    $0xc,%esp
f01007a4:	68 f5 60 10 f0       	push   $0xf01060f5
f01007a9:	68 12 61 10 f0       	push   $0xf0106112
f01007ae:	68 e3 60 10 f0       	push   $0xf01060e3
f01007b3:	e8 9b 30 00 00       	call   f0103853 <cprintf>
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
f01007c5:	68 1d 61 10 f0       	push   $0xf010611d
f01007ca:	e8 84 30 00 00       	call   f0103853 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007cf:	83 c4 08             	add    $0x8,%esp
f01007d2:	68 0c 00 10 00       	push   $0x10000c
f01007d7:	68 ac 61 10 f0       	push   $0xf01061ac
f01007dc:	e8 72 30 00 00       	call   f0103853 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01007e1:	83 c4 0c             	add    $0xc,%esp
f01007e4:	68 0c 00 10 00       	push   $0x10000c
f01007e9:	68 0c 00 10 f0       	push   $0xf010000c
f01007ee:	68 d4 61 10 f0       	push   $0xf01061d4
f01007f3:	e8 5b 30 00 00       	call   f0103853 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01007f8:	83 c4 0c             	add    $0xc,%esp
f01007fb:	68 65 5d 10 00       	push   $0x105d65
f0100800:	68 65 5d 10 f0       	push   $0xf0105d65
f0100805:	68 f8 61 10 f0       	push   $0xf01061f8
f010080a:	e8 44 30 00 00       	call   f0103853 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010080f:	83 c4 0c             	add    $0xc,%esp
f0100812:	68 08 ac 22 00       	push   $0x22ac08
f0100817:	68 08 ac 22 f0       	push   $0xf022ac08
f010081c:	68 1c 62 10 f0       	push   $0xf010621c
f0100821:	e8 2d 30 00 00       	call   f0103853 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f0100826:	83 c4 0c             	add    $0xc,%esp
f0100829:	68 08 d0 26 00       	push   $0x26d008
f010082e:	68 08 d0 26 f0       	push   $0xf026d008
f0100833:	68 40 62 10 f0       	push   $0xf0106240
f0100838:	e8 16 30 00 00       	call   f0103853 <cprintf>
f010083d:	b8 07 d4 26 f0       	mov    $0xf026d407,%eax
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
f010085e:	68 64 62 10 f0       	push   $0xf0106264
f0100863:	e8 eb 2f 00 00       	call   f0103853 <cprintf>
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
f010087a:	68 36 61 10 f0       	push   $0xf0106136
f010087f:	e8 cf 2f 00 00       	call   f0103853 <cprintf>
	
	
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
f0100894:	e8 8b 3d 00 00       	call   f0104624 <debuginfo_eip>
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
f01008be:	68 90 62 10 f0       	push   $0xf0106290
f01008c3:	e8 8b 2f 00 00       	call   f0103853 <cprintf>
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
f01008e7:	68 d4 62 10 f0       	push   $0xf01062d4
f01008ec:	e8 62 2f 00 00       	call   f0103853 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f01008f1:	c7 04 24 f8 62 10 f0 	movl   $0xf01062f8,(%esp)
f01008f8:	e8 56 2f 00 00       	call   f0103853 <cprintf>

	if (tf != NULL)
f01008fd:	83 c4 10             	add    $0x10,%esp
f0100900:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100904:	74 0e                	je     f0100914 <monitor+0x36>
		print_trapframe(tf);
f0100906:	83 ec 0c             	sub    $0xc,%esp
f0100909:	ff 75 08             	pushl  0x8(%ebp)
f010090c:	e8 1d 31 00 00       	call   f0103a2e <print_trapframe>
f0100911:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f0100914:	83 ec 0c             	sub    $0xc,%esp
f0100917:	68 48 61 10 f0       	push   $0xf0106148
f010091c:	e8 2a 45 00 00       	call   f0104e4b <readline>
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
f0100950:	68 4c 61 10 f0       	push   $0xf010614c
f0100955:	e8 0b 47 00 00       	call   f0105065 <strchr>
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
f0100970:	68 51 61 10 f0       	push   $0xf0106151
f0100975:	e8 d9 2e 00 00       	call   f0103853 <cprintf>
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
f0100999:	68 4c 61 10 f0       	push   $0xf010614c
f010099e:	e8 c2 46 00 00       	call   f0105065 <strchr>
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
f01009c7:	ff 34 85 20 63 10 f0 	pushl  -0xfef9ce0(,%eax,4)
f01009ce:	ff 75 a8             	pushl  -0x58(%ebp)
f01009d1:	e8 31 46 00 00       	call   f0105007 <strcmp>
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
f01009eb:	ff 14 85 28 63 10 f0 	call   *-0xfef9cd8(,%eax,4)
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
f0100a0d:	68 6e 61 10 f0       	push   $0xf010616e
f0100a12:	e8 3c 2e 00 00       	call   f0103853 <cprintf>
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
f0100a3d:	3b 0d c8 be 22 f0    	cmp    0xf022bec8,%ecx
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
f0100a4c:	68 a4 5d 10 f0       	push   $0xf0105da4
f0100a51:	68 10 04 00 00       	push   $0x410
f0100a56:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0100a8b:	83 3d 5c b2 22 f0 00 	cmpl   $0x0,0xf022b25c
f0100a92:	75 11                	jne    f0100aa5 <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100a94:	ba 07 e0 26 f0       	mov    $0xf026e007,%edx
f0100a99:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100a9f:	89 15 5c b2 22 f0    	mov    %edx,0xf022b25c
	}
	
	if (n==0){
f0100aa5:	85 c0                	test   %eax,%eax
f0100aa7:	75 06                	jne    f0100aaf <boot_alloc+0x24>
	return nextfree;
f0100aa9:	a1 5c b2 22 f0       	mov    0xf022b25c,%eax
f0100aae:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100aaf:	8b 0d 5c b2 22 f0    	mov    0xf022b25c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100ab5:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100aba:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100abf:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100ac2:	89 15 5c b2 22 f0    	mov    %edx,0xf022b25c
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
f0100ad7:	68 c8 5d 10 f0       	push   $0xf0105dc8
f0100adc:	6a 71                	push   $0x71
f0100ade:	68 35 6d 10 f0       	push   $0xf0106d35
f0100ae3:	e8 58 f5 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100ae8:	a1 c8 be 22 f0       	mov    0xf022bec8,%eax
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
f0100b1d:	68 44 63 10 f0       	push   $0xf0106344
f0100b22:	68 44 03 00 00       	push   $0x344
f0100b27:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0100b3f:	2b 15 d0 be 22 f0    	sub    0xf022bed0,%edx
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
f0100b75:	a3 64 b2 22 f0       	mov    %eax,0xf022b264
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
f0100b7f:	8b 1d 64 b2 22 f0    	mov    0xf022b264,%ebx
f0100b85:	eb 53                	jmp    f0100bda <check_page_free_list+0xd9>
f0100b87:	89 d8                	mov    %ebx,%eax
f0100b89:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
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
f0100ba3:	3b 15 c8 be 22 f0    	cmp    0xf022bec8,%edx
f0100ba9:	72 12                	jb     f0100bbd <check_page_free_list+0xbc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bab:	50                   	push   %eax
f0100bac:	68 a4 5d 10 f0       	push   $0xf0105da4
f0100bb1:	6a 58                	push   $0x58
f0100bb3:	68 41 6d 10 f0       	push   $0xf0106d41
f0100bb8:	e8 83 f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100bbd:	83 ec 04             	sub    $0x4,%esp
f0100bc0:	68 80 00 00 00       	push   $0x80
f0100bc5:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100bca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bcf:	50                   	push   %eax
f0100bd0:	e8 cd 44 00 00       	call   f01050a2 <memset>
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
f0100beb:	8b 15 64 b2 22 f0    	mov    0xf022b264,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100bf1:	8b 0d d0 be 22 f0    	mov    0xf022bed0,%ecx
		assert(pp < pages + npages);
f0100bf7:	a1 c8 be 22 f0       	mov    0xf022bec8,%eax
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
f0100c1c:	68 4f 6d 10 f0       	push   $0xf0106d4f
f0100c21:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100c26:	68 5e 03 00 00       	push   $0x35e
f0100c2b:	68 35 6d 10 f0       	push   $0xf0106d35
f0100c30:	e8 0b f4 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c35:	39 ca                	cmp    %ecx,%edx
f0100c37:	72 19                	jb     f0100c52 <check_page_free_list+0x151>
f0100c39:	68 70 6d 10 f0       	push   $0xf0106d70
f0100c3e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100c43:	68 5f 03 00 00       	push   $0x35f
f0100c48:	68 35 6d 10 f0       	push   $0xf0106d35
f0100c4d:	e8 ee f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c52:	89 d0                	mov    %edx,%eax
f0100c54:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c57:	a8 07                	test   $0x7,%al
f0100c59:	74 19                	je     f0100c74 <check_page_free_list+0x173>
f0100c5b:	68 68 63 10 f0       	push   $0xf0106368
f0100c60:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100c65:	68 60 03 00 00       	push   $0x360
f0100c6a:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0100c7e:	68 84 6d 10 f0       	push   $0xf0106d84
f0100c83:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100c88:	68 63 03 00 00       	push   $0x363
f0100c8d:	68 35 6d 10 f0       	push   $0xf0106d35
f0100c92:	e8 a9 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100c97:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100c9c:	75 19                	jne    f0100cb7 <check_page_free_list+0x1b6>
f0100c9e:	68 95 6d 10 f0       	push   $0xf0106d95
f0100ca3:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100ca8:	68 64 03 00 00       	push   $0x364
f0100cad:	68 35 6d 10 f0       	push   $0xf0106d35
f0100cb2:	e8 89 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cb7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100cbc:	75 19                	jne    f0100cd7 <check_page_free_list+0x1d6>
f0100cbe:	68 9c 63 10 f0       	push   $0xf010639c
f0100cc3:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100cc8:	68 65 03 00 00       	push   $0x365
f0100ccd:	68 35 6d 10 f0       	push   $0xf0106d35
f0100cd2:	e8 69 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cd7:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100cdc:	75 19                	jne    f0100cf7 <check_page_free_list+0x1f6>
f0100cde:	68 ae 6d 10 f0       	push   $0xf0106dae
f0100ce3:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100ce8:	68 66 03 00 00       	push   $0x366
f0100ced:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0100d10:	68 a4 5d 10 f0       	push   $0xf0105da4
f0100d15:	6a 58                	push   $0x58
f0100d17:	68 41 6d 10 f0       	push   $0xf0106d41
f0100d1c:	e8 1f f3 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100d21:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0100d27:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d2a:	0f 86 cf 00 00 00    	jbe    f0100dff <check_page_free_list+0x2fe>
f0100d30:	68 c0 63 10 f0       	push   $0xf01063c0
f0100d35:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100d3a:	68 67 03 00 00       	push   $0x367
f0100d3f:	68 35 6d 10 f0       	push   $0xf0106d35
f0100d44:	e8 f7 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d49:	68 c8 6d 10 f0       	push   $0xf0106dc8
f0100d4e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100d53:	68 69 03 00 00       	push   $0x369
f0100d58:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0100d7c:	68 e5 6d 10 f0       	push   $0xf0106de5
f0100d81:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100d86:	68 71 03 00 00       	push   $0x371
f0100d8b:	68 35 6d 10 f0       	push   $0xf0106d35
f0100d90:	e8 ab f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100d95:	85 ff                	test   %edi,%edi
f0100d97:	7f 19                	jg     f0100db2 <check_page_free_list+0x2b1>
f0100d99:	68 f7 6d 10 f0       	push   $0xf0106df7
f0100d9e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0100da3:	68 72 03 00 00       	push   $0x372
f0100da8:	68 35 6d 10 f0       	push   $0xf0106d35
f0100dad:	e8 8e f2 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100db2:	83 ec 08             	sub    $0x8,%esp
f0100db5:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100db9:	50                   	push   %eax
f0100dba:	68 08 64 10 f0       	push   $0xf0106408
f0100dbf:	e8 8f 2a 00 00       	call   f0103853 <cprintf>
f0100dc4:	eb 49                	jmp    f0100e0f <check_page_free_list+0x30e>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dc6:	a1 64 b2 22 f0       	mov    0xf022b264,%eax
f0100dcb:	85 c0                	test   %eax,%eax
f0100dcd:	0f 85 5e fd ff ff    	jne    f0100b31 <check_page_free_list+0x30>
f0100dd3:	e9 42 fd ff ff       	jmp    f0100b1a <check_page_free_list+0x19>
f0100dd8:	83 3d 64 b2 22 f0 00 	cmpl   $0x0,0xf022b264
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
f0100e1e:	8b 15 d0 be 22 f0    	mov    0xf022bed0,%edx
f0100e24:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100e27:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e2d:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e33:	83 c0 01             	add    $0x1,%eax
f0100e36:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
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
f0100e47:	c7 05 64 b2 22 f0 00 	movl   $0x0,0xf022b264
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
f0100e6c:	68 08 6e 10 f0       	push   $0xf0106e08
f0100e71:	e8 dd 29 00 00       	call   f0103853 <cprintf>
			continue;	
f0100e76:	83 c4 10             	add    $0x10,%esp
f0100e79:	eb 52                	jmp    f0100ecd <page_init+0xb6>
f0100e7b:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0100e82:	8b 15 d0 be 22 f0    	mov    0xf022bed0,%edx
f0100e88:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100e8f:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0100e96:	83 3d 64 b2 22 f0 00 	cmpl   $0x0,0xf022b264
f0100e9d:	75 10                	jne    f0100eaf <page_init+0x98>
			page_free_list = &pages[i];
f0100e9f:	89 c2                	mov    %eax,%edx
f0100ea1:	03 15 d0 be 22 f0    	add    0xf022bed0,%edx
f0100ea7:	89 15 64 b2 22 f0    	mov    %edx,0xf022b264
f0100ead:	eb 16                	jmp    f0100ec5 <page_init+0xae>
		} else {
			prev->pp_link = &pages[i];
f0100eaf:	89 c2                	mov    %eax,%edx
f0100eb1:	03 15 d0 be 22 f0    	add    0xf022bed0,%edx
f0100eb7:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0100eb9:	8b 15 d0 be 22 f0    	mov    0xf022bed0,%edx
f0100ebf:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0100ec2:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0100ec5:	03 05 d0 be 22 f0    	add    0xf022bed0,%eax
f0100ecb:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100ecd:	83 c3 01             	add    $0x1,%ebx
f0100ed0:	83 c6 08             	add    $0x8,%esi
f0100ed3:	3b 1d 68 b2 22 f0    	cmp    0xf022b268,%ebx
f0100ed9:	72 87                	jb     f0100e62 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100edb:	8d 04 dd f8 ff ff ff 	lea    -0x8(,%ebx,8),%eax
f0100ee2:	03 05 d0 be 22 f0    	add    0xf022bed0,%eax
f0100ee8:	a3 58 b2 22 f0       	mov    %eax,0xf022b258
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
f0100eff:	68 c8 5d 10 f0       	push   $0xf0105dc8
f0100f04:	68 75 01 00 00       	push   $0x175
f0100f09:	68 35 6d 10 f0       	push   $0xf0106d35
f0100f0e:	e8 2d f1 ff ff       	call   f0100040 <_panic>
f0100f13:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100f18:	c1 e8 0c             	shr    $0xc,%eax
f0100f1b:	8b 1d 58 b2 22 f0    	mov    0xf022b258,%ebx
f0100f21:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f28:	eb 2c                	jmp    f0100f56 <page_init+0x13f>
		pages[i].pp_ref = 0;
f0100f2a:	89 d1                	mov    %edx,%ecx
f0100f2c:	03 0d d0 be 22 f0    	add    0xf022bed0,%ecx
f0100f32:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100f38:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100f3e:	89 d1                	mov    %edx,%ecx
f0100f40:	03 0d d0 be 22 f0    	add    0xf022bed0,%ecx
f0100f46:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100f48:	89 d3                	mov    %edx,%ebx
f0100f4a:	03 1d d0 be 22 f0    	add    0xf022bed0,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f50:	83 c0 01             	add    $0x1,%eax
f0100f53:	83 c2 08             	add    $0x8,%edx
f0100f56:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
f0100f5c:	72 cc                	jb     f0100f2a <page_init+0x113>
f0100f5e:	89 1d 58 b2 22 f0    	mov    %ebx,0xf022b258
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f64:	83 ec 08             	sub    $0x8,%esp
f0100f67:	ff 35 d0 be 22 f0    	pushl  0xf022bed0
f0100f6d:	68 30 64 10 f0       	push   $0xf0106430
f0100f72:	e8 dc 28 00 00       	call   f0103853 <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f77:	83 c4 08             	add    $0x8,%esp
f0100f7a:	a1 c8 be 22 f0       	mov    0xf022bec8,%eax
f0100f7f:	8d 04 c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%eax
f0100f86:	03 05 d0 be 22 f0    	add    0xf022bed0,%eax
f0100f8c:	50                   	push   %eax
f0100f8d:	68 1e 6e 10 f0       	push   $0xf0106e1e
f0100f92:	e8 bc 28 00 00       	call   f0103853 <cprintf>
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
f0100fa9:	8b 1d 64 b2 22 f0    	mov    0xf022b264,%ebx
f0100faf:	85 db                	test   %ebx,%ebx
f0100fb1:	74 5e                	je     f0101011 <page_alloc+0x6f>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100fb3:	8b 03                	mov    (%ebx),%eax
f0100fb5:	a3 64 b2 22 f0       	mov    %eax,0xf022b264
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
f0100fc8:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
f0100fce:	c1 f8 03             	sar    $0x3,%eax
f0100fd1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fd4:	89 c2                	mov    %eax,%edx
f0100fd6:	c1 ea 0c             	shr    $0xc,%edx
f0100fd9:	3b 15 c8 be 22 f0    	cmp    0xf022bec8,%edx
f0100fdf:	72 12                	jb     f0100ff3 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fe1:	50                   	push   %eax
f0100fe2:	68 a4 5d 10 f0       	push   $0xf0105da4
f0100fe7:	6a 58                	push   $0x58
f0100fe9:	68 41 6d 10 f0       	push   $0xf0106d41
f0100fee:	e8 4d f0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0100ff3:	83 ec 04             	sub    $0x4,%esp
f0100ff6:	68 00 10 00 00       	push   $0x1000
f0100ffb:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0100ffd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101002:	50                   	push   %eax
f0101003:	e8 9a 40 00 00       	call   f01050a2 <memset>
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
f010102b:	68 5c 64 10 f0       	push   $0xf010645c
f0101030:	68 ad 01 00 00       	push   $0x1ad
f0101035:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101046:	68 9c 64 10 f0       	push   $0xf010649c
f010104b:	68 b4 01 00 00       	push   $0x1b4
f0101050:	68 35 6d 10 f0       	push   $0xf0106d35
f0101055:	e8 e6 ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f010105a:	8b 15 64 b2 22 f0    	mov    0xf022b264,%edx
f0101060:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101062:	a3 64 b2 22 f0       	mov    %eax,0xf022b264
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
f01010b7:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
f01010bd:	72 15                	jb     f01010d4 <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010bf:	53                   	push   %ebx
f01010c0:	68 a4 5d 10 f0       	push   $0xf0105da4
f01010c5:	68 f5 01 00 00       	push   $0x1f5
f01010ca:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101103:	2b 1d d0 be 22 f0    	sub    0xf022bed0,%ebx
f0101109:	c1 fb 03             	sar    $0x3,%ebx
f010110c:	c1 e3 0c             	shl    $0xc,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010110f:	89 d8                	mov    %ebx,%eax
f0101111:	c1 e8 0c             	shr    $0xc,%eax
f0101114:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
f010111a:	72 12                	jb     f010112e <pgdir_walk+0x9e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010111c:	53                   	push   %ebx
f010111d:	68 a4 5d 10 f0       	push   $0xf0105da4
f0101122:	6a 58                	push   $0x58
f0101124:	68 41 6d 10 f0       	push   $0xf0106d41
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
f010113f:	e8 5e 3f 00 00       	call   f01050a2 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101144:	2b 3d d0 be 22 f0    	sub    0xf022bed0,%edi
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
f01011cb:	68 d0 64 10 f0       	push   $0xf01064d0
f01011d0:	68 2b 02 00 00       	push   $0x22b
f01011d5:	68 35 6d 10 f0       	push   $0xf0106d35
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
f010122c:	a1 d0 be 22 f0       	mov    0xf022bed0,%eax
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
f0101253:	e8 6f 44 00 00       	call   f01056c7 <cpunum>
f0101258:	6b c0 74             	imul   $0x74,%eax,%eax
f010125b:	83 b8 48 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fb8(%eax)
f0101262:	74 16                	je     f010127a <tlb_invalidate+0x2d>
f0101264:	e8 5e 44 00 00       	call   f01056c7 <cpunum>
f0101269:	6b c0 74             	imul   $0x74,%eax,%eax
f010126c:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
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
f01012fc:	2b 15 d0 be 22 f0    	sub    0xf022bed0,%edx
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
f0101331:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
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
f0101358:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
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
f01013a7:	a1 cc be 22 f0       	mov    0xf022becc,%eax
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
f01013cb:	e8 22 23 00 00       	call   f01036f2 <mc146818_read>
f01013d0:	89 c3                	mov    %eax,%ebx
f01013d2:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01013d9:	e8 14 23 00 00       	call   f01036f2 <mc146818_read>
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
f01013f4:	a3 68 b2 22 f0       	mov    %eax,0xf022b268
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013f9:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101400:	e8 ed 22 00 00       	call   f01036f2 <mc146818_read>
f0101405:	89 c3                	mov    %eax,%ebx
f0101407:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f010140e:	e8 df 22 00 00       	call   f01036f2 <mc146818_read>
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
f0101436:	89 15 c8 be 22 f0    	mov    %edx,0xf022bec8
f010143c:	eb 0c                	jmp    f010144a <mem_init+0x8a>
	else
		npages = npages_basemem;
f010143e:	8b 15 68 b2 22 f0    	mov    0xf022b268,%edx
f0101444:	89 15 c8 be 22 f0    	mov    %edx,0xf022bec8

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
f0101451:	a1 68 b2 22 f0       	mov    0xf022b268,%eax
f0101456:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101459:	c1 e8 0a             	shr    $0xa,%eax
f010145c:	50                   	push   %eax
		npages * PGSIZE / 1024,
f010145d:	a1 c8 be 22 f0       	mov    0xf022bec8,%eax
f0101462:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101465:	c1 e8 0a             	shr    $0xa,%eax
f0101468:	50                   	push   %eax
f0101469:	68 1c 65 10 f0       	push   $0xf010651c
f010146e:	e8 e0 23 00 00       	call   f0103853 <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101473:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101478:	e8 0e f6 ff ff       	call   f0100a8b <boot_alloc>
f010147d:	a3 cc be 22 f0       	mov    %eax,0xf022becc
	memset(kern_pgdir, 0, PGSIZE);
f0101482:	83 c4 0c             	add    $0xc,%esp
f0101485:	68 00 10 00 00       	push   $0x1000
f010148a:	6a 00                	push   $0x0
f010148c:	50                   	push   %eax
f010148d:	e8 10 3c 00 00       	call   f01050a2 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101492:	a1 cc be 22 f0       	mov    0xf022becc,%eax
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
f01014a2:	68 c8 5d 10 f0       	push   $0xf0105dc8
f01014a7:	68 98 00 00 00       	push   $0x98
f01014ac:	68 35 6d 10 f0       	push   $0xf0106d35
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
f01014c5:	a1 c8 be 22 f0       	mov    0xf022bec8,%eax
f01014ca:	c1 e0 03             	shl    $0x3,%eax
f01014cd:	e8 b9 f5 ff ff       	call   f0100a8b <boot_alloc>
f01014d2:	a3 d0 be 22 f0       	mov    %eax,0xf022bed0
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f01014d7:	83 ec 04             	sub    $0x4,%esp
f01014da:	8b 0d c8 be 22 f0    	mov    0xf022bec8,%ecx
f01014e0:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f01014e7:	52                   	push   %edx
f01014e8:	6a 00                	push   $0x0
f01014ea:	50                   	push   %eax
f01014eb:	e8 b2 3b 00 00       	call   f01050a2 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f01014f0:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f01014f5:	e8 91 f5 ff ff       	call   f0100a8b <boot_alloc>
f01014fa:	a3 6c b2 22 f0       	mov    %eax,0xf022b26c
	memset(envs,0,sizeof(struct Env)*NENV);
f01014ff:	83 c4 0c             	add    $0xc,%esp
f0101502:	68 00 f0 01 00       	push   $0x1f000
f0101507:	6a 00                	push   $0x0
f0101509:	50                   	push   %eax
f010150a:	e8 93 3b 00 00       	call   f01050a2 <memset>
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
f0101521:	83 3d d0 be 22 f0 00 	cmpl   $0x0,0xf022bed0
f0101528:	75 17                	jne    f0101541 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f010152a:	83 ec 04             	sub    $0x4,%esp
f010152d:	68 35 6e 10 f0       	push   $0xf0106e35
f0101532:	68 84 03 00 00       	push   $0x384
f0101537:	68 35 6d 10 f0       	push   $0xf0106d35
f010153c:	e8 ff ea ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101541:	a1 64 b2 22 f0       	mov    0xf022b264,%eax
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
f0101569:	68 50 6e 10 f0       	push   $0xf0106e50
f010156e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101573:	68 8c 03 00 00       	push   $0x38c
f0101578:	68 35 6d 10 f0       	push   $0xf0106d35
f010157d:	e8 be ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101582:	83 ec 0c             	sub    $0xc,%esp
f0101585:	6a 00                	push   $0x0
f0101587:	e8 16 fa ff ff       	call   f0100fa2 <page_alloc>
f010158c:	89 c6                	mov    %eax,%esi
f010158e:	83 c4 10             	add    $0x10,%esp
f0101591:	85 c0                	test   %eax,%eax
f0101593:	75 19                	jne    f01015ae <mem_init+0x1ee>
f0101595:	68 66 6e 10 f0       	push   $0xf0106e66
f010159a:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010159f:	68 8d 03 00 00       	push   $0x38d
f01015a4:	68 35 6d 10 f0       	push   $0xf0106d35
f01015a9:	e8 92 ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015ae:	83 ec 0c             	sub    $0xc,%esp
f01015b1:	6a 00                	push   $0x0
f01015b3:	e8 ea f9 ff ff       	call   f0100fa2 <page_alloc>
f01015b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015bb:	83 c4 10             	add    $0x10,%esp
f01015be:	85 c0                	test   %eax,%eax
f01015c0:	75 19                	jne    f01015db <mem_init+0x21b>
f01015c2:	68 7c 6e 10 f0       	push   $0xf0106e7c
f01015c7:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01015cc:	68 8e 03 00 00       	push   $0x38e
f01015d1:	68 35 6d 10 f0       	push   $0xf0106d35
f01015d6:	e8 65 ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015db:	39 f7                	cmp    %esi,%edi
f01015dd:	75 19                	jne    f01015f8 <mem_init+0x238>
f01015df:	68 92 6e 10 f0       	push   $0xf0106e92
f01015e4:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01015e9:	68 91 03 00 00       	push   $0x391
f01015ee:	68 35 6d 10 f0       	push   $0xf0106d35
f01015f3:	e8 48 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015f8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01015fb:	39 c7                	cmp    %eax,%edi
f01015fd:	74 04                	je     f0101603 <mem_init+0x243>
f01015ff:	39 c6                	cmp    %eax,%esi
f0101601:	75 19                	jne    f010161c <mem_init+0x25c>
f0101603:	68 58 65 10 f0       	push   $0xf0106558
f0101608:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010160d:	68 92 03 00 00       	push   $0x392
f0101612:	68 35 6d 10 f0       	push   $0xf0106d35
f0101617:	e8 24 ea ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010161c:	8b 0d d0 be 22 f0    	mov    0xf022bed0,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101622:	8b 15 c8 be 22 f0    	mov    0xf022bec8,%edx
f0101628:	c1 e2 0c             	shl    $0xc,%edx
f010162b:	89 f8                	mov    %edi,%eax
f010162d:	29 c8                	sub    %ecx,%eax
f010162f:	c1 f8 03             	sar    $0x3,%eax
f0101632:	c1 e0 0c             	shl    $0xc,%eax
f0101635:	39 d0                	cmp    %edx,%eax
f0101637:	72 19                	jb     f0101652 <mem_init+0x292>
f0101639:	68 a4 6e 10 f0       	push   $0xf0106ea4
f010163e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101643:	68 93 03 00 00       	push   $0x393
f0101648:	68 35 6d 10 f0       	push   $0xf0106d35
f010164d:	e8 ee e9 ff ff       	call   f0100040 <_panic>
f0101652:	89 f0                	mov    %esi,%eax
f0101654:	29 c8                	sub    %ecx,%eax
f0101656:	c1 f8 03             	sar    $0x3,%eax
f0101659:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f010165c:	39 c2                	cmp    %eax,%edx
f010165e:	77 19                	ja     f0101679 <mem_init+0x2b9>
f0101660:	68 c1 6e 10 f0       	push   $0xf0106ec1
f0101665:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010166a:	68 94 03 00 00       	push   $0x394
f010166f:	68 35 6d 10 f0       	push   $0xf0106d35
f0101674:	e8 c7 e9 ff ff       	call   f0100040 <_panic>
f0101679:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010167c:	29 c8                	sub    %ecx,%eax
f010167e:	c1 f8 03             	sar    $0x3,%eax
f0101681:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f0101684:	39 c2                	cmp    %eax,%edx
f0101686:	77 19                	ja     f01016a1 <mem_init+0x2e1>
f0101688:	68 de 6e 10 f0       	push   $0xf0106ede
f010168d:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101692:	68 95 03 00 00       	push   $0x395
f0101697:	68 35 6d 10 f0       	push   $0xf0106d35
f010169c:	e8 9f e9 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016a1:	a1 64 b2 22 f0       	mov    0xf022b264,%eax
f01016a6:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016a9:	c7 05 64 b2 22 f0 00 	movl   $0x0,0xf022b264
f01016b0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016b3:	83 ec 0c             	sub    $0xc,%esp
f01016b6:	6a 00                	push   $0x0
f01016b8:	e8 e5 f8 ff ff       	call   f0100fa2 <page_alloc>
f01016bd:	83 c4 10             	add    $0x10,%esp
f01016c0:	85 c0                	test   %eax,%eax
f01016c2:	74 19                	je     f01016dd <mem_init+0x31d>
f01016c4:	68 fb 6e 10 f0       	push   $0xf0106efb
f01016c9:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01016ce:	68 9c 03 00 00       	push   $0x39c
f01016d3:	68 35 6d 10 f0       	push   $0xf0106d35
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
f010170e:	68 50 6e 10 f0       	push   $0xf0106e50
f0101713:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101718:	68 a3 03 00 00       	push   $0x3a3
f010171d:	68 35 6d 10 f0       	push   $0xf0106d35
f0101722:	e8 19 e9 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101727:	83 ec 0c             	sub    $0xc,%esp
f010172a:	6a 00                	push   $0x0
f010172c:	e8 71 f8 ff ff       	call   f0100fa2 <page_alloc>
f0101731:	89 c7                	mov    %eax,%edi
f0101733:	83 c4 10             	add    $0x10,%esp
f0101736:	85 c0                	test   %eax,%eax
f0101738:	75 19                	jne    f0101753 <mem_init+0x393>
f010173a:	68 66 6e 10 f0       	push   $0xf0106e66
f010173f:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101744:	68 a4 03 00 00       	push   $0x3a4
f0101749:	68 35 6d 10 f0       	push   $0xf0106d35
f010174e:	e8 ed e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101753:	83 ec 0c             	sub    $0xc,%esp
f0101756:	6a 00                	push   $0x0
f0101758:	e8 45 f8 ff ff       	call   f0100fa2 <page_alloc>
f010175d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101760:	83 c4 10             	add    $0x10,%esp
f0101763:	85 c0                	test   %eax,%eax
f0101765:	75 19                	jne    f0101780 <mem_init+0x3c0>
f0101767:	68 7c 6e 10 f0       	push   $0xf0106e7c
f010176c:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101771:	68 a5 03 00 00       	push   $0x3a5
f0101776:	68 35 6d 10 f0       	push   $0xf0106d35
f010177b:	e8 c0 e8 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101780:	39 fe                	cmp    %edi,%esi
f0101782:	75 19                	jne    f010179d <mem_init+0x3dd>
f0101784:	68 92 6e 10 f0       	push   $0xf0106e92
f0101789:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010178e:	68 a7 03 00 00       	push   $0x3a7
f0101793:	68 35 6d 10 f0       	push   $0xf0106d35
f0101798:	e8 a3 e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010179d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017a0:	39 c6                	cmp    %eax,%esi
f01017a2:	74 04                	je     f01017a8 <mem_init+0x3e8>
f01017a4:	39 c7                	cmp    %eax,%edi
f01017a6:	75 19                	jne    f01017c1 <mem_init+0x401>
f01017a8:	68 58 65 10 f0       	push   $0xf0106558
f01017ad:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01017b2:	68 a8 03 00 00       	push   $0x3a8
f01017b7:	68 35 6d 10 f0       	push   $0xf0106d35
f01017bc:	e8 7f e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01017c1:	83 ec 0c             	sub    $0xc,%esp
f01017c4:	6a 00                	push   $0x0
f01017c6:	e8 d7 f7 ff ff       	call   f0100fa2 <page_alloc>
f01017cb:	83 c4 10             	add    $0x10,%esp
f01017ce:	85 c0                	test   %eax,%eax
f01017d0:	74 19                	je     f01017eb <mem_init+0x42b>
f01017d2:	68 fb 6e 10 f0       	push   $0xf0106efb
f01017d7:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01017dc:	68 a9 03 00 00       	push   $0x3a9
f01017e1:	68 35 6d 10 f0       	push   $0xf0106d35
f01017e6:	e8 55 e8 ff ff       	call   f0100040 <_panic>
f01017eb:	89 f0                	mov    %esi,%eax
f01017ed:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
f01017f3:	c1 f8 03             	sar    $0x3,%eax
f01017f6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01017f9:	89 c2                	mov    %eax,%edx
f01017fb:	c1 ea 0c             	shr    $0xc,%edx
f01017fe:	3b 15 c8 be 22 f0    	cmp    0xf022bec8,%edx
f0101804:	72 12                	jb     f0101818 <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101806:	50                   	push   %eax
f0101807:	68 a4 5d 10 f0       	push   $0xf0105da4
f010180c:	6a 58                	push   $0x58
f010180e:	68 41 6d 10 f0       	push   $0xf0106d41
f0101813:	e8 28 e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101818:	83 ec 04             	sub    $0x4,%esp
f010181b:	68 00 10 00 00       	push   $0x1000
f0101820:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101822:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101827:	50                   	push   %eax
f0101828:	e8 75 38 00 00       	call   f01050a2 <memset>
	page_free(pp0);
f010182d:	89 34 24             	mov    %esi,(%esp)
f0101830:	e8 e3 f7 ff ff       	call   f0101018 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101835:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010183c:	e8 61 f7 ff ff       	call   f0100fa2 <page_alloc>
f0101841:	83 c4 10             	add    $0x10,%esp
f0101844:	85 c0                	test   %eax,%eax
f0101846:	75 19                	jne    f0101861 <mem_init+0x4a1>
f0101848:	68 0a 6f 10 f0       	push   $0xf0106f0a
f010184d:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101852:	68 ae 03 00 00       	push   $0x3ae
f0101857:	68 35 6d 10 f0       	push   $0xf0106d35
f010185c:	e8 df e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101861:	39 c6                	cmp    %eax,%esi
f0101863:	74 19                	je     f010187e <mem_init+0x4be>
f0101865:	68 28 6f 10 f0       	push   $0xf0106f28
f010186a:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010186f:	68 af 03 00 00       	push   $0x3af
f0101874:	68 35 6d 10 f0       	push   $0xf0106d35
f0101879:	e8 c2 e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010187e:	89 f0                	mov    %esi,%eax
f0101880:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
f0101886:	c1 f8 03             	sar    $0x3,%eax
f0101889:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010188c:	89 c2                	mov    %eax,%edx
f010188e:	c1 ea 0c             	shr    $0xc,%edx
f0101891:	3b 15 c8 be 22 f0    	cmp    0xf022bec8,%edx
f0101897:	72 12                	jb     f01018ab <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101899:	50                   	push   %eax
f010189a:	68 a4 5d 10 f0       	push   $0xf0105da4
f010189f:	6a 58                	push   $0x58
f01018a1:	68 41 6d 10 f0       	push   $0xf0106d41
f01018a6:	e8 95 e7 ff ff       	call   f0100040 <_panic>
f01018ab:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01018b1:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018b7:	80 38 00             	cmpb   $0x0,(%eax)
f01018ba:	74 19                	je     f01018d5 <mem_init+0x515>
f01018bc:	68 38 6f 10 f0       	push   $0xf0106f38
f01018c1:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01018c6:	68 b2 03 00 00       	push   $0x3b2
f01018cb:	68 35 6d 10 f0       	push   $0xf0106d35
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
f01018df:	a3 64 b2 22 f0       	mov    %eax,0xf022b264

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
f0101900:	a1 64 b2 22 f0       	mov    0xf022b264,%eax
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
f0101917:	68 42 6f 10 f0       	push   $0xf0106f42
f010191c:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101921:	68 bf 03 00 00       	push   $0x3bf
f0101926:	68 35 6d 10 f0       	push   $0xf0106d35
f010192b:	e8 10 e7 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101930:	83 ec 0c             	sub    $0xc,%esp
f0101933:	68 78 65 10 f0       	push   $0xf0106578
f0101938:	e8 16 1f 00 00       	call   f0103853 <cprintf>
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
f0101953:	68 50 6e 10 f0       	push   $0xf0106e50
f0101958:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010195d:	68 25 04 00 00       	push   $0x425
f0101962:	68 35 6d 10 f0       	push   $0xf0106d35
f0101967:	e8 d4 e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010196c:	83 ec 0c             	sub    $0xc,%esp
f010196f:	6a 00                	push   $0x0
f0101971:	e8 2c f6 ff ff       	call   f0100fa2 <page_alloc>
f0101976:	89 c3                	mov    %eax,%ebx
f0101978:	83 c4 10             	add    $0x10,%esp
f010197b:	85 c0                	test   %eax,%eax
f010197d:	75 19                	jne    f0101998 <mem_init+0x5d8>
f010197f:	68 66 6e 10 f0       	push   $0xf0106e66
f0101984:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101989:	68 26 04 00 00       	push   $0x426
f010198e:	68 35 6d 10 f0       	push   $0xf0106d35
f0101993:	e8 a8 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101998:	83 ec 0c             	sub    $0xc,%esp
f010199b:	6a 00                	push   $0x0
f010199d:	e8 00 f6 ff ff       	call   f0100fa2 <page_alloc>
f01019a2:	89 c6                	mov    %eax,%esi
f01019a4:	83 c4 10             	add    $0x10,%esp
f01019a7:	85 c0                	test   %eax,%eax
f01019a9:	75 19                	jne    f01019c4 <mem_init+0x604>
f01019ab:	68 7c 6e 10 f0       	push   $0xf0106e7c
f01019b0:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01019b5:	68 27 04 00 00       	push   $0x427
f01019ba:	68 35 6d 10 f0       	push   $0xf0106d35
f01019bf:	e8 7c e6 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019c4:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01019c7:	75 19                	jne    f01019e2 <mem_init+0x622>
f01019c9:	68 92 6e 10 f0       	push   $0xf0106e92
f01019ce:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01019d3:	68 2a 04 00 00       	push   $0x42a
f01019d8:	68 35 6d 10 f0       	push   $0xf0106d35
f01019dd:	e8 5e e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01019e2:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01019e5:	74 04                	je     f01019eb <mem_init+0x62b>
f01019e7:	39 c3                	cmp    %eax,%ebx
f01019e9:	75 19                	jne    f0101a04 <mem_init+0x644>
f01019eb:	68 58 65 10 f0       	push   $0xf0106558
f01019f0:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01019f5:	68 2b 04 00 00       	push   $0x42b
f01019fa:	68 35 6d 10 f0       	push   $0xf0106d35
f01019ff:	e8 3c e6 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a04:	a1 64 b2 22 f0       	mov    0xf022b264,%eax
f0101a09:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a0c:	c7 05 64 b2 22 f0 00 	movl   $0x0,0xf022b264
f0101a13:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a16:	83 ec 0c             	sub    $0xc,%esp
f0101a19:	6a 00                	push   $0x0
f0101a1b:	e8 82 f5 ff ff       	call   f0100fa2 <page_alloc>
f0101a20:	83 c4 10             	add    $0x10,%esp
f0101a23:	85 c0                	test   %eax,%eax
f0101a25:	74 19                	je     f0101a40 <mem_init+0x680>
f0101a27:	68 fb 6e 10 f0       	push   $0xf0106efb
f0101a2c:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101a31:	68 33 04 00 00       	push   $0x433
f0101a36:	68 35 6d 10 f0       	push   $0xf0106d35
f0101a3b:	e8 00 e6 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a40:	83 ec 04             	sub    $0x4,%esp
f0101a43:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a46:	50                   	push   %eax
f0101a47:	6a 00                	push   $0x0
f0101a49:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101a4f:	e8 ae f7 ff ff       	call   f0101202 <page_lookup>
f0101a54:	83 c4 10             	add    $0x10,%esp
f0101a57:	85 c0                	test   %eax,%eax
f0101a59:	74 19                	je     f0101a74 <mem_init+0x6b4>
f0101a5b:	68 98 65 10 f0       	push   $0xf0106598
f0101a60:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101a65:	68 37 04 00 00       	push   $0x437
f0101a6a:	68 35 6d 10 f0       	push   $0xf0106d35
f0101a6f:	e8 cc e5 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a74:	6a 02                	push   $0x2
f0101a76:	6a 00                	push   $0x0
f0101a78:	53                   	push   %ebx
f0101a79:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101a7f:	e8 44 f8 ff ff       	call   f01012c8 <page_insert>
f0101a84:	83 c4 10             	add    $0x10,%esp
f0101a87:	85 c0                	test   %eax,%eax
f0101a89:	78 19                	js     f0101aa4 <mem_init+0x6e4>
f0101a8b:	68 d0 65 10 f0       	push   $0xf01065d0
f0101a90:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101a95:	68 3a 04 00 00       	push   $0x43a
f0101a9a:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101ab4:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101aba:	e8 09 f8 ff ff       	call   f01012c8 <page_insert>
f0101abf:	83 c4 20             	add    $0x20,%esp
f0101ac2:	85 c0                	test   %eax,%eax
f0101ac4:	74 19                	je     f0101adf <mem_init+0x71f>
f0101ac6:	68 00 66 10 f0       	push   $0xf0106600
f0101acb:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101ad0:	68 3e 04 00 00       	push   $0x43e
f0101ad5:	68 35 6d 10 f0       	push   $0xf0106d35
f0101ada:	e8 61 e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101adf:	8b 3d cc be 22 f0    	mov    0xf022becc,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ae5:	a1 d0 be 22 f0       	mov    0xf022bed0,%eax
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
f0101b06:	68 30 66 10 f0       	push   $0xf0106630
f0101b0b:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101b10:	68 3f 04 00 00       	push   $0x43f
f0101b15:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101b3a:	68 58 66 10 f0       	push   $0xf0106658
f0101b3f:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101b44:	68 40 04 00 00       	push   $0x440
f0101b49:	68 35 6d 10 f0       	push   $0xf0106d35
f0101b4e:	e8 ed e4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101b53:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b58:	74 19                	je     f0101b73 <mem_init+0x7b3>
f0101b5a:	68 4d 6f 10 f0       	push   $0xf0106f4d
f0101b5f:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101b64:	68 41 04 00 00       	push   $0x441
f0101b69:	68 35 6d 10 f0       	push   $0xf0106d35
f0101b6e:	e8 cd e4 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101b73:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b76:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101b7b:	74 19                	je     f0101b96 <mem_init+0x7d6>
f0101b7d:	68 5e 6f 10 f0       	push   $0xf0106f5e
f0101b82:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101b87:	68 42 04 00 00       	push   $0x442
f0101b8c:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101bab:	68 88 66 10 f0       	push   $0xf0106688
f0101bb0:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101bb5:	68 45 04 00 00       	push   $0x445
f0101bba:	68 35 6d 10 f0       	push   $0xf0106d35
f0101bbf:	e8 7c e4 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bc4:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bc9:	a1 cc be 22 f0       	mov    0xf022becc,%eax
f0101bce:	e8 54 ee ff ff       	call   f0100a27 <check_va2pa>
f0101bd3:	89 f2                	mov    %esi,%edx
f0101bd5:	2b 15 d0 be 22 f0    	sub    0xf022bed0,%edx
f0101bdb:	c1 fa 03             	sar    $0x3,%edx
f0101bde:	c1 e2 0c             	shl    $0xc,%edx
f0101be1:	39 d0                	cmp    %edx,%eax
f0101be3:	74 19                	je     f0101bfe <mem_init+0x83e>
f0101be5:	68 c4 66 10 f0       	push   $0xf01066c4
f0101bea:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101bef:	68 47 04 00 00       	push   $0x447
f0101bf4:	68 35 6d 10 f0       	push   $0xf0106d35
f0101bf9:	e8 42 e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101bfe:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c03:	74 19                	je     f0101c1e <mem_init+0x85e>
f0101c05:	68 6f 6f 10 f0       	push   $0xf0106f6f
f0101c0a:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101c0f:	68 48 04 00 00       	push   $0x448
f0101c14:	68 35 6d 10 f0       	push   $0xf0106d35
f0101c19:	e8 22 e4 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101c1e:	83 ec 0c             	sub    $0xc,%esp
f0101c21:	6a 00                	push   $0x0
f0101c23:	e8 7a f3 ff ff       	call   f0100fa2 <page_alloc>
f0101c28:	83 c4 10             	add    $0x10,%esp
f0101c2b:	85 c0                	test   %eax,%eax
f0101c2d:	74 19                	je     f0101c48 <mem_init+0x888>
f0101c2f:	68 fb 6e 10 f0       	push   $0xf0106efb
f0101c34:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101c39:	68 4b 04 00 00       	push   $0x44b
f0101c3e:	68 35 6d 10 f0       	push   $0xf0106d35
f0101c43:	e8 f8 e3 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c48:	6a 02                	push   $0x2
f0101c4a:	68 00 10 00 00       	push   $0x1000
f0101c4f:	56                   	push   %esi
f0101c50:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101c56:	e8 6d f6 ff ff       	call   f01012c8 <page_insert>
f0101c5b:	83 c4 10             	add    $0x10,%esp
f0101c5e:	85 c0                	test   %eax,%eax
f0101c60:	74 19                	je     f0101c7b <mem_init+0x8bb>
f0101c62:	68 88 66 10 f0       	push   $0xf0106688
f0101c67:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101c6c:	68 4e 04 00 00       	push   $0x44e
f0101c71:	68 35 6d 10 f0       	push   $0xf0106d35
f0101c76:	e8 c5 e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c7b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c80:	a1 cc be 22 f0       	mov    0xf022becc,%eax
f0101c85:	e8 9d ed ff ff       	call   f0100a27 <check_va2pa>
f0101c8a:	89 f2                	mov    %esi,%edx
f0101c8c:	2b 15 d0 be 22 f0    	sub    0xf022bed0,%edx
f0101c92:	c1 fa 03             	sar    $0x3,%edx
f0101c95:	c1 e2 0c             	shl    $0xc,%edx
f0101c98:	39 d0                	cmp    %edx,%eax
f0101c9a:	74 19                	je     f0101cb5 <mem_init+0x8f5>
f0101c9c:	68 c4 66 10 f0       	push   $0xf01066c4
f0101ca1:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101ca6:	68 4f 04 00 00       	push   $0x44f
f0101cab:	68 35 6d 10 f0       	push   $0xf0106d35
f0101cb0:	e8 8b e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101cb5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101cba:	74 19                	je     f0101cd5 <mem_init+0x915>
f0101cbc:	68 6f 6f 10 f0       	push   $0xf0106f6f
f0101cc1:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101cc6:	68 50 04 00 00       	push   $0x450
f0101ccb:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101ce6:	68 fb 6e 10 f0       	push   $0xf0106efb
f0101ceb:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101cf0:	68 54 04 00 00       	push   $0x454
f0101cf5:	68 35 6d 10 f0       	push   $0xf0106d35
f0101cfa:	e8 41 e3 ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101cff:	8b 15 cc be 22 f0    	mov    0xf022becc,%edx
f0101d05:	8b 02                	mov    (%edx),%eax
f0101d07:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d0c:	89 c1                	mov    %eax,%ecx
f0101d0e:	c1 e9 0c             	shr    $0xc,%ecx
f0101d11:	3b 0d c8 be 22 f0    	cmp    0xf022bec8,%ecx
f0101d17:	72 15                	jb     f0101d2e <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d19:	50                   	push   %eax
f0101d1a:	68 a4 5d 10 f0       	push   $0xf0105da4
f0101d1f:	68 57 04 00 00       	push   $0x457
f0101d24:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101d53:	68 f4 66 10 f0       	push   $0xf01066f4
f0101d58:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101d5d:	68 58 04 00 00       	push   $0x458
f0101d62:	68 35 6d 10 f0       	push   $0xf0106d35
f0101d67:	e8 d4 e2 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d6c:	6a 06                	push   $0x6
f0101d6e:	68 00 10 00 00       	push   $0x1000
f0101d73:	56                   	push   %esi
f0101d74:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101d7a:	e8 49 f5 ff ff       	call   f01012c8 <page_insert>
f0101d7f:	83 c4 10             	add    $0x10,%esp
f0101d82:	85 c0                	test   %eax,%eax
f0101d84:	74 19                	je     f0101d9f <mem_init+0x9df>
f0101d86:	68 34 67 10 f0       	push   $0xf0106734
f0101d8b:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101d90:	68 5b 04 00 00       	push   $0x45b
f0101d95:	68 35 6d 10 f0       	push   $0xf0106d35
f0101d9a:	e8 a1 e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d9f:	8b 3d cc be 22 f0    	mov    0xf022becc,%edi
f0101da5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101daa:	89 f8                	mov    %edi,%eax
f0101dac:	e8 76 ec ff ff       	call   f0100a27 <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101db1:	89 f2                	mov    %esi,%edx
f0101db3:	2b 15 d0 be 22 f0    	sub    0xf022bed0,%edx
f0101db9:	c1 fa 03             	sar    $0x3,%edx
f0101dbc:	c1 e2 0c             	shl    $0xc,%edx
f0101dbf:	39 d0                	cmp    %edx,%eax
f0101dc1:	74 19                	je     f0101ddc <mem_init+0xa1c>
f0101dc3:	68 c4 66 10 f0       	push   $0xf01066c4
f0101dc8:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101dcd:	68 5c 04 00 00       	push   $0x45c
f0101dd2:	68 35 6d 10 f0       	push   $0xf0106d35
f0101dd7:	e8 64 e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101ddc:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101de1:	74 19                	je     f0101dfc <mem_init+0xa3c>
f0101de3:	68 6f 6f 10 f0       	push   $0xf0106f6f
f0101de8:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101ded:	68 5d 04 00 00       	push   $0x45d
f0101df2:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101e14:	68 74 67 10 f0       	push   $0xf0106774
f0101e19:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101e1e:	68 5e 04 00 00       	push   $0x45e
f0101e23:	68 35 6d 10 f0       	push   $0xf0106d35
f0101e28:	e8 13 e2 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e2d:	a1 cc be 22 f0       	mov    0xf022becc,%eax
f0101e32:	f6 00 04             	testb  $0x4,(%eax)
f0101e35:	75 19                	jne    f0101e50 <mem_init+0xa90>
f0101e37:	68 80 6f 10 f0       	push   $0xf0106f80
f0101e3c:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101e41:	68 5f 04 00 00       	push   $0x45f
f0101e46:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0101e65:	68 88 66 10 f0       	push   $0xf0106688
f0101e6a:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101e6f:	68 62 04 00 00       	push   $0x462
f0101e74:	68 35 6d 10 f0       	push   $0xf0106d35
f0101e79:	e8 c2 e1 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e7e:	83 ec 04             	sub    $0x4,%esp
f0101e81:	6a 00                	push   $0x0
f0101e83:	68 00 10 00 00       	push   $0x1000
f0101e88:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101e8e:	e8 fd f1 ff ff       	call   f0101090 <pgdir_walk>
f0101e93:	83 c4 10             	add    $0x10,%esp
f0101e96:	f6 00 02             	testb  $0x2,(%eax)
f0101e99:	75 19                	jne    f0101eb4 <mem_init+0xaf4>
f0101e9b:	68 a8 67 10 f0       	push   $0xf01067a8
f0101ea0:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101ea5:	68 63 04 00 00       	push   $0x463
f0101eaa:	68 35 6d 10 f0       	push   $0xf0106d35
f0101eaf:	e8 8c e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101eb4:	83 ec 04             	sub    $0x4,%esp
f0101eb7:	6a 00                	push   $0x0
f0101eb9:	68 00 10 00 00       	push   $0x1000
f0101ebe:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101ec4:	e8 c7 f1 ff ff       	call   f0101090 <pgdir_walk>
f0101ec9:	83 c4 10             	add    $0x10,%esp
f0101ecc:	f6 00 04             	testb  $0x4,(%eax)
f0101ecf:	74 19                	je     f0101eea <mem_init+0xb2a>
f0101ed1:	68 dc 67 10 f0       	push   $0xf01067dc
f0101ed6:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101edb:	68 64 04 00 00       	push   $0x464
f0101ee0:	68 35 6d 10 f0       	push   $0xf0106d35
f0101ee5:	e8 56 e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101eea:	6a 02                	push   $0x2
f0101eec:	68 00 00 40 00       	push   $0x400000
f0101ef1:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ef4:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101efa:	e8 c9 f3 ff ff       	call   f01012c8 <page_insert>
f0101eff:	83 c4 10             	add    $0x10,%esp
f0101f02:	85 c0                	test   %eax,%eax
f0101f04:	78 19                	js     f0101f1f <mem_init+0xb5f>
f0101f06:	68 14 68 10 f0       	push   $0xf0106814
f0101f0b:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101f10:	68 67 04 00 00       	push   $0x467
f0101f15:	68 35 6d 10 f0       	push   $0xf0106d35
f0101f1a:	e8 21 e1 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f1f:	6a 02                	push   $0x2
f0101f21:	68 00 10 00 00       	push   $0x1000
f0101f26:	53                   	push   %ebx
f0101f27:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101f2d:	e8 96 f3 ff ff       	call   f01012c8 <page_insert>
f0101f32:	83 c4 10             	add    $0x10,%esp
f0101f35:	85 c0                	test   %eax,%eax
f0101f37:	74 19                	je     f0101f52 <mem_init+0xb92>
f0101f39:	68 4c 68 10 f0       	push   $0xf010684c
f0101f3e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101f43:	68 6a 04 00 00       	push   $0x46a
f0101f48:	68 35 6d 10 f0       	push   $0xf0106d35
f0101f4d:	e8 ee e0 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f52:	83 ec 04             	sub    $0x4,%esp
f0101f55:	6a 00                	push   $0x0
f0101f57:	68 00 10 00 00       	push   $0x1000
f0101f5c:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0101f62:	e8 29 f1 ff ff       	call   f0101090 <pgdir_walk>
f0101f67:	83 c4 10             	add    $0x10,%esp
f0101f6a:	f6 00 04             	testb  $0x4,(%eax)
f0101f6d:	74 19                	je     f0101f88 <mem_init+0xbc8>
f0101f6f:	68 dc 67 10 f0       	push   $0xf01067dc
f0101f74:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101f79:	68 6b 04 00 00       	push   $0x46b
f0101f7e:	68 35 6d 10 f0       	push   $0xf0106d35
f0101f83:	e8 b8 e0 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101f88:	8b 3d cc be 22 f0    	mov    0xf022becc,%edi
f0101f8e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101f93:	89 f8                	mov    %edi,%eax
f0101f95:	e8 8d ea ff ff       	call   f0100a27 <check_va2pa>
f0101f9a:	89 c1                	mov    %eax,%ecx
f0101f9c:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101f9f:	89 d8                	mov    %ebx,%eax
f0101fa1:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
f0101fa7:	c1 f8 03             	sar    $0x3,%eax
f0101faa:	c1 e0 0c             	shl    $0xc,%eax
f0101fad:	39 c1                	cmp    %eax,%ecx
f0101faf:	74 19                	je     f0101fca <mem_init+0xc0a>
f0101fb1:	68 88 68 10 f0       	push   $0xf0106888
f0101fb6:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101fbb:	68 6e 04 00 00       	push   $0x46e
f0101fc0:	68 35 6d 10 f0       	push   $0xf0106d35
f0101fc5:	e8 76 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101fca:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101fcf:	89 f8                	mov    %edi,%eax
f0101fd1:	e8 51 ea ff ff       	call   f0100a27 <check_va2pa>
f0101fd6:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101fd9:	74 19                	je     f0101ff4 <mem_init+0xc34>
f0101fdb:	68 b4 68 10 f0       	push   $0xf01068b4
f0101fe0:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0101fe5:	68 6f 04 00 00       	push   $0x46f
f0101fea:	68 35 6d 10 f0       	push   $0xf0106d35
f0101fef:	e8 4c e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f0101ff4:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f0101ff9:	74 19                	je     f0102014 <mem_init+0xc54>
f0101ffb:	68 96 6f 10 f0       	push   $0xf0106f96
f0102000:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102005:	68 71 04 00 00       	push   $0x471
f010200a:	68 35 6d 10 f0       	push   $0xf0106d35
f010200f:	e8 2c e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102014:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102019:	74 19                	je     f0102034 <mem_init+0xc74>
f010201b:	68 a7 6f 10 f0       	push   $0xf0106fa7
f0102020:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102025:	68 72 04 00 00       	push   $0x472
f010202a:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102049:	68 e4 68 10 f0       	push   $0xf01068e4
f010204e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102053:	68 75 04 00 00       	push   $0x475
f0102058:	68 35 6d 10 f0       	push   $0xf0106d35
f010205d:	e8 de df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102062:	83 ec 08             	sub    $0x8,%esp
f0102065:	6a 00                	push   $0x0
f0102067:	ff 35 cc be 22 f0    	pushl  0xf022becc
f010206d:	e8 10 f2 ff ff       	call   f0101282 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102072:	8b 3d cc be 22 f0    	mov    0xf022becc,%edi
f0102078:	ba 00 00 00 00       	mov    $0x0,%edx
f010207d:	89 f8                	mov    %edi,%eax
f010207f:	e8 a3 e9 ff ff       	call   f0100a27 <check_va2pa>
f0102084:	83 c4 10             	add    $0x10,%esp
f0102087:	83 f8 ff             	cmp    $0xffffffff,%eax
f010208a:	74 19                	je     f01020a5 <mem_init+0xce5>
f010208c:	68 08 69 10 f0       	push   $0xf0106908
f0102091:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102096:	68 79 04 00 00       	push   $0x479
f010209b:	68 35 6d 10 f0       	push   $0xf0106d35
f01020a0:	e8 9b df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020a5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020aa:	89 f8                	mov    %edi,%eax
f01020ac:	e8 76 e9 ff ff       	call   f0100a27 <check_va2pa>
f01020b1:	89 da                	mov    %ebx,%edx
f01020b3:	2b 15 d0 be 22 f0    	sub    0xf022bed0,%edx
f01020b9:	c1 fa 03             	sar    $0x3,%edx
f01020bc:	c1 e2 0c             	shl    $0xc,%edx
f01020bf:	39 d0                	cmp    %edx,%eax
f01020c1:	74 19                	je     f01020dc <mem_init+0xd1c>
f01020c3:	68 b4 68 10 f0       	push   $0xf01068b4
f01020c8:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01020cd:	68 7a 04 00 00       	push   $0x47a
f01020d2:	68 35 6d 10 f0       	push   $0xf0106d35
f01020d7:	e8 64 df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f01020dc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01020e1:	74 19                	je     f01020fc <mem_init+0xd3c>
f01020e3:	68 4d 6f 10 f0       	push   $0xf0106f4d
f01020e8:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01020ed:	68 7b 04 00 00       	push   $0x47b
f01020f2:	68 35 6d 10 f0       	push   $0xf0106d35
f01020f7:	e8 44 df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f01020fc:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102101:	74 19                	je     f010211c <mem_init+0xd5c>
f0102103:	68 a7 6f 10 f0       	push   $0xf0106fa7
f0102108:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010210d:	68 7c 04 00 00       	push   $0x47c
f0102112:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102131:	68 2c 69 10 f0       	push   $0xf010692c
f0102136:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010213b:	68 7f 04 00 00       	push   $0x47f
f0102140:	68 35 6d 10 f0       	push   $0xf0106d35
f0102145:	e8 f6 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f010214a:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010214f:	75 19                	jne    f010216a <mem_init+0xdaa>
f0102151:	68 b8 6f 10 f0       	push   $0xf0106fb8
f0102156:	68 5b 6d 10 f0       	push   $0xf0106d5b
f010215b:	68 80 04 00 00       	push   $0x480
f0102160:	68 35 6d 10 f0       	push   $0xf0106d35
f0102165:	e8 d6 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f010216a:	83 3b 00             	cmpl   $0x0,(%ebx)
f010216d:	74 19                	je     f0102188 <mem_init+0xdc8>
f010216f:	68 c4 6f 10 f0       	push   $0xf0106fc4
f0102174:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102179:	68 81 04 00 00       	push   $0x481
f010217e:	68 35 6d 10 f0       	push   $0xf0106d35
f0102183:	e8 b8 de ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102188:	83 ec 08             	sub    $0x8,%esp
f010218b:	68 00 10 00 00       	push   $0x1000
f0102190:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0102196:	e8 e7 f0 ff ff       	call   f0101282 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010219b:	8b 3d cc be 22 f0    	mov    0xf022becc,%edi
f01021a1:	ba 00 00 00 00       	mov    $0x0,%edx
f01021a6:	89 f8                	mov    %edi,%eax
f01021a8:	e8 7a e8 ff ff       	call   f0100a27 <check_va2pa>
f01021ad:	83 c4 10             	add    $0x10,%esp
f01021b0:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021b3:	74 19                	je     f01021ce <mem_init+0xe0e>
f01021b5:	68 08 69 10 f0       	push   $0xf0106908
f01021ba:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01021bf:	68 85 04 00 00       	push   $0x485
f01021c4:	68 35 6d 10 f0       	push   $0xf0106d35
f01021c9:	e8 72 de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021ce:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021d3:	89 f8                	mov    %edi,%eax
f01021d5:	e8 4d e8 ff ff       	call   f0100a27 <check_va2pa>
f01021da:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021dd:	74 19                	je     f01021f8 <mem_init+0xe38>
f01021df:	68 64 69 10 f0       	push   $0xf0106964
f01021e4:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01021e9:	68 86 04 00 00       	push   $0x486
f01021ee:	68 35 6d 10 f0       	push   $0xf0106d35
f01021f3:	e8 48 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f01021f8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01021fd:	74 19                	je     f0102218 <mem_init+0xe58>
f01021ff:	68 d9 6f 10 f0       	push   $0xf0106fd9
f0102204:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102209:	68 87 04 00 00       	push   $0x487
f010220e:	68 35 6d 10 f0       	push   $0xf0106d35
f0102213:	e8 28 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102218:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010221d:	74 19                	je     f0102238 <mem_init+0xe78>
f010221f:	68 a7 6f 10 f0       	push   $0xf0106fa7
f0102224:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102229:	68 88 04 00 00       	push   $0x488
f010222e:	68 35 6d 10 f0       	push   $0xf0106d35
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
f010224d:	68 8c 69 10 f0       	push   $0xf010698c
f0102252:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102257:	68 8b 04 00 00       	push   $0x48b
f010225c:	68 35 6d 10 f0       	push   $0xf0106d35
f0102261:	e8 da dd ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102266:	83 ec 0c             	sub    $0xc,%esp
f0102269:	6a 00                	push   $0x0
f010226b:	e8 32 ed ff ff       	call   f0100fa2 <page_alloc>
f0102270:	83 c4 10             	add    $0x10,%esp
f0102273:	85 c0                	test   %eax,%eax
f0102275:	74 19                	je     f0102290 <mem_init+0xed0>
f0102277:	68 fb 6e 10 f0       	push   $0xf0106efb
f010227c:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102281:	68 8e 04 00 00       	push   $0x48e
f0102286:	68 35 6d 10 f0       	push   $0xf0106d35
f010228b:	e8 b0 dd ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102290:	8b 0d cc be 22 f0    	mov    0xf022becc,%ecx
f0102296:	8b 11                	mov    (%ecx),%edx
f0102298:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010229e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022a1:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
f01022a7:	c1 f8 03             	sar    $0x3,%eax
f01022aa:	c1 e0 0c             	shl    $0xc,%eax
f01022ad:	39 c2                	cmp    %eax,%edx
f01022af:	74 19                	je     f01022ca <mem_init+0xf0a>
f01022b1:	68 30 66 10 f0       	push   $0xf0106630
f01022b6:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01022bb:	68 91 04 00 00       	push   $0x491
f01022c0:	68 35 6d 10 f0       	push   $0xf0106d35
f01022c5:	e8 76 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01022ca:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01022d0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022d3:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01022d8:	74 19                	je     f01022f3 <mem_init+0xf33>
f01022da:	68 5e 6f 10 f0       	push   $0xf0106f5e
f01022df:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01022e4:	68 93 04 00 00       	push   $0x493
f01022e9:	68 35 6d 10 f0       	push   $0xf0106d35
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
f010230f:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0102315:	e8 76 ed ff ff       	call   f0101090 <pgdir_walk>
f010231a:	89 c7                	mov    %eax,%edi
f010231c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010231f:	a1 cc be 22 f0       	mov    0xf022becc,%eax
f0102324:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102327:	8b 40 04             	mov    0x4(%eax),%eax
f010232a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010232f:	8b 0d c8 be 22 f0    	mov    0xf022bec8,%ecx
f0102335:	89 c2                	mov    %eax,%edx
f0102337:	c1 ea 0c             	shr    $0xc,%edx
f010233a:	83 c4 10             	add    $0x10,%esp
f010233d:	39 ca                	cmp    %ecx,%edx
f010233f:	72 15                	jb     f0102356 <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102341:	50                   	push   %eax
f0102342:	68 a4 5d 10 f0       	push   $0xf0105da4
f0102347:	68 9a 04 00 00       	push   $0x49a
f010234c:	68 35 6d 10 f0       	push   $0xf0106d35
f0102351:	e8 ea dc ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102356:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f010235b:	39 c7                	cmp    %eax,%edi
f010235d:	74 19                	je     f0102378 <mem_init+0xfb8>
f010235f:	68 ea 6f 10 f0       	push   $0xf0106fea
f0102364:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102369:	68 9b 04 00 00       	push   $0x49b
f010236e:	68 35 6d 10 f0       	push   $0xf0106d35
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
f010238b:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
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
f01023a1:	68 a4 5d 10 f0       	push   $0xf0105da4
f01023a6:	6a 58                	push   $0x58
f01023a8:	68 41 6d 10 f0       	push   $0xf0106d41
f01023ad:	e8 8e dc ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01023b2:	83 ec 04             	sub    $0x4,%esp
f01023b5:	68 00 10 00 00       	push   $0x1000
f01023ba:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01023bf:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023c4:	50                   	push   %eax
f01023c5:	e8 d8 2c 00 00       	call   f01050a2 <memset>
	page_free(pp0);
f01023ca:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01023cd:	89 3c 24             	mov    %edi,(%esp)
f01023d0:	e8 43 ec ff ff       	call   f0101018 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01023d5:	83 c4 0c             	add    $0xc,%esp
f01023d8:	6a 01                	push   $0x1
f01023da:	6a 00                	push   $0x0
f01023dc:	ff 35 cc be 22 f0    	pushl  0xf022becc
f01023e2:	e8 a9 ec ff ff       	call   f0101090 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023e7:	89 fa                	mov    %edi,%edx
f01023e9:	2b 15 d0 be 22 f0    	sub    0xf022bed0,%edx
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
f01023fd:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
f0102403:	72 12                	jb     f0102417 <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102405:	52                   	push   %edx
f0102406:	68 a4 5d 10 f0       	push   $0xf0105da4
f010240b:	6a 58                	push   $0x58
f010240d:	68 41 6d 10 f0       	push   $0xf0106d41
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
f010242b:	68 02 70 10 f0       	push   $0xf0107002
f0102430:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102435:	68 a5 04 00 00       	push   $0x4a5
f010243a:	68 35 6d 10 f0       	push   $0xf0106d35
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
f010244b:	a1 cc be 22 f0       	mov    0xf022becc,%eax
f0102450:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102456:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102459:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f010245f:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102462:	89 0d 64 b2 22 f0    	mov    %ecx,0xf022b264

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
f01024bb:	68 b0 69 10 f0       	push   $0xf01069b0
f01024c0:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01024c5:	68 b5 04 00 00       	push   $0x4b5
f01024ca:	68 35 6d 10 f0       	push   $0xf0106d35
f01024cf:	e8 6c db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01024d4:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f01024da:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f01024e0:	77 08                	ja     f01024ea <mem_init+0x112a>
f01024e2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01024e8:	77 19                	ja     f0102503 <mem_init+0x1143>
f01024ea:	68 d8 69 10 f0       	push   $0xf01069d8
f01024ef:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01024f4:	68 b6 04 00 00       	push   $0x4b6
f01024f9:	68 35 6d 10 f0       	push   $0xf0106d35
f01024fe:	e8 3d db ff ff       	call   f0100040 <_panic>
f0102503:	89 da                	mov    %ebx,%edx
f0102505:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f0102507:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f010250d:	74 19                	je     f0102528 <mem_init+0x1168>
f010250f:	68 00 6a 10 f0       	push   $0xf0106a00
f0102514:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102519:	68 b8 04 00 00       	push   $0x4b8
f010251e:	68 35 6d 10 f0       	push   $0xf0106d35
f0102523:	e8 18 db ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f0102528:	39 c6                	cmp    %eax,%esi
f010252a:	73 19                	jae    f0102545 <mem_init+0x1185>
f010252c:	68 19 70 10 f0       	push   $0xf0107019
f0102531:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102536:	68 ba 04 00 00       	push   $0x4ba
f010253b:	68 35 6d 10 f0       	push   $0xf0106d35
f0102540:	e8 fb da ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f0102545:	8b 3d cc be 22 f0    	mov    0xf022becc,%edi
f010254b:	89 da                	mov    %ebx,%edx
f010254d:	89 f8                	mov    %edi,%eax
f010254f:	e8 d3 e4 ff ff       	call   f0100a27 <check_va2pa>
f0102554:	85 c0                	test   %eax,%eax
f0102556:	74 19                	je     f0102571 <mem_init+0x11b1>
f0102558:	68 28 6a 10 f0       	push   $0xf0106a28
f010255d:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102562:	68 bc 04 00 00       	push   $0x4bc
f0102567:	68 35 6d 10 f0       	push   $0xf0106d35
f010256c:	e8 cf da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102571:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f0102577:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010257a:	89 c2                	mov    %eax,%edx
f010257c:	89 f8                	mov    %edi,%eax
f010257e:	e8 a4 e4 ff ff       	call   f0100a27 <check_va2pa>
f0102583:	3d 00 10 00 00       	cmp    $0x1000,%eax
f0102588:	74 19                	je     f01025a3 <mem_init+0x11e3>
f010258a:	68 4c 6a 10 f0       	push   $0xf0106a4c
f010258f:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102594:	68 bd 04 00 00       	push   $0x4bd
f0102599:	68 35 6d 10 f0       	push   $0xf0106d35
f010259e:	e8 9d da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01025a3:	89 f2                	mov    %esi,%edx
f01025a5:	89 f8                	mov    %edi,%eax
f01025a7:	e8 7b e4 ff ff       	call   f0100a27 <check_va2pa>
f01025ac:	85 c0                	test   %eax,%eax
f01025ae:	74 19                	je     f01025c9 <mem_init+0x1209>
f01025b0:	68 7c 6a 10 f0       	push   $0xf0106a7c
f01025b5:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01025ba:	68 be 04 00 00       	push   $0x4be
f01025bf:	68 35 6d 10 f0       	push   $0xf0106d35
f01025c4:	e8 77 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01025c9:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01025cf:	89 f8                	mov    %edi,%eax
f01025d1:	e8 51 e4 ff ff       	call   f0100a27 <check_va2pa>
f01025d6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025d9:	74 19                	je     f01025f4 <mem_init+0x1234>
f01025db:	68 a0 6a 10 f0       	push   $0xf0106aa0
f01025e0:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01025e5:	68 bf 04 00 00       	push   $0x4bf
f01025ea:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102608:	68 cc 6a 10 f0       	push   $0xf0106acc
f010260d:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102612:	68 c1 04 00 00       	push   $0x4c1
f0102617:	68 35 6d 10 f0       	push   $0xf0106d35
f010261c:	e8 1f da ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102621:	83 ec 04             	sub    $0x4,%esp
f0102624:	6a 00                	push   $0x0
f0102626:	53                   	push   %ebx
f0102627:	ff 35 cc be 22 f0    	pushl  0xf022becc
f010262d:	e8 5e ea ff ff       	call   f0101090 <pgdir_walk>
f0102632:	83 c4 10             	add    $0x10,%esp
f0102635:	f6 00 04             	testb  $0x4,(%eax)
f0102638:	74 19                	je     f0102653 <mem_init+0x1293>
f010263a:	68 10 6b 10 f0       	push   $0xf0106b10
f010263f:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102644:	68 c2 04 00 00       	push   $0x4c2
f0102649:	68 35 6d 10 f0       	push   $0xf0106d35
f010264e:	e8 ed d9 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102653:	83 ec 04             	sub    $0x4,%esp
f0102656:	6a 00                	push   $0x0
f0102658:	53                   	push   %ebx
f0102659:	ff 35 cc be 22 f0    	pushl  0xf022becc
f010265f:	e8 2c ea ff ff       	call   f0101090 <pgdir_walk>
f0102664:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f010266a:	83 c4 0c             	add    $0xc,%esp
f010266d:	6a 00                	push   $0x0
f010266f:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102672:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0102678:	e8 13 ea ff ff       	call   f0101090 <pgdir_walk>
f010267d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f0102683:	83 c4 0c             	add    $0xc,%esp
f0102686:	6a 00                	push   $0x0
f0102688:	56                   	push   %esi
f0102689:	ff 35 cc be 22 f0    	pushl  0xf022becc
f010268f:	e8 fc e9 ff ff       	call   f0101090 <pgdir_walk>
f0102694:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f010269a:	c7 04 24 2b 70 10 f0 	movl   $0xf010702b,(%esp)
f01026a1:	e8 ad 11 00 00       	call   f0103853 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f01026a6:	a1 d0 be 22 f0       	mov    0xf022bed0,%eax
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
f01026b6:	68 c8 5d 10 f0       	push   $0xf0105dc8
f01026bb:	68 c5 00 00 00       	push   $0xc5
f01026c0:	68 35 6d 10 f0       	push   $0xf0106d35
f01026c5:	e8 76 d9 ff ff       	call   f0100040 <_panic>
f01026ca:	8b 15 c8 be 22 f0    	mov    0xf022bec8,%edx
f01026d0:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01026d7:	83 ec 08             	sub    $0x8,%esp
f01026da:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01026e0:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f01026e2:	05 00 00 00 10       	add    $0x10000000,%eax
f01026e7:	50                   	push   %eax
f01026e8:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01026ed:	a1 cc be 22 f0       	mov    0xf022becc,%eax
f01026f2:	e8 84 ea ff ff       	call   f010117b <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f01026f7:	a1 6c b2 22 f0       	mov    0xf022b26c,%eax
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
f0102707:	68 c8 5d 10 f0       	push   $0xf0105dc8
f010270c:	68 cd 00 00 00       	push   $0xcd
f0102711:	68 35 6d 10 f0       	push   $0xf0106d35
f0102716:	e8 25 d9 ff ff       	call   f0100040 <_panic>
f010271b:	83 ec 08             	sub    $0x8,%esp
f010271e:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102720:	05 00 00 00 10       	add    $0x10000000,%eax
f0102725:	50                   	push   %eax
f0102726:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f010272b:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102730:	a1 cc be 22 f0       	mov    0xf022becc,%eax
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
f010274a:	68 c8 5d 10 f0       	push   $0xf0105dc8
f010274f:	68 d9 00 00 00       	push   $0xd9
f0102754:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102772:	a1 cc be 22 f0       	mov    0xf022becc,%eax
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
f010278d:	a1 cc be 22 f0       	mov    0xf022becc,%eax
f0102792:	e8 e4 e9 ff ff       	call   f010117b <boot_map_region>
f0102797:	c7 45 c4 00 d0 22 f0 	movl   $0xf022d000,-0x3c(%ebp)
f010279e:	83 c4 10             	add    $0x10,%esp
f01027a1:	bb 00 d0 22 f0       	mov    $0xf022d000,%ebx
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
f01027b4:	68 c8 5d 10 f0       	push   $0xf0105dc8
f01027b9:	68 20 01 00 00       	push   $0x120
f01027be:	68 35 6d 10 f0       	push   $0xf0106d35
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
f01027db:	a1 cc be 22 f0       	mov    0xf022becc,%eax
f01027e0:	e8 96 e9 ff ff       	call   f010117b <boot_map_region>
f01027e5:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f01027eb:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f01027f1:	83 c4 10             	add    $0x10,%esp
f01027f4:	81 fb 00 d0 26 f0    	cmp    $0xf026d000,%ebx
f01027fa:	75 af                	jne    f01027ab <mem_init+0x13eb>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f01027fc:	8b 3d cc be 22 f0    	mov    0xf022becc,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102802:	a1 c8 be 22 f0       	mov    0xf022bec8,%eax
f0102807:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010280a:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102811:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102816:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102819:	8b 35 d0 be 22 f0    	mov    0xf022bed0,%esi
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
f0102840:	68 c8 5d 10 f0       	push   $0xf0105dc8
f0102845:	68 d7 03 00 00       	push   $0x3d7
f010284a:	68 35 6d 10 f0       	push   $0xf0106d35
f010284f:	e8 ec d7 ff ff       	call   f0100040 <_panic>
f0102854:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f010285b:	39 d0                	cmp    %edx,%eax
f010285d:	74 19                	je     f0102878 <mem_init+0x14b8>
f010285f:	68 44 6b 10 f0       	push   $0xf0106b44
f0102864:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102869:	68 d7 03 00 00       	push   $0x3d7
f010286e:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102883:	8b 35 6c b2 22 f0    	mov    0xf022b26c,%esi
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
f01028a4:	68 c8 5d 10 f0       	push   $0xf0105dc8
f01028a9:	68 dc 03 00 00       	push   $0x3dc
f01028ae:	68 35 6d 10 f0       	push   $0xf0106d35
f01028b3:	e8 88 d7 ff ff       	call   f0100040 <_panic>
f01028b8:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01028bf:	39 d0                	cmp    %edx,%eax
f01028c1:	74 19                	je     f01028dc <mem_init+0x151c>
f01028c3:	68 78 6b 10 f0       	push   $0xf0106b78
f01028c8:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01028cd:	68 dc 03 00 00       	push   $0x3dc
f01028d2:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102908:	68 ac 6b 10 f0       	push   $0xf0106bac
f010290d:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102912:	68 e0 03 00 00       	push   $0x3e0
f0102917:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102968:	68 c8 5d 10 f0       	push   $0xf0105dc8
f010296d:	68 e8 03 00 00       	push   $0x3e8
f0102972:	68 35 6d 10 f0       	push   $0xf0106d35
f0102977:	e8 c4 d6 ff ff       	call   f0100040 <_panic>
f010297c:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010297f:	8d 94 0b 00 d0 22 f0 	lea    -0xfdd3000(%ebx,%ecx,1),%edx
f0102986:	39 d0                	cmp    %edx,%eax
f0102988:	74 19                	je     f01029a3 <mem_init+0x15e3>
f010298a:	68 d4 6b 10 f0       	push   $0xf0106bd4
f010298f:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102994:	68 e8 03 00 00       	push   $0x3e8
f0102999:	68 35 6d 10 f0       	push   $0xf0106d35
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
f01029ca:	68 1c 6c 10 f0       	push   $0xf0106c1c
f01029cf:	68 5b 6d 10 f0       	push   $0xf0106d5b
f01029d4:	68 ea 03 00 00       	push   $0x3ea
f01029d9:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102a04:	81 fe 00 d0 26 f0    	cmp    $0xf026d000,%esi
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
f0102a28:	68 44 70 10 f0       	push   $0xf0107044
f0102a2d:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102a32:	68 f5 03 00 00       	push   $0x3f5
f0102a37:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102a50:	68 44 70 10 f0       	push   $0xf0107044
f0102a55:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102a5a:	68 f9 03 00 00       	push   $0x3f9
f0102a5f:	68 35 6d 10 f0       	push   $0xf0106d35
f0102a64:	e8 d7 d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a69:	f6 c2 02             	test   $0x2,%dl
f0102a6c:	75 38                	jne    f0102aa6 <mem_init+0x16e6>
f0102a6e:	68 55 70 10 f0       	push   $0xf0107055
f0102a73:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102a78:	68 fa 03 00 00       	push   $0x3fa
f0102a7d:	68 35 6d 10 f0       	push   $0xf0106d35
f0102a82:	e8 b9 d5 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102a87:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102a8b:	74 19                	je     f0102aa6 <mem_init+0x16e6>
f0102a8d:	68 66 70 10 f0       	push   $0xf0107066
f0102a92:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102a97:	68 fc 03 00 00       	push   $0x3fc
f0102a9c:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102ab7:	68 40 6c 10 f0       	push   $0xf0106c40
f0102abc:	e8 92 0d 00 00       	call   f0103853 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ac1:	a1 cc be 22 f0       	mov    0xf022becc,%eax
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
f0102ad1:	68 c8 5d 10 f0       	push   $0xf0105dc8
f0102ad6:	68 f2 00 00 00       	push   $0xf2
f0102adb:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102b18:	68 50 6e 10 f0       	push   $0xf0106e50
f0102b1d:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102b22:	68 d7 04 00 00       	push   $0x4d7
f0102b27:	68 35 6d 10 f0       	push   $0xf0106d35
f0102b2c:	e8 0f d5 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b31:	83 ec 0c             	sub    $0xc,%esp
f0102b34:	6a 00                	push   $0x0
f0102b36:	e8 67 e4 ff ff       	call   f0100fa2 <page_alloc>
f0102b3b:	89 c7                	mov    %eax,%edi
f0102b3d:	83 c4 10             	add    $0x10,%esp
f0102b40:	85 c0                	test   %eax,%eax
f0102b42:	75 19                	jne    f0102b5d <mem_init+0x179d>
f0102b44:	68 66 6e 10 f0       	push   $0xf0106e66
f0102b49:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102b4e:	68 d8 04 00 00       	push   $0x4d8
f0102b53:	68 35 6d 10 f0       	push   $0xf0106d35
f0102b58:	e8 e3 d4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b5d:	83 ec 0c             	sub    $0xc,%esp
f0102b60:	6a 00                	push   $0x0
f0102b62:	e8 3b e4 ff ff       	call   f0100fa2 <page_alloc>
f0102b67:	89 c6                	mov    %eax,%esi
f0102b69:	83 c4 10             	add    $0x10,%esp
f0102b6c:	85 c0                	test   %eax,%eax
f0102b6e:	75 19                	jne    f0102b89 <mem_init+0x17c9>
f0102b70:	68 7c 6e 10 f0       	push   $0xf0106e7c
f0102b75:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102b7a:	68 d9 04 00 00       	push   $0x4d9
f0102b7f:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102b94:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
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
f0102ba8:	3b 15 c8 be 22 f0    	cmp    0xf022bec8,%edx
f0102bae:	72 12                	jb     f0102bc2 <mem_init+0x1802>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bb0:	50                   	push   %eax
f0102bb1:	68 a4 5d 10 f0       	push   $0xf0105da4
f0102bb6:	6a 58                	push   $0x58
f0102bb8:	68 41 6d 10 f0       	push   $0xf0106d41
f0102bbd:	e8 7e d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102bc2:	83 ec 04             	sub    $0x4,%esp
f0102bc5:	68 00 10 00 00       	push   $0x1000
f0102bca:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102bcc:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bd1:	50                   	push   %eax
f0102bd2:	e8 cb 24 00 00       	call   f01050a2 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bd7:	89 f0                	mov    %esi,%eax
f0102bd9:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
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
f0102bed:	3b 15 c8 be 22 f0    	cmp    0xf022bec8,%edx
f0102bf3:	72 12                	jb     f0102c07 <mem_init+0x1847>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bf5:	50                   	push   %eax
f0102bf6:	68 a4 5d 10 f0       	push   $0xf0105da4
f0102bfb:	6a 58                	push   $0x58
f0102bfd:	68 41 6d 10 f0       	push   $0xf0106d41
f0102c02:	e8 39 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c07:	83 ec 04             	sub    $0x4,%esp
f0102c0a:	68 00 10 00 00       	push   $0x1000
f0102c0f:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c11:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c16:	50                   	push   %eax
f0102c17:	e8 86 24 00 00       	call   f01050a2 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c1c:	6a 02                	push   $0x2
f0102c1e:	68 00 10 00 00       	push   $0x1000
f0102c23:	57                   	push   %edi
f0102c24:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0102c2a:	e8 99 e6 ff ff       	call   f01012c8 <page_insert>
	assert(pp1->pp_ref == 1);
f0102c2f:	83 c4 20             	add    $0x20,%esp
f0102c32:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c37:	74 19                	je     f0102c52 <mem_init+0x1892>
f0102c39:	68 4d 6f 10 f0       	push   $0xf0106f4d
f0102c3e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102c43:	68 de 04 00 00       	push   $0x4de
f0102c48:	68 35 6d 10 f0       	push   $0xf0106d35
f0102c4d:	e8 ee d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c52:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c59:	01 01 01 
f0102c5c:	74 19                	je     f0102c77 <mem_init+0x18b7>
f0102c5e:	68 60 6c 10 f0       	push   $0xf0106c60
f0102c63:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102c68:	68 df 04 00 00       	push   $0x4df
f0102c6d:	68 35 6d 10 f0       	push   $0xf0106d35
f0102c72:	e8 c9 d3 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c77:	6a 02                	push   $0x2
f0102c79:	68 00 10 00 00       	push   $0x1000
f0102c7e:	56                   	push   %esi
f0102c7f:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0102c85:	e8 3e e6 ff ff       	call   f01012c8 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102c8a:	83 c4 10             	add    $0x10,%esp
f0102c8d:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102c94:	02 02 02 
f0102c97:	74 19                	je     f0102cb2 <mem_init+0x18f2>
f0102c99:	68 84 6c 10 f0       	push   $0xf0106c84
f0102c9e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102ca3:	68 e1 04 00 00       	push   $0x4e1
f0102ca8:	68 35 6d 10 f0       	push   $0xf0106d35
f0102cad:	e8 8e d3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102cb2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102cb7:	74 19                	je     f0102cd2 <mem_init+0x1912>
f0102cb9:	68 6f 6f 10 f0       	push   $0xf0106f6f
f0102cbe:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102cc3:	68 e2 04 00 00       	push   $0x4e2
f0102cc8:	68 35 6d 10 f0       	push   $0xf0106d35
f0102ccd:	e8 6e d3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102cd2:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cd7:	74 19                	je     f0102cf2 <mem_init+0x1932>
f0102cd9:	68 d9 6f 10 f0       	push   $0xf0106fd9
f0102cde:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102ce3:	68 e3 04 00 00       	push   $0x4e3
f0102ce8:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102cfe:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
f0102d04:	c1 f8 03             	sar    $0x3,%eax
f0102d07:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d0a:	89 c2                	mov    %eax,%edx
f0102d0c:	c1 ea 0c             	shr    $0xc,%edx
f0102d0f:	3b 15 c8 be 22 f0    	cmp    0xf022bec8,%edx
f0102d15:	72 12                	jb     f0102d29 <mem_init+0x1969>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d17:	50                   	push   %eax
f0102d18:	68 a4 5d 10 f0       	push   $0xf0105da4
f0102d1d:	6a 58                	push   $0x58
f0102d1f:	68 41 6d 10 f0       	push   $0xf0106d41
f0102d24:	e8 17 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d29:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d30:	03 03 03 
f0102d33:	74 19                	je     f0102d4e <mem_init+0x198e>
f0102d35:	68 a8 6c 10 f0       	push   $0xf0106ca8
f0102d3a:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102d3f:	68 e5 04 00 00       	push   $0x4e5
f0102d44:	68 35 6d 10 f0       	push   $0xf0106d35
f0102d49:	e8 f2 d2 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d4e:	83 ec 08             	sub    $0x8,%esp
f0102d51:	68 00 10 00 00       	push   $0x1000
f0102d56:	ff 35 cc be 22 f0    	pushl  0xf022becc
f0102d5c:	e8 21 e5 ff ff       	call   f0101282 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d61:	83 c4 10             	add    $0x10,%esp
f0102d64:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d69:	74 19                	je     f0102d84 <mem_init+0x19c4>
f0102d6b:	68 a7 6f 10 f0       	push   $0xf0106fa7
f0102d70:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102d75:	68 e7 04 00 00       	push   $0x4e7
f0102d7a:	68 35 6d 10 f0       	push   $0xf0106d35
f0102d7f:	e8 bc d2 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102d84:	8b 0d cc be 22 f0    	mov    0xf022becc,%ecx
f0102d8a:	8b 11                	mov    (%ecx),%edx
f0102d8c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d92:	89 d8                	mov    %ebx,%eax
f0102d94:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
f0102d9a:	c1 f8 03             	sar    $0x3,%eax
f0102d9d:	c1 e0 0c             	shl    $0xc,%eax
f0102da0:	39 c2                	cmp    %eax,%edx
f0102da2:	74 19                	je     f0102dbd <mem_init+0x19fd>
f0102da4:	68 30 66 10 f0       	push   $0xf0106630
f0102da9:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102dae:	68 ea 04 00 00       	push   $0x4ea
f0102db3:	68 35 6d 10 f0       	push   $0xf0106d35
f0102db8:	e8 83 d2 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102dbd:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102dc3:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102dc8:	74 19                	je     f0102de3 <mem_init+0x1a23>
f0102dca:	68 5e 6f 10 f0       	push   $0xf0106f5e
f0102dcf:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0102dd4:	68 ec 04 00 00       	push   $0x4ec
f0102dd9:	68 35 6d 10 f0       	push   $0xf0106d35
f0102dde:	e8 5d d2 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102de3:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102de9:	83 ec 0c             	sub    $0xc,%esp
f0102dec:	53                   	push   %ebx
f0102ded:	e8 26 e2 ff ff       	call   f0101018 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102df2:	c7 04 24 d4 6c 10 f0 	movl   $0xf0106cd4,(%esp)
f0102df9:	e8 55 0a 00 00       	call   f0103853 <cprintf>
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
f0102e3f:	a3 60 b2 22 f0       	mov    %eax,0xf022b260
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
f0102e63:	a1 c8 be 22 f0       	mov    0xf022bec8,%eax
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
f0102e89:	89 15 60 b2 22 f0    	mov    %edx,0xf022b260
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
f0102ea6:	68 a4 5d 10 f0       	push   $0xf0105da4
f0102eab:	68 14 03 00 00       	push   $0x314
f0102eb0:	68 35 6d 10 f0       	push   $0xf0106d35
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
f0102ed9:	89 15 60 b2 22 f0    	mov    %edx,0xf022b260
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
f0102f24:	ff 35 60 b2 22 f0    	pushl  0xf022b260
f0102f2a:	ff 73 48             	pushl  0x48(%ebx)
f0102f2d:	68 00 6d 10 f0       	push   $0xf0106d00
f0102f32:	e8 1c 09 00 00       	call   f0103853 <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f37:	89 1c 24             	mov    %ebx,(%esp)
f0102f3a:	e8 4d 06 00 00       	call   f010358c <env_destroy>
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
f0102f7d:	68 74 70 10 f0       	push   $0xf0107074
f0102f82:	68 34 01 00 00       	push   $0x134
f0102f87:	68 87 70 10 f0       	push   $0xf0107087
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
f0102fa7:	68 f4 70 10 f0       	push   $0xf01070f4
f0102fac:	68 36 01 00 00       	push   $0x136
f0102fb1:	68 87 70 10 f0       	push   $0xf0107087
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
f0102fdc:	e8 e6 26 00 00       	call   f01056c7 <cpunum>
f0102fe1:	6b c0 74             	imul   $0x74,%eax,%eax
f0102fe4:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
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
f0103001:	03 1d 6c b2 22 f0    	add    0xf022b26c,%ebx
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
f0103026:	e8 9c 26 00 00       	call   f01056c7 <cpunum>
f010302b:	6b c0 74             	imul   $0x74,%eax,%eax
f010302e:	39 98 48 c0 22 f0    	cmp    %ebx,-0xfdd3fb8(%eax)
f0103034:	74 26                	je     f010305c <envid2env+0x8f>
f0103036:	8b 73 4c             	mov    0x4c(%ebx),%esi
f0103039:	e8 89 26 00 00       	call   f01056c7 <cpunum>
f010303e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103041:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
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
f0103094:	8b 0d 6c b2 22 f0    	mov    0xf022b26c,%ecx
f010309a:	8b 15 70 b2 22 f0    	mov    0xf022b270,%edx
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
f01030cb:	89 15 70 b2 22 f0    	mov    %edx,0xf022b270
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
f01030df:	8b 1d 70 b2 22 f0    	mov    0xf022b270,%ebx
f01030e5:	85 db                	test   %ebx,%ebx
f01030e7:	0f 84 69 01 00 00    	je     f0103256 <env_alloc+0x17e>
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
f01030fc:	0f 84 5b 01 00 00    	je     f010325d <env_alloc+0x185>
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
f0103107:	2b 05 d0 be 22 f0    	sub    0xf022bed0,%eax
f010310d:	c1 f8 03             	sar    $0x3,%eax
f0103110:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103113:	89 c2                	mov    %eax,%edx
f0103115:	c1 ea 0c             	shr    $0xc,%edx
f0103118:	3b 15 c8 be 22 f0    	cmp    0xf022bec8,%edx
f010311e:	72 12                	jb     f0103132 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103120:	50                   	push   %eax
f0103121:	68 a4 5d 10 f0       	push   $0xf0105da4
f0103126:	6a 58                	push   $0x58
f0103128:	68 41 6d 10 f0       	push   $0xf0106d41
f010312d:	e8 0e cf ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103132:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103137:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f010313a:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f010313f:	8b 15 cc be 22 f0    	mov    0xf022becc,%edx
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
f0103163:	68 c8 5d 10 f0       	push   $0xf0105dc8
f0103168:	68 d0 00 00 00       	push   $0xd0
f010316d:	68 87 70 10 f0       	push   $0xf0107087
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
f010319d:	2b 15 6c b2 22 f0    	sub    0xf022b26c,%edx
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
f01031d4:	e8 c9 1e 00 00       	call   f01050a2 <memset>
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

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f01031f8:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f01031ff:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103203:	8b 43 44             	mov    0x44(%ebx),%eax
f0103206:	a3 70 b2 22 f0       	mov    %eax,0xf022b270
	*newenv_store = e;
f010320b:	8b 45 08             	mov    0x8(%ebp),%eax
f010320e:	89 18                	mov    %ebx,(%eax)

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f0103210:	8b 5b 48             	mov    0x48(%ebx),%ebx
f0103213:	e8 af 24 00 00       	call   f01056c7 <cpunum>
f0103218:	6b c0 74             	imul   $0x74,%eax,%eax
f010321b:	83 c4 10             	add    $0x10,%esp
f010321e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103223:	83 b8 48 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fb8(%eax)
f010322a:	74 11                	je     f010323d <env_alloc+0x165>
f010322c:	e8 96 24 00 00       	call   f01056c7 <cpunum>
f0103231:	6b c0 74             	imul   $0x74,%eax,%eax
f0103234:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f010323a:	8b 50 48             	mov    0x48(%eax),%edx
f010323d:	83 ec 04             	sub    $0x4,%esp
f0103240:	53                   	push   %ebx
f0103241:	52                   	push   %edx
f0103242:	68 92 70 10 f0       	push   $0xf0107092
f0103247:	e8 07 06 00 00       	call   f0103853 <cprintf>
	return 0;
f010324c:	83 c4 10             	add    $0x10,%esp
f010324f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103254:	eb 0c                	jmp    f0103262 <env_alloc+0x18a>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103256:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010325b:	eb 05                	jmp    f0103262 <env_alloc+0x18a>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010325d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103262:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103265:	c9                   	leave  
f0103266:	c3                   	ret    

f0103267 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103267:	55                   	push   %ebp
f0103268:	89 e5                	mov    %esp,%ebp
f010326a:	57                   	push   %edi
f010326b:	56                   	push   %esi
f010326c:	53                   	push   %ebx
f010326d:	83 ec 34             	sub    $0x34,%esp
f0103270:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0103273:	6a 00                	push   $0x0
f0103275:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103278:	50                   	push   %eax
f0103279:	e8 5a fe ff ff       	call   f01030d8 <env_alloc>
	if (r){
f010327e:	83 c4 10             	add    $0x10,%esp
f0103281:	85 c0                	test   %eax,%eax
f0103283:	74 15                	je     f010329a <env_create+0x33>
	panic("env_alloc: %e", r);
f0103285:	50                   	push   %eax
f0103286:	68 a7 70 10 f0       	push   $0xf01070a7
f010328b:	68 b1 01 00 00       	push   $0x1b1
f0103290:	68 87 70 10 f0       	push   $0xf0107087
f0103295:	e8 a6 cd ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f010329a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010329d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f01032a0:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f01032a6:	74 17                	je     f01032bf <env_create+0x58>
	{
		panic ("Not a valid ELF binary image");
f01032a8:	83 ec 04             	sub    $0x4,%esp
f01032ab:	68 b5 70 10 f0       	push   $0xf01070b5
f01032b0:	68 80 01 00 00       	push   $0x180
f01032b5:	68 87 70 10 f0       	push   $0xf0107087
f01032ba:	e8 81 cd ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f01032bf:	89 fb                	mov    %edi,%ebx
f01032c1:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f01032c4:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01032c8:	c1 e6 05             	shl    $0x5,%esi
f01032cb:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f01032cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032d0:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032d3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032d8:	77 15                	ja     f01032ef <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032da:	50                   	push   %eax
f01032db:	68 c8 5d 10 f0       	push   $0xf0105dc8
f01032e0:	68 87 01 00 00       	push   $0x187
f01032e5:	68 87 70 10 f0       	push   $0xf0107087
f01032ea:	e8 51 cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032ef:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01032f4:	0f 22 d8             	mov    %eax,%cr3
f01032f7:	eb 60                	jmp    f0103359 <env_create+0xf2>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f01032f9:	83 3b 01             	cmpl   $0x1,(%ebx)
f01032fc:	75 58                	jne    f0103356 <env_create+0xef>
		
		if(ph->p_memsz < ph->p_filesz){
f01032fe:	8b 4b 14             	mov    0x14(%ebx),%ecx
f0103301:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f0103304:	73 17                	jae    f010331d <env_create+0xb6>
		panic ("Memory size is smaller than file size!!");
f0103306:	83 ec 04             	sub    $0x4,%esp
f0103309:	68 18 71 10 f0       	push   $0xf0107118
f010330e:	68 8d 01 00 00       	push   $0x18d
f0103313:	68 87 70 10 f0       	push   $0xf0107087
f0103318:	e8 23 cd ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f010331d:	8b 53 08             	mov    0x8(%ebx),%edx
f0103320:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103323:	e8 1f fc ff ff       	call   f0102f47 <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103328:	83 ec 04             	sub    $0x4,%esp
f010332b:	ff 73 10             	pushl  0x10(%ebx)
f010332e:	89 f8                	mov    %edi,%eax
f0103330:	03 43 04             	add    0x4(%ebx),%eax
f0103333:	50                   	push   %eax
f0103334:	ff 73 08             	pushl  0x8(%ebx)
f0103337:	e8 1b 1e 00 00       	call   f0105157 <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f010333c:	8b 43 10             	mov    0x10(%ebx),%eax
f010333f:	83 c4 0c             	add    $0xc,%esp
f0103342:	8b 53 14             	mov    0x14(%ebx),%edx
f0103345:	29 c2                	sub    %eax,%edx
f0103347:	52                   	push   %edx
f0103348:	6a 00                	push   $0x0
f010334a:	03 43 08             	add    0x8(%ebx),%eax
f010334d:	50                   	push   %eax
f010334e:	e8 4f 1d 00 00       	call   f01050a2 <memset>
f0103353:	83 c4 10             	add    $0x10,%esp
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0103356:	83 c3 20             	add    $0x20,%ebx
f0103359:	39 de                	cmp    %ebx,%esi
f010335b:	77 9c                	ja     f01032f9 <env_create+0x92>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f010335d:	a1 cc be 22 f0       	mov    0xf022becc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103362:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103367:	77 15                	ja     f010337e <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103369:	50                   	push   %eax
f010336a:	68 c8 5d 10 f0       	push   $0xf0105dc8
f010336f:	68 9a 01 00 00       	push   $0x19a
f0103374:	68 87 70 10 f0       	push   $0xf0107087
f0103379:	e8 c2 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010337e:	05 00 00 00 10       	add    $0x10000000,%eax
f0103383:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0103386:	8b 47 18             	mov    0x18(%edi),%eax
f0103389:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010338c:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f010338f:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103394:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f0103399:	89 f8                	mov    %edi,%eax
f010339b:	e8 a7 fb ff ff       	call   f0102f47 <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f01033a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01033a3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01033a6:	89 50 50             	mov    %edx,0x50(%eax)
}
f01033a9:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01033ac:	5b                   	pop    %ebx
f01033ad:	5e                   	pop    %esi
f01033ae:	5f                   	pop    %edi
f01033af:	5d                   	pop    %ebp
f01033b0:	c3                   	ret    

f01033b1 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033b1:	55                   	push   %ebp
f01033b2:	89 e5                	mov    %esp,%ebp
f01033b4:	57                   	push   %edi
f01033b5:	56                   	push   %esi
f01033b6:	53                   	push   %ebx
f01033b7:	83 ec 1c             	sub    $0x1c,%esp
f01033ba:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033bd:	e8 05 23 00 00       	call   f01056c7 <cpunum>
f01033c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01033c5:	39 b8 48 c0 22 f0    	cmp    %edi,-0xfdd3fb8(%eax)
f01033cb:	75 29                	jne    f01033f6 <env_free+0x45>
		lcr3(PADDR(kern_pgdir));
f01033cd:	a1 cc be 22 f0       	mov    0xf022becc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033d2:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033d7:	77 15                	ja     f01033ee <env_free+0x3d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033d9:	50                   	push   %eax
f01033da:	68 c8 5d 10 f0       	push   $0xf0105dc8
f01033df:	68 c7 01 00 00       	push   $0x1c7
f01033e4:	68 87 70 10 f0       	push   $0xf0107087
f01033e9:	e8 52 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033ee:	05 00 00 00 10       	add    $0x10000000,%eax
f01033f3:	0f 22 d8             	mov    %eax,%cr3

	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
f01033f6:	8b 5f 48             	mov    0x48(%edi),%ebx
f01033f9:	e8 c9 22 00 00       	call   f01056c7 <cpunum>
f01033fe:	6b c0 74             	imul   $0x74,%eax,%eax
f0103401:	ba 00 00 00 00       	mov    $0x0,%edx
f0103406:	83 b8 48 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fb8(%eax)
f010340d:	74 11                	je     f0103420 <env_free+0x6f>
f010340f:	e8 b3 22 00 00       	call   f01056c7 <cpunum>
f0103414:	6b c0 74             	imul   $0x74,%eax,%eax
f0103417:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f010341d:	8b 50 48             	mov    0x48(%eax),%edx
f0103420:	83 ec 04             	sub    $0x4,%esp
f0103423:	53                   	push   %ebx
f0103424:	52                   	push   %edx
f0103425:	68 d2 70 10 f0       	push   $0xf01070d2
f010342a:	e8 24 04 00 00       	call   f0103853 <cprintf>
f010342f:	83 c4 10             	add    $0x10,%esp

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f0103432:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f0103439:	8b 55 e0             	mov    -0x20(%ebp),%edx
f010343c:	89 d0                	mov    %edx,%eax
f010343e:	c1 e0 02             	shl    $0x2,%eax
f0103441:	89 45 d8             	mov    %eax,-0x28(%ebp)

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103444:	8b 47 60             	mov    0x60(%edi),%eax
f0103447:	8b 34 90             	mov    (%eax,%edx,4),%esi
f010344a:	f7 c6 01 00 00 00    	test   $0x1,%esi
f0103450:	0f 84 a8 00 00 00    	je     f01034fe <env_free+0x14d>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103456:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010345c:	89 f0                	mov    %esi,%eax
f010345e:	c1 e8 0c             	shr    $0xc,%eax
f0103461:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103464:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
f010346a:	72 15                	jb     f0103481 <env_free+0xd0>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010346c:	56                   	push   %esi
f010346d:	68 a4 5d 10 f0       	push   $0xf0105da4
f0103472:	68 d6 01 00 00       	push   $0x1d6
f0103477:	68 87 70 10 f0       	push   $0xf0107087
f010347c:	e8 bf cb ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103481:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103484:	c1 e0 16             	shl    $0x16,%eax
f0103487:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010348a:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010348f:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103496:	01 
f0103497:	74 17                	je     f01034b0 <env_free+0xff>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103499:	83 ec 08             	sub    $0x8,%esp
f010349c:	89 d8                	mov    %ebx,%eax
f010349e:	c1 e0 0c             	shl    $0xc,%eax
f01034a1:	0b 45 e4             	or     -0x1c(%ebp),%eax
f01034a4:	50                   	push   %eax
f01034a5:	ff 77 60             	pushl  0x60(%edi)
f01034a8:	e8 d5 dd ff ff       	call   f0101282 <page_remove>
f01034ad:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f01034b0:	83 c3 01             	add    $0x1,%ebx
f01034b3:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f01034b9:	75 d4                	jne    f010348f <env_free+0xde>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f01034bb:	8b 47 60             	mov    0x60(%edi),%eax
f01034be:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01034c1:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034c8:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01034cb:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
f01034d1:	72 14                	jb     f01034e7 <env_free+0x136>
		panic("pa2page called with invalid pa");
f01034d3:	83 ec 04             	sub    $0x4,%esp
f01034d6:	68 40 71 10 f0       	push   $0xf0107140
f01034db:	6a 51                	push   $0x51
f01034dd:	68 41 6d 10 f0       	push   $0xf0106d41
f01034e2:	e8 59 cb ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01034e7:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034ea:	a1 d0 be 22 f0       	mov    0xf022bed0,%eax
f01034ef:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034f2:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01034f5:	50                   	push   %eax
f01034f6:	e8 6e db ff ff       	call   f0101069 <page_decref>
f01034fb:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034fe:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f0103502:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103505:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f010350a:	0f 85 29 ff ff ff    	jne    f0103439 <env_free+0x88>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f0103510:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103513:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103518:	77 15                	ja     f010352f <env_free+0x17e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010351a:	50                   	push   %eax
f010351b:	68 c8 5d 10 f0       	push   $0xf0105dc8
f0103520:	68 e4 01 00 00       	push   $0x1e4
f0103525:	68 87 70 10 f0       	push   $0xf0107087
f010352a:	e8 11 cb ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f010352f:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f0103536:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010353b:	c1 e8 0c             	shr    $0xc,%eax
f010353e:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
f0103544:	72 14                	jb     f010355a <env_free+0x1a9>
		panic("pa2page called with invalid pa");
f0103546:	83 ec 04             	sub    $0x4,%esp
f0103549:	68 40 71 10 f0       	push   $0xf0107140
f010354e:	6a 51                	push   $0x51
f0103550:	68 41 6d 10 f0       	push   $0xf0106d41
f0103555:	e8 e6 ca ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f010355a:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f010355d:	8b 15 d0 be 22 f0    	mov    0xf022bed0,%edx
f0103563:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103566:	50                   	push   %eax
f0103567:	e8 fd da ff ff       	call   f0101069 <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f010356c:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f0103573:	a1 70 b2 22 f0       	mov    0xf022b270,%eax
f0103578:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f010357b:	89 3d 70 b2 22 f0    	mov    %edi,0xf022b270
f0103581:	83 c4 10             	add    $0x10,%esp
}
f0103584:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103587:	5b                   	pop    %ebx
f0103588:	5e                   	pop    %esi
f0103589:	5f                   	pop    %edi
f010358a:	5d                   	pop    %ebp
f010358b:	c3                   	ret    

f010358c <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f010358c:	55                   	push   %ebp
f010358d:	89 e5                	mov    %esp,%ebp
f010358f:	53                   	push   %ebx
f0103590:	83 ec 04             	sub    $0x4,%esp
f0103593:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103596:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f010359a:	75 19                	jne    f01035b5 <env_destroy+0x29>
f010359c:	e8 26 21 00 00       	call   f01056c7 <cpunum>
f01035a1:	6b c0 74             	imul   $0x74,%eax,%eax
f01035a4:	39 98 48 c0 22 f0    	cmp    %ebx,-0xfdd3fb8(%eax)
f01035aa:	74 09                	je     f01035b5 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f01035ac:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f01035b3:	eb 33                	jmp    f01035e8 <env_destroy+0x5c>
	}

	env_free(e);
f01035b5:	83 ec 0c             	sub    $0xc,%esp
f01035b8:	53                   	push   %ebx
f01035b9:	e8 f3 fd ff ff       	call   f01033b1 <env_free>

	if (curenv == e) {
f01035be:	e8 04 21 00 00       	call   f01056c7 <cpunum>
f01035c3:	6b c0 74             	imul   $0x74,%eax,%eax
f01035c6:	83 c4 10             	add    $0x10,%esp
f01035c9:	39 98 48 c0 22 f0    	cmp    %ebx,-0xfdd3fb8(%eax)
f01035cf:	75 17                	jne    f01035e8 <env_destroy+0x5c>
		curenv = NULL;
f01035d1:	e8 f1 20 00 00       	call   f01056c7 <cpunum>
f01035d6:	6b c0 74             	imul   $0x74,%eax,%eax
f01035d9:	c7 80 48 c0 22 f0 00 	movl   $0x0,-0xfdd3fb8(%eax)
f01035e0:	00 00 00 
		sched_yield();
f01035e3:	e8 92 0a 00 00       	call   f010407a <sched_yield>
	}
}
f01035e8:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035eb:	c9                   	leave  
f01035ec:	c3                   	ret    

f01035ed <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035ed:	55                   	push   %ebp
f01035ee:	89 e5                	mov    %esp,%ebp
f01035f0:	53                   	push   %ebx
f01035f1:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01035f4:	e8 ce 20 00 00       	call   f01056c7 <cpunum>
f01035f9:	6b c0 74             	imul   $0x74,%eax,%eax
f01035fc:	8b 98 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%ebx
f0103602:	e8 c0 20 00 00       	call   f01056c7 <cpunum>
f0103607:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f010360a:	8b 65 08             	mov    0x8(%ebp),%esp
f010360d:	61                   	popa   
f010360e:	07                   	pop    %es
f010360f:	1f                   	pop    %ds
f0103610:	83 c4 08             	add    $0x8,%esp
f0103613:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f0103614:	83 ec 04             	sub    $0x4,%esp
f0103617:	68 e8 70 10 f0       	push   $0xf01070e8
f010361c:	68 1a 02 00 00       	push   $0x21a
f0103621:	68 87 70 10 f0       	push   $0xf0107087
f0103626:	e8 15 ca ff ff       	call   f0100040 <_panic>

f010362b <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f010362b:	55                   	push   %ebp
f010362c:	89 e5                	mov    %esp,%ebp
f010362e:	53                   	push   %ebx
f010362f:	83 ec 04             	sub    $0x4,%esp
f0103632:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f0103635:	e8 8d 20 00 00       	call   f01056c7 <cpunum>
f010363a:	6b c0 74             	imul   $0x74,%eax,%eax
f010363d:	83 b8 48 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fb8(%eax)
f0103644:	75 10                	jne    f0103656 <env_run+0x2b>
	curenv = e;
f0103646:	e8 7c 20 00 00       	call   f01056c7 <cpunum>
f010364b:	6b c0 74             	imul   $0x74,%eax,%eax
f010364e:	89 98 48 c0 22 f0    	mov    %ebx,-0xfdd3fb8(%eax)
f0103654:	eb 29                	jmp    f010367f <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103656:	e8 6c 20 00 00       	call   f01056c7 <cpunum>
f010365b:	6b c0 74             	imul   $0x74,%eax,%eax
f010365e:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0103664:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103668:	75 15                	jne    f010367f <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f010366a:	e8 58 20 00 00       	call   f01056c7 <cpunum>
f010366f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103672:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0103678:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f010367f:	e8 43 20 00 00       	call   f01056c7 <cpunum>
f0103684:	6b c0 74             	imul   $0x74,%eax,%eax
f0103687:	89 98 48 c0 22 f0    	mov    %ebx,-0xfdd3fb8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f010368d:	e8 35 20 00 00       	call   f01056c7 <cpunum>
f0103692:	6b c0 74             	imul   $0x74,%eax,%eax
f0103695:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f010369b:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f01036a2:	e8 20 20 00 00       	call   f01056c7 <cpunum>
f01036a7:	6b c0 74             	imul   $0x74,%eax,%eax
f01036aa:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f01036b0:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f01036b4:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01036b7:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01036bc:	77 15                	ja     f01036d3 <env_run+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01036be:	50                   	push   %eax
f01036bf:	68 c8 5d 10 f0       	push   $0xf0105dc8
f01036c4:	68 46 02 00 00       	push   $0x246
f01036c9:	68 87 70 10 f0       	push   $0xf0107087
f01036ce:	e8 6d c9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01036d3:	05 00 00 00 10       	add    $0x10000000,%eax
f01036d8:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f01036db:	83 ec 0c             	sub    $0xc,%esp
f01036de:	68 c0 04 12 f0       	push   $0xf01204c0
f01036e3:	e8 e7 22 00 00       	call   f01059cf <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01036e8:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01036ea:	89 1c 24             	mov    %ebx,(%esp)
f01036ed:	e8 fb fe ff ff       	call   f01035ed <env_pop_tf>

f01036f2 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036f2:	55                   	push   %ebp
f01036f3:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036f5:	ba 70 00 00 00       	mov    $0x70,%edx
f01036fa:	8b 45 08             	mov    0x8(%ebp),%eax
f01036fd:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036fe:	b2 71                	mov    $0x71,%dl
f0103700:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103701:	0f b6 c0             	movzbl %al,%eax
}
f0103704:	5d                   	pop    %ebp
f0103705:	c3                   	ret    

f0103706 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103706:	55                   	push   %ebp
f0103707:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103709:	ba 70 00 00 00       	mov    $0x70,%edx
f010370e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103711:	ee                   	out    %al,(%dx)
f0103712:	b2 71                	mov    $0x71,%dl
f0103714:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103717:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103718:	5d                   	pop    %ebp
f0103719:	c3                   	ret    

f010371a <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f010371a:	55                   	push   %ebp
f010371b:	89 e5                	mov    %esp,%ebp
f010371d:	56                   	push   %esi
f010371e:	53                   	push   %ebx
f010371f:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f0103722:	66 a3 e8 03 12 f0    	mov    %ax,0xf01203e8
	if (!didinit)
f0103728:	80 3d 74 b2 22 f0 00 	cmpb   $0x0,0xf022b274
f010372f:	74 57                	je     f0103788 <irq_setmask_8259A+0x6e>
f0103731:	89 c6                	mov    %eax,%esi
f0103733:	ba 21 00 00 00       	mov    $0x21,%edx
f0103738:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f0103739:	66 c1 e8 08          	shr    $0x8,%ax
f010373d:	b2 a1                	mov    $0xa1,%dl
f010373f:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f0103740:	83 ec 0c             	sub    $0xc,%esp
f0103743:	68 5f 71 10 f0       	push   $0xf010715f
f0103748:	e8 06 01 00 00       	call   f0103853 <cprintf>
f010374d:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f0103750:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103755:	0f b7 f6             	movzwl %si,%esi
f0103758:	f7 d6                	not    %esi
f010375a:	0f a3 de             	bt     %ebx,%esi
f010375d:	73 11                	jae    f0103770 <irq_setmask_8259A+0x56>
			cprintf(" %d", i);
f010375f:	83 ec 08             	sub    $0x8,%esp
f0103762:	53                   	push   %ebx
f0103763:	68 77 76 10 f0       	push   $0xf0107677
f0103768:	e8 e6 00 00 00       	call   f0103853 <cprintf>
f010376d:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f0103770:	83 c3 01             	add    $0x1,%ebx
f0103773:	83 fb 10             	cmp    $0x10,%ebx
f0103776:	75 e2                	jne    f010375a <irq_setmask_8259A+0x40>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103778:	83 ec 0c             	sub    $0xc,%esp
f010377b:	68 12 76 10 f0       	push   $0xf0107612
f0103780:	e8 ce 00 00 00       	call   f0103853 <cprintf>
f0103785:	83 c4 10             	add    $0x10,%esp
}
f0103788:	8d 65 f8             	lea    -0x8(%ebp),%esp
f010378b:	5b                   	pop    %ebx
f010378c:	5e                   	pop    %esi
f010378d:	5d                   	pop    %ebp
f010378e:	c3                   	ret    

f010378f <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010378f:	c6 05 74 b2 22 f0 01 	movb   $0x1,0xf022b274
f0103796:	ba 21 00 00 00       	mov    $0x21,%edx
f010379b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01037a0:	ee                   	out    %al,(%dx)
f01037a1:	b2 a1                	mov    $0xa1,%dl
f01037a3:	ee                   	out    %al,(%dx)
f01037a4:	b2 20                	mov    $0x20,%dl
f01037a6:	b8 11 00 00 00       	mov    $0x11,%eax
f01037ab:	ee                   	out    %al,(%dx)
f01037ac:	b2 21                	mov    $0x21,%dl
f01037ae:	b8 20 00 00 00       	mov    $0x20,%eax
f01037b3:	ee                   	out    %al,(%dx)
f01037b4:	b8 04 00 00 00       	mov    $0x4,%eax
f01037b9:	ee                   	out    %al,(%dx)
f01037ba:	b8 03 00 00 00       	mov    $0x3,%eax
f01037bf:	ee                   	out    %al,(%dx)
f01037c0:	b2 a0                	mov    $0xa0,%dl
f01037c2:	b8 11 00 00 00       	mov    $0x11,%eax
f01037c7:	ee                   	out    %al,(%dx)
f01037c8:	b2 a1                	mov    $0xa1,%dl
f01037ca:	b8 28 00 00 00       	mov    $0x28,%eax
f01037cf:	ee                   	out    %al,(%dx)
f01037d0:	b8 02 00 00 00       	mov    $0x2,%eax
f01037d5:	ee                   	out    %al,(%dx)
f01037d6:	b8 01 00 00 00       	mov    $0x1,%eax
f01037db:	ee                   	out    %al,(%dx)
f01037dc:	b2 20                	mov    $0x20,%dl
f01037de:	b8 68 00 00 00       	mov    $0x68,%eax
f01037e3:	ee                   	out    %al,(%dx)
f01037e4:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037e9:	ee                   	out    %al,(%dx)
f01037ea:	b2 a0                	mov    $0xa0,%dl
f01037ec:	b8 68 00 00 00       	mov    $0x68,%eax
f01037f1:	ee                   	out    %al,(%dx)
f01037f2:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037f7:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01037f8:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f01037ff:	66 83 f8 ff          	cmp    $0xffff,%ax
f0103803:	74 13                	je     f0103818 <pic_init+0x89>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f0103805:	55                   	push   %ebp
f0103806:	89 e5                	mov    %esp,%ebp
f0103808:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f010380b:	0f b7 c0             	movzwl %ax,%eax
f010380e:	50                   	push   %eax
f010380f:	e8 06 ff ff ff       	call   f010371a <irq_setmask_8259A>
f0103814:	83 c4 10             	add    $0x10,%esp
}
f0103817:	c9                   	leave  
f0103818:	f3 c3                	repz ret 

f010381a <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f010381a:	55                   	push   %ebp
f010381b:	89 e5                	mov    %esp,%ebp
f010381d:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f0103820:	ff 75 08             	pushl  0x8(%ebp)
f0103823:	e8 1d cf ff ff       	call   f0100745 <cputchar>
f0103828:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f010382b:	c9                   	leave  
f010382c:	c3                   	ret    

f010382d <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010382d:	55                   	push   %ebp
f010382e:	89 e5                	mov    %esp,%ebp
f0103830:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f0103833:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f010383a:	ff 75 0c             	pushl  0xc(%ebp)
f010383d:	ff 75 08             	pushl  0x8(%ebp)
f0103840:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103843:	50                   	push   %eax
f0103844:	68 1a 38 10 f0       	push   $0xf010381a
f0103849:	e8 e1 11 00 00       	call   f0104a2f <vprintfmt>
	return cnt;
}
f010384e:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103851:	c9                   	leave  
f0103852:	c3                   	ret    

f0103853 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103853:	55                   	push   %ebp
f0103854:	89 e5                	mov    %esp,%ebp
f0103856:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103859:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010385c:	50                   	push   %eax
f010385d:	ff 75 08             	pushl  0x8(%ebp)
f0103860:	e8 c8 ff ff ff       	call   f010382d <vcprintf>
	va_end(ap);

	return cnt;
}
f0103865:	c9                   	leave  
f0103866:	c3                   	ret    

f0103867 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103867:	55                   	push   %ebp
f0103868:	89 e5                	mov    %esp,%ebp
f010386a:	56                   	push   %esi
f010386b:	53                   	push   %ebx
	// bottom three bits are special; we leave them 0)
	ltr(GD_TSS0);
	// Load the IDT
	lidt(&idt_pd);  */
	
	int i = cpunum();
f010386c:	e8 56 1e 00 00       	call   f01056c7 <cpunum>
f0103871:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f0103873:	e8 4f 1e 00 00       	call   f01056c7 <cpunum>
f0103878:	89 c6                	mov    %eax,%esi
f010387a:	e8 48 1e 00 00       	call   f01056c7 <cpunum>
f010387f:	6b f6 74             	imul   $0x74,%esi,%esi
f0103882:	c1 e0 0f             	shl    $0xf,%eax
f0103885:	8d 80 00 50 23 f0    	lea    -0xfdcb000(%eax),%eax
f010388b:	89 86 50 c0 22 f0    	mov    %eax,-0xfdd3fb0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f0103891:	e8 31 1e 00 00       	call   f01056c7 <cpunum>
f0103896:	6b c0 74             	imul   $0x74,%eax,%eax
f0103899:	66 c7 80 54 c0 22 f0 	movw   $0x10,-0xfdd3fac(%eax)
f01038a0:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f01038a2:	8d 43 05             	lea    0x5(%ebx),%eax
f01038a5:	6b d3 74             	imul   $0x74,%ebx,%edx
f01038a8:	81 c2 4c c0 22 f0    	add    $0xf022c04c,%edx
f01038ae:	66 c7 04 c5 80 03 12 	movw   $0x67,-0xfedfc80(,%eax,8)
f01038b5:	f0 67 00 
f01038b8:	66 89 14 c5 82 03 12 	mov    %dx,-0xfedfc7e(,%eax,8)
f01038bf:	f0 
f01038c0:	89 d1                	mov    %edx,%ecx
f01038c2:	c1 e9 10             	shr    $0x10,%ecx
f01038c5:	88 0c c5 84 03 12 f0 	mov    %cl,-0xfedfc7c(,%eax,8)
f01038cc:	c6 04 c5 86 03 12 f0 	movb   $0x40,-0xfedfc7a(,%eax,8)
f01038d3:	40 
f01038d4:	c1 ea 18             	shr    $0x18,%edx
f01038d7:	88 14 c5 87 03 12 f0 	mov    %dl,-0xfedfc79(,%eax,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f01038de:	c6 04 c5 85 03 12 f0 	movb   $0x89,-0xfedfc7b(,%eax,8)
f01038e5:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f01038e6:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038ed:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038f0:	b8 ea 03 12 f0       	mov    $0xf01203ea,%eax
f01038f5:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f01038f8:	5b                   	pop    %ebx
f01038f9:	5e                   	pop    %esi
f01038fa:	5d                   	pop    %ebp
f01038fb:	c3                   	ret    

f01038fc <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f01038fc:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f0103901:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f0103908:	66 89 14 c5 80 b2 22 	mov    %dx,-0xfdd4d80(,%eax,8)
f010390f:	f0 
f0103910:	66 c7 04 c5 82 b2 22 	movw   $0x8,-0xfdd4d7e(,%eax,8)
f0103917:	f0 08 00 
f010391a:	c6 04 c5 84 b2 22 f0 	movb   $0x0,-0xfdd4d7c(,%eax,8)
f0103921:	00 
f0103922:	c6 04 c5 85 b2 22 f0 	movb   $0x8e,-0xfdd4d7b(,%eax,8)
f0103929:	8e 
f010392a:	c1 ea 10             	shr    $0x10,%edx
f010392d:	66 89 14 c5 86 b2 22 	mov    %dx,-0xfdd4d7a(,%eax,8)
f0103934:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i; 
	for (i=0; i<= T_SIMDERR;i++){
f0103935:	83 c0 01             	add    $0x1,%eax
f0103938:	83 f8 14             	cmp    $0x14,%eax
f010393b:	75 c4                	jne    f0103901 <trap_init+0x5>
}


void
trap_init(void)
{
f010393d:	55                   	push   %ebp
f010393e:	89 e5                	mov    %esp,%ebp
f0103940:	83 ec 08             	sub    $0x8,%esp
	for (i=0; i<= T_SIMDERR;i++){
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f0103943:	a1 fc 03 12 f0       	mov    0xf01203fc,%eax
f0103948:	66 a3 98 b2 22 f0    	mov    %ax,0xf022b298
f010394e:	66 c7 05 9a b2 22 f0 	movw   $0x8,0xf022b29a
f0103955:	08 00 
f0103957:	c6 05 9c b2 22 f0 00 	movb   $0x0,0xf022b29c
f010395e:	c6 05 9d b2 22 f0 ee 	movb   $0xee,0xf022b29d
f0103965:	c1 e8 10             	shr    $0x10,%eax
f0103968:	66 a3 9e b2 22 f0    	mov    %ax,0xf022b29e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f010396e:	a1 b0 04 12 f0       	mov    0xf01204b0,%eax
f0103973:	66 a3 00 b4 22 f0    	mov    %ax,0xf022b400
f0103979:	66 c7 05 02 b4 22 f0 	movw   $0x8,0xf022b402
f0103980:	08 00 
f0103982:	c6 05 04 b4 22 f0 00 	movb   $0x0,0xf022b404
f0103989:	c6 05 05 b4 22 f0 ee 	movb   $0xee,0xf022b405
f0103990:	c1 e8 10             	shr    $0x10,%eax
f0103993:	66 a3 06 b4 22 f0    	mov    %ax,0xf022b406

	// Per-CPU setup 
	trap_init_percpu();
f0103999:	e8 c9 fe ff ff       	call   f0103867 <trap_init_percpu>
}
f010399e:	c9                   	leave  
f010399f:	c3                   	ret    

f01039a0 <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f01039a0:	55                   	push   %ebp
f01039a1:	89 e5                	mov    %esp,%ebp
f01039a3:	53                   	push   %ebx
f01039a4:	83 ec 0c             	sub    $0xc,%esp
f01039a7:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039aa:	ff 33                	pushl  (%ebx)
f01039ac:	68 73 71 10 f0       	push   $0xf0107173
f01039b1:	e8 9d fe ff ff       	call   f0103853 <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039b6:	83 c4 08             	add    $0x8,%esp
f01039b9:	ff 73 04             	pushl  0x4(%ebx)
f01039bc:	68 82 71 10 f0       	push   $0xf0107182
f01039c1:	e8 8d fe ff ff       	call   f0103853 <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01039c6:	83 c4 08             	add    $0x8,%esp
f01039c9:	ff 73 08             	pushl  0x8(%ebx)
f01039cc:	68 91 71 10 f0       	push   $0xf0107191
f01039d1:	e8 7d fe ff ff       	call   f0103853 <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01039d6:	83 c4 08             	add    $0x8,%esp
f01039d9:	ff 73 0c             	pushl  0xc(%ebx)
f01039dc:	68 a0 71 10 f0       	push   $0xf01071a0
f01039e1:	e8 6d fe ff ff       	call   f0103853 <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01039e6:	83 c4 08             	add    $0x8,%esp
f01039e9:	ff 73 10             	pushl  0x10(%ebx)
f01039ec:	68 af 71 10 f0       	push   $0xf01071af
f01039f1:	e8 5d fe ff ff       	call   f0103853 <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01039f6:	83 c4 08             	add    $0x8,%esp
f01039f9:	ff 73 14             	pushl  0x14(%ebx)
f01039fc:	68 be 71 10 f0       	push   $0xf01071be
f0103a01:	e8 4d fe ff ff       	call   f0103853 <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a06:	83 c4 08             	add    $0x8,%esp
f0103a09:	ff 73 18             	pushl  0x18(%ebx)
f0103a0c:	68 cd 71 10 f0       	push   $0xf01071cd
f0103a11:	e8 3d fe ff ff       	call   f0103853 <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a16:	83 c4 08             	add    $0x8,%esp
f0103a19:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a1c:	68 dc 71 10 f0       	push   $0xf01071dc
f0103a21:	e8 2d fe ff ff       	call   f0103853 <cprintf>
f0103a26:	83 c4 10             	add    $0x10,%esp
}
f0103a29:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a2c:	c9                   	leave  
f0103a2d:	c3                   	ret    

f0103a2e <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f0103a2e:	55                   	push   %ebp
f0103a2f:	89 e5                	mov    %esp,%ebp
f0103a31:	56                   	push   %esi
f0103a32:	53                   	push   %ebx
f0103a33:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a36:	e8 8c 1c 00 00       	call   f01056c7 <cpunum>
f0103a3b:	83 ec 04             	sub    $0x4,%esp
f0103a3e:	50                   	push   %eax
f0103a3f:	53                   	push   %ebx
f0103a40:	68 40 72 10 f0       	push   $0xf0107240
f0103a45:	e8 09 fe ff ff       	call   f0103853 <cprintf>
	print_regs(&tf->tf_regs);
f0103a4a:	89 1c 24             	mov    %ebx,(%esp)
f0103a4d:	e8 4e ff ff ff       	call   f01039a0 <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a52:	83 c4 08             	add    $0x8,%esp
f0103a55:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a59:	50                   	push   %eax
f0103a5a:	68 5e 72 10 f0       	push   $0xf010725e
f0103a5f:	e8 ef fd ff ff       	call   f0103853 <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103a64:	83 c4 08             	add    $0x8,%esp
f0103a67:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103a6b:	50                   	push   %eax
f0103a6c:	68 71 72 10 f0       	push   $0xf0107271
f0103a71:	e8 dd fd ff ff       	call   f0103853 <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103a76:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103a79:	83 c4 10             	add    $0x10,%esp
f0103a7c:	83 f8 13             	cmp    $0x13,%eax
f0103a7f:	77 09                	ja     f0103a8a <print_trapframe+0x5c>
		return excnames[trapno];
f0103a81:	8b 14 85 40 75 10 f0 	mov    -0xfef8ac0(,%eax,4),%edx
f0103a88:	eb 1f                	jmp    f0103aa9 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103a8a:	83 f8 30             	cmp    $0x30,%eax
f0103a8d:	74 15                	je     f0103aa4 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103a8f:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103a92:	83 fa 10             	cmp    $0x10,%edx
f0103a95:	b9 0a 72 10 f0       	mov    $0xf010720a,%ecx
f0103a9a:	ba f7 71 10 f0       	mov    $0xf01071f7,%edx
f0103a9f:	0f 43 d1             	cmovae %ecx,%edx
f0103aa2:	eb 05                	jmp    f0103aa9 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103aa4:	ba eb 71 10 f0       	mov    $0xf01071eb,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103aa9:	83 ec 04             	sub    $0x4,%esp
f0103aac:	52                   	push   %edx
f0103aad:	50                   	push   %eax
f0103aae:	68 84 72 10 f0       	push   $0xf0107284
f0103ab3:	e8 9b fd ff ff       	call   f0103853 <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103ab8:	83 c4 10             	add    $0x10,%esp
f0103abb:	3b 1d 80 ba 22 f0    	cmp    0xf022ba80,%ebx
f0103ac1:	75 1a                	jne    f0103add <print_trapframe+0xaf>
f0103ac3:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ac7:	75 14                	jne    f0103add <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103ac9:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103acc:	83 ec 08             	sub    $0x8,%esp
f0103acf:	50                   	push   %eax
f0103ad0:	68 96 72 10 f0       	push   $0xf0107296
f0103ad5:	e8 79 fd ff ff       	call   f0103853 <cprintf>
f0103ada:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103add:	83 ec 08             	sub    $0x8,%esp
f0103ae0:	ff 73 2c             	pushl  0x2c(%ebx)
f0103ae3:	68 a5 72 10 f0       	push   $0xf01072a5
f0103ae8:	e8 66 fd ff ff       	call   f0103853 <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103aed:	83 c4 10             	add    $0x10,%esp
f0103af0:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103af4:	75 49                	jne    f0103b3f <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103af6:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103af9:	89 c2                	mov    %eax,%edx
f0103afb:	83 e2 01             	and    $0x1,%edx
f0103afe:	ba 24 72 10 f0       	mov    $0xf0107224,%edx
f0103b03:	b9 19 72 10 f0       	mov    $0xf0107219,%ecx
f0103b08:	0f 44 ca             	cmove  %edx,%ecx
f0103b0b:	89 c2                	mov    %eax,%edx
f0103b0d:	83 e2 02             	and    $0x2,%edx
f0103b10:	ba 36 72 10 f0       	mov    $0xf0107236,%edx
f0103b15:	be 30 72 10 f0       	mov    $0xf0107230,%esi
f0103b1a:	0f 45 d6             	cmovne %esi,%edx
f0103b1d:	83 e0 04             	and    $0x4,%eax
f0103b20:	be 8c 73 10 f0       	mov    $0xf010738c,%esi
f0103b25:	b8 3b 72 10 f0       	mov    $0xf010723b,%eax
f0103b2a:	0f 44 c6             	cmove  %esi,%eax
f0103b2d:	51                   	push   %ecx
f0103b2e:	52                   	push   %edx
f0103b2f:	50                   	push   %eax
f0103b30:	68 b3 72 10 f0       	push   $0xf01072b3
f0103b35:	e8 19 fd ff ff       	call   f0103853 <cprintf>
f0103b3a:	83 c4 10             	add    $0x10,%esp
f0103b3d:	eb 10                	jmp    f0103b4f <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b3f:	83 ec 0c             	sub    $0xc,%esp
f0103b42:	68 12 76 10 f0       	push   $0xf0107612
f0103b47:	e8 07 fd ff ff       	call   f0103853 <cprintf>
f0103b4c:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b4f:	83 ec 08             	sub    $0x8,%esp
f0103b52:	ff 73 30             	pushl  0x30(%ebx)
f0103b55:	68 c2 72 10 f0       	push   $0xf01072c2
f0103b5a:	e8 f4 fc ff ff       	call   f0103853 <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b5f:	83 c4 08             	add    $0x8,%esp
f0103b62:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103b66:	50                   	push   %eax
f0103b67:	68 d1 72 10 f0       	push   $0xf01072d1
f0103b6c:	e8 e2 fc ff ff       	call   f0103853 <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103b71:	83 c4 08             	add    $0x8,%esp
f0103b74:	ff 73 38             	pushl  0x38(%ebx)
f0103b77:	68 e4 72 10 f0       	push   $0xf01072e4
f0103b7c:	e8 d2 fc ff ff       	call   f0103853 <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103b81:	83 c4 10             	add    $0x10,%esp
f0103b84:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103b88:	74 25                	je     f0103baf <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103b8a:	83 ec 08             	sub    $0x8,%esp
f0103b8d:	ff 73 3c             	pushl  0x3c(%ebx)
f0103b90:	68 f3 72 10 f0       	push   $0xf01072f3
f0103b95:	e8 b9 fc ff ff       	call   f0103853 <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103b9a:	83 c4 08             	add    $0x8,%esp
f0103b9d:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103ba1:	50                   	push   %eax
f0103ba2:	68 02 73 10 f0       	push   $0xf0107302
f0103ba7:	e8 a7 fc ff ff       	call   f0103853 <cprintf>
f0103bac:	83 c4 10             	add    $0x10,%esp
	}
}
f0103baf:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103bb2:	5b                   	pop    %ebx
f0103bb3:	5e                   	pop    %esi
f0103bb4:	5d                   	pop    %ebp
f0103bb5:	c3                   	ret    

f0103bb6 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bb6:	55                   	push   %ebp
f0103bb7:	89 e5                	mov    %esp,%ebp
f0103bb9:	57                   	push   %edi
f0103bba:	56                   	push   %esi
f0103bbb:	53                   	push   %ebx
f0103bbc:	83 ec 1c             	sub    $0x1c,%esp
f0103bbf:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103bc2:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103bc5:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103bc9:	75 15                	jne    f0103be0 <page_fault_handler+0x2a>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103bcb:	56                   	push   %esi
f0103bcc:	68 d8 74 10 f0       	push   $0xf01074d8
f0103bd1:	68 4c 01 00 00       	push   $0x14c
f0103bd6:	68 15 73 10 f0       	push   $0xf0107315
f0103bdb:	e8 60 c4 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	//Store the current env's stack tf_esp for use, if the call occurs inside UXtrapframe  
	const uint32_t cur_tf_esp_addr = (uint32_t)(tf->tf_esp); 	// trap-time esp
f0103be0:	8b 7b 3c             	mov    0x3c(%ebx),%edi

	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
f0103be3:	e8 df 1a 00 00       	call   f01056c7 <cpunum>
f0103be8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103beb:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0103bf1:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103bf5:	75 46                	jne    f0103c3d <page_fault_handler+0x87>
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103bf7:	8b 43 30             	mov    0x30(%ebx),%eax
f0103bfa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			curenv->env_id, fault_va, tf->tf_eip);
f0103bfd:	e8 c5 1a 00 00       	call   f01056c7 <cpunum>
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c02:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c05:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103c06:	6b c0 74             	imul   $0x74,%eax,%eax
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c09:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0103c0f:	ff 70 48             	pushl  0x48(%eax)
f0103c12:	68 00 75 10 f0       	push   $0xf0107500
f0103c17:	e8 37 fc ff ff       	call   f0103853 <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103c1c:	89 1c 24             	mov    %ebx,(%esp)
f0103c1f:	e8 0a fe ff ff       	call   f0103a2e <print_trapframe>
		env_destroy(curenv);	// Destroy the environment that caused the fault.
f0103c24:	e8 9e 1a 00 00       	call   f01056c7 <cpunum>
f0103c29:	83 c4 04             	add    $0x4,%esp
f0103c2c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c2f:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f0103c35:	e8 52 f9 ff ff       	call   f010358c <env_destroy>
f0103c3a:	83 c4 10             	add    $0x10,%esp
	}
	
	//Check if the	
	struct UTrapframe* usertf = NULL; //As defined in inc/trap.h
	
	if((cur_tf_esp_addr < UXSTACKTOP) && (cur_tf_esp_addr >=(UXSTACKTOP - PGSIZE)))
f0103c3d:	8d 97 00 10 40 11    	lea    0x11401000(%edi),%edx
	{
		//If its already inside the exception stack
		//Allocate the address by leaving space for 32-bit word
		usertf = (struct UTrapframe*)(cur_tf_esp_addr - 4 - sizeof(struct UTrapframe));
f0103c43:	8d 47 c8             	lea    -0x38(%edi),%eax
f0103c46:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103c4c:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103c51:	0f 46 d0             	cmovbe %eax,%edx
f0103c54:	89 d7                	mov    %edx,%edi
		usertf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
	}
	
	//Check whether the usertf memory is valid
	//This function will not return if there is a fault and it will also destroy the environment
	user_mem_assert(curenv, (void*)usertf, sizeof(struct UTrapframe), PTE_U | PTE_P | PTE_W);
f0103c56:	e8 6c 1a 00 00       	call   f01056c7 <cpunum>
f0103c5b:	6a 07                	push   $0x7
f0103c5d:	6a 34                	push   $0x34
f0103c5f:	57                   	push   %edi
f0103c60:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c63:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f0103c69:	e8 8f f2 ff ff       	call   f0102efd <user_mem_assert>
	
	
	// User exeception trapframe
	usertf->utf_fault_va = fault_va;
f0103c6e:	89 fa                	mov    %edi,%edx
f0103c70:	89 37                	mov    %esi,(%edi)
	usertf->utf_err = tf->tf_err;
f0103c72:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103c75:	89 47 04             	mov    %eax,0x4(%edi)
	usertf->utf_regs = tf->tf_regs;
f0103c78:	8d 7f 08             	lea    0x8(%edi),%edi
f0103c7b:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103c80:	89 de                	mov    %ebx,%esi
f0103c82:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	usertf->utf_eip = tf->tf_eip;
f0103c84:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c87:	89 42 28             	mov    %eax,0x28(%edx)
	usertf->utf_esp = tf->tf_esp;
f0103c8a:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c8d:	89 42 30             	mov    %eax,0x30(%edx)
	usertf->utf_eflags = tf->tf_eflags;
f0103c90:	8b 43 38             	mov    0x38(%ebx),%eax
f0103c93:	89 42 2c             	mov    %eax,0x2c(%edx)
	
	//Setup the tf with Exception stack frame
	
	tf->tf_esp= (uintptr_t)usertf;
f0103c96:	89 53 3c             	mov    %edx,0x3c(%ebx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall; 
f0103c99:	e8 29 1a 00 00       	call   f01056c7 <cpunum>
f0103c9e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ca1:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0103ca7:	8b 40 64             	mov    0x64(%eax),%eax
f0103caa:	89 43 30             	mov    %eax,0x30(%ebx)

	env_run(curenv);
f0103cad:	e8 15 1a 00 00       	call   f01056c7 <cpunum>
f0103cb2:	83 c4 04             	add    $0x4,%esp
f0103cb5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cb8:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f0103cbe:	e8 68 f9 ff ff       	call   f010362b <env_run>

f0103cc3 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103cc3:	55                   	push   %ebp
f0103cc4:	89 e5                	mov    %esp,%ebp
f0103cc6:	57                   	push   %edi
f0103cc7:	56                   	push   %esi
f0103cc8:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103ccb:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103ccc:	83 3d c0 be 22 f0 00 	cmpl   $0x0,0xf022bec0
f0103cd3:	74 01                	je     f0103cd6 <trap+0x13>
		asm volatile("hlt");
f0103cd5:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103cd6:	e8 ec 19 00 00       	call   f01056c7 <cpunum>
f0103cdb:	6b d0 74             	imul   $0x74,%eax,%edx
f0103cde:	81 c2 40 c0 22 f0    	add    $0xf022c040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103ce4:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ce9:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103ced:	83 f8 02             	cmp    $0x2,%eax
f0103cf0:	75 10                	jne    f0103d02 <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103cf2:	83 ec 0c             	sub    $0xc,%esp
f0103cf5:	68 c0 04 12 f0       	push   $0xf01204c0
f0103cfa:	e8 33 1c 00 00       	call   f0105932 <spin_lock>
f0103cff:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103d02:	9c                   	pushf  
f0103d03:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d04:	f6 c4 02             	test   $0x2,%ah
f0103d07:	74 19                	je     f0103d22 <trap+0x5f>
f0103d09:	68 21 73 10 f0       	push   $0xf0107321
f0103d0e:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0103d13:	68 12 01 00 00       	push   $0x112
f0103d18:	68 15 73 10 f0       	push   $0xf0107315
f0103d1d:	e8 1e c3 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d22:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d26:	83 e0 03             	and    $0x3,%eax
f0103d29:	66 83 f8 03          	cmp    $0x3,%ax
f0103d2d:	0f 85 a0 00 00 00    	jne    f0103dd3 <trap+0x110>
f0103d33:	83 ec 0c             	sub    $0xc,%esp
f0103d36:	68 c0 04 12 f0       	push   $0xf01204c0
f0103d3b:	e8 f2 1b 00 00       	call   f0105932 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f0103d40:	e8 82 19 00 00       	call   f01056c7 <cpunum>
f0103d45:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d48:	83 c4 10             	add    $0x10,%esp
f0103d4b:	83 b8 48 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fb8(%eax)
f0103d52:	75 19                	jne    f0103d6d <trap+0xaa>
f0103d54:	68 3a 73 10 f0       	push   $0xf010733a
f0103d59:	68 5b 6d 10 f0       	push   $0xf0106d5b
f0103d5e:	68 1a 01 00 00       	push   $0x11a
f0103d63:	68 15 73 10 f0       	push   $0xf0107315
f0103d68:	e8 d3 c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103d6d:	e8 55 19 00 00       	call   f01056c7 <cpunum>
f0103d72:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d75:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0103d7b:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103d7f:	75 2d                	jne    f0103dae <trap+0xeb>
			env_free(curenv);
f0103d81:	e8 41 19 00 00       	call   f01056c7 <cpunum>
f0103d86:	83 ec 0c             	sub    $0xc,%esp
f0103d89:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d8c:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f0103d92:	e8 1a f6 ff ff       	call   f01033b1 <env_free>
			curenv = NULL;
f0103d97:	e8 2b 19 00 00       	call   f01056c7 <cpunum>
f0103d9c:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d9f:	c7 80 48 c0 22 f0 00 	movl   $0x0,-0xfdd3fb8(%eax)
f0103da6:	00 00 00 
			sched_yield();
f0103da9:	e8 cc 02 00 00       	call   f010407a <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103dae:	e8 14 19 00 00       	call   f01056c7 <cpunum>
f0103db3:	6b c0 74             	imul   $0x74,%eax,%eax
f0103db6:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0103dbc:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103dc1:	89 c7                	mov    %eax,%edi
f0103dc3:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103dc5:	e8 fd 18 00 00       	call   f01056c7 <cpunum>
f0103dca:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dcd:	8b b0 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103dd3:	89 35 80 ba 22 f0    	mov    %esi,0xf022ba80
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103dd9:	8b 46 28             	mov    0x28(%esi),%eax
f0103ddc:	83 f8 0e             	cmp    $0xe,%eax
f0103ddf:	74 24                	je     f0103e05 <trap+0x142>
f0103de1:	83 f8 30             	cmp    $0x30,%eax
f0103de4:	74 28                	je     f0103e0e <trap+0x14b>
f0103de6:	83 f8 03             	cmp    $0x3,%eax
f0103de9:	75 44                	jne    f0103e2f <trap+0x16c>
		case T_BRKPT:
			monitor(tf);
f0103deb:	83 ec 0c             	sub    $0xc,%esp
f0103dee:	56                   	push   %esi
f0103def:	e8 ea ca ff ff       	call   f01008de <monitor>
			cprintf("return from breakpoint....\n");
f0103df4:	c7 04 24 41 73 10 f0 	movl   $0xf0107341,(%esp)
f0103dfb:	e8 53 fa ff ff       	call   f0103853 <cprintf>
f0103e00:	83 c4 10             	add    $0x10,%esp
f0103e03:	eb 2a                	jmp    f0103e2f <trap+0x16c>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103e05:	83 ec 0c             	sub    $0xc,%esp
f0103e08:	56                   	push   %esi
f0103e09:	e8 a8 fd ff ff       	call   f0103bb6 <page_fault_handler>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e0e:	83 ec 08             	sub    $0x8,%esp
f0103e11:	ff 76 04             	pushl  0x4(%esi)
f0103e14:	ff 36                	pushl  (%esi)
f0103e16:	ff 76 10             	pushl  0x10(%esi)
f0103e19:	ff 76 18             	pushl  0x18(%esi)
f0103e1c:	ff 76 14             	pushl  0x14(%esi)
f0103e1f:	ff 76 1c             	pushl  0x1c(%esi)
f0103e22:	e8 33 03 00 00       	call   f010415a <syscall>
f0103e27:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e2a:	83 c4 20             	add    $0x20,%esp
f0103e2d:	eb 63                	jmp    f0103e92 <trap+0x1cf>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e2f:	83 7e 28 27          	cmpl   $0x27,0x28(%esi)
f0103e33:	75 1a                	jne    f0103e4f <trap+0x18c>
		cprintf("Spurious interrupt on irq 7\n");
f0103e35:	83 ec 0c             	sub    $0xc,%esp
f0103e38:	68 5d 73 10 f0       	push   $0xf010735d
f0103e3d:	e8 11 fa ff ff       	call   f0103853 <cprintf>
		print_trapframe(tf);
f0103e42:	89 34 24             	mov    %esi,(%esp)
f0103e45:	e8 e4 fb ff ff       	call   f0103a2e <print_trapframe>
f0103e4a:	83 c4 10             	add    $0x10,%esp
f0103e4d:	eb 43                	jmp    f0103e92 <trap+0x1cf>
	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e4f:	83 ec 0c             	sub    $0xc,%esp
f0103e52:	56                   	push   %esi
f0103e53:	e8 d6 fb ff ff       	call   f0103a2e <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0103e58:	83 c4 10             	add    $0x10,%esp
f0103e5b:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e60:	75 17                	jne    f0103e79 <trap+0x1b6>
		panic("unhandled trap in kernel");
f0103e62:	83 ec 04             	sub    $0x4,%esp
f0103e65:	68 7a 73 10 f0       	push   $0xf010737a
f0103e6a:	68 f7 00 00 00       	push   $0xf7
f0103e6f:	68 15 73 10 f0       	push   $0xf0107315
f0103e74:	e8 c7 c1 ff ff       	call   f0100040 <_panic>
	}
	else {
		env_destroy(curenv);
f0103e79:	e8 49 18 00 00       	call   f01056c7 <cpunum>
f0103e7e:	83 ec 0c             	sub    $0xc,%esp
f0103e81:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e84:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f0103e8a:	e8 fd f6 ff ff       	call   f010358c <env_destroy>
f0103e8f:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103e92:	e8 30 18 00 00       	call   f01056c7 <cpunum>
f0103e97:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e9a:	83 b8 48 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fb8(%eax)
f0103ea1:	74 2a                	je     f0103ecd <trap+0x20a>
f0103ea3:	e8 1f 18 00 00       	call   f01056c7 <cpunum>
f0103ea8:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eab:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0103eb1:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103eb5:	75 16                	jne    f0103ecd <trap+0x20a>
		env_run(curenv);
f0103eb7:	e8 0b 18 00 00       	call   f01056c7 <cpunum>
f0103ebc:	83 ec 0c             	sub    $0xc,%esp
f0103ebf:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ec2:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f0103ec8:	e8 5e f7 ff ff       	call   f010362b <env_run>
	else
		sched_yield();
f0103ecd:	e8 a8 01 00 00       	call   f010407a <sched_yield>

f0103ed2 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103ed2:	6a 00                	push   $0x0
f0103ed4:	6a 00                	push   $0x0
f0103ed6:	e9 ba 00 00 00       	jmp    f0103f95 <_alltraps>
f0103edb:	90                   	nop

f0103edc <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103edc:	6a 00                	push   $0x0
f0103ede:	6a 01                	push   $0x1
f0103ee0:	e9 b0 00 00 00       	jmp    f0103f95 <_alltraps>
f0103ee5:	90                   	nop

f0103ee6 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103ee6:	6a 00                	push   $0x0
f0103ee8:	6a 02                	push   $0x2
f0103eea:	e9 a6 00 00 00       	jmp    f0103f95 <_alltraps>
f0103eef:	90                   	nop

f0103ef0 <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103ef0:	6a 00                	push   $0x0
f0103ef2:	6a 03                	push   $0x3
f0103ef4:	e9 9c 00 00 00       	jmp    f0103f95 <_alltraps>
f0103ef9:	90                   	nop

f0103efa <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103efa:	6a 00                	push   $0x0
f0103efc:	6a 04                	push   $0x4
f0103efe:	e9 92 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f03:	90                   	nop

f0103f04 <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103f04:	6a 00                	push   $0x0
f0103f06:	6a 05                	push   $0x5
f0103f08:	e9 88 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f0d:	90                   	nop

f0103f0e <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103f0e:	6a 00                	push   $0x0
f0103f10:	6a 06                	push   $0x6
f0103f12:	e9 7e 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f17:	90                   	nop

f0103f18 <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103f18:	6a 00                	push   $0x0
f0103f1a:	6a 07                	push   $0x7
f0103f1c:	e9 74 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f21:	90                   	nop

f0103f22 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103f22:	6a 08                	push   $0x8
f0103f24:	e9 6c 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f29:	90                   	nop

f0103f2a <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103f2a:	6a 00                	push   $0x0
f0103f2c:	6a 09                	push   $0x9
f0103f2e:	e9 62 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f33:	90                   	nop

f0103f34 <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103f34:	6a 0a                	push   $0xa
f0103f36:	e9 5a 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f3b:	90                   	nop

f0103f3c <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103f3c:	6a 0b                	push   $0xb
f0103f3e:	e9 52 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f43:	90                   	nop

f0103f44 <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103f44:	6a 0c                	push   $0xc
f0103f46:	e9 4a 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f4b:	90                   	nop

f0103f4c <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103f4c:	6a 0d                	push   $0xd
f0103f4e:	e9 42 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f53:	90                   	nop

f0103f54 <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103f54:	6a 0e                	push   $0xe
f0103f56:	e9 3a 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f5b:	90                   	nop

f0103f5c <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103f5c:	6a 00                	push   $0x0
f0103f5e:	6a 0f                	push   $0xf
f0103f60:	e9 30 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f65:	90                   	nop

f0103f66 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103f66:	6a 00                	push   $0x0
f0103f68:	6a 10                	push   $0x10
f0103f6a:	e9 26 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f6f:	90                   	nop

f0103f70 <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103f70:	6a 11                	push   $0x11
f0103f72:	e9 1e 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f77:	90                   	nop

f0103f78 <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103f78:	6a 00                	push   $0x0
f0103f7a:	6a 12                	push   $0x12
f0103f7c:	e9 14 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f81:	90                   	nop

f0103f82 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103f82:	6a 00                	push   $0x0
f0103f84:	6a 13                	push   $0x13
f0103f86:	e9 0a 00 00 00       	jmp    f0103f95 <_alltraps>
f0103f8b:	90                   	nop

f0103f8c <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f0103f8c:	6a 00                	push   $0x0
f0103f8e:	6a 30                	push   $0x30
f0103f90:	e9 00 00 00 00       	jmp    f0103f95 <_alltraps>

f0103f95 <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f0103f95:	1e                   	push   %ds
	push %es
f0103f96:	06                   	push   %es
	pushal
f0103f97:	60                   	pusha  

	
	movw $GD_KD, %ax
f0103f98:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f0103f9c:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f0103f9e:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f0103fa0:	54                   	push   %esp
	call trap
f0103fa1:	e8 1d fd ff ff       	call   f0103cc3 <trap>

f0103fa6 <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f0103fa6:	55                   	push   %ebp
f0103fa7:	89 e5                	mov    %esp,%ebp
f0103fa9:	83 ec 08             	sub    $0x8,%esp
f0103fac:	a1 6c b2 22 f0       	mov    0xf022b26c,%eax
f0103fb1:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103fb4:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f0103fb9:	8b 02                	mov    (%edx),%eax
f0103fbb:	83 e8 01             	sub    $0x1,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f0103fbe:	83 f8 02             	cmp    $0x2,%eax
f0103fc1:	76 10                	jbe    f0103fd3 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f0103fc3:	83 c1 01             	add    $0x1,%ecx
f0103fc6:	83 c2 7c             	add    $0x7c,%edx
f0103fc9:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fcf:	75 e8                	jne    f0103fb9 <sched_halt+0x13>
f0103fd1:	eb 08                	jmp    f0103fdb <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f0103fd3:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f0103fd9:	75 1f                	jne    f0103ffa <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0103fdb:	83 ec 0c             	sub    $0xc,%esp
f0103fde:	68 90 75 10 f0       	push   $0xf0107590
f0103fe3:	e8 6b f8 ff ff       	call   f0103853 <cprintf>
f0103fe8:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0103feb:	83 ec 0c             	sub    $0xc,%esp
f0103fee:	6a 00                	push   $0x0
f0103ff0:	e8 e9 c8 ff ff       	call   f01008de <monitor>
f0103ff5:	83 c4 10             	add    $0x10,%esp
f0103ff8:	eb f1                	jmp    f0103feb <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0103ffa:	e8 c8 16 00 00       	call   f01056c7 <cpunum>
f0103fff:	6b c0 74             	imul   $0x74,%eax,%eax
f0104002:	c7 80 48 c0 22 f0 00 	movl   $0x0,-0xfdd3fb8(%eax)
f0104009:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f010400c:	a1 cc be 22 f0       	mov    0xf022becc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104011:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0104016:	77 12                	ja     f010402a <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0104018:	50                   	push   %eax
f0104019:	68 c8 5d 10 f0       	push   $0xf0105dc8
f010401e:	6a 54                	push   $0x54
f0104020:	68 b9 75 10 f0       	push   $0xf01075b9
f0104025:	e8 16 c0 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010402a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010402f:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104032:	e8 90 16 00 00       	call   f01056c7 <cpunum>
f0104037:	6b d0 74             	imul   $0x74,%eax,%edx
f010403a:	81 c2 40 c0 22 f0    	add    $0xf022c040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104040:	b8 02 00 00 00       	mov    $0x2,%eax
f0104045:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0104049:	83 ec 0c             	sub    $0xc,%esp
f010404c:	68 c0 04 12 f0       	push   $0xf01204c0
f0104051:	e8 79 19 00 00       	call   f01059cf <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f0104056:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f0104058:	e8 6a 16 00 00       	call   f01056c7 <cpunum>
f010405d:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104060:	8b 80 50 c0 22 f0    	mov    -0xfdd3fb0(%eax),%eax
f0104066:	bd 00 00 00 00       	mov    $0x0,%ebp
f010406b:	89 c4                	mov    %eax,%esp
f010406d:	6a 00                	push   $0x0
f010406f:	6a 00                	push   $0x0
f0104071:	fb                   	sti    
f0104072:	f4                   	hlt    
f0104073:	eb fd                	jmp    f0104072 <sched_halt+0xcc>
f0104075:	83 c4 10             	add    $0x10,%esp
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f0104078:	c9                   	leave  
f0104079:	c3                   	ret    

f010407a <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f010407a:	55                   	push   %ebp
f010407b:	89 e5                	mov    %esp,%ebp
f010407d:	53                   	push   %ebx
f010407e:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f0104081:	e8 41 16 00 00       	call   f01056c7 <cpunum>
f0104086:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f0104089:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f010408e:	83 b8 48 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fb8(%eax)
f0104095:	74 33                	je     f01040ca <sched_yield+0x50>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f0104097:	e8 2b 16 00 00       	call   f01056c7 <cpunum>
f010409c:	6b c0 74             	imul   $0x74,%eax,%eax
f010409f:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f01040a5:	2b 05 6c b2 22 f0    	sub    0xf022b26c,%eax
f01040ab:	c1 f8 02             	sar    $0x2,%eax
f01040ae:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f01040b4:	83 c0 01             	add    $0x1,%eax
f01040b7:	89 c1                	mov    %eax,%ecx
f01040b9:	c1 f9 1f             	sar    $0x1f,%ecx
f01040bc:	c1 e9 16             	shr    $0x16,%ecx
f01040bf:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f01040c2:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01040c8:	29 ca                	sub    %ecx,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f01040ca:	a1 6c b2 22 f0       	mov    0xf022b26c,%eax
f01040cf:	b9 00 04 00 00       	mov    $0x400,%ecx
f01040d4:	6b da 7c             	imul   $0x7c,%edx,%ebx
f01040d7:	83 7c 18 54 02       	cmpl   $0x2,0x54(%eax,%ebx,1)
f01040dc:	74 70                	je     f010414e <sched_yield+0xd4>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f01040de:	83 c2 01             	add    $0x1,%edx
f01040e1:	89 d3                	mov    %edx,%ebx
f01040e3:	c1 fb 1f             	sar    $0x1f,%ebx
f01040e6:	c1 eb 16             	shr    $0x16,%ebx
f01040e9:	01 da                	add    %ebx,%edx
f01040eb:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01040f1:	29 da                	sub    %ebx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f01040f3:	83 e9 01             	sub    $0x1,%ecx
f01040f6:	75 dc                	jne    f01040d4 <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f01040f8:	6b d2 7c             	imul   $0x7c,%edx,%edx
f01040fb:	01 c2                	add    %eax,%edx
f01040fd:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104101:	75 09                	jne    f010410c <sched_yield+0x92>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f0104103:	83 ec 0c             	sub    $0xc,%esp
f0104106:	52                   	push   %edx
f0104107:	e8 1f f5 ff ff       	call   f010362b <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f010410c:	e8 b6 15 00 00       	call   f01056c7 <cpunum>
f0104111:	6b c0 74             	imul   $0x74,%eax,%eax
f0104114:	83 b8 48 c0 22 f0 00 	cmpl   $0x0,-0xfdd3fb8(%eax)
f010411b:	74 2a                	je     f0104147 <sched_yield+0xcd>
f010411d:	e8 a5 15 00 00       	call   f01056c7 <cpunum>
f0104122:	6b c0 74             	imul   $0x74,%eax,%eax
f0104125:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f010412b:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f010412f:	75 16                	jne    f0104147 <sched_yield+0xcd>
	    env_run(curenv) ;
f0104131:	e8 91 15 00 00       	call   f01056c7 <cpunum>
f0104136:	83 ec 0c             	sub    $0xc,%esp
f0104139:	6b c0 74             	imul   $0x74,%eax,%eax
f010413c:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f0104142:	e8 e4 f4 ff ff       	call   f010362b <env_run>
	}
	// sched_halt never returns
	sched_halt();
f0104147:	e8 5a fe ff ff       	call   f0103fa6 <sched_halt>
f010414c:	eb 07                	jmp    f0104155 <sched_yield+0xdb>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f010414e:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104151:	01 c2                	add    %eax,%edx
f0104153:	eb ae                	jmp    f0104103 <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f0104155:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104158:	c9                   	leave  
f0104159:	c3                   	ret    

f010415a <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f010415a:	55                   	push   %ebp
f010415b:	89 e5                	mov    %esp,%ebp
f010415d:	57                   	push   %edi
f010415e:	56                   	push   %esi
f010415f:	53                   	push   %ebx
f0104160:	83 ec 1c             	sub    $0x1c,%esp
f0104163:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f0104166:	83 f8 0a             	cmp    $0xa,%eax
f0104169:	0f 87 94 03 00 00    	ja     f0104503 <syscall+0x3a9>
f010416f:	ff 24 85 24 76 10 f0 	jmp    *-0xfef89dc(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f0104176:	e8 4c 15 00 00       	call   f01056c7 <cpunum>
f010417b:	6a 05                	push   $0x5
f010417d:	ff 75 10             	pushl  0x10(%ebp)
f0104180:	ff 75 0c             	pushl  0xc(%ebp)
f0104183:	6b c0 74             	imul   $0x74,%eax,%eax
f0104186:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f010418c:	e8 6c ed ff ff       	call   f0102efd <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f0104191:	83 c4 0c             	add    $0xc,%esp
f0104194:	ff 75 0c             	pushl  0xc(%ebp)
f0104197:	ff 75 10             	pushl  0x10(%ebp)
f010419a:	68 c6 75 10 f0       	push   $0xf01075c6
f010419f:	e8 af f6 ff ff       	call   f0103853 <cprintf>
f01041a4:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f01041a7:	b8 00 00 00 00       	mov    $0x0,%eax
f01041ac:	e9 69 03 00 00       	jmp    f010451a <syscall+0x3c0>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01041b1:	e8 2f c4 ff ff       	call   f01005e5 <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f01041b6:	e9 5f 03 00 00       	jmp    f010451a <syscall+0x3c0>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01041bb:	e8 07 15 00 00       	call   f01056c7 <cpunum>
f01041c0:	6b c0 74             	imul   $0x74,%eax,%eax
f01041c3:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f01041c9:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f01041cc:	e9 49 03 00 00       	jmp    f010451a <syscall+0x3c0>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01041d1:	83 ec 04             	sub    $0x4,%esp
f01041d4:	6a 01                	push   $0x1
f01041d6:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01041d9:	50                   	push   %eax
f01041da:	ff 75 0c             	pushl  0xc(%ebp)
f01041dd:	e8 eb ed ff ff       	call   f0102fcd <envid2env>
f01041e2:	89 c2                	mov    %eax,%edx
f01041e4:	83 c4 10             	add    $0x10,%esp
f01041e7:	85 d2                	test   %edx,%edx
f01041e9:	0f 88 2b 03 00 00    	js     f010451a <syscall+0x3c0>
		return r;
	if (e == curenv)
f01041ef:	e8 d3 14 00 00       	call   f01056c7 <cpunum>
f01041f4:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01041f7:	6b c0 74             	imul   $0x74,%eax,%eax
f01041fa:	39 90 48 c0 22 f0    	cmp    %edx,-0xfdd3fb8(%eax)
f0104200:	75 23                	jne    f0104225 <syscall+0xcb>
		cprintf("[%08x] exiting gracefully\n", curenv->env_id);
f0104202:	e8 c0 14 00 00       	call   f01056c7 <cpunum>
f0104207:	83 ec 08             	sub    $0x8,%esp
f010420a:	6b c0 74             	imul   $0x74,%eax,%eax
f010420d:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0104213:	ff 70 48             	pushl  0x48(%eax)
f0104216:	68 cb 75 10 f0       	push   $0xf01075cb
f010421b:	e8 33 f6 ff ff       	call   f0103853 <cprintf>
f0104220:	83 c4 10             	add    $0x10,%esp
f0104223:	eb 25                	jmp    f010424a <syscall+0xf0>
	else
		cprintf("[%08x] destroying %08x\n", curenv->env_id, e->env_id);
f0104225:	8b 5a 48             	mov    0x48(%edx),%ebx
f0104228:	e8 9a 14 00 00       	call   f01056c7 <cpunum>
f010422d:	83 ec 04             	sub    $0x4,%esp
f0104230:	53                   	push   %ebx
f0104231:	6b c0 74             	imul   $0x74,%eax,%eax
f0104234:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f010423a:	ff 70 48             	pushl  0x48(%eax)
f010423d:	68 e6 75 10 f0       	push   $0xf01075e6
f0104242:	e8 0c f6 ff ff       	call   f0103853 <cprintf>
f0104247:	83 c4 10             	add    $0x10,%esp
	env_destroy(e);
f010424a:	83 ec 0c             	sub    $0xc,%esp
f010424d:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104250:	e8 37 f3 ff ff       	call   f010358c <env_destroy>
f0104255:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104258:	b8 00 00 00 00       	mov    $0x0,%eax
f010425d:	e9 b8 02 00 00       	jmp    f010451a <syscall+0x3c0>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f0104262:	e8 13 fe ff ff       	call   f010407a <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childenv;
	int errcode = env_alloc(&childenv, curenv->env_id);
f0104267:	e8 5b 14 00 00       	call   f01056c7 <cpunum>
f010426c:	83 ec 08             	sub    $0x8,%esp
f010426f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104272:	8b 80 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%eax
f0104278:	ff 70 48             	pushl  0x48(%eax)
f010427b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010427e:	50                   	push   %eax
f010427f:	e8 54 ee ff ff       	call   f01030d8 <env_alloc>
f0104284:	89 c2                	mov    %eax,%edx
	
	//If the error code is less than 0, that means there has been an error while creating an env	
	if (errcode < 0) {
f0104286:	83 c4 10             	add    $0x10,%esp
f0104289:	85 d2                	test   %edx,%edx
f010428b:	0f 88 89 02 00 00    	js     f010451a <syscall+0x3c0>
		return errcode; //Return the environment
	}
	
	//Set the child environment as not runnable	
	childenv->env_status = ENV_NOT_RUNNABLE;
f0104291:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104294:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)

	//Copy the current environemnt register data into the child
	childenv->env_tf = curenv->env_tf;
f010429b:	e8 27 14 00 00       	call   f01056c7 <cpunum>
f01042a0:	6b c0 74             	imul   $0x74,%eax,%eax
f01042a3:	8b b0 48 c0 22 f0    	mov    -0xfdd3fb8(%eax),%esi
f01042a9:	b9 11 00 00 00       	mov    $0x11,%ecx
f01042ae:	89 df                	mov    %ebx,%edi
f01042b0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

	// when the child is scheduled to run, it has to restart the trapframe. 
	//Hence we modify the register eax to be 0. 

	childenv->env_tf.tf_regs.reg_eax = 0; 
f01042b2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042b5:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return childenv->env_id;
f01042bc:	8b 40 48             	mov    0x48(%eax),%eax
f01042bf:	e9 56 02 00 00       	jmp    f010451a <syscall+0x3c0>

	// LAB 4: Your code here.
	
	struct Env *env_store;
	int errcode; 
	errcode = envid2env(envid, &env_store,1);
f01042c4:	83 ec 04             	sub    $0x4,%esp
f01042c7:	6a 01                	push   $0x1
f01042c9:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01042cc:	50                   	push   %eax
f01042cd:	ff 75 0c             	pushl  0xc(%ebp)
f01042d0:	e8 f8 ec ff ff       	call   f0102fcd <envid2env>
	if (errcode < 0)
f01042d5:	83 c4 10             	add    $0x10,%esp
f01042d8:	85 c0                	test   %eax,%eax
f01042da:	0f 88 3a 02 00 00    	js     f010451a <syscall+0x3c0>
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f01042e0:	8b 45 10             	mov    0x10(%ebp),%eax
f01042e3:	8d 50 fe             	lea    -0x2(%eax),%edx
		env_store->env_status = status;

	else
		return E_INVAL;
f01042e6:	b8 03 00 00 00       	mov    $0x3,%eax
	errcode = envid2env(envid, &env_store,1);
	if (errcode < 0)
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f01042eb:	f7 c2 fd ff ff ff    	test   $0xfffffffd,%edx
f01042f1:	0f 85 23 02 00 00    	jne    f010451a <syscall+0x3c0>
		env_store->env_status = status;
f01042f7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01042fa:	8b 7d 10             	mov    0x10(%ebp),%edi
f01042fd:	89 78 54             	mov    %edi,0x54(%eax)

	else
		return E_INVAL;

	return 0;
f0104300:	b8 00 00 00 00       	mov    $0x0,%eax
f0104305:	e9 10 02 00 00       	jmp    f010451a <syscall+0x3c0>
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
		return  E_INVAL;
f010430a:	b8 03 00 00 00       	mov    $0x3,%eax
	
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
f010430f:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104316:	0f 87 fe 01 00 00    	ja     f010451a <syscall+0x3c0>
f010431c:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f0104323:	0f 85 f1 01 00 00    	jne    f010451a <syscall+0x3c0>
		return  E_INVAL;

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104329:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f0104330:	0f 84 e4 01 00 00    	je     f010451a <syscall+0x3c0>
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
f0104336:	83 ec 0c             	sub    $0xc,%esp
f0104339:	6a 01                	push   $0x1
f010433b:	e8 62 cc ff ff       	call   f0100fa2 <page_alloc>
f0104340:	89 c3                	mov    %eax,%ebx
	if (!newpage)
f0104342:	83 c4 10             	add    $0x10,%esp
		return E_NO_MEM; 
f0104345:	b8 04 00 00 00       	mov    $0x4,%eax
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
	if (!newpage)
f010434a:	85 db                	test   %ebx,%ebx
f010434c:	0f 84 c8 01 00 00    	je     f010451a <syscall+0x3c0>
		return E_NO_MEM; 

	//Use environid to get the environment 
	if ((code = envid2env(envid, &en,1))<0)
f0104352:	83 ec 04             	sub    $0x4,%esp
f0104355:	6a 01                	push   $0x1
f0104357:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010435a:	50                   	push   %eax
f010435b:	ff 75 0c             	pushl  0xc(%ebp)
f010435e:	e8 6a ec ff ff       	call   f0102fcd <envid2env>
f0104363:	83 c4 10             	add    $0x10,%esp
f0104366:	85 c0                	test   %eax,%eax
f0104368:	0f 88 ac 01 00 00    	js     f010451a <syscall+0x3c0>
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
f010436e:	ff 75 14             	pushl  0x14(%ebp)
f0104371:	ff 75 10             	pushl  0x10(%ebp)
f0104374:	53                   	push   %ebx
f0104375:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104378:	ff 70 60             	pushl  0x60(%eax)
f010437b:	e8 48 cf ff ff       	call   f01012c8 <page_insert>
f0104380:	89 c6                	mov    %eax,%esi
	if (code < 0)
f0104382:	83 c4 10             	add    $0x10,%esp
	{
		page_free(newpage);
		return code;
	}
	
	return 0;
f0104385:	b8 00 00 00 00       	mov    $0x0,%eax
	if ((code = envid2env(envid, &en,1))<0)
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
	if (code < 0)
f010438a:	85 f6                	test   %esi,%esi
f010438c:	0f 89 88 01 00 00    	jns    f010451a <syscall+0x3c0>
	{
		page_free(newpage);
f0104392:	83 ec 0c             	sub    $0xc,%esp
f0104395:	53                   	push   %ebx
f0104396:	e8 7d cc ff ff       	call   f0101018 <page_free>
f010439b:	83 c4 10             	add    $0x10,%esp
		return code;
f010439e:	89 f0                	mov    %esi,%eax
f01043a0:	e9 75 01 00 00       	jmp    f010451a <syscall+0x3c0>
	struct Env* src_env;
	struct Env* dst_env;
	int errcode;
	
	//Check for valid src env id
	errcode = envid2env(srcenvid, &src_env, 1);
f01043a5:	83 ec 04             	sub    $0x4,%esp
f01043a8:	6a 01                	push   $0x1
f01043aa:	8d 45 dc             	lea    -0x24(%ebp),%eax
f01043ad:	50                   	push   %eax
f01043ae:	ff 75 0c             	pushl  0xc(%ebp)
f01043b1:	e8 17 ec ff ff       	call   f0102fcd <envid2env>
f01043b6:	89 c2                	mov    %eax,%edx
	if (errcode < 0) 
f01043b8:	83 c4 10             	add    $0x10,%esp
f01043bb:	85 d2                	test   %edx,%edx
f01043bd:	0f 88 57 01 00 00    	js     f010451a <syscall+0x3c0>
		return errcode;
	
	//Check for valid des env id
	errcode = envid2env(dstenvid, &dst_env, 1);
f01043c3:	83 ec 04             	sub    $0x4,%esp
f01043c6:	6a 01                	push   $0x1
f01043c8:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01043cb:	50                   	push   %eax
f01043cc:	ff 75 14             	pushl  0x14(%ebp)
f01043cf:	e8 f9 eb ff ff       	call   f0102fcd <envid2env>
	if (errcode < 0) 
f01043d4:	83 c4 10             	add    $0x10,%esp
f01043d7:	85 c0                	test   %eax,%eax
f01043d9:	0f 88 3b 01 00 00    	js     f010451a <syscall+0x3c0>
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
f01043df:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01043e6:	77 78                	ja     f0104460 <syscall+0x306>
f01043e8:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f01043ef:	77 6f                	ja     f0104460 <syscall+0x306>
f01043f1:	8b 45 10             	mov    0x10(%ebp),%eax
f01043f4:	0b 45 18             	or     0x18(%ebp),%eax
		return -E_INVAL;
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
f01043f7:	a9 ff 0f 00 00       	test   $0xfff,%eax
f01043fc:	75 6c                	jne    f010446a <syscall+0x310>
		return -E_INVAL;

	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
f01043fe:	83 ec 04             	sub    $0x4,%esp
f0104401:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104404:	50                   	push   %eax
f0104405:	ff 75 10             	pushl  0x10(%ebp)
f0104408:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010440b:	ff 70 60             	pushl  0x60(%eax)
f010440e:	e8 ef cd ff ff       	call   f0101202 <page_lookup>
f0104413:	89 c2                	mov    %eax,%edx
	if (!srcPage) 
f0104415:	83 c4 10             	add    $0x10,%esp
f0104418:	85 c0                	test   %eax,%eax
f010441a:	74 58                	je     f0104474 <syscall+0x31a>
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL; 	
f010441c:	b8 03 00 00 00       	mov    $0x3,%eax
	if (!srcPage) 
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104421:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f0104428:	0f 84 ec 00 00 00    	je     f010451a <syscall+0x3c0>
		return E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
f010442e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104431:	f6 00 02             	testb  $0x2,(%eax)
f0104434:	75 06                	jne    f010443c <syscall+0x2e2>
f0104436:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f010443a:	75 42                	jne    f010447e <syscall+0x324>
		return -E_INVAL;
	}

	// mapping
	errcode = page_insert(dst_env->env_pgdir, srcPage, dstva, perm);
f010443c:	ff 75 1c             	pushl  0x1c(%ebp)
f010443f:	ff 75 18             	pushl  0x18(%ebp)
f0104442:	52                   	push   %edx
f0104443:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104446:	ff 70 60             	pushl  0x60(%eax)
f0104449:	e8 7a ce ff ff       	call   f01012c8 <page_insert>
f010444e:	83 c4 10             	add    $0x10,%esp
f0104451:	85 c0                	test   %eax,%eax
f0104453:	ba 00 00 00 00       	mov    $0x0,%edx
f0104458:	0f 4f c2             	cmovg  %edx,%eax
f010445b:	e9 ba 00 00 00       	jmp    f010451a <syscall+0x3c0>
	if (errcode < 0) 
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
		return -E_INVAL;
f0104460:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104465:	e9 b0 00 00 00       	jmp    f010451a <syscall+0x3c0>
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
		return -E_INVAL;
f010446a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010446f:	e9 a6 00 00 00       	jmp    f010451a <syscall+0x3c0>
	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
	if (!srcPage) 
		return -E_INVAL;
f0104474:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104479:	e9 9c 00 00 00       	jmp    f010451a <syscall+0x3c0>
		return E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
		return -E_INVAL;
f010447e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f0104483:	e9 92 00 00 00       	jmp    f010451a <syscall+0x3c0>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env* en;
	//Check for valid envid
	int errcode = envid2env(envid, &en, 1);
f0104488:	83 ec 04             	sub    $0x4,%esp
f010448b:	6a 01                	push   $0x1
f010448d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104490:	50                   	push   %eax
f0104491:	ff 75 0c             	pushl  0xc(%ebp)
f0104494:	e8 34 eb ff ff       	call   f0102fcd <envid2env>
	if (errcode < 0){ 
f0104499:	83 c4 10             	add    $0x10,%esp
f010449c:	85 c0                	test   %eax,%eax
f010449e:	78 7a                	js     f010451a <syscall+0x3c0>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
f01044a0:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01044a7:	77 24                	ja     f01044cd <syscall+0x373>
f01044a9:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01044b0:	75 22                	jne    f01044d4 <syscall+0x37a>
		return -E_INVAL;
	}

	page_remove(en->env_pgdir, va);
f01044b2:	83 ec 08             	sub    $0x8,%esp
f01044b5:	ff 75 10             	pushl  0x10(%ebp)
f01044b8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044bb:	ff 70 60             	pushl  0x60(%eax)
f01044be:	e8 bf cd ff ff       	call   f0101282 <page_remove>
f01044c3:	83 c4 10             	add    $0x10,%esp

	return 0;
f01044c6:	b8 00 00 00 00       	mov    $0x0,%eax
f01044cb:	eb 4d                	jmp    f010451a <syscall+0x3c0>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
		return -E_INVAL;
f01044cd:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01044d2:	eb 46                	jmp    f010451a <syscall+0x3c0>
f01044d4:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f01044d9:	eb 3f                	jmp    f010451a <syscall+0x3c0>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here. //Exercise 8 code
	struct Env* en;
	int errcode = envid2env(envid, &en, 1);
f01044db:	83 ec 04             	sub    $0x4,%esp
f01044de:	6a 01                	push   $0x1
f01044e0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044e3:	50                   	push   %eax
f01044e4:	ff 75 0c             	pushl  0xc(%ebp)
f01044e7:	e8 e1 ea ff ff       	call   f0102fcd <envid2env>
	if (errcode < 0) {
f01044ec:	83 c4 10             	add    $0x10,%esp
f01044ef:	85 c0                	test   %eax,%eax
f01044f1:	78 27                	js     f010451a <syscall+0x3c0>
		return errcode;
	}

	//Set the pgfault_upcall to func
	en->env_pgfault_upcall = func;
f01044f3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01044f6:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01044f9:	89 48 64             	mov    %ecx,0x64(%eax)
	return 0;
f01044fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0104501:	eb 17                	jmp    f010451a <syscall+0x3c0>

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall((envid_t) a1, (void *)a2);
		
	default:
		panic("Invalid System Call \n");
f0104503:	83 ec 04             	sub    $0x4,%esp
f0104506:	68 fe 75 10 f0       	push   $0xf01075fe
f010450b:	68 c6 01 00 00       	push   $0x1c6
f0104510:	68 14 76 10 f0       	push   $0xf0107614
f0104515:	e8 26 bb ff ff       	call   f0100040 <_panic>
		return -E_INVAL;
	}
}
f010451a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010451d:	5b                   	pop    %ebx
f010451e:	5e                   	pop    %esi
f010451f:	5f                   	pop    %edi
f0104520:	5d                   	pop    %ebp
f0104521:	c3                   	ret    

f0104522 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0104522:	55                   	push   %ebp
f0104523:	89 e5                	mov    %esp,%ebp
f0104525:	57                   	push   %edi
f0104526:	56                   	push   %esi
f0104527:	53                   	push   %ebx
f0104528:	83 ec 14             	sub    $0x14,%esp
f010452b:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010452e:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0104531:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f0104534:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f0104537:	8b 1a                	mov    (%edx),%ebx
f0104539:	8b 01                	mov    (%ecx),%eax
f010453b:	89 45 f0             	mov    %eax,-0x10(%ebp)
f010453e:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f0104545:	e9 88 00 00 00       	jmp    f01045d2 <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f010454a:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010454d:	01 d8                	add    %ebx,%eax
f010454f:	89 c6                	mov    %eax,%esi
f0104551:	c1 ee 1f             	shr    $0x1f,%esi
f0104554:	01 c6                	add    %eax,%esi
f0104556:	d1 fe                	sar    %esi
f0104558:	8d 04 76             	lea    (%esi,%esi,2),%eax
f010455b:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f010455e:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f0104561:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104563:	eb 03                	jmp    f0104568 <stab_binsearch+0x46>
			m--;
f0104565:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0104568:	39 c3                	cmp    %eax,%ebx
f010456a:	7f 1f                	jg     f010458b <stab_binsearch+0x69>
f010456c:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104570:	83 ea 0c             	sub    $0xc,%edx
f0104573:	39 f9                	cmp    %edi,%ecx
f0104575:	75 ee                	jne    f0104565 <stab_binsearch+0x43>
f0104577:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f010457a:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010457d:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f0104580:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f0104584:	39 55 0c             	cmp    %edx,0xc(%ebp)
f0104587:	76 18                	jbe    f01045a1 <stab_binsearch+0x7f>
f0104589:	eb 05                	jmp    f0104590 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f010458b:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f010458e:	eb 42                	jmp    f01045d2 <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0104590:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f0104593:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f0104595:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104598:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f010459f:	eb 31                	jmp    f01045d2 <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01045a1:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01045a4:	73 17                	jae    f01045bd <stab_binsearch+0x9b>
			*region_right = m - 1;
f01045a6:	8b 45 e8             	mov    -0x18(%ebp),%eax
f01045a9:	83 e8 01             	sub    $0x1,%eax
f01045ac:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01045af:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01045b2:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01045b4:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f01045bb:	eb 15                	jmp    f01045d2 <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01045bd:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01045c0:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f01045c3:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f01045c5:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f01045c9:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01045cb:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01045d2:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f01045d5:	0f 8e 6f ff ff ff    	jle    f010454a <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01045db:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f01045df:	75 0f                	jne    f01045f0 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f01045e1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045e4:	8b 00                	mov    (%eax),%eax
f01045e6:	83 e8 01             	sub    $0x1,%eax
f01045e9:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01045ec:	89 06                	mov    %eax,(%esi)
f01045ee:	eb 2c                	jmp    f010461c <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01045f0:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01045f3:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f01045f5:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01045f8:	8b 0e                	mov    (%esi),%ecx
f01045fa:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01045fd:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104600:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104603:	eb 03                	jmp    f0104608 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0104605:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104608:	39 c8                	cmp    %ecx,%eax
f010460a:	7e 0b                	jle    f0104617 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f010460c:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104610:	83 ea 0c             	sub    $0xc,%edx
f0104613:	39 fb                	cmp    %edi,%ebx
f0104615:	75 ee                	jne    f0104605 <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104617:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f010461a:	89 06                	mov    %eax,(%esi)
	}
}
f010461c:	83 c4 14             	add    $0x14,%esp
f010461f:	5b                   	pop    %ebx
f0104620:	5e                   	pop    %esi
f0104621:	5f                   	pop    %edi
f0104622:	5d                   	pop    %ebp
f0104623:	c3                   	ret    

f0104624 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0104624:	55                   	push   %ebp
f0104625:	89 e5                	mov    %esp,%ebp
f0104627:	57                   	push   %edi
f0104628:	56                   	push   %esi
f0104629:	53                   	push   %ebx
f010462a:	83 ec 3c             	sub    $0x3c,%esp
f010462d:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104630:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0104633:	c7 06 50 76 10 f0    	movl   $0xf0107650,(%esi)
	info->eip_line = 0;
f0104639:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f0104640:	c7 46 08 50 76 10 f0 	movl   $0xf0107650,0x8(%esi)
	info->eip_fn_namelen = 9;
f0104647:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f010464e:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f0104651:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0104658:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f010465e:	0f 87 a4 00 00 00    	ja     f0104708 <debuginfo_eip+0xe4>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f0104664:	e8 5e 10 00 00       	call   f01056c7 <cpunum>
f0104669:	6a 05                	push   $0x5
f010466b:	6a 10                	push   $0x10
f010466d:	68 00 00 20 00       	push   $0x200000
f0104672:	6b c0 74             	imul   $0x74,%eax,%eax
f0104675:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f010467b:	e8 89 e7 ff ff       	call   f0102e09 <user_mem_check>
f0104680:	83 c4 10             	add    $0x10,%esp
f0104683:	85 c0                	test   %eax,%eax
f0104685:	0f 88 24 02 00 00    	js     f01048af <debuginfo_eip+0x28b>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f010468b:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f0104690:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f0104696:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f010469c:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f010469f:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f01046a5:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f01046a8:	89 d9                	mov    %ebx,%ecx
f01046aa:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f01046ad:	29 c1                	sub    %eax,%ecx
f01046af:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f01046b2:	e8 10 10 00 00       	call   f01056c7 <cpunum>
f01046b7:	6a 05                	push   $0x5
f01046b9:	ff 75 b8             	pushl  -0x48(%ebp)
f01046bc:	ff 75 c4             	pushl  -0x3c(%ebp)
f01046bf:	6b c0 74             	imul   $0x74,%eax,%eax
f01046c2:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f01046c8:	e8 3c e7 ff ff       	call   f0102e09 <user_mem_check>
f01046cd:	83 c4 10             	add    $0x10,%esp
f01046d0:	85 c0                	test   %eax,%eax
f01046d2:	0f 88 de 01 00 00    	js     f01048b6 <debuginfo_eip+0x292>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f01046d8:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01046db:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01046de:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01046e1:	e8 e1 0f 00 00       	call   f01056c7 <cpunum>
f01046e6:	6a 05                	push   $0x5
f01046e8:	ff 75 b8             	pushl  -0x48(%ebp)
f01046eb:	ff 75 c0             	pushl  -0x40(%ebp)
f01046ee:	6b c0 74             	imul   $0x74,%eax,%eax
f01046f1:	ff b0 48 c0 22 f0    	pushl  -0xfdd3fb8(%eax)
f01046f7:	e8 0d e7 ff ff       	call   f0102e09 <user_mem_check>
f01046fc:	83 c4 10             	add    $0x10,%esp
f01046ff:	85 c0                	test   %eax,%eax
f0104701:	79 1f                	jns    f0104722 <debuginfo_eip+0xfe>
f0104703:	e9 b5 01 00 00       	jmp    f01048bd <debuginfo_eip+0x299>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104708:	c7 45 bc bf 56 11 f0 	movl   $0xf01156bf,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f010470f:	c7 45 c0 f1 1f 11 f0 	movl   $0xf0111ff1,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f0104716:	bb f0 1f 11 f0       	mov    $0xf0111ff0,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f010471b:	c7 45 c4 38 7b 10 f0 	movl   $0xf0107b38,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0104722:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104725:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104728:	0f 83 96 01 00 00    	jae    f01048c4 <debuginfo_eip+0x2a0>
f010472e:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f0104732:	0f 85 93 01 00 00    	jne    f01048cb <debuginfo_eip+0x2a7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0104738:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f010473f:	89 d8                	mov    %ebx,%eax
f0104741:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104744:	29 d8                	sub    %ebx,%eax
f0104746:	c1 f8 02             	sar    $0x2,%eax
f0104749:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010474f:	83 e8 01             	sub    $0x1,%eax
f0104752:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0104755:	83 ec 08             	sub    $0x8,%esp
f0104758:	57                   	push   %edi
f0104759:	6a 64                	push   $0x64
f010475b:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f010475e:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104761:	89 d8                	mov    %ebx,%eax
f0104763:	e8 ba fd ff ff       	call   f0104522 <stab_binsearch>
	if (lfile == 0)
f0104768:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010476b:	83 c4 10             	add    $0x10,%esp
f010476e:	85 c0                	test   %eax,%eax
f0104770:	0f 84 5c 01 00 00    	je     f01048d2 <debuginfo_eip+0x2ae>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0104776:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f0104779:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010477c:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010477f:	83 ec 08             	sub    $0x8,%esp
f0104782:	57                   	push   %edi
f0104783:	6a 24                	push   $0x24
f0104785:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0104788:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010478b:	89 d8                	mov    %ebx,%eax
f010478d:	e8 90 fd ff ff       	call   f0104522 <stab_binsearch>

	if (lfun <= rfun) {
f0104792:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0104795:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104798:	83 c4 10             	add    $0x10,%esp
f010479b:	39 d8                	cmp    %ebx,%eax
f010479d:	7f 32                	jg     f01047d1 <debuginfo_eip+0x1ad>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010479f:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01047a2:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f01047a5:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f01047a8:	8b 11                	mov    (%ecx),%edx
f01047aa:	89 55 b8             	mov    %edx,-0x48(%ebp)
f01047ad:	8b 55 bc             	mov    -0x44(%ebp),%edx
f01047b0:	2b 55 c0             	sub    -0x40(%ebp),%edx
f01047b3:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f01047b6:	73 09                	jae    f01047c1 <debuginfo_eip+0x19d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01047b8:	8b 55 b8             	mov    -0x48(%ebp),%edx
f01047bb:	03 55 c0             	add    -0x40(%ebp),%edx
f01047be:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f01047c1:	8b 51 08             	mov    0x8(%ecx),%edx
f01047c4:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f01047c7:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f01047c9:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01047cc:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f01047cf:	eb 0f                	jmp    f01047e0 <debuginfo_eip+0x1bc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01047d1:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f01047d4:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01047d7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01047da:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01047dd:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01047e0:	83 ec 08             	sub    $0x8,%esp
f01047e3:	6a 3a                	push   $0x3a
f01047e5:	ff 76 08             	pushl  0x8(%esi)
f01047e8:	e8 99 08 00 00       	call   f0105086 <strfind>
f01047ed:	2b 46 08             	sub    0x8(%esi),%eax
f01047f0:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f01047f3:	83 c4 08             	add    $0x8,%esp
f01047f6:	57                   	push   %edi
f01047f7:	6a 44                	push   $0x44
f01047f9:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01047fc:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01047ff:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104802:	89 d8                	mov    %ebx,%eax
f0104804:	e8 19 fd ff ff       	call   f0104522 <stab_binsearch>
	if (lline > rline) {
f0104809:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010480c:	83 c4 10             	add    $0x10,%esp
f010480f:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104812:	0f 8f c1 00 00 00    	jg     f01048d9 <debuginfo_eip+0x2b5>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104818:	8d 04 40             	lea    (%eax,%eax,2),%eax
f010481b:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0104820:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104823:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104826:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104829:	8d 14 40             	lea    (%eax,%eax,2),%edx
f010482c:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f010482f:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104832:	eb 06                	jmp    f010483a <debuginfo_eip+0x216>
f0104834:	83 e8 01             	sub    $0x1,%eax
f0104837:	83 ea 0c             	sub    $0xc,%edx
f010483a:	39 c7                	cmp    %eax,%edi
f010483c:	7f 2a                	jg     f0104868 <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f010483e:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104842:	80 f9 84             	cmp    $0x84,%cl
f0104845:	0f 84 9c 00 00 00    	je     f01048e7 <debuginfo_eip+0x2c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010484b:	80 f9 64             	cmp    $0x64,%cl
f010484e:	75 e4                	jne    f0104834 <debuginfo_eip+0x210>
f0104850:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104854:	74 de                	je     f0104834 <debuginfo_eip+0x210>
f0104856:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104859:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010485c:	e9 8c 00 00 00       	jmp    f01048ed <debuginfo_eip+0x2c9>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104861:	03 55 c0             	add    -0x40(%ebp),%edx
f0104864:	89 16                	mov    %edx,(%esi)
f0104866:	eb 03                	jmp    f010486b <debuginfo_eip+0x247>
f0104868:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010486b:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010486e:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104871:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104876:	39 da                	cmp    %ebx,%edx
f0104878:	0f 8d 8b 00 00 00    	jge    f0104909 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
f010487e:	83 c2 01             	add    $0x1,%edx
f0104881:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104884:	89 d0                	mov    %edx,%eax
f0104886:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104889:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f010488c:	8d 14 97             	lea    (%edi,%edx,4),%edx
f010488f:	eb 04                	jmp    f0104895 <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104891:	83 46 14 01          	addl   $0x1,0x14(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104895:	39 c3                	cmp    %eax,%ebx
f0104897:	7e 47                	jle    f01048e0 <debuginfo_eip+0x2bc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104899:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f010489d:	83 c0 01             	add    $0x1,%eax
f01048a0:	83 c2 0c             	add    $0xc,%edx
f01048a3:	80 f9 a0             	cmp    $0xa0,%cl
f01048a6:	74 e9                	je     f0104891 <debuginfo_eip+0x26d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01048a8:	b8 00 00 00 00       	mov    $0x0,%eax
f01048ad:	eb 5a                	jmp    f0104909 <debuginfo_eip+0x2e5>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f01048af:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048b4:	eb 53                	jmp    f0104909 <debuginfo_eip+0x2e5>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f01048b6:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048bb:	eb 4c                	jmp    f0104909 <debuginfo_eip+0x2e5>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f01048bd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048c2:	eb 45                	jmp    f0104909 <debuginfo_eip+0x2e5>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01048c4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048c9:	eb 3e                	jmp    f0104909 <debuginfo_eip+0x2e5>
f01048cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048d0:	eb 37                	jmp    f0104909 <debuginfo_eip+0x2e5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f01048d2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048d7:	eb 30                	jmp    f0104909 <debuginfo_eip+0x2e5>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f01048d9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01048de:	eb 29                	jmp    f0104909 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01048e0:	b8 00 00 00 00       	mov    $0x0,%eax
f01048e5:	eb 22                	jmp    f0104909 <debuginfo_eip+0x2e5>
f01048e7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01048ea:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01048ed:	8d 04 40             	lea    (%eax,%eax,2),%eax
f01048f0:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f01048f3:	8b 14 87             	mov    (%edi,%eax,4),%edx
f01048f6:	8b 45 bc             	mov    -0x44(%ebp),%eax
f01048f9:	2b 45 c0             	sub    -0x40(%ebp),%eax
f01048fc:	39 c2                	cmp    %eax,%edx
f01048fe:	0f 82 5d ff ff ff    	jb     f0104861 <debuginfo_eip+0x23d>
f0104904:	e9 62 ff ff ff       	jmp    f010486b <debuginfo_eip+0x247>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0104909:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010490c:	5b                   	pop    %ebx
f010490d:	5e                   	pop    %esi
f010490e:	5f                   	pop    %edi
f010490f:	5d                   	pop    %ebp
f0104910:	c3                   	ret    

f0104911 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104911:	55                   	push   %ebp
f0104912:	89 e5                	mov    %esp,%ebp
f0104914:	57                   	push   %edi
f0104915:	56                   	push   %esi
f0104916:	53                   	push   %ebx
f0104917:	83 ec 1c             	sub    $0x1c,%esp
f010491a:	89 c7                	mov    %eax,%edi
f010491c:	89 d6                	mov    %edx,%esi
f010491e:	8b 45 08             	mov    0x8(%ebp),%eax
f0104921:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104924:	89 d1                	mov    %edx,%ecx
f0104926:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104929:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f010492c:	8b 45 10             	mov    0x10(%ebp),%eax
f010492f:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104932:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104935:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f010493c:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f010493f:	72 05                	jb     f0104946 <printnum+0x35>
f0104941:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0104944:	77 3e                	ja     f0104984 <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104946:	83 ec 0c             	sub    $0xc,%esp
f0104949:	ff 75 18             	pushl  0x18(%ebp)
f010494c:	83 eb 01             	sub    $0x1,%ebx
f010494f:	53                   	push   %ebx
f0104950:	50                   	push   %eax
f0104951:	83 ec 08             	sub    $0x8,%esp
f0104954:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104957:	ff 75 e0             	pushl  -0x20(%ebp)
f010495a:	ff 75 dc             	pushl  -0x24(%ebp)
f010495d:	ff 75 d8             	pushl  -0x28(%ebp)
f0104960:	e8 5b 11 00 00       	call   f0105ac0 <__udivdi3>
f0104965:	83 c4 18             	add    $0x18,%esp
f0104968:	52                   	push   %edx
f0104969:	50                   	push   %eax
f010496a:	89 f2                	mov    %esi,%edx
f010496c:	89 f8                	mov    %edi,%eax
f010496e:	e8 9e ff ff ff       	call   f0104911 <printnum>
f0104973:	83 c4 20             	add    $0x20,%esp
f0104976:	eb 13                	jmp    f010498b <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104978:	83 ec 08             	sub    $0x8,%esp
f010497b:	56                   	push   %esi
f010497c:	ff 75 18             	pushl  0x18(%ebp)
f010497f:	ff d7                	call   *%edi
f0104981:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104984:	83 eb 01             	sub    $0x1,%ebx
f0104987:	85 db                	test   %ebx,%ebx
f0104989:	7f ed                	jg     f0104978 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f010498b:	83 ec 08             	sub    $0x8,%esp
f010498e:	56                   	push   %esi
f010498f:	83 ec 04             	sub    $0x4,%esp
f0104992:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104995:	ff 75 e0             	pushl  -0x20(%ebp)
f0104998:	ff 75 dc             	pushl  -0x24(%ebp)
f010499b:	ff 75 d8             	pushl  -0x28(%ebp)
f010499e:	e8 4d 12 00 00       	call   f0105bf0 <__umoddi3>
f01049a3:	83 c4 14             	add    $0x14,%esp
f01049a6:	0f be 80 5a 76 10 f0 	movsbl -0xfef89a6(%eax),%eax
f01049ad:	50                   	push   %eax
f01049ae:	ff d7                	call   *%edi
f01049b0:	83 c4 10             	add    $0x10,%esp
}
f01049b3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01049b6:	5b                   	pop    %ebx
f01049b7:	5e                   	pop    %esi
f01049b8:	5f                   	pop    %edi
f01049b9:	5d                   	pop    %ebp
f01049ba:	c3                   	ret    

f01049bb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01049bb:	55                   	push   %ebp
f01049bc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01049be:	83 fa 01             	cmp    $0x1,%edx
f01049c1:	7e 0e                	jle    f01049d1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01049c3:	8b 10                	mov    (%eax),%edx
f01049c5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01049c8:	89 08                	mov    %ecx,(%eax)
f01049ca:	8b 02                	mov    (%edx),%eax
f01049cc:	8b 52 04             	mov    0x4(%edx),%edx
f01049cf:	eb 22                	jmp    f01049f3 <getuint+0x38>
	else if (lflag)
f01049d1:	85 d2                	test   %edx,%edx
f01049d3:	74 10                	je     f01049e5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01049d5:	8b 10                	mov    (%eax),%edx
f01049d7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01049da:	89 08                	mov    %ecx,(%eax)
f01049dc:	8b 02                	mov    (%edx),%eax
f01049de:	ba 00 00 00 00       	mov    $0x0,%edx
f01049e3:	eb 0e                	jmp    f01049f3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01049e5:	8b 10                	mov    (%eax),%edx
f01049e7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01049ea:	89 08                	mov    %ecx,(%eax)
f01049ec:	8b 02                	mov    (%edx),%eax
f01049ee:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01049f3:	5d                   	pop    %ebp
f01049f4:	c3                   	ret    

f01049f5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01049f5:	55                   	push   %ebp
f01049f6:	89 e5                	mov    %esp,%ebp
f01049f8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01049fb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01049ff:	8b 10                	mov    (%eax),%edx
f0104a01:	3b 50 04             	cmp    0x4(%eax),%edx
f0104a04:	73 0a                	jae    f0104a10 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104a06:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104a09:	89 08                	mov    %ecx,(%eax)
f0104a0b:	8b 45 08             	mov    0x8(%ebp),%eax
f0104a0e:	88 02                	mov    %al,(%edx)
}
f0104a10:	5d                   	pop    %ebp
f0104a11:	c3                   	ret    

f0104a12 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104a12:	55                   	push   %ebp
f0104a13:	89 e5                	mov    %esp,%ebp
f0104a15:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104a18:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104a1b:	50                   	push   %eax
f0104a1c:	ff 75 10             	pushl  0x10(%ebp)
f0104a1f:	ff 75 0c             	pushl  0xc(%ebp)
f0104a22:	ff 75 08             	pushl  0x8(%ebp)
f0104a25:	e8 05 00 00 00       	call   f0104a2f <vprintfmt>
	va_end(ap);
f0104a2a:	83 c4 10             	add    $0x10,%esp
}
f0104a2d:	c9                   	leave  
f0104a2e:	c3                   	ret    

f0104a2f <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104a2f:	55                   	push   %ebp
f0104a30:	89 e5                	mov    %esp,%ebp
f0104a32:	57                   	push   %edi
f0104a33:	56                   	push   %esi
f0104a34:	53                   	push   %ebx
f0104a35:	83 ec 2c             	sub    $0x2c,%esp
f0104a38:	8b 75 08             	mov    0x8(%ebp),%esi
f0104a3b:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104a3e:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104a41:	eb 12                	jmp    f0104a55 <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104a43:	85 c0                	test   %eax,%eax
f0104a45:	0f 84 90 03 00 00    	je     f0104ddb <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0104a4b:	83 ec 08             	sub    $0x8,%esp
f0104a4e:	53                   	push   %ebx
f0104a4f:	50                   	push   %eax
f0104a50:	ff d6                	call   *%esi
f0104a52:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104a55:	83 c7 01             	add    $0x1,%edi
f0104a58:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104a5c:	83 f8 25             	cmp    $0x25,%eax
f0104a5f:	75 e2                	jne    f0104a43 <vprintfmt+0x14>
f0104a61:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104a65:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104a6c:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104a73:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104a7a:	ba 00 00 00 00       	mov    $0x0,%edx
f0104a7f:	eb 07                	jmp    f0104a88 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a81:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104a84:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104a88:	8d 47 01             	lea    0x1(%edi),%eax
f0104a8b:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104a8e:	0f b6 07             	movzbl (%edi),%eax
f0104a91:	0f b6 c8             	movzbl %al,%ecx
f0104a94:	83 e8 23             	sub    $0x23,%eax
f0104a97:	3c 55                	cmp    $0x55,%al
f0104a99:	0f 87 21 03 00 00    	ja     f0104dc0 <vprintfmt+0x391>
f0104a9f:	0f b6 c0             	movzbl %al,%eax
f0104aa2:	ff 24 85 20 77 10 f0 	jmp    *-0xfef88e0(,%eax,4)
f0104aa9:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104aac:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104ab0:	eb d6                	jmp    f0104a88 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ab2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104ab5:	b8 00 00 00 00       	mov    $0x0,%eax
f0104aba:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104abd:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104ac0:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104ac4:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104ac7:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104aca:	83 fa 09             	cmp    $0x9,%edx
f0104acd:	77 39                	ja     f0104b08 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104acf:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104ad2:	eb e9                	jmp    f0104abd <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104ad4:	8b 45 14             	mov    0x14(%ebp),%eax
f0104ad7:	8d 48 04             	lea    0x4(%eax),%ecx
f0104ada:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104add:	8b 00                	mov    (%eax),%eax
f0104adf:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104ae2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104ae5:	eb 27                	jmp    f0104b0e <vprintfmt+0xdf>
f0104ae7:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104aea:	85 c0                	test   %eax,%eax
f0104aec:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104af1:	0f 49 c8             	cmovns %eax,%ecx
f0104af4:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104af7:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104afa:	eb 8c                	jmp    f0104a88 <vprintfmt+0x59>
f0104afc:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104aff:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104b06:	eb 80                	jmp    f0104a88 <vprintfmt+0x59>
f0104b08:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104b0b:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104b0e:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104b12:	0f 89 70 ff ff ff    	jns    f0104a88 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104b18:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104b1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104b1e:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104b25:	e9 5e ff ff ff       	jmp    f0104a88 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104b2a:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b2d:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104b30:	e9 53 ff ff ff       	jmp    f0104a88 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104b35:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b38:	8d 50 04             	lea    0x4(%eax),%edx
f0104b3b:	89 55 14             	mov    %edx,0x14(%ebp)
f0104b3e:	83 ec 08             	sub    $0x8,%esp
f0104b41:	53                   	push   %ebx
f0104b42:	ff 30                	pushl  (%eax)
f0104b44:	ff d6                	call   *%esi
			break;
f0104b46:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b49:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104b4c:	e9 04 ff ff ff       	jmp    f0104a55 <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104b51:	8b 45 14             	mov    0x14(%ebp),%eax
f0104b54:	8d 50 04             	lea    0x4(%eax),%edx
f0104b57:	89 55 14             	mov    %edx,0x14(%ebp)
f0104b5a:	8b 00                	mov    (%eax),%eax
f0104b5c:	99                   	cltd   
f0104b5d:	31 d0                	xor    %edx,%eax
f0104b5f:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104b61:	83 f8 09             	cmp    $0x9,%eax
f0104b64:	7f 0b                	jg     f0104b71 <vprintfmt+0x142>
f0104b66:	8b 14 85 80 78 10 f0 	mov    -0xfef8780(,%eax,4),%edx
f0104b6d:	85 d2                	test   %edx,%edx
f0104b6f:	75 18                	jne    f0104b89 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104b71:	50                   	push   %eax
f0104b72:	68 72 76 10 f0       	push   $0xf0107672
f0104b77:	53                   	push   %ebx
f0104b78:	56                   	push   %esi
f0104b79:	e8 94 fe ff ff       	call   f0104a12 <printfmt>
f0104b7e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b81:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104b84:	e9 cc fe ff ff       	jmp    f0104a55 <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104b89:	52                   	push   %edx
f0104b8a:	68 6d 6d 10 f0       	push   $0xf0106d6d
f0104b8f:	53                   	push   %ebx
f0104b90:	56                   	push   %esi
f0104b91:	e8 7c fe ff ff       	call   f0104a12 <printfmt>
f0104b96:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104b99:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104b9c:	e9 b4 fe ff ff       	jmp    f0104a55 <vprintfmt+0x26>
f0104ba1:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104ba4:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104ba7:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104baa:	8b 45 14             	mov    0x14(%ebp),%eax
f0104bad:	8d 50 04             	lea    0x4(%eax),%edx
f0104bb0:	89 55 14             	mov    %edx,0x14(%ebp)
f0104bb3:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104bb5:	85 ff                	test   %edi,%edi
f0104bb7:	ba 6b 76 10 f0       	mov    $0xf010766b,%edx
f0104bbc:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0104bbf:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104bc3:	0f 84 92 00 00 00    	je     f0104c5b <vprintfmt+0x22c>
f0104bc9:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104bcd:	0f 8e 96 00 00 00    	jle    f0104c69 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104bd3:	83 ec 08             	sub    $0x8,%esp
f0104bd6:	51                   	push   %ecx
f0104bd7:	57                   	push   %edi
f0104bd8:	e8 5f 03 00 00       	call   f0104f3c <strnlen>
f0104bdd:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104be0:	29 c1                	sub    %eax,%ecx
f0104be2:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104be5:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104be8:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104bec:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104bef:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104bf2:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104bf4:	eb 0f                	jmp    f0104c05 <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104bf6:	83 ec 08             	sub    $0x8,%esp
f0104bf9:	53                   	push   %ebx
f0104bfa:	ff 75 e0             	pushl  -0x20(%ebp)
f0104bfd:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104bff:	83 ef 01             	sub    $0x1,%edi
f0104c02:	83 c4 10             	add    $0x10,%esp
f0104c05:	85 ff                	test   %edi,%edi
f0104c07:	7f ed                	jg     f0104bf6 <vprintfmt+0x1c7>
f0104c09:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104c0c:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104c0f:	85 c9                	test   %ecx,%ecx
f0104c11:	b8 00 00 00 00       	mov    $0x0,%eax
f0104c16:	0f 49 c1             	cmovns %ecx,%eax
f0104c19:	29 c1                	sub    %eax,%ecx
f0104c1b:	89 75 08             	mov    %esi,0x8(%ebp)
f0104c1e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104c21:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104c24:	89 cb                	mov    %ecx,%ebx
f0104c26:	eb 4d                	jmp    f0104c75 <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104c28:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104c2c:	74 1b                	je     f0104c49 <vprintfmt+0x21a>
f0104c2e:	0f be c0             	movsbl %al,%eax
f0104c31:	83 e8 20             	sub    $0x20,%eax
f0104c34:	83 f8 5e             	cmp    $0x5e,%eax
f0104c37:	76 10                	jbe    f0104c49 <vprintfmt+0x21a>
					putch('?', putdat);
f0104c39:	83 ec 08             	sub    $0x8,%esp
f0104c3c:	ff 75 0c             	pushl  0xc(%ebp)
f0104c3f:	6a 3f                	push   $0x3f
f0104c41:	ff 55 08             	call   *0x8(%ebp)
f0104c44:	83 c4 10             	add    $0x10,%esp
f0104c47:	eb 0d                	jmp    f0104c56 <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104c49:	83 ec 08             	sub    $0x8,%esp
f0104c4c:	ff 75 0c             	pushl  0xc(%ebp)
f0104c4f:	52                   	push   %edx
f0104c50:	ff 55 08             	call   *0x8(%ebp)
f0104c53:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104c56:	83 eb 01             	sub    $0x1,%ebx
f0104c59:	eb 1a                	jmp    f0104c75 <vprintfmt+0x246>
f0104c5b:	89 75 08             	mov    %esi,0x8(%ebp)
f0104c5e:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104c61:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104c64:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104c67:	eb 0c                	jmp    f0104c75 <vprintfmt+0x246>
f0104c69:	89 75 08             	mov    %esi,0x8(%ebp)
f0104c6c:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104c6f:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104c72:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104c75:	83 c7 01             	add    $0x1,%edi
f0104c78:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104c7c:	0f be d0             	movsbl %al,%edx
f0104c7f:	85 d2                	test   %edx,%edx
f0104c81:	74 23                	je     f0104ca6 <vprintfmt+0x277>
f0104c83:	85 f6                	test   %esi,%esi
f0104c85:	78 a1                	js     f0104c28 <vprintfmt+0x1f9>
f0104c87:	83 ee 01             	sub    $0x1,%esi
f0104c8a:	79 9c                	jns    f0104c28 <vprintfmt+0x1f9>
f0104c8c:	89 df                	mov    %ebx,%edi
f0104c8e:	8b 75 08             	mov    0x8(%ebp),%esi
f0104c91:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104c94:	eb 18                	jmp    f0104cae <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104c96:	83 ec 08             	sub    $0x8,%esp
f0104c99:	53                   	push   %ebx
f0104c9a:	6a 20                	push   $0x20
f0104c9c:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104c9e:	83 ef 01             	sub    $0x1,%edi
f0104ca1:	83 c4 10             	add    $0x10,%esp
f0104ca4:	eb 08                	jmp    f0104cae <vprintfmt+0x27f>
f0104ca6:	89 df                	mov    %ebx,%edi
f0104ca8:	8b 75 08             	mov    0x8(%ebp),%esi
f0104cab:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104cae:	85 ff                	test   %edi,%edi
f0104cb0:	7f e4                	jg     f0104c96 <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cb2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104cb5:	e9 9b fd ff ff       	jmp    f0104a55 <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104cba:	83 fa 01             	cmp    $0x1,%edx
f0104cbd:	7e 16                	jle    f0104cd5 <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f0104cbf:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cc2:	8d 50 08             	lea    0x8(%eax),%edx
f0104cc5:	89 55 14             	mov    %edx,0x14(%ebp)
f0104cc8:	8b 50 04             	mov    0x4(%eax),%edx
f0104ccb:	8b 00                	mov    (%eax),%eax
f0104ccd:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104cd0:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104cd3:	eb 32                	jmp    f0104d07 <vprintfmt+0x2d8>
	else if (lflag)
f0104cd5:	85 d2                	test   %edx,%edx
f0104cd7:	74 18                	je     f0104cf1 <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f0104cd9:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cdc:	8d 50 04             	lea    0x4(%eax),%edx
f0104cdf:	89 55 14             	mov    %edx,0x14(%ebp)
f0104ce2:	8b 00                	mov    (%eax),%eax
f0104ce4:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104ce7:	89 c1                	mov    %eax,%ecx
f0104ce9:	c1 f9 1f             	sar    $0x1f,%ecx
f0104cec:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104cef:	eb 16                	jmp    f0104d07 <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f0104cf1:	8b 45 14             	mov    0x14(%ebp),%eax
f0104cf4:	8d 50 04             	lea    0x4(%eax),%edx
f0104cf7:	89 55 14             	mov    %edx,0x14(%ebp)
f0104cfa:	8b 00                	mov    (%eax),%eax
f0104cfc:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104cff:	89 c1                	mov    %eax,%ecx
f0104d01:	c1 f9 1f             	sar    $0x1f,%ecx
f0104d04:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104d07:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104d0a:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104d0d:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104d12:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104d16:	79 74                	jns    f0104d8c <vprintfmt+0x35d>
				putch('-', putdat);
f0104d18:	83 ec 08             	sub    $0x8,%esp
f0104d1b:	53                   	push   %ebx
f0104d1c:	6a 2d                	push   $0x2d
f0104d1e:	ff d6                	call   *%esi
				num = -(long long) num;
f0104d20:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104d23:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104d26:	f7 d8                	neg    %eax
f0104d28:	83 d2 00             	adc    $0x0,%edx
f0104d2b:	f7 da                	neg    %edx
f0104d2d:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104d30:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104d35:	eb 55                	jmp    f0104d8c <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104d37:	8d 45 14             	lea    0x14(%ebp),%eax
f0104d3a:	e8 7c fc ff ff       	call   f01049bb <getuint>
			base = 10;
f0104d3f:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104d44:	eb 46                	jmp    f0104d8c <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104d46:	8d 45 14             	lea    0x14(%ebp),%eax
f0104d49:	e8 6d fc ff ff       	call   f01049bb <getuint>
			base = 8;
f0104d4e:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104d53:	eb 37                	jmp    f0104d8c <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0104d55:	83 ec 08             	sub    $0x8,%esp
f0104d58:	53                   	push   %ebx
f0104d59:	6a 30                	push   $0x30
f0104d5b:	ff d6                	call   *%esi
			putch('x', putdat);
f0104d5d:	83 c4 08             	add    $0x8,%esp
f0104d60:	53                   	push   %ebx
f0104d61:	6a 78                	push   $0x78
f0104d63:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104d65:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d68:	8d 50 04             	lea    0x4(%eax),%edx
f0104d6b:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104d6e:	8b 00                	mov    (%eax),%eax
f0104d70:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104d75:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104d78:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104d7d:	eb 0d                	jmp    f0104d8c <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104d7f:	8d 45 14             	lea    0x14(%ebp),%eax
f0104d82:	e8 34 fc ff ff       	call   f01049bb <getuint>
			base = 16;
f0104d87:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104d8c:	83 ec 0c             	sub    $0xc,%esp
f0104d8f:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104d93:	57                   	push   %edi
f0104d94:	ff 75 e0             	pushl  -0x20(%ebp)
f0104d97:	51                   	push   %ecx
f0104d98:	52                   	push   %edx
f0104d99:	50                   	push   %eax
f0104d9a:	89 da                	mov    %ebx,%edx
f0104d9c:	89 f0                	mov    %esi,%eax
f0104d9e:	e8 6e fb ff ff       	call   f0104911 <printnum>
			break;
f0104da3:	83 c4 20             	add    $0x20,%esp
f0104da6:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104da9:	e9 a7 fc ff ff       	jmp    f0104a55 <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0104dae:	83 ec 08             	sub    $0x8,%esp
f0104db1:	53                   	push   %ebx
f0104db2:	51                   	push   %ecx
f0104db3:	ff d6                	call   *%esi
			break;
f0104db5:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104db8:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0104dbb:	e9 95 fc ff ff       	jmp    f0104a55 <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0104dc0:	83 ec 08             	sub    $0x8,%esp
f0104dc3:	53                   	push   %ebx
f0104dc4:	6a 25                	push   $0x25
f0104dc6:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0104dc8:	83 c4 10             	add    $0x10,%esp
f0104dcb:	eb 03                	jmp    f0104dd0 <vprintfmt+0x3a1>
f0104dcd:	83 ef 01             	sub    $0x1,%edi
f0104dd0:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f0104dd4:	75 f7                	jne    f0104dcd <vprintfmt+0x39e>
f0104dd6:	e9 7a fc ff ff       	jmp    f0104a55 <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0104ddb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104dde:	5b                   	pop    %ebx
f0104ddf:	5e                   	pop    %esi
f0104de0:	5f                   	pop    %edi
f0104de1:	5d                   	pop    %ebp
f0104de2:	c3                   	ret    

f0104de3 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0104de3:	55                   	push   %ebp
f0104de4:	89 e5                	mov    %esp,%ebp
f0104de6:	83 ec 18             	sub    $0x18,%esp
f0104de9:	8b 45 08             	mov    0x8(%ebp),%eax
f0104dec:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0104def:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104df2:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0104df6:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0104df9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0104e00:	85 c0                	test   %eax,%eax
f0104e02:	74 26                	je     f0104e2a <vsnprintf+0x47>
f0104e04:	85 d2                	test   %edx,%edx
f0104e06:	7e 22                	jle    f0104e2a <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0104e08:	ff 75 14             	pushl  0x14(%ebp)
f0104e0b:	ff 75 10             	pushl  0x10(%ebp)
f0104e0e:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0104e11:	50                   	push   %eax
f0104e12:	68 f5 49 10 f0       	push   $0xf01049f5
f0104e17:	e8 13 fc ff ff       	call   f0104a2f <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0104e1c:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0104e1f:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0104e22:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0104e25:	83 c4 10             	add    $0x10,%esp
f0104e28:	eb 05                	jmp    f0104e2f <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0104e2a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0104e2f:	c9                   	leave  
f0104e30:	c3                   	ret    

f0104e31 <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0104e31:	55                   	push   %ebp
f0104e32:	89 e5                	mov    %esp,%ebp
f0104e34:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0104e37:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0104e3a:	50                   	push   %eax
f0104e3b:	ff 75 10             	pushl  0x10(%ebp)
f0104e3e:	ff 75 0c             	pushl  0xc(%ebp)
f0104e41:	ff 75 08             	pushl  0x8(%ebp)
f0104e44:	e8 9a ff ff ff       	call   f0104de3 <vsnprintf>
	va_end(ap);

	return rc;
}
f0104e49:	c9                   	leave  
f0104e4a:	c3                   	ret    

f0104e4b <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0104e4b:	55                   	push   %ebp
f0104e4c:	89 e5                	mov    %esp,%ebp
f0104e4e:	57                   	push   %edi
f0104e4f:	56                   	push   %esi
f0104e50:	53                   	push   %ebx
f0104e51:	83 ec 0c             	sub    $0xc,%esp
f0104e54:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0104e57:	85 c0                	test   %eax,%eax
f0104e59:	74 11                	je     f0104e6c <readline+0x21>
		cprintf("%s", prompt);
f0104e5b:	83 ec 08             	sub    $0x8,%esp
f0104e5e:	50                   	push   %eax
f0104e5f:	68 6d 6d 10 f0       	push   $0xf0106d6d
f0104e64:	e8 ea e9 ff ff       	call   f0103853 <cprintf>
f0104e69:	83 c4 10             	add    $0x10,%esp

	i = 0;
	echoing = iscons(0);
f0104e6c:	83 ec 0c             	sub    $0xc,%esp
f0104e6f:	6a 00                	push   $0x0
f0104e71:	e8 f0 b8 ff ff       	call   f0100766 <iscons>
f0104e76:	89 c7                	mov    %eax,%edi
f0104e78:	83 c4 10             	add    $0x10,%esp
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0104e7b:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0104e80:	e8 d0 b8 ff ff       	call   f0100755 <getchar>
f0104e85:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0104e87:	85 c0                	test   %eax,%eax
f0104e89:	79 18                	jns    f0104ea3 <readline+0x58>
			cprintf("read error: %e\n", c);
f0104e8b:	83 ec 08             	sub    $0x8,%esp
f0104e8e:	50                   	push   %eax
f0104e8f:	68 a8 78 10 f0       	push   $0xf01078a8
f0104e94:	e8 ba e9 ff ff       	call   f0103853 <cprintf>
			return NULL;
f0104e99:	83 c4 10             	add    $0x10,%esp
f0104e9c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104ea1:	eb 79                	jmp    f0104f1c <readline+0xd1>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0104ea3:	83 f8 7f             	cmp    $0x7f,%eax
f0104ea6:	0f 94 c2             	sete   %dl
f0104ea9:	83 f8 08             	cmp    $0x8,%eax
f0104eac:	0f 94 c0             	sete   %al
f0104eaf:	08 c2                	or     %al,%dl
f0104eb1:	74 1a                	je     f0104ecd <readline+0x82>
f0104eb3:	85 f6                	test   %esi,%esi
f0104eb5:	7e 16                	jle    f0104ecd <readline+0x82>
			if (echoing)
f0104eb7:	85 ff                	test   %edi,%edi
f0104eb9:	74 0d                	je     f0104ec8 <readline+0x7d>
				cputchar('\b');
f0104ebb:	83 ec 0c             	sub    $0xc,%esp
f0104ebe:	6a 08                	push   $0x8
f0104ec0:	e8 80 b8 ff ff       	call   f0100745 <cputchar>
f0104ec5:	83 c4 10             	add    $0x10,%esp
			i--;
f0104ec8:	83 ee 01             	sub    $0x1,%esi
f0104ecb:	eb b3                	jmp    f0104e80 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0104ecd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0104ed3:	7f 20                	jg     f0104ef5 <readline+0xaa>
f0104ed5:	83 fb 1f             	cmp    $0x1f,%ebx
f0104ed8:	7e 1b                	jle    f0104ef5 <readline+0xaa>
			if (echoing)
f0104eda:	85 ff                	test   %edi,%edi
f0104edc:	74 0c                	je     f0104eea <readline+0x9f>
				cputchar(c);
f0104ede:	83 ec 0c             	sub    $0xc,%esp
f0104ee1:	53                   	push   %ebx
f0104ee2:	e8 5e b8 ff ff       	call   f0100745 <cputchar>
f0104ee7:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0104eea:	88 9e c0 ba 22 f0    	mov    %bl,-0xfdd4540(%esi)
f0104ef0:	8d 76 01             	lea    0x1(%esi),%esi
f0104ef3:	eb 8b                	jmp    f0104e80 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0104ef5:	83 fb 0d             	cmp    $0xd,%ebx
f0104ef8:	74 05                	je     f0104eff <readline+0xb4>
f0104efa:	83 fb 0a             	cmp    $0xa,%ebx
f0104efd:	75 81                	jne    f0104e80 <readline+0x35>
			if (echoing)
f0104eff:	85 ff                	test   %edi,%edi
f0104f01:	74 0d                	je     f0104f10 <readline+0xc5>
				cputchar('\n');
f0104f03:	83 ec 0c             	sub    $0xc,%esp
f0104f06:	6a 0a                	push   $0xa
f0104f08:	e8 38 b8 ff ff       	call   f0100745 <cputchar>
f0104f0d:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0104f10:	c6 86 c0 ba 22 f0 00 	movb   $0x0,-0xfdd4540(%esi)
			return buf;
f0104f17:	b8 c0 ba 22 f0       	mov    $0xf022bac0,%eax
		}
	}
}
f0104f1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104f1f:	5b                   	pop    %ebx
f0104f20:	5e                   	pop    %esi
f0104f21:	5f                   	pop    %edi
f0104f22:	5d                   	pop    %ebp
f0104f23:	c3                   	ret    

f0104f24 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0104f24:	55                   	push   %ebp
f0104f25:	89 e5                	mov    %esp,%ebp
f0104f27:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0104f2a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104f2f:	eb 03                	jmp    f0104f34 <strlen+0x10>
		n++;
f0104f31:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0104f34:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0104f38:	75 f7                	jne    f0104f31 <strlen+0xd>
		n++;
	return n;
}
f0104f3a:	5d                   	pop    %ebp
f0104f3b:	c3                   	ret    

f0104f3c <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0104f3c:	55                   	push   %ebp
f0104f3d:	89 e5                	mov    %esp,%ebp
f0104f3f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104f42:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104f45:	ba 00 00 00 00       	mov    $0x0,%edx
f0104f4a:	eb 03                	jmp    f0104f4f <strnlen+0x13>
		n++;
f0104f4c:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0104f4f:	39 c2                	cmp    %eax,%edx
f0104f51:	74 08                	je     f0104f5b <strnlen+0x1f>
f0104f53:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f0104f57:	75 f3                	jne    f0104f4c <strnlen+0x10>
f0104f59:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f0104f5b:	5d                   	pop    %ebp
f0104f5c:	c3                   	ret    

f0104f5d <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0104f5d:	55                   	push   %ebp
f0104f5e:	89 e5                	mov    %esp,%ebp
f0104f60:	53                   	push   %ebx
f0104f61:	8b 45 08             	mov    0x8(%ebp),%eax
f0104f64:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0104f67:	89 c2                	mov    %eax,%edx
f0104f69:	83 c2 01             	add    $0x1,%edx
f0104f6c:	83 c1 01             	add    $0x1,%ecx
f0104f6f:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f0104f73:	88 5a ff             	mov    %bl,-0x1(%edx)
f0104f76:	84 db                	test   %bl,%bl
f0104f78:	75 ef                	jne    f0104f69 <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f0104f7a:	5b                   	pop    %ebx
f0104f7b:	5d                   	pop    %ebp
f0104f7c:	c3                   	ret    

f0104f7d <strcat>:

char *
strcat(char *dst, const char *src)
{
f0104f7d:	55                   	push   %ebp
f0104f7e:	89 e5                	mov    %esp,%ebp
f0104f80:	53                   	push   %ebx
f0104f81:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0104f84:	53                   	push   %ebx
f0104f85:	e8 9a ff ff ff       	call   f0104f24 <strlen>
f0104f8a:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f0104f8d:	ff 75 0c             	pushl  0xc(%ebp)
f0104f90:	01 d8                	add    %ebx,%eax
f0104f92:	50                   	push   %eax
f0104f93:	e8 c5 ff ff ff       	call   f0104f5d <strcpy>
	return dst;
}
f0104f98:	89 d8                	mov    %ebx,%eax
f0104f9a:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0104f9d:	c9                   	leave  
f0104f9e:	c3                   	ret    

f0104f9f <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104f9f:	55                   	push   %ebp
f0104fa0:	89 e5                	mov    %esp,%ebp
f0104fa2:	56                   	push   %esi
f0104fa3:	53                   	push   %ebx
f0104fa4:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fa7:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104faa:	89 f3                	mov    %esi,%ebx
f0104fac:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104faf:	89 f2                	mov    %esi,%edx
f0104fb1:	eb 0f                	jmp    f0104fc2 <strncpy+0x23>
		*dst++ = *src;
f0104fb3:	83 c2 01             	add    $0x1,%edx
f0104fb6:	0f b6 01             	movzbl (%ecx),%eax
f0104fb9:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104fbc:	80 39 01             	cmpb   $0x1,(%ecx)
f0104fbf:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104fc2:	39 da                	cmp    %ebx,%edx
f0104fc4:	75 ed                	jne    f0104fb3 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104fc6:	89 f0                	mov    %esi,%eax
f0104fc8:	5b                   	pop    %ebx
f0104fc9:	5e                   	pop    %esi
f0104fca:	5d                   	pop    %ebp
f0104fcb:	c3                   	ret    

f0104fcc <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104fcc:	55                   	push   %ebp
f0104fcd:	89 e5                	mov    %esp,%ebp
f0104fcf:	56                   	push   %esi
f0104fd0:	53                   	push   %ebx
f0104fd1:	8b 75 08             	mov    0x8(%ebp),%esi
f0104fd4:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0104fd7:	8b 55 10             	mov    0x10(%ebp),%edx
f0104fda:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104fdc:	85 d2                	test   %edx,%edx
f0104fde:	74 21                	je     f0105001 <strlcpy+0x35>
f0104fe0:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0104fe4:	89 f2                	mov    %esi,%edx
f0104fe6:	eb 09                	jmp    f0104ff1 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0104fe8:	83 c2 01             	add    $0x1,%edx
f0104feb:	83 c1 01             	add    $0x1,%ecx
f0104fee:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104ff1:	39 c2                	cmp    %eax,%edx
f0104ff3:	74 09                	je     f0104ffe <strlcpy+0x32>
f0104ff5:	0f b6 19             	movzbl (%ecx),%ebx
f0104ff8:	84 db                	test   %bl,%bl
f0104ffa:	75 ec                	jne    f0104fe8 <strlcpy+0x1c>
f0104ffc:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f0104ffe:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105001:	29 f0                	sub    %esi,%eax
}
f0105003:	5b                   	pop    %ebx
f0105004:	5e                   	pop    %esi
f0105005:	5d                   	pop    %ebp
f0105006:	c3                   	ret    

f0105007 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105007:	55                   	push   %ebp
f0105008:	89 e5                	mov    %esp,%ebp
f010500a:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010500d:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105010:	eb 06                	jmp    f0105018 <strcmp+0x11>
		p++, q++;
f0105012:	83 c1 01             	add    $0x1,%ecx
f0105015:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105018:	0f b6 01             	movzbl (%ecx),%eax
f010501b:	84 c0                	test   %al,%al
f010501d:	74 04                	je     f0105023 <strcmp+0x1c>
f010501f:	3a 02                	cmp    (%edx),%al
f0105021:	74 ef                	je     f0105012 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0105023:	0f b6 c0             	movzbl %al,%eax
f0105026:	0f b6 12             	movzbl (%edx),%edx
f0105029:	29 d0                	sub    %edx,%eax
}
f010502b:	5d                   	pop    %ebp
f010502c:	c3                   	ret    

f010502d <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010502d:	55                   	push   %ebp
f010502e:	89 e5                	mov    %esp,%ebp
f0105030:	53                   	push   %ebx
f0105031:	8b 45 08             	mov    0x8(%ebp),%eax
f0105034:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105037:	89 c3                	mov    %eax,%ebx
f0105039:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f010503c:	eb 06                	jmp    f0105044 <strncmp+0x17>
		n--, p++, q++;
f010503e:	83 c0 01             	add    $0x1,%eax
f0105041:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0105044:	39 d8                	cmp    %ebx,%eax
f0105046:	74 15                	je     f010505d <strncmp+0x30>
f0105048:	0f b6 08             	movzbl (%eax),%ecx
f010504b:	84 c9                	test   %cl,%cl
f010504d:	74 04                	je     f0105053 <strncmp+0x26>
f010504f:	3a 0a                	cmp    (%edx),%cl
f0105051:	74 eb                	je     f010503e <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0105053:	0f b6 00             	movzbl (%eax),%eax
f0105056:	0f b6 12             	movzbl (%edx),%edx
f0105059:	29 d0                	sub    %edx,%eax
f010505b:	eb 05                	jmp    f0105062 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f010505d:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0105062:	5b                   	pop    %ebx
f0105063:	5d                   	pop    %ebp
f0105064:	c3                   	ret    

f0105065 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0105065:	55                   	push   %ebp
f0105066:	89 e5                	mov    %esp,%ebp
f0105068:	8b 45 08             	mov    0x8(%ebp),%eax
f010506b:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f010506f:	eb 07                	jmp    f0105078 <strchr+0x13>
		if (*s == c)
f0105071:	38 ca                	cmp    %cl,%dl
f0105073:	74 0f                	je     f0105084 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0105075:	83 c0 01             	add    $0x1,%eax
f0105078:	0f b6 10             	movzbl (%eax),%edx
f010507b:	84 d2                	test   %dl,%dl
f010507d:	75 f2                	jne    f0105071 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f010507f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105084:	5d                   	pop    %ebp
f0105085:	c3                   	ret    

f0105086 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105086:	55                   	push   %ebp
f0105087:	89 e5                	mov    %esp,%ebp
f0105089:	8b 45 08             	mov    0x8(%ebp),%eax
f010508c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105090:	eb 03                	jmp    f0105095 <strfind+0xf>
f0105092:	83 c0 01             	add    $0x1,%eax
f0105095:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105098:	84 d2                	test   %dl,%dl
f010509a:	74 04                	je     f01050a0 <strfind+0x1a>
f010509c:	38 ca                	cmp    %cl,%dl
f010509e:	75 f2                	jne    f0105092 <strfind+0xc>
			break;
	return (char *) s;
}
f01050a0:	5d                   	pop    %ebp
f01050a1:	c3                   	ret    

f01050a2 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f01050a2:	55                   	push   %ebp
f01050a3:	89 e5                	mov    %esp,%ebp
f01050a5:	57                   	push   %edi
f01050a6:	56                   	push   %esi
f01050a7:	53                   	push   %ebx
f01050a8:	8b 7d 08             	mov    0x8(%ebp),%edi
f01050ab:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f01050ae:	85 c9                	test   %ecx,%ecx
f01050b0:	74 36                	je     f01050e8 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f01050b2:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01050b8:	75 28                	jne    f01050e2 <memset+0x40>
f01050ba:	f6 c1 03             	test   $0x3,%cl
f01050bd:	75 23                	jne    f01050e2 <memset+0x40>
		c &= 0xFF;
f01050bf:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01050c3:	89 d3                	mov    %edx,%ebx
f01050c5:	c1 e3 08             	shl    $0x8,%ebx
f01050c8:	89 d6                	mov    %edx,%esi
f01050ca:	c1 e6 18             	shl    $0x18,%esi
f01050cd:	89 d0                	mov    %edx,%eax
f01050cf:	c1 e0 10             	shl    $0x10,%eax
f01050d2:	09 f0                	or     %esi,%eax
f01050d4:	09 c2                	or     %eax,%edx
f01050d6:	89 d0                	mov    %edx,%eax
f01050d8:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01050da:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01050dd:	fc                   	cld    
f01050de:	f3 ab                	rep stos %eax,%es:(%edi)
f01050e0:	eb 06                	jmp    f01050e8 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01050e2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01050e5:	fc                   	cld    
f01050e6:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01050e8:	89 f8                	mov    %edi,%eax
f01050ea:	5b                   	pop    %ebx
f01050eb:	5e                   	pop    %esi
f01050ec:	5f                   	pop    %edi
f01050ed:	5d                   	pop    %ebp
f01050ee:	c3                   	ret    

f01050ef <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01050ef:	55                   	push   %ebp
f01050f0:	89 e5                	mov    %esp,%ebp
f01050f2:	57                   	push   %edi
f01050f3:	56                   	push   %esi
f01050f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01050f7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01050fa:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01050fd:	39 c6                	cmp    %eax,%esi
f01050ff:	73 35                	jae    f0105136 <memmove+0x47>
f0105101:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105104:	39 d0                	cmp    %edx,%eax
f0105106:	73 2e                	jae    f0105136 <memmove+0x47>
		s += n;
		d += n;
f0105108:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f010510b:	89 d6                	mov    %edx,%esi
f010510d:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010510f:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105115:	75 13                	jne    f010512a <memmove+0x3b>
f0105117:	f6 c1 03             	test   $0x3,%cl
f010511a:	75 0e                	jne    f010512a <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010511c:	83 ef 04             	sub    $0x4,%edi
f010511f:	8d 72 fc             	lea    -0x4(%edx),%esi
f0105122:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0105125:	fd                   	std    
f0105126:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0105128:	eb 09                	jmp    f0105133 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010512a:	83 ef 01             	sub    $0x1,%edi
f010512d:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0105130:	fd                   	std    
f0105131:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0105133:	fc                   	cld    
f0105134:	eb 1d                	jmp    f0105153 <memmove+0x64>
f0105136:	89 f2                	mov    %esi,%edx
f0105138:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010513a:	f6 c2 03             	test   $0x3,%dl
f010513d:	75 0f                	jne    f010514e <memmove+0x5f>
f010513f:	f6 c1 03             	test   $0x3,%cl
f0105142:	75 0a                	jne    f010514e <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0105144:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0105147:	89 c7                	mov    %eax,%edi
f0105149:	fc                   	cld    
f010514a:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010514c:	eb 05                	jmp    f0105153 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f010514e:	89 c7                	mov    %eax,%edi
f0105150:	fc                   	cld    
f0105151:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0105153:	5e                   	pop    %esi
f0105154:	5f                   	pop    %edi
f0105155:	5d                   	pop    %ebp
f0105156:	c3                   	ret    

f0105157 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0105157:	55                   	push   %ebp
f0105158:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f010515a:	ff 75 10             	pushl  0x10(%ebp)
f010515d:	ff 75 0c             	pushl  0xc(%ebp)
f0105160:	ff 75 08             	pushl  0x8(%ebp)
f0105163:	e8 87 ff ff ff       	call   f01050ef <memmove>
}
f0105168:	c9                   	leave  
f0105169:	c3                   	ret    

f010516a <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f010516a:	55                   	push   %ebp
f010516b:	89 e5                	mov    %esp,%ebp
f010516d:	56                   	push   %esi
f010516e:	53                   	push   %ebx
f010516f:	8b 45 08             	mov    0x8(%ebp),%eax
f0105172:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105175:	89 c6                	mov    %eax,%esi
f0105177:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010517a:	eb 1a                	jmp    f0105196 <memcmp+0x2c>
		if (*s1 != *s2)
f010517c:	0f b6 08             	movzbl (%eax),%ecx
f010517f:	0f b6 1a             	movzbl (%edx),%ebx
f0105182:	38 d9                	cmp    %bl,%cl
f0105184:	74 0a                	je     f0105190 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105186:	0f b6 c1             	movzbl %cl,%eax
f0105189:	0f b6 db             	movzbl %bl,%ebx
f010518c:	29 d8                	sub    %ebx,%eax
f010518e:	eb 0f                	jmp    f010519f <memcmp+0x35>
		s1++, s2++;
f0105190:	83 c0 01             	add    $0x1,%eax
f0105193:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105196:	39 f0                	cmp    %esi,%eax
f0105198:	75 e2                	jne    f010517c <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010519a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010519f:	5b                   	pop    %ebx
f01051a0:	5e                   	pop    %esi
f01051a1:	5d                   	pop    %ebp
f01051a2:	c3                   	ret    

f01051a3 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01051a3:	55                   	push   %ebp
f01051a4:	89 e5                	mov    %esp,%ebp
f01051a6:	8b 45 08             	mov    0x8(%ebp),%eax
f01051a9:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f01051ac:	89 c2                	mov    %eax,%edx
f01051ae:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01051b1:	eb 07                	jmp    f01051ba <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f01051b3:	38 08                	cmp    %cl,(%eax)
f01051b5:	74 07                	je     f01051be <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01051b7:	83 c0 01             	add    $0x1,%eax
f01051ba:	39 d0                	cmp    %edx,%eax
f01051bc:	72 f5                	jb     f01051b3 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01051be:	5d                   	pop    %ebp
f01051bf:	c3                   	ret    

f01051c0 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01051c0:	55                   	push   %ebp
f01051c1:	89 e5                	mov    %esp,%ebp
f01051c3:	57                   	push   %edi
f01051c4:	56                   	push   %esi
f01051c5:	53                   	push   %ebx
f01051c6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01051c9:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01051cc:	eb 03                	jmp    f01051d1 <strtol+0x11>
		s++;
f01051ce:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01051d1:	0f b6 01             	movzbl (%ecx),%eax
f01051d4:	3c 09                	cmp    $0x9,%al
f01051d6:	74 f6                	je     f01051ce <strtol+0xe>
f01051d8:	3c 20                	cmp    $0x20,%al
f01051da:	74 f2                	je     f01051ce <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f01051dc:	3c 2b                	cmp    $0x2b,%al
f01051de:	75 0a                	jne    f01051ea <strtol+0x2a>
		s++;
f01051e0:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01051e3:	bf 00 00 00 00       	mov    $0x0,%edi
f01051e8:	eb 10                	jmp    f01051fa <strtol+0x3a>
f01051ea:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01051ef:	3c 2d                	cmp    $0x2d,%al
f01051f1:	75 07                	jne    f01051fa <strtol+0x3a>
		s++, neg = 1;
f01051f3:	8d 49 01             	lea    0x1(%ecx),%ecx
f01051f6:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01051fa:	85 db                	test   %ebx,%ebx
f01051fc:	0f 94 c0             	sete   %al
f01051ff:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105205:	75 19                	jne    f0105220 <strtol+0x60>
f0105207:	80 39 30             	cmpb   $0x30,(%ecx)
f010520a:	75 14                	jne    f0105220 <strtol+0x60>
f010520c:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105210:	0f 85 82 00 00 00    	jne    f0105298 <strtol+0xd8>
		s += 2, base = 16;
f0105216:	83 c1 02             	add    $0x2,%ecx
f0105219:	bb 10 00 00 00       	mov    $0x10,%ebx
f010521e:	eb 16                	jmp    f0105236 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f0105220:	84 c0                	test   %al,%al
f0105222:	74 12                	je     f0105236 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0105224:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105229:	80 39 30             	cmpb   $0x30,(%ecx)
f010522c:	75 08                	jne    f0105236 <strtol+0x76>
		s++, base = 8;
f010522e:	83 c1 01             	add    $0x1,%ecx
f0105231:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f0105236:	b8 00 00 00 00       	mov    $0x0,%eax
f010523b:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f010523e:	0f b6 11             	movzbl (%ecx),%edx
f0105241:	8d 72 d0             	lea    -0x30(%edx),%esi
f0105244:	89 f3                	mov    %esi,%ebx
f0105246:	80 fb 09             	cmp    $0x9,%bl
f0105249:	77 08                	ja     f0105253 <strtol+0x93>
			dig = *s - '0';
f010524b:	0f be d2             	movsbl %dl,%edx
f010524e:	83 ea 30             	sub    $0x30,%edx
f0105251:	eb 22                	jmp    f0105275 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f0105253:	8d 72 9f             	lea    -0x61(%edx),%esi
f0105256:	89 f3                	mov    %esi,%ebx
f0105258:	80 fb 19             	cmp    $0x19,%bl
f010525b:	77 08                	ja     f0105265 <strtol+0xa5>
			dig = *s - 'a' + 10;
f010525d:	0f be d2             	movsbl %dl,%edx
f0105260:	83 ea 57             	sub    $0x57,%edx
f0105263:	eb 10                	jmp    f0105275 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f0105265:	8d 72 bf             	lea    -0x41(%edx),%esi
f0105268:	89 f3                	mov    %esi,%ebx
f010526a:	80 fb 19             	cmp    $0x19,%bl
f010526d:	77 16                	ja     f0105285 <strtol+0xc5>
			dig = *s - 'A' + 10;
f010526f:	0f be d2             	movsbl %dl,%edx
f0105272:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f0105275:	3b 55 10             	cmp    0x10(%ebp),%edx
f0105278:	7d 0f                	jge    f0105289 <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f010527a:	83 c1 01             	add    $0x1,%ecx
f010527d:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105281:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105283:	eb b9                	jmp    f010523e <strtol+0x7e>
f0105285:	89 c2                	mov    %eax,%edx
f0105287:	eb 02                	jmp    f010528b <strtol+0xcb>
f0105289:	89 c2                	mov    %eax,%edx

	if (endptr)
f010528b:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010528f:	74 0d                	je     f010529e <strtol+0xde>
		*endptr = (char *) s;
f0105291:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105294:	89 0e                	mov    %ecx,(%esi)
f0105296:	eb 06                	jmp    f010529e <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105298:	84 c0                	test   %al,%al
f010529a:	75 92                	jne    f010522e <strtol+0x6e>
f010529c:	eb 98                	jmp    f0105236 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010529e:	f7 da                	neg    %edx
f01052a0:	85 ff                	test   %edi,%edi
f01052a2:	0f 45 c2             	cmovne %edx,%eax
}
f01052a5:	5b                   	pop    %ebx
f01052a6:	5e                   	pop    %esi
f01052a7:	5f                   	pop    %edi
f01052a8:	5d                   	pop    %ebp
f01052a9:	c3                   	ret    
f01052aa:	66 90                	xchg   %ax,%ax

f01052ac <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f01052ac:	fa                   	cli    

	xorw    %ax, %ax
f01052ad:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f01052af:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01052b1:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01052b3:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f01052b5:	0f 01 16             	lgdtl  (%esi)
f01052b8:	74 70                	je     f010532a <mpsearch1+0x3>
	movl    %cr0, %eax
f01052ba:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f01052bd:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f01052c1:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f01052c4:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f01052ca:	08 00                	or     %al,(%eax)

f01052cc <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f01052cc:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f01052d0:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f01052d2:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f01052d4:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f01052d6:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f01052da:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f01052dc:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f01052de:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f01052e3:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f01052e6:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f01052e9:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f01052ee:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f01052f1:	8b 25 c4 be 22 f0    	mov    0xf022bec4,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f01052f7:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f01052fc:	b8 b4 01 10 f0       	mov    $0xf01001b4,%eax
	call    *%eax
f0105301:	ff d0                	call   *%eax

f0105303 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105303:	eb fe                	jmp    f0105303 <spin>
f0105305:	8d 76 00             	lea    0x0(%esi),%esi

f0105308 <gdt>:
	...
f0105310:	ff                   	(bad)  
f0105311:	ff 00                	incl   (%eax)
f0105313:	00 00                	add    %al,(%eax)
f0105315:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f010531c:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f0105320 <gdtdesc>:
f0105320:	17                   	pop    %ss
f0105321:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f0105326 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f0105326:	90                   	nop

f0105327 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f0105327:	55                   	push   %ebp
f0105328:	89 e5                	mov    %esp,%ebp
f010532a:	57                   	push   %edi
f010532b:	56                   	push   %esi
f010532c:	53                   	push   %ebx
f010532d:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105330:	8b 0d c8 be 22 f0    	mov    0xf022bec8,%ecx
f0105336:	89 c3                	mov    %eax,%ebx
f0105338:	c1 eb 0c             	shr    $0xc,%ebx
f010533b:	39 cb                	cmp    %ecx,%ebx
f010533d:	72 12                	jb     f0105351 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010533f:	50                   	push   %eax
f0105340:	68 a4 5d 10 f0       	push   $0xf0105da4
f0105345:	6a 57                	push   $0x57
f0105347:	68 45 7a 10 f0       	push   $0xf0107a45
f010534c:	e8 ef ac ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105351:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f0105357:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105359:	89 c2                	mov    %eax,%edx
f010535b:	c1 ea 0c             	shr    $0xc,%edx
f010535e:	39 d1                	cmp    %edx,%ecx
f0105360:	77 12                	ja     f0105374 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105362:	50                   	push   %eax
f0105363:	68 a4 5d 10 f0       	push   $0xf0105da4
f0105368:	6a 57                	push   $0x57
f010536a:	68 45 7a 10 f0       	push   $0xf0107a45
f010536f:	e8 cc ac ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105374:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f010537a:	eb 2f                	jmp    f01053ab <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f010537c:	83 ec 04             	sub    $0x4,%esp
f010537f:	6a 04                	push   $0x4
f0105381:	68 55 7a 10 f0       	push   $0xf0107a55
f0105386:	53                   	push   %ebx
f0105387:	e8 de fd ff ff       	call   f010516a <memcmp>
f010538c:	83 c4 10             	add    $0x10,%esp
f010538f:	85 c0                	test   %eax,%eax
f0105391:	75 15                	jne    f01053a8 <mpsearch1+0x81>
f0105393:	89 da                	mov    %ebx,%edx
f0105395:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105398:	0f b6 0a             	movzbl (%edx),%ecx
f010539b:	01 c8                	add    %ecx,%eax
f010539d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01053a0:	39 fa                	cmp    %edi,%edx
f01053a2:	75 f4                	jne    f0105398 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01053a4:	84 c0                	test   %al,%al
f01053a6:	74 0e                	je     f01053b6 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f01053a8:	83 c3 10             	add    $0x10,%ebx
f01053ab:	39 f3                	cmp    %esi,%ebx
f01053ad:	72 cd                	jb     f010537c <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f01053af:	b8 00 00 00 00       	mov    $0x0,%eax
f01053b4:	eb 02                	jmp    f01053b8 <mpsearch1+0x91>
f01053b6:	89 d8                	mov    %ebx,%eax
}
f01053b8:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01053bb:	5b                   	pop    %ebx
f01053bc:	5e                   	pop    %esi
f01053bd:	5f                   	pop    %edi
f01053be:	5d                   	pop    %ebp
f01053bf:	c3                   	ret    

f01053c0 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f01053c0:	55                   	push   %ebp
f01053c1:	89 e5                	mov    %esp,%ebp
f01053c3:	57                   	push   %edi
f01053c4:	56                   	push   %esi
f01053c5:	53                   	push   %ebx
f01053c6:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f01053c9:	c7 05 e0 c3 22 f0 40 	movl   $0xf022c040,0xf022c3e0
f01053d0:	c0 22 f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01053d3:	83 3d c8 be 22 f0 00 	cmpl   $0x0,0xf022bec8
f01053da:	75 16                	jne    f01053f2 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01053dc:	68 00 04 00 00       	push   $0x400
f01053e1:	68 a4 5d 10 f0       	push   $0xf0105da4
f01053e6:	6a 6f                	push   $0x6f
f01053e8:	68 45 7a 10 f0       	push   $0xf0107a45
f01053ed:	e8 4e ac ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f01053f2:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f01053f9:	85 c0                	test   %eax,%eax
f01053fb:	74 16                	je     f0105413 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
f01053fd:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105400:	ba 00 04 00 00       	mov    $0x400,%edx
f0105405:	e8 1d ff ff ff       	call   f0105327 <mpsearch1>
f010540a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010540d:	85 c0                	test   %eax,%eax
f010540f:	75 3c                	jne    f010544d <mp_init+0x8d>
f0105411:	eb 20                	jmp    f0105433 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105413:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010541a:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f010541d:	2d 00 04 00 00       	sub    $0x400,%eax
f0105422:	ba 00 04 00 00       	mov    $0x400,%edx
f0105427:	e8 fb fe ff ff       	call   f0105327 <mpsearch1>
f010542c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010542f:	85 c0                	test   %eax,%eax
f0105431:	75 1a                	jne    f010544d <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f0105433:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105438:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f010543d:	e8 e5 fe ff ff       	call   f0105327 <mpsearch1>
f0105442:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f0105445:	85 c0                	test   %eax,%eax
f0105447:	0f 84 5a 02 00 00    	je     f01056a7 <mp_init+0x2e7>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f010544d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0105450:	8b 70 04             	mov    0x4(%eax),%esi
f0105453:	85 f6                	test   %esi,%esi
f0105455:	74 06                	je     f010545d <mp_init+0x9d>
f0105457:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f010545b:	74 15                	je     f0105472 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f010545d:	83 ec 0c             	sub    $0xc,%esp
f0105460:	68 b8 78 10 f0       	push   $0xf01078b8
f0105465:	e8 e9 e3 ff ff       	call   f0103853 <cprintf>
f010546a:	83 c4 10             	add    $0x10,%esp
f010546d:	e9 35 02 00 00       	jmp    f01056a7 <mp_init+0x2e7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105472:	89 f0                	mov    %esi,%eax
f0105474:	c1 e8 0c             	shr    $0xc,%eax
f0105477:	3b 05 c8 be 22 f0    	cmp    0xf022bec8,%eax
f010547d:	72 15                	jb     f0105494 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010547f:	56                   	push   %esi
f0105480:	68 a4 5d 10 f0       	push   $0xf0105da4
f0105485:	68 90 00 00 00       	push   $0x90
f010548a:	68 45 7a 10 f0       	push   $0xf0107a45
f010548f:	e8 ac ab ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105494:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010549a:	83 ec 04             	sub    $0x4,%esp
f010549d:	6a 04                	push   $0x4
f010549f:	68 5a 7a 10 f0       	push   $0xf0107a5a
f01054a4:	53                   	push   %ebx
f01054a5:	e8 c0 fc ff ff       	call   f010516a <memcmp>
f01054aa:	83 c4 10             	add    $0x10,%esp
f01054ad:	85 c0                	test   %eax,%eax
f01054af:	74 15                	je     f01054c6 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f01054b1:	83 ec 0c             	sub    $0xc,%esp
f01054b4:	68 e8 78 10 f0       	push   $0xf01078e8
f01054b9:	e8 95 e3 ff ff       	call   f0103853 <cprintf>
f01054be:	83 c4 10             	add    $0x10,%esp
f01054c1:	e9 e1 01 00 00       	jmp    f01056a7 <mp_init+0x2e7>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01054c6:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f01054ca:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f01054ce:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01054d1:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01054d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01054db:	eb 0d                	jmp    f01054ea <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f01054dd:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f01054e4:	f0 
f01054e5:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01054e7:	83 c0 01             	add    $0x1,%eax
f01054ea:	39 c7                	cmp    %eax,%edi
f01054ec:	75 ef                	jne    f01054dd <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f01054ee:	84 d2                	test   %dl,%dl
f01054f0:	74 15                	je     f0105507 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f01054f2:	83 ec 0c             	sub    $0xc,%esp
f01054f5:	68 1c 79 10 f0       	push   $0xf010791c
f01054fa:	e8 54 e3 ff ff       	call   f0103853 <cprintf>
f01054ff:	83 c4 10             	add    $0x10,%esp
f0105502:	e9 a0 01 00 00       	jmp    f01056a7 <mp_init+0x2e7>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105507:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010550b:	3c 04                	cmp    $0x4,%al
f010550d:	74 1d                	je     f010552c <mp_init+0x16c>
f010550f:	3c 01                	cmp    $0x1,%al
f0105511:	74 19                	je     f010552c <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105513:	83 ec 08             	sub    $0x8,%esp
f0105516:	0f b6 c0             	movzbl %al,%eax
f0105519:	50                   	push   %eax
f010551a:	68 40 79 10 f0       	push   $0xf0107940
f010551f:	e8 2f e3 ff ff       	call   f0103853 <cprintf>
f0105524:	83 c4 10             	add    $0x10,%esp
f0105527:	e9 7b 01 00 00       	jmp    f01056a7 <mp_init+0x2e7>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f010552c:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f0105530:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105534:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105539:	b8 00 00 00 00       	mov    $0x0,%eax
f010553e:	01 ce                	add    %ecx,%esi
f0105540:	eb 0d                	jmp    f010554f <mp_init+0x18f>
		sum += ((uint8_t *)addr)[i];
f0105542:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f0105549:	f0 
f010554a:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f010554c:	83 c0 01             	add    $0x1,%eax
f010554f:	39 c7                	cmp    %eax,%edi
f0105551:	75 ef                	jne    f0105542 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f0105553:	89 d0                	mov    %edx,%eax
f0105555:	02 43 2a             	add    0x2a(%ebx),%al
f0105558:	74 15                	je     f010556f <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f010555a:	83 ec 0c             	sub    $0xc,%esp
f010555d:	68 60 79 10 f0       	push   $0xf0107960
f0105562:	e8 ec e2 ff ff       	call   f0103853 <cprintf>
f0105567:	83 c4 10             	add    $0x10,%esp
f010556a:	e9 38 01 00 00       	jmp    f01056a7 <mp_init+0x2e7>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f010556f:	85 db                	test   %ebx,%ebx
f0105571:	0f 84 30 01 00 00    	je     f01056a7 <mp_init+0x2e7>
		return;
	ismp = 1;
f0105577:	c7 05 00 c0 22 f0 01 	movl   $0x1,0xf022c000
f010557e:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105581:	8b 43 24             	mov    0x24(%ebx),%eax
f0105584:	a3 00 d0 26 f0       	mov    %eax,0xf026d000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105589:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f010558c:	be 00 00 00 00       	mov    $0x0,%esi
f0105591:	e9 85 00 00 00       	jmp    f010561b <mp_init+0x25b>
		switch (*p) {
f0105596:	0f b6 07             	movzbl (%edi),%eax
f0105599:	84 c0                	test   %al,%al
f010559b:	74 06                	je     f01055a3 <mp_init+0x1e3>
f010559d:	3c 04                	cmp    $0x4,%al
f010559f:	77 55                	ja     f01055f6 <mp_init+0x236>
f01055a1:	eb 4e                	jmp    f01055f1 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f01055a3:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f01055a7:	74 11                	je     f01055ba <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f01055a9:	6b 05 e4 c3 22 f0 74 	imul   $0x74,0xf022c3e4,%eax
f01055b0:	05 40 c0 22 f0       	add    $0xf022c040,%eax
f01055b5:	a3 e0 c3 22 f0       	mov    %eax,0xf022c3e0
			if (ncpu < NCPU) {
f01055ba:	a1 e4 c3 22 f0       	mov    0xf022c3e4,%eax
f01055bf:	83 f8 07             	cmp    $0x7,%eax
f01055c2:	7f 13                	jg     f01055d7 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f01055c4:	6b d0 74             	imul   $0x74,%eax,%edx
f01055c7:	88 82 40 c0 22 f0    	mov    %al,-0xfdd3fc0(%edx)
				ncpu++;
f01055cd:	83 c0 01             	add    $0x1,%eax
f01055d0:	a3 e4 c3 22 f0       	mov    %eax,0xf022c3e4
f01055d5:	eb 15                	jmp    f01055ec <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f01055d7:	83 ec 08             	sub    $0x8,%esp
f01055da:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f01055de:	50                   	push   %eax
f01055df:	68 90 79 10 f0       	push   $0xf0107990
f01055e4:	e8 6a e2 ff ff       	call   f0103853 <cprintf>
f01055e9:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f01055ec:	83 c7 14             	add    $0x14,%edi
			continue;
f01055ef:	eb 27                	jmp    f0105618 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f01055f1:	83 c7 08             	add    $0x8,%edi
			continue;
f01055f4:	eb 22                	jmp    f0105618 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f01055f6:	83 ec 08             	sub    $0x8,%esp
f01055f9:	0f b6 c0             	movzbl %al,%eax
f01055fc:	50                   	push   %eax
f01055fd:	68 b8 79 10 f0       	push   $0xf01079b8
f0105602:	e8 4c e2 ff ff       	call   f0103853 <cprintf>
			ismp = 0;
f0105607:	c7 05 00 c0 22 f0 00 	movl   $0x0,0xf022c000
f010560e:	00 00 00 
			i = conf->entry;
f0105611:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105615:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105618:	83 c6 01             	add    $0x1,%esi
f010561b:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010561f:	39 c6                	cmp    %eax,%esi
f0105621:	0f 82 6f ff ff ff    	jb     f0105596 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f0105627:	a1 e0 c3 22 f0       	mov    0xf022c3e0,%eax
f010562c:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f0105633:	83 3d 00 c0 22 f0 00 	cmpl   $0x0,0xf022c000
f010563a:	75 26                	jne    f0105662 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f010563c:	c7 05 e4 c3 22 f0 01 	movl   $0x1,0xf022c3e4
f0105643:	00 00 00 
		lapicaddr = 0;
f0105646:	c7 05 00 d0 26 f0 00 	movl   $0x0,0xf026d000
f010564d:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f0105650:	83 ec 0c             	sub    $0xc,%esp
f0105653:	68 d8 79 10 f0       	push   $0xf01079d8
f0105658:	e8 f6 e1 ff ff       	call   f0103853 <cprintf>
		return;
f010565d:	83 c4 10             	add    $0x10,%esp
f0105660:	eb 45                	jmp    f01056a7 <mp_init+0x2e7>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f0105662:	83 ec 04             	sub    $0x4,%esp
f0105665:	ff 35 e4 c3 22 f0    	pushl  0xf022c3e4
f010566b:	0f b6 00             	movzbl (%eax),%eax
f010566e:	50                   	push   %eax
f010566f:	68 5f 7a 10 f0       	push   $0xf0107a5f
f0105674:	e8 da e1 ff ff       	call   f0103853 <cprintf>

	if (mp->imcrp) {
f0105679:	83 c4 10             	add    $0x10,%esp
f010567c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010567f:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105683:	74 22                	je     f01056a7 <mp_init+0x2e7>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105685:	83 ec 0c             	sub    $0xc,%esp
f0105688:	68 04 7a 10 f0       	push   $0xf0107a04
f010568d:	e8 c1 e1 ff ff       	call   f0103853 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105692:	ba 22 00 00 00       	mov    $0x22,%edx
f0105697:	b8 70 00 00 00       	mov    $0x70,%eax
f010569c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010569d:	b2 23                	mov    $0x23,%dl
f010569f:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f01056a0:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01056a3:	ee                   	out    %al,(%dx)
f01056a4:	83 c4 10             	add    $0x10,%esp
	}
}
f01056a7:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01056aa:	5b                   	pop    %ebx
f01056ab:	5e                   	pop    %esi
f01056ac:	5f                   	pop    %edi
f01056ad:	5d                   	pop    %ebp
f01056ae:	c3                   	ret    

f01056af <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f01056af:	55                   	push   %ebp
f01056b0:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f01056b2:	8b 0d 04 d0 26 f0    	mov    0xf026d004,%ecx
f01056b8:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f01056bb:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f01056bd:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f01056c2:	8b 40 20             	mov    0x20(%eax),%eax
}
f01056c5:	5d                   	pop    %ebp
f01056c6:	c3                   	ret    

f01056c7 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f01056c7:	55                   	push   %ebp
f01056c8:	89 e5                	mov    %esp,%ebp
	if (lapic)
f01056ca:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f01056cf:	85 c0                	test   %eax,%eax
f01056d1:	74 08                	je     f01056db <cpunum+0x14>
		return lapic[ID] >> 24;
f01056d3:	8b 40 20             	mov    0x20(%eax),%eax
f01056d6:	c1 e8 18             	shr    $0x18,%eax
f01056d9:	eb 05                	jmp    f01056e0 <cpunum+0x19>
	return 0;
f01056db:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01056e0:	5d                   	pop    %ebp
f01056e1:	c3                   	ret    

f01056e2 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f01056e2:	a1 00 d0 26 f0       	mov    0xf026d000,%eax
f01056e7:	85 c0                	test   %eax,%eax
f01056e9:	0f 84 21 01 00 00    	je     f0105810 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f01056ef:	55                   	push   %ebp
f01056f0:	89 e5                	mov    %esp,%ebp
f01056f2:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f01056f5:	68 00 10 00 00       	push   $0x1000
f01056fa:	50                   	push   %eax
f01056fb:	e8 81 bc ff ff       	call   f0101381 <mmio_map_region>
f0105700:	a3 04 d0 26 f0       	mov    %eax,0xf026d004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105705:	ba 27 01 00 00       	mov    $0x127,%edx
f010570a:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010570f:	e8 9b ff ff ff       	call   f01056af <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105714:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105719:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010571e:	e8 8c ff ff ff       	call   f01056af <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f0105723:	ba 20 00 02 00       	mov    $0x20020,%edx
f0105728:	b8 c8 00 00 00       	mov    $0xc8,%eax
f010572d:	e8 7d ff ff ff       	call   f01056af <lapicw>
	lapicw(TICR, 10000000); 
f0105732:	ba 80 96 98 00       	mov    $0x989680,%edx
f0105737:	b8 e0 00 00 00       	mov    $0xe0,%eax
f010573c:	e8 6e ff ff ff       	call   f01056af <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f0105741:	e8 81 ff ff ff       	call   f01056c7 <cpunum>
f0105746:	6b c0 74             	imul   $0x74,%eax,%eax
f0105749:	05 40 c0 22 f0       	add    $0xf022c040,%eax
f010574e:	83 c4 10             	add    $0x10,%esp
f0105751:	39 05 e0 c3 22 f0    	cmp    %eax,0xf022c3e0
f0105757:	74 0f                	je     f0105768 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f0105759:	ba 00 00 01 00       	mov    $0x10000,%edx
f010575e:	b8 d4 00 00 00       	mov    $0xd4,%eax
f0105763:	e8 47 ff ff ff       	call   f01056af <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f0105768:	ba 00 00 01 00       	mov    $0x10000,%edx
f010576d:	b8 d8 00 00 00       	mov    $0xd8,%eax
f0105772:	e8 38 ff ff ff       	call   f01056af <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f0105777:	a1 04 d0 26 f0       	mov    0xf026d004,%eax
f010577c:	8b 40 30             	mov    0x30(%eax),%eax
f010577f:	c1 e8 10             	shr    $0x10,%eax
f0105782:	3c 03                	cmp    $0x3,%al
f0105784:	76 0f                	jbe    f0105795 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105786:	ba 00 00 01 00       	mov    $0x10000,%edx
f010578b:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105790:	e8 1a ff ff ff       	call   f01056af <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105795:	ba 33 00 00 00       	mov    $0x33,%edx
f010579a:	b8 dc 00 00 00       	mov    $0xdc,%eax
f010579f:	e8 0b ff ff ff       	call   f01056af <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f01057a4:	ba 00 00 00 00       	mov    $0x0,%edx
f01057a9:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01057ae:	e8 fc fe ff ff       	call   f01056af <lapicw>
	lapicw(ESR, 0);
f01057b3:	ba 00 00 00 00       	mov    $0x0,%edx
f01057b8:	b8 a0 00 00 00       	mov    $0xa0,%eax
f01057bd:	e8 ed fe ff ff       	call   f01056af <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f01057c2:	ba 00 00 00 00       	mov    $0x0,%edx
f01057c7:	b8 2c 00 00 00       	mov    $0x2c,%eax
f01057cc:	e8 de fe ff ff       	call   f01056af <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f01057d1:	ba 00 00 00 00       	mov    $0x0,%edx
f01057d6:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01057db:	e8 cf fe ff ff       	call   f01056af <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f01057e0:	ba 00 85 08 00       	mov    $0x88500,%edx
f01057e5:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01057ea:	e8 c0 fe ff ff       	call   f01056af <lapicw>
	while(lapic[ICRLO] & DELIVS)
f01057ef:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f01057f5:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f01057fb:	f6 c4 10             	test   $0x10,%ah
f01057fe:	75 f5                	jne    f01057f5 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105800:	ba 00 00 00 00       	mov    $0x0,%edx
f0105805:	b8 20 00 00 00       	mov    $0x20,%eax
f010580a:	e8 a0 fe ff ff       	call   f01056af <lapicw>
}
f010580f:	c9                   	leave  
f0105810:	f3 c3                	repz ret 

f0105812 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105812:	83 3d 04 d0 26 f0 00 	cmpl   $0x0,0xf026d004
f0105819:	74 13                	je     f010582e <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f010581b:	55                   	push   %ebp
f010581c:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f010581e:	ba 00 00 00 00       	mov    $0x0,%edx
f0105823:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105828:	e8 82 fe ff ff       	call   f01056af <lapicw>
}
f010582d:	5d                   	pop    %ebp
f010582e:	f3 c3                	repz ret 

f0105830 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105830:	55                   	push   %ebp
f0105831:	89 e5                	mov    %esp,%ebp
f0105833:	56                   	push   %esi
f0105834:	53                   	push   %ebx
f0105835:	8b 75 08             	mov    0x8(%ebp),%esi
f0105838:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f010583b:	ba 70 00 00 00       	mov    $0x70,%edx
f0105840:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105845:	ee                   	out    %al,(%dx)
f0105846:	b2 71                	mov    $0x71,%dl
f0105848:	b8 0a 00 00 00       	mov    $0xa,%eax
f010584d:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010584e:	83 3d c8 be 22 f0 00 	cmpl   $0x0,0xf022bec8
f0105855:	75 19                	jne    f0105870 <lapic_startap+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105857:	68 67 04 00 00       	push   $0x467
f010585c:	68 a4 5d 10 f0       	push   $0xf0105da4
f0105861:	68 98 00 00 00       	push   $0x98
f0105866:	68 7c 7a 10 f0       	push   $0xf0107a7c
f010586b:	e8 d0 a7 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105870:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105877:	00 00 
	wrv[1] = addr >> 4;
f0105879:	89 d8                	mov    %ebx,%eax
f010587b:	c1 e8 04             	shr    $0x4,%eax
f010587e:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105884:	c1 e6 18             	shl    $0x18,%esi
f0105887:	89 f2                	mov    %esi,%edx
f0105889:	b8 c4 00 00 00       	mov    $0xc4,%eax
f010588e:	e8 1c fe ff ff       	call   f01056af <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105893:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105898:	b8 c0 00 00 00       	mov    $0xc0,%eax
f010589d:	e8 0d fe ff ff       	call   f01056af <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f01058a2:	ba 00 85 00 00       	mov    $0x8500,%edx
f01058a7:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01058ac:	e8 fe fd ff ff       	call   f01056af <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01058b1:	c1 eb 0c             	shr    $0xc,%ebx
f01058b4:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01058b7:	89 f2                	mov    %esi,%edx
f01058b9:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01058be:	e8 ec fd ff ff       	call   f01056af <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01058c3:	89 da                	mov    %ebx,%edx
f01058c5:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01058ca:	e8 e0 fd ff ff       	call   f01056af <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f01058cf:	89 f2                	mov    %esi,%edx
f01058d1:	b8 c4 00 00 00       	mov    $0xc4,%eax
f01058d6:	e8 d4 fd ff ff       	call   f01056af <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f01058db:	89 da                	mov    %ebx,%edx
f01058dd:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01058e2:	e8 c8 fd ff ff       	call   f01056af <lapicw>
		microdelay(200);
	}
}
f01058e7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01058ea:	5b                   	pop    %ebx
f01058eb:	5e                   	pop    %esi
f01058ec:	5d                   	pop    %ebp
f01058ed:	c3                   	ret    

f01058ee <lapic_ipi>:

void
lapic_ipi(int vector)
{
f01058ee:	55                   	push   %ebp
f01058ef:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f01058f1:	8b 55 08             	mov    0x8(%ebp),%edx
f01058f4:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f01058fa:	b8 c0 00 00 00       	mov    $0xc0,%eax
f01058ff:	e8 ab fd ff ff       	call   f01056af <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105904:	8b 15 04 d0 26 f0    	mov    0xf026d004,%edx
f010590a:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105910:	f6 c4 10             	test   $0x10,%ah
f0105913:	75 f5                	jne    f010590a <lapic_ipi+0x1c>
		;
}
f0105915:	5d                   	pop    %ebp
f0105916:	c3                   	ret    

f0105917 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105917:	55                   	push   %ebp
f0105918:	89 e5                	mov    %esp,%ebp
f010591a:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f010591d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105923:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105926:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105929:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105930:	5d                   	pop    %ebp
f0105931:	c3                   	ret    

f0105932 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105932:	55                   	push   %ebp
f0105933:	89 e5                	mov    %esp,%ebp
f0105935:	56                   	push   %esi
f0105936:	53                   	push   %ebx
f0105937:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f010593a:	83 3b 00             	cmpl   $0x0,(%ebx)
f010593d:	74 14                	je     f0105953 <spin_lock+0x21>
f010593f:	8b 73 08             	mov    0x8(%ebx),%esi
f0105942:	e8 80 fd ff ff       	call   f01056c7 <cpunum>
f0105947:	6b c0 74             	imul   $0x74,%eax,%eax
f010594a:	05 40 c0 22 f0       	add    $0xf022c040,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f010594f:	39 c6                	cmp    %eax,%esi
f0105951:	74 07                	je     f010595a <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105953:	ba 01 00 00 00       	mov    $0x1,%edx
f0105958:	eb 20                	jmp    f010597a <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f010595a:	8b 5b 04             	mov    0x4(%ebx),%ebx
f010595d:	e8 65 fd ff ff       	call   f01056c7 <cpunum>
f0105962:	83 ec 0c             	sub    $0xc,%esp
f0105965:	53                   	push   %ebx
f0105966:	50                   	push   %eax
f0105967:	68 8c 7a 10 f0       	push   $0xf0107a8c
f010596c:	6a 41                	push   $0x41
f010596e:	68 f0 7a 10 f0       	push   $0xf0107af0
f0105973:	e8 c8 a6 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105978:	f3 90                	pause  
f010597a:	89 d0                	mov    %edx,%eax
f010597c:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f010597f:	85 c0                	test   %eax,%eax
f0105981:	75 f5                	jne    f0105978 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105983:	e8 3f fd ff ff       	call   f01056c7 <cpunum>
f0105988:	6b c0 74             	imul   $0x74,%eax,%eax
f010598b:	05 40 c0 22 f0       	add    $0xf022c040,%eax
f0105990:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105993:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0105996:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105998:	b8 00 00 00 00       	mov    $0x0,%eax
f010599d:	eb 0b                	jmp    f01059aa <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f010599f:	8b 4a 04             	mov    0x4(%edx),%ecx
f01059a2:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f01059a5:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f01059a7:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f01059aa:	83 f8 09             	cmp    $0x9,%eax
f01059ad:	7f 14                	jg     f01059c3 <spin_lock+0x91>
f01059af:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f01059b5:	77 e8                	ja     f010599f <spin_lock+0x6d>
f01059b7:	eb 0a                	jmp    f01059c3 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f01059b9:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f01059c0:	83 c0 01             	add    $0x1,%eax
f01059c3:	83 f8 09             	cmp    $0x9,%eax
f01059c6:	7e f1                	jle    f01059b9 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f01059c8:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01059cb:	5b                   	pop    %ebx
f01059cc:	5e                   	pop    %esi
f01059cd:	5d                   	pop    %ebp
f01059ce:	c3                   	ret    

f01059cf <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f01059cf:	55                   	push   %ebp
f01059d0:	89 e5                	mov    %esp,%ebp
f01059d2:	57                   	push   %edi
f01059d3:	56                   	push   %esi
f01059d4:	53                   	push   %ebx
f01059d5:	83 ec 4c             	sub    $0x4c,%esp
f01059d8:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f01059db:	83 3e 00             	cmpl   $0x0,(%esi)
f01059de:	74 18                	je     f01059f8 <spin_unlock+0x29>
f01059e0:	8b 5e 08             	mov    0x8(%esi),%ebx
f01059e3:	e8 df fc ff ff       	call   f01056c7 <cpunum>
f01059e8:	6b c0 74             	imul   $0x74,%eax,%eax
f01059eb:	05 40 c0 22 f0       	add    $0xf022c040,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f01059f0:	39 c3                	cmp    %eax,%ebx
f01059f2:	0f 84 a5 00 00 00    	je     f0105a9d <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f01059f8:	83 ec 04             	sub    $0x4,%esp
f01059fb:	6a 28                	push   $0x28
f01059fd:	8d 46 0c             	lea    0xc(%esi),%eax
f0105a00:	50                   	push   %eax
f0105a01:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105a04:	53                   	push   %ebx
f0105a05:	e8 e5 f6 ff ff       	call   f01050ef <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105a0a:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105a0d:	0f b6 38             	movzbl (%eax),%edi
f0105a10:	8b 76 04             	mov    0x4(%esi),%esi
f0105a13:	e8 af fc ff ff       	call   f01056c7 <cpunum>
f0105a18:	57                   	push   %edi
f0105a19:	56                   	push   %esi
f0105a1a:	50                   	push   %eax
f0105a1b:	68 b8 7a 10 f0       	push   $0xf0107ab8
f0105a20:	e8 2e de ff ff       	call   f0103853 <cprintf>
f0105a25:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105a28:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105a2b:	eb 54                	jmp    f0105a81 <spin_unlock+0xb2>
f0105a2d:	83 ec 08             	sub    $0x8,%esp
f0105a30:	57                   	push   %edi
f0105a31:	50                   	push   %eax
f0105a32:	e8 ed eb ff ff       	call   f0104624 <debuginfo_eip>
f0105a37:	83 c4 10             	add    $0x10,%esp
f0105a3a:	85 c0                	test   %eax,%eax
f0105a3c:	78 27                	js     f0105a65 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105a3e:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105a40:	83 ec 04             	sub    $0x4,%esp
f0105a43:	89 c2                	mov    %eax,%edx
f0105a45:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105a48:	52                   	push   %edx
f0105a49:	ff 75 b0             	pushl  -0x50(%ebp)
f0105a4c:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105a4f:	ff 75 ac             	pushl  -0x54(%ebp)
f0105a52:	ff 75 a8             	pushl  -0x58(%ebp)
f0105a55:	50                   	push   %eax
f0105a56:	68 00 7b 10 f0       	push   $0xf0107b00
f0105a5b:	e8 f3 dd ff ff       	call   f0103853 <cprintf>
f0105a60:	83 c4 20             	add    $0x20,%esp
f0105a63:	eb 12                	jmp    f0105a77 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105a65:	83 ec 08             	sub    $0x8,%esp
f0105a68:	ff 36                	pushl  (%esi)
f0105a6a:	68 17 7b 10 f0       	push   $0xf0107b17
f0105a6f:	e8 df dd ff ff       	call   f0103853 <cprintf>
f0105a74:	83 c4 10             	add    $0x10,%esp
f0105a77:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105a7a:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105a7d:	39 c3                	cmp    %eax,%ebx
f0105a7f:	74 08                	je     f0105a89 <spin_unlock+0xba>
f0105a81:	89 de                	mov    %ebx,%esi
f0105a83:	8b 03                	mov    (%ebx),%eax
f0105a85:	85 c0                	test   %eax,%eax
f0105a87:	75 a4                	jne    f0105a2d <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105a89:	83 ec 04             	sub    $0x4,%esp
f0105a8c:	68 1f 7b 10 f0       	push   $0xf0107b1f
f0105a91:	6a 67                	push   $0x67
f0105a93:	68 f0 7a 10 f0       	push   $0xf0107af0
f0105a98:	e8 a3 a5 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105a9d:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105aa4:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0105aab:	b8 00 00 00 00       	mov    $0x0,%eax
f0105ab0:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105ab3:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105ab6:	5b                   	pop    %ebx
f0105ab7:	5e                   	pop    %esi
f0105ab8:	5f                   	pop    %edi
f0105ab9:	5d                   	pop    %ebp
f0105aba:	c3                   	ret    
f0105abb:	66 90                	xchg   %ax,%ax
f0105abd:	66 90                	xchg   %ax,%ax
f0105abf:	90                   	nop

f0105ac0 <__udivdi3>:
f0105ac0:	55                   	push   %ebp
f0105ac1:	57                   	push   %edi
f0105ac2:	56                   	push   %esi
f0105ac3:	83 ec 10             	sub    $0x10,%esp
f0105ac6:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0105aca:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0105ace:	8b 74 24 24          	mov    0x24(%esp),%esi
f0105ad2:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0105ad6:	85 d2                	test   %edx,%edx
f0105ad8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105adc:	89 34 24             	mov    %esi,(%esp)
f0105adf:	89 c8                	mov    %ecx,%eax
f0105ae1:	75 35                	jne    f0105b18 <__udivdi3+0x58>
f0105ae3:	39 f1                	cmp    %esi,%ecx
f0105ae5:	0f 87 bd 00 00 00    	ja     f0105ba8 <__udivdi3+0xe8>
f0105aeb:	85 c9                	test   %ecx,%ecx
f0105aed:	89 cd                	mov    %ecx,%ebp
f0105aef:	75 0b                	jne    f0105afc <__udivdi3+0x3c>
f0105af1:	b8 01 00 00 00       	mov    $0x1,%eax
f0105af6:	31 d2                	xor    %edx,%edx
f0105af8:	f7 f1                	div    %ecx
f0105afa:	89 c5                	mov    %eax,%ebp
f0105afc:	89 f0                	mov    %esi,%eax
f0105afe:	31 d2                	xor    %edx,%edx
f0105b00:	f7 f5                	div    %ebp
f0105b02:	89 c6                	mov    %eax,%esi
f0105b04:	89 f8                	mov    %edi,%eax
f0105b06:	f7 f5                	div    %ebp
f0105b08:	89 f2                	mov    %esi,%edx
f0105b0a:	83 c4 10             	add    $0x10,%esp
f0105b0d:	5e                   	pop    %esi
f0105b0e:	5f                   	pop    %edi
f0105b0f:	5d                   	pop    %ebp
f0105b10:	c3                   	ret    
f0105b11:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105b18:	3b 14 24             	cmp    (%esp),%edx
f0105b1b:	77 7b                	ja     f0105b98 <__udivdi3+0xd8>
f0105b1d:	0f bd f2             	bsr    %edx,%esi
f0105b20:	83 f6 1f             	xor    $0x1f,%esi
f0105b23:	0f 84 97 00 00 00    	je     f0105bc0 <__udivdi3+0x100>
f0105b29:	bd 20 00 00 00       	mov    $0x20,%ebp
f0105b2e:	89 d7                	mov    %edx,%edi
f0105b30:	89 f1                	mov    %esi,%ecx
f0105b32:	29 f5                	sub    %esi,%ebp
f0105b34:	d3 e7                	shl    %cl,%edi
f0105b36:	89 c2                	mov    %eax,%edx
f0105b38:	89 e9                	mov    %ebp,%ecx
f0105b3a:	d3 ea                	shr    %cl,%edx
f0105b3c:	89 f1                	mov    %esi,%ecx
f0105b3e:	09 fa                	or     %edi,%edx
f0105b40:	8b 3c 24             	mov    (%esp),%edi
f0105b43:	d3 e0                	shl    %cl,%eax
f0105b45:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105b49:	89 e9                	mov    %ebp,%ecx
f0105b4b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105b4f:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105b53:	89 fa                	mov    %edi,%edx
f0105b55:	d3 ea                	shr    %cl,%edx
f0105b57:	89 f1                	mov    %esi,%ecx
f0105b59:	d3 e7                	shl    %cl,%edi
f0105b5b:	89 e9                	mov    %ebp,%ecx
f0105b5d:	d3 e8                	shr    %cl,%eax
f0105b5f:	09 c7                	or     %eax,%edi
f0105b61:	89 f8                	mov    %edi,%eax
f0105b63:	f7 74 24 08          	divl   0x8(%esp)
f0105b67:	89 d5                	mov    %edx,%ebp
f0105b69:	89 c7                	mov    %eax,%edi
f0105b6b:	f7 64 24 0c          	mull   0xc(%esp)
f0105b6f:	39 d5                	cmp    %edx,%ebp
f0105b71:	89 14 24             	mov    %edx,(%esp)
f0105b74:	72 11                	jb     f0105b87 <__udivdi3+0xc7>
f0105b76:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105b7a:	89 f1                	mov    %esi,%ecx
f0105b7c:	d3 e2                	shl    %cl,%edx
f0105b7e:	39 c2                	cmp    %eax,%edx
f0105b80:	73 5e                	jae    f0105be0 <__udivdi3+0x120>
f0105b82:	3b 2c 24             	cmp    (%esp),%ebp
f0105b85:	75 59                	jne    f0105be0 <__udivdi3+0x120>
f0105b87:	8d 47 ff             	lea    -0x1(%edi),%eax
f0105b8a:	31 f6                	xor    %esi,%esi
f0105b8c:	89 f2                	mov    %esi,%edx
f0105b8e:	83 c4 10             	add    $0x10,%esp
f0105b91:	5e                   	pop    %esi
f0105b92:	5f                   	pop    %edi
f0105b93:	5d                   	pop    %ebp
f0105b94:	c3                   	ret    
f0105b95:	8d 76 00             	lea    0x0(%esi),%esi
f0105b98:	31 f6                	xor    %esi,%esi
f0105b9a:	31 c0                	xor    %eax,%eax
f0105b9c:	89 f2                	mov    %esi,%edx
f0105b9e:	83 c4 10             	add    $0x10,%esp
f0105ba1:	5e                   	pop    %esi
f0105ba2:	5f                   	pop    %edi
f0105ba3:	5d                   	pop    %ebp
f0105ba4:	c3                   	ret    
f0105ba5:	8d 76 00             	lea    0x0(%esi),%esi
f0105ba8:	89 f2                	mov    %esi,%edx
f0105baa:	31 f6                	xor    %esi,%esi
f0105bac:	89 f8                	mov    %edi,%eax
f0105bae:	f7 f1                	div    %ecx
f0105bb0:	89 f2                	mov    %esi,%edx
f0105bb2:	83 c4 10             	add    $0x10,%esp
f0105bb5:	5e                   	pop    %esi
f0105bb6:	5f                   	pop    %edi
f0105bb7:	5d                   	pop    %ebp
f0105bb8:	c3                   	ret    
f0105bb9:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105bc0:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0105bc4:	76 0b                	jbe    f0105bd1 <__udivdi3+0x111>
f0105bc6:	31 c0                	xor    %eax,%eax
f0105bc8:	3b 14 24             	cmp    (%esp),%edx
f0105bcb:	0f 83 37 ff ff ff    	jae    f0105b08 <__udivdi3+0x48>
f0105bd1:	b8 01 00 00 00       	mov    $0x1,%eax
f0105bd6:	e9 2d ff ff ff       	jmp    f0105b08 <__udivdi3+0x48>
f0105bdb:	90                   	nop
f0105bdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105be0:	89 f8                	mov    %edi,%eax
f0105be2:	31 f6                	xor    %esi,%esi
f0105be4:	e9 1f ff ff ff       	jmp    f0105b08 <__udivdi3+0x48>
f0105be9:	66 90                	xchg   %ax,%ax
f0105beb:	66 90                	xchg   %ax,%ax
f0105bed:	66 90                	xchg   %ax,%ax
f0105bef:	90                   	nop

f0105bf0 <__umoddi3>:
f0105bf0:	55                   	push   %ebp
f0105bf1:	57                   	push   %edi
f0105bf2:	56                   	push   %esi
f0105bf3:	83 ec 20             	sub    $0x20,%esp
f0105bf6:	8b 44 24 34          	mov    0x34(%esp),%eax
f0105bfa:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105bfe:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105c02:	89 c6                	mov    %eax,%esi
f0105c04:	89 44 24 10          	mov    %eax,0x10(%esp)
f0105c08:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105c0c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0105c10:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105c14:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105c18:	89 74 24 18          	mov    %esi,0x18(%esp)
f0105c1c:	85 c0                	test   %eax,%eax
f0105c1e:	89 c2                	mov    %eax,%edx
f0105c20:	75 1e                	jne    f0105c40 <__umoddi3+0x50>
f0105c22:	39 f7                	cmp    %esi,%edi
f0105c24:	76 52                	jbe    f0105c78 <__umoddi3+0x88>
f0105c26:	89 c8                	mov    %ecx,%eax
f0105c28:	89 f2                	mov    %esi,%edx
f0105c2a:	f7 f7                	div    %edi
f0105c2c:	89 d0                	mov    %edx,%eax
f0105c2e:	31 d2                	xor    %edx,%edx
f0105c30:	83 c4 20             	add    $0x20,%esp
f0105c33:	5e                   	pop    %esi
f0105c34:	5f                   	pop    %edi
f0105c35:	5d                   	pop    %ebp
f0105c36:	c3                   	ret    
f0105c37:	89 f6                	mov    %esi,%esi
f0105c39:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105c40:	39 f0                	cmp    %esi,%eax
f0105c42:	77 5c                	ja     f0105ca0 <__umoddi3+0xb0>
f0105c44:	0f bd e8             	bsr    %eax,%ebp
f0105c47:	83 f5 1f             	xor    $0x1f,%ebp
f0105c4a:	75 64                	jne    f0105cb0 <__umoddi3+0xc0>
f0105c4c:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0105c50:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0105c54:	0f 86 f6 00 00 00    	jbe    f0105d50 <__umoddi3+0x160>
f0105c5a:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0105c5e:	0f 82 ec 00 00 00    	jb     f0105d50 <__umoddi3+0x160>
f0105c64:	8b 44 24 14          	mov    0x14(%esp),%eax
f0105c68:	8b 54 24 18          	mov    0x18(%esp),%edx
f0105c6c:	83 c4 20             	add    $0x20,%esp
f0105c6f:	5e                   	pop    %esi
f0105c70:	5f                   	pop    %edi
f0105c71:	5d                   	pop    %ebp
f0105c72:	c3                   	ret    
f0105c73:	90                   	nop
f0105c74:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105c78:	85 ff                	test   %edi,%edi
f0105c7a:	89 fd                	mov    %edi,%ebp
f0105c7c:	75 0b                	jne    f0105c89 <__umoddi3+0x99>
f0105c7e:	b8 01 00 00 00       	mov    $0x1,%eax
f0105c83:	31 d2                	xor    %edx,%edx
f0105c85:	f7 f7                	div    %edi
f0105c87:	89 c5                	mov    %eax,%ebp
f0105c89:	8b 44 24 10          	mov    0x10(%esp),%eax
f0105c8d:	31 d2                	xor    %edx,%edx
f0105c8f:	f7 f5                	div    %ebp
f0105c91:	89 c8                	mov    %ecx,%eax
f0105c93:	f7 f5                	div    %ebp
f0105c95:	eb 95                	jmp    f0105c2c <__umoddi3+0x3c>
f0105c97:	89 f6                	mov    %esi,%esi
f0105c99:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105ca0:	89 c8                	mov    %ecx,%eax
f0105ca2:	89 f2                	mov    %esi,%edx
f0105ca4:	83 c4 20             	add    $0x20,%esp
f0105ca7:	5e                   	pop    %esi
f0105ca8:	5f                   	pop    %edi
f0105ca9:	5d                   	pop    %ebp
f0105caa:	c3                   	ret    
f0105cab:	90                   	nop
f0105cac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105cb0:	b8 20 00 00 00       	mov    $0x20,%eax
f0105cb5:	89 e9                	mov    %ebp,%ecx
f0105cb7:	29 e8                	sub    %ebp,%eax
f0105cb9:	d3 e2                	shl    %cl,%edx
f0105cbb:	89 c7                	mov    %eax,%edi
f0105cbd:	89 44 24 18          	mov    %eax,0x18(%esp)
f0105cc1:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105cc5:	89 f9                	mov    %edi,%ecx
f0105cc7:	d3 e8                	shr    %cl,%eax
f0105cc9:	89 c1                	mov    %eax,%ecx
f0105ccb:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105ccf:	09 d1                	or     %edx,%ecx
f0105cd1:	89 fa                	mov    %edi,%edx
f0105cd3:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105cd7:	89 e9                	mov    %ebp,%ecx
f0105cd9:	d3 e0                	shl    %cl,%eax
f0105cdb:	89 f9                	mov    %edi,%ecx
f0105cdd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105ce1:	89 f0                	mov    %esi,%eax
f0105ce3:	d3 e8                	shr    %cl,%eax
f0105ce5:	89 e9                	mov    %ebp,%ecx
f0105ce7:	89 c7                	mov    %eax,%edi
f0105ce9:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0105ced:	d3 e6                	shl    %cl,%esi
f0105cef:	89 d1                	mov    %edx,%ecx
f0105cf1:	89 fa                	mov    %edi,%edx
f0105cf3:	d3 e8                	shr    %cl,%eax
f0105cf5:	89 e9                	mov    %ebp,%ecx
f0105cf7:	09 f0                	or     %esi,%eax
f0105cf9:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f0105cfd:	f7 74 24 10          	divl   0x10(%esp)
f0105d01:	d3 e6                	shl    %cl,%esi
f0105d03:	89 d1                	mov    %edx,%ecx
f0105d05:	f7 64 24 0c          	mull   0xc(%esp)
f0105d09:	39 d1                	cmp    %edx,%ecx
f0105d0b:	89 74 24 14          	mov    %esi,0x14(%esp)
f0105d0f:	89 d7                	mov    %edx,%edi
f0105d11:	89 c6                	mov    %eax,%esi
f0105d13:	72 0a                	jb     f0105d1f <__umoddi3+0x12f>
f0105d15:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0105d19:	73 10                	jae    f0105d2b <__umoddi3+0x13b>
f0105d1b:	39 d1                	cmp    %edx,%ecx
f0105d1d:	75 0c                	jne    f0105d2b <__umoddi3+0x13b>
f0105d1f:	89 d7                	mov    %edx,%edi
f0105d21:	89 c6                	mov    %eax,%esi
f0105d23:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0105d27:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f0105d2b:	89 ca                	mov    %ecx,%edx
f0105d2d:	89 e9                	mov    %ebp,%ecx
f0105d2f:	8b 44 24 14          	mov    0x14(%esp),%eax
f0105d33:	29 f0                	sub    %esi,%eax
f0105d35:	19 fa                	sbb    %edi,%edx
f0105d37:	d3 e8                	shr    %cl,%eax
f0105d39:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f0105d3e:	89 d7                	mov    %edx,%edi
f0105d40:	d3 e7                	shl    %cl,%edi
f0105d42:	89 e9                	mov    %ebp,%ecx
f0105d44:	09 f8                	or     %edi,%eax
f0105d46:	d3 ea                	shr    %cl,%edx
f0105d48:	83 c4 20             	add    $0x20,%esp
f0105d4b:	5e                   	pop    %esi
f0105d4c:	5f                   	pop    %edi
f0105d4d:	5d                   	pop    %ebp
f0105d4e:	c3                   	ret    
f0105d4f:	90                   	nop
f0105d50:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105d54:	29 f9                	sub    %edi,%ecx
f0105d56:	19 c6                	sbb    %eax,%esi
f0105d58:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105d5c:	89 74 24 18          	mov    %esi,0x18(%esp)
f0105d60:	e9 ff fe ff ff       	jmp    f0105c64 <__umoddi3+0x74>
