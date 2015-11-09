
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
f0100048:	83 3d c0 de 1d f0 00 	cmpl   $0x0,0xf01ddec0
f010004f:	75 3a                	jne    f010008b <_panic+0x4b>
		goto dead;
	panicstr = fmt;
f0100051:	89 35 c0 de 1d f0    	mov    %esi,0xf01ddec0

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100057:	fa                   	cli    
f0100058:	fc                   	cld    

	va_start(ap, fmt);
f0100059:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic on CPU %d at %s:%d: ", cpunum(), file, line);
f010005c:	e8 e6 58 00 00       	call   f0105947 <cpunum>
f0100061:	ff 75 0c             	pushl  0xc(%ebp)
f0100064:	ff 75 08             	pushl  0x8(%ebp)
f0100067:	50                   	push   %eax
f0100068:	68 00 60 10 f0       	push   $0xf0106000
f010006d:	e8 9d 37 00 00       	call   f010380f <cprintf>
	vcprintf(fmt, ap);
f0100072:	83 c4 08             	add    $0x8,%esp
f0100075:	53                   	push   %ebx
f0100076:	56                   	push   %esi
f0100077:	e8 6d 37 00 00       	call   f01037e9 <vcprintf>
	cprintf("\n");
f010007c:	c7 04 24 1f 78 10 f0 	movl   $0xf010781f,(%esp)
f0100083:	e8 87 37 00 00       	call   f010380f <cprintf>
	va_end(ap);
f0100088:	83 c4 10             	add    $0x10,%esp

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f010008b:	83 ec 0c             	sub    $0xc,%esp
f010008e:	6a 00                	push   $0x0
f0100090:	e8 6f 08 00 00       	call   f0100904 <monitor>
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
f01000a1:	b8 08 f0 21 f0       	mov    $0xf021f008,%eax
f01000a6:	2d f0 ce 1d f0       	sub    $0xf01dcef0,%eax
f01000ab:	50                   	push   %eax
f01000ac:	6a 00                	push   $0x0
f01000ae:	68 f0 ce 1d f0       	push   $0xf01dcef0
f01000b3:	e8 6b 52 00 00       	call   f0105323 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000b8:	e8 77 05 00 00       	call   f0100634 <cons_init>

	cprintf("6828 decimal is %o octal!\n", 6828);
f01000bd:	83 c4 08             	add    $0x8,%esp
f01000c0:	68 ac 1a 00 00       	push   $0x1aac
f01000c5:	68 6c 60 10 f0       	push   $0xf010606c
f01000ca:	e8 40 37 00 00       	call   f010380f <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f01000cf:	e8 12 13 00 00       	call   f01013e6 <mem_init>

	// Lab 3 user environment initialization functions
	env_init();
f01000d4:	e8 e1 2f 00 00       	call   f01030ba <env_init>
	trap_init();
f01000d9:	e8 da 37 00 00       	call   f01038b8 <trap_init>

	// Lab 4 multiprocessor initialization functions
	mp_init();
f01000de:	e8 5d 55 00 00       	call   f0105640 <mp_init>
	lapic_init();
f01000e3:	e8 7a 58 00 00       	call   f0105962 <lapic_init>

	// Lab 4 multitasking initialization functions
	pic_init();
f01000e8:	e8 5e 36 00 00       	call   f010374b <pic_init>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f01000ed:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f01000f4:	e8 b9 5a 00 00       	call   f0105bb2 <spin_lock>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01000f9:	83 c4 10             	add    $0x10,%esp
f01000fc:	83 3d c8 de 1d f0 07 	cmpl   $0x7,0xf01ddec8
f0100103:	77 16                	ja     f010011b <i386_init+0x81>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100105:	68 00 70 00 00       	push   $0x7000
f010010a:	68 24 60 10 f0       	push   $0xf0106024
f010010f:	6a 63                	push   $0x63
f0100111:	68 87 60 10 f0       	push   $0xf0106087
f0100116:	e8 25 ff ff ff       	call   f0100040 <_panic>
	void *code;
	struct CpuInfo *c;

	// Write entry code to unused memory at MPENTRY_PADDR
	code = KADDR(MPENTRY_PADDR);
	memmove(code, mpentry_start, mpentry_end - mpentry_start);
f010011b:	83 ec 04             	sub    $0x4,%esp
f010011e:	b8 a6 55 10 f0       	mov    $0xf01055a6,%eax
f0100123:	2d 2c 55 10 f0       	sub    $0xf010552c,%eax
f0100128:	50                   	push   %eax
f0100129:	68 2c 55 10 f0       	push   $0xf010552c
f010012e:	68 00 70 00 f0       	push   $0xf0007000
f0100133:	e8 38 52 00 00       	call   f0105370 <memmove>
f0100138:	83 c4 10             	add    $0x10,%esp

	// Boot each AP one at a time
	for (c = cpus; c < cpus + ncpu; c++) {
f010013b:	bb 40 e0 1d f0       	mov    $0xf01de040,%ebx
f0100140:	eb 4e                	jmp    f0100190 <i386_init+0xf6>
		if (c == cpus + cpunum())  // We've started already.
f0100142:	e8 00 58 00 00       	call   f0105947 <cpunum>
f0100147:	6b c0 74             	imul   $0x74,%eax,%eax
f010014a:	05 40 e0 1d f0       	add    $0xf01de040,%eax
f010014f:	39 c3                	cmp    %eax,%ebx
f0100151:	74 3a                	je     f010018d <i386_init+0xf3>
f0100153:	89 d8                	mov    %ebx,%eax
f0100155:	2d 40 e0 1d f0       	sub    $0xf01de040,%eax
			continue;

		// Tell mpentry.S what stack to use 
		mpentry_kstack = percpu_kstacks[c - cpus] + KSTKSIZE;
f010015a:	c1 f8 02             	sar    $0x2,%eax
f010015d:	69 c0 35 c2 72 4f    	imul   $0x4f72c235,%eax,%eax
f0100163:	c1 e0 0f             	shl    $0xf,%eax
f0100166:	8d 80 00 70 1e f0    	lea    -0xfe19000(%eax),%eax
f010016c:	a3 c4 de 1d f0       	mov    %eax,0xf01ddec4
		// Start the CPU at mpentry_start
		lapic_startap(c->cpu_id, PADDR(code));
f0100171:	83 ec 08             	sub    $0x8,%esp
f0100174:	68 00 70 00 00       	push   $0x7000
f0100179:	0f b6 03             	movzbl (%ebx),%eax
f010017c:	50                   	push   %eax
f010017d:	e8 2e 59 00 00       	call   f0105ab0 <lapic_startap>
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
f0100190:	6b 05 e4 e3 1d f0 74 	imul   $0x74,0xf01de3e4,%eax
f0100197:	05 40 e0 1d f0       	add    $0xf01de040,%eax
f010019c:	39 c3                	cmp    %eax,%ebx
f010019e:	72 a2                	jb     f0100142 <i386_init+0xa8>
	// Start fs.
	//ENV_CREATE(fs_fs, ENV_TYPE_FS);

#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
f01001a0:	83 ec 08             	sub    $0x8,%esp
f01001a3:	6a 00                	push   $0x0
f01001a5:	68 98 b6 18 f0       	push   $0xf018b698
f01001aa:	e8 a9 30 00 00       	call   f0103258 <env_create>
	//ENV_CREATE(user_yield, ENV_TYPE_USER);

#endif // TEST*

	// Should not be necessary - drains keyboard because interrupt has given up.
	kbd_intr();
f01001af:	e8 24 04 00 00       	call   f01005d8 <kbd_intr>

	// Schedule and run the first user environment!
	sched_yield();
f01001b4:	e8 e7 3f 00 00       	call   f01041a0 <sched_yield>

f01001b9 <mp_main>:
}

// Setup code for APs
void
mp_main(void)
{
f01001b9:	55                   	push   %ebp
f01001ba:	89 e5                	mov    %esp,%ebp
f01001bc:	83 ec 08             	sub    $0x8,%esp
	// We are in high EIP now, safe to switch to kern_pgdir 
	lcr3(PADDR(kern_pgdir));
f01001bf:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01001c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01001c9:	77 12                	ja     f01001dd <mp_main+0x24>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01001cb:	50                   	push   %eax
f01001cc:	68 48 60 10 f0       	push   $0xf0106048
f01001d1:	6a 7a                	push   $0x7a
f01001d3:	68 87 60 10 f0       	push   $0xf0106087
f01001d8:	e8 63 fe ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01001dd:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01001e2:	0f 22 d8             	mov    %eax,%cr3
	cprintf("SMP: CPU %d starting\n", cpunum());
f01001e5:	e8 5d 57 00 00       	call   f0105947 <cpunum>
f01001ea:	83 ec 08             	sub    $0x8,%esp
f01001ed:	50                   	push   %eax
f01001ee:	68 93 60 10 f0       	push   $0xf0106093
f01001f3:	e8 17 36 00 00       	call   f010380f <cprintf>

	lapic_init();
f01001f8:	e8 65 57 00 00       	call   f0105962 <lapic_init>
	env_init_percpu();
f01001fd:	e8 8e 2e 00 00       	call   f0103090 <env_init_percpu>
	trap_init_percpu();
f0100202:	e8 1c 36 00 00       	call   f0103823 <trap_init_percpu>
	xchg(&thiscpu->cpu_status, CPU_STARTED); // tell boot_aps() we're up
f0100207:	e8 3b 57 00 00       	call   f0105947 <cpunum>
f010020c:	6b d0 74             	imul   $0x74,%eax,%edx
f010020f:	81 c2 40 e0 1d f0    	add    $0xf01de040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0100215:	b8 01 00 00 00       	mov    $0x1,%eax
f010021a:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f010021e:	c7 04 24 c0 04 12 f0 	movl   $0xf01204c0,(%esp)
f0100225:	e8 88 59 00 00       	call   f0105bb2 <spin_lock>
	// to start running processes on this CPU.  But make sure that
	// only one CPU can enter the scheduler at a time!
	//
	// Your code here:
	lock_kernel();  //Acquire the lock
	sched_yield(); //Call the sched_yield() function to schedule and run different environments, Exercise 6
f010022a:	e8 71 3f 00 00       	call   f01041a0 <sched_yield>

f010022f <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f010022f:	55                   	push   %ebp
f0100230:	89 e5                	mov    %esp,%ebp
f0100232:	53                   	push   %ebx
f0100233:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0100236:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100239:	ff 75 0c             	pushl  0xc(%ebp)
f010023c:	ff 75 08             	pushl  0x8(%ebp)
f010023f:	68 a9 60 10 f0       	push   $0xf01060a9
f0100244:	e8 c6 35 00 00       	call   f010380f <cprintf>
	vcprintf(fmt, ap);
f0100249:	83 c4 08             	add    $0x8,%esp
f010024c:	53                   	push   %ebx
f010024d:	ff 75 10             	pushl  0x10(%ebp)
f0100250:	e8 94 35 00 00       	call   f01037e9 <vcprintf>
	cprintf("\n");
f0100255:	c7 04 24 1f 78 10 f0 	movl   $0xf010781f,(%esp)
f010025c:	e8 ae 35 00 00       	call   f010380f <cprintf>
	va_end(ap);
f0100261:	83 c4 10             	add    $0x10,%esp
}
f0100264:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0100267:	c9                   	leave  
f0100268:	c3                   	ret    

f0100269 <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f0100269:	55                   	push   %ebp
f010026a:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010026c:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100271:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f0100272:	a8 01                	test   $0x1,%al
f0100274:	74 08                	je     f010027e <serial_proc_data+0x15>
f0100276:	b2 f8                	mov    $0xf8,%dl
f0100278:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100279:	0f b6 c0             	movzbl %al,%eax
f010027c:	eb 05                	jmp    f0100283 <serial_proc_data+0x1a>

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f010027e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	return inb(COM1+COM_RX);
}
f0100283:	5d                   	pop    %ebp
f0100284:	c3                   	ret    

f0100285 <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f0100285:	55                   	push   %ebp
f0100286:	89 e5                	mov    %esp,%ebp
f0100288:	53                   	push   %ebx
f0100289:	83 ec 04             	sub    $0x4,%esp
f010028c:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f010028e:	eb 2a                	jmp    f01002ba <cons_intr+0x35>
		if (c == 0)
f0100290:	85 d2                	test   %edx,%edx
f0100292:	74 26                	je     f01002ba <cons_intr+0x35>
			continue;
		cons.buf[cons.wpos++] = c;
f0100294:	a1 44 d2 1d f0       	mov    0xf01dd244,%eax
f0100299:	8d 48 01             	lea    0x1(%eax),%ecx
f010029c:	89 0d 44 d2 1d f0    	mov    %ecx,0xf01dd244
f01002a2:	88 90 40 d0 1d f0    	mov    %dl,-0xfe22fc0(%eax)
		if (cons.wpos == CONSBUFSIZE)
f01002a8:	81 f9 00 02 00 00    	cmp    $0x200,%ecx
f01002ae:	75 0a                	jne    f01002ba <cons_intr+0x35>
			cons.wpos = 0;
f01002b0:	c7 05 44 d2 1d f0 00 	movl   $0x0,0xf01dd244
f01002b7:	00 00 00 
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01002ba:	ff d3                	call   *%ebx
f01002bc:	89 c2                	mov    %eax,%edx
f01002be:	83 f8 ff             	cmp    $0xffffffff,%eax
f01002c1:	75 cd                	jne    f0100290 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01002c3:	83 c4 04             	add    $0x4,%esp
f01002c6:	5b                   	pop    %ebx
f01002c7:	5d                   	pop    %ebp
f01002c8:	c3                   	ret    

f01002c9 <kbd_proc_data>:
f01002c9:	ba 64 00 00 00       	mov    $0x64,%edx
f01002ce:	ec                   	in     (%dx),%al
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01002cf:	a8 01                	test   $0x1,%al
f01002d1:	0f 84 f0 00 00 00    	je     f01003c7 <kbd_proc_data+0xfe>
f01002d7:	b2 60                	mov    $0x60,%dl
f01002d9:	ec                   	in     (%dx),%al
f01002da:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01002dc:	3c e0                	cmp    $0xe0,%al
f01002de:	75 0d                	jne    f01002ed <kbd_proc_data+0x24>
		// E0 escape character
		shift |= E0ESC;
f01002e0:	83 0d 00 d0 1d f0 40 	orl    $0x40,0xf01dd000
		return 0;
f01002e7:	b8 00 00 00 00       	mov    $0x0,%eax
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01002ec:	c3                   	ret    
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01002ed:	55                   	push   %ebp
f01002ee:	89 e5                	mov    %esp,%ebp
f01002f0:	53                   	push   %ebx
f01002f1:	83 ec 04             	sub    $0x4,%esp

	if (data == 0xE0) {
		// E0 escape character
		shift |= E0ESC;
		return 0;
	} else if (data & 0x80) {
f01002f4:	84 c0                	test   %al,%al
f01002f6:	79 36                	jns    f010032e <kbd_proc_data+0x65>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01002f8:	8b 0d 00 d0 1d f0    	mov    0xf01dd000,%ecx
f01002fe:	89 cb                	mov    %ecx,%ebx
f0100300:	83 e3 40             	and    $0x40,%ebx
f0100303:	83 e0 7f             	and    $0x7f,%eax
f0100306:	85 db                	test   %ebx,%ebx
f0100308:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f010030b:	0f b6 d2             	movzbl %dl,%edx
f010030e:	0f b6 82 40 62 10 f0 	movzbl -0xfef9dc0(%edx),%eax
f0100315:	83 c8 40             	or     $0x40,%eax
f0100318:	0f b6 c0             	movzbl %al,%eax
f010031b:	f7 d0                	not    %eax
f010031d:	21 c8                	and    %ecx,%eax
f010031f:	a3 00 d0 1d f0       	mov    %eax,0xf01dd000
		return 0;
f0100324:	b8 00 00 00 00       	mov    $0x0,%eax
f0100329:	e9 a1 00 00 00       	jmp    f01003cf <kbd_proc_data+0x106>
	} else if (shift & E0ESC) {
f010032e:	8b 0d 00 d0 1d f0    	mov    0xf01dd000,%ecx
f0100334:	f6 c1 40             	test   $0x40,%cl
f0100337:	74 0e                	je     f0100347 <kbd_proc_data+0x7e>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100339:	83 c8 80             	or     $0xffffff80,%eax
f010033c:	89 c2                	mov    %eax,%edx
		shift &= ~E0ESC;
f010033e:	83 e1 bf             	and    $0xffffffbf,%ecx
f0100341:	89 0d 00 d0 1d f0    	mov    %ecx,0xf01dd000
	}

	shift |= shiftcode[data];
f0100347:	0f b6 c2             	movzbl %dl,%eax
f010034a:	0f b6 90 40 62 10 f0 	movzbl -0xfef9dc0(%eax),%edx
f0100351:	0b 15 00 d0 1d f0    	or     0xf01dd000,%edx
	shift ^= togglecode[data];
f0100357:	0f b6 88 40 61 10 f0 	movzbl -0xfef9ec0(%eax),%ecx
f010035e:	31 ca                	xor    %ecx,%edx
f0100360:	89 15 00 d0 1d f0    	mov    %edx,0xf01dd000

	c = charcode[shift & (CTL | SHIFT)][data];
f0100366:	89 d1                	mov    %edx,%ecx
f0100368:	83 e1 03             	and    $0x3,%ecx
f010036b:	8b 0c 8d 00 61 10 f0 	mov    -0xfef9f00(,%ecx,4),%ecx
f0100372:	0f b6 04 01          	movzbl (%ecx,%eax,1),%eax
f0100376:	0f b6 d8             	movzbl %al,%ebx
	if (shift & CAPSLOCK) {
f0100379:	f6 c2 08             	test   $0x8,%dl
f010037c:	74 1b                	je     f0100399 <kbd_proc_data+0xd0>
		if ('a' <= c && c <= 'z')
f010037e:	89 d8                	mov    %ebx,%eax
f0100380:	8d 4b 9f             	lea    -0x61(%ebx),%ecx
f0100383:	83 f9 19             	cmp    $0x19,%ecx
f0100386:	77 05                	ja     f010038d <kbd_proc_data+0xc4>
			c += 'A' - 'a';
f0100388:	83 eb 20             	sub    $0x20,%ebx
f010038b:	eb 0c                	jmp    f0100399 <kbd_proc_data+0xd0>
		else if ('A' <= c && c <= 'Z')
f010038d:	83 e8 41             	sub    $0x41,%eax
			c += 'a' - 'A';
f0100390:	8d 4b 20             	lea    0x20(%ebx),%ecx
f0100393:	83 f8 19             	cmp    $0x19,%eax
f0100396:	0f 46 d9             	cmovbe %ecx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f0100399:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f010039f:	75 2c                	jne    f01003cd <kbd_proc_data+0x104>
f01003a1:	f7 d2                	not    %edx
f01003a3:	f6 c2 06             	test   $0x6,%dl
f01003a6:	75 25                	jne    f01003cd <kbd_proc_data+0x104>
		cprintf("Rebooting!\n");
f01003a8:	83 ec 0c             	sub    $0xc,%esp
f01003ab:	68 c3 60 10 f0       	push   $0xf01060c3
f01003b0:	e8 5a 34 00 00       	call   f010380f <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01003b5:	ba 92 00 00 00       	mov    $0x92,%edx
f01003ba:	b8 03 00 00 00       	mov    $0x3,%eax
f01003bf:	ee                   	out    %al,(%dx)
f01003c0:	83 c4 10             	add    $0x10,%esp
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003c3:	89 d8                	mov    %ebx,%eax
f01003c5:	eb 08                	jmp    f01003cf <kbd_proc_data+0x106>
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003c7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01003cc:	c3                   	ret    
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
		cprintf("Rebooting!\n");
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
f01003cd:	89 d8                	mov    %ebx,%eax
}
f01003cf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01003d2:	c9                   	leave  
f01003d3:	c3                   	ret    

f01003d4 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01003d4:	55                   	push   %ebp
f01003d5:	89 e5                	mov    %esp,%ebp
f01003d7:	57                   	push   %edi
f01003d8:	56                   	push   %esi
f01003d9:	53                   	push   %ebx
f01003da:	83 ec 1c             	sub    $0x1c,%esp
f01003dd:	89 c7                	mov    %eax,%edi
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01003df:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e4:	be fd 03 00 00       	mov    $0x3fd,%esi
f01003e9:	b9 84 00 00 00       	mov    $0x84,%ecx
f01003ee:	eb 09                	jmp    f01003f9 <cons_putc+0x25>
f01003f0:	89 ca                	mov    %ecx,%edx
f01003f2:	ec                   	in     (%dx),%al
f01003f3:	ec                   	in     (%dx),%al
f01003f4:	ec                   	in     (%dx),%al
f01003f5:	ec                   	in     (%dx),%al
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
f01003f6:	83 c3 01             	add    $0x1,%ebx
f01003f9:	89 f2                	mov    %esi,%edx
f01003fb:	ec                   	in     (%dx),%al
serial_putc(int c)
{
	int i;

	for (i = 0;
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01003fc:	a8 20                	test   $0x20,%al
f01003fe:	75 08                	jne    f0100408 <cons_putc+0x34>
f0100400:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f0100406:	7e e8                	jle    f01003f0 <cons_putc+0x1c>
f0100408:	89 f8                	mov    %edi,%eax
f010040a:	88 45 e7             	mov    %al,-0x19(%ebp)
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010040d:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100412:	89 f8                	mov    %edi,%eax
f0100414:	ee                   	out    %al,(%dx)
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100415:	bb 00 00 00 00       	mov    $0x0,%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010041a:	be 79 03 00 00       	mov    $0x379,%esi
f010041f:	b9 84 00 00 00       	mov    $0x84,%ecx
f0100424:	eb 09                	jmp    f010042f <cons_putc+0x5b>
f0100426:	89 ca                	mov    %ecx,%edx
f0100428:	ec                   	in     (%dx),%al
f0100429:	ec                   	in     (%dx),%al
f010042a:	ec                   	in     (%dx),%al
f010042b:	ec                   	in     (%dx),%al
f010042c:	83 c3 01             	add    $0x1,%ebx
f010042f:	89 f2                	mov    %esi,%edx
f0100431:	ec                   	in     (%dx),%al
f0100432:	84 c0                	test   %al,%al
f0100434:	78 08                	js     f010043e <cons_putc+0x6a>
f0100436:	81 fb ff 31 00 00    	cmp    $0x31ff,%ebx
f010043c:	7e e8                	jle    f0100426 <cons_putc+0x52>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010043e:	ba 78 03 00 00       	mov    $0x378,%edx
f0100443:	0f b6 45 e7          	movzbl -0x19(%ebp),%eax
f0100447:	ee                   	out    %al,(%dx)
f0100448:	b2 7a                	mov    $0x7a,%dl
f010044a:	b8 0d 00 00 00       	mov    $0xd,%eax
f010044f:	ee                   	out    %al,(%dx)
f0100450:	b8 08 00 00 00       	mov    $0x8,%eax
f0100455:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	if (!(c & ~0xFF))
f0100456:	89 fa                	mov    %edi,%edx
f0100458:	81 e2 00 ff ff ff    	and    $0xffffff00,%edx
		c |= 0x0700;
f010045e:	89 f8                	mov    %edi,%eax
f0100460:	80 cc 07             	or     $0x7,%ah
f0100463:	85 d2                	test   %edx,%edx
f0100465:	0f 44 f8             	cmove  %eax,%edi

	switch (c & 0xff) {
f0100468:	89 f8                	mov    %edi,%eax
f010046a:	0f b6 c0             	movzbl %al,%eax
f010046d:	83 f8 09             	cmp    $0x9,%eax
f0100470:	74 74                	je     f01004e6 <cons_putc+0x112>
f0100472:	83 f8 09             	cmp    $0x9,%eax
f0100475:	7f 0a                	jg     f0100481 <cons_putc+0xad>
f0100477:	83 f8 08             	cmp    $0x8,%eax
f010047a:	74 14                	je     f0100490 <cons_putc+0xbc>
f010047c:	e9 99 00 00 00       	jmp    f010051a <cons_putc+0x146>
f0100481:	83 f8 0a             	cmp    $0xa,%eax
f0100484:	74 3a                	je     f01004c0 <cons_putc+0xec>
f0100486:	83 f8 0d             	cmp    $0xd,%eax
f0100489:	74 3d                	je     f01004c8 <cons_putc+0xf4>
f010048b:	e9 8a 00 00 00       	jmp    f010051a <cons_putc+0x146>
	case '\b':
		if (crt_pos > 0) {
f0100490:	0f b7 05 48 d2 1d f0 	movzwl 0xf01dd248,%eax
f0100497:	66 85 c0             	test   %ax,%ax
f010049a:	0f 84 e6 00 00 00    	je     f0100586 <cons_putc+0x1b2>
			crt_pos--;
f01004a0:	83 e8 01             	sub    $0x1,%eax
f01004a3:	66 a3 48 d2 1d f0    	mov    %ax,0xf01dd248
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01004a9:	0f b7 c0             	movzwl %ax,%eax
f01004ac:	66 81 e7 00 ff       	and    $0xff00,%di
f01004b1:	83 cf 20             	or     $0x20,%edi
f01004b4:	8b 15 4c d2 1d f0    	mov    0xf01dd24c,%edx
f01004ba:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
f01004be:	eb 78                	jmp    f0100538 <cons_putc+0x164>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01004c0:	66 83 05 48 d2 1d f0 	addw   $0x50,0xf01dd248
f01004c7:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01004c8:	0f b7 05 48 d2 1d f0 	movzwl 0xf01dd248,%eax
f01004cf:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01004d5:	c1 e8 16             	shr    $0x16,%eax
f01004d8:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01004db:	c1 e0 04             	shl    $0x4,%eax
f01004de:	66 a3 48 d2 1d f0    	mov    %ax,0xf01dd248
f01004e4:	eb 52                	jmp    f0100538 <cons_putc+0x164>
		break;
	case '\t':
		cons_putc(' ');
f01004e6:	b8 20 00 00 00       	mov    $0x20,%eax
f01004eb:	e8 e4 fe ff ff       	call   f01003d4 <cons_putc>
		cons_putc(' ');
f01004f0:	b8 20 00 00 00       	mov    $0x20,%eax
f01004f5:	e8 da fe ff ff       	call   f01003d4 <cons_putc>
		cons_putc(' ');
f01004fa:	b8 20 00 00 00       	mov    $0x20,%eax
f01004ff:	e8 d0 fe ff ff       	call   f01003d4 <cons_putc>
		cons_putc(' ');
f0100504:	b8 20 00 00 00       	mov    $0x20,%eax
f0100509:	e8 c6 fe ff ff       	call   f01003d4 <cons_putc>
		cons_putc(' ');
f010050e:	b8 20 00 00 00       	mov    $0x20,%eax
f0100513:	e8 bc fe ff ff       	call   f01003d4 <cons_putc>
f0100518:	eb 1e                	jmp    f0100538 <cons_putc+0x164>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f010051a:	0f b7 05 48 d2 1d f0 	movzwl 0xf01dd248,%eax
f0100521:	8d 50 01             	lea    0x1(%eax),%edx
f0100524:	66 89 15 48 d2 1d f0 	mov    %dx,0xf01dd248
f010052b:	0f b7 c0             	movzwl %ax,%eax
f010052e:	8b 15 4c d2 1d f0    	mov    0xf01dd24c,%edx
f0100534:	66 89 3c 42          	mov    %di,(%edx,%eax,2)
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100538:	66 81 3d 48 d2 1d f0 	cmpw   $0x7cf,0xf01dd248
f010053f:	cf 07 
f0100541:	76 43                	jbe    f0100586 <cons_putc+0x1b2>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100543:	a1 4c d2 1d f0       	mov    0xf01dd24c,%eax
f0100548:	83 ec 04             	sub    $0x4,%esp
f010054b:	68 00 0f 00 00       	push   $0xf00
f0100550:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100556:	52                   	push   %edx
f0100557:	50                   	push   %eax
f0100558:	e8 13 4e 00 00       	call   f0105370 <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f010055d:	8b 15 4c d2 1d f0    	mov    0xf01dd24c,%edx
f0100563:	8d 82 00 0f 00 00    	lea    0xf00(%edx),%eax
f0100569:	81 c2 a0 0f 00 00    	add    $0xfa0,%edx
f010056f:	83 c4 10             	add    $0x10,%esp
f0100572:	66 c7 00 20 07       	movw   $0x720,(%eax)
f0100577:	83 c0 02             	add    $0x2,%eax
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f010057a:	39 d0                	cmp    %edx,%eax
f010057c:	75 f4                	jne    f0100572 <cons_putc+0x19e>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010057e:	66 83 2d 48 d2 1d f0 	subw   $0x50,0xf01dd248
f0100585:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100586:	8b 0d 50 d2 1d f0    	mov    0xf01dd250,%ecx
f010058c:	b8 0e 00 00 00       	mov    $0xe,%eax
f0100591:	89 ca                	mov    %ecx,%edx
f0100593:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100594:	0f b7 1d 48 d2 1d f0 	movzwl 0xf01dd248,%ebx
f010059b:	8d 71 01             	lea    0x1(%ecx),%esi
f010059e:	89 d8                	mov    %ebx,%eax
f01005a0:	66 c1 e8 08          	shr    $0x8,%ax
f01005a4:	89 f2                	mov    %esi,%edx
f01005a6:	ee                   	out    %al,(%dx)
f01005a7:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005ac:	89 ca                	mov    %ecx,%edx
f01005ae:	ee                   	out    %al,(%dx)
f01005af:	89 d8                	mov    %ebx,%eax
f01005b1:	89 f2                	mov    %esi,%edx
f01005b3:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01005b4:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01005b7:	5b                   	pop    %ebx
f01005b8:	5e                   	pop    %esi
f01005b9:	5f                   	pop    %edi
f01005ba:	5d                   	pop    %ebp
f01005bb:	c3                   	ret    

f01005bc <serial_intr>:
}

void
serial_intr(void)
{
	if (serial_exists)
f01005bc:	80 3d 54 d2 1d f0 00 	cmpb   $0x0,0xf01dd254
f01005c3:	74 11                	je     f01005d6 <serial_intr+0x1a>
	return inb(COM1+COM_RX);
}

void
serial_intr(void)
{
f01005c5:	55                   	push   %ebp
f01005c6:	89 e5                	mov    %esp,%ebp
f01005c8:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
		cons_intr(serial_proc_data);
f01005cb:	b8 69 02 10 f0       	mov    $0xf0100269,%eax
f01005d0:	e8 b0 fc ff ff       	call   f0100285 <cons_intr>
}
f01005d5:	c9                   	leave  
f01005d6:	f3 c3                	repz ret 

f01005d8 <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01005d8:	55                   	push   %ebp
f01005d9:	89 e5                	mov    %esp,%ebp
f01005db:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01005de:	b8 c9 02 10 f0       	mov    $0xf01002c9,%eax
f01005e3:	e8 9d fc ff ff       	call   f0100285 <cons_intr>
}
f01005e8:	c9                   	leave  
f01005e9:	c3                   	ret    

f01005ea <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01005ea:	55                   	push   %ebp
f01005eb:	89 e5                	mov    %esp,%ebp
f01005ed:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01005f0:	e8 c7 ff ff ff       	call   f01005bc <serial_intr>
	kbd_intr();
f01005f5:	e8 de ff ff ff       	call   f01005d8 <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01005fa:	a1 40 d2 1d f0       	mov    0xf01dd240,%eax
f01005ff:	3b 05 44 d2 1d f0    	cmp    0xf01dd244,%eax
f0100605:	74 26                	je     f010062d <cons_getc+0x43>
		c = cons.buf[cons.rpos++];
f0100607:	8d 50 01             	lea    0x1(%eax),%edx
f010060a:	89 15 40 d2 1d f0    	mov    %edx,0xf01dd240
f0100610:	0f b6 88 40 d0 1d f0 	movzbl -0xfe22fc0(%eax),%ecx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
f0100617:	89 c8                	mov    %ecx,%eax
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
f0100619:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f010061f:	75 11                	jne    f0100632 <cons_getc+0x48>
			cons.rpos = 0;
f0100621:	c7 05 40 d2 1d f0 00 	movl   $0x0,0xf01dd240
f0100628:	00 00 00 
f010062b:	eb 05                	jmp    f0100632 <cons_getc+0x48>
		return c;
	}
	return 0;
f010062d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100632:	c9                   	leave  
f0100633:	c3                   	ret    

f0100634 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100634:	55                   	push   %ebp
f0100635:	89 e5                	mov    %esp,%ebp
f0100637:	57                   	push   %edi
f0100638:	56                   	push   %esi
f0100639:	53                   	push   %ebx
f010063a:	83 ec 0c             	sub    $0xc,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010063d:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100644:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010064b:	5a a5 
	if (*cp != 0xA55A) {
f010064d:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100654:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100658:	74 11                	je     f010066b <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010065a:	c7 05 50 d2 1d f0 b4 	movl   $0x3b4,0xf01dd250
f0100661:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100664:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100669:	eb 16                	jmp    f0100681 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010066b:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100672:	c7 05 50 d2 1d f0 d4 	movl   $0x3d4,0xf01dd250
f0100679:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010067c:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100681:	8b 3d 50 d2 1d f0    	mov    0xf01dd250,%edi
f0100687:	b8 0e 00 00 00       	mov    $0xe,%eax
f010068c:	89 fa                	mov    %edi,%edx
f010068e:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010068f:	8d 4f 01             	lea    0x1(%edi),%ecx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100692:	89 ca                	mov    %ecx,%edx
f0100694:	ec                   	in     (%dx),%al
f0100695:	0f b6 c0             	movzbl %al,%eax
f0100698:	c1 e0 08             	shl    $0x8,%eax
f010069b:	89 c3                	mov    %eax,%ebx
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010069d:	b8 0f 00 00 00       	mov    $0xf,%eax
f01006a2:	89 fa                	mov    %edi,%edx
f01006a4:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01006a5:	89 ca                	mov    %ecx,%edx
f01006a7:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01006a8:	89 35 4c d2 1d f0    	mov    %esi,0xf01dd24c

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01006ae:	0f b6 c8             	movzbl %al,%ecx
f01006b1:	89 d8                	mov    %ebx,%eax
f01006b3:	09 c8                	or     %ecx,%eax

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01006b5:	66 a3 48 d2 1d f0    	mov    %ax,0xf01dd248

static void
kbd_init(void)
{
	// Drain the kbd buffer so that QEMU generates interrupts.
	kbd_intr();
f01006bb:	e8 18 ff ff ff       	call   f01005d8 <kbd_intr>
	irq_setmask_8259A(irq_mask_8259A & ~(1<<1));
f01006c0:	83 ec 0c             	sub    $0xc,%esp
f01006c3:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f01006ca:	25 fd ff 00 00       	and    $0xfffd,%eax
f01006cf:	50                   	push   %eax
f01006d0:	e8 01 30 00 00       	call   f01036d6 <irq_setmask_8259A>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01006d5:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01006da:	b8 00 00 00 00       	mov    $0x0,%eax
f01006df:	89 da                	mov    %ebx,%edx
f01006e1:	ee                   	out    %al,(%dx)
f01006e2:	b2 fb                	mov    $0xfb,%dl
f01006e4:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01006e9:	ee                   	out    %al,(%dx)
f01006ea:	be f8 03 00 00       	mov    $0x3f8,%esi
f01006ef:	b8 0c 00 00 00       	mov    $0xc,%eax
f01006f4:	89 f2                	mov    %esi,%edx
f01006f6:	ee                   	out    %al,(%dx)
f01006f7:	b2 f9                	mov    $0xf9,%dl
f01006f9:	b8 00 00 00 00       	mov    $0x0,%eax
f01006fe:	ee                   	out    %al,(%dx)
f01006ff:	b2 fb                	mov    $0xfb,%dl
f0100701:	b8 03 00 00 00       	mov    $0x3,%eax
f0100706:	ee                   	out    %al,(%dx)
f0100707:	b2 fc                	mov    $0xfc,%dl
f0100709:	b8 00 00 00 00       	mov    $0x0,%eax
f010070e:	ee                   	out    %al,(%dx)
f010070f:	b2 f9                	mov    $0xf9,%dl
f0100711:	b8 01 00 00 00       	mov    $0x1,%eax
f0100716:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100717:	b2 fd                	mov    $0xfd,%dl
f0100719:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010071a:	83 c4 10             	add    $0x10,%esp
f010071d:	3c ff                	cmp    $0xff,%al
f010071f:	0f 95 c1             	setne  %cl
f0100722:	88 0d 54 d2 1d f0    	mov    %cl,0xf01dd254
f0100728:	89 da                	mov    %ebx,%edx
f010072a:	ec                   	in     (%dx),%al
f010072b:	89 f2                	mov    %esi,%edx
f010072d:	ec                   	in     (%dx),%al
	(void) inb(COM1+COM_IIR);
	(void) inb(COM1+COM_RX);

	// Enable serial interrupts
	if (serial_exists)
f010072e:	84 c9                	test   %cl,%cl
f0100730:	74 21                	je     f0100753 <cons_init+0x11f>
		irq_setmask_8259A(irq_mask_8259A & ~(1<<4));
f0100732:	83 ec 0c             	sub    $0xc,%esp
f0100735:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f010073c:	25 ef ff 00 00       	and    $0xffef,%eax
f0100741:	50                   	push   %eax
f0100742:	e8 8f 2f 00 00       	call   f01036d6 <irq_setmask_8259A>
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f0100747:	83 c4 10             	add    $0x10,%esp
f010074a:	80 3d 54 d2 1d f0 00 	cmpb   $0x0,0xf01dd254
f0100751:	75 10                	jne    f0100763 <cons_init+0x12f>
		cprintf("Serial port does not exist!\n");
f0100753:	83 ec 0c             	sub    $0xc,%esp
f0100756:	68 cf 60 10 f0       	push   $0xf01060cf
f010075b:	e8 af 30 00 00       	call   f010380f <cprintf>
f0100760:	83 c4 10             	add    $0x10,%esp
}
f0100763:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100766:	5b                   	pop    %ebx
f0100767:	5e                   	pop    %esi
f0100768:	5f                   	pop    %edi
f0100769:	5d                   	pop    %ebp
f010076a:	c3                   	ret    

f010076b <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f010076b:	55                   	push   %ebp
f010076c:	89 e5                	mov    %esp,%ebp
f010076e:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f0100771:	8b 45 08             	mov    0x8(%ebp),%eax
f0100774:	e8 5b fc ff ff       	call   f01003d4 <cons_putc>
}
f0100779:	c9                   	leave  
f010077a:	c3                   	ret    

f010077b <getchar>:

int
getchar(void)
{
f010077b:	55                   	push   %ebp
f010077c:	89 e5                	mov    %esp,%ebp
f010077e:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f0100781:	e8 64 fe ff ff       	call   f01005ea <cons_getc>
f0100786:	85 c0                	test   %eax,%eax
f0100788:	74 f7                	je     f0100781 <getchar+0x6>
		/* do nothing */;
	return c;
}
f010078a:	c9                   	leave  
f010078b:	c3                   	ret    

f010078c <iscons>:

int
iscons(int fdnum)
{
f010078c:	55                   	push   %ebp
f010078d:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010078f:	b8 01 00 00 00       	mov    $0x1,%eax
f0100794:	5d                   	pop    %ebp
f0100795:	c3                   	ret    

f0100796 <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f0100796:	55                   	push   %ebp
f0100797:	89 e5                	mov    %esp,%ebp
f0100799:	83 ec 0c             	sub    $0xc,%esp
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f010079c:	68 40 63 10 f0       	push   $0xf0106340
f01007a1:	68 5e 63 10 f0       	push   $0xf010635e
f01007a6:	68 63 63 10 f0       	push   $0xf0106363
f01007ab:	e8 5f 30 00 00       	call   f010380f <cprintf>
f01007b0:	83 c4 0c             	add    $0xc,%esp
f01007b3:	68 04 64 10 f0       	push   $0xf0106404
f01007b8:	68 6c 63 10 f0       	push   $0xf010636c
f01007bd:	68 63 63 10 f0       	push   $0xf0106363
f01007c2:	e8 48 30 00 00       	call   f010380f <cprintf>
f01007c7:	83 c4 0c             	add    $0xc,%esp
f01007ca:	68 75 63 10 f0       	push   $0xf0106375
f01007cf:	68 92 63 10 f0       	push   $0xf0106392
f01007d4:	68 63 63 10 f0       	push   $0xf0106363
f01007d9:	e8 31 30 00 00       	call   f010380f <cprintf>
	return 0;
}
f01007de:	b8 00 00 00 00       	mov    $0x0,%eax
f01007e3:	c9                   	leave  
f01007e4:	c3                   	ret    

f01007e5 <mon_kerninfo>:

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f01007e5:	55                   	push   %ebp
f01007e6:	89 e5                	mov    %esp,%ebp
f01007e8:	83 ec 14             	sub    $0x14,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f01007eb:	68 9d 63 10 f0       	push   $0xf010639d
f01007f0:	e8 1a 30 00 00       	call   f010380f <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01007f5:	83 c4 08             	add    $0x8,%esp
f01007f8:	68 0c 00 10 00       	push   $0x10000c
f01007fd:	68 2c 64 10 f0       	push   $0xf010642c
f0100802:	e8 08 30 00 00       	call   f010380f <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100807:	83 c4 0c             	add    $0xc,%esp
f010080a:	68 0c 00 10 00       	push   $0x10000c
f010080f:	68 0c 00 10 f0       	push   $0xf010000c
f0100814:	68 54 64 10 f0       	push   $0xf0106454
f0100819:	e8 f1 2f 00 00       	call   f010380f <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f010081e:	83 c4 0c             	add    $0xc,%esp
f0100821:	68 e5 5f 10 00       	push   $0x105fe5
f0100826:	68 e5 5f 10 f0       	push   $0xf0105fe5
f010082b:	68 78 64 10 f0       	push   $0xf0106478
f0100830:	e8 da 2f 00 00       	call   f010380f <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f0100835:	83 c4 0c             	add    $0xc,%esp
f0100838:	68 f0 ce 1d 00       	push   $0x1dcef0
f010083d:	68 f0 ce 1d f0       	push   $0xf01dcef0
f0100842:	68 9c 64 10 f0       	push   $0xf010649c
f0100847:	e8 c3 2f 00 00       	call   f010380f <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010084c:	83 c4 0c             	add    $0xc,%esp
f010084f:	68 08 f0 21 00       	push   $0x21f008
f0100854:	68 08 f0 21 f0       	push   $0xf021f008
f0100859:	68 c0 64 10 f0       	push   $0xf01064c0
f010085e:	e8 ac 2f 00 00       	call   f010380f <cprintf>
f0100863:	b8 07 f4 21 f0       	mov    $0xf021f407,%eax
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100868:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f010086d:	83 c4 08             	add    $0x8,%esp
		ROUNDUP(end - entry, 1024) / 1024);
f0100870:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100875:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010087b:	85 c0                	test   %eax,%eax
f010087d:	0f 48 c2             	cmovs  %edx,%eax
f0100880:	c1 f8 0a             	sar    $0xa,%eax
f0100883:	50                   	push   %eax
f0100884:	68 e4 64 10 f0       	push   $0xf01064e4
f0100889:	e8 81 2f 00 00       	call   f010380f <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f010088e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100893:	c9                   	leave  
f0100894:	c3                   	ret    

f0100895 <mon_backtrace>:

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100895:	55                   	push   %ebp
f0100896:	89 e5                	mov    %esp,%ebp
f0100898:	57                   	push   %edi
f0100899:	56                   	push   %esi
f010089a:	53                   	push   %ebx
f010089b:	83 ec 38             	sub    $0x38,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f010089e:	89 eb                	mov    %ebp,%ebx
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
f01008a0:	68 b6 63 10 f0       	push   $0xf01063b6
f01008a5:	e8 65 2f 00 00       	call   f010380f <cprintf>
	
	
	while (ebp){
f01008aa:	83 c4 10             	add    $0x10,%esp
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
		debuginfo_eip(eip, &sym);
f01008ad:	8d 7d d0             	lea    -0x30(%ebp),%edi
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01008b0:	eb 41                	jmp    f01008f3 <mon_backtrace+0x5e>
	// Your code here.
		struct Eipdebuginfo sym;
		uint32_t eip = *((uint32_t*)ebp+1);
f01008b2:	8b 73 04             	mov    0x4(%ebx),%esi
		debuginfo_eip(eip, &sym);
f01008b5:	83 ec 08             	sub    $0x8,%esp
f01008b8:	57                   	push   %edi
f01008b9:	56                   	push   %esi
f01008ba:	e8 ce 3f 00 00       	call   f010488d <debuginfo_eip>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n %s:%d: %.*s+%d\n",ebp,eip,
f01008bf:	89 f0                	mov    %esi,%eax
f01008c1:	2b 45 e0             	sub    -0x20(%ebp),%eax
f01008c4:	89 04 24             	mov    %eax,(%esp)
f01008c7:	ff 75 d8             	pushl  -0x28(%ebp)
f01008ca:	ff 75 dc             	pushl  -0x24(%ebp)
f01008cd:	ff 75 d4             	pushl  -0x2c(%ebp)
f01008d0:	ff 75 d0             	pushl  -0x30(%ebp)
f01008d3:	ff 73 18             	pushl  0x18(%ebx)
f01008d6:	ff 73 14             	pushl  0x14(%ebx)
f01008d9:	ff 73 10             	pushl  0x10(%ebx)
f01008dc:	ff 73 0c             	pushl  0xc(%ebx)
f01008df:	ff 73 08             	pushl  0x8(%ebx)
f01008e2:	56                   	push   %esi
f01008e3:	53                   	push   %ebx
f01008e4:	68 10 65 10 f0       	push   $0xf0106510
f01008e9:	e8 21 2f 00 00       	call   f010380f <cprintf>
		*((uint32_t *)ebp + 6), sym.eip_file,
			      sym.eip_line,
			      sym.eip_fn_namelen,
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
f01008ee:	8b 1b                	mov    (%ebx),%ebx
f01008f0:	83 c4 40             	add    $0x40,%esp
{
	uint32_t ebp = read_ebp();
	cprintf("Stack backtrace:\n");
	
	
	while (ebp){
f01008f3:	85 db                	test   %ebx,%ebx
f01008f5:	75 bb                	jne    f01008b2 <mon_backtrace+0x1d>
			      sym.eip_fn_name,
			      (char*)eip - (char*)sym.eip_fn_addr);
	ebp = *(uint32_t*)ebp;
	}
	return 0;
}
f01008f7:	b8 00 00 00 00       	mov    $0x0,%eax
f01008fc:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01008ff:	5b                   	pop    %ebx
f0100900:	5e                   	pop    %esi
f0100901:	5f                   	pop    %edi
f0100902:	5d                   	pop    %ebp
f0100903:	c3                   	ret    

f0100904 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100904:	55                   	push   %ebp
f0100905:	89 e5                	mov    %esp,%ebp
f0100907:	57                   	push   %edi
f0100908:	56                   	push   %esi
f0100909:	53                   	push   %ebx
f010090a:	83 ec 58             	sub    $0x58,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f010090d:	68 54 65 10 f0       	push   $0xf0106554
f0100912:	e8 f8 2e 00 00       	call   f010380f <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100917:	c7 04 24 78 65 10 f0 	movl   $0xf0106578,(%esp)
f010091e:	e8 ec 2e 00 00       	call   f010380f <cprintf>

	if (tf != NULL)
f0100923:	83 c4 10             	add    $0x10,%esp
f0100926:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f010092a:	74 0e                	je     f010093a <monitor+0x36>
		print_trapframe(tf);
f010092c:	83 ec 0c             	sub    $0xc,%esp
f010092f:	ff 75 08             	pushl  0x8(%ebp)
f0100932:	e8 f4 30 00 00       	call   f0103a2b <print_trapframe>
f0100937:	83 c4 10             	add    $0x10,%esp

	while (1) {
		buf = readline("K> ");
f010093a:	83 ec 0c             	sub    $0xc,%esp
f010093d:	68 c8 63 10 f0       	push   $0xf01063c8
f0100942:	e8 6d 47 00 00       	call   f01050b4 <readline>
f0100947:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100949:	83 c4 10             	add    $0x10,%esp
f010094c:	85 c0                	test   %eax,%eax
f010094e:	74 ea                	je     f010093a <monitor+0x36>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100950:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100957:	be 00 00 00 00       	mov    $0x0,%esi
f010095c:	eb 0a                	jmp    f0100968 <monitor+0x64>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010095e:	c6 03 00             	movb   $0x0,(%ebx)
f0100961:	89 f7                	mov    %esi,%edi
f0100963:	8d 5b 01             	lea    0x1(%ebx),%ebx
f0100966:	89 fe                	mov    %edi,%esi
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100968:	0f b6 03             	movzbl (%ebx),%eax
f010096b:	84 c0                	test   %al,%al
f010096d:	74 63                	je     f01009d2 <monitor+0xce>
f010096f:	83 ec 08             	sub    $0x8,%esp
f0100972:	0f be c0             	movsbl %al,%eax
f0100975:	50                   	push   %eax
f0100976:	68 cc 63 10 f0       	push   $0xf01063cc
f010097b:	e8 66 49 00 00       	call   f01052e6 <strchr>
f0100980:	83 c4 10             	add    $0x10,%esp
f0100983:	85 c0                	test   %eax,%eax
f0100985:	75 d7                	jne    f010095e <monitor+0x5a>
			*buf++ = 0;
		if (*buf == 0)
f0100987:	80 3b 00             	cmpb   $0x0,(%ebx)
f010098a:	74 46                	je     f01009d2 <monitor+0xce>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f010098c:	83 fe 0f             	cmp    $0xf,%esi
f010098f:	75 14                	jne    f01009a5 <monitor+0xa1>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100991:	83 ec 08             	sub    $0x8,%esp
f0100994:	6a 10                	push   $0x10
f0100996:	68 d1 63 10 f0       	push   $0xf01063d1
f010099b:	e8 6f 2e 00 00       	call   f010380f <cprintf>
f01009a0:	83 c4 10             	add    $0x10,%esp
f01009a3:	eb 95                	jmp    f010093a <monitor+0x36>
			return 0;
		}
		argv[argc++] = buf;
f01009a5:	8d 7e 01             	lea    0x1(%esi),%edi
f01009a8:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f01009ac:	eb 03                	jmp    f01009b1 <monitor+0xad>
		while (*buf && !strchr(WHITESPACE, *buf))
			buf++;
f01009ae:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f01009b1:	0f b6 03             	movzbl (%ebx),%eax
f01009b4:	84 c0                	test   %al,%al
f01009b6:	74 ae                	je     f0100966 <monitor+0x62>
f01009b8:	83 ec 08             	sub    $0x8,%esp
f01009bb:	0f be c0             	movsbl %al,%eax
f01009be:	50                   	push   %eax
f01009bf:	68 cc 63 10 f0       	push   $0xf01063cc
f01009c4:	e8 1d 49 00 00       	call   f01052e6 <strchr>
f01009c9:	83 c4 10             	add    $0x10,%esp
f01009cc:	85 c0                	test   %eax,%eax
f01009ce:	74 de                	je     f01009ae <monitor+0xaa>
f01009d0:	eb 94                	jmp    f0100966 <monitor+0x62>
			buf++;
	}
	argv[argc] = 0;
f01009d2:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f01009d9:	00 

	// Lookup and invoke the command
	if (argc == 0)
f01009da:	85 f6                	test   %esi,%esi
f01009dc:	0f 84 58 ff ff ff    	je     f010093a <monitor+0x36>
f01009e2:	bb 00 00 00 00       	mov    $0x0,%ebx
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f01009e7:	83 ec 08             	sub    $0x8,%esp
f01009ea:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f01009ed:	ff 34 85 a0 65 10 f0 	pushl  -0xfef9a60(,%eax,4)
f01009f4:	ff 75 a8             	pushl  -0x58(%ebp)
f01009f7:	e8 8c 48 00 00       	call   f0105288 <strcmp>
f01009fc:	83 c4 10             	add    $0x10,%esp
f01009ff:	85 c0                	test   %eax,%eax
f0100a01:	75 22                	jne    f0100a25 <monitor+0x121>
			return commands[i].func(argc, argv, tf);
f0100a03:	83 ec 04             	sub    $0x4,%esp
f0100a06:	8d 04 5b             	lea    (%ebx,%ebx,2),%eax
f0100a09:	ff 75 08             	pushl  0x8(%ebp)
f0100a0c:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100a0f:	52                   	push   %edx
f0100a10:	56                   	push   %esi
f0100a11:	ff 14 85 a8 65 10 f0 	call   *-0xfef9a58(,%eax,4)
		print_trapframe(tf);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100a18:	83 c4 10             	add    $0x10,%esp
f0100a1b:	85 c0                	test   %eax,%eax
f0100a1d:	0f 89 17 ff ff ff    	jns    f010093a <monitor+0x36>
f0100a23:	eb 20                	jmp    f0100a45 <monitor+0x141>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100a25:	83 c3 01             	add    $0x1,%ebx
f0100a28:	83 fb 03             	cmp    $0x3,%ebx
f0100a2b:	75 ba                	jne    f01009e7 <monitor+0xe3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100a2d:	83 ec 08             	sub    $0x8,%esp
f0100a30:	ff 75 a8             	pushl  -0x58(%ebp)
f0100a33:	68 ee 63 10 f0       	push   $0xf01063ee
f0100a38:	e8 d2 2d 00 00       	call   f010380f <cprintf>
f0100a3d:	83 c4 10             	add    $0x10,%esp
f0100a40:	e9 f5 fe ff ff       	jmp    f010093a <monitor+0x36>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100a45:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100a48:	5b                   	pop    %ebx
f0100a49:	5e                   	pop    %esi
f0100a4a:	5f                   	pop    %edi
f0100a4b:	5d                   	pop    %ebp
f0100a4c:	c3                   	ret    

f0100a4d <check_va2pa>:
static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100a4d:	89 d1                	mov    %edx,%ecx
f0100a4f:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100a52:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0100a55:	a8 01                	test   $0x1,%al
f0100a57:	74 52                	je     f0100aab <check_va2pa+0x5e>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100a59:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100a5e:	89 c1                	mov    %eax,%ecx
f0100a60:	c1 e9 0c             	shr    $0xc,%ecx
f0100a63:	3b 0d c8 de 1d f0    	cmp    0xf01ddec8,%ecx
f0100a69:	72 1b                	jb     f0100a86 <check_va2pa+0x39>
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100a6b:	55                   	push   %ebp
f0100a6c:	89 e5                	mov    %esp,%ebp
f0100a6e:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100a71:	50                   	push   %eax
f0100a72:	68 24 60 10 f0       	push   $0xf0106024
f0100a77:	68 10 04 00 00       	push   $0x410
f0100a7c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100a81:	e8 ba f5 ff ff       	call   f0100040 <_panic>

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
f0100a86:	c1 ea 0c             	shr    $0xc,%edx
f0100a89:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100a8f:	8b 84 90 00 00 00 f0 	mov    -0x10000000(%eax,%edx,4),%eax
f0100a96:	89 c2                	mov    %eax,%edx
f0100a98:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100a9b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100aa0:	85 d2                	test   %edx,%edx
f0100aa2:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100aa7:	0f 44 c2             	cmove  %edx,%eax
f0100aaa:	c3                   	ret    
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
		return ~0;
f0100aab:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
	if (!(p[PTX(va)] & PTE_P))
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
}
f0100ab0:	c3                   	ret    

f0100ab1 <boot_alloc>:
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100ab1:	83 3d 5c d2 1d f0 00 	cmpl   $0x0,0xf01dd25c
f0100ab8:	75 11                	jne    f0100acb <boot_alloc+0x1a>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE); // Roundup function rounds according to the given functions
f0100aba:	ba 07 00 22 f0       	mov    $0xf0220007,%edx
f0100abf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100ac5:	89 15 5c d2 1d f0    	mov    %edx,0xf01dd25c
	}
	
	if (n==0){
f0100acb:	85 c0                	test   %eax,%eax
f0100acd:	75 06                	jne    f0100ad5 <boot_alloc+0x24>
	return nextfree;
f0100acf:	a1 5c d2 1d f0       	mov    0xf01dd25c,%eax
f0100ad4:	c3                   	ret    
	// Allocate a chunk large enough to hold 'n' bytes, then update
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	//
	// LAB 2: Your code here.
	result  = nextfree;
f0100ad5:	8b 0d 5c d2 1d f0    	mov    0xf01dd25c,%ecx
	nextfree += ROUNDUP(n,PGSIZE);
f0100adb:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100ae0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100ae5:	8d 14 01             	lea    (%ecx,%eax,1),%edx
f0100ae8:	89 15 5c d2 1d f0    	mov    %edx,0xf01dd25c
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100aee:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0100af4:	77 18                	ja     f0100b0e <boot_alloc+0x5d>
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100af6:	55                   	push   %ebp
f0100af7:	89 e5                	mov    %esp,%ebp
f0100af9:	83 ec 08             	sub    $0x8,%esp
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100afc:	52                   	push   %edx
f0100afd:	68 48 60 10 f0       	push   $0xf0106048
f0100b02:	6a 71                	push   $0x71
f0100b04:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100b09:	e8 32 f5 ff ff       	call   f0100040 <_panic>
	// LAB 2: Your code here.
	result  = nextfree;
	nextfree += ROUNDUP(n,PGSIZE);
	
	
	if ((PADDR(nextfree))>npages*PGSIZE){
f0100b0e:	a1 c8 de 1d f0       	mov    0xf01ddec8,%eax
f0100b13:	c1 e0 0c             	shl    $0xc,%eax
	return (physaddr_t)kva - KERNBASE;
f0100b16:	81 c2 00 00 00 10    	add    $0x10000000,%edx
		return 0;
	}
	return result;
f0100b1c:	39 c2                	cmp    %eax,%edx
f0100b1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100b23:	0f 46 c1             	cmovbe %ecx,%eax
}
f0100b26:	c3                   	ret    

f0100b27 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100b27:	55                   	push   %ebp
f0100b28:	89 e5                	mov    %esp,%ebp
f0100b2a:	57                   	push   %edi
f0100b2b:	56                   	push   %esi
f0100b2c:	53                   	push   %ebx
f0100b2d:	83 ec 3c             	sub    $0x3c,%esp
f0100b30:	89 45 c0             	mov    %eax,-0x40(%ebp)
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100b33:	84 c0                	test   %al,%al
f0100b35:	0f 85 b1 02 00 00    	jne    f0100dec <check_page_free_list+0x2c5>
f0100b3b:	e9 be 02 00 00       	jmp    f0100dfe <check_page_free_list+0x2d7>
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
		panic("'page_free_list' is a null pointer!");
f0100b40:	83 ec 04             	sub    $0x4,%esp
f0100b43:	68 c4 65 10 f0       	push   $0xf01065c4
f0100b48:	68 44 03 00 00       	push   $0x344
f0100b4d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100b52:	e8 e9 f4 ff ff       	call   f0100040 <_panic>

	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100b57:	8d 55 d8             	lea    -0x28(%ebp),%edx
f0100b5a:	89 55 e0             	mov    %edx,-0x20(%ebp)
f0100b5d:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100b60:	89 55 e4             	mov    %edx,-0x1c(%ebp)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100b63:	89 c2                	mov    %eax,%edx
f0100b65:	2b 15 d0 de 1d f0    	sub    0xf01dded0,%edx
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100b6b:	f7 c2 00 e0 7f 00    	test   $0x7fe000,%edx
f0100b71:	0f 95 c2             	setne  %dl
f0100b74:	0f b6 d2             	movzbl %dl,%edx
			*tp[pagetype] = pp;
f0100b77:	8b 4c 95 e0          	mov    -0x20(%ebp,%edx,4),%ecx
f0100b7b:	89 01                	mov    %eax,(%ecx)
			tp[pagetype] = &pp->pp_link;
f0100b7d:	89 44 95 e0          	mov    %eax,-0x20(%ebp,%edx,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100b81:	8b 00                	mov    (%eax),%eax
f0100b83:	85 c0                	test   %eax,%eax
f0100b85:	75 dc                	jne    f0100b63 <check_page_free_list+0x3c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100b87:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100b8a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100b90:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100b93:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100b96:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100b98:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100b9b:	a3 64 d2 1d f0       	mov    %eax,0xf01dd264
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ba0:	be 01 00 00 00       	mov    $0x1,%esi
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100ba5:	8b 1d 64 d2 1d f0    	mov    0xf01dd264,%ebx
f0100bab:	eb 53                	jmp    f0100c00 <check_page_free_list+0xd9>
f0100bad:	89 d8                	mov    %ebx,%eax
f0100baf:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0100bb5:	c1 f8 03             	sar    $0x3,%eax
f0100bb8:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100bbb:	89 c2                	mov    %eax,%edx
f0100bbd:	c1 ea 16             	shr    $0x16,%edx
f0100bc0:	39 f2                	cmp    %esi,%edx
f0100bc2:	73 3a                	jae    f0100bfe <check_page_free_list+0xd7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100bc4:	89 c2                	mov    %eax,%edx
f0100bc6:	c1 ea 0c             	shr    $0xc,%edx
f0100bc9:	3b 15 c8 de 1d f0    	cmp    0xf01ddec8,%edx
f0100bcf:	72 12                	jb     f0100be3 <check_page_free_list+0xbc>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100bd1:	50                   	push   %eax
f0100bd2:	68 24 60 10 f0       	push   $0xf0106024
f0100bd7:	6a 58                	push   $0x58
f0100bd9:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0100bde:	e8 5d f4 ff ff       	call   f0100040 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100be3:	83 ec 04             	sub    $0x4,%esp
f0100be6:	68 80 00 00 00       	push   $0x80
f0100beb:	68 97 00 00 00       	push   $0x97
	return (void *)(pa + KERNBASE);
f0100bf0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100bf5:	50                   	push   %eax
f0100bf6:	e8 28 47 00 00       	call   f0105323 <memset>
f0100bfb:	83 c4 10             	add    $0x10,%esp
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100bfe:	8b 1b                	mov    (%ebx),%ebx
f0100c00:	85 db                	test   %ebx,%ebx
f0100c02:	75 a9                	jne    f0100bad <check_page_free_list+0x86>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100c04:	b8 00 00 00 00       	mov    $0x0,%eax
f0100c09:	e8 a3 fe ff ff       	call   f0100ab1 <boot_alloc>
f0100c0e:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c11:	8b 15 64 d2 1d f0    	mov    0xf01dd264,%edx
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c17:	8b 0d d0 de 1d f0    	mov    0xf01dded0,%ecx
		assert(pp < pages + npages);
f0100c1d:	a1 c8 de 1d f0       	mov    0xf01ddec8,%eax
f0100c22:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0100c25:	8d 34 c1             	lea    (%ecx,%eax,8),%esi
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c28:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100c2b:	bf 00 00 00 00       	mov    $0x0,%edi
f0100c30:	89 5d cc             	mov    %ebx,-0x34(%ebp)
f0100c33:	89 f0                	mov    %esi,%eax
f0100c35:	89 ce                	mov    %ecx,%esi
f0100c37:	89 c1                	mov    %eax,%ecx
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100c39:	e9 55 01 00 00       	jmp    f0100d93 <check_page_free_list+0x26c>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100c3e:	39 f2                	cmp    %esi,%edx
f0100c40:	73 19                	jae    f0100c5b <check_page_free_list+0x134>
f0100c42:	68 cf 6f 10 f0       	push   $0xf0106fcf
f0100c47:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100c4c:	68 5e 03 00 00       	push   $0x35e
f0100c51:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100c56:	e8 e5 f3 ff ff       	call   f0100040 <_panic>
		assert(pp < pages + npages);
f0100c5b:	39 ca                	cmp    %ecx,%edx
f0100c5d:	72 19                	jb     f0100c78 <check_page_free_list+0x151>
f0100c5f:	68 f0 6f 10 f0       	push   $0xf0106ff0
f0100c64:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100c69:	68 5f 03 00 00       	push   $0x35f
f0100c6e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100c73:	e8 c8 f3 ff ff       	call   f0100040 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100c78:	89 d0                	mov    %edx,%eax
f0100c7a:	2b 45 d4             	sub    -0x2c(%ebp),%eax
f0100c7d:	a8 07                	test   $0x7,%al
f0100c7f:	74 19                	je     f0100c9a <check_page_free_list+0x173>
f0100c81:	68 e8 65 10 f0       	push   $0xf01065e8
f0100c86:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100c8b:	68 60 03 00 00       	push   $0x360
f0100c90:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100c95:	e8 a6 f3 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100c9a:	c1 f8 03             	sar    $0x3,%eax
f0100c9d:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ca0:	85 c0                	test   %eax,%eax
f0100ca2:	75 19                	jne    f0100cbd <check_page_free_list+0x196>
f0100ca4:	68 04 70 10 f0       	push   $0xf0107004
f0100ca9:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100cae:	68 63 03 00 00       	push   $0x363
f0100cb3:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100cb8:	e8 83 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100cbd:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100cc2:	75 19                	jne    f0100cdd <check_page_free_list+0x1b6>
f0100cc4:	68 15 70 10 f0       	push   $0xf0107015
f0100cc9:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100cce:	68 64 03 00 00       	push   $0x364
f0100cd3:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100cd8:	e8 63 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100cdd:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100ce2:	75 19                	jne    f0100cfd <check_page_free_list+0x1d6>
f0100ce4:	68 1c 66 10 f0       	push   $0xf010661c
f0100ce9:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100cee:	68 65 03 00 00       	push   $0x365
f0100cf3:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100cf8:	e8 43 f3 ff ff       	call   f0100040 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100cfd:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100d02:	75 19                	jne    f0100d1d <check_page_free_list+0x1f6>
f0100d04:	68 2e 70 10 f0       	push   $0xf010702e
f0100d09:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100d0e:	68 66 03 00 00       	push   $0x366
f0100d13:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100d18:	e8 23 f3 ff ff       	call   f0100040 <_panic>
f0100d1d:	89 45 d0             	mov    %eax,-0x30(%ebp)
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100d20:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100d25:	0f 86 ea 00 00 00    	jbe    f0100e15 <check_page_free_list+0x2ee>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d2b:	89 c3                	mov    %eax,%ebx
f0100d2d:	c1 eb 0c             	shr    $0xc,%ebx
f0100d30:	39 5d c4             	cmp    %ebx,-0x3c(%ebp)
f0100d33:	77 12                	ja     f0100d47 <check_page_free_list+0x220>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d35:	50                   	push   %eax
f0100d36:	68 24 60 10 f0       	push   $0xf0106024
f0100d3b:	6a 58                	push   $0x58
f0100d3d:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0100d42:	e8 f9 f2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0100d47:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
f0100d4d:	39 5d c8             	cmp    %ebx,-0x38(%ebp)
f0100d50:	0f 86 cf 00 00 00    	jbe    f0100e25 <check_page_free_list+0x2fe>
f0100d56:	68 40 66 10 f0       	push   $0xf0106640
f0100d5b:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100d60:	68 67 03 00 00       	push   $0x367
f0100d65:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100d6a:	e8 d1 f2 ff ff       	call   f0100040 <_panic>
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100d6f:	68 48 70 10 f0       	push   $0xf0107048
f0100d74:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100d79:	68 69 03 00 00       	push   $0x369
f0100d7e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100d83:	e8 b8 f2 ff ff       	call   f0100040 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100d88:	83 45 cc 01          	addl   $0x1,-0x34(%ebp)
f0100d8c:	eb 03                	jmp    f0100d91 <check_page_free_list+0x26a>
		else
			++nfree_extmem;
f0100d8e:	83 c7 01             	add    $0x1,%edi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d91:	8b 12                	mov    (%edx),%edx
f0100d93:	85 d2                	test   %edx,%edx
f0100d95:	0f 85 a3 fe ff ff    	jne    f0100c3e <check_page_free_list+0x117>
f0100d9b:	8b 5d cc             	mov    -0x34(%ebp),%ebx
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100d9e:	85 db                	test   %ebx,%ebx
f0100da0:	7f 19                	jg     f0100dbb <check_page_free_list+0x294>
f0100da2:	68 65 70 10 f0       	push   $0xf0107065
f0100da7:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100dac:	68 71 03 00 00       	push   $0x371
f0100db1:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100db6:	e8 85 f2 ff ff       	call   f0100040 <_panic>
	assert(nfree_extmem > 0);
f0100dbb:	85 ff                	test   %edi,%edi
f0100dbd:	7f 19                	jg     f0100dd8 <check_page_free_list+0x2b1>
f0100dbf:	68 77 70 10 f0       	push   $0xf0107077
f0100dc4:	68 db 6f 10 f0       	push   $0xf0106fdb
f0100dc9:	68 72 03 00 00       	push   $0x372
f0100dce:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100dd3:	e8 68 f2 ff ff       	call   f0100040 <_panic>
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
f0100dd8:	83 ec 08             	sub    $0x8,%esp
f0100ddb:	0f b6 45 c0          	movzbl -0x40(%ebp),%eax
f0100ddf:	50                   	push   %eax
f0100de0:	68 88 66 10 f0       	push   $0xf0106688
f0100de5:	e8 25 2a 00 00       	call   f010380f <cprintf>
f0100dea:	eb 49                	jmp    f0100e35 <check_page_free_list+0x30e>
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100dec:	a1 64 d2 1d f0       	mov    0xf01dd264,%eax
f0100df1:	85 c0                	test   %eax,%eax
f0100df3:	0f 85 5e fd ff ff    	jne    f0100b57 <check_page_free_list+0x30>
f0100df9:	e9 42 fd ff ff       	jmp    f0100b40 <check_page_free_list+0x19>
f0100dfe:	83 3d 64 d2 1d f0 00 	cmpl   $0x0,0xf01dd264
f0100e05:	0f 84 35 fd ff ff    	je     f0100b40 <check_page_free_list+0x19>
//
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100e0b:	be 00 04 00 00       	mov    $0x400,%esi
f0100e10:	e9 90 fd ff ff       	jmp    f0100ba5 <check_page_free_list+0x7e>
		assert(page2pa(pp) != IOPHYSMEM);
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
		assert(page2pa(pp) != EXTPHYSMEM);
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
		// (new test for lab 4)
		assert(page2pa(pp) != MPENTRY_PADDR);
f0100e15:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e1a:	0f 85 68 ff ff ff    	jne    f0100d88 <check_page_free_list+0x261>
f0100e20:	e9 4a ff ff ff       	jmp    f0100d6f <check_page_free_list+0x248>
f0100e25:	3d 00 70 00 00       	cmp    $0x7000,%eax
f0100e2a:	0f 85 5e ff ff ff    	jne    f0100d8e <check_page_free_list+0x267>
f0100e30:	e9 3a ff ff ff       	jmp    f0100d6f <check_page_free_list+0x248>
	}

	assert(nfree_basemem > 0);
	assert(nfree_extmem > 0);
	cprintf("check_page_free_list(%d) ok cleared\n", only_low_memory);
}
f0100e35:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100e38:	5b                   	pop    %ebx
f0100e39:	5e                   	pop    %esi
f0100e3a:	5f                   	pop    %edi
f0100e3b:	5d                   	pop    %ebp
f0100e3c:	c3                   	ret    

f0100e3d <page_init>:
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e3d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100e42:	eb 18                	jmp    f0100e5c <page_init+0x1f>
	{
	 pages[i].pp_ref = 1; //Used Pages
f0100e44:	8b 15 d0 de 1d f0    	mov    0xf01dded0,%edx
f0100e4a:	8d 14 c2             	lea    (%edx,%eax,8),%edx
f0100e4d:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
	 pages[i].pp_link = 0; // No links to any pages
f0100e53:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
	
	size_t i;
	static struct PageInfo *track; //Keep track from basememory 

	// First mark all pages as used
	for (i = 1 ; i< npages; i++)
f0100e59:	83 c0 01             	add    $0x1,%eax
f0100e5c:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f0100e62:	72 e0                	jb     f0100e44 <page_init+0x7>
//


void
page_init(void)
{
f0100e64:	55                   	push   %ebp
f0100e65:	89 e5                	mov    %esp,%ebp
f0100e67:	57                   	push   %edi
f0100e68:	56                   	push   %esi
f0100e69:	53                   	push   %ebx
f0100e6a:	83 ec 0c             	sub    $0xc,%esp
	//Modification for Lab 4, We have to skip the Page that MPENTRY_PADDR is at from the page_free_list
	//Hence we can divide it with PGSIZE and whatever is the value, just skip that page. 
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
f0100e6d:	c7 05 64 d2 1d f0 00 	movl   $0x0,0xf01dd264
f0100e74:	00 00 00 
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100e77:	be 00 00 00 00       	mov    $0x0,%esi
	size_t mpentyPg = MPENTRY_PADDR/PGSIZE;

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
f0100e7c:	bf 00 00 00 00       	mov    $0x0,%edi
	for (i = 1; i < npages_basemem; ++i) {
f0100e81:	bb 01 00 00 00       	mov    $0x1,%ebx
f0100e86:	eb 71                	jmp    f0100ef9 <page_init+0xbc>
		if (i == mpentyPg) {
f0100e88:	83 fb 07             	cmp    $0x7,%ebx
f0100e8b:	75 14                	jne    f0100ea1 <page_init+0x64>
			cprintf("Skipped this page %d\n", i);
f0100e8d:	83 ec 08             	sub    $0x8,%esp
f0100e90:	6a 07                	push   $0x7
f0100e92:	68 88 70 10 f0       	push   $0xf0107088
f0100e97:	e8 73 29 00 00       	call   f010380f <cprintf>
			continue;	
f0100e9c:	83 c4 10             	add    $0x10,%esp
f0100e9f:	eb 52                	jmp    f0100ef3 <page_init+0xb6>
f0100ea1:	8d 04 dd 00 00 00 00 	lea    0x0(,%ebx,8),%eax
		}

		pages[i].pp_ref = 0;
f0100ea8:	8b 15 d0 de 1d f0    	mov    0xf01dded0,%edx
f0100eae:	66 c7 44 02 04 00 00 	movw   $0x0,0x4(%edx,%eax,1)
		pages[i].pp_link = 0;
f0100eb5:	c7 04 da 00 00 00 00 	movl   $0x0,(%edx,%ebx,8)
		if (!page_free_list) {
f0100ebc:	83 3d 64 d2 1d f0 00 	cmpl   $0x0,0xf01dd264
f0100ec3:	75 10                	jne    f0100ed5 <page_init+0x98>
			page_free_list = &pages[i];
f0100ec5:	89 c2                	mov    %eax,%edx
f0100ec7:	03 15 d0 de 1d f0    	add    0xf01dded0,%edx
f0100ecd:	89 15 64 d2 1d f0    	mov    %edx,0xf01dd264
f0100ed3:	eb 16                	jmp    f0100eeb <page_init+0xae>
		} else {
			prev->pp_link = &pages[i];
f0100ed5:	89 c2                	mov    %eax,%edx
f0100ed7:	03 15 d0 de 1d f0    	add    0xf01dded0,%edx
f0100edd:	89 17                	mov    %edx,(%edi)
			pages[i-1].pp_link = &pages[i];
f0100edf:	8b 15 d0 de 1d f0    	mov    0xf01dded0,%edx
f0100ee5:	8d 0c 02             	lea    (%edx,%eax,1),%ecx
f0100ee8:	89 0c 32             	mov    %ecx,(%edx,%esi,1)
		}
		prev = &pages[i];
f0100eeb:	03 05 d0 de 1d f0    	add    0xf01dded0,%eax
f0100ef1:	89 c7                	mov    %eax,%edi

	// 2. The rest of base memory 
	page_free_list = 0 ;
	
	struct PageInfo *prev = 0;
	for (i = 1; i < npages_basemem; ++i) {
f0100ef3:	83 c3 01             	add    $0x1,%ebx
f0100ef6:	83 c6 08             	add    $0x8,%esi
f0100ef9:	3b 1d 68 d2 1d f0    	cmp    0xf01dd268,%ebx
f0100eff:	72 87                	jb     f0100e88 <page_init+0x4b>
		prev = &pages[i];
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
f0100f01:	8d 04 dd f8 ff ff ff 	lea    -0x8(,%ebx,8),%eax
f0100f08:	03 05 d0 de 1d f0    	add    0xf01dded0,%eax
f0100f0e:	a3 58 d2 1d f0       	mov    %eax,0xf01dd258
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f13:	b8 00 00 00 00       	mov    $0x0,%eax
f0100f18:	e8 94 fb ff ff       	call   f0100ab1 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100f1d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0100f22:	77 15                	ja     f0100f39 <page_init+0xfc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100f24:	50                   	push   %eax
f0100f25:	68 48 60 10 f0       	push   $0xf0106048
f0100f2a:	68 75 01 00 00       	push   $0x175
f0100f2f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0100f34:	e8 07 f1 ff ff       	call   f0100040 <_panic>
f0100f39:	05 ff 0f 00 10       	add    $0x10000fff,%eax
f0100f3e:	c1 e8 0c             	shr    $0xc,%eax
f0100f41:	8b 1d 58 d2 1d f0    	mov    0xf01dd258,%ebx
f0100f47:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100f4e:	eb 2c                	jmp    f0100f7c <page_init+0x13f>
		pages[i].pp_ref = 0;
f0100f50:	89 d1                	mov    %edx,%ecx
f0100f52:	03 0d d0 de 1d f0    	add    0xf01dded0,%ecx
f0100f58:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = 0;
f0100f5e:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
		track->pp_link = &pages[i];
f0100f64:	89 d1                	mov    %edx,%ecx
f0100f66:	03 0d d0 de 1d f0    	add    0xf01dded0,%ecx
f0100f6c:	89 0b                	mov    %ecx,(%ebx)
		track = &pages[i];
f0100f6e:	89 d3                	mov    %edx,%ebx
f0100f70:	03 1d d0 de 1d f0    	add    0xf01dded0,%ebx
	}
	
	
	//3. To cover the IO hole we can skip accross the hole by linking the free memory 
	track  = &pages[i-1]; // Link to the last but 1 Base_memory page
	for (i = ROUNDUP(PADDR(boot_alloc(0)), PGSIZE) / PGSIZE; i < npages; ++i) {
f0100f76:	83 c0 01             	add    $0x1,%eax
f0100f79:	83 c2 08             	add    $0x8,%edx
f0100f7c:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f0100f82:	72 cc                	jb     f0100f50 <page_init+0x113>
f0100f84:	89 1d 58 d2 1d f0    	mov    %ebx,0xf01dd258
		pages[i].pp_link = 0;
		track->pp_link = &pages[i];
		track = &pages[i];
	}
	
	cprintf("Check first entry of pages &pages[0] = %x\n", &pages[0]);
f0100f8a:	83 ec 08             	sub    $0x8,%esp
f0100f8d:	ff 35 d0 de 1d f0    	pushl  0xf01dded0
f0100f93:	68 b0 66 10 f0       	push   $0xf01066b0
f0100f98:	e8 72 28 00 00       	call   f010380f <cprintf>
	cprintf("&pages[npages-1] = %x\n", &pages[npages-1]);
f0100f9d:	83 c4 08             	add    $0x8,%esp
f0100fa0:	a1 c8 de 1d f0       	mov    0xf01ddec8,%eax
f0100fa5:	8d 04 c5 f8 ff ff ff 	lea    -0x8(,%eax,8),%eax
f0100fac:	03 05 d0 de 1d f0    	add    0xf01dded0,%eax
f0100fb2:	50                   	push   %eax
f0100fb3:	68 9e 70 10 f0       	push   $0xf010709e
f0100fb8:	e8 52 28 00 00       	call   f010380f <cprintf>
f0100fbd:	83 c4 10             	add    $0x10,%esp
}
f0100fc0:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0100fc3:	5b                   	pop    %ebx
f0100fc4:	5e                   	pop    %esi
f0100fc5:	5f                   	pop    %edi
f0100fc6:	5d                   	pop    %ebp
f0100fc7:	c3                   	ret    

f0100fc8 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100fc8:	55                   	push   %ebp
f0100fc9:	89 e5                	mov    %esp,%ebp
f0100fcb:	53                   	push   %ebx
f0100fcc:	83 ec 04             	sub    $0x4,%esp
	// Check if there is a free_page available 
	if (!page_free_list)
f0100fcf:	8b 1d 64 d2 1d f0    	mov    0xf01dd264,%ebx
f0100fd5:	85 db                	test   %ebx,%ebx
f0100fd7:	74 5e                	je     f0101037 <page_alloc+0x6f>
	return NULL;
	}
	
	struct PageInfo *allocPage = NULL;   //Create a temporary pointer 
	allocPage = page_free_list;	//Point to the current head of free_page_list
	page_free_list = allocPage ->pp_link; //Move the head to the next avaialble page
f0100fd9:	8b 03                	mov    (%ebx),%eax
f0100fdb:	a3 64 d2 1d f0       	mov    %eax,0xf01dd264
	allocPage->pp_link = NULL;	//Break the link 
f0100fe0:	c7 03 00 00 00 00    	movl   $0x0,(%ebx)
	if (alloc_flags && ALLOC_ZERO){		//ALLOC_ZERO = 1<<0; which is nothing but  = 1
f0100fe6:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
f0100fea:	74 45                	je     f0101031 <page_alloc+0x69>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100fec:	89 d8                	mov    %ebx,%eax
f0100fee:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0100ff4:	c1 f8 03             	sar    $0x3,%eax
f0100ff7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100ffa:	89 c2                	mov    %eax,%edx
f0100ffc:	c1 ea 0c             	shr    $0xc,%edx
f0100fff:	3b 15 c8 de 1d f0    	cmp    0xf01ddec8,%edx
f0101005:	72 12                	jb     f0101019 <page_alloc+0x51>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101007:	50                   	push   %eax
f0101008:	68 24 60 10 f0       	push   $0xf0106024
f010100d:	6a 58                	push   $0x58
f010100f:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0101014:	e8 27 f0 ff ff       	call   f0100040 <_panic>
	memset(page2kva(allocPage), 0, PGSIZE);  //Clean the entire page and make it 0
f0101019:	83 ec 04             	sub    $0x4,%esp
f010101c:	68 00 10 00 00       	push   $0x1000
f0101021:	6a 00                	push   $0x0
	return (void *)(pa + KERNBASE);
f0101023:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101028:	50                   	push   %eax
f0101029:	e8 f5 42 00 00       	call   f0105323 <memset>
f010102e:	83 c4 10             	add    $0x10,%esp
	}
	
	allocPage->pp_ref = 0;
f0101031:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)
	return allocPage;
}
f0101037:	89 d8                	mov    %ebx,%eax
f0101039:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010103c:	c9                   	leave  
f010103d:	c3                   	ret    

f010103e <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010103e:	55                   	push   %ebp
f010103f:	89 e5                	mov    %esp,%ebp
f0101041:	83 ec 08             	sub    $0x8,%esp
f0101044:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	// Hint: You may want to panic if pp->pp_ref is nonzero or
	
	if(pp->pp_ref)
f0101047:	66 83 78 04 00       	cmpw   $0x0,0x4(%eax)
f010104c:	74 17                	je     f0101065 <page_free+0x27>
	{
	panic("Page cannot be returned to free list, as it is still refernced ");
f010104e:	83 ec 04             	sub    $0x4,%esp
f0101051:	68 dc 66 10 f0       	push   $0xf01066dc
f0101056:	68 ad 01 00 00       	push   $0x1ad
f010105b:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101060:	e8 db ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
	// pp->pp_link is not NULL.
	else if(!pp) 
f0101065:	85 c0                	test   %eax,%eax
f0101067:	75 17                	jne    f0101080 <page_free+0x42>
	{
	panic("Page cannot be returned to free list as it is Null");
f0101069:	83 ec 04             	sub    $0x4,%esp
f010106c:	68 1c 67 10 f0       	push   $0xf010671c
f0101071:	68 b4 01 00 00       	push   $0x1b4
f0101076:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010107b:	e8 c0 ef ff ff       	call   f0100040 <_panic>
	return;
	}
	
       else{
	pp->pp_link = page_free_list;
f0101080:	8b 15 64 d2 1d f0    	mov    0xf01dd264,%edx
f0101086:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101088:	a3 64 d2 1d f0       	mov    %eax,0xf01dd264
	}


}
f010108d:	c9                   	leave  
f010108e:	c3                   	ret    

f010108f <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010108f:	55                   	push   %ebp
f0101090:	89 e5                	mov    %esp,%ebp
f0101092:	83 ec 08             	sub    $0x8,%esp
f0101095:	8b 55 08             	mov    0x8(%ebp),%edx
	if (--pp->pp_ref == 0)
f0101098:	0f b7 42 04          	movzwl 0x4(%edx),%eax
f010109c:	83 e8 01             	sub    $0x1,%eax
f010109f:	66 89 42 04          	mov    %ax,0x4(%edx)
f01010a3:	66 85 c0             	test   %ax,%ax
f01010a6:	75 0c                	jne    f01010b4 <page_decref+0x25>
		page_free(pp);
f01010a8:	83 ec 0c             	sub    $0xc,%esp
f01010ab:	52                   	push   %edx
f01010ac:	e8 8d ff ff ff       	call   f010103e <page_free>
f01010b1:	83 c4 10             	add    $0x10,%esp
}
f01010b4:	c9                   	leave  
f01010b5:	c3                   	ret    

f01010b6 <pgdir_walk>:
// table and page directory entries.
//

pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01010b6:	55                   	push   %ebp
f01010b7:	89 e5                	mov    %esp,%ebp
f01010b9:	57                   	push   %edi
f01010ba:	56                   	push   %esi
f01010bb:	53                   	push   %ebx
f01010bc:	83 ec 0c             	sub    $0xc,%esp
	pte_t *pgTab;  //Page Table index variable

	//To find the index from the pgdir we need to get the MS 10 bits,
	//We get the MS 10bits of the virtual address by using PDX function (found in inc/mmu.h ) 
	//#define PDX(la)		((((uintptr_t) (la)) >> PDXSHIFT) & 0x3FF)
	pgDir = &pgdir[PDX(va)];
f01010bf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01010c2:	c1 ee 16             	shr    $0x16,%esi
f01010c5:	c1 e6 02             	shl    $0x2,%esi
f01010c8:	03 75 08             	add    0x8(%ebp),%esi

	// Check if page is present, PTE_P = 0x1 means page present  
	if (*pgDir & PTE_P)  {
f01010cb:	8b 1e                	mov    (%esi),%ebx
f01010cd:	f6 c3 01             	test   $0x1,%bl
f01010d0:	74 30                	je     f0101102 <pgdir_walk+0x4c>
		//page table entry to get to the final address translation. Now using the pgDir we can use the 
		//PTE_ADDR(pde) function to get the upper 20 bits, but this function returns a physical address. 
		//Since the kernel requires a virtual address, we can use the function KADDR to get the virtual 
		//address.
		
		pgTab = (pte_t*) KADDR(PTE_ADDR(*pgDir));
f01010d2:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010d8:	89 d8                	mov    %ebx,%eax
f01010da:	c1 e8 0c             	shr    $0xc,%eax
f01010dd:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f01010e3:	72 15                	jb     f01010fa <pgdir_walk+0x44>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01010e5:	53                   	push   %ebx
f01010e6:	68 24 60 10 f0       	push   $0xf0106024
f01010eb:	68 f5 01 00 00       	push   $0x1f5
f01010f0:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01010f5:	e8 46 ef ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01010fa:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
f0101100:	eb 7c                	jmp    f010117e <pgdir_walk+0xc8>
	//If page is not present 
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
f0101102:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101106:	0f 84 81 00 00 00    	je     f010118d <pgdir_walk+0xd7>
f010110c:	83 ec 0c             	sub    $0xc,%esp
f010110f:	68 00 10 00 00       	push   $0x1000
f0101114:	e8 af fe ff ff       	call   f0100fc8 <page_alloc>
f0101119:	89 c7                	mov    %eax,%edi
f010111b:	83 c4 10             	add    $0x10,%esp
f010111e:	85 c0                	test   %eax,%eax
f0101120:	74 72                	je     f0101194 <pgdir_walk+0xde>
			return 0;
		}

		newPage->pp_ref++;  //Increment the ref pointer of the page 
f0101122:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101127:	89 c3                	mov    %eax,%ebx
f0101129:	2b 1d d0 de 1d f0    	sub    0xf01dded0,%ebx
f010112f:	c1 fb 03             	sar    $0x3,%ebx
f0101132:	c1 e3 0c             	shl    $0xc,%ebx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101135:	89 d8                	mov    %ebx,%eax
f0101137:	c1 e8 0c             	shr    $0xc,%eax
f010113a:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f0101140:	72 12                	jb     f0101154 <pgdir_walk+0x9e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101142:	53                   	push   %ebx
f0101143:	68 24 60 10 f0       	push   $0xf0106024
f0101148:	6a 58                	push   $0x58
f010114a:	68 c1 6f 10 f0       	push   $0xf0106fc1
f010114f:	e8 ec ee ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101154:	81 eb 00 00 00 10    	sub    $0x10000000,%ebx
		//Now this section creates the bindings and updates all the flags 
		//for relevant use of the page.
		
		//First create a link on the pgTab wrt to the new page
		pgTab = (pte_t*)page2kva(newPage); // this function gets the virtual address of the new page
		memset (pgTab, 0, PGSIZE); //Clear the entire page
f010115a:	83 ec 04             	sub    $0x4,%esp
f010115d:	68 00 10 00 00       	push   $0x1000
f0101162:	6a 00                	push   $0x0
f0101164:	53                   	push   %ebx
f0101165:	e8 b9 41 00 00       	call   f0105323 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010116a:	2b 3d d0 de 1d f0    	sub    0xf01dded0,%edi
f0101170:	c1 ff 03             	sar    $0x3,%edi
f0101173:	c1 e7 0c             	shl    $0xc,%edi

		//Page Table, pgTab contains the virtual address , now we need to set the permission bits.
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
f0101176:	83 cf 07             	or     $0x7,%edi
f0101179:	89 3e                	mov    %edi,(%esi)
f010117b:	83 c4 10             	add    $0x10,%esp
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
f010117e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101181:	c1 e8 0a             	shr    $0xa,%eax
f0101184:	25 fc 0f 00 00       	and    $0xffc,%eax
f0101189:	01 d8                	add    %ebx,%eax
f010118b:	eb 0c                	jmp    f0101199 <pgdir_walk+0xe3>
	else{
		struct PageInfo *newPage; // Create a holder for a new page

		//if Create = false or page_alloc returns false , then return null.
 		if(!create || !(newPage = page_alloc(PGSIZE))){
			return 0;
f010118d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101192:	eb 05                	jmp    f0101199 <pgdir_walk+0xe3>
f0101194:	b8 00 00 00 00       	mov    $0x0,%eax
		//The page directory entry contains the 20 bit physical address and also the permission bits,
		//We can set better permissive bits here.
		*pgDir = page2pa(newPage)| PTE_P | PTE_W | PTE_U;  // Set present, writable and user.
	}
	return &pgTab[PTX(va)];	//Return the final virtual address of the page table entry.
}
f0101199:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010119c:	5b                   	pop    %ebx
f010119d:	5e                   	pop    %esi
f010119e:	5f                   	pop    %edi
f010119f:	5d                   	pop    %ebp
f01011a0:	c3                   	ret    

f01011a1 <boot_map_region>:
//
// Hint: the TA solution uses pgdir_walk

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01011a1:	55                   	push   %ebp
f01011a2:	89 e5                	mov    %esp,%ebp
f01011a4:	57                   	push   %edi
f01011a5:	56                   	push   %esi
f01011a6:	53                   	push   %ebx
f01011a7:	83 ec 1c             	sub    $0x1c,%esp
f01011aa:	89 45 e0             	mov    %eax,-0x20(%ebp)
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011ad:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
f01011b3:	8b 45 08             	mov    0x8(%ebp),%eax
f01011b6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
	size = ROUNDUP(size, PGSIZE); 
f01011bb:	8d b9 ff 0f 00 00    	lea    0xfff(%ecx),%edi
f01011c1:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi

static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	pte_t *pgTbEnt; // Placeholder variable
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
f01011c7:	89 d3                	mov    %edx,%ebx
f01011c9:	29 d0                	sub    %edx,%eax
f01011cb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011ce:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011d1:	83 c8 01             	or     $0x1,%eax
f01011d4:	89 45 dc             	mov    %eax,-0x24(%ebp)
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f01011d7:	eb 3d                	jmp    f0101216 <boot_map_region+0x75>
		if (!(pgTbEnt = pgdir_walk(pgdir, (const void*)vaBegin, 1))){
f01011d9:	83 ec 04             	sub    $0x4,%esp
f01011dc:	6a 01                	push   $0x1
f01011de:	53                   	push   %ebx
f01011df:	ff 75 e0             	pushl  -0x20(%ebp)
f01011e2:	e8 cf fe ff ff       	call   f01010b6 <pgdir_walk>
f01011e7:	83 c4 10             	add    $0x10,%esp
f01011ea:	85 c0                	test   %eax,%eax
f01011ec:	75 17                	jne    f0101205 <boot_map_region+0x64>
			panic("Cannot find page for the page table entry, from boot_map_region function");
f01011ee:	83 ec 04             	sub    $0x4,%esp
f01011f1:	68 50 67 10 f0       	push   $0xf0106750
f01011f6:	68 2b 02 00 00       	push   $0x22b
f01011fb:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101200:	e8 3b ee ff ff       	call   f0100040 <_panic>
		}
		//if (*pgTbEnt & PTE_P)
		//	panic("Page is already mapped");
		
		
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
f0101205:	0b 75 dc             	or     -0x24(%ebp),%esi
f0101208:	89 30                	mov    %esi,(%eax)
		vaBegin += PGSIZE;
f010120a:	81 c3 00 10 00 00    	add    $0x1000,%ebx
		paBegin += PGSIZE; 
		size -= PGSIZE;
f0101210:	81 ef 00 10 00 00    	sub    $0x1000,%edi
f0101216:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101219:	8d 34 18             	lea    (%eax,%ebx,1),%esi
	uintptr_t vaBegin = ROUNDDOWN(va, PGSIZE);  //Virtual address pointer 
	uintptr_t paBegin = ROUNDDOWN(pa, PGSIZE);  //Virtual address pointer for the physical address pointer
	size = ROUNDUP(size, PGSIZE); 

	//While size is not 0
	while(size) {
f010121c:	85 ff                	test   %edi,%edi
f010121e:	75 b9                	jne    f01011d9 <boot_map_region+0x38>
		*pgTbEnt = paBegin | perm | PTE_P;   //assign the flags
		vaBegin += PGSIZE;
		paBegin += PGSIZE; 
		size -= PGSIZE;
	} 	
}
f0101220:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0101223:	5b                   	pop    %ebx
f0101224:	5e                   	pop    %esi
f0101225:	5f                   	pop    %edi
f0101226:	5d                   	pop    %ebp
f0101227:	c3                   	ret    

f0101228 <page_lookup>:
// Hint: the TA solution uses pgdir_walk and pa2page.
//

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101228:	55                   	push   %ebp
f0101229:	89 e5                	mov    %esp,%ebp
f010122b:	53                   	push   %ebx
f010122c:	83 ec 08             	sub    $0x8,%esp
f010122f:	8b 5d 10             	mov    0x10(%ebp),%ebx
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
	pgTbEty = pgdir_walk(pgdir, va, 0);
f0101232:	6a 00                	push   $0x0
f0101234:	ff 75 0c             	pushl  0xc(%ebp)
f0101237:	ff 75 08             	pushl  0x8(%ebp)
f010123a:	e8 77 fe ff ff       	call   f01010b6 <pgdir_walk>
f010123f:	89 c1                	mov    %eax,%ecx
	if (pgTbEty && (*pgTbEty & PTE_P)) {
f0101241:	83 c4 10             	add    $0x10,%esp
f0101244:	85 c0                	test   %eax,%eax
f0101246:	74 1a                	je     f0101262 <page_lookup+0x3a>
f0101248:	8b 10                	mov    (%eax),%edx
f010124a:	f6 c2 01             	test   $0x1,%dl
f010124d:	74 1a                	je     f0101269 <page_lookup+0x41>
		ret = pages + (PTE_ADDR(*pgTbEty) >> PTXSHIFT);
f010124f:	c1 ea 0c             	shr    $0xc,%edx
f0101252:	a1 d0 de 1d f0       	mov    0xf01dded0,%eax
f0101257:	8d 04 d0             	lea    (%eax,%edx,8),%eax
		if (pte_store) {
f010125a:	85 db                	test   %ebx,%ebx
f010125c:	74 10                	je     f010126e <page_lookup+0x46>
			*pte_store = pgTbEty;
f010125e:	89 0b                	mov    %ecx,(%ebx)
f0101260:	eb 0c                	jmp    f010126e <page_lookup+0x46>

struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
	pte_t *pgTbEty;
	struct PageInfo* ret = NULL;
f0101262:	b8 00 00 00 00       	mov    $0x0,%eax
f0101267:	eb 05                	jmp    f010126e <page_lookup+0x46>
f0101269:	b8 00 00 00 00       	mov    $0x0,%eax
		if (pte_store) {
			*pte_store = pgTbEty;
		}
	}
	return ret;
}
f010126e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0101271:	c9                   	leave  
f0101272:	c3                   	ret    

f0101273 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101273:	55                   	push   %ebp
f0101274:	89 e5                	mov    %esp,%ebp
f0101276:	83 ec 08             	sub    $0x8,%esp
	// Flush the entry only if we're modifying the current address space.
	if (!curenv || curenv->env_pgdir == pgdir)
f0101279:	e8 c9 46 00 00       	call   f0105947 <cpunum>
f010127e:	6b c0 74             	imul   $0x74,%eax,%eax
f0101281:	83 b8 48 e0 1d f0 00 	cmpl   $0x0,-0xfe21fb8(%eax)
f0101288:	74 16                	je     f01012a0 <tlb_invalidate+0x2d>
f010128a:	e8 b8 46 00 00       	call   f0105947 <cpunum>
f010128f:	6b c0 74             	imul   $0x74,%eax,%eax
f0101292:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0101298:	8b 55 08             	mov    0x8(%ebp),%edx
f010129b:	39 50 60             	cmp    %edx,0x60(%eax)
f010129e:	75 06                	jne    f01012a6 <tlb_invalidate+0x33>
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f01012a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012a3:	0f 01 38             	invlpg (%eax)
		invlpg(va);
}
f01012a6:	c9                   	leave  
f01012a7:	c3                   	ret    

f01012a8 <page_remove>:
// 	tlb_invalidate, and page_decref.
//

void
page_remove(pde_t *pgdir, void *va)
{
f01012a8:	55                   	push   %ebp
f01012a9:	89 e5                	mov    %esp,%ebp
f01012ab:	56                   	push   %esi
f01012ac:	53                   	push   %ebx
f01012ad:	83 ec 14             	sub    $0x14,%esp
f01012b0:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01012b3:	8b 75 0c             	mov    0xc(%ebp),%esi
	pte_t *pte;
	struct PageInfo *remPage = 0;
	if (!(remPage = page_lookup(pgdir, va, &pte))) {
f01012b6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01012b9:	50                   	push   %eax
f01012ba:	56                   	push   %esi
f01012bb:	53                   	push   %ebx
f01012bc:	e8 67 ff ff ff       	call   f0101228 <page_lookup>
f01012c1:	83 c4 10             	add    $0x10,%esp
f01012c4:	85 c0                	test   %eax,%eax
f01012c6:	74 1f                	je     f01012e7 <page_remove+0x3f>
		return;
	}
	page_decref(remPage);
f01012c8:	83 ec 0c             	sub    $0xc,%esp
f01012cb:	50                   	push   %eax
f01012cc:	e8 be fd ff ff       	call   f010108f <page_decref>
	*pte = 0;
f01012d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01012d4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	tlb_invalidate(pgdir, va);
f01012da:	83 c4 08             	add    $0x8,%esp
f01012dd:	56                   	push   %esi
f01012de:	53                   	push   %ebx
f01012df:	e8 8f ff ff ff       	call   f0101273 <tlb_invalidate>
f01012e4:	83 c4 10             	add    $0x10,%esp
}
f01012e7:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01012ea:	5b                   	pop    %ebx
f01012eb:	5e                   	pop    %esi
f01012ec:	5d                   	pop    %ebp
f01012ed:	c3                   	ret    

f01012ee <page_insert>:
// and page2pa.
//

int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01012ee:	55                   	push   %ebp
f01012ef:	89 e5                	mov    %esp,%ebp
f01012f1:	57                   	push   %edi
f01012f2:	56                   	push   %esi
f01012f3:	53                   	push   %ebx
f01012f4:	83 ec 10             	sub    $0x10,%esp
f01012f7:	8b 75 0c             	mov    0xc(%ebp),%esi
f01012fa:	8b 7d 10             	mov    0x10(%ebp),%edi
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
f01012fd:	6a 01                	push   $0x1
f01012ff:	57                   	push   %edi
f0101300:	ff 75 08             	pushl  0x8(%ebp)
f0101303:	e8 ae fd ff ff       	call   f01010b6 <pgdir_walk>
f0101308:	89 c3                	mov    %eax,%ebx
	
	if (!pte){
f010130a:	83 c4 10             	add    $0x10,%esp
f010130d:	85 c0                	test   %eax,%eax
f010130f:	0f 84 85 00 00 00    	je     f010139a <page_insert+0xac>
		return -E_NO_MEM; //Page table could not be allocated	
	}

	if (*pte & PTE_P){    //if page is already present
f0101315:	8b 00                	mov    (%eax),%eax
f0101317:	a8 01                	test   $0x1,%al
f0101319:	74 5b                	je     f0101376 <page_insert+0x88>
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
f010131b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101320:	89 f2                	mov    %esi,%edx
f0101322:	2b 15 d0 de 1d f0    	sub    0xf01dded0,%edx
f0101328:	c1 fa 03             	sar    $0x3,%edx
f010132b:	c1 e2 0c             	shl    $0xc,%edx
f010132e:	39 d0                	cmp    %edx,%eax
f0101330:	75 11                	jne    f0101343 <page_insert+0x55>
f0101332:	8b 55 14             	mov    0x14(%ebp),%edx
f0101335:	83 ca 01             	or     $0x1,%edx
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
f0101338:	09 d0                	or     %edx,%eax
f010133a:	89 03                	mov    %eax,(%ebx)
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
			pp->pp_ref ++;  //incremnt the page reference
		}
		return 0;
f010133c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101341:	eb 5c                	jmp    f010139f <page_insert+0xb1>
	if (*pte & PTE_P){    //if page is already present
		if (PTE_ADDR(*pte) == page2pa(pp)){            //Corner-case, if pte is the same mapped pp to the same 
			*pte = page2pa(pp) | PTE_P | perm;   //va, just update the permissions on that page 
		}
		else{ 		// If there is already a page allocated to the VA, remove that page link 
			page_remove(pgdir, va);  // REmove the page 
f0101343:	83 ec 08             	sub    $0x8,%esp
f0101346:	57                   	push   %edi
f0101347:	ff 75 08             	pushl  0x8(%ebp)
f010134a:	e8 59 ff ff ff       	call   f01012a8 <page_remove>
f010134f:	8b 55 14             	mov    0x14(%ebp),%edx
f0101352:	83 ca 01             	or     $0x1,%edx
f0101355:	89 f0                	mov    %esi,%eax
f0101357:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f010135d:	c1 f8 03             	sar    $0x3,%eax
f0101360:	c1 e0 0c             	shl    $0xc,%eax
			*pte = page2pa(pp) | PTE_P|perm; // Allocate the permissions
f0101363:	09 d0                	or     %edx,%eax
f0101365:	89 03                	mov    %eax,(%ebx)
			pp->pp_ref ++;  //incremnt the page reference
f0101367:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
f010136c:	83 c4 10             	add    $0x10,%esp
		}
		return 0;
f010136f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101374:	eb 29                	jmp    f010139f <page_insert+0xb1>
f0101376:	8b 55 14             	mov    0x14(%ebp),%edx
f0101379:	83 ca 01             	or     $0x1,%edx
f010137c:	89 f0                	mov    %esi,%eax
f010137e:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0101384:	c1 f8 03             	sar    $0x3,%eax
f0101387:	c1 e0 0c             	shl    $0xc,%eax
	}	
	else{   // if page is not present
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
f010138a:	09 d0                	or     %edx,%eax
f010138c:	89 03                	mov    %eax,(%ebx)
		pp->pp_ref ++; // increment the page reference count	     
f010138e:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	}
	return 0;
f0101393:	b8 00 00 00 00       	mov    $0x0,%eax
f0101398:	eb 05                	jmp    f010139f <page_insert+0xb1>
{
	pte_t *pte; //Initalize a page table entry variable
	pte = pgdir_walk(pgdir, va, 1);
	
	if (!pte){
		return -E_NO_MEM; //Page table could not be allocated	
f010139a:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
		*pte = page2pa(pp)|PTE_P |perm; // Mark the page as present
		pp->pp_ref ++; // increment the page reference count	     
	}
	return 0;

}
f010139f:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01013a2:	5b                   	pop    %ebx
f01013a3:	5e                   	pop    %esi
f01013a4:	5f                   	pop    %edi
f01013a5:	5d                   	pop    %ebp
f01013a6:	c3                   	ret    

f01013a7 <mmio_map_region>:
// location.  Return the base of the reserved region.  size does *not*
// have to be multiple of PGSIZE.
//
void *
mmio_map_region(physaddr_t pa, size_t size)
{
f01013a7:	55                   	push   %ebp
f01013a8:	89 e5                	mov    %esp,%ebp
f01013aa:	56                   	push   %esi
f01013ab:	53                   	push   %ebx
	//
	// Your code here:
	//panic("mmio_map_region not implemented");
	
	//Since we modify the value of the pointer, copy the value of the pointer into some variable
	void* save = (void*) base;  // USe a pointer to void, just to store the first address
f01013ac:	8b 35 00 03 12 f0    	mov    0xf0120300,%esi
	
	//Roundup size to pgsize
	size = ROUNDUP(size,PGSIZE);
f01013b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01013b5:	8d 98 ff 0f 00 00    	lea    0xfff(%eax),%ebx
f01013bb:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	
	//Use bootmap region to map the given region
	boot_map_region(kern_pgdir, base, size, pa, PTE_W | PTE_P |PTE_PCD|PTE_PWT);
f01013c1:	83 ec 08             	sub    $0x8,%esp
f01013c4:	6a 1b                	push   $0x1b
f01013c6:	ff 75 08             	pushl  0x8(%ebp)
f01013c9:	89 d9                	mov    %ebx,%ecx
f01013cb:	89 f2                	mov    %esi,%edx
f01013cd:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f01013d2:	e8 ca fd ff ff       	call   f01011a1 <boot_map_region>
	
	//reserving size bytes of memory
	base += size;
f01013d7:	01 1d 00 03 12 f0    	add    %ebx,0xf0120300
	
	return save; 
	
}
f01013dd:	89 f0                	mov    %esi,%eax
f01013df:	8d 65 f8             	lea    -0x8(%ebp),%esp
f01013e2:	5b                   	pop    %ebx
f01013e3:	5e                   	pop    %esi
f01013e4:	5d                   	pop    %ebp
f01013e5:	c3                   	ret    

f01013e6 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01013e6:	55                   	push   %ebp
f01013e7:	89 e5                	mov    %esp,%ebp
f01013e9:	57                   	push   %edi
f01013ea:	56                   	push   %esi
f01013eb:	53                   	push   %ebx
f01013ec:	83 ec 48             	sub    $0x48,%esp
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01013ef:	6a 15                	push   $0x15
f01013f1:	e8 b8 22 00 00       	call   f01036ae <mc146818_read>
f01013f6:	89 c3                	mov    %eax,%ebx
f01013f8:	c7 04 24 16 00 00 00 	movl   $0x16,(%esp)
f01013ff:	e8 aa 22 00 00       	call   f01036ae <mc146818_read>
f0101404:	c1 e0 08             	shl    $0x8,%eax
f0101407:	09 d8                	or     %ebx,%eax
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101409:	c1 e0 0a             	shl    $0xa,%eax
f010140c:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101412:	85 c0                	test   %eax,%eax
f0101414:	0f 48 c2             	cmovs  %edx,%eax
f0101417:	c1 f8 0c             	sar    $0xc,%eax
f010141a:	a3 68 d2 1d f0       	mov    %eax,0xf01dd268
// --------------------------------------------------------------

static int
nvram_read(int r)
{
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010141f:	c7 04 24 17 00 00 00 	movl   $0x17,(%esp)
f0101426:	e8 83 22 00 00       	call   f01036ae <mc146818_read>
f010142b:	89 c3                	mov    %eax,%ebx
f010142d:	c7 04 24 18 00 00 00 	movl   $0x18,(%esp)
f0101434:	e8 75 22 00 00       	call   f01036ae <mc146818_read>
f0101439:	c1 e0 08             	shl    $0x8,%eax
f010143c:	09 d8                	or     %ebx,%eax
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f010143e:	c1 e0 0a             	shl    $0xa,%eax
f0101441:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101447:	83 c4 10             	add    $0x10,%esp
f010144a:	85 c0                	test   %eax,%eax
f010144c:	0f 48 c2             	cmovs  %edx,%eax
f010144f:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101452:	85 c0                	test   %eax,%eax
f0101454:	74 0e                	je     f0101464 <mem_init+0x7e>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101456:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010145c:	89 15 c8 de 1d f0    	mov    %edx,0xf01ddec8
f0101462:	eb 0c                	jmp    f0101470 <mem_init+0x8a>
	else
		npages = npages_basemem;
f0101464:	8b 15 68 d2 1d f0    	mov    0xf01dd268,%edx
f010146a:	89 15 c8 de 1d f0    	mov    %edx,0xf01ddec8

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101470:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101473:	c1 e8 0a             	shr    $0xa,%eax
f0101476:	50                   	push   %eax
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101477:	a1 68 d2 1d f0       	mov    0xf01dd268,%eax
f010147c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010147f:	c1 e8 0a             	shr    $0xa,%eax
f0101482:	50                   	push   %eax
		npages * PGSIZE / 1024,
f0101483:	a1 c8 de 1d f0       	mov    0xf01ddec8,%eax
f0101488:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010148b:	c1 e8 0a             	shr    $0xa,%eax
f010148e:	50                   	push   %eax
f010148f:	68 9c 67 10 f0       	push   $0xf010679c
f0101494:	e8 76 23 00 00       	call   f010380f <cprintf>
	// Remove this line when you're ready to test this function.
	//panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101499:	b8 00 10 00 00       	mov    $0x1000,%eax
f010149e:	e8 0e f6 ff ff       	call   f0100ab1 <boot_alloc>
f01014a3:	a3 cc de 1d f0       	mov    %eax,0xf01ddecc
	memset(kern_pgdir, 0, PGSIZE);
f01014a8:	83 c4 0c             	add    $0xc,%esp
f01014ab:	68 00 10 00 00       	push   $0x1000
f01014b0:	6a 00                	push   $0x0
f01014b2:	50                   	push   %eax
f01014b3:	e8 6b 3e 00 00       	call   f0105323 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014b8:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01014bd:	83 c4 10             	add    $0x10,%esp
f01014c0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014c5:	77 15                	ja     f01014dc <mem_init+0xf6>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014c7:	50                   	push   %eax
f01014c8:	68 48 60 10 f0       	push   $0xf0106048
f01014cd:	68 98 00 00 00       	push   $0x98
f01014d2:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01014d7:	e8 64 eb ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01014dc:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01014e2:	83 ca 05             	or     $0x5,%edx
f01014e5:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// array.  'npages' is the number of physical pages in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.

	//This line creates a boot allocation of memory of the size of number of pages
	// mulitplied by size of struct Pageinfo to store metadata of the page. 
	pages = boot_alloc(sizeof(struct PageInfo) * npages);   
f01014eb:	a1 c8 de 1d f0       	mov    0xf01ddec8,%eax
f01014f0:	c1 e0 03             	shl    $0x3,%eax
f01014f3:	e8 b9 f5 ff ff       	call   f0100ab1 <boot_alloc>
f01014f8:	a3 d0 de 1d f0       	mov    %eax,0xf01dded0
	memset(pages, 0, sizeof(struct PageInfo) * npages); //Clear the memory 
f01014fd:	83 ec 04             	sub    $0x4,%esp
f0101500:	8b 0d c8 de 1d f0    	mov    0xf01ddec8,%ecx
f0101506:	8d 14 cd 00 00 00 00 	lea    0x0(,%ecx,8),%edx
f010150d:	52                   	push   %edx
f010150e:	6a 00                	push   $0x0
f0101510:	50                   	push   %eax
f0101511:	e8 0d 3e 00 00       	call   f0105323 <memset>
	// The kernel uses this array to keep track of environment array:
	// 'NENV' is the number of Environments in memory.  Use memset
	// to initialize all fields of each struct PageInfo to 0.
	// Make 'envs' point to an array of size 'NENV' of 'struct Env'.
	// LAB 3: Your code here.
	envs = boot_alloc(sizeof(struct Env)*NENV);
f0101516:	b8 00 f0 01 00       	mov    $0x1f000,%eax
f010151b:	e8 91 f5 ff ff       	call   f0100ab1 <boot_alloc>
f0101520:	a3 6c d2 1d f0       	mov    %eax,0xf01dd26c
	memset(envs,0,sizeof(struct Env)*NENV);
f0101525:	83 c4 0c             	add    $0xc,%esp
f0101528:	68 00 f0 01 00       	push   $0x1f000
f010152d:	6a 00                	push   $0x0
f010152f:	50                   	push   %eax
f0101530:	e8 ee 3d 00 00       	call   f0105323 <memset>
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101535:	e8 03 f9 ff ff       	call   f0100e3d <page_init>

	check_page_free_list(1);
f010153a:	b8 01 00 00 00       	mov    $0x1,%eax
f010153f:	e8 e3 f5 ff ff       	call   f0100b27 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101544:	83 c4 10             	add    $0x10,%esp
f0101547:	83 3d d0 de 1d f0 00 	cmpl   $0x0,0xf01dded0
f010154e:	75 17                	jne    f0101567 <mem_init+0x181>
		panic("'pages' is a null pointer!");
f0101550:	83 ec 04             	sub    $0x4,%esp
f0101553:	68 b5 70 10 f0       	push   $0xf01070b5
f0101558:	68 84 03 00 00       	push   $0x384
f010155d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101562:	e8 d9 ea ff ff       	call   f0100040 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101567:	a1 64 d2 1d f0       	mov    0xf01dd264,%eax
f010156c:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101571:	eb 05                	jmp    f0101578 <mem_init+0x192>
		++nfree;
f0101573:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101576:	8b 00                	mov    (%eax),%eax
f0101578:	85 c0                	test   %eax,%eax
f010157a:	75 f7                	jne    f0101573 <mem_init+0x18d>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010157c:	83 ec 0c             	sub    $0xc,%esp
f010157f:	6a 00                	push   $0x0
f0101581:	e8 42 fa ff ff       	call   f0100fc8 <page_alloc>
f0101586:	89 c7                	mov    %eax,%edi
f0101588:	83 c4 10             	add    $0x10,%esp
f010158b:	85 c0                	test   %eax,%eax
f010158d:	75 19                	jne    f01015a8 <mem_init+0x1c2>
f010158f:	68 d0 70 10 f0       	push   $0xf01070d0
f0101594:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101599:	68 8c 03 00 00       	push   $0x38c
f010159e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01015a3:	e8 98 ea ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f01015a8:	83 ec 0c             	sub    $0xc,%esp
f01015ab:	6a 00                	push   $0x0
f01015ad:	e8 16 fa ff ff       	call   f0100fc8 <page_alloc>
f01015b2:	89 c6                	mov    %eax,%esi
f01015b4:	83 c4 10             	add    $0x10,%esp
f01015b7:	85 c0                	test   %eax,%eax
f01015b9:	75 19                	jne    f01015d4 <mem_init+0x1ee>
f01015bb:	68 e6 70 10 f0       	push   $0xf01070e6
f01015c0:	68 db 6f 10 f0       	push   $0xf0106fdb
f01015c5:	68 8d 03 00 00       	push   $0x38d
f01015ca:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01015cf:	e8 6c ea ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01015d4:	83 ec 0c             	sub    $0xc,%esp
f01015d7:	6a 00                	push   $0x0
f01015d9:	e8 ea f9 ff ff       	call   f0100fc8 <page_alloc>
f01015de:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01015e1:	83 c4 10             	add    $0x10,%esp
f01015e4:	85 c0                	test   %eax,%eax
f01015e6:	75 19                	jne    f0101601 <mem_init+0x21b>
f01015e8:	68 fc 70 10 f0       	push   $0xf01070fc
f01015ed:	68 db 6f 10 f0       	push   $0xf0106fdb
f01015f2:	68 8e 03 00 00       	push   $0x38e
f01015f7:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01015fc:	e8 3f ea ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101601:	39 f7                	cmp    %esi,%edi
f0101603:	75 19                	jne    f010161e <mem_init+0x238>
f0101605:	68 12 71 10 f0       	push   $0xf0107112
f010160a:	68 db 6f 10 f0       	push   $0xf0106fdb
f010160f:	68 91 03 00 00       	push   $0x391
f0101614:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101619:	e8 22 ea ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f010161e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101621:	39 c7                	cmp    %eax,%edi
f0101623:	74 04                	je     f0101629 <mem_init+0x243>
f0101625:	39 c6                	cmp    %eax,%esi
f0101627:	75 19                	jne    f0101642 <mem_init+0x25c>
f0101629:	68 d8 67 10 f0       	push   $0xf01067d8
f010162e:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101633:	68 92 03 00 00       	push   $0x392
f0101638:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010163d:	e8 fe e9 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101642:	8b 0d d0 de 1d f0    	mov    0xf01dded0,%ecx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101648:	8b 15 c8 de 1d f0    	mov    0xf01ddec8,%edx
f010164e:	c1 e2 0c             	shl    $0xc,%edx
f0101651:	89 f8                	mov    %edi,%eax
f0101653:	29 c8                	sub    %ecx,%eax
f0101655:	c1 f8 03             	sar    $0x3,%eax
f0101658:	c1 e0 0c             	shl    $0xc,%eax
f010165b:	39 d0                	cmp    %edx,%eax
f010165d:	72 19                	jb     f0101678 <mem_init+0x292>
f010165f:	68 24 71 10 f0       	push   $0xf0107124
f0101664:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101669:	68 93 03 00 00       	push   $0x393
f010166e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101673:	e8 c8 e9 ff ff       	call   f0100040 <_panic>
f0101678:	89 f0                	mov    %esi,%eax
f010167a:	29 c8                	sub    %ecx,%eax
f010167c:	c1 f8 03             	sar    $0x3,%eax
f010167f:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp1) < npages*PGSIZE);
f0101682:	39 c2                	cmp    %eax,%edx
f0101684:	77 19                	ja     f010169f <mem_init+0x2b9>
f0101686:	68 41 71 10 f0       	push   $0xf0107141
f010168b:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101690:	68 94 03 00 00       	push   $0x394
f0101695:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010169a:	e8 a1 e9 ff ff       	call   f0100040 <_panic>
f010169f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01016a2:	29 c8                	sub    %ecx,%eax
f01016a4:	c1 f8 03             	sar    $0x3,%eax
f01016a7:	c1 e0 0c             	shl    $0xc,%eax
	assert(page2pa(pp2) < npages*PGSIZE);
f01016aa:	39 c2                	cmp    %eax,%edx
f01016ac:	77 19                	ja     f01016c7 <mem_init+0x2e1>
f01016ae:	68 5e 71 10 f0       	push   $0xf010715e
f01016b3:	68 db 6f 10 f0       	push   $0xf0106fdb
f01016b8:	68 95 03 00 00       	push   $0x395
f01016bd:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01016c2:	e8 79 e9 ff ff       	call   f0100040 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01016c7:	a1 64 d2 1d f0       	mov    0xf01dd264,%eax
f01016cc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01016cf:	c7 05 64 d2 1d f0 00 	movl   $0x0,0xf01dd264
f01016d6:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01016d9:	83 ec 0c             	sub    $0xc,%esp
f01016dc:	6a 00                	push   $0x0
f01016de:	e8 e5 f8 ff ff       	call   f0100fc8 <page_alloc>
f01016e3:	83 c4 10             	add    $0x10,%esp
f01016e6:	85 c0                	test   %eax,%eax
f01016e8:	74 19                	je     f0101703 <mem_init+0x31d>
f01016ea:	68 7b 71 10 f0       	push   $0xf010717b
f01016ef:	68 db 6f 10 f0       	push   $0xf0106fdb
f01016f4:	68 9c 03 00 00       	push   $0x39c
f01016f9:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01016fe:	e8 3d e9 ff ff       	call   f0100040 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101703:	83 ec 0c             	sub    $0xc,%esp
f0101706:	57                   	push   %edi
f0101707:	e8 32 f9 ff ff       	call   f010103e <page_free>
	page_free(pp1);
f010170c:	89 34 24             	mov    %esi,(%esp)
f010170f:	e8 2a f9 ff ff       	call   f010103e <page_free>
	page_free(pp2);
f0101714:	83 c4 04             	add    $0x4,%esp
f0101717:	ff 75 d4             	pushl  -0x2c(%ebp)
f010171a:	e8 1f f9 ff ff       	call   f010103e <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010171f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101726:	e8 9d f8 ff ff       	call   f0100fc8 <page_alloc>
f010172b:	89 c6                	mov    %eax,%esi
f010172d:	83 c4 10             	add    $0x10,%esp
f0101730:	85 c0                	test   %eax,%eax
f0101732:	75 19                	jne    f010174d <mem_init+0x367>
f0101734:	68 d0 70 10 f0       	push   $0xf01070d0
f0101739:	68 db 6f 10 f0       	push   $0xf0106fdb
f010173e:	68 a3 03 00 00       	push   $0x3a3
f0101743:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101748:	e8 f3 e8 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f010174d:	83 ec 0c             	sub    $0xc,%esp
f0101750:	6a 00                	push   $0x0
f0101752:	e8 71 f8 ff ff       	call   f0100fc8 <page_alloc>
f0101757:	89 c7                	mov    %eax,%edi
f0101759:	83 c4 10             	add    $0x10,%esp
f010175c:	85 c0                	test   %eax,%eax
f010175e:	75 19                	jne    f0101779 <mem_init+0x393>
f0101760:	68 e6 70 10 f0       	push   $0xf01070e6
f0101765:	68 db 6f 10 f0       	push   $0xf0106fdb
f010176a:	68 a4 03 00 00       	push   $0x3a4
f010176f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101774:	e8 c7 e8 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0101779:	83 ec 0c             	sub    $0xc,%esp
f010177c:	6a 00                	push   $0x0
f010177e:	e8 45 f8 ff ff       	call   f0100fc8 <page_alloc>
f0101783:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101786:	83 c4 10             	add    $0x10,%esp
f0101789:	85 c0                	test   %eax,%eax
f010178b:	75 19                	jne    f01017a6 <mem_init+0x3c0>
f010178d:	68 fc 70 10 f0       	push   $0xf01070fc
f0101792:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101797:	68 a5 03 00 00       	push   $0x3a5
f010179c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01017a1:	e8 9a e8 ff ff       	call   f0100040 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01017a6:	39 fe                	cmp    %edi,%esi
f01017a8:	75 19                	jne    f01017c3 <mem_init+0x3dd>
f01017aa:	68 12 71 10 f0       	push   $0xf0107112
f01017af:	68 db 6f 10 f0       	push   $0xf0106fdb
f01017b4:	68 a7 03 00 00       	push   $0x3a7
f01017b9:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01017be:	e8 7d e8 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01017c3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017c6:	39 c6                	cmp    %eax,%esi
f01017c8:	74 04                	je     f01017ce <mem_init+0x3e8>
f01017ca:	39 c7                	cmp    %eax,%edi
f01017cc:	75 19                	jne    f01017e7 <mem_init+0x401>
f01017ce:	68 d8 67 10 f0       	push   $0xf01067d8
f01017d3:	68 db 6f 10 f0       	push   $0xf0106fdb
f01017d8:	68 a8 03 00 00       	push   $0x3a8
f01017dd:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01017e2:	e8 59 e8 ff ff       	call   f0100040 <_panic>
	assert(!page_alloc(0));
f01017e7:	83 ec 0c             	sub    $0xc,%esp
f01017ea:	6a 00                	push   $0x0
f01017ec:	e8 d7 f7 ff ff       	call   f0100fc8 <page_alloc>
f01017f1:	83 c4 10             	add    $0x10,%esp
f01017f4:	85 c0                	test   %eax,%eax
f01017f6:	74 19                	je     f0101811 <mem_init+0x42b>
f01017f8:	68 7b 71 10 f0       	push   $0xf010717b
f01017fd:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101802:	68 a9 03 00 00       	push   $0x3a9
f0101807:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010180c:	e8 2f e8 ff ff       	call   f0100040 <_panic>
f0101811:	89 f0                	mov    %esi,%eax
f0101813:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0101819:	c1 f8 03             	sar    $0x3,%eax
f010181c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010181f:	89 c2                	mov    %eax,%edx
f0101821:	c1 ea 0c             	shr    $0xc,%edx
f0101824:	3b 15 c8 de 1d f0    	cmp    0xf01ddec8,%edx
f010182a:	72 12                	jb     f010183e <mem_init+0x458>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010182c:	50                   	push   %eax
f010182d:	68 24 60 10 f0       	push   $0xf0106024
f0101832:	6a 58                	push   $0x58
f0101834:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0101839:	e8 02 e8 ff ff       	call   f0100040 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f010183e:	83 ec 04             	sub    $0x4,%esp
f0101841:	68 00 10 00 00       	push   $0x1000
f0101846:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0101848:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010184d:	50                   	push   %eax
f010184e:	e8 d0 3a 00 00       	call   f0105323 <memset>
	page_free(pp0);
f0101853:	89 34 24             	mov    %esi,(%esp)
f0101856:	e8 e3 f7 ff ff       	call   f010103e <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010185b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101862:	e8 61 f7 ff ff       	call   f0100fc8 <page_alloc>
f0101867:	83 c4 10             	add    $0x10,%esp
f010186a:	85 c0                	test   %eax,%eax
f010186c:	75 19                	jne    f0101887 <mem_init+0x4a1>
f010186e:	68 8a 71 10 f0       	push   $0xf010718a
f0101873:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101878:	68 ae 03 00 00       	push   $0x3ae
f010187d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101882:	e8 b9 e7 ff ff       	call   f0100040 <_panic>
	assert(pp && pp0 == pp);
f0101887:	39 c6                	cmp    %eax,%esi
f0101889:	74 19                	je     f01018a4 <mem_init+0x4be>
f010188b:	68 a8 71 10 f0       	push   $0xf01071a8
f0101890:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101895:	68 af 03 00 00       	push   $0x3af
f010189a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010189f:	e8 9c e7 ff ff       	call   f0100040 <_panic>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01018a4:	89 f0                	mov    %esi,%eax
f01018a6:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f01018ac:	c1 f8 03             	sar    $0x3,%eax
f01018af:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018b2:	89 c2                	mov    %eax,%edx
f01018b4:	c1 ea 0c             	shr    $0xc,%edx
f01018b7:	3b 15 c8 de 1d f0    	cmp    0xf01ddec8,%edx
f01018bd:	72 12                	jb     f01018d1 <mem_init+0x4eb>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018bf:	50                   	push   %eax
f01018c0:	68 24 60 10 f0       	push   $0xf0106024
f01018c5:	6a 58                	push   $0x58
f01018c7:	68 c1 6f 10 f0       	push   $0xf0106fc1
f01018cc:	e8 6f e7 ff ff       	call   f0100040 <_panic>
f01018d1:	8d 90 00 10 00 f0    	lea    -0xffff000(%eax),%edx
	return (void *)(pa + KERNBASE);
f01018d7:	8d 80 00 00 00 f0    	lea    -0x10000000(%eax),%eax
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
		assert(c[i] == 0);
f01018dd:	80 38 00             	cmpb   $0x0,(%eax)
f01018e0:	74 19                	je     f01018fb <mem_init+0x515>
f01018e2:	68 b8 71 10 f0       	push   $0xf01071b8
f01018e7:	68 db 6f 10 f0       	push   $0xf0106fdb
f01018ec:	68 b2 03 00 00       	push   $0x3b2
f01018f1:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01018f6:	e8 45 e7 ff ff       	call   f0100040 <_panic>
f01018fb:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++)
f01018fe:	39 d0                	cmp    %edx,%eax
f0101900:	75 db                	jne    f01018dd <mem_init+0x4f7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101902:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0101905:	a3 64 d2 1d f0       	mov    %eax,0xf01dd264

	// free the pages we took
	page_free(pp0);
f010190a:	83 ec 0c             	sub    $0xc,%esp
f010190d:	56                   	push   %esi
f010190e:	e8 2b f7 ff ff       	call   f010103e <page_free>
	page_free(pp1);
f0101913:	89 3c 24             	mov    %edi,(%esp)
f0101916:	e8 23 f7 ff ff       	call   f010103e <page_free>
	page_free(pp2);
f010191b:	83 c4 04             	add    $0x4,%esp
f010191e:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101921:	e8 18 f7 ff ff       	call   f010103e <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101926:	a1 64 d2 1d f0       	mov    0xf01dd264,%eax
f010192b:	83 c4 10             	add    $0x10,%esp
f010192e:	eb 05                	jmp    f0101935 <mem_init+0x54f>
		--nfree;
f0101930:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101933:	8b 00                	mov    (%eax),%eax
f0101935:	85 c0                	test   %eax,%eax
f0101937:	75 f7                	jne    f0101930 <mem_init+0x54a>
		--nfree;
	assert(nfree == 0);
f0101939:	85 db                	test   %ebx,%ebx
f010193b:	74 19                	je     f0101956 <mem_init+0x570>
f010193d:	68 c2 71 10 f0       	push   $0xf01071c2
f0101942:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101947:	68 bf 03 00 00       	push   $0x3bf
f010194c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101951:	e8 ea e6 ff ff       	call   f0100040 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101956:	83 ec 0c             	sub    $0xc,%esp
f0101959:	68 f8 67 10 f0       	push   $0xf01067f8
f010195e:	e8 ac 1e 00 00       	call   f010380f <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101963:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010196a:	e8 59 f6 ff ff       	call   f0100fc8 <page_alloc>
f010196f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101972:	83 c4 10             	add    $0x10,%esp
f0101975:	85 c0                	test   %eax,%eax
f0101977:	75 19                	jne    f0101992 <mem_init+0x5ac>
f0101979:	68 d0 70 10 f0       	push   $0xf01070d0
f010197e:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101983:	68 25 04 00 00       	push   $0x425
f0101988:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010198d:	e8 ae e6 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0101992:	83 ec 0c             	sub    $0xc,%esp
f0101995:	6a 00                	push   $0x0
f0101997:	e8 2c f6 ff ff       	call   f0100fc8 <page_alloc>
f010199c:	89 c3                	mov    %eax,%ebx
f010199e:	83 c4 10             	add    $0x10,%esp
f01019a1:	85 c0                	test   %eax,%eax
f01019a3:	75 19                	jne    f01019be <mem_init+0x5d8>
f01019a5:	68 e6 70 10 f0       	push   $0xf01070e6
f01019aa:	68 db 6f 10 f0       	push   $0xf0106fdb
f01019af:	68 26 04 00 00       	push   $0x426
f01019b4:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01019b9:	e8 82 e6 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f01019be:	83 ec 0c             	sub    $0xc,%esp
f01019c1:	6a 00                	push   $0x0
f01019c3:	e8 00 f6 ff ff       	call   f0100fc8 <page_alloc>
f01019c8:	89 c6                	mov    %eax,%esi
f01019ca:	83 c4 10             	add    $0x10,%esp
f01019cd:	85 c0                	test   %eax,%eax
f01019cf:	75 19                	jne    f01019ea <mem_init+0x604>
f01019d1:	68 fc 70 10 f0       	push   $0xf01070fc
f01019d6:	68 db 6f 10 f0       	push   $0xf0106fdb
f01019db:	68 27 04 00 00       	push   $0x427
f01019e0:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01019e5:	e8 56 e6 ff ff       	call   f0100040 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01019ea:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01019ed:	75 19                	jne    f0101a08 <mem_init+0x622>
f01019ef:	68 12 71 10 f0       	push   $0xf0107112
f01019f4:	68 db 6f 10 f0       	push   $0xf0106fdb
f01019f9:	68 2a 04 00 00       	push   $0x42a
f01019fe:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101a03:	e8 38 e6 ff ff       	call   f0100040 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a08:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f0101a0b:	74 04                	je     f0101a11 <mem_init+0x62b>
f0101a0d:	39 c3                	cmp    %eax,%ebx
f0101a0f:	75 19                	jne    f0101a2a <mem_init+0x644>
f0101a11:	68 d8 67 10 f0       	push   $0xf01067d8
f0101a16:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101a1b:	68 2b 04 00 00       	push   $0x42b
f0101a20:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101a25:	e8 16 e6 ff ff       	call   f0100040 <_panic>
	

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101a2a:	a1 64 d2 1d f0       	mov    0xf01dd264,%eax
f0101a2f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101a32:	c7 05 64 d2 1d f0 00 	movl   $0x0,0xf01dd264
f0101a39:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101a3c:	83 ec 0c             	sub    $0xc,%esp
f0101a3f:	6a 00                	push   $0x0
f0101a41:	e8 82 f5 ff ff       	call   f0100fc8 <page_alloc>
f0101a46:	83 c4 10             	add    $0x10,%esp
f0101a49:	85 c0                	test   %eax,%eax
f0101a4b:	74 19                	je     f0101a66 <mem_init+0x680>
f0101a4d:	68 7b 71 10 f0       	push   $0xf010717b
f0101a52:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101a57:	68 33 04 00 00       	push   $0x433
f0101a5c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101a61:	e8 da e5 ff ff       	call   f0100040 <_panic>
	
	
	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101a66:	83 ec 04             	sub    $0x4,%esp
f0101a69:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101a6c:	50                   	push   %eax
f0101a6d:	6a 00                	push   $0x0
f0101a6f:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101a75:	e8 ae f7 ff ff       	call   f0101228 <page_lookup>
f0101a7a:	83 c4 10             	add    $0x10,%esp
f0101a7d:	85 c0                	test   %eax,%eax
f0101a7f:	74 19                	je     f0101a9a <mem_init+0x6b4>
f0101a81:	68 18 68 10 f0       	push   $0xf0106818
f0101a86:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101a8b:	68 37 04 00 00       	push   $0x437
f0101a90:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101a95:	e8 a6 e5 ff ff       	call   f0100040 <_panic>
	
	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101a9a:	6a 02                	push   $0x2
f0101a9c:	6a 00                	push   $0x0
f0101a9e:	53                   	push   %ebx
f0101a9f:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101aa5:	e8 44 f8 ff ff       	call   f01012ee <page_insert>
f0101aaa:	83 c4 10             	add    $0x10,%esp
f0101aad:	85 c0                	test   %eax,%eax
f0101aaf:	78 19                	js     f0101aca <mem_init+0x6e4>
f0101ab1:	68 50 68 10 f0       	push   $0xf0106850
f0101ab6:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101abb:	68 3a 04 00 00       	push   $0x43a
f0101ac0:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101ac5:	e8 76 e5 ff ff       	call   f0100040 <_panic>
	
	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101aca:	83 ec 0c             	sub    $0xc,%esp
f0101acd:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101ad0:	e8 69 f5 ff ff       	call   f010103e <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101ad5:	6a 02                	push   $0x2
f0101ad7:	6a 00                	push   $0x0
f0101ad9:	53                   	push   %ebx
f0101ada:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101ae0:	e8 09 f8 ff ff       	call   f01012ee <page_insert>
f0101ae5:	83 c4 20             	add    $0x20,%esp
f0101ae8:	85 c0                	test   %eax,%eax
f0101aea:	74 19                	je     f0101b05 <mem_init+0x71f>
f0101aec:	68 80 68 10 f0       	push   $0xf0106880
f0101af1:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101af6:	68 3e 04 00 00       	push   $0x43e
f0101afb:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101b00:	e8 3b e5 ff ff       	call   f0100040 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101b05:	8b 3d cc de 1d f0    	mov    0xf01ddecc,%edi
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101b0b:	a1 d0 de 1d f0       	mov    0xf01dded0,%eax
f0101b10:	89 c1                	mov    %eax,%ecx
f0101b12:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101b15:	8b 17                	mov    (%edi),%edx
f0101b17:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101b1d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b20:	29 c8                	sub    %ecx,%eax
f0101b22:	c1 f8 03             	sar    $0x3,%eax
f0101b25:	c1 e0 0c             	shl    $0xc,%eax
f0101b28:	39 c2                	cmp    %eax,%edx
f0101b2a:	74 19                	je     f0101b45 <mem_init+0x75f>
f0101b2c:	68 b0 68 10 f0       	push   $0xf01068b0
f0101b31:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101b36:	68 3f 04 00 00       	push   $0x43f
f0101b3b:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101b40:	e8 fb e4 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101b45:	ba 00 00 00 00       	mov    $0x0,%edx
f0101b4a:	89 f8                	mov    %edi,%eax
f0101b4c:	e8 fc ee ff ff       	call   f0100a4d <check_va2pa>
f0101b51:	89 da                	mov    %ebx,%edx
f0101b53:	2b 55 cc             	sub    -0x34(%ebp),%edx
f0101b56:	c1 fa 03             	sar    $0x3,%edx
f0101b59:	c1 e2 0c             	shl    $0xc,%edx
f0101b5c:	39 d0                	cmp    %edx,%eax
f0101b5e:	74 19                	je     f0101b79 <mem_init+0x793>
f0101b60:	68 d8 68 10 f0       	push   $0xf01068d8
f0101b65:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101b6a:	68 40 04 00 00       	push   $0x440
f0101b6f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101b74:	e8 c7 e4 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0101b79:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b7e:	74 19                	je     f0101b99 <mem_init+0x7b3>
f0101b80:	68 cd 71 10 f0       	push   $0xf01071cd
f0101b85:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101b8a:	68 41 04 00 00       	push   $0x441
f0101b8f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101b94:	e8 a7 e4 ff ff       	call   f0100040 <_panic>
	assert(pp0->pp_ref == 1);
f0101b99:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b9c:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ba1:	74 19                	je     f0101bbc <mem_init+0x7d6>
f0101ba3:	68 de 71 10 f0       	push   $0xf01071de
f0101ba8:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101bad:	68 42 04 00 00       	push   $0x442
f0101bb2:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101bb7:	e8 84 e4 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bbc:	6a 02                	push   $0x2
f0101bbe:	68 00 10 00 00       	push   $0x1000
f0101bc3:	56                   	push   %esi
f0101bc4:	57                   	push   %edi
f0101bc5:	e8 24 f7 ff ff       	call   f01012ee <page_insert>
f0101bca:	83 c4 10             	add    $0x10,%esp
f0101bcd:	85 c0                	test   %eax,%eax
f0101bcf:	74 19                	je     f0101bea <mem_init+0x804>
f0101bd1:	68 08 69 10 f0       	push   $0xf0106908
f0101bd6:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101bdb:	68 45 04 00 00       	push   $0x445
f0101be0:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101be5:	e8 56 e4 ff ff       	call   f0100040 <_panic>

	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101bea:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101bef:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f0101bf4:	e8 54 ee ff ff       	call   f0100a4d <check_va2pa>
f0101bf9:	89 f2                	mov    %esi,%edx
f0101bfb:	2b 15 d0 de 1d f0    	sub    0xf01dded0,%edx
f0101c01:	c1 fa 03             	sar    $0x3,%edx
f0101c04:	c1 e2 0c             	shl    $0xc,%edx
f0101c07:	39 d0                	cmp    %edx,%eax
f0101c09:	74 19                	je     f0101c24 <mem_init+0x83e>
f0101c0b:	68 44 69 10 f0       	push   $0xf0106944
f0101c10:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101c15:	68 47 04 00 00       	push   $0x447
f0101c1a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101c1f:	e8 1c e4 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101c24:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101c29:	74 19                	je     f0101c44 <mem_init+0x85e>
f0101c2b:	68 ef 71 10 f0       	push   $0xf01071ef
f0101c30:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101c35:	68 48 04 00 00       	push   $0x448
f0101c3a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101c3f:	e8 fc e3 ff ff       	call   f0100040 <_panic>
	
	// should be no free memory
	assert(!page_alloc(0));
f0101c44:	83 ec 0c             	sub    $0xc,%esp
f0101c47:	6a 00                	push   $0x0
f0101c49:	e8 7a f3 ff ff       	call   f0100fc8 <page_alloc>
f0101c4e:	83 c4 10             	add    $0x10,%esp
f0101c51:	85 c0                	test   %eax,%eax
f0101c53:	74 19                	je     f0101c6e <mem_init+0x888>
f0101c55:	68 7b 71 10 f0       	push   $0xf010717b
f0101c5a:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101c5f:	68 4b 04 00 00       	push   $0x44b
f0101c64:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101c69:	e8 d2 e3 ff ff       	call   f0100040 <_panic>
	
	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101c6e:	6a 02                	push   $0x2
f0101c70:	68 00 10 00 00       	push   $0x1000
f0101c75:	56                   	push   %esi
f0101c76:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101c7c:	e8 6d f6 ff ff       	call   f01012ee <page_insert>
f0101c81:	83 c4 10             	add    $0x10,%esp
f0101c84:	85 c0                	test   %eax,%eax
f0101c86:	74 19                	je     f0101ca1 <mem_init+0x8bb>
f0101c88:	68 08 69 10 f0       	push   $0xf0106908
f0101c8d:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101c92:	68 4e 04 00 00       	push   $0x44e
f0101c97:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101c9c:	e8 9f e3 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ca1:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ca6:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f0101cab:	e8 9d ed ff ff       	call   f0100a4d <check_va2pa>
f0101cb0:	89 f2                	mov    %esi,%edx
f0101cb2:	2b 15 d0 de 1d f0    	sub    0xf01dded0,%edx
f0101cb8:	c1 fa 03             	sar    $0x3,%edx
f0101cbb:	c1 e2 0c             	shl    $0xc,%edx
f0101cbe:	39 d0                	cmp    %edx,%eax
f0101cc0:	74 19                	je     f0101cdb <mem_init+0x8f5>
f0101cc2:	68 44 69 10 f0       	push   $0xf0106944
f0101cc7:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101ccc:	68 4f 04 00 00       	push   $0x44f
f0101cd1:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101cd6:	e8 65 e3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101cdb:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101ce0:	74 19                	je     f0101cfb <mem_init+0x915>
f0101ce2:	68 ef 71 10 f0       	push   $0xf01071ef
f0101ce7:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101cec:	68 50 04 00 00       	push   $0x450
f0101cf1:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101cf6:	e8 45 e3 ff ff       	call   f0100040 <_panic>
	
	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101cfb:	83 ec 0c             	sub    $0xc,%esp
f0101cfe:	6a 00                	push   $0x0
f0101d00:	e8 c3 f2 ff ff       	call   f0100fc8 <page_alloc>
f0101d05:	83 c4 10             	add    $0x10,%esp
f0101d08:	85 c0                	test   %eax,%eax
f0101d0a:	74 19                	je     f0101d25 <mem_init+0x93f>
f0101d0c:	68 7b 71 10 f0       	push   $0xf010717b
f0101d11:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101d16:	68 54 04 00 00       	push   $0x454
f0101d1b:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101d20:	e8 1b e3 ff ff       	call   f0100040 <_panic>
	
	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101d25:	8b 15 cc de 1d f0    	mov    0xf01ddecc,%edx
f0101d2b:	8b 02                	mov    (%edx),%eax
f0101d2d:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d32:	89 c1                	mov    %eax,%ecx
f0101d34:	c1 e9 0c             	shr    $0xc,%ecx
f0101d37:	3b 0d c8 de 1d f0    	cmp    0xf01ddec8,%ecx
f0101d3d:	72 15                	jb     f0101d54 <mem_init+0x96e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d3f:	50                   	push   %eax
f0101d40:	68 24 60 10 f0       	push   $0xf0106024
f0101d45:	68 57 04 00 00       	push   $0x457
f0101d4a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101d4f:	e8 ec e2 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0101d54:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101d59:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101d5c:	83 ec 04             	sub    $0x4,%esp
f0101d5f:	6a 00                	push   $0x0
f0101d61:	68 00 10 00 00       	push   $0x1000
f0101d66:	52                   	push   %edx
f0101d67:	e8 4a f3 ff ff       	call   f01010b6 <pgdir_walk>
f0101d6c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101d6f:	8d 51 04             	lea    0x4(%ecx),%edx
f0101d72:	83 c4 10             	add    $0x10,%esp
f0101d75:	39 d0                	cmp    %edx,%eax
f0101d77:	74 19                	je     f0101d92 <mem_init+0x9ac>
f0101d79:	68 74 69 10 f0       	push   $0xf0106974
f0101d7e:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101d83:	68 58 04 00 00       	push   $0x458
f0101d88:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101d8d:	e8 ae e2 ff ff       	call   f0100040 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d92:	6a 06                	push   $0x6
f0101d94:	68 00 10 00 00       	push   $0x1000
f0101d99:	56                   	push   %esi
f0101d9a:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101da0:	e8 49 f5 ff ff       	call   f01012ee <page_insert>
f0101da5:	83 c4 10             	add    $0x10,%esp
f0101da8:	85 c0                	test   %eax,%eax
f0101daa:	74 19                	je     f0101dc5 <mem_init+0x9df>
f0101dac:	68 b4 69 10 f0       	push   $0xf01069b4
f0101db1:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101db6:	68 5b 04 00 00       	push   $0x45b
f0101dbb:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101dc0:	e8 7b e2 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dc5:	8b 3d cc de 1d f0    	mov    0xf01ddecc,%edi
f0101dcb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dd0:	89 f8                	mov    %edi,%eax
f0101dd2:	e8 76 ec ff ff       	call   f0100a4d <check_va2pa>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101dd7:	89 f2                	mov    %esi,%edx
f0101dd9:	2b 15 d0 de 1d f0    	sub    0xf01dded0,%edx
f0101ddf:	c1 fa 03             	sar    $0x3,%edx
f0101de2:	c1 e2 0c             	shl    $0xc,%edx
f0101de5:	39 d0                	cmp    %edx,%eax
f0101de7:	74 19                	je     f0101e02 <mem_init+0xa1c>
f0101de9:	68 44 69 10 f0       	push   $0xf0106944
f0101dee:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101df3:	68 5c 04 00 00       	push   $0x45c
f0101df8:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101dfd:	e8 3e e2 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0101e02:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101e07:	74 19                	je     f0101e22 <mem_init+0xa3c>
f0101e09:	68 ef 71 10 f0       	push   $0xf01071ef
f0101e0e:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101e13:	68 5d 04 00 00       	push   $0x45d
f0101e18:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101e1d:	e8 1e e2 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101e22:	83 ec 04             	sub    $0x4,%esp
f0101e25:	6a 00                	push   $0x0
f0101e27:	68 00 10 00 00       	push   $0x1000
f0101e2c:	57                   	push   %edi
f0101e2d:	e8 84 f2 ff ff       	call   f01010b6 <pgdir_walk>
f0101e32:	83 c4 10             	add    $0x10,%esp
f0101e35:	f6 00 04             	testb  $0x4,(%eax)
f0101e38:	75 19                	jne    f0101e53 <mem_init+0xa6d>
f0101e3a:	68 f4 69 10 f0       	push   $0xf01069f4
f0101e3f:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101e44:	68 5e 04 00 00       	push   $0x45e
f0101e49:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101e4e:	e8 ed e1 ff ff       	call   f0100040 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e53:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f0101e58:	f6 00 04             	testb  $0x4,(%eax)
f0101e5b:	75 19                	jne    f0101e76 <mem_init+0xa90>
f0101e5d:	68 00 72 10 f0       	push   $0xf0107200
f0101e62:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101e67:	68 5f 04 00 00       	push   $0x45f
f0101e6c:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101e71:	e8 ca e1 ff ff       	call   f0100040 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e76:	6a 02                	push   $0x2
f0101e78:	68 00 10 00 00       	push   $0x1000
f0101e7d:	56                   	push   %esi
f0101e7e:	50                   	push   %eax
f0101e7f:	e8 6a f4 ff ff       	call   f01012ee <page_insert>
f0101e84:	83 c4 10             	add    $0x10,%esp
f0101e87:	85 c0                	test   %eax,%eax
f0101e89:	74 19                	je     f0101ea4 <mem_init+0xabe>
f0101e8b:	68 08 69 10 f0       	push   $0xf0106908
f0101e90:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101e95:	68 62 04 00 00       	push   $0x462
f0101e9a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101e9f:	e8 9c e1 ff ff       	call   f0100040 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101ea4:	83 ec 04             	sub    $0x4,%esp
f0101ea7:	6a 00                	push   $0x0
f0101ea9:	68 00 10 00 00       	push   $0x1000
f0101eae:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101eb4:	e8 fd f1 ff ff       	call   f01010b6 <pgdir_walk>
f0101eb9:	83 c4 10             	add    $0x10,%esp
f0101ebc:	f6 00 02             	testb  $0x2,(%eax)
f0101ebf:	75 19                	jne    f0101eda <mem_init+0xaf4>
f0101ec1:	68 28 6a 10 f0       	push   $0xf0106a28
f0101ec6:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101ecb:	68 63 04 00 00       	push   $0x463
f0101ed0:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101ed5:	e8 66 e1 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101eda:	83 ec 04             	sub    $0x4,%esp
f0101edd:	6a 00                	push   $0x0
f0101edf:	68 00 10 00 00       	push   $0x1000
f0101ee4:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101eea:	e8 c7 f1 ff ff       	call   f01010b6 <pgdir_walk>
f0101eef:	83 c4 10             	add    $0x10,%esp
f0101ef2:	f6 00 04             	testb  $0x4,(%eax)
f0101ef5:	74 19                	je     f0101f10 <mem_init+0xb2a>
f0101ef7:	68 5c 6a 10 f0       	push   $0xf0106a5c
f0101efc:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101f01:	68 64 04 00 00       	push   $0x464
f0101f06:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101f0b:	e8 30 e1 ff ff       	call   f0100040 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0101f10:	6a 02                	push   $0x2
f0101f12:	68 00 00 40 00       	push   $0x400000
f0101f17:	ff 75 d4             	pushl  -0x2c(%ebp)
f0101f1a:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101f20:	e8 c9 f3 ff ff       	call   f01012ee <page_insert>
f0101f25:	83 c4 10             	add    $0x10,%esp
f0101f28:	85 c0                	test   %eax,%eax
f0101f2a:	78 19                	js     f0101f45 <mem_init+0xb5f>
f0101f2c:	68 94 6a 10 f0       	push   $0xf0106a94
f0101f31:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101f36:	68 67 04 00 00       	push   $0x467
f0101f3b:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101f40:	e8 fb e0 ff ff       	call   f0100040 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0101f45:	6a 02                	push   $0x2
f0101f47:	68 00 10 00 00       	push   $0x1000
f0101f4c:	53                   	push   %ebx
f0101f4d:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101f53:	e8 96 f3 ff ff       	call   f01012ee <page_insert>
f0101f58:	83 c4 10             	add    $0x10,%esp
f0101f5b:	85 c0                	test   %eax,%eax
f0101f5d:	74 19                	je     f0101f78 <mem_init+0xb92>
f0101f5f:	68 cc 6a 10 f0       	push   $0xf0106acc
f0101f64:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101f69:	68 6a 04 00 00       	push   $0x46a
f0101f6e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101f73:	e8 c8 e0 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101f78:	83 ec 04             	sub    $0x4,%esp
f0101f7b:	6a 00                	push   $0x0
f0101f7d:	68 00 10 00 00       	push   $0x1000
f0101f82:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0101f88:	e8 29 f1 ff ff       	call   f01010b6 <pgdir_walk>
f0101f8d:	83 c4 10             	add    $0x10,%esp
f0101f90:	f6 00 04             	testb  $0x4,(%eax)
f0101f93:	74 19                	je     f0101fae <mem_init+0xbc8>
f0101f95:	68 5c 6a 10 f0       	push   $0xf0106a5c
f0101f9a:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101f9f:	68 6b 04 00 00       	push   $0x46b
f0101fa4:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101fa9:	e8 92 e0 ff ff       	call   f0100040 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0101fae:	8b 3d cc de 1d f0    	mov    0xf01ddecc,%edi
f0101fb4:	ba 00 00 00 00       	mov    $0x0,%edx
f0101fb9:	89 f8                	mov    %edi,%eax
f0101fbb:	e8 8d ea ff ff       	call   f0100a4d <check_va2pa>
f0101fc0:	89 c1                	mov    %eax,%ecx
f0101fc2:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101fc5:	89 d8                	mov    %ebx,%eax
f0101fc7:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0101fcd:	c1 f8 03             	sar    $0x3,%eax
f0101fd0:	c1 e0 0c             	shl    $0xc,%eax
f0101fd3:	39 c1                	cmp    %eax,%ecx
f0101fd5:	74 19                	je     f0101ff0 <mem_init+0xc0a>
f0101fd7:	68 08 6b 10 f0       	push   $0xf0106b08
f0101fdc:	68 db 6f 10 f0       	push   $0xf0106fdb
f0101fe1:	68 6e 04 00 00       	push   $0x46e
f0101fe6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0101feb:	e8 50 e0 ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0101ff0:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ff5:	89 f8                	mov    %edi,%eax
f0101ff7:	e8 51 ea ff ff       	call   f0100a4d <check_va2pa>
f0101ffc:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101fff:	74 19                	je     f010201a <mem_init+0xc34>
f0102001:	68 34 6b 10 f0       	push   $0xf0106b34
f0102006:	68 db 6f 10 f0       	push   $0xf0106fdb
f010200b:	68 6f 04 00 00       	push   $0x46f
f0102010:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102015:	e8 26 e0 ff ff       	call   f0100040 <_panic>
	// ... and ref counts should reflect this
	assert(pp1->pp_ref == 2);
f010201a:	66 83 7b 04 02       	cmpw   $0x2,0x4(%ebx)
f010201f:	74 19                	je     f010203a <mem_init+0xc54>
f0102021:	68 16 72 10 f0       	push   $0xf0107216
f0102026:	68 db 6f 10 f0       	push   $0xf0106fdb
f010202b:	68 71 04 00 00       	push   $0x471
f0102030:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102035:	e8 06 e0 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010203a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f010203f:	74 19                	je     f010205a <mem_init+0xc74>
f0102041:	68 27 72 10 f0       	push   $0xf0107227
f0102046:	68 db 6f 10 f0       	push   $0xf0106fdb
f010204b:	68 72 04 00 00       	push   $0x472
f0102050:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102055:	e8 e6 df ff ff       	call   f0100040 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010205a:	83 ec 0c             	sub    $0xc,%esp
f010205d:	6a 00                	push   $0x0
f010205f:	e8 64 ef ff ff       	call   f0100fc8 <page_alloc>
f0102064:	83 c4 10             	add    $0x10,%esp
f0102067:	85 c0                	test   %eax,%eax
f0102069:	74 04                	je     f010206f <mem_init+0xc89>
f010206b:	39 c6                	cmp    %eax,%esi
f010206d:	74 19                	je     f0102088 <mem_init+0xca2>
f010206f:	68 64 6b 10 f0       	push   $0xf0106b64
f0102074:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102079:	68 75 04 00 00       	push   $0x475
f010207e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102083:	e8 b8 df ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102088:	83 ec 08             	sub    $0x8,%esp
f010208b:	6a 00                	push   $0x0
f010208d:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0102093:	e8 10 f2 ff ff       	call   f01012a8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102098:	8b 3d cc de 1d f0    	mov    0xf01ddecc,%edi
f010209e:	ba 00 00 00 00       	mov    $0x0,%edx
f01020a3:	89 f8                	mov    %edi,%eax
f01020a5:	e8 a3 e9 ff ff       	call   f0100a4d <check_va2pa>
f01020aa:	83 c4 10             	add    $0x10,%esp
f01020ad:	83 f8 ff             	cmp    $0xffffffff,%eax
f01020b0:	74 19                	je     f01020cb <mem_init+0xce5>
f01020b2:	68 88 6b 10 f0       	push   $0xf0106b88
f01020b7:	68 db 6f 10 f0       	push   $0xf0106fdb
f01020bc:	68 79 04 00 00       	push   $0x479
f01020c1:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01020c6:	e8 75 df ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01020cb:	ba 00 10 00 00       	mov    $0x1000,%edx
f01020d0:	89 f8                	mov    %edi,%eax
f01020d2:	e8 76 e9 ff ff       	call   f0100a4d <check_va2pa>
f01020d7:	89 da                	mov    %ebx,%edx
f01020d9:	2b 15 d0 de 1d f0    	sub    0xf01dded0,%edx
f01020df:	c1 fa 03             	sar    $0x3,%edx
f01020e2:	c1 e2 0c             	shl    $0xc,%edx
f01020e5:	39 d0                	cmp    %edx,%eax
f01020e7:	74 19                	je     f0102102 <mem_init+0xd1c>
f01020e9:	68 34 6b 10 f0       	push   $0xf0106b34
f01020ee:	68 db 6f 10 f0       	push   $0xf0106fdb
f01020f3:	68 7a 04 00 00       	push   $0x47a
f01020f8:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01020fd:	e8 3e df ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 1);
f0102102:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102107:	74 19                	je     f0102122 <mem_init+0xd3c>
f0102109:	68 cd 71 10 f0       	push   $0xf01071cd
f010210e:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102113:	68 7b 04 00 00       	push   $0x47b
f0102118:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010211d:	e8 1e df ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f0102122:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102127:	74 19                	je     f0102142 <mem_init+0xd5c>
f0102129:	68 27 72 10 f0       	push   $0xf0107227
f010212e:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102133:	68 7c 04 00 00       	push   $0x47c
f0102138:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010213d:	e8 fe de ff ff       	call   f0100040 <_panic>

	// test re-inserting pp1 at PGSIZE
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, 0) == 0);
f0102142:	6a 00                	push   $0x0
f0102144:	68 00 10 00 00       	push   $0x1000
f0102149:	53                   	push   %ebx
f010214a:	57                   	push   %edi
f010214b:	e8 9e f1 ff ff       	call   f01012ee <page_insert>
f0102150:	83 c4 10             	add    $0x10,%esp
f0102153:	85 c0                	test   %eax,%eax
f0102155:	74 19                	je     f0102170 <mem_init+0xd8a>
f0102157:	68 ac 6b 10 f0       	push   $0xf0106bac
f010215c:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102161:	68 7f 04 00 00       	push   $0x47f
f0102166:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010216b:	e8 d0 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref);
f0102170:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102175:	75 19                	jne    f0102190 <mem_init+0xdaa>
f0102177:	68 38 72 10 f0       	push   $0xf0107238
f010217c:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102181:	68 80 04 00 00       	push   $0x480
f0102186:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010218b:	e8 b0 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_link == NULL);
f0102190:	83 3b 00             	cmpl   $0x0,(%ebx)
f0102193:	74 19                	je     f01021ae <mem_init+0xdc8>
f0102195:	68 44 72 10 f0       	push   $0xf0107244
f010219a:	68 db 6f 10 f0       	push   $0xf0106fdb
f010219f:	68 81 04 00 00       	push   $0x481
f01021a4:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01021a9:	e8 92 de ff ff       	call   f0100040 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01021ae:	83 ec 08             	sub    $0x8,%esp
f01021b1:	68 00 10 00 00       	push   $0x1000
f01021b6:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f01021bc:	e8 e7 f0 ff ff       	call   f01012a8 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01021c1:	8b 3d cc de 1d f0    	mov    0xf01ddecc,%edi
f01021c7:	ba 00 00 00 00       	mov    $0x0,%edx
f01021cc:	89 f8                	mov    %edi,%eax
f01021ce:	e8 7a e8 ff ff       	call   f0100a4d <check_va2pa>
f01021d3:	83 c4 10             	add    $0x10,%esp
f01021d6:	83 f8 ff             	cmp    $0xffffffff,%eax
f01021d9:	74 19                	je     f01021f4 <mem_init+0xe0e>
f01021db:	68 88 6b 10 f0       	push   $0xf0106b88
f01021e0:	68 db 6f 10 f0       	push   $0xf0106fdb
f01021e5:	68 85 04 00 00       	push   $0x485
f01021ea:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01021ef:	e8 4c de ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01021f4:	ba 00 10 00 00       	mov    $0x1000,%edx
f01021f9:	89 f8                	mov    %edi,%eax
f01021fb:	e8 4d e8 ff ff       	call   f0100a4d <check_va2pa>
f0102200:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102203:	74 19                	je     f010221e <mem_init+0xe38>
f0102205:	68 e4 6b 10 f0       	push   $0xf0106be4
f010220a:	68 db 6f 10 f0       	push   $0xf0106fdb
f010220f:	68 86 04 00 00       	push   $0x486
f0102214:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102219:	e8 22 de ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f010221e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102223:	74 19                	je     f010223e <mem_init+0xe58>
f0102225:	68 59 72 10 f0       	push   $0xf0107259
f010222a:	68 db 6f 10 f0       	push   $0xf0106fdb
f010222f:	68 87 04 00 00       	push   $0x487
f0102234:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102239:	e8 02 de ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 0);
f010223e:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102243:	74 19                	je     f010225e <mem_init+0xe78>
f0102245:	68 27 72 10 f0       	push   $0xf0107227
f010224a:	68 db 6f 10 f0       	push   $0xf0106fdb
f010224f:	68 88 04 00 00       	push   $0x488
f0102254:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102259:	e8 e2 dd ff ff       	call   f0100040 <_panic>
	
	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010225e:	83 ec 0c             	sub    $0xc,%esp
f0102261:	6a 00                	push   $0x0
f0102263:	e8 60 ed ff ff       	call   f0100fc8 <page_alloc>
f0102268:	83 c4 10             	add    $0x10,%esp
f010226b:	85 c0                	test   %eax,%eax
f010226d:	74 04                	je     f0102273 <mem_init+0xe8d>
f010226f:	39 c3                	cmp    %eax,%ebx
f0102271:	74 19                	je     f010228c <mem_init+0xea6>
f0102273:	68 0c 6c 10 f0       	push   $0xf0106c0c
f0102278:	68 db 6f 10 f0       	push   $0xf0106fdb
f010227d:	68 8b 04 00 00       	push   $0x48b
f0102282:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102287:	e8 b4 dd ff ff       	call   f0100040 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010228c:	83 ec 0c             	sub    $0xc,%esp
f010228f:	6a 00                	push   $0x0
f0102291:	e8 32 ed ff ff       	call   f0100fc8 <page_alloc>
f0102296:	83 c4 10             	add    $0x10,%esp
f0102299:	85 c0                	test   %eax,%eax
f010229b:	74 19                	je     f01022b6 <mem_init+0xed0>
f010229d:	68 7b 71 10 f0       	push   $0xf010717b
f01022a2:	68 db 6f 10 f0       	push   $0xf0106fdb
f01022a7:	68 8e 04 00 00       	push   $0x48e
f01022ac:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01022b1:	e8 8a dd ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01022b6:	8b 0d cc de 1d f0    	mov    0xf01ddecc,%ecx
f01022bc:	8b 11                	mov    (%ecx),%edx
f01022be:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01022c4:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022c7:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f01022cd:	c1 f8 03             	sar    $0x3,%eax
f01022d0:	c1 e0 0c             	shl    $0xc,%eax
f01022d3:	39 c2                	cmp    %eax,%edx
f01022d5:	74 19                	je     f01022f0 <mem_init+0xf0a>
f01022d7:	68 b0 68 10 f0       	push   $0xf01068b0
f01022dc:	68 db 6f 10 f0       	push   $0xf0106fdb
f01022e1:	68 91 04 00 00       	push   $0x491
f01022e6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01022eb:	e8 50 dd ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f01022f0:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f01022f6:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01022f9:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f01022fe:	74 19                	je     f0102319 <mem_init+0xf33>
f0102300:	68 de 71 10 f0       	push   $0xf01071de
f0102305:	68 db 6f 10 f0       	push   $0xf0106fdb
f010230a:	68 93 04 00 00       	push   $0x493
f010230f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102314:	e8 27 dd ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102319:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010231c:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102322:	83 ec 0c             	sub    $0xc,%esp
f0102325:	50                   	push   %eax
f0102326:	e8 13 ed ff ff       	call   f010103e <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010232b:	83 c4 0c             	add    $0xc,%esp
f010232e:	6a 01                	push   $0x1
f0102330:	68 00 10 40 00       	push   $0x401000
f0102335:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f010233b:	e8 76 ed ff ff       	call   f01010b6 <pgdir_walk>
f0102340:	89 c7                	mov    %eax,%edi
f0102342:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102345:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f010234a:	89 45 cc             	mov    %eax,-0x34(%ebp)
f010234d:	8b 40 04             	mov    0x4(%eax),%eax
f0102350:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102355:	8b 0d c8 de 1d f0    	mov    0xf01ddec8,%ecx
f010235b:	89 c2                	mov    %eax,%edx
f010235d:	c1 ea 0c             	shr    $0xc,%edx
f0102360:	83 c4 10             	add    $0x10,%esp
f0102363:	39 ca                	cmp    %ecx,%edx
f0102365:	72 15                	jb     f010237c <mem_init+0xf96>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102367:	50                   	push   %eax
f0102368:	68 24 60 10 f0       	push   $0xf0106024
f010236d:	68 9a 04 00 00       	push   $0x49a
f0102372:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102377:	e8 c4 dc ff ff       	call   f0100040 <_panic>
	assert(ptep == ptep1 + PTX(va));
f010237c:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0102381:	39 c7                	cmp    %eax,%edi
f0102383:	74 19                	je     f010239e <mem_init+0xfb8>
f0102385:	68 6a 72 10 f0       	push   $0xf010726a
f010238a:	68 db 6f 10 f0       	push   $0xf0106fdb
f010238f:	68 9b 04 00 00       	push   $0x49b
f0102394:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102399:	e8 a2 dc ff ff       	call   f0100040 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010239e:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01023a1:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
	pp0->pp_ref = 0;
f01023a8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023ab:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01023b1:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f01023b7:	c1 f8 03             	sar    $0x3,%eax
f01023ba:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01023bd:	89 c2                	mov    %eax,%edx
f01023bf:	c1 ea 0c             	shr    $0xc,%edx
f01023c2:	39 d1                	cmp    %edx,%ecx
f01023c4:	77 12                	ja     f01023d8 <mem_init+0xff2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01023c6:	50                   	push   %eax
f01023c7:	68 24 60 10 f0       	push   $0xf0106024
f01023cc:	6a 58                	push   $0x58
f01023ce:	68 c1 6f 10 f0       	push   $0xf0106fc1
f01023d3:	e8 68 dc ff ff       	call   f0100040 <_panic>
	
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f01023d8:	83 ec 04             	sub    $0x4,%esp
f01023db:	68 00 10 00 00       	push   $0x1000
f01023e0:	68 ff 00 00 00       	push   $0xff
	return (void *)(pa + KERNBASE);
f01023e5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01023ea:	50                   	push   %eax
f01023eb:	e8 33 2f 00 00       	call   f0105323 <memset>
	page_free(pp0);
f01023f0:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01023f3:	89 3c 24             	mov    %edi,(%esp)
f01023f6:	e8 43 ec ff ff       	call   f010103e <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f01023fb:	83 c4 0c             	add    $0xc,%esp
f01023fe:	6a 01                	push   $0x1
f0102400:	6a 00                	push   $0x0
f0102402:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0102408:	e8 a9 ec ff ff       	call   f01010b6 <pgdir_walk>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010240d:	89 fa                	mov    %edi,%edx
f010240f:	2b 15 d0 de 1d f0    	sub    0xf01dded0,%edx
f0102415:	c1 fa 03             	sar    $0x3,%edx
f0102418:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010241b:	89 d0                	mov    %edx,%eax
f010241d:	c1 e8 0c             	shr    $0xc,%eax
f0102420:	83 c4 10             	add    $0x10,%esp
f0102423:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f0102429:	72 12                	jb     f010243d <mem_init+0x1057>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010242b:	52                   	push   %edx
f010242c:	68 24 60 10 f0       	push   $0xf0106024
f0102431:	6a 58                	push   $0x58
f0102433:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0102438:	e8 03 dc ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f010243d:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102443:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102446:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010244c:	f6 00 01             	testb  $0x1,(%eax)
f010244f:	74 19                	je     f010246a <mem_init+0x1084>
f0102451:	68 82 72 10 f0       	push   $0xf0107282
f0102456:	68 db 6f 10 f0       	push   $0xf0106fdb
f010245b:	68 a5 04 00 00       	push   $0x4a5
f0102460:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102465:	e8 d6 db ff ff       	call   f0100040 <_panic>
f010246a:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010246d:	39 d0                	cmp    %edx,%eax
f010246f:	75 db                	jne    f010244c <mem_init+0x1066>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102471:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f0102476:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010247c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010247f:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)

	// give free list back
	page_free_list = fl;
f0102485:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102488:	89 0d 64 d2 1d f0    	mov    %ecx,0xf01dd264

	// free the pages we took
	page_free(pp0);
f010248e:	83 ec 0c             	sub    $0xc,%esp
f0102491:	50                   	push   %eax
f0102492:	e8 a7 eb ff ff       	call   f010103e <page_free>
	page_free(pp1);
f0102497:	89 1c 24             	mov    %ebx,(%esp)
f010249a:	e8 9f eb ff ff       	call   f010103e <page_free>
	page_free(pp2);
f010249f:	89 34 24             	mov    %esi,(%esp)
f01024a2:	e8 97 eb ff ff       	call   f010103e <page_free>

	// test mmio_map_region
	mm1 = (uintptr_t) mmio_map_region(0, 4097);
f01024a7:	83 c4 08             	add    $0x8,%esp
f01024aa:	68 01 10 00 00       	push   $0x1001
f01024af:	6a 00                	push   $0x0
f01024b1:	e8 f1 ee ff ff       	call   f01013a7 <mmio_map_region>
f01024b6:	89 c3                	mov    %eax,%ebx
	mm2 = (uintptr_t) mmio_map_region(0, 4096);
f01024b8:	83 c4 08             	add    $0x8,%esp
f01024bb:	68 00 10 00 00       	push   $0x1000
f01024c0:	6a 00                	push   $0x0
f01024c2:	e8 e0 ee ff ff       	call   f01013a7 <mmio_map_region>
f01024c7:	89 c6                	mov    %eax,%esi
	// check that they're in the right region
	assert(mm1 >= MMIOBASE && mm1 + 8096 < MMIOLIM);
f01024c9:	8d 83 a0 1f 00 00    	lea    0x1fa0(%ebx),%eax
f01024cf:	83 c4 10             	add    $0x10,%esp
f01024d2:	3d ff ff bf ef       	cmp    $0xefbfffff,%eax
f01024d7:	77 08                	ja     f01024e1 <mem_init+0x10fb>
f01024d9:	81 fb ff ff 7f ef    	cmp    $0xef7fffff,%ebx
f01024df:	77 19                	ja     f01024fa <mem_init+0x1114>
f01024e1:	68 30 6c 10 f0       	push   $0xf0106c30
f01024e6:	68 db 6f 10 f0       	push   $0xf0106fdb
f01024eb:	68 b5 04 00 00       	push   $0x4b5
f01024f0:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01024f5:	e8 46 db ff ff       	call   f0100040 <_panic>
	assert(mm2 >= MMIOBASE && mm2 + 8096 < MMIOLIM);
f01024fa:	8d 96 a0 1f 00 00    	lea    0x1fa0(%esi),%edx
f0102500:	81 fa ff ff bf ef    	cmp    $0xefbfffff,%edx
f0102506:	77 08                	ja     f0102510 <mem_init+0x112a>
f0102508:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010250e:	77 19                	ja     f0102529 <mem_init+0x1143>
f0102510:	68 58 6c 10 f0       	push   $0xf0106c58
f0102515:	68 db 6f 10 f0       	push   $0xf0106fdb
f010251a:	68 b6 04 00 00       	push   $0x4b6
f010251f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102524:	e8 17 db ff ff       	call   f0100040 <_panic>
f0102529:	89 da                	mov    %ebx,%edx
f010252b:	09 f2                	or     %esi,%edx
	// check that they're page-aligned
	assert(mm1 % PGSIZE == 0 && mm2 % PGSIZE == 0);
f010252d:	f7 c2 ff 0f 00 00    	test   $0xfff,%edx
f0102533:	74 19                	je     f010254e <mem_init+0x1168>
f0102535:	68 80 6c 10 f0       	push   $0xf0106c80
f010253a:	68 db 6f 10 f0       	push   $0xf0106fdb
f010253f:	68 b8 04 00 00       	push   $0x4b8
f0102544:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102549:	e8 f2 da ff ff       	call   f0100040 <_panic>
	// check that they don't overlap
	assert(mm1 + 8096 <= mm2);
f010254e:	39 c6                	cmp    %eax,%esi
f0102550:	73 19                	jae    f010256b <mem_init+0x1185>
f0102552:	68 99 72 10 f0       	push   $0xf0107299
f0102557:	68 db 6f 10 f0       	push   $0xf0106fdb
f010255c:	68 ba 04 00 00       	push   $0x4ba
f0102561:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102566:	e8 d5 da ff ff       	call   f0100040 <_panic>
	// check page mappings
	assert(check_va2pa(kern_pgdir, mm1) == 0);
f010256b:	8b 3d cc de 1d f0    	mov    0xf01ddecc,%edi
f0102571:	89 da                	mov    %ebx,%edx
f0102573:	89 f8                	mov    %edi,%eax
f0102575:	e8 d3 e4 ff ff       	call   f0100a4d <check_va2pa>
f010257a:	85 c0                	test   %eax,%eax
f010257c:	74 19                	je     f0102597 <mem_init+0x11b1>
f010257e:	68 a8 6c 10 f0       	push   $0xf0106ca8
f0102583:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102588:	68 bc 04 00 00       	push   $0x4bc
f010258d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102592:	e8 a9 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm1+PGSIZE) == PGSIZE);
f0102597:	8d 83 00 10 00 00    	lea    0x1000(%ebx),%eax
f010259d:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01025a0:	89 c2                	mov    %eax,%edx
f01025a2:	89 f8                	mov    %edi,%eax
f01025a4:	e8 a4 e4 ff ff       	call   f0100a4d <check_va2pa>
f01025a9:	3d 00 10 00 00       	cmp    $0x1000,%eax
f01025ae:	74 19                	je     f01025c9 <mem_init+0x11e3>
f01025b0:	68 cc 6c 10 f0       	push   $0xf0106ccc
f01025b5:	68 db 6f 10 f0       	push   $0xf0106fdb
f01025ba:	68 bd 04 00 00       	push   $0x4bd
f01025bf:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01025c4:	e8 77 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2) == 0);
f01025c9:	89 f2                	mov    %esi,%edx
f01025cb:	89 f8                	mov    %edi,%eax
f01025cd:	e8 7b e4 ff ff       	call   f0100a4d <check_va2pa>
f01025d2:	85 c0                	test   %eax,%eax
f01025d4:	74 19                	je     f01025ef <mem_init+0x1209>
f01025d6:	68 fc 6c 10 f0       	push   $0xf0106cfc
f01025db:	68 db 6f 10 f0       	push   $0xf0106fdb
f01025e0:	68 be 04 00 00       	push   $0x4be
f01025e5:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01025ea:	e8 51 da ff ff       	call   f0100040 <_panic>
	assert(check_va2pa(kern_pgdir, mm2+PGSIZE) == ~0);
f01025ef:	8d 96 00 10 00 00    	lea    0x1000(%esi),%edx
f01025f5:	89 f8                	mov    %edi,%eax
f01025f7:	e8 51 e4 ff ff       	call   f0100a4d <check_va2pa>
f01025fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01025ff:	74 19                	je     f010261a <mem_init+0x1234>
f0102601:	68 20 6d 10 f0       	push   $0xf0106d20
f0102606:	68 db 6f 10 f0       	push   $0xf0106fdb
f010260b:	68 bf 04 00 00       	push   $0x4bf
f0102610:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102615:	e8 26 da ff ff       	call   f0100040 <_panic>
	// check permissions
	assert(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & (PTE_W|PTE_PWT|PTE_PCD));
f010261a:	83 ec 04             	sub    $0x4,%esp
f010261d:	6a 00                	push   $0x0
f010261f:	53                   	push   %ebx
f0102620:	57                   	push   %edi
f0102621:	e8 90 ea ff ff       	call   f01010b6 <pgdir_walk>
f0102626:	83 c4 10             	add    $0x10,%esp
f0102629:	f6 00 1a             	testb  $0x1a,(%eax)
f010262c:	75 19                	jne    f0102647 <mem_init+0x1261>
f010262e:	68 4c 6d 10 f0       	push   $0xf0106d4c
f0102633:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102638:	68 c1 04 00 00       	push   $0x4c1
f010263d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102642:	e8 f9 d9 ff ff       	call   f0100040 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) mm1, 0) & PTE_U));
f0102647:	83 ec 04             	sub    $0x4,%esp
f010264a:	6a 00                	push   $0x0
f010264c:	53                   	push   %ebx
f010264d:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0102653:	e8 5e ea ff ff       	call   f01010b6 <pgdir_walk>
f0102658:	83 c4 10             	add    $0x10,%esp
f010265b:	f6 00 04             	testb  $0x4,(%eax)
f010265e:	74 19                	je     f0102679 <mem_init+0x1293>
f0102660:	68 90 6d 10 f0       	push   $0xf0106d90
f0102665:	68 db 6f 10 f0       	push   $0xf0106fdb
f010266a:	68 c2 04 00 00       	push   $0x4c2
f010266f:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102674:	e8 c7 d9 ff ff       	call   f0100040 <_panic>
	// clear the mappings
	*pgdir_walk(kern_pgdir, (void*) mm1, 0) = 0;
f0102679:	83 ec 04             	sub    $0x4,%esp
f010267c:	6a 00                	push   $0x0
f010267e:	53                   	push   %ebx
f010267f:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0102685:	e8 2c ea ff ff       	call   f01010b6 <pgdir_walk>
f010268a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm1 + PGSIZE, 0) = 0;
f0102690:	83 c4 0c             	add    $0xc,%esp
f0102693:	6a 00                	push   $0x0
f0102695:	ff 75 d4             	pushl  -0x2c(%ebp)
f0102698:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f010269e:	e8 13 ea ff ff       	call   f01010b6 <pgdir_walk>
f01026a3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	*pgdir_walk(kern_pgdir, (void*) mm2, 0) = 0;
f01026a9:	83 c4 0c             	add    $0xc,%esp
f01026ac:	6a 00                	push   $0x0
f01026ae:	56                   	push   %esi
f01026af:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f01026b5:	e8 fc e9 ff ff       	call   f01010b6 <pgdir_walk>
f01026ba:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

	cprintf("check_page() succeeded!\n");
f01026c0:	c7 04 24 ab 72 10 f0 	movl   $0xf01072ab,(%esp)
f01026c7:	e8 43 11 00 00       	call   f010380f <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP( (sizeof(struct PageInfo)*npages),PGSIZE), PADDR(pages), PTE_U | PTE_P);
f01026cc:	a1 d0 de 1d f0       	mov    0xf01dded0,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01026d1:	83 c4 10             	add    $0x10,%esp
f01026d4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01026d9:	77 15                	ja     f01026f0 <mem_init+0x130a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01026db:	50                   	push   %eax
f01026dc:	68 48 60 10 f0       	push   $0xf0106048
f01026e1:	68 c5 00 00 00       	push   $0xc5
f01026e6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01026eb:	e8 50 d9 ff ff       	call   f0100040 <_panic>
f01026f0:	8b 15 c8 de 1d f0    	mov    0xf01ddec8,%edx
f01026f6:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01026fd:	83 ec 08             	sub    $0x8,%esp
f0102700:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102706:	6a 05                	push   $0x5
	return (physaddr_t)kva - KERNBASE;
f0102708:	05 00 00 00 10       	add    $0x10000000,%eax
f010270d:	50                   	push   %eax
f010270e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102713:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f0102718:	e8 84 ea ff ff       	call   f01011a1 <boot_map_region>
	// (ie. perm = PTE_U | PTE_P).
	// Permissions:
	//    - the new image at UENVS  -- kernel R, user R
	//    - envs itself -- kernel RW, user NONE
	// LAB 3: Your code here.
	boot_map_region(kern_pgdir, UENVS, sizeof(struct Env) * NENV,PADDR(envs), PTE_U);
f010271d:	a1 6c d2 1d f0       	mov    0xf01dd26c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102722:	83 c4 10             	add    $0x10,%esp
f0102725:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010272a:	77 15                	ja     f0102741 <mem_init+0x135b>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010272c:	50                   	push   %eax
f010272d:	68 48 60 10 f0       	push   $0xf0106048
f0102732:	68 cd 00 00 00       	push   $0xcd
f0102737:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010273c:	e8 ff d8 ff ff       	call   f0100040 <_panic>
f0102741:	83 ec 08             	sub    $0x8,%esp
f0102744:	6a 04                	push   $0x4
	return (physaddr_t)kva - KERNBASE;
f0102746:	05 00 00 00 10       	add    $0x10000000,%eax
f010274b:	50                   	push   %eax
f010274c:	b9 00 f0 01 00       	mov    $0x1f000,%ecx
f0102751:	ba 00 00 c0 ee       	mov    $0xeec00000,%edx
f0102756:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f010275b:	e8 41 ea ff ff       	call   f01011a1 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102760:	83 c4 10             	add    $0x10,%esp
f0102763:	b8 00 60 11 f0       	mov    $0xf0116000,%eax
f0102768:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010276d:	77 15                	ja     f0102784 <mem_init+0x139e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010276f:	50                   	push   %eax
f0102770:	68 48 60 10 f0       	push   $0xf0106048
f0102775:	68 d9 00 00 00       	push   $0xd9
f010277a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010277f:	e8 bc d8 ff ff       	call   f0100040 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W | PTE_P);
f0102784:	83 ec 08             	sub    $0x8,%esp
f0102787:	6a 03                	push   $0x3
f0102789:	68 00 60 11 00       	push   $0x116000
f010278e:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102793:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102798:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f010279d:	e8 ff e9 ff ff       	call   f01011a1 <boot_map_region>
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	size_t size = ROUNDUP(0xFFFFFFFF - KERNBASE + 1, PGSIZE);
	boot_map_region(kern_pgdir, KERNBASE, size, 0, PTE_W | PTE_P);
f01027a2:	83 c4 08             	add    $0x8,%esp
f01027a5:	6a 03                	push   $0x3
f01027a7:	6a 00                	push   $0x0
f01027a9:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f01027ae:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f01027b3:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f01027b8:	e8 e4 e9 ff ff       	call   f01011a1 <boot_map_region>
f01027bd:	c7 45 c4 00 f0 1d f0 	movl   $0xf01df000,-0x3c(%ebp)
f01027c4:	83 c4 10             	add    $0x10,%esp
f01027c7:	bb 00 f0 1d f0       	mov    $0xf01df000,%ebx
f01027cc:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01027d1:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f01027d7:	77 15                	ja     f01027ee <mem_init+0x1408>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01027d9:	53                   	push   %ebx
f01027da:	68 48 60 10 f0       	push   $0xf0106048
f01027df:	68 20 01 00 00       	push   $0x120
f01027e4:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01027e9:	e8 52 d8 ff ff       	call   f0100040 <_panic>
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
	{	
		boot_map_region(kern_pgdir, percpu_stacktop - KSTKSIZE, KSTKSIZE,PADDR((void*)percpu_kstacks[i]), PTE_W | PTE_P);
f01027ee:	83 ec 08             	sub    $0x8,%esp
f01027f1:	6a 03                	push   $0x3
f01027f3:	8d 83 00 00 00 10    	lea    0x10000000(%ebx),%eax
f01027f9:	50                   	push   %eax
f01027fa:	b9 00 80 00 00       	mov    $0x8000,%ecx
f01027ff:	89 f2                	mov    %esi,%edx
f0102801:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
f0102806:	e8 96 e9 ff ff       	call   f01011a1 <boot_map_region>
f010280b:	81 c3 00 80 00 00    	add    $0x8000,%ebx
f0102811:	81 ee 00 00 01 00    	sub    $0x10000,%esi
	
	int i=0;
	uint32_t percpu_stacktop = KSTACKTOP;
	//uint32_t percpu_stackbtm;
	
	for (i=0;i<NCPU;i++)
f0102817:	83 c4 10             	add    $0x10,%esp
f010281a:	81 fb 00 f0 21 f0    	cmp    $0xf021f000,%ebx
f0102820:	75 af                	jne    f01027d1 <mem_init+0x13eb>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102822:	8b 3d cc de 1d f0    	mov    0xf01ddecc,%edi

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102828:	a1 c8 de 1d f0       	mov    0xf01ddec8,%eax
f010282d:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0102830:	8d 04 c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%eax
f0102837:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f010283c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f010283f:	8b 35 d0 de 1d f0    	mov    0xf01dded0,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102845:	89 75 d0             	mov    %esi,-0x30(%ebp)

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102848:	bb 00 00 00 00       	mov    $0x0,%ebx
f010284d:	eb 55                	jmp    f01028a4 <mem_init+0x14be>
f010284f:	8d 93 00 00 00 ef    	lea    -0x11000000(%ebx),%edx
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102855:	89 f8                	mov    %edi,%eax
f0102857:	e8 f1 e1 ff ff       	call   f0100a4d <check_va2pa>
f010285c:	81 7d d0 ff ff ff ef 	cmpl   $0xefffffff,-0x30(%ebp)
f0102863:	77 15                	ja     f010287a <mem_init+0x1494>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102865:	56                   	push   %esi
f0102866:	68 48 60 10 f0       	push   $0xf0106048
f010286b:	68 d7 03 00 00       	push   $0x3d7
f0102870:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102875:	e8 c6 d7 ff ff       	call   f0100040 <_panic>
f010287a:	8d 94 1e 00 00 00 10 	lea    0x10000000(%esi,%ebx,1),%edx
f0102881:	39 d0                	cmp    %edx,%eax
f0102883:	74 19                	je     f010289e <mem_init+0x14b8>
f0102885:	68 c4 6d 10 f0       	push   $0xf0106dc4
f010288a:	68 db 6f 10 f0       	push   $0xf0106fdb
f010288f:	68 d7 03 00 00       	push   $0x3d7
f0102894:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102899:	e8 a2 d7 ff ff       	call   f0100040 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f010289e:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01028a4:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f01028a7:	77 a6                	ja     f010284f <mem_init+0x1469>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);
f01028a9:	8b 35 6c d2 1d f0    	mov    0xf01dd26c,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028af:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01028b2:	bb 00 00 c0 ee       	mov    $0xeec00000,%ebx
f01028b7:	89 da                	mov    %ebx,%edx
f01028b9:	89 f8                	mov    %edi,%eax
f01028bb:	e8 8d e1 ff ff       	call   f0100a4d <check_va2pa>
f01028c0:	81 7d d4 ff ff ff ef 	cmpl   $0xefffffff,-0x2c(%ebp)
f01028c7:	77 15                	ja     f01028de <mem_init+0x14f8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028c9:	56                   	push   %esi
f01028ca:	68 48 60 10 f0       	push   $0xf0106048
f01028cf:	68 dc 03 00 00       	push   $0x3dc
f01028d4:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01028d9:	e8 62 d7 ff ff       	call   f0100040 <_panic>
f01028de:	8d 94 1e 00 00 40 21 	lea    0x21400000(%esi,%ebx,1),%edx
f01028e5:	39 d0                	cmp    %edx,%eax
f01028e7:	74 19                	je     f0102902 <mem_init+0x151c>
f01028e9:	68 f8 6d 10 f0       	push   $0xf0106df8
f01028ee:	68 db 6f 10 f0       	push   $0xf0106fdb
f01028f3:	68 dc 03 00 00       	push   $0x3dc
f01028f8:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01028fd:	e8 3e d7 ff ff       	call   f0100040 <_panic>
f0102902:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);

	// check envs array (new test for lab 3)
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
f0102908:	81 fb 00 f0 c1 ee    	cmp    $0xeec1f000,%ebx
f010290e:	75 a7                	jne    f01028b7 <mem_init+0x14d1>
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102910:	8b 75 cc             	mov    -0x34(%ebp),%esi
f0102913:	c1 e6 0c             	shl    $0xc,%esi
f0102916:	bb 00 00 00 00       	mov    $0x0,%ebx
f010291b:	eb 30                	jmp    f010294d <mem_init+0x1567>
f010291d:	8d 93 00 00 00 f0    	lea    -0x10000000(%ebx),%edx
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102923:	89 f8                	mov    %edi,%eax
f0102925:	e8 23 e1 ff ff       	call   f0100a4d <check_va2pa>
f010292a:	39 c3                	cmp    %eax,%ebx
f010292c:	74 19                	je     f0102947 <mem_init+0x1561>
f010292e:	68 2c 6e 10 f0       	push   $0xf0106e2c
f0102933:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102938:	68 e0 03 00 00       	push   $0x3e0
f010293d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102942:	e8 f9 d6 ff ff       	call   f0100040 <_panic>
	n = ROUNDUP(NENV*sizeof(struct Env), PGSIZE);
	for (i = 0; i < n; i += PGSIZE)
		assert(check_va2pa(pgdir, UENVS + i) == PADDR(envs) + i);

	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102947:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010294d:	39 f3                	cmp    %esi,%ebx
f010294f:	72 cc                	jb     f010291d <mem_init+0x1537>
f0102951:	c7 45 c8 00 00 00 00 	movl   $0x0,-0x38(%ebp)
f0102958:	be 00 80 ff ef       	mov    $0xefff8000,%esi
f010295d:	89 75 cc             	mov    %esi,-0x34(%ebp)
f0102960:	8b 75 c4             	mov    -0x3c(%ebp),%esi
f0102963:	8b 45 cc             	mov    -0x34(%ebp),%eax
f0102966:	8d 88 00 80 00 00    	lea    0x8000(%eax),%ecx
f010296c:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f010296f:	89 c3                	mov    %eax,%ebx
f0102971:	8b 45 c8             	mov    -0x38(%ebp),%eax
f0102974:	05 00 80 00 20       	add    $0x20008000,%eax
f0102979:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
f010297c:	89 da                	mov    %ebx,%edx
f010297e:	89 f8                	mov    %edi,%eax
f0102980:	e8 c8 e0 ff ff       	call   f0100a4d <check_va2pa>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102985:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f010298b:	77 15                	ja     f01029a2 <mem_init+0x15bc>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010298d:	56                   	push   %esi
f010298e:	68 48 60 10 f0       	push   $0xf0106048
f0102993:	68 e8 03 00 00       	push   $0x3e8
f0102998:	68 b5 6f 10 f0       	push   $0xf0106fb5
f010299d:	e8 9e d6 ff ff       	call   f0100040 <_panic>
f01029a2:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01029a5:	8d 94 0b 00 f0 1d f0 	lea    -0xfe21000(%ebx,%ecx,1),%edx
f01029ac:	39 d0                	cmp    %edx,%eax
f01029ae:	74 19                	je     f01029c9 <mem_init+0x15e3>
f01029b0:	68 54 6e 10 f0       	push   $0xf0106e54
f01029b5:	68 db 6f 10 f0       	push   $0xf0106fdb
f01029ba:	68 e8 03 00 00       	push   $0x3e8
f01029bf:	68 b5 6f 10 f0       	push   $0xf0106fb5
f01029c4:	e8 77 d6 ff ff       	call   f0100040 <_panic>
f01029c9:	81 c3 00 10 00 00    	add    $0x1000,%ebx

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029cf:	3b 5d d0             	cmp    -0x30(%ebp),%ebx
f01029d2:	75 a8                	jne    f010297c <mem_init+0x1596>
f01029d4:	8b 45 cc             	mov    -0x34(%ebp),%eax
f01029d7:	8d 98 00 80 ff ff    	lea    -0x8000(%eax),%ebx
f01029dd:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01029e0:	89 c6                	mov    %eax,%esi
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
f01029e2:	89 da                	mov    %ebx,%edx
f01029e4:	89 f8                	mov    %edi,%eax
f01029e6:	e8 62 e0 ff ff       	call   f0100a4d <check_va2pa>
f01029eb:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029ee:	74 19                	je     f0102a09 <mem_init+0x1623>
f01029f0:	68 9c 6e 10 f0       	push   $0xf0106e9c
f01029f5:	68 db 6f 10 f0       	push   $0xf0106fdb
f01029fa:	68 ea 03 00 00       	push   $0x3ea
f01029ff:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102a04:	e8 37 d6 ff ff       	call   f0100040 <_panic>
f0102a09:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	for (n = 0; n < NCPU; n++) {
		uint32_t base = KSTACKTOP - (KSTKSIZE + KSTKGAP) * (n + 1);
		for (i = 0; i < KSTKSIZE; i += PGSIZE)
			assert(check_va2pa(pgdir, base + KSTKGAP + i)
				== PADDR(percpu_kstacks[n]) + i);
		for (i = 0; i < KSTKGAP; i += PGSIZE)
f0102a0f:	39 de                	cmp    %ebx,%esi
f0102a11:	75 cf                	jne    f01029e2 <mem_init+0x15fc>
f0102a13:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0102a16:	81 6d cc 00 00 01 00 	subl   $0x10000,-0x34(%ebp)
f0102a1d:	81 45 c8 00 80 01 00 	addl   $0x18000,-0x38(%ebp)
f0102a24:	81 c6 00 80 00 00    	add    $0x8000,%esi
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	// (updated in lab 4 to check per-CPU kernel stacks)
	for (n = 0; n < NCPU; n++) {
f0102a2a:	81 fe 00 f0 21 f0    	cmp    $0xf021f000,%esi
f0102a30:	0f 85 2d ff ff ff    	jne    f0102963 <mem_init+0x157d>
f0102a36:	b8 00 00 00 00       	mov    $0x0,%eax
f0102a3b:	eb 2a                	jmp    f0102a67 <mem_init+0x1681>
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a3d:	8d 90 45 fc ff ff    	lea    -0x3bb(%eax),%edx
f0102a43:	83 fa 04             	cmp    $0x4,%edx
f0102a46:	77 1f                	ja     f0102a67 <mem_init+0x1681>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
		case PDX(UENVS):
		case PDX(MMIOBASE):
			assert(pgdir[i] & PTE_P);
f0102a48:	f6 04 87 01          	testb  $0x1,(%edi,%eax,4)
f0102a4c:	75 7e                	jne    f0102acc <mem_init+0x16e6>
f0102a4e:	68 c4 72 10 f0       	push   $0xf01072c4
f0102a53:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102a58:	68 f5 03 00 00       	push   $0x3f5
f0102a5d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102a62:	e8 d9 d5 ff ff       	call   f0100040 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a67:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a6c:	76 3f                	jbe    f0102aad <mem_init+0x16c7>
				assert(pgdir[i] & PTE_P);
f0102a6e:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0102a71:	f6 c2 01             	test   $0x1,%dl
f0102a74:	75 19                	jne    f0102a8f <mem_init+0x16a9>
f0102a76:	68 c4 72 10 f0       	push   $0xf01072c4
f0102a7b:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102a80:	68 f9 03 00 00       	push   $0x3f9
f0102a85:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102a8a:	e8 b1 d5 ff ff       	call   f0100040 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a8f:	f6 c2 02             	test   $0x2,%dl
f0102a92:	75 38                	jne    f0102acc <mem_init+0x16e6>
f0102a94:	68 d5 72 10 f0       	push   $0xf01072d5
f0102a99:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102a9e:	68 fa 03 00 00       	push   $0x3fa
f0102aa3:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102aa8:	e8 93 d5 ff ff       	call   f0100040 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102aad:	83 3c 87 00          	cmpl   $0x0,(%edi,%eax,4)
f0102ab1:	74 19                	je     f0102acc <mem_init+0x16e6>
f0102ab3:	68 e6 72 10 f0       	push   $0xf01072e6
f0102ab8:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102abd:	68 fc 03 00 00       	push   $0x3fc
f0102ac2:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102ac7:	e8 74 d5 ff ff       	call   f0100040 <_panic>
		for (i = 0; i < KSTKGAP; i += PGSIZE)
			assert(check_va2pa(pgdir, base + i) == ~0);
	}

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102acc:	83 c0 01             	add    $0x1,%eax
f0102acf:	3d ff 03 00 00       	cmp    $0x3ff,%eax
f0102ad4:	0f 86 63 ff ff ff    	jbe    f0102a3d <mem_init+0x1657>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ada:	83 ec 0c             	sub    $0xc,%esp
f0102add:	68 c0 6e 10 f0       	push   $0xf0106ec0
f0102ae2:	e8 28 0d 00 00       	call   f010380f <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ae7:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102aec:	83 c4 10             	add    $0x10,%esp
f0102aef:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102af4:	77 15                	ja     f0102b0b <mem_init+0x1725>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102af6:	50                   	push   %eax
f0102af7:	68 48 60 10 f0       	push   $0xf0106048
f0102afc:	68 f2 00 00 00       	push   $0xf2
f0102b01:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102b06:	e8 35 d5 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b0b:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b10:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102b13:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b18:	e8 0a e0 ff ff       	call   f0100b27 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b1d:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b20:	83 e0 f3             	and    $0xfffffff3,%eax
f0102b23:	0d 23 00 05 80       	or     $0x80050023,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b28:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b2b:	83 ec 0c             	sub    $0xc,%esp
f0102b2e:	6a 00                	push   $0x0
f0102b30:	e8 93 e4 ff ff       	call   f0100fc8 <page_alloc>
f0102b35:	89 c3                	mov    %eax,%ebx
f0102b37:	83 c4 10             	add    $0x10,%esp
f0102b3a:	85 c0                	test   %eax,%eax
f0102b3c:	75 19                	jne    f0102b57 <mem_init+0x1771>
f0102b3e:	68 d0 70 10 f0       	push   $0xf01070d0
f0102b43:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102b48:	68 d7 04 00 00       	push   $0x4d7
f0102b4d:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102b52:	e8 e9 d4 ff ff       	call   f0100040 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b57:	83 ec 0c             	sub    $0xc,%esp
f0102b5a:	6a 00                	push   $0x0
f0102b5c:	e8 67 e4 ff ff       	call   f0100fc8 <page_alloc>
f0102b61:	89 c7                	mov    %eax,%edi
f0102b63:	83 c4 10             	add    $0x10,%esp
f0102b66:	85 c0                	test   %eax,%eax
f0102b68:	75 19                	jne    f0102b83 <mem_init+0x179d>
f0102b6a:	68 e6 70 10 f0       	push   $0xf01070e6
f0102b6f:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102b74:	68 d8 04 00 00       	push   $0x4d8
f0102b79:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102b7e:	e8 bd d4 ff ff       	call   f0100040 <_panic>
	assert((pp2 = page_alloc(0)));
f0102b83:	83 ec 0c             	sub    $0xc,%esp
f0102b86:	6a 00                	push   $0x0
f0102b88:	e8 3b e4 ff ff       	call   f0100fc8 <page_alloc>
f0102b8d:	89 c6                	mov    %eax,%esi
f0102b8f:	83 c4 10             	add    $0x10,%esp
f0102b92:	85 c0                	test   %eax,%eax
f0102b94:	75 19                	jne    f0102baf <mem_init+0x17c9>
f0102b96:	68 fc 70 10 f0       	push   $0xf01070fc
f0102b9b:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102ba0:	68 d9 04 00 00       	push   $0x4d9
f0102ba5:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102baa:	e8 91 d4 ff ff       	call   f0100040 <_panic>
	page_free(pp0);
f0102baf:	83 ec 0c             	sub    $0xc,%esp
f0102bb2:	53                   	push   %ebx
f0102bb3:	e8 86 e4 ff ff       	call   f010103e <page_free>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bb8:	89 f8                	mov    %edi,%eax
f0102bba:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0102bc0:	c1 f8 03             	sar    $0x3,%eax
f0102bc3:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bc6:	89 c2                	mov    %eax,%edx
f0102bc8:	c1 ea 0c             	shr    $0xc,%edx
f0102bcb:	83 c4 10             	add    $0x10,%esp
f0102bce:	3b 15 c8 de 1d f0    	cmp    0xf01ddec8,%edx
f0102bd4:	72 12                	jb     f0102be8 <mem_init+0x1802>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bd6:	50                   	push   %eax
f0102bd7:	68 24 60 10 f0       	push   $0xf0106024
f0102bdc:	6a 58                	push   $0x58
f0102bde:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0102be3:	e8 58 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102be8:	83 ec 04             	sub    $0x4,%esp
f0102beb:	68 00 10 00 00       	push   $0x1000
f0102bf0:	6a 01                	push   $0x1
	return (void *)(pa + KERNBASE);
f0102bf2:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102bf7:	50                   	push   %eax
f0102bf8:	e8 26 27 00 00       	call   f0105323 <memset>
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102bfd:	89 f0                	mov    %esi,%eax
f0102bff:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0102c05:	c1 f8 03             	sar    $0x3,%eax
f0102c08:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c0b:	89 c2                	mov    %eax,%edx
f0102c0d:	c1 ea 0c             	shr    $0xc,%edx
f0102c10:	83 c4 10             	add    $0x10,%esp
f0102c13:	3b 15 c8 de 1d f0    	cmp    0xf01ddec8,%edx
f0102c19:	72 12                	jb     f0102c2d <mem_init+0x1847>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c1b:	50                   	push   %eax
f0102c1c:	68 24 60 10 f0       	push   $0xf0106024
f0102c21:	6a 58                	push   $0x58
f0102c23:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0102c28:	e8 13 d4 ff ff       	call   f0100040 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c2d:	83 ec 04             	sub    $0x4,%esp
f0102c30:	68 00 10 00 00       	push   $0x1000
f0102c35:	6a 02                	push   $0x2
	return (void *)(pa + KERNBASE);
f0102c37:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c3c:	50                   	push   %eax
f0102c3d:	e8 e1 26 00 00       	call   f0105323 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c42:	6a 02                	push   $0x2
f0102c44:	68 00 10 00 00       	push   $0x1000
f0102c49:	57                   	push   %edi
f0102c4a:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0102c50:	e8 99 e6 ff ff       	call   f01012ee <page_insert>
	assert(pp1->pp_ref == 1);
f0102c55:	83 c4 20             	add    $0x20,%esp
f0102c58:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102c5d:	74 19                	je     f0102c78 <mem_init+0x1892>
f0102c5f:	68 cd 71 10 f0       	push   $0xf01071cd
f0102c64:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102c69:	68 de 04 00 00       	push   $0x4de
f0102c6e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102c73:	e8 c8 d3 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102c78:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102c7f:	01 01 01 
f0102c82:	74 19                	je     f0102c9d <mem_init+0x18b7>
f0102c84:	68 e0 6e 10 f0       	push   $0xf0106ee0
f0102c89:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102c8e:	68 df 04 00 00       	push   $0x4df
f0102c93:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102c98:	e8 a3 d3 ff ff       	call   f0100040 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102c9d:	6a 02                	push   $0x2
f0102c9f:	68 00 10 00 00       	push   $0x1000
f0102ca4:	56                   	push   %esi
f0102ca5:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0102cab:	e8 3e e6 ff ff       	call   f01012ee <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102cb0:	83 c4 10             	add    $0x10,%esp
f0102cb3:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102cba:	02 02 02 
f0102cbd:	74 19                	je     f0102cd8 <mem_init+0x18f2>
f0102cbf:	68 04 6f 10 f0       	push   $0xf0106f04
f0102cc4:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102cc9:	68 e1 04 00 00       	push   $0x4e1
f0102cce:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102cd3:	e8 68 d3 ff ff       	call   f0100040 <_panic>
	assert(pp2->pp_ref == 1);
f0102cd8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102cdd:	74 19                	je     f0102cf8 <mem_init+0x1912>
f0102cdf:	68 ef 71 10 f0       	push   $0xf01071ef
f0102ce4:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102ce9:	68 e2 04 00 00       	push   $0x4e2
f0102cee:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102cf3:	e8 48 d3 ff ff       	call   f0100040 <_panic>
	assert(pp1->pp_ref == 0);
f0102cf8:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102cfd:	74 19                	je     f0102d18 <mem_init+0x1932>
f0102cff:	68 59 72 10 f0       	push   $0xf0107259
f0102d04:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102d09:	68 e3 04 00 00       	push   $0x4e3
f0102d0e:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102d13:	e8 28 d3 ff ff       	call   f0100040 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102d18:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102d1f:	03 03 03 
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102d22:	89 f0                	mov    %esi,%eax
f0102d24:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0102d2a:	c1 f8 03             	sar    $0x3,%eax
f0102d2d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d30:	89 c2                	mov    %eax,%edx
f0102d32:	c1 ea 0c             	shr    $0xc,%edx
f0102d35:	3b 15 c8 de 1d f0    	cmp    0xf01ddec8,%edx
f0102d3b:	72 12                	jb     f0102d4f <mem_init+0x1969>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d3d:	50                   	push   %eax
f0102d3e:	68 24 60 10 f0       	push   $0xf0106024
f0102d43:	6a 58                	push   $0x58
f0102d45:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0102d4a:	e8 f1 d2 ff ff       	call   f0100040 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102d4f:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102d56:	03 03 03 
f0102d59:	74 19                	je     f0102d74 <mem_init+0x198e>
f0102d5b:	68 28 6f 10 f0       	push   $0xf0106f28
f0102d60:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102d65:	68 e5 04 00 00       	push   $0x4e5
f0102d6a:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102d6f:	e8 cc d2 ff ff       	call   f0100040 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102d74:	83 ec 08             	sub    $0x8,%esp
f0102d77:	68 00 10 00 00       	push   $0x1000
f0102d7c:	ff 35 cc de 1d f0    	pushl  0xf01ddecc
f0102d82:	e8 21 e5 ff ff       	call   f01012a8 <page_remove>
	assert(pp2->pp_ref == 0);
f0102d87:	83 c4 10             	add    $0x10,%esp
f0102d8a:	66 83 7e 04 00       	cmpw   $0x0,0x4(%esi)
f0102d8f:	74 19                	je     f0102daa <mem_init+0x19c4>
f0102d91:	68 27 72 10 f0       	push   $0xf0107227
f0102d96:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102d9b:	68 e7 04 00 00       	push   $0x4e7
f0102da0:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102da5:	e8 96 d2 ff ff       	call   f0100040 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102daa:	8b 0d cc de 1d f0    	mov    0xf01ddecc,%ecx
f0102db0:	8b 11                	mov    (%ecx),%edx
f0102db2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102db8:	89 d8                	mov    %ebx,%eax
f0102dba:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0102dc0:	c1 f8 03             	sar    $0x3,%eax
f0102dc3:	c1 e0 0c             	shl    $0xc,%eax
f0102dc6:	39 c2                	cmp    %eax,%edx
f0102dc8:	74 19                	je     f0102de3 <mem_init+0x19fd>
f0102dca:	68 b0 68 10 f0       	push   $0xf01068b0
f0102dcf:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102dd4:	68 ea 04 00 00       	push   $0x4ea
f0102dd9:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102dde:	e8 5d d2 ff ff       	call   f0100040 <_panic>
	kern_pgdir[0] = 0;
f0102de3:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
	assert(pp0->pp_ref == 1);
f0102de9:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102dee:	74 19                	je     f0102e09 <mem_init+0x1a23>
f0102df0:	68 de 71 10 f0       	push   $0xf01071de
f0102df5:	68 db 6f 10 f0       	push   $0xf0106fdb
f0102dfa:	68 ec 04 00 00       	push   $0x4ec
f0102dff:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102e04:	e8 37 d2 ff ff       	call   f0100040 <_panic>
	pp0->pp_ref = 0;
f0102e09:	66 c7 43 04 00 00    	movw   $0x0,0x4(%ebx)

	// free the pages we took
	page_free(pp0);
f0102e0f:	83 ec 0c             	sub    $0xc,%esp
f0102e12:	53                   	push   %ebx
f0102e13:	e8 26 e2 ff ff       	call   f010103e <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102e18:	c7 04 24 54 6f 10 f0 	movl   $0xf0106f54,(%esp)
f0102e1f:	e8 eb 09 00 00       	call   f010380f <cprintf>
f0102e24:	83 c4 10             	add    $0x10,%esp
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102e27:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102e2a:	5b                   	pop    %ebx
f0102e2b:	5e                   	pop    %esi
f0102e2c:	5f                   	pop    %edi
f0102e2d:	5d                   	pop    %ebp
f0102e2e:	c3                   	ret    

f0102e2f <user_mem_check>:
// Returns 0 if the user program can access this range of addresses,
// and -E_FAULT otherwise.
//
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
f0102e2f:	55                   	push   %ebp
f0102e30:	89 e5                	mov    %esp,%ebp
f0102e32:	57                   	push   %edi
f0102e33:	56                   	push   %esi
f0102e34:	53                   	push   %ebx
f0102e35:	83 ec 1c             	sub    $0x1c,%esp
f0102e38:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102e3b:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// LAB 3: Your code here.

	// step 1 : check below ULIM
  uintptr_t va_beg = (uintptr_t)va;
  uintptr_t va_end = va_beg + len;
f0102e3e:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102e41:	03 75 10             	add    0x10(%ebp),%esi
  if (va_beg >= ULIM || va_end >= ULIM) {
f0102e44:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0102e4a:	77 09                	ja     f0102e55 <user_mem_check+0x26>
f0102e4c:	81 7d 0c ff ff 7f ef 	cmpl   $0xef7fffff,0xc(%ebp)
f0102e53:	76 1f                	jbe    f0102e74 <user_mem_check+0x45>
    user_mem_check_addr = (va_beg >= ULIM) ? va_beg : ULIM;
f0102e55:	81 7d 0c 00 00 80 ef 	cmpl   $0xef800000,0xc(%ebp)
f0102e5c:	b8 00 00 80 ef       	mov    $0xef800000,%eax
f0102e61:	0f 43 45 0c          	cmovae 0xc(%ebp),%eax
f0102e65:	a3 60 d2 1d f0       	mov    %eax,0xf01dd260
    return -E_FAULT;
f0102e6a:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102e6f:	e9 a7 00 00 00       	jmp    f0102f1b <user_mem_check+0xec>
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
f0102e74:	8b 55 0c             	mov    0xc(%ebp),%edx
f0102e77:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
f0102e7d:	81 c6 ff 0f 00 00    	add    $0xfff,%esi
f0102e83:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e89:	a1 c8 de 1d f0       	mov    0xf01ddec8,%eax
f0102e8e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0102e91:	89 7d 08             	mov    %edi,0x8(%ebp)
  while (va_beg2 < va_end2) {
f0102e94:	eb 7c                	jmp    f0102f12 <user_mem_check+0xe3>

    // check page table is present ?
    if (!(env->env_pgdir[PDX(va_beg2)] & PTE_P)) {
f0102e96:	89 d1                	mov    %edx,%ecx
f0102e98:	c1 e9 16             	shr    $0x16,%ecx
f0102e9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102e9e:	8b 40 60             	mov    0x60(%eax),%eax
f0102ea1:	8b 04 88             	mov    (%eax,%ecx,4),%eax
f0102ea4:	a8 01                	test   $0x1,%al
f0102ea6:	75 14                	jne    f0102ebc <user_mem_check+0x8d>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102ea8:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102eab:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102eaf:	89 15 60 d2 1d f0    	mov    %edx,0xf01dd260
      return -E_FAULT;
f0102eb5:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102eba:	eb 5f                	jmp    f0102f1b <user_mem_check+0xec>
    }

    // get current page table kernel va
    uint32_t* pt_kva = KADDR(PTE_ADDR(env->env_pgdir[PDX(va_beg2)]));
f0102ebc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0102ec1:	89 c1                	mov    %eax,%ecx
f0102ec3:	c1 e9 0c             	shr    $0xc,%ecx
f0102ec6:	3b 4d e4             	cmp    -0x1c(%ebp),%ecx
f0102ec9:	72 15                	jb     f0102ee0 <user_mem_check+0xb1>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ecb:	50                   	push   %eax
f0102ecc:	68 24 60 10 f0       	push   $0xf0106024
f0102ed1:	68 14 03 00 00       	push   $0x314
f0102ed6:	68 b5 6f 10 f0       	push   $0xf0106fb5
f0102edb:	e8 60 d1 ff ff       	call   f0100040 <_panic>

    // check page is present & permissions
    if (!((pt_kva[PTX(va_beg2)] & perm) == perm)) {
f0102ee0:	89 d1                	mov    %edx,%ecx
f0102ee2:	c1 e9 0c             	shr    $0xc,%ecx
f0102ee5:	81 e1 ff 03 00 00    	and    $0x3ff,%ecx
f0102eeb:	89 df                	mov    %ebx,%edi
f0102eed:	23 bc 88 00 00 00 f0 	and    -0x10000000(%eax,%ecx,4),%edi
f0102ef4:	39 fb                	cmp    %edi,%ebx
f0102ef6:	74 14                	je     f0102f0c <user_mem_check+0xdd>
      user_mem_check_addr = (va_beg2 > va_beg) ? va_beg2 : va_beg;
f0102ef8:	3b 55 0c             	cmp    0xc(%ebp),%edx
f0102efb:	0f 42 55 0c          	cmovb  0xc(%ebp),%edx
f0102eff:	89 15 60 d2 1d f0    	mov    %edx,0xf01dd260
      return -E_FAULT;
f0102f05:	b8 fa ff ff ff       	mov    $0xfffffffa,%eax
f0102f0a:	eb 0f                	jmp    f0102f1b <user_mem_check+0xec>
    }

    va_beg2 += PGSIZE;
f0102f0c:	81 c2 00 10 00 00    	add    $0x1000,%edx
  }

  // step 2 : check present & permission
  uintptr_t va_beg2 = ROUNDDOWN(va_beg, PGSIZE);
  uintptr_t va_end2 = ROUNDUP(va_end, PGSIZE);
  while (va_beg2 < va_end2) {
f0102f12:	39 f2                	cmp    %esi,%edx
f0102f14:	72 80                	jb     f0102e96 <user_mem_check+0x67>
      return -E_FAULT;
    }

    va_beg2 += PGSIZE;
  }
  return 0;
f0102f16:	b8 00 00 00 00       	mov    $0x0,%eax

}
f0102f1b:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102f1e:	5b                   	pop    %ebx
f0102f1f:	5e                   	pop    %esi
f0102f20:	5f                   	pop    %edi
f0102f21:	5d                   	pop    %ebp
f0102f22:	c3                   	ret    

f0102f23 <user_mem_assert>:
// If it cannot, 'env' is destroyed and, if env is the current
// environment, this function will not return.
//
void
user_mem_assert(struct Env *env, const void *va, size_t len, int perm)
{
f0102f23:	55                   	push   %ebp
f0102f24:	89 e5                	mov    %esp,%ebp
f0102f26:	53                   	push   %ebx
f0102f27:	83 ec 04             	sub    $0x4,%esp
f0102f2a:	8b 5d 08             	mov    0x8(%ebp),%ebx
	if (user_mem_check(env, va, len, perm | PTE_U) < 0) {
f0102f2d:	8b 45 14             	mov    0x14(%ebp),%eax
f0102f30:	83 c8 04             	or     $0x4,%eax
f0102f33:	50                   	push   %eax
f0102f34:	ff 75 10             	pushl  0x10(%ebp)
f0102f37:	ff 75 0c             	pushl  0xc(%ebp)
f0102f3a:	53                   	push   %ebx
f0102f3b:	e8 ef fe ff ff       	call   f0102e2f <user_mem_check>
f0102f40:	83 c4 10             	add    $0x10,%esp
f0102f43:	85 c0                	test   %eax,%eax
f0102f45:	79 21                	jns    f0102f68 <user_mem_assert+0x45>
		cprintf("[%08x] user_mem_check assertion failure for "
f0102f47:	83 ec 04             	sub    $0x4,%esp
f0102f4a:	ff 35 60 d2 1d f0    	pushl  0xf01dd260
f0102f50:	ff 73 48             	pushl  0x48(%ebx)
f0102f53:	68 80 6f 10 f0       	push   $0xf0106f80
f0102f58:	e8 b2 08 00 00       	call   f010380f <cprintf>
			"va %08x\n", env->env_id, user_mem_check_addr);
		env_destroy(env);	// may not return
f0102f5d:	89 1c 24             	mov    %ebx,(%esp)
f0102f60:	e8 e3 05 00 00       	call   f0103548 <env_destroy>
f0102f65:	83 c4 10             	add    $0x10,%esp
	}
}
f0102f68:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0102f6b:	c9                   	leave  
f0102f6c:	c3                   	ret    

f0102f6d <region_alloc>:
// Pages should be writable by user and kernel.
// Panic if any allocation attempt fails.
//
static void
region_alloc(struct Env *e, void *va, size_t len)
{
f0102f6d:	55                   	push   %ebp
f0102f6e:	89 e5                	mov    %esp,%ebp
f0102f70:	57                   	push   %edi
f0102f71:	56                   	push   %esi
f0102f72:	53                   	push   %ebx
f0102f73:	83 ec 0c             	sub    $0xc,%esp
f0102f76:	89 c7                	mov    %eax,%edi
	//
	// Hint: It is easier to use region_alloc if the caller can pass
	//   'va' and 'len' values that are not page-aligned.
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
f0102f78:	89 d3                	mov    %edx,%ebx
f0102f7a:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
f0102f80:	8d b4 0a ff 0f 00 00 	lea    0xfff(%edx,%ecx,1),%esi
f0102f87:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
	
	while (vaBegin<vaEnd){
f0102f8d:	eb 58                	jmp    f0102fe7 <region_alloc+0x7a>
		struct PageInfo *p = page_alloc(0);
f0102f8f:	83 ec 0c             	sub    $0xc,%esp
f0102f92:	6a 00                	push   $0x0
f0102f94:	e8 2f e0 ff ff       	call   f0100fc8 <page_alloc>
		if (p == NULL)
f0102f99:	83 c4 10             	add    $0x10,%esp
f0102f9c:	85 c0                	test   %eax,%eax
f0102f9e:	75 17                	jne    f0102fb7 <region_alloc+0x4a>
			panic("Page alloc failed!");
f0102fa0:	83 ec 04             	sub    $0x4,%esp
f0102fa3:	68 f4 72 10 f0       	push   $0xf01072f4
f0102fa8:	68 35 01 00 00       	push   $0x135
f0102fad:	68 07 73 10 f0       	push   $0xf0107307
f0102fb2:	e8 89 d0 ff ff       	call   f0100040 <_panic>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
f0102fb7:	6a 06                	push   $0x6
f0102fb9:	53                   	push   %ebx
f0102fba:	50                   	push   %eax
f0102fbb:	ff 77 60             	pushl  0x60(%edi)
f0102fbe:	e8 2b e3 ff ff       	call   f01012ee <page_insert>
f0102fc3:	83 c4 10             	add    $0x10,%esp
f0102fc6:	85 c0                	test   %eax,%eax
f0102fc8:	74 17                	je     f0102fe1 <region_alloc+0x74>
			panic("Page table couldn't be allocated!!");
f0102fca:	83 ec 04             	sub    $0x4,%esp
f0102fcd:	68 4c 73 10 f0       	push   $0xf010734c
f0102fd2:	68 37 01 00 00       	push   $0x137
f0102fd7:	68 07 73 10 f0       	push   $0xf0107307
f0102fdc:	e8 5f d0 ff ff       	call   f0100040 <_panic>
		}
		vaBegin += PGSIZE;
f0102fe1:	81 c3 00 10 00 00    	add    $0x1000,%ebx
	//   You should round va down, and round (va + len) up.
	//   (Watch out for corner-cases!)
	uintptr_t vaBegin = ROUNDDOWN((uintptr_t)va, PGSIZE);
	uintptr_t vaEnd = ROUNDUP(((uintptr_t)va) + len, PGSIZE);
	
	while (vaBegin<vaEnd){
f0102fe7:	39 f3                	cmp    %esi,%ebx
f0102fe9:	72 a4                	jb     f0102f8f <region_alloc+0x22>
		else if (page_insert(e->env_pgdir,p,(void*)vaBegin,PTE_W|PTE_U)){
			panic("Page table couldn't be allocated!!");
		}
		vaBegin += PGSIZE;
	}
}
f0102feb:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0102fee:	5b                   	pop    %ebx
f0102fef:	5e                   	pop    %esi
f0102ff0:	5f                   	pop    %edi
f0102ff1:	5d                   	pop    %ebp
f0102ff2:	c3                   	ret    

f0102ff3 <envid2env>:
//   On success, sets *env_store to the environment.
//   On error, sets *env_store to NULL.
//
int
envid2env(envid_t envid, struct Env **env_store, bool checkperm)
{
f0102ff3:	55                   	push   %ebp
f0102ff4:	89 e5                	mov    %esp,%ebp
f0102ff6:	56                   	push   %esi
f0102ff7:	53                   	push   %ebx
f0102ff8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ffb:	8b 55 10             	mov    0x10(%ebp),%edx
	struct Env *e;

	// If envid is zero, return the current environment.
	if (envid == 0) {
f0102ffe:	85 c0                	test   %eax,%eax
f0103000:	75 1a                	jne    f010301c <envid2env+0x29>
		*env_store = curenv;
f0103002:	e8 40 29 00 00       	call   f0105947 <cpunum>
f0103007:	6b c0 74             	imul   $0x74,%eax,%eax
f010300a:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103010:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0103013:	89 01                	mov    %eax,(%ecx)
		return 0;
f0103015:	b8 00 00 00 00       	mov    $0x0,%eax
f010301a:	eb 70                	jmp    f010308c <envid2env+0x99>
	// Look up the Env structure via the index part of the envid,
	// then check the env_id field in that struct Env
	// to ensure that the envid is not stale
	// (i.e., does not refer to a _previous_ environment
	// that used the same slot in the envs[] array).
	e = &envs[ENVX(envid)];
f010301c:	89 c3                	mov    %eax,%ebx
f010301e:	81 e3 ff 03 00 00    	and    $0x3ff,%ebx
f0103024:	6b db 7c             	imul   $0x7c,%ebx,%ebx
f0103027:	03 1d 6c d2 1d f0    	add    0xf01dd26c,%ebx
	if (e->env_status == ENV_FREE || e->env_id != envid) {
f010302d:	83 7b 54 00          	cmpl   $0x0,0x54(%ebx)
f0103031:	74 05                	je     f0103038 <envid2env+0x45>
f0103033:	39 43 48             	cmp    %eax,0x48(%ebx)
f0103036:	74 10                	je     f0103048 <envid2env+0x55>
		*env_store = 0;
f0103038:	8b 45 0c             	mov    0xc(%ebp),%eax
f010303b:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f0103041:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103046:	eb 44                	jmp    f010308c <envid2env+0x99>
	// Check that the calling environment has legitimate permission
	// to manipulate the specified environment.
	// If checkperm is set, the specified environment
	// must be either the current environment
	// or an immediate child of the current environment.
	if (checkperm && e != curenv && e->env_parent_id != curenv->env_id) {
f0103048:	84 d2                	test   %dl,%dl
f010304a:	74 36                	je     f0103082 <envid2env+0x8f>
f010304c:	e8 f6 28 00 00       	call   f0105947 <cpunum>
f0103051:	6b c0 74             	imul   $0x74,%eax,%eax
f0103054:	39 98 48 e0 1d f0    	cmp    %ebx,-0xfe21fb8(%eax)
f010305a:	74 26                	je     f0103082 <envid2env+0x8f>
f010305c:	8b 73 4c             	mov    0x4c(%ebx),%esi
f010305f:	e8 e3 28 00 00       	call   f0105947 <cpunum>
f0103064:	6b c0 74             	imul   $0x74,%eax,%eax
f0103067:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f010306d:	3b 70 48             	cmp    0x48(%eax),%esi
f0103070:	74 10                	je     f0103082 <envid2env+0x8f>
		*env_store = 0;
f0103072:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103075:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		return -E_BAD_ENV;
f010307b:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f0103080:	eb 0a                	jmp    f010308c <envid2env+0x99>
	}

	*env_store = e;
f0103082:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103085:	89 18                	mov    %ebx,(%eax)
	return 0;
f0103087:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010308c:	5b                   	pop    %ebx
f010308d:	5e                   	pop    %esi
f010308e:	5d                   	pop    %ebp
f010308f:	c3                   	ret    

f0103090 <env_init_percpu>:
}

// Load GDT and segment descriptors.
void
env_init_percpu(void)
{
f0103090:	55                   	push   %ebp
f0103091:	89 e5                	mov    %esp,%ebp
}

static __inline void
lgdt(void *p)
{
	__asm __volatile("lgdt (%0)" : : "r" (p));
f0103093:	b8 40 03 12 f0       	mov    $0xf0120340,%eax
f0103098:	0f 01 10             	lgdtl  (%eax)
	lgdt(&gdt_pd);
	// The kernel never uses GS or FS, so we leave those set to
	// the user data segment.
	asm volatile("movw %%ax,%%gs" :: "a" (GD_UD|3));
f010309b:	b8 23 00 00 00       	mov    $0x23,%eax
f01030a0:	8e e8                	mov    %eax,%gs
	asm volatile("movw %%ax,%%fs" :: "a" (GD_UD|3));
f01030a2:	8e e0                	mov    %eax,%fs
	// The kernel does use ES, DS, and SS.  We'll change between
	// the kernel and user data segments as needed.
	asm volatile("movw %%ax,%%es" :: "a" (GD_KD));
f01030a4:	b0 10                	mov    $0x10,%al
f01030a6:	8e c0                	mov    %eax,%es
	asm volatile("movw %%ax,%%ds" :: "a" (GD_KD));
f01030a8:	8e d8                	mov    %eax,%ds
	asm volatile("movw %%ax,%%ss" :: "a" (GD_KD));
f01030aa:	8e d0                	mov    %eax,%ss
	// Load the kernel text segment into CS.
	asm volatile("ljmp %0,$1f\n 1:\n" :: "i" (GD_KT));
f01030ac:	ea b3 30 10 f0 08 00 	ljmp   $0x8,$0xf01030b3
}

static __inline void
lldt(uint16_t sel)
{
	__asm __volatile("lldt %0" : : "r" (sel));
f01030b3:	b0 00                	mov    $0x0,%al
f01030b5:	0f 00 d0             	lldt   %ax
	// For good measure, clear the local descriptor table (LDT),
	// since we don't use it.
	lldt(0);
}
f01030b8:	5d                   	pop    %ebp
f01030b9:	c3                   	ret    

f01030ba <env_init>:
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
f01030ba:	8b 0d 6c d2 1d f0    	mov    0xf01dd26c,%ecx
f01030c0:	8b 15 70 d2 1d f0    	mov    0xf01dd270,%edx
f01030c6:	89 c8                	mov    %ecx,%eax
f01030c8:	81 c1 00 f0 01 00    	add    $0x1f000,%ecx
f01030ce:	c7 40 48 00 00 00 00 	movl   $0x0,0x48(%eax)
		envs[i].env_link = NULL;
f01030d5:	c7 40 44 00 00 00 00 	movl   $0x0,0x44(%eax)

		if (!env_free_list){		
f01030dc:	85 d2                	test   %edx,%edx
f01030de:	74 05                	je     f01030e5 <env_init+0x2b>
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
		}
		else{
		envs[i-1].env_link = &envs[i];
f01030e0:	89 40 c8             	mov    %eax,-0x38(%eax)
f01030e3:	eb 02                	jmp    f01030e7 <env_init+0x2d>
	for (i = 0; i < NENV; i++) {
		envs[i].env_id = 0;
		envs[i].env_link = NULL;

		if (!env_free_list){		
		env_free_list = &envs[i];	// if env_free_list is 0 then point to current env
f01030e5:	89 c2                	mov    %eax,%edx
f01030e7:	83 c0 7c             	add    $0x7c,%eax
env_init(void)
{
	// Set up envs array
	// LAB 3: Your code here.
	int i;
	for (i = 0; i < NENV; i++) {
f01030ea:	39 c8                	cmp    %ecx,%eax
f01030ec:	75 e0                	jne    f01030ce <env_init+0x14>
// they are in the envs array (i.e., so that the first call to
// env_alloc() returns envs[0]).
//
void
env_init(void)
{
f01030ee:	55                   	push   %ebp
f01030ef:	89 e5                	mov    %esp,%ebp
f01030f1:	89 15 70 d2 1d f0    	mov    %edx,0xf01dd270
		}	//Previous env is linked to this current env
	}
	

	// Per-CPU part of the initialization
	env_init_percpu();
f01030f7:	e8 94 ff ff ff       	call   f0103090 <env_init_percpu>
}
f01030fc:	5d                   	pop    %ebp
f01030fd:	c3                   	ret    

f01030fe <env_alloc>:
//	-E_NO_FREE_ENV if all NENVS environments are allocated
//	-E_NO_MEM on memory exhaustion
//
int
env_alloc(struct Env **newenv_store, envid_t parent_id)
{
f01030fe:	55                   	push   %ebp
f01030ff:	89 e5                	mov    %esp,%ebp
f0103101:	53                   	push   %ebx
f0103102:	83 ec 04             	sub    $0x4,%esp
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
f0103105:	8b 1d 70 d2 1d f0    	mov    0xf01dd270,%ebx
f010310b:	85 db                	test   %ebx,%ebx
f010310d:	0f 84 34 01 00 00    	je     f0103247 <env_alloc+0x149>
{
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
f0103113:	83 ec 0c             	sub    $0xc,%esp
f0103116:	6a 01                	push   $0x1
f0103118:	e8 ab de ff ff       	call   f0100fc8 <page_alloc>
f010311d:	83 c4 10             	add    $0x10,%esp
f0103120:	85 c0                	test   %eax,%eax
f0103122:	0f 84 26 01 00 00    	je     f010324e <env_alloc+0x150>
	//	is an exception -- you need to increment env_pgdir's
	//	pp_ref for env_free to work correctly.
	//    - The functions in kern/pmap.h are handy.

	// LAB 3: Your code here.
	p->pp_ref++;
f0103128:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	user_mem_assert(struct Env *env, const void *va, size_t len, int perm);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010312d:	2b 05 d0 de 1d f0    	sub    0xf01dded0,%eax
f0103133:	c1 f8 03             	sar    $0x3,%eax
f0103136:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103139:	89 c2                	mov    %eax,%edx
f010313b:	c1 ea 0c             	shr    $0xc,%edx
f010313e:	3b 15 c8 de 1d f0    	cmp    0xf01ddec8,%edx
f0103144:	72 12                	jb     f0103158 <env_alloc+0x5a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103146:	50                   	push   %eax
f0103147:	68 24 60 10 f0       	push   $0xf0106024
f010314c:	6a 58                	push   $0x58
f010314e:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0103153:	e8 e8 ce ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0103158:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010315d:	89 43 60             	mov    %eax,0x60(%ebx)
	e->env_pgdir = (pde_t*)page2kva(p);
f0103160:	b8 00 00 00 00       	mov    $0x0,%eax

	for (i = 0; i < NPDENTRIES; ++i) {
		e->env_pgdir[i] = kern_pgdir[i];  //Mapping all 1024 entries of the kernel
f0103165:	8b 15 cc de 1d f0    	mov    0xf01ddecc,%edx
f010316b:	8b 0c 02             	mov    (%edx,%eax,1),%ecx
f010316e:	8b 53 60             	mov    0x60(%ebx),%edx
f0103171:	89 0c 02             	mov    %ecx,(%edx,%eax,1)
f0103174:	83 c0 04             	add    $0x4,%eax

	// LAB 3: Your code here.
	p->pp_ref++;
	e->env_pgdir = (pde_t*)page2kva(p);

	for (i = 0; i < NPDENTRIES; ++i) {
f0103177:	3d 00 10 00 00       	cmp    $0x1000,%eax
f010317c:	75 e7                	jne    f0103165 <env_alloc+0x67>
						 //pgdir to the environment pgdir
	}
	
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
f010317e:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103181:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103186:	77 15                	ja     f010319d <env_alloc+0x9f>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0103188:	50                   	push   %eax
f0103189:	68 48 60 10 f0       	push   $0xf0106048
f010318e:	68 d0 00 00 00       	push   $0xd0
f0103193:	68 07 73 10 f0       	push   $0xf0107307
f0103198:	e8 a3 ce ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010319d:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f01031a3:	83 ca 05             	or     $0x5,%edx
f01031a6:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate and set up the page directory for this environment.
	if ((r = env_setup_vm(e)) < 0)
		return r;

	// Generate an env_id for this environment.
	generation = (e->env_id + (1 << ENVGENSHIFT)) & ~(NENV - 1);
f01031ac:	8b 43 48             	mov    0x48(%ebx),%eax
f01031af:	05 00 10 00 00       	add    $0x1000,%eax
	if (generation <= 0)	// Don't create a negative env_id.
f01031b4:	25 00 fc ff ff       	and    $0xfffffc00,%eax
		generation = 1 << ENVGENSHIFT;
f01031b9:	ba 00 10 00 00       	mov    $0x1000,%edx
f01031be:	0f 4e c2             	cmovle %edx,%eax
	e->env_id = generation | (e - envs);
f01031c1:	89 da                	mov    %ebx,%edx
f01031c3:	2b 15 6c d2 1d f0    	sub    0xf01dd26c,%edx
f01031c9:	c1 fa 02             	sar    $0x2,%edx
f01031cc:	69 d2 df 7b ef bd    	imul   $0xbdef7bdf,%edx,%edx
f01031d2:	09 d0                	or     %edx,%eax
f01031d4:	89 43 48             	mov    %eax,0x48(%ebx)

	// Set the basic status variables.
	e->env_parent_id = parent_id;
f01031d7:	8b 45 0c             	mov    0xc(%ebp),%eax
f01031da:	89 43 4c             	mov    %eax,0x4c(%ebx)
	e->env_type = ENV_TYPE_USER;
f01031dd:	c7 43 50 00 00 00 00 	movl   $0x0,0x50(%ebx)
	e->env_status = ENV_RUNNABLE;
f01031e4:	c7 43 54 02 00 00 00 	movl   $0x2,0x54(%ebx)
	e->env_runs = 0;
f01031eb:	c7 43 58 00 00 00 00 	movl   $0x0,0x58(%ebx)

	// Clear out all the saved register state,
	// to prevent the register values
	// of a prior environment inhabiting this Env structure
	// from "leaking" into our new environment.
	memset(&e->env_tf, 0, sizeof(e->env_tf));
f01031f2:	83 ec 04             	sub    $0x4,%esp
f01031f5:	6a 44                	push   $0x44
f01031f7:	6a 00                	push   $0x0
f01031f9:	53                   	push   %ebx
f01031fa:	e8 24 21 00 00       	call   f0105323 <memset>
	// The low 2 bits of each segment register contains the
	// Requestor Privilege Level (RPL); 3 means user mode.  When
	// we switch privilege levels, the hardware does various
	// checks involving the RPL and the Descriptor Privilege Level
	// (DPL) stored in the descriptors themselves.
	e->env_tf.tf_ds = GD_UD | 3;
f01031ff:	66 c7 43 24 23 00    	movw   $0x23,0x24(%ebx)
	e->env_tf.tf_es = GD_UD | 3;
f0103205:	66 c7 43 20 23 00    	movw   $0x23,0x20(%ebx)
	e->env_tf.tf_ss = GD_UD | 3;
f010320b:	66 c7 43 40 23 00    	movw   $0x23,0x40(%ebx)
	e->env_tf.tf_esp = USTACKTOP;
f0103211:	c7 43 3c 00 e0 bf ee 	movl   $0xeebfe000,0x3c(%ebx)
	e->env_tf.tf_cs = GD_UT | 3;
f0103218:	66 c7 43 34 1b 00    	movw   $0x1b,0x34(%ebx)
	// You will set e->env_tf.tf_eip later.

	// Enable interrupts while in user mode.
	// LAB 4: Your code here.
	e->env_tf.tf_eflags |= FL_IF;  //Modification for exercise 13
f010321e:	81 4b 38 00 02 00 00 	orl    $0x200,0x38(%ebx)

	// Clear the page fault handler until user installs one.
	e->env_pgfault_upcall = 0;
f0103225:	c7 43 64 00 00 00 00 	movl   $0x0,0x64(%ebx)

	// Also clear the IPC receiving flag.
	e->env_ipc_recving = 0;
f010322c:	c6 43 68 00          	movb   $0x0,0x68(%ebx)

	// commit the allocation
	env_free_list = e->env_link;
f0103230:	8b 43 44             	mov    0x44(%ebx),%eax
f0103233:	a3 70 d2 1d f0       	mov    %eax,0xf01dd270
	*newenv_store = e;
f0103238:	8b 45 08             	mov    0x8(%ebp),%eax
f010323b:	89 18                	mov    %ebx,(%eax)

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
f010323d:	83 c4 10             	add    $0x10,%esp
f0103240:	b8 00 00 00 00       	mov    $0x0,%eax
f0103245:	eb 0c                	jmp    f0103253 <env_alloc+0x155>
	int32_t generation;
	int r;
	struct Env *e;

	if (!(e = env_free_list))
		return -E_NO_FREE_ENV;
f0103247:	b8 fb ff ff ff       	mov    $0xfffffffb,%eax
f010324c:	eb 05                	jmp    f0103253 <env_alloc+0x155>
	int i;
	struct PageInfo *p = NULL;

	// Allocate a page for the page directory
	if (!(p = page_alloc(ALLOC_ZERO)))
		return -E_NO_MEM;
f010324e:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
	env_free_list = e->env_link;
	*newenv_store = e;

	// cprintf("[%08x] new env %08x\n", curenv ? curenv->env_id : 0, e->env_id);
	return 0;
}
f0103253:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103256:	c9                   	leave  
f0103257:	c3                   	ret    

f0103258 <env_create>:
// before running the first user-mode environment.
// The new env's parent ID is set to 0.
//
void
env_create(uint8_t *binary, enum EnvType type)
{
f0103258:	55                   	push   %ebp
f0103259:	89 e5                	mov    %esp,%ebp
f010325b:	57                   	push   %edi
f010325c:	56                   	push   %esi
f010325d:	53                   	push   %ebx
f010325e:	83 ec 34             	sub    $0x34,%esp
f0103261:	8b 7d 08             	mov    0x8(%ebp),%edi
	// LAB 3: Your code here.
	int r;
	struct Env *env;
	r = env_alloc( &env, 0);
f0103264:	6a 00                	push   $0x0
f0103266:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0103269:	50                   	push   %eax
f010326a:	e8 8f fe ff ff       	call   f01030fe <env_alloc>
	if (r){
f010326f:	83 c4 10             	add    $0x10,%esp
f0103272:	85 c0                	test   %eax,%eax
f0103274:	74 15                	je     f010328b <env_create+0x33>
	panic("env_alloc: %e", r);
f0103276:	50                   	push   %eax
f0103277:	68 12 73 10 f0       	push   $0xf0107312
f010327c:	68 b2 01 00 00       	push   $0x1b2
f0103281:	68 07 73 10 f0       	push   $0xf0107307
f0103286:	e8 b5 cd ff ff       	call   f0100040 <_panic>
	}
	
	load_icode(env,binary);
f010328b:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010328e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Get the beginning and end of program header table
	//Details of struct proghdr are in /lab/inc/elf.h

	// is this a valid ELF?
	
	if (((struct Elf*)binary)->e_magic != ELF_MAGIC)
f0103291:	81 3f 7f 45 4c 46    	cmpl   $0x464c457f,(%edi)
f0103297:	74 17                	je     f01032b0 <env_create+0x58>
	{
		panic ("Not a valid ELF binary image");
f0103299:	83 ec 04             	sub    $0x4,%esp
f010329c:	68 20 73 10 f0       	push   $0xf0107320
f01032a1:	68 81 01 00 00       	push   $0x181
f01032a6:	68 07 73 10 f0       	push   $0xf0107307
f01032ab:	e8 90 cd ff ff       	call   f0100040 <_panic>
	}

	struct Proghdr *ph =(struct Proghdr *)(binary + ((struct Elf*)binary)->e_phoff); //phoff is the offset
f01032b0:	89 fb                	mov    %edi,%ebx
f01032b2:	03 5f 1c             	add    0x1c(%edi),%ebx
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
f01032b5:	0f b7 77 2c          	movzwl 0x2c(%edi),%esi
f01032b9:	c1 e6 05             	shl    $0x5,%esi
f01032bc:	01 de                	add    %ebx,%esi
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));
f01032be:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032c1:	8b 40 60             	mov    0x60(%eax),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01032c4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01032c9:	77 15                	ja     f01032e0 <env_create+0x88>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01032cb:	50                   	push   %eax
f01032cc:	68 48 60 10 f0       	push   $0xf0106048
f01032d1:	68 88 01 00 00       	push   $0x188
f01032d6:	68 07 73 10 f0       	push   $0xf0107307
f01032db:	e8 60 cd ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01032e0:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f01032e5:	0f 22 d8             	mov    %eax,%cr3
f01032e8:	eb 60                	jmp    f010334a <env_create+0xf2>

	for (;ph<phEnd;++ph){
		if (ph->p_type == ELF_PROG_LOAD){	//Check whether the type is ELF_PROG_LOAD
f01032ea:	83 3b 01             	cmpl   $0x1,(%ebx)
f01032ed:	75 58                	jne    f0103347 <env_create+0xef>
		
		if(ph->p_memsz < ph->p_filesz){
f01032ef:	8b 4b 14             	mov    0x14(%ebx),%ecx
f01032f2:	3b 4b 10             	cmp    0x10(%ebx),%ecx
f01032f5:	73 17                	jae    f010330e <env_create+0xb6>
		panic ("Memory size is smaller than file size!!");
f01032f7:	83 ec 04             	sub    $0x4,%esp
f01032fa:	68 70 73 10 f0       	push   $0xf0107370
f01032ff:	68 8e 01 00 00       	push   $0x18e
f0103304:	68 07 73 10 f0       	push   $0xf0107307
f0103309:	e8 32 cd ff ff       	call   f0100040 <_panic>
		}
		region_alloc(e, (void *)ph->p_va, ph->p_memsz);  //Allocate region per segment
f010330e:	8b 53 08             	mov    0x8(%ebx),%edx
f0103311:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103314:	e8 54 fc ff ff       	call   f0102f6d <region_alloc>
	

		memcpy((void*)ph->p_va, (void*)(binary + ph->p_offset), ph->p_filesz); //Load Binary into memory
f0103319:	83 ec 04             	sub    $0x4,%esp
f010331c:	ff 73 10             	pushl  0x10(%ebx)
f010331f:	89 f8                	mov    %edi,%eax
f0103321:	03 43 04             	add    0x4(%ebx),%eax
f0103324:	50                   	push   %eax
f0103325:	ff 73 08             	pushl  0x8(%ebx)
f0103328:	e8 ab 20 00 00       	call   f01053d8 <memcpy>

		memset((void*)(ph->p_va + ph->p_filesz),0,ph->p_memsz-ph->p_filesz);  //Clear the rest of the memory, i.e the bss segment
f010332d:	8b 43 10             	mov    0x10(%ebx),%eax
f0103330:	83 c4 0c             	add    $0xc,%esp
f0103333:	8b 53 14             	mov    0x14(%ebx),%edx
f0103336:	29 c2                	sub    %eax,%edx
f0103338:	52                   	push   %edx
f0103339:	6a 00                	push   $0x0
f010333b:	03 43 08             	add    0x8(%ebx),%eax
f010333e:	50                   	push   %eax
f010333f:	e8 df 1f 00 00       	call   f0105323 <memset>
f0103344:	83 c4 10             	add    $0x10,%esp
	struct Proghdr *phEnd =(struct Proghdr *)(ph + ((struct Elf*)binary)->e_phnum);
	
	// switch to env's pgdir by getting its physical address and loading into lcr3
	lcr3(PADDR(e->env_pgdir));

	for (;ph<phEnd;++ph){
f0103347:	83 c3 20             	add    $0x20,%ebx
f010334a:	39 de                	cmp    %ebx,%esi
f010334c:	77 9c                	ja     f01032ea <env_create+0x92>
		}
		else{
			continue;
		}
	}
	lcr3(PADDR(kern_pgdir));   //Switch back to Kernel page directory
f010334e:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103353:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103358:	77 15                	ja     f010336f <env_create+0x117>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010335a:	50                   	push   %eax
f010335b:	68 48 60 10 f0       	push   $0xf0106048
f0103360:	68 9b 01 00 00       	push   $0x19b
f0103365:	68 07 73 10 f0       	push   $0xf0107307
f010336a:	e8 d1 cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010336f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103374:	0f 22 d8             	mov    %eax,%cr3
	
	e->env_tf.tf_eip = ((struct Elf*)binary)->e_entry;   //Define the entry point of the env from the ELF binary entry point
f0103377:	8b 47 18             	mov    0x18(%edi),%eax
f010337a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f010337d:	89 47 30             	mov    %eax,0x30(%edi)

	region_alloc(e,(void *)USTACKTOP - PGSIZE, PGSIZE);
f0103380:	b9 00 10 00 00       	mov    $0x1000,%ecx
f0103385:	ba 00 d0 bf ee       	mov    $0xeebfd000,%edx
f010338a:	89 f8                	mov    %edi,%eax
f010338c:	e8 dc fb ff ff       	call   f0102f6d <region_alloc>
	if (r){
	panic("env_alloc: %e", r);
	}
	
	load_icode(env,binary);
	env->env_type = type;
f0103391:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103394:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103397:	89 50 50             	mov    %edx,0x50(%eax)

	// If this is the file server (type == ENV_TYPE_FS) give it I/O privileges.
	// LAB 5: Your code here.

}
f010339a:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010339d:	5b                   	pop    %ebx
f010339e:	5e                   	pop    %esi
f010339f:	5f                   	pop    %edi
f01033a0:	5d                   	pop    %ebp
f01033a1:	c3                   	ret    

f01033a2 <env_free>:
//
// Frees env e and all memory it uses.
//
void
env_free(struct Env *e)
{
f01033a2:	55                   	push   %ebp
f01033a3:	89 e5                	mov    %esp,%ebp
f01033a5:	57                   	push   %edi
f01033a6:	56                   	push   %esi
f01033a7:	53                   	push   %ebx
f01033a8:	83 ec 1c             	sub    $0x1c,%esp
f01033ab:	8b 7d 08             	mov    0x8(%ebp),%edi
	physaddr_t pa;

	// If freeing the current environment, switch to kern_pgdir
	// before freeing the page directory, just in case the page
	// gets reused.
	if (e == curenv)
f01033ae:	e8 94 25 00 00       	call   f0105947 <cpunum>
f01033b3:	6b c0 74             	imul   $0x74,%eax,%eax
f01033b6:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01033bd:	39 b8 48 e0 1d f0    	cmp    %edi,-0xfe21fb8(%eax)
f01033c3:	75 30                	jne    f01033f5 <env_free+0x53>
		lcr3(PADDR(kern_pgdir));
f01033c5:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01033ca:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01033cf:	77 15                	ja     f01033e6 <env_free+0x44>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01033d1:	50                   	push   %eax
f01033d2:	68 48 60 10 f0       	push   $0xf0106048
f01033d7:	68 cc 01 00 00       	push   $0x1cc
f01033dc:	68 07 73 10 f0       	push   $0xf0107307
f01033e1:	e8 5a cc ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01033e6:	05 00 00 00 10       	add    $0x10000000,%eax
f01033eb:	0f 22 d8             	mov    %eax,%cr3
f01033ee:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
f01033f5:	8b 55 e0             	mov    -0x20(%ebp),%edx
f01033f8:	89 d0                	mov    %edx,%eax
f01033fa:	c1 e0 02             	shl    $0x2,%eax
f01033fd:	89 45 d8             	mov    %eax,-0x28(%ebp)
	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {

		// only look at mapped page tables
		if (!(e->env_pgdir[pdeno] & PTE_P))
f0103400:	8b 47 60             	mov    0x60(%edi),%eax
f0103403:	8b 34 90             	mov    (%eax,%edx,4),%esi
f0103406:	f7 c6 01 00 00 00    	test   $0x1,%esi
f010340c:	0f 84 a8 00 00 00    	je     f01034ba <env_free+0x118>
			continue;

		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
f0103412:	81 e6 00 f0 ff ff    	and    $0xfffff000,%esi
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103418:	89 f0                	mov    %esi,%eax
f010341a:	c1 e8 0c             	shr    $0xc,%eax
f010341d:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103420:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f0103426:	72 15                	jb     f010343d <env_free+0x9b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103428:	56                   	push   %esi
f0103429:	68 24 60 10 f0       	push   $0xf0106024
f010342e:	68 db 01 00 00       	push   $0x1db
f0103433:	68 07 73 10 f0       	push   $0xf0107307
f0103438:	e8 03 cc ff ff       	call   f0100040 <_panic>
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f010343d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103440:	c1 e0 16             	shl    $0x16,%eax
f0103443:	89 45 e4             	mov    %eax,-0x1c(%ebp)
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f0103446:	bb 00 00 00 00       	mov    $0x0,%ebx
			if (pt[pteno] & PTE_P)
f010344b:	f6 84 9e 00 00 00 f0 	testb  $0x1,-0x10000000(%esi,%ebx,4)
f0103452:	01 
f0103453:	74 17                	je     f010346c <env_free+0xca>
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
f0103455:	83 ec 08             	sub    $0x8,%esp
f0103458:	89 d8                	mov    %ebx,%eax
f010345a:	c1 e0 0c             	shl    $0xc,%eax
f010345d:	0b 45 e4             	or     -0x1c(%ebp),%eax
f0103460:	50                   	push   %eax
f0103461:	ff 77 60             	pushl  0x60(%edi)
f0103464:	e8 3f de ff ff       	call   f01012a8 <page_remove>
f0103469:	83 c4 10             	add    $0x10,%esp
		// find the pa and va of the page table
		pa = PTE_ADDR(e->env_pgdir[pdeno]);
		pt = (pte_t*) KADDR(pa);

		// unmap all PTEs in this page table
		for (pteno = 0; pteno <= PTX(~0); pteno++) {
f010346c:	83 c3 01             	add    $0x1,%ebx
f010346f:	81 fb 00 04 00 00    	cmp    $0x400,%ebx
f0103475:	75 d4                	jne    f010344b <env_free+0xa9>
			if (pt[pteno] & PTE_P)
				page_remove(e->env_pgdir, PGADDR(pdeno, pteno, 0));
		}

		// free the page table itself
		e->env_pgdir[pdeno] = 0;
f0103477:	8b 47 60             	mov    0x60(%edi),%eax
f010347a:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010347d:	c7 04 10 00 00 00 00 	movl   $0x0,(%eax,%edx,1)
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103484:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103487:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f010348d:	72 14                	jb     f01034a3 <env_free+0x101>
		panic("pa2page called with invalid pa");
f010348f:	83 ec 04             	sub    $0x4,%esp
f0103492:	68 98 73 10 f0       	push   $0xf0107398
f0103497:	6a 51                	push   $0x51
f0103499:	68 c1 6f 10 f0       	push   $0xf0106fc1
f010349e:	e8 9d cb ff ff       	call   f0100040 <_panic>
		page_decref(pa2page(pa));
f01034a3:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f01034a6:	a1 d0 de 1d f0       	mov    0xf01dded0,%eax
f01034ab:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01034ae:	8d 04 d0             	lea    (%eax,%edx,8),%eax
f01034b1:	50                   	push   %eax
f01034b2:	e8 d8 db ff ff       	call   f010108f <page_decref>
f01034b7:	83 c4 10             	add    $0x10,%esp
	// Note the environment's demise.
	// cprintf("[%08x] free env %08x\n", curenv ? curenv->env_id : 0, e->env_id);

	// Flush all mapped pages in the user portion of the address space
	static_assert(UTOP % PTSIZE == 0);
	for (pdeno = 0; pdeno < PDX(UTOP); pdeno++) {
f01034ba:	83 45 e0 01          	addl   $0x1,-0x20(%ebp)
f01034be:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01034c1:	3d bb 03 00 00       	cmp    $0x3bb,%eax
f01034c6:	0f 85 29 ff ff ff    	jne    f01033f5 <env_free+0x53>
		e->env_pgdir[pdeno] = 0;
		page_decref(pa2page(pa));
	}

	// free the page directory
	pa = PADDR(e->env_pgdir);
f01034cc:	8b 47 60             	mov    0x60(%edi),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01034cf:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01034d4:	77 15                	ja     f01034eb <env_free+0x149>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01034d6:	50                   	push   %eax
f01034d7:	68 48 60 10 f0       	push   $0xf0106048
f01034dc:	68 e9 01 00 00       	push   $0x1e9
f01034e1:	68 07 73 10 f0       	push   $0xf0107307
f01034e6:	e8 55 cb ff ff       	call   f0100040 <_panic>
	e->env_pgdir = 0;
f01034eb:	c7 47 60 00 00 00 00 	movl   $0x0,0x60(%edi)
	return (physaddr_t)kva - KERNBASE;
f01034f2:	05 00 00 00 10       	add    $0x10000000,%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01034f7:	c1 e8 0c             	shr    $0xc,%eax
f01034fa:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f0103500:	72 14                	jb     f0103516 <env_free+0x174>
		panic("pa2page called with invalid pa");
f0103502:	83 ec 04             	sub    $0x4,%esp
f0103505:	68 98 73 10 f0       	push   $0xf0107398
f010350a:	6a 51                	push   $0x51
f010350c:	68 c1 6f 10 f0       	push   $0xf0106fc1
f0103511:	e8 2a cb ff ff       	call   f0100040 <_panic>
	page_decref(pa2page(pa));
f0103516:	83 ec 0c             	sub    $0xc,%esp
	return &pages[PGNUM(pa)];
f0103519:	8b 15 d0 de 1d f0    	mov    0xf01dded0,%edx
f010351f:	8d 04 c2             	lea    (%edx,%eax,8),%eax
f0103522:	50                   	push   %eax
f0103523:	e8 67 db ff ff       	call   f010108f <page_decref>

	// return the environment to the free list
	e->env_status = ENV_FREE;
f0103528:	c7 47 54 00 00 00 00 	movl   $0x0,0x54(%edi)
	e->env_link = env_free_list;
f010352f:	a1 70 d2 1d f0       	mov    0xf01dd270,%eax
f0103534:	89 47 44             	mov    %eax,0x44(%edi)
	env_free_list = e;
f0103537:	89 3d 70 d2 1d f0    	mov    %edi,0xf01dd270
f010353d:	83 c4 10             	add    $0x10,%esp
}
f0103540:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0103543:	5b                   	pop    %ebx
f0103544:	5e                   	pop    %esi
f0103545:	5f                   	pop    %edi
f0103546:	5d                   	pop    %ebp
f0103547:	c3                   	ret    

f0103548 <env_destroy>:
// If e was the current env, then runs a new environment (and does not return
// to the caller).
//
void
env_destroy(struct Env *e)
{
f0103548:	55                   	push   %ebp
f0103549:	89 e5                	mov    %esp,%ebp
f010354b:	53                   	push   %ebx
f010354c:	83 ec 04             	sub    $0x4,%esp
f010354f:	8b 5d 08             	mov    0x8(%ebp),%ebx
	// If e is currently running on other CPUs, we change its state to
	// ENV_DYING. A zombie environment will be freed the next time
	// it traps to the kernel.
	if (e->env_status == ENV_RUNNING && curenv != e) {
f0103552:	83 7b 54 03          	cmpl   $0x3,0x54(%ebx)
f0103556:	75 19                	jne    f0103571 <env_destroy+0x29>
f0103558:	e8 ea 23 00 00       	call   f0105947 <cpunum>
f010355d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103560:	39 98 48 e0 1d f0    	cmp    %ebx,-0xfe21fb8(%eax)
f0103566:	74 09                	je     f0103571 <env_destroy+0x29>
		e->env_status = ENV_DYING;
f0103568:	c7 43 54 01 00 00 00 	movl   $0x1,0x54(%ebx)
		return;
f010356f:	eb 33                	jmp    f01035a4 <env_destroy+0x5c>
	}

	env_free(e);
f0103571:	83 ec 0c             	sub    $0xc,%esp
f0103574:	53                   	push   %ebx
f0103575:	e8 28 fe ff ff       	call   f01033a2 <env_free>

	if (curenv == e) {
f010357a:	e8 c8 23 00 00       	call   f0105947 <cpunum>
f010357f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103582:	83 c4 10             	add    $0x10,%esp
f0103585:	39 98 48 e0 1d f0    	cmp    %ebx,-0xfe21fb8(%eax)
f010358b:	75 17                	jne    f01035a4 <env_destroy+0x5c>
		curenv = NULL;
f010358d:	e8 b5 23 00 00       	call   f0105947 <cpunum>
f0103592:	6b c0 74             	imul   $0x74,%eax,%eax
f0103595:	c7 80 48 e0 1d f0 00 	movl   $0x0,-0xfe21fb8(%eax)
f010359c:	00 00 00 
		sched_yield();
f010359f:	e8 fc 0b 00 00       	call   f01041a0 <sched_yield>
	}
}
f01035a4:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f01035a7:	c9                   	leave  
f01035a8:	c3                   	ret    

f01035a9 <env_pop_tf>:
//
// This function does not return.
//
void
env_pop_tf(struct Trapframe *tf)
{
f01035a9:	55                   	push   %ebp
f01035aa:	89 e5                	mov    %esp,%ebp
f01035ac:	53                   	push   %ebx
f01035ad:	83 ec 04             	sub    $0x4,%esp
	// Record the CPU we are running on for user-space debugging
	curenv->env_cpunum = cpunum();
f01035b0:	e8 92 23 00 00       	call   f0105947 <cpunum>
f01035b5:	6b c0 74             	imul   $0x74,%eax,%eax
f01035b8:	8b 98 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%ebx
f01035be:	e8 84 23 00 00       	call   f0105947 <cpunum>
f01035c3:	89 43 5c             	mov    %eax,0x5c(%ebx)

	__asm __volatile("movl %0,%%esp\n"
f01035c6:	8b 65 08             	mov    0x8(%ebp),%esp
f01035c9:	61                   	popa   
f01035ca:	07                   	pop    %es
f01035cb:	1f                   	pop    %ds
f01035cc:	83 c4 08             	add    $0x8,%esp
f01035cf:	cf                   	iret   
		"\tpopl %%es\n"
		"\tpopl %%ds\n"
		"\taddl $0x8,%%esp\n" /* skip tf_trapno and tf_errcode */
		"\tiret"
		: : "g" (tf) : "memory");
	panic("iret failed");  /* mostly to placate the compiler */
f01035d0:	83 ec 04             	sub    $0x4,%esp
f01035d3:	68 3d 73 10 f0       	push   $0xf010733d
f01035d8:	68 1f 02 00 00       	push   $0x21f
f01035dd:	68 07 73 10 f0       	push   $0xf0107307
f01035e2:	e8 59 ca ff ff       	call   f0100040 <_panic>

f01035e7 <env_run>:
//
// This function does not return.
//
void
env_run(struct Env *e)
{
f01035e7:	55                   	push   %ebp
f01035e8:	89 e5                	mov    %esp,%ebp
f01035ea:	53                   	push   %ebx
f01035eb:	83 ec 04             	sub    $0x4,%esp
f01035ee:	8b 5d 08             	mov    0x8(%ebp),%ebx
	//	e->env_tf to sensible values.

	// LAB 3: Your code here.

	//check if this is the first call to env_run
	if (curenv == NULL){
f01035f1:	e8 51 23 00 00       	call   f0105947 <cpunum>
f01035f6:	6b c0 74             	imul   $0x74,%eax,%eax
f01035f9:	83 b8 48 e0 1d f0 00 	cmpl   $0x0,-0xfe21fb8(%eax)
f0103600:	75 10                	jne    f0103612 <env_run+0x2b>
	curenv = e;
f0103602:	e8 40 23 00 00       	call   f0105947 <cpunum>
f0103607:	6b c0 74             	imul   $0x74,%eax,%eax
f010360a:	89 98 48 e0 1d f0    	mov    %ebx,-0xfe21fb8(%eax)
f0103610:	eb 29                	jmp    f010363b <env_run+0x54>
	}
	
	//If curenv state is running mode , set it to runnable 
	else if (curenv->env_status == ENV_RUNNING){
f0103612:	e8 30 23 00 00       	call   f0105947 <cpunum>
f0103617:	6b c0 74             	imul   $0x74,%eax,%eax
f010361a:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103620:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103624:	75 15                	jne    f010363b <env_run+0x54>
	 curenv->env_status = ENV_RUNNABLE;
f0103626:	e8 1c 23 00 00       	call   f0105947 <cpunum>
f010362b:	6b c0 74             	imul   $0x74,%eax,%eax
f010362e:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103634:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	}
	curenv = e;	//Set the current environment to the new env
f010363b:	e8 07 23 00 00       	call   f0105947 <cpunum>
f0103640:	6b c0 74             	imul   $0x74,%eax,%eax
f0103643:	89 98 48 e0 1d f0    	mov    %ebx,-0xfe21fb8(%eax)
	curenv->env_status = ENV_RUNNING; //Set it to running state
f0103649:	e8 f9 22 00 00       	call   f0105947 <cpunum>
f010364e:	6b c0 74             	imul   $0x74,%eax,%eax
f0103651:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103657:	c7 40 54 03 00 00 00 	movl   $0x3,0x54(%eax)
	curenv->env_runs++;	// Increment the env_runs counter
f010365e:	e8 e4 22 00 00       	call   f0105947 <cpunum>
f0103663:	6b c0 74             	imul   $0x74,%eax,%eax
f0103666:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f010366c:	83 40 58 01          	addl   $0x1,0x58(%eax)
	
	lcr3(PADDR(e->env_pgdir));	//Use lcr3 to switch to the env directory
f0103670:	8b 43 60             	mov    0x60(%ebx),%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0103673:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0103678:	77 15                	ja     f010368f <env_run+0xa8>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010367a:	50                   	push   %eax
f010367b:	68 48 60 10 f0       	push   $0xf0106048
f0103680:	68 4b 02 00 00       	push   $0x24b
f0103685:	68 07 73 10 f0       	push   $0xf0107307
f010368a:	e8 b1 c9 ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010368f:	05 00 00 00 10       	add    $0x10000000,%eax
f0103694:	0f 22 d8             	mov    %eax,%cr3
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f0103697:	83 ec 0c             	sub    $0xc,%esp
f010369a:	68 c0 04 12 f0       	push   $0xf01204c0
f010369f:	e8 ab 25 00 00       	call   f0105c4f <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f01036a4:	f3 90                	pause  
	unlock_kernel();
	env_pop_tf(&e->env_tf);
f01036a6:	89 1c 24             	mov    %ebx,(%esp)
f01036a9:	e8 fb fe ff ff       	call   f01035a9 <env_pop_tf>

f01036ae <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f01036ae:	55                   	push   %ebp
f01036af:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036b1:	ba 70 00 00 00       	mov    $0x70,%edx
f01036b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01036b9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01036ba:	b2 71                	mov    $0x71,%dl
f01036bc:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f01036bd:	0f b6 c0             	movzbl %al,%eax
}
f01036c0:	5d                   	pop    %ebp
f01036c1:	c3                   	ret    

f01036c2 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01036c2:	55                   	push   %ebp
f01036c3:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01036c5:	ba 70 00 00 00       	mov    $0x70,%edx
f01036ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01036cd:	ee                   	out    %al,(%dx)
f01036ce:	b2 71                	mov    $0x71,%dl
f01036d0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01036d3:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01036d4:	5d                   	pop    %ebp
f01036d5:	c3                   	ret    

f01036d6 <irq_setmask_8259A>:
		irq_setmask_8259A(irq_mask_8259A);
}

void
irq_setmask_8259A(uint16_t mask)
{
f01036d6:	55                   	push   %ebp
f01036d7:	89 e5                	mov    %esp,%ebp
f01036d9:	56                   	push   %esi
f01036da:	53                   	push   %ebx
f01036db:	8b 45 08             	mov    0x8(%ebp),%eax
	int i;
	irq_mask_8259A = mask;
f01036de:	66 a3 e8 03 12 f0    	mov    %ax,0xf01203e8
	if (!didinit)
f01036e4:	80 3d 74 d2 1d f0 00 	cmpb   $0x0,0xf01dd274
f01036eb:	74 57                	je     f0103744 <irq_setmask_8259A+0x6e>
f01036ed:	89 c6                	mov    %eax,%esi
f01036ef:	ba 21 00 00 00       	mov    $0x21,%edx
f01036f4:	ee                   	out    %al,(%dx)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
f01036f5:	66 c1 e8 08          	shr    $0x8,%ax
f01036f9:	b2 a1                	mov    $0xa1,%dl
f01036fb:	ee                   	out    %al,(%dx)
	cprintf("enabled interrupts:");
f01036fc:	83 ec 0c             	sub    $0xc,%esp
f01036ff:	68 b7 73 10 f0       	push   $0xf01073b7
f0103704:	e8 06 01 00 00       	call   f010380f <cprintf>
f0103709:	83 c4 10             	add    $0x10,%esp
	for (i = 0; i < 16; i++)
f010370c:	bb 00 00 00 00       	mov    $0x0,%ebx
		if (~mask & (1<<i))
f0103711:	0f b7 f6             	movzwl %si,%esi
f0103714:	f7 d6                	not    %esi
f0103716:	0f a3 de             	bt     %ebx,%esi
f0103719:	73 11                	jae    f010372c <irq_setmask_8259A+0x56>
			cprintf(" %d", i);
f010371b:	83 ec 08             	sub    $0x8,%esp
f010371e:	53                   	push   %ebx
f010371f:	68 8f 78 10 f0       	push   $0xf010788f
f0103724:	e8 e6 00 00 00       	call   f010380f <cprintf>
f0103729:	83 c4 10             	add    $0x10,%esp
	if (!didinit)
		return;
	outb(IO_PIC1+1, (char)mask);
	outb(IO_PIC2+1, (char)(mask >> 8));
	cprintf("enabled interrupts:");
	for (i = 0; i < 16; i++)
f010372c:	83 c3 01             	add    $0x1,%ebx
f010372f:	83 fb 10             	cmp    $0x10,%ebx
f0103732:	75 e2                	jne    f0103716 <irq_setmask_8259A+0x40>
		if (~mask & (1<<i))
			cprintf(" %d", i);
	cprintf("\n");
f0103734:	83 ec 0c             	sub    $0xc,%esp
f0103737:	68 1f 78 10 f0       	push   $0xf010781f
f010373c:	e8 ce 00 00 00       	call   f010380f <cprintf>
f0103741:	83 c4 10             	add    $0x10,%esp
}
f0103744:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103747:	5b                   	pop    %ebx
f0103748:	5e                   	pop    %esi
f0103749:	5d                   	pop    %ebp
f010374a:	c3                   	ret    

f010374b <pic_init>:

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
	didinit = 1;
f010374b:	c6 05 74 d2 1d f0 01 	movb   $0x1,0xf01dd274
f0103752:	ba 21 00 00 00       	mov    $0x21,%edx
f0103757:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010375c:	ee                   	out    %al,(%dx)
f010375d:	b2 a1                	mov    $0xa1,%dl
f010375f:	ee                   	out    %al,(%dx)
f0103760:	b2 20                	mov    $0x20,%dl
f0103762:	b8 11 00 00 00       	mov    $0x11,%eax
f0103767:	ee                   	out    %al,(%dx)
f0103768:	b2 21                	mov    $0x21,%dl
f010376a:	b8 20 00 00 00       	mov    $0x20,%eax
f010376f:	ee                   	out    %al,(%dx)
f0103770:	b8 04 00 00 00       	mov    $0x4,%eax
f0103775:	ee                   	out    %al,(%dx)
f0103776:	b8 03 00 00 00       	mov    $0x3,%eax
f010377b:	ee                   	out    %al,(%dx)
f010377c:	b2 a0                	mov    $0xa0,%dl
f010377e:	b8 11 00 00 00       	mov    $0x11,%eax
f0103783:	ee                   	out    %al,(%dx)
f0103784:	b2 a1                	mov    $0xa1,%dl
f0103786:	b8 28 00 00 00       	mov    $0x28,%eax
f010378b:	ee                   	out    %al,(%dx)
f010378c:	b8 02 00 00 00       	mov    $0x2,%eax
f0103791:	ee                   	out    %al,(%dx)
f0103792:	b8 01 00 00 00       	mov    $0x1,%eax
f0103797:	ee                   	out    %al,(%dx)
f0103798:	b2 20                	mov    $0x20,%dl
f010379a:	b8 68 00 00 00       	mov    $0x68,%eax
f010379f:	ee                   	out    %al,(%dx)
f01037a0:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037a5:	ee                   	out    %al,(%dx)
f01037a6:	b2 a0                	mov    $0xa0,%dl
f01037a8:	b8 68 00 00 00       	mov    $0x68,%eax
f01037ad:	ee                   	out    %al,(%dx)
f01037ae:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037b3:	ee                   	out    %al,(%dx)
	outb(IO_PIC1, 0x0a);             /* read IRR by default */

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
f01037b4:	0f b7 05 e8 03 12 f0 	movzwl 0xf01203e8,%eax
f01037bb:	66 83 f8 ff          	cmp    $0xffff,%ax
f01037bf:	74 13                	je     f01037d4 <pic_init+0x89>
static bool didinit;

/* Initialize the 8259A interrupt controllers. */
void
pic_init(void)
{
f01037c1:	55                   	push   %ebp
f01037c2:	89 e5                	mov    %esp,%ebp
f01037c4:	83 ec 14             	sub    $0x14,%esp

	outb(IO_PIC2, 0x68);               /* OCW3 */
	outb(IO_PIC2, 0x0a);               /* OCW3 */

	if (irq_mask_8259A != 0xFFFF)
		irq_setmask_8259A(irq_mask_8259A);
f01037c7:	0f b7 c0             	movzwl %ax,%eax
f01037ca:	50                   	push   %eax
f01037cb:	e8 06 ff ff ff       	call   f01036d6 <irq_setmask_8259A>
f01037d0:	83 c4 10             	add    $0x10,%esp
}
f01037d3:	c9                   	leave  
f01037d4:	f3 c3                	repz ret 

f01037d6 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01037d6:	55                   	push   %ebp
f01037d7:	89 e5                	mov    %esp,%ebp
f01037d9:	83 ec 14             	sub    $0x14,%esp
	cputchar(ch);
f01037dc:	ff 75 08             	pushl  0x8(%ebp)
f01037df:	e8 87 cf ff ff       	call   f010076b <cputchar>
f01037e4:	83 c4 10             	add    $0x10,%esp
	*cnt++;
}
f01037e7:	c9                   	leave  
f01037e8:	c3                   	ret    

f01037e9 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01037e9:	55                   	push   %ebp
f01037ea:	89 e5                	mov    %esp,%ebp
f01037ec:	83 ec 18             	sub    $0x18,%esp
	int cnt = 0;
f01037ef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01037f6:	ff 75 0c             	pushl  0xc(%ebp)
f01037f9:	ff 75 08             	pushl  0x8(%ebp)
f01037fc:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01037ff:	50                   	push   %eax
f0103800:	68 d6 37 10 f0       	push   $0xf01037d6
f0103805:	e8 8e 14 00 00       	call   f0104c98 <vprintfmt>
	return cnt;
}
f010380a:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010380d:	c9                   	leave  
f010380e:	c3                   	ret    

f010380f <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010380f:	55                   	push   %ebp
f0103810:	89 e5                	mov    %esp,%ebp
f0103812:	83 ec 10             	sub    $0x10,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103815:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103818:	50                   	push   %eax
f0103819:	ff 75 08             	pushl  0x8(%ebp)
f010381c:	e8 c8 ff ff ff       	call   f01037e9 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103821:	c9                   	leave  
f0103822:	c3                   	ret    

f0103823 <trap_init_percpu>:
}

// Initialize and load the per-CPU TSS and IDT
void
trap_init_percpu(void)
{
f0103823:	55                   	push   %ebp
f0103824:	89 e5                	mov    %esp,%ebp
f0103826:	56                   	push   %esi
f0103827:	53                   	push   %ebx
	// user space on that CPU.
	//
	// LAB 4: Your code here:

	
	int i = cpunum();
f0103828:	e8 1a 21 00 00       	call   f0105947 <cpunum>
f010382d:	89 c3                	mov    %eax,%ebx
	

	// Setup a TSS so that we get the right stack
	// when we trap to the kernel.
	thiscpu->cpu_ts.ts_esp0 = (uintptr_t)(percpu_kstacks[cpunum()] + KSTKSIZE);
f010382f:	e8 13 21 00 00       	call   f0105947 <cpunum>
f0103834:	89 c6                	mov    %eax,%esi
f0103836:	e8 0c 21 00 00       	call   f0105947 <cpunum>
f010383b:	6b f6 74             	imul   $0x74,%esi,%esi
f010383e:	c1 e0 0f             	shl    $0xf,%eax
f0103841:	8d 80 00 70 1e f0    	lea    -0xfe19000(%eax),%eax
f0103847:	89 86 50 e0 1d f0    	mov    %eax,-0xfe21fb0(%esi)
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
f010384d:	e8 f5 20 00 00       	call   f0105947 <cpunum>
f0103852:	6b c0 74             	imul   $0x74,%eax,%eax
f0103855:	66 c7 80 54 e0 1d f0 	movw   $0x10,-0xfe21fac(%eax)
f010385c:	10 00 

	// Initialize the TSS slot of the gdt.
	gdt[(GD_TSS0 >> 3)+i] = SEG16(STS_T32A, (uint32_t) (&cpus[i].cpu_ts),  //It was (&ts) instead of &cpus[i].cpu_ts
f010385e:	8d 43 05             	lea    0x5(%ebx),%eax
f0103861:	6b d3 74             	imul   $0x74,%ebx,%edx
f0103864:	81 c2 4c e0 1d f0    	add    $0xf01de04c,%edx
f010386a:	66 c7 04 c5 80 03 12 	movw   $0x67,-0xfedfc80(,%eax,8)
f0103871:	f0 67 00 
f0103874:	66 89 14 c5 82 03 12 	mov    %dx,-0xfedfc7e(,%eax,8)
f010387b:	f0 
f010387c:	89 d1                	mov    %edx,%ecx
f010387e:	c1 e9 10             	shr    $0x10,%ecx
f0103881:	88 0c c5 84 03 12 f0 	mov    %cl,-0xfedfc7c(,%eax,8)
f0103888:	c6 04 c5 86 03 12 f0 	movb   $0x40,-0xfedfc7a(,%eax,8)
f010388f:	40 
f0103890:	c1 ea 18             	shr    $0x18,%edx
f0103893:	88 14 c5 87 03 12 f0 	mov    %dl,-0xfedfc79(,%eax,8)
					sizeof(struct Taskstate)-1, 0);
	gdt[(GD_TSS0 >> 3)+i].sd_s = 0;
f010389a:	c6 04 c5 85 03 12 f0 	movb   $0x89,-0xfedfc7b(,%eax,8)
f01038a1:	89 

	// Load the TSS selector (like other segment selectors, the
	// bottom three bits are special; we leave them 0)
	ltr(((GD_TSS0>>3) + i) << 3);	
f01038a2:	8d 1c dd 28 00 00 00 	lea    0x28(,%ebx,8),%ebx
}

static __inline void
ltr(uint16_t sel)
{
	__asm __volatile("ltr %0" : : "r" (sel));
f01038a9:	0f 00 db             	ltr    %bx
}

static __inline void
lidt(void *p)
{
	__asm __volatile("lidt (%0)" : : "r" (p));
f01038ac:	b8 ea 03 12 f0       	mov    $0xf01203ea,%eax
f01038b1:	0f 01 18             	lidtl  (%eax)
	lidt(&idt_pd); 
	
	


}
f01038b4:	5b                   	pop    %ebx
f01038b5:	5e                   	pop    %esi
f01038b6:	5d                   	pop    %ebp
f01038b7:	c3                   	ret    

f01038b8 <trap_init>:
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f01038b8:	b8 00 00 00 00       	mov    $0x0,%eax
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
f01038bd:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f01038c4:	66 89 14 c5 80 d2 1d 	mov    %dx,-0xfe22d80(,%eax,8)
f01038cb:	f0 
f01038cc:	66 c7 04 c5 82 d2 1d 	movw   $0x8,-0xfe22d7e(,%eax,8)
f01038d3:	f0 08 00 
f01038d6:	c6 04 c5 84 d2 1d f0 	movb   $0x0,-0xfe22d7c(,%eax,8)
f01038dd:	00 
f01038de:	c6 04 c5 85 d2 1d f0 	movb   $0x8e,-0xfe22d7b(,%eax,8)
f01038e5:	8e 
f01038e6:	c1 ea 10             	shr    $0x10,%edx
f01038e9:	66 89 14 c5 86 d2 1d 	mov    %dx,-0xfe22d7a(,%eax,8)
f01038f0:	f0 
	extern struct Segdesc gdt[];
	
	// LAB 3: Your code here.
	extern long int_vector_table[];
	int i,j; 
	for (i=0; i<= T_SIMDERR;i++){
f01038f1:	83 c0 01             	add    $0x1,%eax
f01038f4:	83 f8 14             	cmp    $0x14,%eax
f01038f7:	75 c4                	jne    f01038bd <trap_init+0x5>
		SETGATE(idt[i],0,GD_KT,int_vector_table[i],0);
	}

	//Interrupt 3 is a soft interrupt generated by user, hence the dpl of the gate will be checked with 3
  	SETGATE(idt[3],0,GD_KT,int_vector_table[3],3);
f01038f9:	a1 fc 03 12 f0       	mov    0xf01203fc,%eax
f01038fe:	66 a3 98 d2 1d f0    	mov    %ax,0xf01dd298
f0103904:	66 c7 05 9a d2 1d f0 	movw   $0x8,0xf01dd29a
f010390b:	08 00 
f010390d:	c6 05 9c d2 1d f0 00 	movb   $0x0,0xf01dd29c
f0103914:	c6 05 9d d2 1d f0 ee 	movb   $0xee,0xf01dd29d
f010391b:	c1 e8 10             	shr    $0x10,%eax
f010391e:	66 a3 9e d2 1d f0    	mov    %ax,0xf01dd29e

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3
f0103924:	a1 b0 04 12 f0       	mov    0xf01204b0,%eax
f0103929:	66 a3 00 d4 1d f0    	mov    %ax,0xf01dd400
f010392f:	66 c7 05 02 d4 1d f0 	movw   $0x8,0xf01dd402
f0103936:	08 00 
f0103938:	c6 05 04 d4 1d f0 00 	movb   $0x0,0xf01dd404
f010393f:	c6 05 05 d4 1d f0 ee 	movb   $0xee,0xf01dd405
f0103946:	c1 e8 10             	shr    $0x10,%eax
f0103949:	66 a3 06 d4 1d f0    	mov    %ax,0xf01dd406
f010394f:	b8 20 00 00 00       	mov    $0x20,%eax

	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);
f0103954:	8b 14 85 f0 03 12 f0 	mov    -0xfedfc10(,%eax,4),%edx
f010395b:	66 89 14 c5 80 d2 1d 	mov    %dx,-0xfe22d80(,%eax,8)
f0103962:	f0 
f0103963:	66 c7 04 c5 82 d2 1d 	movw   $0x8,-0xfe22d7e(,%eax,8)
f010396a:	f0 08 00 
f010396d:	c6 04 c5 84 d2 1d f0 	movb   $0x0,-0xfe22d7c(,%eax,8)
f0103974:	00 
f0103975:	c6 04 c5 85 d2 1d f0 	movb   $0xee,-0xfe22d7b(,%eax,8)
f010397c:	ee 
f010397d:	c1 ea 10             	shr    $0x10,%edx
f0103980:	66 89 14 c5 86 d2 1d 	mov    %dx,-0xfe22d7a(,%eax,8)
f0103987:	f0 
f0103988:	83 c0 01             	add    $0x1,%eax

	//similarly system call is setup by the user and hence the gate should be checked with 3 
	SETGATE(idt[T_SYSCALL], 0, GD_KT, int_vector_table[T_SYSCALL], 3);// T_SYSCALL = 3

	//For IRQ interrupts
	for(j=0;j<16;j++)
f010398b:	83 f8 30             	cmp    $0x30,%eax
f010398e:	75 c4                	jne    f0103954 <trap_init+0x9c>
}


void
trap_init(void)
{
f0103990:	55                   	push   %ebp
f0103991:	89 e5                	mov    %esp,%ebp
f0103993:	83 ec 08             	sub    $0x8,%esp
	//For IRQ interrupts
	for(j=0;j<16;j++)
	    SETGATE(idt[IRQ_OFFSET + j], 0, GD_KT, int_vector_table[IRQ_OFFSET + j], 3);

	// Per-CPU setup 
	trap_init_percpu();
f0103996:	e8 88 fe ff ff       	call   f0103823 <trap_init_percpu>
}
f010399b:	c9                   	leave  
f010399c:	c3                   	ret    

f010399d <print_regs>:
	}
}

void
print_regs(struct PushRegs *regs)
{
f010399d:	55                   	push   %ebp
f010399e:	89 e5                	mov    %esp,%ebp
f01039a0:	53                   	push   %ebx
f01039a1:	83 ec 0c             	sub    $0xc,%esp
f01039a4:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("  edi  0x%08x\n", regs->reg_edi);
f01039a7:	ff 33                	pushl  (%ebx)
f01039a9:	68 cb 73 10 f0       	push   $0xf01073cb
f01039ae:	e8 5c fe ff ff       	call   f010380f <cprintf>
	cprintf("  esi  0x%08x\n", regs->reg_esi);
f01039b3:	83 c4 08             	add    $0x8,%esp
f01039b6:	ff 73 04             	pushl  0x4(%ebx)
f01039b9:	68 da 73 10 f0       	push   $0xf01073da
f01039be:	e8 4c fe ff ff       	call   f010380f <cprintf>
	cprintf("  ebp  0x%08x\n", regs->reg_ebp);
f01039c3:	83 c4 08             	add    $0x8,%esp
f01039c6:	ff 73 08             	pushl  0x8(%ebx)
f01039c9:	68 e9 73 10 f0       	push   $0xf01073e9
f01039ce:	e8 3c fe ff ff       	call   f010380f <cprintf>
	cprintf("  oesp 0x%08x\n", regs->reg_oesp);
f01039d3:	83 c4 08             	add    $0x8,%esp
f01039d6:	ff 73 0c             	pushl  0xc(%ebx)
f01039d9:	68 f8 73 10 f0       	push   $0xf01073f8
f01039de:	e8 2c fe ff ff       	call   f010380f <cprintf>
	cprintf("  ebx  0x%08x\n", regs->reg_ebx);
f01039e3:	83 c4 08             	add    $0x8,%esp
f01039e6:	ff 73 10             	pushl  0x10(%ebx)
f01039e9:	68 07 74 10 f0       	push   $0xf0107407
f01039ee:	e8 1c fe ff ff       	call   f010380f <cprintf>
	cprintf("  edx  0x%08x\n", regs->reg_edx);
f01039f3:	83 c4 08             	add    $0x8,%esp
f01039f6:	ff 73 14             	pushl  0x14(%ebx)
f01039f9:	68 16 74 10 f0       	push   $0xf0107416
f01039fe:	e8 0c fe ff ff       	call   f010380f <cprintf>
	cprintf("  ecx  0x%08x\n", regs->reg_ecx);
f0103a03:	83 c4 08             	add    $0x8,%esp
f0103a06:	ff 73 18             	pushl  0x18(%ebx)
f0103a09:	68 25 74 10 f0       	push   $0xf0107425
f0103a0e:	e8 fc fd ff ff       	call   f010380f <cprintf>
	cprintf("  eax  0x%08x\n", regs->reg_eax);
f0103a13:	83 c4 08             	add    $0x8,%esp
f0103a16:	ff 73 1c             	pushl  0x1c(%ebx)
f0103a19:	68 34 74 10 f0       	push   $0xf0107434
f0103a1e:	e8 ec fd ff ff       	call   f010380f <cprintf>
f0103a23:	83 c4 10             	add    $0x10,%esp
}
f0103a26:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f0103a29:	c9                   	leave  
f0103a2a:	c3                   	ret    

f0103a2b <print_trapframe>:

}

void
print_trapframe(struct Trapframe *tf)
{
f0103a2b:	55                   	push   %ebp
f0103a2c:	89 e5                	mov    %esp,%ebp
f0103a2e:	56                   	push   %esi
f0103a2f:	53                   	push   %ebx
f0103a30:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
f0103a33:	e8 0f 1f 00 00       	call   f0105947 <cpunum>
f0103a38:	83 ec 04             	sub    $0x4,%esp
f0103a3b:	50                   	push   %eax
f0103a3c:	53                   	push   %ebx
f0103a3d:	68 98 74 10 f0       	push   $0xf0107498
f0103a42:	e8 c8 fd ff ff       	call   f010380f <cprintf>
	print_regs(&tf->tf_regs);
f0103a47:	89 1c 24             	mov    %ebx,(%esp)
f0103a4a:	e8 4e ff ff ff       	call   f010399d <print_regs>
	cprintf("  es   0x----%04x\n", tf->tf_es);
f0103a4f:	83 c4 08             	add    $0x8,%esp
f0103a52:	0f b7 43 20          	movzwl 0x20(%ebx),%eax
f0103a56:	50                   	push   %eax
f0103a57:	68 b6 74 10 f0       	push   $0xf01074b6
f0103a5c:	e8 ae fd ff ff       	call   f010380f <cprintf>
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
f0103a61:	83 c4 08             	add    $0x8,%esp
f0103a64:	0f b7 43 24          	movzwl 0x24(%ebx),%eax
f0103a68:	50                   	push   %eax
f0103a69:	68 c9 74 10 f0       	push   $0xf01074c9
f0103a6e:	e8 9c fd ff ff       	call   f010380f <cprintf>
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103a73:	8b 43 28             	mov    0x28(%ebx),%eax
		"Alignment Check",
		"Machine-Check",
		"SIMD Floating-Point Exception"
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
f0103a76:	83 c4 10             	add    $0x10,%esp
f0103a79:	83 f8 13             	cmp    $0x13,%eax
f0103a7c:	77 09                	ja     f0103a87 <print_trapframe+0x5c>
		return excnames[trapno];
f0103a7e:	8b 14 85 80 77 10 f0 	mov    -0xfef8880(,%eax,4),%edx
f0103a85:	eb 1f                	jmp    f0103aa6 <print_trapframe+0x7b>
	if (trapno == T_SYSCALL)
f0103a87:	83 f8 30             	cmp    $0x30,%eax
f0103a8a:	74 15                	je     f0103aa1 <print_trapframe+0x76>
		return "System call";
	if (trapno >= IRQ_OFFSET && trapno < IRQ_OFFSET + 16)
f0103a8c:	8d 50 e0             	lea    -0x20(%eax),%edx
		return "Hardware Interrupt";
	return "(unknown trap)";
f0103a8f:	83 fa 10             	cmp    $0x10,%edx
f0103a92:	b9 62 74 10 f0       	mov    $0xf0107462,%ecx
f0103a97:	ba 4f 74 10 f0       	mov    $0xf010744f,%edx
f0103a9c:	0f 43 d1             	cmovae %ecx,%edx
f0103a9f:	eb 05                	jmp    f0103aa6 <print_trapframe+0x7b>
	};

	if (trapno < sizeof(excnames)/sizeof(excnames[0]))
		return excnames[trapno];
	if (trapno == T_SYSCALL)
		return "System call";
f0103aa1:	ba 43 74 10 f0       	mov    $0xf0107443,%edx
{
	cprintf("TRAP frame at %p from CPU %d\n", tf, cpunum());
	print_regs(&tf->tf_regs);
	cprintf("  es   0x----%04x\n", tf->tf_es);
	cprintf("  ds   0x----%04x\n", tf->tf_ds);
	cprintf("  trap 0x%08x %s\n", tf->tf_trapno, trapname(tf->tf_trapno));
f0103aa6:	83 ec 04             	sub    $0x4,%esp
f0103aa9:	52                   	push   %edx
f0103aaa:	50                   	push   %eax
f0103aab:	68 dc 74 10 f0       	push   $0xf01074dc
f0103ab0:	e8 5a fd ff ff       	call   f010380f <cprintf>
	// If this trap was a page fault that just happened
	// (so %cr2 is meaningful), print the faulting linear address.
	if (tf == last_tf && tf->tf_trapno == T_PGFLT)
f0103ab5:	83 c4 10             	add    $0x10,%esp
f0103ab8:	3b 1d 80 da 1d f0    	cmp    0xf01dda80,%ebx
f0103abe:	75 1a                	jne    f0103ada <print_trapframe+0xaf>
f0103ac0:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103ac4:	75 14                	jne    f0103ada <print_trapframe+0xaf>

static __inline uint32_t
rcr2(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr2,%0" : "=r" (val));
f0103ac6:	0f 20 d0             	mov    %cr2,%eax
		cprintf("  cr2  0x%08x\n", rcr2());
f0103ac9:	83 ec 08             	sub    $0x8,%esp
f0103acc:	50                   	push   %eax
f0103acd:	68 ee 74 10 f0       	push   $0xf01074ee
f0103ad2:	e8 38 fd ff ff       	call   f010380f <cprintf>
f0103ad7:	83 c4 10             	add    $0x10,%esp
	cprintf("  err  0x%08x", tf->tf_err);
f0103ada:	83 ec 08             	sub    $0x8,%esp
f0103add:	ff 73 2c             	pushl  0x2c(%ebx)
f0103ae0:	68 fd 74 10 f0       	push   $0xf01074fd
f0103ae5:	e8 25 fd ff ff       	call   f010380f <cprintf>
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
f0103aea:	83 c4 10             	add    $0x10,%esp
f0103aed:	83 7b 28 0e          	cmpl   $0xe,0x28(%ebx)
f0103af1:	75 49                	jne    f0103b3c <print_trapframe+0x111>
		cprintf(" [%s, %s, %s]\n",
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
f0103af3:	8b 43 2c             	mov    0x2c(%ebx),%eax
	// For page faults, print decoded fault error code:
	// U/K=fault occurred in user/kernel mode
	// W/R=a write/read caused the fault
	// PR=a protection violation caused the fault (NP=page not present).
	if (tf->tf_trapno == T_PGFLT)
		cprintf(" [%s, %s, %s]\n",
f0103af6:	89 c2                	mov    %eax,%edx
f0103af8:	83 e2 01             	and    $0x1,%edx
f0103afb:	ba 7c 74 10 f0       	mov    $0xf010747c,%edx
f0103b00:	b9 71 74 10 f0       	mov    $0xf0107471,%ecx
f0103b05:	0f 44 ca             	cmove  %edx,%ecx
f0103b08:	89 c2                	mov    %eax,%edx
f0103b0a:	83 e2 02             	and    $0x2,%edx
f0103b0d:	ba 8e 74 10 f0       	mov    $0xf010748e,%edx
f0103b12:	be 88 74 10 f0       	mov    $0xf0107488,%esi
f0103b17:	0f 45 d6             	cmovne %esi,%edx
f0103b1a:	83 e0 04             	and    $0x4,%eax
f0103b1d:	be e4 75 10 f0       	mov    $0xf01075e4,%esi
f0103b22:	b8 93 74 10 f0       	mov    $0xf0107493,%eax
f0103b27:	0f 44 c6             	cmove  %esi,%eax
f0103b2a:	51                   	push   %ecx
f0103b2b:	52                   	push   %edx
f0103b2c:	50                   	push   %eax
f0103b2d:	68 0b 75 10 f0       	push   $0xf010750b
f0103b32:	e8 d8 fc ff ff       	call   f010380f <cprintf>
f0103b37:	83 c4 10             	add    $0x10,%esp
f0103b3a:	eb 10                	jmp    f0103b4c <print_trapframe+0x121>
			tf->tf_err & 4 ? "user" : "kernel",
			tf->tf_err & 2 ? "write" : "read",
			tf->tf_err & 1 ? "protection" : "not-present");
	else
		cprintf("\n");
f0103b3c:	83 ec 0c             	sub    $0xc,%esp
f0103b3f:	68 1f 78 10 f0       	push   $0xf010781f
f0103b44:	e8 c6 fc ff ff       	call   f010380f <cprintf>
f0103b49:	83 c4 10             	add    $0x10,%esp
	cprintf("  eip  0x%08x\n", tf->tf_eip);
f0103b4c:	83 ec 08             	sub    $0x8,%esp
f0103b4f:	ff 73 30             	pushl  0x30(%ebx)
f0103b52:	68 1a 75 10 f0       	push   $0xf010751a
f0103b57:	e8 b3 fc ff ff       	call   f010380f <cprintf>
	cprintf("  cs   0x----%04x\n", tf->tf_cs);
f0103b5c:	83 c4 08             	add    $0x8,%esp
f0103b5f:	0f b7 43 34          	movzwl 0x34(%ebx),%eax
f0103b63:	50                   	push   %eax
f0103b64:	68 29 75 10 f0       	push   $0xf0107529
f0103b69:	e8 a1 fc ff ff       	call   f010380f <cprintf>
	cprintf("  flag 0x%08x\n", tf->tf_eflags);
f0103b6e:	83 c4 08             	add    $0x8,%esp
f0103b71:	ff 73 38             	pushl  0x38(%ebx)
f0103b74:	68 3c 75 10 f0       	push   $0xf010753c
f0103b79:	e8 91 fc ff ff       	call   f010380f <cprintf>
	if ((tf->tf_cs & 3) != 0) {
f0103b7e:	83 c4 10             	add    $0x10,%esp
f0103b81:	f6 43 34 03          	testb  $0x3,0x34(%ebx)
f0103b85:	74 25                	je     f0103bac <print_trapframe+0x181>
		cprintf("  esp  0x%08x\n", tf->tf_esp);
f0103b87:	83 ec 08             	sub    $0x8,%esp
f0103b8a:	ff 73 3c             	pushl  0x3c(%ebx)
f0103b8d:	68 4b 75 10 f0       	push   $0xf010754b
f0103b92:	e8 78 fc ff ff       	call   f010380f <cprintf>
		cprintf("  ss   0x----%04x\n", tf->tf_ss);
f0103b97:	83 c4 08             	add    $0x8,%esp
f0103b9a:	0f b7 43 40          	movzwl 0x40(%ebx),%eax
f0103b9e:	50                   	push   %eax
f0103b9f:	68 5a 75 10 f0       	push   $0xf010755a
f0103ba4:	e8 66 fc ff ff       	call   f010380f <cprintf>
f0103ba9:	83 c4 10             	add    $0x10,%esp
	}
}
f0103bac:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0103baf:	5b                   	pop    %ebx
f0103bb0:	5e                   	pop    %esi
f0103bb1:	5d                   	pop    %ebp
f0103bb2:	c3                   	ret    

f0103bb3 <page_fault_handler>:
}


void
page_fault_handler(struct Trapframe *tf)
{
f0103bb3:	55                   	push   %ebp
f0103bb4:	89 e5                	mov    %esp,%ebp
f0103bb6:	57                   	push   %edi
f0103bb7:	56                   	push   %esi
f0103bb8:	53                   	push   %ebx
f0103bb9:	83 ec 1c             	sub    $0x1c,%esp
f0103bbc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103bbf:	0f 20 d6             	mov    %cr2,%esi
	// LAB 3: Your code here.


	//If the processor is already in kernel mode when the interrupt or exception occurs 
	//(the low 2 bits of the CS register are already zero), Hence we have to check the CS register to make sure its in kernel mode
	if ((tf->tf_cs & 0x11) == 0){
f0103bc2:	f6 43 34 11          	testb  $0x11,0x34(%ebx)
f0103bc6:	75 15                	jne    f0103bdd <page_fault_handler+0x2a>
		panic("Fault occured in kernel space on %08x \n",fault_va);
f0103bc8:	56                   	push   %esi
f0103bc9:	68 30 77 10 f0       	push   $0xf0107730
f0103bce:	68 50 01 00 00       	push   $0x150
f0103bd3:	68 6d 75 10 f0       	push   $0xf010756d
f0103bd8:	e8 63 c4 ff ff       	call   f0100040 <_panic>
	//   (the 'tf' variable points at 'curenv->env_tf').

	// LAB 4: Your code here.

	//Store the current env's stack tf_esp for use, if the call occurs inside UXtrapframe  
	const uint32_t cur_tf_esp_addr = (uint32_t)(tf->tf_esp); 	// trap-time esp
f0103bdd:	8b 7b 3c             	mov    0x3c(%ebx),%edi

	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
f0103be0:	e8 62 1d 00 00       	call   f0105947 <cpunum>
f0103be5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103be8:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103bee:	83 78 64 00          	cmpl   $0x0,0x64(%eax)
f0103bf2:	75 46                	jne    f0103c3a <page_fault_handler+0x87>
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103bf4:	8b 43 30             	mov    0x30(%ebx),%eax
f0103bf7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
			curenv->env_id, fault_va, tf->tf_eip);
f0103bfa:	e8 48 1d 00 00       	call   f0105947 <cpunum>
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103bff:	ff 75 e4             	pushl  -0x1c(%ebp)
f0103c02:	56                   	push   %esi
			curenv->env_id, fault_va, tf->tf_eip);
f0103c03:	6b c0 74             	imul   $0x74,%eax,%eax
	

	// If there is no env_pgfault_upcall or no page fault handler for the curenv follow the original procedure
	if (!curenv->env_pgfault_upcall)
	{
		cprintf("[%08x] user fault va %08x ip %08x\n",
f0103c06:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103c0c:	ff 70 48             	pushl  0x48(%eax)
f0103c0f:	68 58 77 10 f0       	push   $0xf0107758
f0103c14:	e8 f6 fb ff ff       	call   f010380f <cprintf>
			curenv->env_id, fault_va, tf->tf_eip);
		print_trapframe(tf);
f0103c19:	89 1c 24             	mov    %ebx,(%esp)
f0103c1c:	e8 0a fe ff ff       	call   f0103a2b <print_trapframe>
		env_destroy(curenv);	// Destroy the environment that caused the fault.
f0103c21:	e8 21 1d 00 00       	call   f0105947 <cpunum>
f0103c26:	83 c4 04             	add    $0x4,%esp
f0103c29:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c2c:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0103c32:	e8 11 f9 ff ff       	call   f0103548 <env_destroy>
f0103c37:	83 c4 10             	add    $0x10,%esp
	}
	
	//Check if the	
	struct UTrapframe* usertf = NULL; //As defined in inc/trap.h
	
	if((cur_tf_esp_addr < UXSTACKTOP) && (cur_tf_esp_addr >=(UXSTACKTOP - PGSIZE)))
f0103c3a:	8d 97 00 10 40 11    	lea    0x11401000(%edi),%edx
	{
		//If its already inside the exception stack
		//Allocate the address by leaving space for 32-bit word
		usertf = (struct UTrapframe*)(cur_tf_esp_addr - 4 - sizeof(struct UTrapframe));
f0103c40:	8d 47 c8             	lea    -0x38(%edi),%eax
f0103c43:	81 fa ff 0f 00 00    	cmp    $0xfff,%edx
f0103c49:	ba cc ff bf ee       	mov    $0xeebfffcc,%edx
f0103c4e:	0f 46 d0             	cmovbe %eax,%edx
f0103c51:	89 d7                	mov    %edx,%edi
		usertf = (struct UTrapframe*)(UXSTACKTOP - sizeof(struct UTrapframe));
	}
	
	//Check whether the usertf memory is valid
	//This function will not return if there is a fault and it will also destroy the environment
	user_mem_assert(curenv, (void*)usertf, sizeof(struct UTrapframe), PTE_U | PTE_P | PTE_W);
f0103c53:	e8 ef 1c 00 00       	call   f0105947 <cpunum>
f0103c58:	6a 07                	push   $0x7
f0103c5a:	6a 34                	push   $0x34
f0103c5c:	57                   	push   %edi
f0103c5d:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c60:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0103c66:	e8 b8 f2 ff ff       	call   f0102f23 <user_mem_assert>
	
	
	// User exeception trapframe
	usertf->utf_fault_va = fault_va;
f0103c6b:	89 fa                	mov    %edi,%edx
f0103c6d:	89 37                	mov    %esi,(%edi)
	usertf->utf_err = tf->tf_err;
f0103c6f:	8b 43 2c             	mov    0x2c(%ebx),%eax
f0103c72:	89 47 04             	mov    %eax,0x4(%edi)
	usertf->utf_regs = tf->tf_regs;
f0103c75:	8d 7f 08             	lea    0x8(%edi),%edi
f0103c78:	b9 08 00 00 00       	mov    $0x8,%ecx
f0103c7d:	89 de                	mov    %ebx,%esi
f0103c7f:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
	usertf->utf_eip = tf->tf_eip;
f0103c81:	8b 43 30             	mov    0x30(%ebx),%eax
f0103c84:	89 42 28             	mov    %eax,0x28(%edx)
	usertf->utf_esp = tf->tf_esp;
f0103c87:	8b 43 3c             	mov    0x3c(%ebx),%eax
f0103c8a:	89 42 30             	mov    %eax,0x30(%edx)
	usertf->utf_eflags = tf->tf_eflags;
f0103c8d:	8b 43 38             	mov    0x38(%ebx),%eax
f0103c90:	89 42 2c             	mov    %eax,0x2c(%edx)
	
	//Setup the tf with Exception stack frame
	
	tf->tf_esp= (uintptr_t)usertf;
f0103c93:	89 53 3c             	mov    %edx,0x3c(%ebx)
	tf->tf_eip = (uintptr_t)curenv->env_pgfault_upcall; 
f0103c96:	e8 ac 1c 00 00       	call   f0105947 <cpunum>
f0103c9b:	6b c0 74             	imul   $0x74,%eax,%eax
f0103c9e:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103ca4:	8b 40 64             	mov    0x64(%eax),%eax
f0103ca7:	89 43 30             	mov    %eax,0x30(%ebx)

	env_run(curenv);
f0103caa:	e8 98 1c 00 00       	call   f0105947 <cpunum>
f0103caf:	83 c4 04             	add    $0x4,%esp
f0103cb2:	6b c0 74             	imul   $0x74,%eax,%eax
f0103cb5:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0103cbb:	e8 27 f9 ff ff       	call   f01035e7 <env_run>

f0103cc0 <trap>:
	}
}

void
trap(struct Trapframe *tf)
{
f0103cc0:	55                   	push   %ebp
f0103cc1:	89 e5                	mov    %esp,%ebp
f0103cc3:	57                   	push   %edi
f0103cc4:	56                   	push   %esi
f0103cc5:	8b 75 08             	mov    0x8(%ebp),%esi
	// The environment may have set DF and some versions
	// of GCC rely on DF being clear
	asm volatile("cld" ::: "cc");
f0103cc8:	fc                   	cld    

	// Halt the CPU if some other CPU has called panic()
	extern char *panicstr;
	if (panicstr)
f0103cc9:	83 3d c0 de 1d f0 00 	cmpl   $0x0,0xf01ddec0
f0103cd0:	74 01                	je     f0103cd3 <trap+0x13>
		asm volatile("hlt");
f0103cd2:	f4                   	hlt    

	// Re-acqurie the big kernel lock if we were halted in
	// sched_yield()
	if (xchg(&thiscpu->cpu_status, CPU_STARTED) == CPU_HALTED)
f0103cd3:	e8 6f 1c 00 00       	call   f0105947 <cpunum>
f0103cd8:	6b d0 74             	imul   $0x74,%eax,%edx
f0103cdb:	81 c2 40 e0 1d f0    	add    $0xf01de040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0103ce1:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ce6:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
f0103cea:	83 f8 02             	cmp    $0x2,%eax
f0103ced:	75 10                	jne    f0103cff <trap+0x3f>
extern struct spinlock kernel_lock;

static inline void
lock_kernel(void)
{
	spin_lock(&kernel_lock);
f0103cef:	83 ec 0c             	sub    $0xc,%esp
f0103cf2:	68 c0 04 12 f0       	push   $0xf01204c0
f0103cf7:	e8 b6 1e 00 00       	call   f0105bb2 <spin_lock>
f0103cfc:	83 c4 10             	add    $0x10,%esp

static __inline uint32_t
read_eflags(void)
{
	uint32_t eflags;
	__asm __volatile("pushfl; popl %0" : "=r" (eflags));
f0103cff:	9c                   	pushf  
f0103d00:	58                   	pop    %eax
		lock_kernel();
	// Check that interrupts are disabled.  If this assertion
	// fails, DO NOT be tempted to fix it by inserting a "cli" in
	// the interrupt path.
	assert(!(read_eflags() & FL_IF));
f0103d01:	f6 c4 02             	test   $0x2,%ah
f0103d04:	74 19                	je     f0103d1f <trap+0x5f>
f0103d06:	68 79 75 10 f0       	push   $0xf0107579
f0103d0b:	68 db 6f 10 f0       	push   $0xf0106fdb
f0103d10:	68 16 01 00 00       	push   $0x116
f0103d15:	68 6d 75 10 f0       	push   $0xf010756d
f0103d1a:	e8 21 c3 ff ff       	call   f0100040 <_panic>

	if ((tf->tf_cs & 3) == 3) {
f0103d1f:	0f b7 46 34          	movzwl 0x34(%esi),%eax
f0103d23:	83 e0 03             	and    $0x3,%eax
f0103d26:	66 83 f8 03          	cmp    $0x3,%ax
f0103d2a:	0f 85 a0 00 00 00    	jne    f0103dd0 <trap+0x110>
f0103d30:	83 ec 0c             	sub    $0xc,%esp
f0103d33:	68 c0 04 12 f0       	push   $0xf01204c0
f0103d38:	e8 75 1e 00 00       	call   f0105bb2 <spin_lock>
		// Trapped from user mode.
		// Acquire the big kernel lock before doing any
		// serious kernel work.
		// LAB 4: Your code here.
		lock_kernel(); //Lock Kernel
		assert(curenv);
f0103d3d:	e8 05 1c 00 00       	call   f0105947 <cpunum>
f0103d42:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d45:	83 c4 10             	add    $0x10,%esp
f0103d48:	83 b8 48 e0 1d f0 00 	cmpl   $0x0,-0xfe21fb8(%eax)
f0103d4f:	75 19                	jne    f0103d6a <trap+0xaa>
f0103d51:	68 92 75 10 f0       	push   $0xf0107592
f0103d56:	68 db 6f 10 f0       	push   $0xf0106fdb
f0103d5b:	68 1e 01 00 00       	push   $0x11e
f0103d60:	68 6d 75 10 f0       	push   $0xf010756d
f0103d65:	e8 d6 c2 ff ff       	call   f0100040 <_panic>

		// Garbage collect if current enviroment is a zombie
		if (curenv->env_status == ENV_DYING) {
f0103d6a:	e8 d8 1b 00 00       	call   f0105947 <cpunum>
f0103d6f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d72:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103d78:	83 78 54 01          	cmpl   $0x1,0x54(%eax)
f0103d7c:	75 2d                	jne    f0103dab <trap+0xeb>
			env_free(curenv);
f0103d7e:	e8 c4 1b 00 00       	call   f0105947 <cpunum>
f0103d83:	83 ec 0c             	sub    $0xc,%esp
f0103d86:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d89:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0103d8f:	e8 0e f6 ff ff       	call   f01033a2 <env_free>
			curenv = NULL;
f0103d94:	e8 ae 1b 00 00       	call   f0105947 <cpunum>
f0103d99:	6b c0 74             	imul   $0x74,%eax,%eax
f0103d9c:	c7 80 48 e0 1d f0 00 	movl   $0x0,-0xfe21fb8(%eax)
f0103da3:	00 00 00 
			sched_yield();
f0103da6:	e8 f5 03 00 00       	call   f01041a0 <sched_yield>
		}

		// Copy trap frame (which is currently on the stack)
		// into 'curenv->env_tf', so that running the environment
		// will restart at the trap point.
		curenv->env_tf = *tf;
f0103dab:	e8 97 1b 00 00       	call   f0105947 <cpunum>
f0103db0:	6b c0 74             	imul   $0x74,%eax,%eax
f0103db3:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103db9:	b9 11 00 00 00       	mov    $0x11,%ecx
f0103dbe:	89 c7                	mov    %eax,%edi
f0103dc0:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
		// The trapframe on the stack should be ignored from here on.
		tf = &curenv->env_tf;
f0103dc2:	e8 80 1b 00 00       	call   f0105947 <cpunum>
f0103dc7:	6b c0 74             	imul   $0x74,%eax,%eax
f0103dca:	8b b0 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%esi
	}

	// Record that tf is the last real trapframe so
	// print_trapframe can print some additional information.
	last_tf = tf;
f0103dd0:	89 35 80 da 1d f0    	mov    %esi,0xf01dda80
trap_dispatch(struct Trapframe *tf)
{
	// Handle processor exceptions.
	// LAB 3: Your code here.
	//call trap_handler function for page_fault
	switch (tf->tf_trapno) {
f0103dd6:	8b 46 28             	mov    0x28(%esi),%eax
f0103dd9:	83 f8 0e             	cmp    $0xe,%eax
f0103ddc:	74 24                	je     f0103e02 <trap+0x142>
f0103dde:	83 f8 30             	cmp    $0x30,%eax
f0103de1:	74 28                	je     f0103e0b <trap+0x14b>
f0103de3:	83 f8 03             	cmp    $0x3,%eax
f0103de6:	75 44                	jne    f0103e2c <trap+0x16c>
		case T_BRKPT:
			monitor(tf);
f0103de8:	83 ec 0c             	sub    $0xc,%esp
f0103deb:	56                   	push   %esi
f0103dec:	e8 13 cb ff ff       	call   f0100904 <monitor>
			cprintf("return from breakpoint....\n");
f0103df1:	c7 04 24 99 75 10 f0 	movl   $0xf0107599,(%esp)
f0103df8:	e8 12 fa ff ff       	call   f010380f <cprintf>
f0103dfd:	83 c4 10             	add    $0x10,%esp
f0103e00:	eb 2a                	jmp    f0103e2c <trap+0x16c>
			break;

		case T_PGFLT:
			page_fault_handler(tf);
f0103e02:	83 ec 0c             	sub    $0xc,%esp
f0103e05:	56                   	push   %esi
f0103e06:	e8 a8 fd ff ff       	call   f0103bb3 <page_fault_handler>
			break;

		case T_SYSCALL:
			tf->tf_regs.reg_eax = syscall(tf->tf_regs.reg_eax,
f0103e0b:	83 ec 08             	sub    $0x8,%esp
f0103e0e:	ff 76 04             	pushl  0x4(%esi)
f0103e11:	ff 36                	pushl  (%esi)
f0103e13:	ff 76 10             	pushl  0x10(%esi)
f0103e16:	ff 76 18             	pushl  0x18(%esi)
f0103e19:	ff 76 14             	pushl  0x14(%esi)
f0103e1c:	ff 76 1c             	pushl  0x1c(%esi)
f0103e1f:	e8 5c 04 00 00       	call   f0104280 <syscall>
f0103e24:	89 46 1c             	mov    %eax,0x1c(%esi)
f0103e27:	83 c4 20             	add    $0x20,%esp
f0103e2a:	eb 74                	jmp    f0103ea0 <trap+0x1e0>
	}

	// Handle spurious interrupts
	// The hardware sometimes raises these because of noise on the
	// IRQ line or other reasons. We don't care.
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SPURIOUS) {
f0103e2c:	8b 46 28             	mov    0x28(%esi),%eax
f0103e2f:	83 f8 27             	cmp    $0x27,%eax
f0103e32:	75 1a                	jne    f0103e4e <trap+0x18e>
		cprintf("Spurious interrupt on irq 7\n");
f0103e34:	83 ec 0c             	sub    $0xc,%esp
f0103e37:	68 b5 75 10 f0       	push   $0xf01075b5
f0103e3c:	e8 ce f9 ff ff       	call   f010380f <cprintf>
		print_trapframe(tf);
f0103e41:	89 34 24             	mov    %esi,(%esp)
f0103e44:	e8 e2 fb ff ff       	call   f0103a2b <print_trapframe>
f0103e49:	83 c4 10             	add    $0x10,%esp
f0103e4c:	eb 52                	jmp    f0103ea0 <trap+0x1e0>

	// Handle clock interrupts. Don't forget to acknowledge the
	// interrupt using lapic_eoi() before calling the scheduler!
	// LAB 4: Your code here.

	if (tf->tf_trapno == IRQ_OFFSET + IRQ_TIMER) {
f0103e4e:	83 f8 20             	cmp    $0x20,%eax
f0103e51:	75 0a                	jne    f0103e5d <trap+0x19d>
		lapic_eoi();
f0103e53:	e8 3a 1c 00 00       	call   f0105a92 <lapic_eoi>
		sched_yield();
f0103e58:	e8 43 03 00 00       	call   f01041a0 <sched_yield>


	

	// Unexpected trap: The user process or the kernel has a bug.
	print_trapframe(tf);
f0103e5d:	83 ec 0c             	sub    $0xc,%esp
f0103e60:	56                   	push   %esi
f0103e61:	e8 c5 fb ff ff       	call   f0103a2b <print_trapframe>
	if (tf->tf_cs == GD_KT){
f0103e66:	83 c4 10             	add    $0x10,%esp
f0103e69:	66 83 7e 34 08       	cmpw   $0x8,0x34(%esi)
f0103e6e:	75 17                	jne    f0103e87 <trap+0x1c7>
		panic("unhandled trap in kernel");
f0103e70:	83 ec 04             	sub    $0x4,%esp
f0103e73:	68 d2 75 10 f0       	push   $0xf01075d2
f0103e78:	68 fb 00 00 00       	push   $0xfb
f0103e7d:	68 6d 75 10 f0       	push   $0xf010756d
f0103e82:	e8 b9 c1 ff ff       	call   f0100040 <_panic>
	}
	else {
		env_destroy(curenv);
f0103e87:	e8 bb 1a 00 00       	call   f0105947 <cpunum>
f0103e8c:	83 ec 0c             	sub    $0xc,%esp
f0103e8f:	6b c0 74             	imul   $0x74,%eax,%eax
f0103e92:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0103e98:	e8 ab f6 ff ff       	call   f0103548 <env_destroy>
f0103e9d:	83 c4 10             	add    $0x10,%esp
	trap_dispatch(tf);

	// If we made it to this point, then no other environment was
	// scheduled, so we should return to the current environment
	// if doing so makes sense.
	if (curenv && curenv->env_status == ENV_RUNNING)
f0103ea0:	e8 a2 1a 00 00       	call   f0105947 <cpunum>
f0103ea5:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ea8:	83 b8 48 e0 1d f0 00 	cmpl   $0x0,-0xfe21fb8(%eax)
f0103eaf:	74 2a                	je     f0103edb <trap+0x21b>
f0103eb1:	e8 91 1a 00 00       	call   f0105947 <cpunum>
f0103eb6:	6b c0 74             	imul   $0x74,%eax,%eax
f0103eb9:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0103ebf:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0103ec3:	75 16                	jne    f0103edb <trap+0x21b>
		env_run(curenv);
f0103ec5:	e8 7d 1a 00 00       	call   f0105947 <cpunum>
f0103eca:	83 ec 0c             	sub    $0xc,%esp
f0103ecd:	6b c0 74             	imul   $0x74,%eax,%eax
f0103ed0:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0103ed6:	e8 0c f7 ff ff       	call   f01035e7 <env_run>
	else
		sched_yield();
f0103edb:	e8 c0 02 00 00       	call   f01041a0 <sched_yield>

f0103ee0 <handler_0>:
#define T_DEFAULT   500		// catchall
*/

//TRAPHANDLER_NOEC for traps without error code
// From 0-7 no error code requred
	TRAPHANDLER_NOEC(handler_0, 0)   #Divide error
f0103ee0:	6a 00                	push   $0x0
f0103ee2:	6a 00                	push   $0x0
f0103ee4:	e9 d2 01 00 00       	jmp    f01040bb <_alltraps>
f0103ee9:	90                   	nop

f0103eea <handler_1>:
	TRAPHANDLER_NOEC(handler_1, 1)   #Debug exceptions 
f0103eea:	6a 00                	push   $0x0
f0103eec:	6a 01                	push   $0x1
f0103eee:	e9 c8 01 00 00       	jmp    f01040bb <_alltraps>
f0103ef3:	90                   	nop

f0103ef4 <handler_2>:
 	TRAPHANDLER_NOEC(handler_2, 2)   //NMI Interrupt
f0103ef4:	6a 00                	push   $0x0
f0103ef6:	6a 02                	push   $0x2
f0103ef8:	e9 be 01 00 00       	jmp    f01040bb <_alltraps>
f0103efd:	90                   	nop

f0103efe <handler_3>:
	TRAPHANDLER_NOEC(handler_3, 3)   //Breakpoint
f0103efe:	6a 00                	push   $0x0
f0103f00:	6a 03                	push   $0x3
f0103f02:	e9 b4 01 00 00       	jmp    f01040bb <_alltraps>
f0103f07:	90                   	nop

f0103f08 <handler_4>:
	TRAPHANDLER_NOEC(handler_4, 4)   //Overflow
f0103f08:	6a 00                	push   $0x0
f0103f0a:	6a 04                	push   $0x4
f0103f0c:	e9 aa 01 00 00       	jmp    f01040bb <_alltraps>
f0103f11:	90                   	nop

f0103f12 <handler_5>:
	TRAPHANDLER_NOEC(handler_5, 5)   //Bounds check 
f0103f12:	6a 00                	push   $0x0
f0103f14:	6a 05                	push   $0x5
f0103f16:	e9 a0 01 00 00       	jmp    f01040bb <_alltraps>
f0103f1b:	90                   	nop

f0103f1c <handler_6>:
	TRAPHANDLER_NOEC(handler_6, 6)   //Invalid opcode
f0103f1c:	6a 00                	push   $0x0
f0103f1e:	6a 06                	push   $0x6
f0103f20:	e9 96 01 00 00       	jmp    f01040bb <_alltraps>
f0103f25:	90                   	nop

f0103f26 <handler_7>:
	TRAPHANDLER_NOEC(handler_7, 7)   //Coprocessor not available
f0103f26:	6a 00                	push   $0x0
f0103f28:	6a 07                	push   $0x7
f0103f2a:	e9 8c 01 00 00       	jmp    f01040bb <_alltraps>
f0103f2f:	90                   	nop

f0103f30 <handler_8>:
	
	TRAPHANDLER(handler_8, 8)   // double fault
f0103f30:	6a 08                	push   $0x8
f0103f32:	e9 84 01 00 00       	jmp    f01040bb <_alltraps>
f0103f37:	90                   	nop

f0103f38 <handler_9>:
	
	TRAPHANDLER_NOEC(handler_9, 9)   //Coprocessor Segment Overrun
f0103f38:	6a 00                	push   $0x0
f0103f3a:	6a 09                	push   $0x9
f0103f3c:	e9 7a 01 00 00       	jmp    f01040bb <_alltraps>
f0103f41:	90                   	nop

f0103f42 <handler_10>:

	TRAPHANDLER(handler_10, 10)   // invalid task switch segment
f0103f42:	6a 0a                	push   $0xa
f0103f44:	e9 72 01 00 00       	jmp    f01040bb <_alltraps>
f0103f49:	90                   	nop

f0103f4a <handler_11>:
	TRAPHANDLER(handler_11, 11)   // segment not present
f0103f4a:	6a 0b                	push   $0xb
f0103f4c:	e9 6a 01 00 00       	jmp    f01040bb <_alltraps>
f0103f51:	90                   	nop

f0103f52 <handler_12>:
	TRAPHANDLER(handler_12, 12)   // stack exception
f0103f52:	6a 0c                	push   $0xc
f0103f54:	e9 62 01 00 00       	jmp    f01040bb <_alltraps>
f0103f59:	90                   	nop

f0103f5a <handler_13>:
	TRAPHANDLER(handler_13, 13)   // general protection fault
f0103f5a:	6a 0d                	push   $0xd
f0103f5c:	e9 5a 01 00 00       	jmp    f01040bb <_alltraps>
f0103f61:	90                   	nop

f0103f62 <handler_14>:
	TRAPHANDLER(handler_14, 14)   // page fault
f0103f62:	6a 0e                	push   $0xe
f0103f64:	e9 52 01 00 00       	jmp    f01040bb <_alltraps>
f0103f69:	90                   	nop

f0103f6a <handler_15>:

	TRAPHANDLER_NOEC(handler_15, 15)   // Reserved
f0103f6a:	6a 00                	push   $0x0
f0103f6c:	6a 0f                	push   $0xf
f0103f6e:	e9 48 01 00 00       	jmp    f01040bb <_alltraps>
f0103f73:	90                   	nop

f0103f74 <handler_16>:

	TRAPHANDLER_NOEC(handler_16, 16)   // floating point error
f0103f74:	6a 00                	push   $0x0
f0103f76:	6a 10                	push   $0x10
f0103f78:	e9 3e 01 00 00       	jmp    f01040bb <_alltraps>
f0103f7d:	90                   	nop

f0103f7e <handler_17>:

	TRAPHANDLER(handler_17, 17)   // aligment check
f0103f7e:	6a 11                	push   $0x11
f0103f80:	e9 36 01 00 00       	jmp    f01040bb <_alltraps>
f0103f85:	90                   	nop

f0103f86 <handler_18>:

	TRAPHANDLER_NOEC(handler_18, 18)   // machine check
f0103f86:	6a 00                	push   $0x0
f0103f88:	6a 12                	push   $0x12
f0103f8a:	e9 2c 01 00 00       	jmp    f01040bb <_alltraps>
f0103f8f:	90                   	nop

f0103f90 <handler_19>:
	TRAPHANDLER_NOEC(handler_19, 19)   // SIMD floating point error
f0103f90:	6a 00                	push   $0x0
f0103f92:	6a 13                	push   $0x13
f0103f94:	e9 22 01 00 00       	jmp    f01040bb <_alltraps>
f0103f99:	90                   	nop

f0103f9a <handler_20>:

	TRAPHANDLER_NOEC(handler_20, 20)
f0103f9a:	6a 00                	push   $0x0
f0103f9c:	6a 14                	push   $0x14
f0103f9e:	e9 18 01 00 00       	jmp    f01040bb <_alltraps>
f0103fa3:	90                   	nop

f0103fa4 <handler_21>:
	TRAPHANDLER_NOEC(handler_21, 21)
f0103fa4:	6a 00                	push   $0x0
f0103fa6:	6a 15                	push   $0x15
f0103fa8:	e9 0e 01 00 00       	jmp    f01040bb <_alltraps>
f0103fad:	90                   	nop

f0103fae <handler_22>:
	TRAPHANDLER_NOEC(handler_22, 22)
f0103fae:	6a 00                	push   $0x0
f0103fb0:	6a 16                	push   $0x16
f0103fb2:	e9 04 01 00 00       	jmp    f01040bb <_alltraps>
f0103fb7:	90                   	nop

f0103fb8 <handler_23>:
	TRAPHANDLER_NOEC(handler_23, 23)
f0103fb8:	6a 00                	push   $0x0
f0103fba:	6a 17                	push   $0x17
f0103fbc:	e9 fa 00 00 00       	jmp    f01040bb <_alltraps>
f0103fc1:	90                   	nop

f0103fc2 <handler_24>:
	TRAPHANDLER_NOEC(handler_24, 24)
f0103fc2:	6a 00                	push   $0x0
f0103fc4:	6a 18                	push   $0x18
f0103fc6:	e9 f0 00 00 00       	jmp    f01040bb <_alltraps>
f0103fcb:	90                   	nop

f0103fcc <handler_25>:
	TRAPHANDLER_NOEC(handler_25, 25)
f0103fcc:	6a 00                	push   $0x0
f0103fce:	6a 19                	push   $0x19
f0103fd0:	e9 e6 00 00 00       	jmp    f01040bb <_alltraps>
f0103fd5:	90                   	nop

f0103fd6 <handler_26>:
	TRAPHANDLER_NOEC(handler_26, 26)
f0103fd6:	6a 00                	push   $0x0
f0103fd8:	6a 1a                	push   $0x1a
f0103fda:	e9 dc 00 00 00       	jmp    f01040bb <_alltraps>
f0103fdf:	90                   	nop

f0103fe0 <handler_27>:
	TRAPHANDLER_NOEC(handler_27, 27)
f0103fe0:	6a 00                	push   $0x0
f0103fe2:	6a 1b                	push   $0x1b
f0103fe4:	e9 d2 00 00 00       	jmp    f01040bb <_alltraps>
f0103fe9:	90                   	nop

f0103fea <handler_28>:
	TRAPHANDLER_NOEC(handler_28, 28)
f0103fea:	6a 00                	push   $0x0
f0103fec:	6a 1c                	push   $0x1c
f0103fee:	e9 c8 00 00 00       	jmp    f01040bb <_alltraps>
f0103ff3:	90                   	nop

f0103ff4 <handler_29>:
	TRAPHANDLER_NOEC(handler_29, 29)
f0103ff4:	6a 00                	push   $0x0
f0103ff6:	6a 1d                	push   $0x1d
f0103ff8:	e9 be 00 00 00       	jmp    f01040bb <_alltraps>
f0103ffd:	90                   	nop

f0103ffe <handler_30>:
	TRAPHANDLER_NOEC(handler_30, 30)
f0103ffe:	6a 00                	push   $0x0
f0104000:	6a 1e                	push   $0x1e
f0104002:	e9 b4 00 00 00       	jmp    f01040bb <_alltraps>
f0104007:	90                   	nop

f0104008 <handler_31>:
	TRAPHANDLER_NOEC(handler_31, 31)
f0104008:	6a 00                	push   $0x0
f010400a:	6a 1f                	push   $0x1f
f010400c:	e9 aa 00 00 00       	jmp    f01040bb <_alltraps>
f0104011:	90                   	nop

f0104012 <handler_32>:
	TRAPHANDLER_NOEC(handler_32, 32)
f0104012:	6a 00                	push   $0x0
f0104014:	6a 20                	push   $0x20
f0104016:	e9 a0 00 00 00       	jmp    f01040bb <_alltraps>
f010401b:	90                   	nop

f010401c <handler_33>:
	TRAPHANDLER_NOEC(handler_33, 33)
f010401c:	6a 00                	push   $0x0
f010401e:	6a 21                	push   $0x21
f0104020:	e9 96 00 00 00       	jmp    f01040bb <_alltraps>
f0104025:	90                   	nop

f0104026 <handler_34>:
	TRAPHANDLER_NOEC(handler_34, 34)
f0104026:	6a 00                	push   $0x0
f0104028:	6a 22                	push   $0x22
f010402a:	e9 8c 00 00 00       	jmp    f01040bb <_alltraps>
f010402f:	90                   	nop

f0104030 <handler_35>:
	TRAPHANDLER_NOEC(handler_35, 35)
f0104030:	6a 00                	push   $0x0
f0104032:	6a 23                	push   $0x23
f0104034:	e9 82 00 00 00       	jmp    f01040bb <_alltraps>
f0104039:	90                   	nop

f010403a <handler_36>:
	TRAPHANDLER_NOEC(handler_36, 36)
f010403a:	6a 00                	push   $0x0
f010403c:	6a 24                	push   $0x24
f010403e:	e9 78 00 00 00       	jmp    f01040bb <_alltraps>
f0104043:	90                   	nop

f0104044 <handler_37>:
	TRAPHANDLER_NOEC(handler_37, 37)
f0104044:	6a 00                	push   $0x0
f0104046:	6a 25                	push   $0x25
f0104048:	e9 6e 00 00 00       	jmp    f01040bb <_alltraps>
f010404d:	90                   	nop

f010404e <handler_38>:
	TRAPHANDLER_NOEC(handler_38, 38)
f010404e:	6a 00                	push   $0x0
f0104050:	6a 26                	push   $0x26
f0104052:	e9 64 00 00 00       	jmp    f01040bb <_alltraps>
f0104057:	90                   	nop

f0104058 <handler_39>:
	TRAPHANDLER_NOEC(handler_39, 39)
f0104058:	6a 00                	push   $0x0
f010405a:	6a 27                	push   $0x27
f010405c:	e9 5a 00 00 00       	jmp    f01040bb <_alltraps>
f0104061:	90                   	nop

f0104062 <handler_40>:
	TRAPHANDLER_NOEC(handler_40, 40)
f0104062:	6a 00                	push   $0x0
f0104064:	6a 28                	push   $0x28
f0104066:	e9 50 00 00 00       	jmp    f01040bb <_alltraps>
f010406b:	90                   	nop

f010406c <handler_41>:
	TRAPHANDLER_NOEC(handler_41, 41)
f010406c:	6a 00                	push   $0x0
f010406e:	6a 29                	push   $0x29
f0104070:	e9 46 00 00 00       	jmp    f01040bb <_alltraps>
f0104075:	90                   	nop

f0104076 <handler_42>:
	TRAPHANDLER_NOEC(handler_42, 42)
f0104076:	6a 00                	push   $0x0
f0104078:	6a 2a                	push   $0x2a
f010407a:	e9 3c 00 00 00       	jmp    f01040bb <_alltraps>
f010407f:	90                   	nop

f0104080 <handler_43>:
	TRAPHANDLER_NOEC(handler_43, 43)
f0104080:	6a 00                	push   $0x0
f0104082:	6a 2b                	push   $0x2b
f0104084:	e9 32 00 00 00       	jmp    f01040bb <_alltraps>
f0104089:	90                   	nop

f010408a <handler_44>:
	TRAPHANDLER_NOEC(handler_44, 44)
f010408a:	6a 00                	push   $0x0
f010408c:	6a 2c                	push   $0x2c
f010408e:	e9 28 00 00 00       	jmp    f01040bb <_alltraps>
f0104093:	90                   	nop

f0104094 <handler_45>:
	TRAPHANDLER_NOEC(handler_45, 45)
f0104094:	6a 00                	push   $0x0
f0104096:	6a 2d                	push   $0x2d
f0104098:	e9 1e 00 00 00       	jmp    f01040bb <_alltraps>
f010409d:	90                   	nop

f010409e <handler_46>:
	TRAPHANDLER_NOEC(handler_46, 46)
f010409e:	6a 00                	push   $0x0
f01040a0:	6a 2e                	push   $0x2e
f01040a2:	e9 14 00 00 00       	jmp    f01040bb <_alltraps>
f01040a7:	90                   	nop

f01040a8 <handler_47>:
	TRAPHANDLER_NOEC(handler_47, 47)
f01040a8:	6a 00                	push   $0x0
f01040aa:	6a 2f                	push   $0x2f
f01040ac:	e9 0a 00 00 00       	jmp    f01040bb <_alltraps>
f01040b1:	90                   	nop

f01040b2 <handler_48>:

	TRAPHANDLER_NOEC(handler_48, 48)   // system call
f01040b2:	6a 00                	push   $0x0
f01040b4:	6a 30                	push   $0x30
f01040b6:	e9 00 00 00 00       	jmp    f01040bb <_alltraps>

f01040bb <_alltraps>:
 */

.globl _alltraps
_alltraps:
	#Remaining Trap frame
	push %ds
f01040bb:	1e                   	push   %ds
	push %es
f01040bc:	06                   	push   %es
	pushal
f01040bd:	60                   	pusha  

	
	movw $GD_KD, %ax
f01040be:	66 b8 10 00          	mov    $0x10,%ax
	movw %ax, %ds
f01040c2:	8e d8                	mov    %eax,%ds
	movw %ax, %es
f01040c4:	8e c0                	mov    %eax,%es

	#call Trap 
	pushl %esp
f01040c6:	54                   	push   %esp
	call trap
f01040c7:	e8 f4 fb ff ff       	call   f0103cc0 <trap>

f01040cc <sched_halt>:
// Halt this CPU when there is nothing to do. Wait until the
// timer interrupt wakes it up. This function never returns.
//
void
sched_halt(void)
{
f01040cc:	55                   	push   %ebp
f01040cd:	89 e5                	mov    %esp,%ebp
f01040cf:	83 ec 08             	sub    $0x8,%esp
f01040d2:	a1 6c d2 1d f0       	mov    0xf01dd26c,%eax
f01040d7:	8d 50 54             	lea    0x54(%eax),%edx
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01040da:	b9 00 00 00 00       	mov    $0x0,%ecx
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
f01040df:	8b 02                	mov    (%edx),%eax
f01040e1:	83 e8 01             	sub    $0x1,%eax
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
		if ((envs[i].env_status == ENV_RUNNABLE ||
f01040e4:	83 f8 02             	cmp    $0x2,%eax
f01040e7:	76 10                	jbe    f01040f9 <sched_halt+0x2d>
{
	int i;

	// For debugging and testing purposes, if there are no runnable
	// environments in the system, then drop into the kernel monitor.
	for (i = 0; i < NENV; i++) {
f01040e9:	83 c1 01             	add    $0x1,%ecx
f01040ec:	83 c2 7c             	add    $0x7c,%edx
f01040ef:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01040f5:	75 e8                	jne    f01040df <sched_halt+0x13>
f01040f7:	eb 08                	jmp    f0104101 <sched_halt+0x35>
		if ((envs[i].env_status == ENV_RUNNABLE ||
		     envs[i].env_status == ENV_RUNNING ||
		     envs[i].env_status == ENV_DYING))
			break;
	}
	if (i == NENV) {
f01040f9:	81 f9 00 04 00 00    	cmp    $0x400,%ecx
f01040ff:	75 1f                	jne    f0104120 <sched_halt+0x54>
		cprintf("No runnable environments in the system!\n");
f0104101:	83 ec 0c             	sub    $0xc,%esp
f0104104:	68 d0 77 10 f0       	push   $0xf01077d0
f0104109:	e8 01 f7 ff ff       	call   f010380f <cprintf>
f010410e:	83 c4 10             	add    $0x10,%esp
		while (1)
			monitor(NULL);
f0104111:	83 ec 0c             	sub    $0xc,%esp
f0104114:	6a 00                	push   $0x0
f0104116:	e8 e9 c7 ff ff       	call   f0100904 <monitor>
f010411b:	83 c4 10             	add    $0x10,%esp
f010411e:	eb f1                	jmp    f0104111 <sched_halt+0x45>
	}

	// Mark that no environment is running on this CPU
	curenv = NULL;
f0104120:	e8 22 18 00 00       	call   f0105947 <cpunum>
f0104125:	6b c0 74             	imul   $0x74,%eax,%eax
f0104128:	c7 80 48 e0 1d f0 00 	movl   $0x0,-0xfe21fb8(%eax)
f010412f:	00 00 00 
	lcr3(PADDR(kern_pgdir));
f0104132:	a1 cc de 1d f0       	mov    0xf01ddecc,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0104137:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010413c:	77 12                	ja     f0104150 <sched_halt+0x84>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010413e:	50                   	push   %eax
f010413f:	68 48 60 10 f0       	push   $0xf0106048
f0104144:	6a 54                	push   $0x54
f0104146:	68 f9 77 10 f0       	push   $0xf01077f9
f010414b:	e8 f0 be ff ff       	call   f0100040 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0104150:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0104155:	0f 22 d8             	mov    %eax,%cr3

	// Mark that this CPU is in the HALT state, so that when
	// timer interupts come in, we know we should re-acquire the
	// big kernel lock
	xchg(&thiscpu->cpu_status, CPU_HALTED);
f0104158:	e8 ea 17 00 00       	call   f0105947 <cpunum>
f010415d:	6b d0 74             	imul   $0x74,%eax,%edx
f0104160:	81 c2 40 e0 1d f0    	add    $0xf01de040,%edx
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0104166:	b8 02 00 00 00       	mov    $0x2,%eax
f010416b:	f0 87 42 04          	lock xchg %eax,0x4(%edx)
}

static inline void
unlock_kernel(void)
{
	spin_unlock(&kernel_lock);
f010416f:	83 ec 0c             	sub    $0xc,%esp
f0104172:	68 c0 04 12 f0       	push   $0xf01204c0
f0104177:	e8 d3 1a 00 00       	call   f0105c4f <spin_unlock>

	// Normally we wouldn't need to do this, but QEMU only runs
	// one CPU at a time and has a long time-slice.  Without the
	// pause, this CPU is likely to reacquire the lock before
	// another CPU has even been given a chance to acquire it.
	asm volatile("pause");
f010417c:	f3 90                	pause  
		"pushl $0\n"
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
f010417e:	e8 c4 17 00 00       	call   f0105947 <cpunum>
f0104183:	6b c0 74             	imul   $0x74,%eax,%eax

	// Release the big kernel lock as if we were "leaving" the kernel
	unlock_kernel();

	// Reset stack pointer, enable interrupts and then halt.
	asm volatile (
f0104186:	8b 80 50 e0 1d f0    	mov    -0xfe21fb0(%eax),%eax
f010418c:	bd 00 00 00 00       	mov    $0x0,%ebp
f0104191:	89 c4                	mov    %eax,%esp
f0104193:	6a 00                	push   $0x0
f0104195:	6a 00                	push   $0x0
f0104197:	fb                   	sti    
f0104198:	f4                   	hlt    
f0104199:	eb fd                	jmp    f0104198 <sched_halt+0xcc>
f010419b:	83 c4 10             	add    $0x10,%esp
		"sti\n"
		"1:\n"
		"hlt\n"
		"jmp 1b\n"
	: : "a" (thiscpu->cpu_ts.ts_esp0));
}
f010419e:	c9                   	leave  
f010419f:	c3                   	ret    

f01041a0 <sched_yield>:
void sched_halt(void);

// Choose a user environment to run and run it.
void
sched_yield(void)
{
f01041a0:	55                   	push   %ebp
f01041a1:	89 e5                	mov    %esp,%ebp
f01041a3:	53                   	push   %ebx
f01041a4:	83 ec 04             	sub    $0x4,%esp
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01041a7:	e8 9b 17 00 00       	call   f0105947 <cpunum>
f01041ac:	6b c0 74             	imul   $0x74,%eax,%eax
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
f01041af:	ba 00 00 00 00       	mov    $0x0,%edx
	// below to halt the cpu.

	// LAB 4: Your code here.
	int envVal, j = 0 ;
	 
	if (curenv)
f01041b4:	83 b8 48 e0 1d f0 00 	cmpl   $0x0,-0xfe21fb8(%eax)
f01041bb:	74 33                	je     f01041f0 <sched_yield+0x50>
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
f01041bd:	e8 85 17 00 00       	call   f0105947 <cpunum>
f01041c2:	6b c0 74             	imul   $0x74,%eax,%eax
f01041c5:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f01041cb:	2b 05 6c d2 1d f0    	sub    0xf01dd26c,%eax
f01041d1:	c1 f8 02             	sar    $0x2,%eax
f01041d4:	69 c0 df 7b ef bd    	imul   $0xbdef7bdf,%eax,%eax
f01041da:	83 c0 01             	add    $0x1,%eax
f01041dd:	89 c1                	mov    %eax,%ecx
f01041df:	c1 f9 1f             	sar    $0x1f,%ecx
f01041e2:	c1 e9 16             	shr    $0x16,%ecx
f01041e5:	8d 14 08             	lea    (%eax,%ecx,1),%edx
f01041e8:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f01041ee:	29 ca                	sub    %ecx,%edx
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
	{
		if (envs[envVal].env_status == ENV_RUNNABLE)
f01041f0:	a1 6c d2 1d f0       	mov    0xf01dd26c,%eax
f01041f5:	b9 00 04 00 00       	mov    $0x400,%ecx
f01041fa:	6b da 7c             	imul   $0x7c,%edx,%ebx
f01041fd:	83 7c 18 54 02       	cmpl   $0x2,0x54(%eax,%ebx,1)
f0104202:	74 70                	je     f0104274 <sched_yield+0xd4>
		    break;
		else
		    envVal=(envVal+1)%NENV;
f0104204:	83 c2 01             	add    $0x1,%edx
f0104207:	89 d3                	mov    %edx,%ebx
f0104209:	c1 fb 1f             	sar    $0x1f,%ebx
f010420c:	c1 eb 16             	shr    $0x16,%ebx
f010420f:	01 da                	add    %ebx,%edx
f0104211:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0104217:	29 da                	sub    %ebx,%edx
		envVal = (curenv - envs +1 ) % NENV;  // Since both curenv and envs are arrays, to get the index into the env array
						     // we can use the value 'curenv- envs' to get the current env and +1 to get the next env
	else 
		envVal = 0; 
	
	for (j = 0; j< NENV; j++)
f0104219:	83 e9 01             	sub    $0x1,%ecx
f010421c:	75 dc                	jne    f01041fa <sched_yield+0x5a>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f010421e:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104221:	01 c2                	add    %eax,%edx
f0104223:	83 7a 54 02          	cmpl   $0x2,0x54(%edx)
f0104227:	75 09                	jne    f0104232 <sched_yield+0x92>
	{
	    idle = envs + envVal ;
	    env_run(idle);
f0104229:	83 ec 0c             	sub    $0xc,%esp
f010422c:	52                   	push   %edx
f010422d:	e8 b5 f3 ff ff       	call   f01035e7 <env_run>
	} 
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
f0104232:	e8 10 17 00 00       	call   f0105947 <cpunum>
f0104237:	6b c0 74             	imul   $0x74,%eax,%eax
f010423a:	83 b8 48 e0 1d f0 00 	cmpl   $0x0,-0xfe21fb8(%eax)
f0104241:	74 2a                	je     f010426d <sched_yield+0xcd>
f0104243:	e8 ff 16 00 00       	call   f0105947 <cpunum>
f0104248:	6b c0 74             	imul   $0x74,%eax,%eax
f010424b:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0104251:	83 78 54 03          	cmpl   $0x3,0x54(%eax)
f0104255:	75 16                	jne    f010426d <sched_yield+0xcd>
	    env_run(curenv) ;
f0104257:	e8 eb 16 00 00       	call   f0105947 <cpunum>
f010425c:	83 ec 0c             	sub    $0xc,%esp
f010425f:	6b c0 74             	imul   $0x74,%eax,%eax
f0104262:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0104268:	e8 7a f3 ff ff       	call   f01035e7 <env_run>
	}
	// sched_halt never returns
	sched_halt();
f010426d:	e8 5a fe ff ff       	call   f01040cc <sched_halt>
f0104272:	eb 07                	jmp    f010427b <sched_yield+0xdb>
		    break;
		else
		    envVal=(envVal+1)%NENV;
	}
	
	if (envs[envVal].env_status == ENV_RUNNABLE)
f0104274:	6b d2 7c             	imul   $0x7c,%edx,%edx
f0104277:	01 c2                	add    %eax,%edx
f0104279:	eb ae                	jmp    f0104229 <sched_yield+0x89>
	else if (!idle && (curenv) && (curenv->env_status == ENV_RUNNING) ){
	    env_run(curenv) ;
	}
	// sched_halt never returns
	sched_halt();
}
f010427b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010427e:	c9                   	leave  
f010427f:	c3                   	ret    

f0104280 <syscall>:
}

// Dispatches to the correct kernel function, passing the arguments.
int32_t
syscall(uint32_t syscallno, uint32_t a1, uint32_t a2, uint32_t a3, uint32_t a4, uint32_t a5)
{
f0104280:	55                   	push   %ebp
f0104281:	89 e5                	mov    %esp,%ebp
f0104283:	57                   	push   %edi
f0104284:	56                   	push   %esi
f0104285:	53                   	push   %ebx
f0104286:	83 ec 1c             	sub    $0x1c,%esp
f0104289:	8b 45 08             	mov    0x8(%ebp),%eax
	// Return any appropriate return value.
	// LAB 3: Your code here.

	

	switch (syscallno) {
f010428c:	83 f8 0d             	cmp    $0xd,%eax
f010428f:	0f 87 d2 04 00 00    	ja     f0104767 <syscall+0x4e7>
f0104295:	ff 24 85 30 78 10 f0 	jmp    *-0xfef87d0(,%eax,4)
{
	// Check that the user has permission to read memory [s, s+len).
	// Destroy the environment if not.

	// LAB 3: Your code here.
	user_mem_assert(curenv, s, len, PTE_P | PTE_U);
f010429c:	e8 a6 16 00 00       	call   f0105947 <cpunum>
f01042a1:	6a 05                	push   $0x5
f01042a3:	ff 75 10             	pushl  0x10(%ebp)
f01042a6:	ff 75 0c             	pushl  0xc(%ebp)
f01042a9:	6b c0 74             	imul   $0x74,%eax,%eax
f01042ac:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f01042b2:	e8 6c ec ff ff       	call   f0102f23 <user_mem_assert>
	// Print the string supplied by the user.
	cprintf("%.*s", len, s);
f01042b7:	83 c4 0c             	add    $0xc,%esp
f01042ba:	ff 75 0c             	pushl  0xc(%ebp)
f01042bd:	ff 75 10             	pushl  0x10(%ebp)
f01042c0:	68 06 78 10 f0       	push   $0xf0107806
f01042c5:	e8 45 f5 ff ff       	call   f010380f <cprintf>
f01042ca:	83 c4 10             	add    $0x10,%esp

	switch (syscallno) {

	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;
f01042cd:	b8 00 00 00 00       	mov    $0x0,%eax
f01042d2:	e9 ac 04 00 00       	jmp    f0104783 <syscall+0x503>
// Read a character from the system console without blocking.
// Returns the character, or 0 if there is no input waiting.
static int
sys_cgetc(void)
{
	return cons_getc();
f01042d7:	e8 0e c3 ff ff       	call   f01005ea <cons_getc>
	case SYS_cputs:
		sys_cputs((char *)a1, (size_t)a2);
		return 0;

	case SYS_cgetc:
		return sys_cgetc();
f01042dc:	e9 a2 04 00 00       	jmp    f0104783 <syscall+0x503>

// Returns the current environment's envid.
static envid_t
sys_getenvid(void)
{
	return curenv->env_id;
f01042e1:	e8 61 16 00 00       	call   f0105947 <cpunum>
f01042e6:	6b c0 74             	imul   $0x74,%eax,%eax
f01042e9:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f01042ef:	8b 40 48             	mov    0x48(%eax),%eax

	case SYS_cgetc:
		return sys_cgetc();
		
	case SYS_getenvid:
		return sys_getenvid();
f01042f2:	e9 8c 04 00 00       	jmp    f0104783 <syscall+0x503>
sys_env_destroy(envid_t envid)
{
	int r;
	struct Env *e;

	if ((r = envid2env(envid, &e, 1)) < 0)
f01042f7:	83 ec 04             	sub    $0x4,%esp
f01042fa:	6a 01                	push   $0x1
f01042fc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01042ff:	50                   	push   %eax
f0104300:	ff 75 0c             	pushl  0xc(%ebp)
f0104303:	e8 eb ec ff ff       	call   f0102ff3 <envid2env>
f0104308:	89 c2                	mov    %eax,%edx
f010430a:	83 c4 10             	add    $0x10,%esp
f010430d:	85 d2                	test   %edx,%edx
f010430f:	0f 88 6e 04 00 00    	js     f0104783 <syscall+0x503>
		return r;
	env_destroy(e);
f0104315:	83 ec 0c             	sub    $0xc,%esp
f0104318:	ff 75 e4             	pushl  -0x1c(%ebp)
f010431b:	e8 28 f2 ff ff       	call   f0103548 <env_destroy>
f0104320:	83 c4 10             	add    $0x10,%esp
	return 0;
f0104323:	b8 00 00 00 00       	mov    $0x0,%eax
f0104328:	e9 56 04 00 00       	jmp    f0104783 <syscall+0x503>

// Deschedule current environment and pick a different one to run.
static void
sys_yield(void)
{
	sched_yield();
f010432d:	e8 6e fe ff ff       	call   f01041a0 <sched_yield>
	// from the current environment -- but tweaked so sys_exofork
	// will appear to return 0.

	// LAB 4: Your code here.
	struct Env* childenv;
	int errcode = env_alloc(&childenv, curenv->env_id);
f0104332:	e8 10 16 00 00       	call   f0105947 <cpunum>
f0104337:	83 ec 08             	sub    $0x8,%esp
f010433a:	6b c0 74             	imul   $0x74,%eax,%eax
f010433d:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0104343:	ff 70 48             	pushl  0x48(%eax)
f0104346:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104349:	50                   	push   %eax
f010434a:	e8 af ed ff ff       	call   f01030fe <env_alloc>
f010434f:	89 c2                	mov    %eax,%edx
	
	//If the error code is less than 0, that means there has been an error while creating an env	
	if (errcode < 0) {
f0104351:	83 c4 10             	add    $0x10,%esp
f0104354:	85 d2                	test   %edx,%edx
f0104356:	0f 88 27 04 00 00    	js     f0104783 <syscall+0x503>
		return errcode; //Return the environment
	}
	
	//Set the child environment as not runnable	
	childenv->env_status = ENV_NOT_RUNNABLE;
f010435c:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f010435f:	c7 43 54 04 00 00 00 	movl   $0x4,0x54(%ebx)

	//Copy the current environemnt register data into the child
	childenv->env_tf = curenv->env_tf;
f0104366:	e8 dc 15 00 00       	call   f0105947 <cpunum>
f010436b:	6b c0 74             	imul   $0x74,%eax,%eax
f010436e:	8b b0 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%esi
f0104374:	b9 11 00 00 00       	mov    $0x11,%ecx
f0104379:	89 df                	mov    %ebx,%edi
f010437b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

	// when the child is scheduled to run, it has to restart the trapframe. 
	//Hence we modify the register eax to be 0. 

	childenv->env_tf.tf_regs.reg_eax = 0; 
f010437d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104380:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

	return childenv->env_id;
f0104387:	8b 40 48             	mov    0x48(%eax),%eax
f010438a:	e9 f4 03 00 00       	jmp    f0104783 <syscall+0x503>

	// LAB 4: Your code here.
	
	struct Env *env_store;
	int errcode; 
	errcode = envid2env(envid, &env_store,1);
f010438f:	83 ec 04             	sub    $0x4,%esp
f0104392:	6a 01                	push   $0x1
f0104394:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104397:	50                   	push   %eax
f0104398:	ff 75 0c             	pushl  0xc(%ebp)
f010439b:	e8 53 ec ff ff       	call   f0102ff3 <envid2env>
	if (errcode < 0)
f01043a0:	83 c4 10             	add    $0x10,%esp
f01043a3:	85 c0                	test   %eax,%eax
f01043a5:	0f 88 d8 03 00 00    	js     f0104783 <syscall+0x503>
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f01043ab:	8b 45 10             	mov    0x10(%ebp),%eax
f01043ae:	8d 50 fe             	lea    -0x2(%eax),%edx
		env_store->env_status = status;

	else
		return E_INVAL;
f01043b1:	b8 03 00 00 00       	mov    $0x3,%eax
	errcode = envid2env(envid, &env_store,1);
	if (errcode < 0)
		return errcode;
	
	//Check if status is runnable or not runnable
	if (status == ENV_RUNNABLE || status == ENV_NOT_RUNNABLE)
f01043b6:	f7 c2 fd ff ff ff    	test   $0xfffffffd,%edx
f01043bc:	0f 85 c1 03 00 00    	jne    f0104783 <syscall+0x503>
		env_store->env_status = status;
f01043c2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01043c5:	8b 75 10             	mov    0x10(%ebp),%esi
f01043c8:	89 70 54             	mov    %esi,0x54(%eax)

	else
		return E_INVAL;

	return 0;
f01043cb:	b8 00 00 00 00       	mov    $0x0,%eax
f01043d0:	e9 ae 03 00 00       	jmp    f0104783 <syscall+0x503>
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
		return  E_INVAL;
f01043d5:	b8 03 00 00 00       	mov    $0x3,%eax
	
	struct Env *en; 
	int code;
	
	//Check for valid address and page alignment
	if((((uint32_t)va) >= UTOP) || (((uint32_t)va) % PGSIZE) !=0)
f01043da:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01043e1:	0f 87 9c 03 00 00    	ja     f0104783 <syscall+0x503>
f01043e7:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f01043ee:	0f 85 8f 03 00 00    	jne    f0104783 <syscall+0x503>
		return  E_INVAL;

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f01043f4:	f7 45 14 fd f1 ff ff 	testl  $0xfffff1fd,0x14(%ebp)
f01043fb:	0f 84 82 03 00 00    	je     f0104783 <syscall+0x503>
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
f0104401:	83 ec 0c             	sub    $0xc,%esp
f0104404:	6a 01                	push   $0x1
f0104406:	e8 bd cb ff ff       	call   f0100fc8 <page_alloc>
f010440b:	89 c3                	mov    %eax,%ebx
	if (!newpage)
f010440d:	83 c4 10             	add    $0x10,%esp
		return E_NO_MEM; 
f0104410:	b8 04 00 00 00       	mov    $0x4,%eax
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return E_INVAL;

	//Page allocation check
	struct PageInfo *newpage = page_alloc(ALLOC_ZERO); 
	if (!newpage)
f0104415:	85 db                	test   %ebx,%ebx
f0104417:	0f 84 66 03 00 00    	je     f0104783 <syscall+0x503>
		return E_NO_MEM; 

	//Use environid to get the environment 
	if ((code = envid2env(envid, &en,1))<0)
f010441d:	83 ec 04             	sub    $0x4,%esp
f0104420:	6a 01                	push   $0x1
f0104422:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0104425:	50                   	push   %eax
f0104426:	ff 75 0c             	pushl  0xc(%ebp)
f0104429:	e8 c5 eb ff ff       	call   f0102ff3 <envid2env>
f010442e:	83 c4 10             	add    $0x10,%esp
f0104431:	85 c0                	test   %eax,%eax
f0104433:	0f 88 4a 03 00 00    	js     f0104783 <syscall+0x503>
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
f0104439:	ff 75 14             	pushl  0x14(%ebp)
f010443c:	ff 75 10             	pushl  0x10(%ebp)
f010443f:	53                   	push   %ebx
f0104440:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104443:	ff 70 60             	pushl  0x60(%eax)
f0104446:	e8 a3 ce ff ff       	call   f01012ee <page_insert>
f010444b:	89 c6                	mov    %eax,%esi
	if (code < 0)
f010444d:	83 c4 10             	add    $0x10,%esp
	{
		page_free(newpage);
		return code;
	}
	
	return 0;
f0104450:	b8 00 00 00 00       	mov    $0x0,%eax
	if ((code = envid2env(envid, &en,1))<0)
		return code;

	//Check if the page mapping is correct otherwise free the page
	code=page_insert(en->env_pgdir,newpage,(void *)va,perm);
	if (code < 0)
f0104455:	85 f6                	test   %esi,%esi
f0104457:	0f 89 26 03 00 00    	jns    f0104783 <syscall+0x503>
	{
		page_free(newpage);
f010445d:	83 ec 0c             	sub    $0xc,%esp
f0104460:	53                   	push   %ebx
f0104461:	e8 d8 cb ff ff       	call   f010103e <page_free>
f0104466:	83 c4 10             	add    $0x10,%esp
		return code;
f0104469:	89 f0                	mov    %esi,%eax
f010446b:	e9 13 03 00 00       	jmp    f0104783 <syscall+0x503>
	struct Env* src_env;
	struct Env* dst_env;
	int errcode;
	
	//Check for valid src env id
	errcode = envid2env(srcenvid, &src_env, 1);
f0104470:	83 ec 04             	sub    $0x4,%esp
f0104473:	6a 01                	push   $0x1
f0104475:	8d 45 dc             	lea    -0x24(%ebp),%eax
f0104478:	50                   	push   %eax
f0104479:	ff 75 0c             	pushl  0xc(%ebp)
f010447c:	e8 72 eb ff ff       	call   f0102ff3 <envid2env>
f0104481:	89 c2                	mov    %eax,%edx
	if (errcode < 0) 
f0104483:	83 c4 10             	add    $0x10,%esp
f0104486:	85 d2                	test   %edx,%edx
f0104488:	0f 88 f5 02 00 00    	js     f0104783 <syscall+0x503>
		return errcode;
	
	//Check for valid des env id
	errcode = envid2env(dstenvid, &dst_env, 1);
f010448e:	83 ec 04             	sub    $0x4,%esp
f0104491:	6a 01                	push   $0x1
f0104493:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0104496:	50                   	push   %eax
f0104497:	ff 75 14             	pushl  0x14(%ebp)
f010449a:	e8 54 eb ff ff       	call   f0102ff3 <envid2env>
	if (errcode < 0) 
f010449f:	83 c4 10             	add    $0x10,%esp
f01044a2:	85 c0                	test   %eax,%eax
f01044a4:	0f 88 d9 02 00 00    	js     f0104783 <syscall+0x503>
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
f01044aa:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f01044b1:	77 6d                	ja     f0104520 <syscall+0x2a0>
f01044b3:	81 7d 18 ff ff bf ee 	cmpl   $0xeebfffff,0x18(%ebp)
f01044ba:	77 64                	ja     f0104520 <syscall+0x2a0>
f01044bc:	8b 45 10             	mov    0x10(%ebp),%eax
f01044bf:	0b 45 18             	or     0x18(%ebp),%eax
		return -E_INVAL;
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
f01044c2:	a9 ff 0f 00 00       	test   $0xfff,%eax
f01044c7:	75 61                	jne    f010452a <syscall+0x2aa>
		return -E_INVAL;

	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
f01044c9:	83 ec 04             	sub    $0x4,%esp
f01044cc:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01044cf:	50                   	push   %eax
f01044d0:	ff 75 10             	pushl  0x10(%ebp)
f01044d3:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01044d6:	ff 70 60             	pushl  0x60(%eax)
f01044d9:	e8 4a cd ff ff       	call   f0101228 <page_lookup>
	if (!srcPage) 
f01044de:	83 c4 10             	add    $0x10,%esp
f01044e1:	85 c0                	test   %eax,%eax
f01044e3:	74 4f                	je     f0104534 <syscall+0x2b4>
		return -E_INVAL;
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f01044e5:	f7 45 1c fd f1 ff ff 	testl  $0xfffff1fd,0x1c(%ebp)
f01044ec:	74 50                	je     f010453e <syscall+0x2be>
		return -E_INVAL; 	
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
f01044ee:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01044f1:	f6 02 02             	testb  $0x2,(%edx)
f01044f4:	75 06                	jne    f01044fc <syscall+0x27c>
f01044f6:	f6 45 1c 02          	testb  $0x2,0x1c(%ebp)
f01044fa:	75 4c                	jne    f0104548 <syscall+0x2c8>
		return -E_INVAL;
	}

	// mapping
	errcode = page_insert(dst_env->env_pgdir, srcPage, dstva, perm);
f01044fc:	ff 75 1c             	pushl  0x1c(%ebp)
f01044ff:	ff 75 18             	pushl  0x18(%ebp)
f0104502:	50                   	push   %eax
f0104503:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104506:	ff 70 60             	pushl  0x60(%eax)
f0104509:	e8 e0 cd ff ff       	call   f01012ee <page_insert>
f010450e:	83 c4 10             	add    $0x10,%esp
f0104511:	85 c0                	test   %eax,%eax
f0104513:	ba 00 00 00 00       	mov    $0x0,%edx
f0104518:	0f 4f c2             	cmovg  %edx,%eax
f010451b:	e9 63 02 00 00       	jmp    f0104783 <syscall+0x503>
	if (errcode < 0) 
		return errcode;
	
	//Check if the address is below UTOP
	if (((uint32_t)srcva) >= UTOP || ((uint32_t)dstva) >= UTOP) 
		return -E_INVAL;
f0104520:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104525:	e9 59 02 00 00       	jmp    f0104783 <syscall+0x503>
	
	//Checking if the address is page aligned
	if ((((uint32_t)srcva)%PGSIZE != 0) || (((uint32_t)dstva)%PGSIZE != 0)) 
		return -E_INVAL;
f010452a:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f010452f:	e9 4f 02 00 00       	jmp    f0104783 <syscall+0x503>
	// find the page corresponding to srcva in src_e
	pte_t* pte_src;

	struct PageInfo* srcPage = page_lookup(src_env->env_pgdir, srcva, &pte_src);
	if (!srcPage) 
		return -E_INVAL;
f0104534:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104539:	e9 45 02 00 00       	jmp    f0104783 <syscall+0x503>
	

	//Check for permissions
	if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
		return -E_INVAL; 	
f010453e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f0104543:	e9 3b 02 00 00       	jmp    f0104783 <syscall+0x503>
	

	// the page is not writable but write permission is set	
	if (!(*pte_src & PTE_W) && (perm & PTE_W)) {
		return -E_INVAL;
f0104548:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	case SYS_page_alloc:
		return sys_page_alloc( (envid_t)a1, (void *)a2, (int)a3);
	
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
f010454d:	e9 31 02 00 00       	jmp    f0104783 <syscall+0x503>
	// Hint: This function is a wrapper around page_remove().

	// LAB 4: Your code here.
	struct Env* en;
	//Check for valid envid
	int errcode = envid2env(envid, &en, 1);
f0104552:	83 ec 04             	sub    $0x4,%esp
f0104555:	6a 01                	push   $0x1
f0104557:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010455a:	50                   	push   %eax
f010455b:	ff 75 0c             	pushl  0xc(%ebp)
f010455e:	e8 90 ea ff ff       	call   f0102ff3 <envid2env>
	if (errcode < 0){ 
f0104563:	83 c4 10             	add    $0x10,%esp
f0104566:	85 c0                	test   %eax,%eax
f0104568:	0f 88 15 02 00 00    	js     f0104783 <syscall+0x503>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
f010456e:	81 7d 10 ff ff bf ee 	cmpl   $0xeebfffff,0x10(%ebp)
f0104575:	77 27                	ja     f010459e <syscall+0x31e>
f0104577:	f7 45 10 ff 0f 00 00 	testl  $0xfff,0x10(%ebp)
f010457e:	75 28                	jne    f01045a8 <syscall+0x328>
		return -E_INVAL;
	}

	page_remove(en->env_pgdir, va);
f0104580:	83 ec 08             	sub    $0x8,%esp
f0104583:	ff 75 10             	pushl  0x10(%ebp)
f0104586:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104589:	ff 70 60             	pushl  0x60(%eax)
f010458c:	e8 17 cd ff ff       	call   f01012a8 <page_remove>
f0104591:	83 c4 10             	add    $0x10,%esp

	return 0;
f0104594:	b8 00 00 00 00       	mov    $0x0,%eax
f0104599:	e9 e5 01 00 00       	jmp    f0104783 <syscall+0x503>
		return errcode;
	}
	
	//Checkfor valid address and page alignment
	if ((((uint32_t)va) >= UTOP) ||(((uint32_t)va)%PGSIZE != 0 ) ) {
		return -E_INVAL;
f010459e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01045a3:	e9 db 01 00 00       	jmp    f0104783 <syscall+0x503>
f01045a8:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	case SYS_page_map:
		return sys_page_map( (envid_t)a1, (void *)a2,
	     (envid_t) a3, (void *)a4, (int )a5);

	case SYS_page_unmap:
		return sys_page_unmap((envid_t)a1, (void *)a2);	
f01045ad:	e9 d1 01 00 00       	jmp    f0104783 <syscall+0x503>
static int
sys_env_set_pgfault_upcall(envid_t envid, void *func)
{
	// LAB 4: Your code here. //Exercise 8 code
	struct Env* en;
	int errcode = envid2env(envid, &en, 1);
f01045b2:	83 ec 04             	sub    $0x4,%esp
f01045b5:	6a 01                	push   $0x1
f01045b7:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f01045ba:	50                   	push   %eax
f01045bb:	ff 75 0c             	pushl  0xc(%ebp)
f01045be:	e8 30 ea ff ff       	call   f0102ff3 <envid2env>
	if (errcode < 0) {
f01045c3:	83 c4 10             	add    $0x10,%esp
f01045c6:	85 c0                	test   %eax,%eax
f01045c8:	0f 88 b5 01 00 00    	js     f0104783 <syscall+0x503>
		return errcode;
	}

	//Set the pgfault_upcall to func
	en->env_pgfault_upcall = func;
f01045ce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01045d1:	8b 7d 10             	mov    0x10(%ebp),%edi
f01045d4:	89 78 64             	mov    %edi,0x64(%eax)
	return 0;
f01045d7:	b8 00 00 00 00       	mov    $0x0,%eax
f01045dc:	e9 a2 01 00 00       	jmp    f0104783 <syscall+0x503>
	// LAB 4: Your code here.
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
f01045e1:	83 ec 04             	sub    $0x4,%esp
f01045e4:	6a 00                	push   $0x0
f01045e6:	8d 45 e0             	lea    -0x20(%ebp),%eax
f01045e9:	50                   	push   %eax
f01045ea:	ff 75 0c             	pushl  0xc(%ebp)
f01045ed:	e8 01 ea ff ff       	call   f0102ff3 <envid2env>
f01045f2:	83 c4 10             	add    $0x10,%esp
f01045f5:	85 c0                	test   %eax,%eax
f01045f7:	0f 88 0a 01 00 00    	js     f0104707 <syscall+0x487>
		return -E_BAD_ENV; 
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
f01045fd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104600:	80 78 68 00          	cmpb   $0x0,0x68(%eax)
f0104604:	0f 84 04 01 00 00    	je     f010470e <syscall+0x48e>
		return -E_IPC_NOT_RECV;
	
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
f010460a:	81 7d 14 ff ff bf ee 	cmpl   $0xeebfffff,0x14(%ebp)
f0104611:	0f 87 b0 00 00 00    	ja     f01046c7 <syscall+0x447>
f0104617:	81 78 6c ff ff bf ee 	cmpl   $0xeebfffff,0x6c(%eax)
f010461e:	0f 87 a3 00 00 00    	ja     f01046c7 <syscall+0x447>
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
			return -E_INVAL;
f0104624:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
	//If src and dst addesses are below UTOP
	if (((uint32_t)srcva) < UTOP && (uint32_t)target_env->env_ipc_dstva < UTOP)
	{
		
		//Check if srcva is page aligned
		if ((uint32_t)srcva % PGSIZE !=0)
f0104629:	f7 45 14 ff 0f 00 00 	testl  $0xfff,0x14(%ebp)
f0104630:	0f 85 4d 01 00 00    	jne    f0104783 <syscall+0x503>
			return -E_INVAL;
	
		//Check for permissions
		if (!(perm & PTE_U) && !(perm & PTE_P) && !(perm & ~(PTE_SYSCALL)))
f0104636:	f7 45 18 fd f1 ff ff 	testl  $0xfffff1fd,0x18(%ebp)
f010463d:	0f 84 40 01 00 00    	je     f0104783 <syscall+0x503>
			return -E_INVAL;

		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
f0104643:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
f010464a:	e8 f8 12 00 00       	call   f0105947 <cpunum>
f010464f:	83 ec 04             	sub    $0x4,%esp
f0104652:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0104655:	52                   	push   %edx
f0104656:	ff 75 14             	pushl  0x14(%ebp)
f0104659:	6b c0 74             	imul   $0x74,%eax,%eax
f010465c:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0104662:	ff 70 60             	pushl  0x60(%eax)
f0104665:	e8 be cb ff ff       	call   f0101228 <page_lookup>
f010466a:	89 c2                	mov    %eax,%edx
f010466c:	83 c4 10             	add    $0x10,%esp
f010466f:	85 c0                	test   %eax,%eax
f0104671:	74 40                	je     f01046b3 <syscall+0x433>
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f0104673:	f6 45 18 02          	testb  $0x2,0x18(%ebp)
f0104677:	74 11                	je     f010468a <syscall+0x40a>
			return -E_INVAL; 
f0104679:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
		
		//if (perm & PTE_W), but srcva is read-only in the
		//current environment's address space.
		if ((perm & PTE_W) && !(*pte & PTE_W))
f010467e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0104681:	f6 01 02             	testb  $0x2,(%ecx)
f0104684:	0f 84 f9 00 00 00    	je     f0104783 <syscall+0x503>
			return -E_INVAL; 
		
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
f010468a:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010468d:	8b 48 6c             	mov    0x6c(%eax),%ecx
f0104690:	85 c9                	test   %ecx,%ecx
f0104692:	74 14                	je     f01046a8 <syscall+0x428>
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
f0104694:	ff 75 18             	pushl  0x18(%ebp)
f0104697:	51                   	push   %ecx
f0104698:	52                   	push   %edx
f0104699:	ff 70 60             	pushl  0x60(%eax)
f010469c:	e8 4d cc ff ff       	call   f01012ee <page_insert>
f01046a1:	83 c4 10             	add    $0x10,%esp
f01046a4:	85 c0                	test   %eax,%eax
f01046a6:	78 15                	js     f01046bd <syscall+0x43d>
				return -E_NO_MEM;
			
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
f01046a8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046ab:	8b 75 18             	mov    0x18(%ebp),%esi
f01046ae:	89 70 78             	mov    %esi,0x78(%eax)
f01046b1:	eb 1b                	jmp    f01046ce <syscall+0x44e>
		struct PageInfo* srcpage = NULL;

		pte_t* pte = NULL;
		//Lookup the page and get a pte
		if (!(srcpage = page_lookup(curenv->env_pgdir, srcva,&pte)))
			return -E_INVAL;
f01046b3:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
f01046b8:	e9 c6 00 00 00       	jmp    f0104783 <syscall+0x503>
		//Page mappingto destination
		if (target_env->env_ipc_dstva)
		{
			//map the page
			if ((r = page_insert(target_env->env_pgdir, srcpage, (void *)target_env->env_ipc_dstva,perm) )< 0)
				return -E_NO_MEM;
f01046bd:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01046c2:	e9 bc 00 00 00       	jmp    f0104783 <syscall+0x503>
		}
		
		target_env->env_ipc_perm = perm; // is set to 'perm' if a page was transferred, 0 otherwise. 
	}
	else{
		target_env->env_ipc_perm = 0; //  0 otherwise. 
f01046c7:	c7 40 78 00 00 00 00 	movl   $0x0,0x78(%eax)
	}
	
	target_env->env_ipc_recving  = 0; //is set to 0 to block future sends
f01046ce:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01046d1:	c6 43 68 00          	movb   $0x0,0x68(%ebx)
	target_env->env_ipc_from = curenv->env_id; // is set to the sending envid;
f01046d5:	e8 6d 12 00 00       	call   f0105947 <cpunum>
f01046da:	6b c0 74             	imul   $0x74,%eax,%eax
f01046dd:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f01046e3:	8b 40 48             	mov    0x48(%eax),%eax
f01046e6:	89 43 74             	mov    %eax,0x74(%ebx)
	target_env->env_tf.tf_regs.reg_eax = 0;
f01046e9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01046ec:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)
	target_env->env_ipc_value = value; // is set to the 'value' parameter;
f01046f3:	8b 4d 10             	mov    0x10(%ebp),%ecx
f01046f6:	89 48 70             	mov    %ecx,0x70(%eax)
	target_env->env_status = ENV_RUNNABLE; 
f01046f9:	c7 40 54 02 00 00 00 	movl   $0x2,0x54(%eax)
	
	return 0;
f0104700:	b8 00 00 00 00       	mov    $0x0,%eax
f0104705:	eb 7c                	jmp    f0104783 <syscall+0x503>
	int r; 
	struct Env* target_env; 
	
	//Bad Environment
	if ((r = envid2env(envid, &target_env, 0)) < 0)
		return -E_BAD_ENV; 
f0104707:	b8 fe ff ff ff       	mov    $0xfffffffe,%eax
f010470c:	eb 75                	jmp    f0104783 <syscall+0x503>
	
	//If target is not receiving
	if(!target_env->env_ipc_recving)
		return -E_IPC_NOT_RECV;
f010470e:	b8 f9 ff ff ff       	mov    $0xfffffff9,%eax

	case SYS_env_set_pgfault_upcall:
		return sys_env_set_pgfault_upcall((envid_t) a1, (void *)a2);

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);
f0104713:	eb 6e                	jmp    f0104783 <syscall+0x503>
	//panic("sys_ipc_recv not implemented");

	//check if dstva is below UTOP
	
	
	if ((uint32_t)dstva < UTOP)
f0104715:	81 7d 0c ff ff bf ee 	cmpl   $0xeebfffff,0xc(%ebp)
f010471c:	77 1d                	ja     f010473b <syscall+0x4bb>
	{
		if ((uint32_t)dstva % PGSIZE !=0)
f010471e:	f7 45 0c ff 0f 00 00 	testl  $0xfff,0xc(%ebp)
f0104725:	75 57                	jne    f010477e <syscall+0x4fe>
			return -E_INVAL;
		curenv->env_ipc_dstva = dstva;
f0104727:	e8 1b 12 00 00       	call   f0105947 <cpunum>
f010472c:	6b c0 74             	imul   $0x74,%eax,%eax
f010472f:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0104735:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104738:	89 70 6c             	mov    %esi,0x6c(%eax)
	}
	
	//Enable receiving
	curenv->env_ipc_recving = 1;
f010473b:	e8 07 12 00 00       	call   f0105947 <cpunum>
f0104740:	6b c0 74             	imul   $0x74,%eax,%eax
f0104743:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f0104749:	c6 40 68 01          	movb   $0x1,0x68(%eax)
	curenv->env_status = ENV_NOT_RUNNABLE;
f010474d:	e8 f5 11 00 00       	call   f0105947 <cpunum>
f0104752:	6b c0 74             	imul   $0x74,%eax,%eax
f0104755:	8b 80 48 e0 1d f0    	mov    -0xfe21fb8(%eax),%eax
f010475b:	c7 40 54 04 00 00 00 	movl   $0x4,0x54(%eax)
	sched_yield();
f0104762:	e8 39 fa ff ff       	call   f01041a0 <sched_yield>

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
		
	default:
		panic("Invalid System Call \n");
f0104767:	83 ec 04             	sub    $0x4,%esp
f010476a:	68 0b 78 10 f0       	push   $0xf010780b
f010476f:	68 21 02 00 00       	push   $0x221
f0104774:	68 21 78 10 f0       	push   $0xf0107821
f0104779:	e8 c2 b8 ff ff       	call   f0100040 <_panic>

	case SYS_ipc_try_send:
		return sys_ipc_try_send(a1,a2,(void*)a3, a4);

	case SYS_ipc_recv:
		return sys_ipc_recv((void*)a1);
f010477e:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax
		
	default:
		panic("Invalid System Call \n");
		return -E_INVAL;
	}
}
f0104783:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104786:	5b                   	pop    %ebx
f0104787:	5e                   	pop    %esi
f0104788:	5f                   	pop    %edi
f0104789:	5d                   	pop    %ebp
f010478a:	c3                   	ret    

f010478b <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f010478b:	55                   	push   %ebp
f010478c:	89 e5                	mov    %esp,%ebp
f010478e:	57                   	push   %edi
f010478f:	56                   	push   %esi
f0104790:	53                   	push   %ebx
f0104791:	83 ec 14             	sub    $0x14,%esp
f0104794:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0104797:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f010479a:	89 4d e0             	mov    %ecx,-0x20(%ebp)
f010479d:	8b 7d 08             	mov    0x8(%ebp),%edi
	int l = *region_left, r = *region_right, any_matches = 0;
f01047a0:	8b 1a                	mov    (%edx),%ebx
f01047a2:	8b 01                	mov    (%ecx),%eax
f01047a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01047a7:	c7 45 e8 00 00 00 00 	movl   $0x0,-0x18(%ebp)

	while (l <= r) {
f01047ae:	e9 88 00 00 00       	jmp    f010483b <stab_binsearch+0xb0>
		int true_m = (l + r) / 2, m = true_m;
f01047b3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01047b6:	01 d8                	add    %ebx,%eax
f01047b8:	89 c6                	mov    %eax,%esi
f01047ba:	c1 ee 1f             	shr    $0x1f,%esi
f01047bd:	01 c6                	add    %eax,%esi
f01047bf:	d1 fe                	sar    %esi
f01047c1:	8d 04 76             	lea    (%esi,%esi,2),%eax
f01047c4:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01047c7:	8d 14 81             	lea    (%ecx,%eax,4),%edx
f01047ca:	89 f0                	mov    %esi,%eax

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01047cc:	eb 03                	jmp    f01047d1 <stab_binsearch+0x46>
			m--;
f01047ce:	83 e8 01             	sub    $0x1,%eax

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01047d1:	39 c3                	cmp    %eax,%ebx
f01047d3:	7f 1f                	jg     f01047f4 <stab_binsearch+0x69>
f01047d5:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f01047d9:	83 ea 0c             	sub    $0xc,%edx
f01047dc:	39 f9                	cmp    %edi,%ecx
f01047de:	75 ee                	jne    f01047ce <stab_binsearch+0x43>
f01047e0:	89 45 e8             	mov    %eax,-0x18(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01047e3:	8d 14 40             	lea    (%eax,%eax,2),%edx
f01047e6:	8b 4d ec             	mov    -0x14(%ebp),%ecx
f01047e9:	8b 54 91 08          	mov    0x8(%ecx,%edx,4),%edx
f01047ed:	39 55 0c             	cmp    %edx,0xc(%ebp)
f01047f0:	76 18                	jbe    f010480a <stab_binsearch+0x7f>
f01047f2:	eb 05                	jmp    f01047f9 <stab_binsearch+0x6e>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01047f4:	8d 5e 01             	lea    0x1(%esi),%ebx
			continue;
f01047f7:	eb 42                	jmp    f010483b <stab_binsearch+0xb0>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01047f9:	8b 5d e4             	mov    -0x1c(%ebp),%ebx
f01047fc:	89 03                	mov    %eax,(%ebx)
			l = true_m + 1;
f01047fe:	8d 5e 01             	lea    0x1(%esi),%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104801:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104808:	eb 31                	jmp    f010483b <stab_binsearch+0xb0>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f010480a:	39 55 0c             	cmp    %edx,0xc(%ebp)
f010480d:	73 17                	jae    f0104826 <stab_binsearch+0x9b>
			*region_right = m - 1;
f010480f:	8b 45 e8             	mov    -0x18(%ebp),%eax
f0104812:	83 e8 01             	sub    $0x1,%eax
f0104815:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0104818:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010481b:	89 06                	mov    %eax,(%esi)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010481d:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
f0104824:	eb 15                	jmp    f010483b <stab_binsearch+0xb0>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0104826:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104829:	8b 5d e8             	mov    -0x18(%ebp),%ebx
f010482c:	89 1e                	mov    %ebx,(%esi)
			l = m;
			addr++;
f010482e:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
f0104832:	89 c3                	mov    %eax,%ebx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0104834:	c7 45 e8 01 00 00 00 	movl   $0x1,-0x18(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010483b:	3b 5d f0             	cmp    -0x10(%ebp),%ebx
f010483e:	0f 8e 6f ff ff ff    	jle    f01047b3 <stab_binsearch+0x28>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0104844:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
f0104848:	75 0f                	jne    f0104859 <stab_binsearch+0xce>
		*region_right = *region_left - 1;
f010484a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010484d:	8b 00                	mov    (%eax),%eax
f010484f:	83 e8 01             	sub    $0x1,%eax
f0104852:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0104855:	89 06                	mov    %eax,(%esi)
f0104857:	eb 2c                	jmp    f0104885 <stab_binsearch+0xfa>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104859:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010485c:	8b 00                	mov    (%eax),%eax
		     l > *region_left && stabs[l].n_type != type;
f010485e:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104861:	8b 0e                	mov    (%esi),%ecx
f0104863:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104866:	8b 75 ec             	mov    -0x14(%ebp),%esi
f0104869:	8d 14 96             	lea    (%esi,%edx,4),%edx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010486c:	eb 03                	jmp    f0104871 <stab_binsearch+0xe6>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010486e:	83 e8 01             	sub    $0x1,%eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0104871:	39 c8                	cmp    %ecx,%eax
f0104873:	7e 0b                	jle    f0104880 <stab_binsearch+0xf5>
		     l > *region_left && stabs[l].n_type != type;
f0104875:	0f b6 5a 04          	movzbl 0x4(%edx),%ebx
f0104879:	83 ea 0c             	sub    $0xc,%edx
f010487c:	39 fb                	cmp    %edi,%ebx
f010487e:	75 ee                	jne    f010486e <stab_binsearch+0xe3>
		     l--)
			/* do nothing */;
		*region_left = l;
f0104880:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0104883:	89 06                	mov    %eax,(%esi)
	}
}
f0104885:	83 c4 14             	add    $0x14,%esp
f0104888:	5b                   	pop    %ebx
f0104889:	5e                   	pop    %esi
f010488a:	5f                   	pop    %edi
f010488b:	5d                   	pop    %ebp
f010488c:	c3                   	ret    

f010488d <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010488d:	55                   	push   %ebp
f010488e:	89 e5                	mov    %esp,%ebp
f0104890:	57                   	push   %edi
f0104891:	56                   	push   %esi
f0104892:	53                   	push   %ebx
f0104893:	83 ec 3c             	sub    $0x3c,%esp
f0104896:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104899:	8b 75 0c             	mov    0xc(%ebp),%esi
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010489c:	c7 06 68 78 10 f0    	movl   $0xf0107868,(%esi)
	info->eip_line = 0;
f01048a2:	c7 46 04 00 00 00 00 	movl   $0x0,0x4(%esi)
	info->eip_fn_name = "<unknown>";
f01048a9:	c7 46 08 68 78 10 f0 	movl   $0xf0107868,0x8(%esi)
	info->eip_fn_namelen = 9;
f01048b0:	c7 46 0c 09 00 00 00 	movl   $0x9,0xc(%esi)
	info->eip_fn_addr = addr;
f01048b7:	89 7e 10             	mov    %edi,0x10(%esi)
	info->eip_fn_narg = 0;
f01048ba:	c7 46 14 00 00 00 00 	movl   $0x0,0x14(%esi)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01048c1:	81 ff ff ff 7f ef    	cmp    $0xef7fffff,%edi
f01048c7:	0f 87 a4 00 00 00    	ja     f0104971 <debuginfo_eip+0xe4>
		const struct UserStabData *usd = (const struct UserStabData *) USTABDATA;

		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
f01048cd:	e8 75 10 00 00       	call   f0105947 <cpunum>
f01048d2:	6a 05                	push   $0x5
f01048d4:	6a 10                	push   $0x10
f01048d6:	68 00 00 20 00       	push   $0x200000
f01048db:	6b c0 74             	imul   $0x74,%eax,%eax
f01048de:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f01048e4:	e8 46 e5 ff ff       	call   f0102e2f <user_mem_check>
f01048e9:	83 c4 10             	add    $0x10,%esp
f01048ec:	85 c0                	test   %eax,%eax
f01048ee:	0f 88 24 02 00 00    	js     f0104b18 <debuginfo_eip+0x28b>
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
		}
		stabs = usd->stabs;
f01048f4:	a1 00 00 20 00       	mov    0x200000,%eax
		stab_end = usd->stab_end;
f01048f9:	8b 1d 04 00 20 00    	mov    0x200004,%ebx
		stabstr = usd->stabstr;
f01048ff:	8b 0d 08 00 20 00    	mov    0x200008,%ecx
f0104905:	89 4d c0             	mov    %ecx,-0x40(%ebp)
		stabstr_end = usd->stabstr_end;
f0104908:	8b 15 0c 00 20 00    	mov    0x20000c,%edx
f010490e:	89 55 bc             	mov    %edx,-0x44(%ebp)

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
f0104911:	89 d9                	mov    %ebx,%ecx
f0104913:	89 45 c4             	mov    %eax,-0x3c(%ebp)
f0104916:	29 c1                	sub    %eax,%ecx
f0104918:	89 4d b8             	mov    %ecx,-0x48(%ebp)
f010491b:	e8 27 10 00 00       	call   f0105947 <cpunum>
f0104920:	6a 05                	push   $0x5
f0104922:	ff 75 b8             	pushl  -0x48(%ebp)
f0104925:	ff 75 c4             	pushl  -0x3c(%ebp)
f0104928:	6b c0 74             	imul   $0x74,%eax,%eax
f010492b:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0104931:	e8 f9 e4 ff ff       	call   f0102e2f <user_mem_check>
f0104936:	83 c4 10             	add    $0x10,%esp
f0104939:	85 c0                	test   %eax,%eax
f010493b:	0f 88 de 01 00 00    	js     f0104b1f <debuginfo_eip+0x292>
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
		}

		if (user_mem_check(curenv, (const void *)stabstr,
f0104941:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104944:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104947:	89 55 b8             	mov    %edx,-0x48(%ebp)
f010494a:	e8 f8 0f 00 00       	call   f0105947 <cpunum>
f010494f:	6a 05                	push   $0x5
f0104951:	ff 75 b8             	pushl  -0x48(%ebp)
f0104954:	ff 75 c0             	pushl  -0x40(%ebp)
f0104957:	6b c0 74             	imul   $0x74,%eax,%eax
f010495a:	ff b0 48 e0 1d f0    	pushl  -0xfe21fb8(%eax)
f0104960:	e8 ca e4 ff ff       	call   f0102e2f <user_mem_check>
f0104965:	83 c4 10             	add    $0x10,%esp
f0104968:	85 c0                	test   %eax,%eax
f010496a:	79 1f                	jns    f010498b <debuginfo_eip+0xfe>
f010496c:	e9 b5 01 00 00       	jmp    f0104b26 <debuginfo_eip+0x299>
	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
f0104971:	c7 45 bc a0 5d 11 f0 	movl   $0xf0115da0,-0x44(%ebp)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
f0104978:	c7 45 c0 25 26 11 f0 	movl   $0xf0112625,-0x40(%ebp)
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
		stab_end = __STAB_END__;
f010497f:	bb 24 26 11 f0       	mov    $0xf0112624,%ebx
	info->eip_fn_addr = addr;
	info->eip_fn_narg = 0;

	// Find the relevant set of stabs
	if (addr >= ULIM) {
		stabs = __STAB_BEGIN__;
f0104984:	c7 45 c4 30 7e 10 f0 	movl   $0xf0107e30,-0x3c(%ebp)
			return -1;
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010498b:	8b 45 bc             	mov    -0x44(%ebp),%eax
f010498e:	39 45 c0             	cmp    %eax,-0x40(%ebp)
f0104991:	0f 83 96 01 00 00    	jae    f0104b2d <debuginfo_eip+0x2a0>
f0104997:	80 78 ff 00          	cmpb   $0x0,-0x1(%eax)
f010499b:	0f 85 93 01 00 00    	jne    f0104b34 <debuginfo_eip+0x2a7>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01049a1:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01049a8:	89 d8                	mov    %ebx,%eax
f01049aa:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f01049ad:	29 d8                	sub    %ebx,%eax
f01049af:	c1 f8 02             	sar    $0x2,%eax
f01049b2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01049b8:	83 e8 01             	sub    $0x1,%eax
f01049bb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01049be:	83 ec 08             	sub    $0x8,%esp
f01049c1:	57                   	push   %edi
f01049c2:	6a 64                	push   $0x64
f01049c4:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01049c7:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01049ca:	89 d8                	mov    %ebx,%eax
f01049cc:	e8 ba fd ff ff       	call   f010478b <stab_binsearch>
	if (lfile == 0)
f01049d1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01049d4:	83 c4 10             	add    $0x10,%esp
f01049d7:	85 c0                	test   %eax,%eax
f01049d9:	0f 84 5c 01 00 00    	je     f0104b3b <debuginfo_eip+0x2ae>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01049df:	89 45 dc             	mov    %eax,-0x24(%ebp)
	rfun = rfile;
f01049e2:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01049e5:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01049e8:	83 ec 08             	sub    $0x8,%esp
f01049eb:	57                   	push   %edi
f01049ec:	6a 24                	push   $0x24
f01049ee:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01049f1:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01049f4:	89 d8                	mov    %ebx,%eax
f01049f6:	e8 90 fd ff ff       	call   f010478b <stab_binsearch>

	if (lfun <= rfun) {
f01049fb:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01049fe:	8b 5d d8             	mov    -0x28(%ebp),%ebx
f0104a01:	83 c4 10             	add    $0x10,%esp
f0104a04:	39 d8                	cmp    %ebx,%eax
f0104a06:	7f 32                	jg     f0104a3a <debuginfo_eip+0x1ad>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0104a08:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104a0b:	8b 4d c4             	mov    -0x3c(%ebp),%ecx
f0104a0e:	8d 0c 91             	lea    (%ecx,%edx,4),%ecx
f0104a11:	8b 11                	mov    (%ecx),%edx
f0104a13:	89 55 b8             	mov    %edx,-0x48(%ebp)
f0104a16:	8b 55 bc             	mov    -0x44(%ebp),%edx
f0104a19:	2b 55 c0             	sub    -0x40(%ebp),%edx
f0104a1c:	39 55 b8             	cmp    %edx,-0x48(%ebp)
f0104a1f:	73 09                	jae    f0104a2a <debuginfo_eip+0x19d>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0104a21:	8b 55 b8             	mov    -0x48(%ebp),%edx
f0104a24:	03 55 c0             	add    -0x40(%ebp),%edx
f0104a27:	89 56 08             	mov    %edx,0x8(%esi)
		info->eip_fn_addr = stabs[lfun].n_value;
f0104a2a:	8b 51 08             	mov    0x8(%ecx),%edx
f0104a2d:	89 56 10             	mov    %edx,0x10(%esi)
		addr -= info->eip_fn_addr;
f0104a30:	29 d7                	sub    %edx,%edi
		// Search within the function definition for the line number.
		lline = lfun;
f0104a32:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0104a35:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0104a38:	eb 0f                	jmp    f0104a49 <debuginfo_eip+0x1bc>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0104a3a:	89 7e 10             	mov    %edi,0x10(%esi)
		lline = lfile;
f0104a3d:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0104a40:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0104a43:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104a46:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0104a49:	83 ec 08             	sub    $0x8,%esp
f0104a4c:	6a 3a                	push   $0x3a
f0104a4e:	ff 76 08             	pushl  0x8(%esi)
f0104a51:	e8 b1 08 00 00       	call   f0105307 <strfind>
f0104a56:	2b 46 08             	sub    0x8(%esi),%eax
f0104a59:	89 46 0c             	mov    %eax,0xc(%esi)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
f0104a5c:	83 c4 08             	add    $0x8,%esp
f0104a5f:	57                   	push   %edi
f0104a60:	6a 44                	push   $0x44
f0104a62:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0104a65:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0104a68:	8b 5d c4             	mov    -0x3c(%ebp),%ebx
f0104a6b:	89 d8                	mov    %ebx,%eax
f0104a6d:	e8 19 fd ff ff       	call   f010478b <stab_binsearch>
	if (lline > rline) {
f0104a72:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104a75:	83 c4 10             	add    $0x10,%esp
f0104a78:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0104a7b:	0f 8f c1 00 00 00    	jg     f0104b42 <debuginfo_eip+0x2b5>
		return -1; //Did not find the line number in the stab
	}
	info->eip_line = stabs[lline].n_desc; //If found update the info object with the correct line number
f0104a81:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104a84:	0f b7 44 83 06       	movzwl 0x6(%ebx,%eax,4),%eax
f0104a89:	89 46 04             	mov    %eax,0x4(%esi)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0104a8c:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104a8f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0104a92:	8d 14 40             	lea    (%eax,%eax,2),%edx
f0104a95:	8d 14 93             	lea    (%ebx,%edx,4),%edx
f0104a98:	89 75 0c             	mov    %esi,0xc(%ebp)
f0104a9b:	eb 06                	jmp    f0104aa3 <debuginfo_eip+0x216>
f0104a9d:	83 e8 01             	sub    $0x1,%eax
f0104aa0:	83 ea 0c             	sub    $0xc,%edx
f0104aa3:	39 c7                	cmp    %eax,%edi
f0104aa5:	7f 2a                	jg     f0104ad1 <debuginfo_eip+0x244>
	       && stabs[lline].n_type != N_SOL
f0104aa7:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104aab:	80 f9 84             	cmp    $0x84,%cl
f0104aae:	0f 84 9c 00 00 00    	je     f0104b50 <debuginfo_eip+0x2c3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0104ab4:	80 f9 64             	cmp    $0x64,%cl
f0104ab7:	75 e4                	jne    f0104a9d <debuginfo_eip+0x210>
f0104ab9:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0104abd:	74 de                	je     f0104a9d <debuginfo_eip+0x210>
f0104abf:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104ac2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0104ac5:	e9 8c 00 00 00       	jmp    f0104b56 <debuginfo_eip+0x2c9>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
		info->eip_file = stabstr + stabs[lline].n_strx;
f0104aca:	03 55 c0             	add    -0x40(%ebp),%edx
f0104acd:	89 16                	mov    %edx,(%esi)
f0104acf:	eb 03                	jmp    f0104ad4 <debuginfo_eip+0x247>
f0104ad1:	8b 75 0c             	mov    0xc(%ebp),%esi


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104ad4:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104ad7:	8b 5d d8             	mov    -0x28(%ebp),%ebx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104ada:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0104adf:	39 da                	cmp    %ebx,%edx
f0104ae1:	0f 8d 8b 00 00 00    	jge    f0104b72 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
f0104ae7:	83 c2 01             	add    $0x1,%edx
f0104aea:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0104aed:	89 d0                	mov    %edx,%eax
f0104aef:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0104af2:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104af5:	8d 14 97             	lea    (%edi,%edx,4),%edx
f0104af8:	eb 04                	jmp    f0104afe <debuginfo_eip+0x271>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;
f0104afa:	83 46 14 01          	addl   $0x1,0x14(%esi)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0104afe:	39 c3                	cmp    %eax,%ebx
f0104b00:	7e 47                	jle    f0104b49 <debuginfo_eip+0x2bc>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0104b02:	0f b6 4a 04          	movzbl 0x4(%edx),%ecx
f0104b06:	83 c0 01             	add    $0x1,%eax
f0104b09:	83 c2 0c             	add    $0xc,%edx
f0104b0c:	80 f9 a0             	cmp    $0xa0,%cl
f0104b0f:	74 e9                	je     f0104afa <debuginfo_eip+0x26d>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104b11:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b16:	eb 5a                	jmp    f0104b72 <debuginfo_eip+0x2e5>
		// Make sure this memory is valid.
		// Return -1 if it is not.  Hint: Call user_mem_check.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)usd,
				sizeof(struct UserStabData), PTE_U | PTE_P) < 0) {
			return -1;
f0104b18:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b1d:	eb 53                	jmp    f0104b72 <debuginfo_eip+0x2e5>

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv, (const void *)stabs,
				(uintptr_t)stab_end  - (uintptr_t)stabs, PTE_U | PTE_P) < 0) {
			return -1;
f0104b1f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b24:	eb 4c                	jmp    f0104b72 <debuginfo_eip+0x2e5>
		}

		if (user_mem_check(curenv, (const void *)stabstr,
				(uintptr_t)stabstr_end - (uintptr_t)stabstr, PTE_U | PTE_P) < 0) {
			return -1;
f0104b26:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b2b:	eb 45                	jmp    f0104b72 <debuginfo_eip+0x2e5>
		}
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0104b2d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b32:	eb 3e                	jmp    f0104b72 <debuginfo_eip+0x2e5>
f0104b34:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b39:	eb 37                	jmp    f0104b72 <debuginfo_eip+0x2e5>
	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
		return -1;
f0104b3b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b40:	eb 30                	jmp    f0104b72 <debuginfo_eip+0x2e5>
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr); // text segment line number
	if (lline > rline) {
		return -1; //Did not find the line number in the stab
f0104b42:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0104b47:	eb 29                	jmp    f0104b72 <debuginfo_eip+0x2e5>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0104b49:	b8 00 00 00 00       	mov    $0x0,%eax
f0104b4e:	eb 22                	jmp    f0104b72 <debuginfo_eip+0x2e5>
f0104b50:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104b53:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
	       && stabs[lline].n_type != N_SOL
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0104b56:	8d 04 40             	lea    (%eax,%eax,2),%eax
f0104b59:	8b 7d c4             	mov    -0x3c(%ebp),%edi
f0104b5c:	8b 14 87             	mov    (%edi,%eax,4),%edx
f0104b5f:	8b 45 bc             	mov    -0x44(%ebp),%eax
f0104b62:	2b 45 c0             	sub    -0x40(%ebp),%eax
f0104b65:	39 c2                	cmp    %eax,%edx
f0104b67:	0f 82 5d ff ff ff    	jb     f0104aca <debuginfo_eip+0x23d>
f0104b6d:	e9 62 ff ff ff       	jmp    f0104ad4 <debuginfo_eip+0x247>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
}
f0104b72:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104b75:	5b                   	pop    %ebx
f0104b76:	5e                   	pop    %esi
f0104b77:	5f                   	pop    %edi
f0104b78:	5d                   	pop    %ebp
f0104b79:	c3                   	ret    

f0104b7a <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0104b7a:	55                   	push   %ebp
f0104b7b:	89 e5                	mov    %esp,%ebp
f0104b7d:	57                   	push   %edi
f0104b7e:	56                   	push   %esi
f0104b7f:	53                   	push   %ebx
f0104b80:	83 ec 1c             	sub    $0x1c,%esp
f0104b83:	89 c7                	mov    %eax,%edi
f0104b85:	89 d6                	mov    %edx,%esi
f0104b87:	8b 45 08             	mov    0x8(%ebp),%eax
f0104b8a:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104b8d:	89 d1                	mov    %edx,%ecx
f0104b8f:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104b92:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104b95:	8b 45 10             	mov    0x10(%ebp),%eax
f0104b98:	8b 5d 14             	mov    0x14(%ebp),%ebx
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0104b9b:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104b9e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0104ba5:	39 4d e4             	cmp    %ecx,-0x1c(%ebp)
f0104ba8:	72 05                	jb     f0104baf <printnum+0x35>
f0104baa:	3b 45 d8             	cmp    -0x28(%ebp),%eax
f0104bad:	77 3e                	ja     f0104bed <printnum+0x73>
		printnum(putch, putdat, num / base, base, width - 1, padc);
f0104baf:	83 ec 0c             	sub    $0xc,%esp
f0104bb2:	ff 75 18             	pushl  0x18(%ebp)
f0104bb5:	83 eb 01             	sub    $0x1,%ebx
f0104bb8:	53                   	push   %ebx
f0104bb9:	50                   	push   %eax
f0104bba:	83 ec 08             	sub    $0x8,%esp
f0104bbd:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104bc0:	ff 75 e0             	pushl  -0x20(%ebp)
f0104bc3:	ff 75 dc             	pushl  -0x24(%ebp)
f0104bc6:	ff 75 d8             	pushl  -0x28(%ebp)
f0104bc9:	e8 72 11 00 00       	call   f0105d40 <__udivdi3>
f0104bce:	83 c4 18             	add    $0x18,%esp
f0104bd1:	52                   	push   %edx
f0104bd2:	50                   	push   %eax
f0104bd3:	89 f2                	mov    %esi,%edx
f0104bd5:	89 f8                	mov    %edi,%eax
f0104bd7:	e8 9e ff ff ff       	call   f0104b7a <printnum>
f0104bdc:	83 c4 20             	add    $0x20,%esp
f0104bdf:	eb 13                	jmp    f0104bf4 <printnum+0x7a>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f0104be1:	83 ec 08             	sub    $0x8,%esp
f0104be4:	56                   	push   %esi
f0104be5:	ff 75 18             	pushl  0x18(%ebp)
f0104be8:	ff d7                	call   *%edi
f0104bea:	83 c4 10             	add    $0x10,%esp
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0104bed:	83 eb 01             	sub    $0x1,%ebx
f0104bf0:	85 db                	test   %ebx,%ebx
f0104bf2:	7f ed                	jg     f0104be1 <printnum+0x67>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0104bf4:	83 ec 08             	sub    $0x8,%esp
f0104bf7:	56                   	push   %esi
f0104bf8:	83 ec 04             	sub    $0x4,%esp
f0104bfb:	ff 75 e4             	pushl  -0x1c(%ebp)
f0104bfe:	ff 75 e0             	pushl  -0x20(%ebp)
f0104c01:	ff 75 dc             	pushl  -0x24(%ebp)
f0104c04:	ff 75 d8             	pushl  -0x28(%ebp)
f0104c07:	e8 64 12 00 00       	call   f0105e70 <__umoddi3>
f0104c0c:	83 c4 14             	add    $0x14,%esp
f0104c0f:	0f be 80 72 78 10 f0 	movsbl -0xfef878e(%eax),%eax
f0104c16:	50                   	push   %eax
f0104c17:	ff d7                	call   *%edi
f0104c19:	83 c4 10             	add    $0x10,%esp
}
f0104c1c:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0104c1f:	5b                   	pop    %ebx
f0104c20:	5e                   	pop    %esi
f0104c21:	5f                   	pop    %edi
f0104c22:	5d                   	pop    %ebp
f0104c23:	c3                   	ret    

f0104c24 <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f0104c24:	55                   	push   %ebp
f0104c25:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f0104c27:	83 fa 01             	cmp    $0x1,%edx
f0104c2a:	7e 0e                	jle    f0104c3a <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0104c2c:	8b 10                	mov    (%eax),%edx
f0104c2e:	8d 4a 08             	lea    0x8(%edx),%ecx
f0104c31:	89 08                	mov    %ecx,(%eax)
f0104c33:	8b 02                	mov    (%edx),%eax
f0104c35:	8b 52 04             	mov    0x4(%edx),%edx
f0104c38:	eb 22                	jmp    f0104c5c <getuint+0x38>
	else if (lflag)
f0104c3a:	85 d2                	test   %edx,%edx
f0104c3c:	74 10                	je     f0104c4e <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0104c3e:	8b 10                	mov    (%eax),%edx
f0104c40:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104c43:	89 08                	mov    %ecx,(%eax)
f0104c45:	8b 02                	mov    (%edx),%eax
f0104c47:	ba 00 00 00 00       	mov    $0x0,%edx
f0104c4c:	eb 0e                	jmp    f0104c5c <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0104c4e:	8b 10                	mov    (%eax),%edx
f0104c50:	8d 4a 04             	lea    0x4(%edx),%ecx
f0104c53:	89 08                	mov    %ecx,(%eax)
f0104c55:	8b 02                	mov    (%edx),%eax
f0104c57:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0104c5c:	5d                   	pop    %ebp
f0104c5d:	c3                   	ret    

f0104c5e <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0104c5e:	55                   	push   %ebp
f0104c5f:	89 e5                	mov    %esp,%ebp
f0104c61:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0104c64:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0104c68:	8b 10                	mov    (%eax),%edx
f0104c6a:	3b 50 04             	cmp    0x4(%eax),%edx
f0104c6d:	73 0a                	jae    f0104c79 <sprintputch+0x1b>
		*b->buf++ = ch;
f0104c6f:	8d 4a 01             	lea    0x1(%edx),%ecx
f0104c72:	89 08                	mov    %ecx,(%eax)
f0104c74:	8b 45 08             	mov    0x8(%ebp),%eax
f0104c77:	88 02                	mov    %al,(%edx)
}
f0104c79:	5d                   	pop    %ebp
f0104c7a:	c3                   	ret    

f0104c7b <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0104c7b:	55                   	push   %ebp
f0104c7c:	89 e5                	mov    %esp,%ebp
f0104c7e:	83 ec 08             	sub    $0x8,%esp
	va_list ap;

	va_start(ap, fmt);
f0104c81:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0104c84:	50                   	push   %eax
f0104c85:	ff 75 10             	pushl  0x10(%ebp)
f0104c88:	ff 75 0c             	pushl  0xc(%ebp)
f0104c8b:	ff 75 08             	pushl  0x8(%ebp)
f0104c8e:	e8 05 00 00 00       	call   f0104c98 <vprintfmt>
	va_end(ap);
f0104c93:	83 c4 10             	add    $0x10,%esp
}
f0104c96:	c9                   	leave  
f0104c97:	c3                   	ret    

f0104c98 <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0104c98:	55                   	push   %ebp
f0104c99:	89 e5                	mov    %esp,%ebp
f0104c9b:	57                   	push   %edi
f0104c9c:	56                   	push   %esi
f0104c9d:	53                   	push   %ebx
f0104c9e:	83 ec 2c             	sub    $0x2c,%esp
f0104ca1:	8b 75 08             	mov    0x8(%ebp),%esi
f0104ca4:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104ca7:	8b 7d 10             	mov    0x10(%ebp),%edi
f0104caa:	eb 12                	jmp    f0104cbe <vprintfmt+0x26>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0104cac:	85 c0                	test   %eax,%eax
f0104cae:	0f 84 90 03 00 00    	je     f0105044 <vprintfmt+0x3ac>
				return;
			putch(ch, putdat);
f0104cb4:	83 ec 08             	sub    $0x8,%esp
f0104cb7:	53                   	push   %ebx
f0104cb8:	50                   	push   %eax
f0104cb9:	ff d6                	call   *%esi
f0104cbb:	83 c4 10             	add    $0x10,%esp
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0104cbe:	83 c7 01             	add    $0x1,%edi
f0104cc1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104cc5:	83 f8 25             	cmp    $0x25,%eax
f0104cc8:	75 e2                	jne    f0104cac <vprintfmt+0x14>
f0104cca:	c6 45 d4 20          	movb   $0x20,-0x2c(%ebp)
f0104cce:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)
f0104cd5:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104cdc:	c7 45 e0 ff ff ff ff 	movl   $0xffffffff,-0x20(%ebp)
f0104ce3:	ba 00 00 00 00       	mov    $0x0,%edx
f0104ce8:	eb 07                	jmp    f0104cf1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cea:	8b 7d e4             	mov    -0x1c(%ebp),%edi

		// flag to pad on the right
		case '-':
			padc = '-';
f0104ced:	c6 45 d4 2d          	movb   $0x2d,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104cf1:	8d 47 01             	lea    0x1(%edi),%eax
f0104cf4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0104cf7:	0f b6 07             	movzbl (%edi),%eax
f0104cfa:	0f b6 c8             	movzbl %al,%ecx
f0104cfd:	83 e8 23             	sub    $0x23,%eax
f0104d00:	3c 55                	cmp    $0x55,%al
f0104d02:	0f 87 21 03 00 00    	ja     f0105029 <vprintfmt+0x391>
f0104d08:	0f b6 c0             	movzbl %al,%eax
f0104d0b:	ff 24 85 c0 79 10 f0 	jmp    *-0xfef8640(,%eax,4)
f0104d12:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0104d15:	c6 45 d4 30          	movb   $0x30,-0x2c(%ebp)
f0104d19:	eb d6                	jmp    f0104cf1 <vprintfmt+0x59>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104d1e:	b8 00 00 00 00       	mov    $0x0,%eax
f0104d23:	89 55 e4             	mov    %edx,-0x1c(%ebp)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0104d26:	8d 04 80             	lea    (%eax,%eax,4),%eax
f0104d29:	8d 44 41 d0          	lea    -0x30(%ecx,%eax,2),%eax
				ch = *fmt;
f0104d2d:	0f be 0f             	movsbl (%edi),%ecx
				if (ch < '0' || ch > '9')
f0104d30:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0104d33:	83 fa 09             	cmp    $0x9,%edx
f0104d36:	77 39                	ja     f0104d71 <vprintfmt+0xd9>
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0104d38:	83 c7 01             	add    $0x1,%edi
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
					break;
			}
f0104d3b:	eb e9                	jmp    f0104d26 <vprintfmt+0x8e>
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0104d3d:	8b 45 14             	mov    0x14(%ebp),%eax
f0104d40:	8d 48 04             	lea    0x4(%eax),%ecx
f0104d43:	89 4d 14             	mov    %ecx,0x14(%ebp)
f0104d46:	8b 00                	mov    (%eax),%eax
f0104d48:	89 45 d0             	mov    %eax,-0x30(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d4b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0104d4e:	eb 27                	jmp    f0104d77 <vprintfmt+0xdf>
f0104d50:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104d53:	85 c0                	test   %eax,%eax
f0104d55:	b9 00 00 00 00       	mov    $0x0,%ecx
f0104d5a:	0f 49 c8             	cmovns %eax,%ecx
f0104d5d:	89 4d e0             	mov    %ecx,-0x20(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d60:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104d63:	eb 8c                	jmp    f0104cf1 <vprintfmt+0x59>
f0104d65:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0104d68:	c7 45 d8 01 00 00 00 	movl   $0x1,-0x28(%ebp)
			goto reswitch;
f0104d6f:	eb 80                	jmp    f0104cf1 <vprintfmt+0x59>
f0104d71:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0104d74:	89 45 d0             	mov    %eax,-0x30(%ebp)

		process_precision:
			if (width < 0)
f0104d77:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
f0104d7b:	0f 89 70 ff ff ff    	jns    f0104cf1 <vprintfmt+0x59>
				width = precision, precision = -1;
f0104d81:	8b 45 d0             	mov    -0x30(%ebp),%eax
f0104d84:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104d87:	c7 45 d0 ff ff ff ff 	movl   $0xffffffff,-0x30(%ebp)
f0104d8e:	e9 5e ff ff ff       	jmp    f0104cf1 <vprintfmt+0x59>
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0104d93:	83 c2 01             	add    $0x1,%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104d96:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0104d99:	e9 53 ff ff ff       	jmp    f0104cf1 <vprintfmt+0x59>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0104d9e:	8b 45 14             	mov    0x14(%ebp),%eax
f0104da1:	8d 50 04             	lea    0x4(%eax),%edx
f0104da4:	89 55 14             	mov    %edx,0x14(%ebp)
f0104da7:	83 ec 08             	sub    $0x8,%esp
f0104daa:	53                   	push   %ebx
f0104dab:	ff 30                	pushl  (%eax)
f0104dad:	ff d6                	call   *%esi
			break;
f0104daf:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104db2:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0104db5:	e9 04 ff ff ff       	jmp    f0104cbe <vprintfmt+0x26>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0104dba:	8b 45 14             	mov    0x14(%ebp),%eax
f0104dbd:	8d 50 04             	lea    0x4(%eax),%edx
f0104dc0:	89 55 14             	mov    %edx,0x14(%ebp)
f0104dc3:	8b 00                	mov    (%eax),%eax
f0104dc5:	99                   	cltd   
f0104dc6:	31 d0                	xor    %edx,%eax
f0104dc8:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0104dca:	83 f8 0f             	cmp    $0xf,%eax
f0104dcd:	7f 0b                	jg     f0104dda <vprintfmt+0x142>
f0104dcf:	8b 14 85 40 7b 10 f0 	mov    -0xfef84c0(,%eax,4),%edx
f0104dd6:	85 d2                	test   %edx,%edx
f0104dd8:	75 18                	jne    f0104df2 <vprintfmt+0x15a>
				printfmt(putch, putdat, "error %d", err);
f0104dda:	50                   	push   %eax
f0104ddb:	68 8a 78 10 f0       	push   $0xf010788a
f0104de0:	53                   	push   %ebx
f0104de1:	56                   	push   %esi
f0104de2:	e8 94 fe ff ff       	call   f0104c7b <printfmt>
f0104de7:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104dea:	8b 7d e4             	mov    -0x1c(%ebp),%edi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0104ded:	e9 cc fe ff ff       	jmp    f0104cbe <vprintfmt+0x26>
			else
				printfmt(putch, putdat, "%s", p);
f0104df2:	52                   	push   %edx
f0104df3:	68 ed 6f 10 f0       	push   $0xf0106fed
f0104df8:	53                   	push   %ebx
f0104df9:	56                   	push   %esi
f0104dfa:	e8 7c fe ff ff       	call   f0104c7b <printfmt>
f0104dff:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104e02:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104e05:	e9 b4 fe ff ff       	jmp    f0104cbe <vprintfmt+0x26>
f0104e0a:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0104e0d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0104e10:	89 45 cc             	mov    %eax,-0x34(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0104e13:	8b 45 14             	mov    0x14(%ebp),%eax
f0104e16:	8d 50 04             	lea    0x4(%eax),%edx
f0104e19:	89 55 14             	mov    %edx,0x14(%ebp)
f0104e1c:	8b 38                	mov    (%eax),%edi
				p = "(null)";
f0104e1e:	85 ff                	test   %edi,%edi
f0104e20:	ba 83 78 10 f0       	mov    $0xf0107883,%edx
f0104e25:	0f 44 fa             	cmove  %edx,%edi
			if (width > 0 && padc != '-')
f0104e28:	80 7d d4 2d          	cmpb   $0x2d,-0x2c(%ebp)
f0104e2c:	0f 84 92 00 00 00    	je     f0104ec4 <vprintfmt+0x22c>
f0104e32:	83 7d cc 00          	cmpl   $0x0,-0x34(%ebp)
f0104e36:	0f 8e 96 00 00 00    	jle    f0104ed2 <vprintfmt+0x23a>
				for (width -= strnlen(p, precision); width > 0; width--)
f0104e3c:	83 ec 08             	sub    $0x8,%esp
f0104e3f:	51                   	push   %ecx
f0104e40:	57                   	push   %edi
f0104e41:	e8 77 03 00 00       	call   f01051bd <strnlen>
f0104e46:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104e49:	29 c1                	sub    %eax,%ecx
f0104e4b:	89 4d cc             	mov    %ecx,-0x34(%ebp)
f0104e4e:	83 c4 10             	add    $0x10,%esp
					putch(padc, putdat);
f0104e51:	0f be 45 d4          	movsbl -0x2c(%ebp),%eax
f0104e55:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0104e58:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0104e5b:	89 cf                	mov    %ecx,%edi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104e5d:	eb 0f                	jmp    f0104e6e <vprintfmt+0x1d6>
					putch(padc, putdat);
f0104e5f:	83 ec 08             	sub    $0x8,%esp
f0104e62:	53                   	push   %ebx
f0104e63:	ff 75 e0             	pushl  -0x20(%ebp)
f0104e66:	ff d6                	call   *%esi
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0104e68:	83 ef 01             	sub    $0x1,%edi
f0104e6b:	83 c4 10             	add    $0x10,%esp
f0104e6e:	85 ff                	test   %edi,%edi
f0104e70:	7f ed                	jg     f0104e5f <vprintfmt+0x1c7>
f0104e72:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0104e75:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0104e78:	85 c9                	test   %ecx,%ecx
f0104e7a:	b8 00 00 00 00       	mov    $0x0,%eax
f0104e7f:	0f 49 c1             	cmovns %ecx,%eax
f0104e82:	29 c1                	sub    %eax,%ecx
f0104e84:	89 75 08             	mov    %esi,0x8(%ebp)
f0104e87:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104e8a:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104e8d:	89 cb                	mov    %ecx,%ebx
f0104e8f:	eb 4d                	jmp    f0104ede <vprintfmt+0x246>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0104e91:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
f0104e95:	74 1b                	je     f0104eb2 <vprintfmt+0x21a>
f0104e97:	0f be c0             	movsbl %al,%eax
f0104e9a:	83 e8 20             	sub    $0x20,%eax
f0104e9d:	83 f8 5e             	cmp    $0x5e,%eax
f0104ea0:	76 10                	jbe    f0104eb2 <vprintfmt+0x21a>
					putch('?', putdat);
f0104ea2:	83 ec 08             	sub    $0x8,%esp
f0104ea5:	ff 75 0c             	pushl  0xc(%ebp)
f0104ea8:	6a 3f                	push   $0x3f
f0104eaa:	ff 55 08             	call   *0x8(%ebp)
f0104ead:	83 c4 10             	add    $0x10,%esp
f0104eb0:	eb 0d                	jmp    f0104ebf <vprintfmt+0x227>
				else
					putch(ch, putdat);
f0104eb2:	83 ec 08             	sub    $0x8,%esp
f0104eb5:	ff 75 0c             	pushl  0xc(%ebp)
f0104eb8:	52                   	push   %edx
f0104eb9:	ff 55 08             	call   *0x8(%ebp)
f0104ebc:	83 c4 10             	add    $0x10,%esp
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0104ebf:	83 eb 01             	sub    $0x1,%ebx
f0104ec2:	eb 1a                	jmp    f0104ede <vprintfmt+0x246>
f0104ec4:	89 75 08             	mov    %esi,0x8(%ebp)
f0104ec7:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104eca:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104ecd:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104ed0:	eb 0c                	jmp    f0104ede <vprintfmt+0x246>
f0104ed2:	89 75 08             	mov    %esi,0x8(%ebp)
f0104ed5:	8b 75 d0             	mov    -0x30(%ebp),%esi
f0104ed8:	89 5d 0c             	mov    %ebx,0xc(%ebp)
f0104edb:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0104ede:	83 c7 01             	add    $0x1,%edi
f0104ee1:	0f b6 47 ff          	movzbl -0x1(%edi),%eax
f0104ee5:	0f be d0             	movsbl %al,%edx
f0104ee8:	85 d2                	test   %edx,%edx
f0104eea:	74 23                	je     f0104f0f <vprintfmt+0x277>
f0104eec:	85 f6                	test   %esi,%esi
f0104eee:	78 a1                	js     f0104e91 <vprintfmt+0x1f9>
f0104ef0:	83 ee 01             	sub    $0x1,%esi
f0104ef3:	79 9c                	jns    f0104e91 <vprintfmt+0x1f9>
f0104ef5:	89 df                	mov    %ebx,%edi
f0104ef7:	8b 75 08             	mov    0x8(%ebp),%esi
f0104efa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104efd:	eb 18                	jmp    f0104f17 <vprintfmt+0x27f>
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0104eff:	83 ec 08             	sub    $0x8,%esp
f0104f02:	53                   	push   %ebx
f0104f03:	6a 20                	push   $0x20
f0104f05:	ff d6                	call   *%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0104f07:	83 ef 01             	sub    $0x1,%edi
f0104f0a:	83 c4 10             	add    $0x10,%esp
f0104f0d:	eb 08                	jmp    f0104f17 <vprintfmt+0x27f>
f0104f0f:	89 df                	mov    %ebx,%edi
f0104f11:	8b 75 08             	mov    0x8(%ebp),%esi
f0104f14:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104f17:	85 ff                	test   %edi,%edi
f0104f19:	7f e4                	jg     f0104eff <vprintfmt+0x267>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0104f1b:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0104f1e:	e9 9b fd ff ff       	jmp    f0104cbe <vprintfmt+0x26>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0104f23:	83 fa 01             	cmp    $0x1,%edx
f0104f26:	7e 16                	jle    f0104f3e <vprintfmt+0x2a6>
		return va_arg(*ap, long long);
f0104f28:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f2b:	8d 50 08             	lea    0x8(%eax),%edx
f0104f2e:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f31:	8b 50 04             	mov    0x4(%eax),%edx
f0104f34:	8b 00                	mov    (%eax),%eax
f0104f36:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104f39:	89 55 dc             	mov    %edx,-0x24(%ebp)
f0104f3c:	eb 32                	jmp    f0104f70 <vprintfmt+0x2d8>
	else if (lflag)
f0104f3e:	85 d2                	test   %edx,%edx
f0104f40:	74 18                	je     f0104f5a <vprintfmt+0x2c2>
		return va_arg(*ap, long);
f0104f42:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f45:	8d 50 04             	lea    0x4(%eax),%edx
f0104f48:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f4b:	8b 00                	mov    (%eax),%eax
f0104f4d:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104f50:	89 c1                	mov    %eax,%ecx
f0104f52:	c1 f9 1f             	sar    $0x1f,%ecx
f0104f55:	89 4d dc             	mov    %ecx,-0x24(%ebp)
f0104f58:	eb 16                	jmp    f0104f70 <vprintfmt+0x2d8>
	else
		return va_arg(*ap, int);
f0104f5a:	8b 45 14             	mov    0x14(%ebp),%eax
f0104f5d:	8d 50 04             	lea    0x4(%eax),%edx
f0104f60:	89 55 14             	mov    %edx,0x14(%ebp)
f0104f63:	8b 00                	mov    (%eax),%eax
f0104f65:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0104f68:	89 c1                	mov    %eax,%ecx
f0104f6a:	c1 f9 1f             	sar    $0x1f,%ecx
f0104f6d:	89 4d dc             	mov    %ecx,-0x24(%ebp)
				putch(' ', putdat);
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
f0104f70:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104f73:	8b 55 dc             	mov    -0x24(%ebp),%edx
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0104f76:	b9 0a 00 00 00       	mov    $0xa,%ecx
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0104f7b:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0104f7f:	79 74                	jns    f0104ff5 <vprintfmt+0x35d>
				putch('-', putdat);
f0104f81:	83 ec 08             	sub    $0x8,%esp
f0104f84:	53                   	push   %ebx
f0104f85:	6a 2d                	push   $0x2d
f0104f87:	ff d6                	call   *%esi
				num = -(long long) num;
f0104f89:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0104f8c:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0104f8f:	f7 d8                	neg    %eax
f0104f91:	83 d2 00             	adc    $0x0,%edx
f0104f94:	f7 da                	neg    %edx
f0104f96:	83 c4 10             	add    $0x10,%esp
			}
			base = 10;
f0104f99:	b9 0a 00 00 00       	mov    $0xa,%ecx
f0104f9e:	eb 55                	jmp    f0104ff5 <vprintfmt+0x35d>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0104fa0:	8d 45 14             	lea    0x14(%ebp),%eax
f0104fa3:	e8 7c fc ff ff       	call   f0104c24 <getuint>
			base = 10;
f0104fa8:	b9 0a 00 00 00       	mov    $0xa,%ecx
			goto number;
f0104fad:	eb 46                	jmp    f0104ff5 <vprintfmt+0x35d>

		// (unsigned) octal
		case 'o':
			// Replace this with your code.
			num = getuint(&ap, lflag);
f0104faf:	8d 45 14             	lea    0x14(%ebp),%eax
f0104fb2:	e8 6d fc ff ff       	call   f0104c24 <getuint>
			base = 8;
f0104fb7:	b9 08 00 00 00       	mov    $0x8,%ecx
			goto number;
f0104fbc:	eb 37                	jmp    f0104ff5 <vprintfmt+0x35d>
			break;

		// pointer
		case 'p':
			putch('0', putdat);
f0104fbe:	83 ec 08             	sub    $0x8,%esp
f0104fc1:	53                   	push   %ebx
f0104fc2:	6a 30                	push   $0x30
f0104fc4:	ff d6                	call   *%esi
			putch('x', putdat);
f0104fc6:	83 c4 08             	add    $0x8,%esp
f0104fc9:	53                   	push   %ebx
f0104fca:	6a 78                	push   $0x78
f0104fcc:	ff d6                	call   *%esi
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0104fce:	8b 45 14             	mov    0x14(%ebp),%eax
f0104fd1:	8d 50 04             	lea    0x4(%eax),%edx
f0104fd4:	89 55 14             	mov    %edx,0x14(%ebp)

		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0104fd7:	8b 00                	mov    (%eax),%eax
f0104fd9:	ba 00 00 00 00       	mov    $0x0,%edx
				(uintptr_t) va_arg(ap, void *);
			base = 16;
			goto number;
f0104fde:	83 c4 10             	add    $0x10,%esp
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0104fe1:	b9 10 00 00 00       	mov    $0x10,%ecx
			goto number;
f0104fe6:	eb 0d                	jmp    f0104ff5 <vprintfmt+0x35d>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0104fe8:	8d 45 14             	lea    0x14(%ebp),%eax
f0104feb:	e8 34 fc ff ff       	call   f0104c24 <getuint>
			base = 16;
f0104ff0:	b9 10 00 00 00       	mov    $0x10,%ecx
		number:
			printnum(putch, putdat, num, base, width, padc);
f0104ff5:	83 ec 0c             	sub    $0xc,%esp
f0104ff8:	0f be 7d d4          	movsbl -0x2c(%ebp),%edi
f0104ffc:	57                   	push   %edi
f0104ffd:	ff 75 e0             	pushl  -0x20(%ebp)
f0105000:	51                   	push   %ecx
f0105001:	52                   	push   %edx
f0105002:	50                   	push   %eax
f0105003:	89 da                	mov    %ebx,%edx
f0105005:	89 f0                	mov    %esi,%eax
f0105007:	e8 6e fb ff ff       	call   f0104b7a <printnum>
			break;
f010500c:	83 c4 20             	add    $0x20,%esp
f010500f:	8b 7d e4             	mov    -0x1c(%ebp),%edi
f0105012:	e9 a7 fc ff ff       	jmp    f0104cbe <vprintfmt+0x26>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0105017:	83 ec 08             	sub    $0x8,%esp
f010501a:	53                   	push   %ebx
f010501b:	51                   	push   %ecx
f010501c:	ff d6                	call   *%esi
			break;
f010501e:	83 c4 10             	add    $0x10,%esp
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0105021:	8b 7d e4             	mov    -0x1c(%ebp),%edi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0105024:	e9 95 fc ff ff       	jmp    f0104cbe <vprintfmt+0x26>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0105029:	83 ec 08             	sub    $0x8,%esp
f010502c:	53                   	push   %ebx
f010502d:	6a 25                	push   $0x25
f010502f:	ff d6                	call   *%esi
			for (fmt--; fmt[-1] != '%'; fmt--)
f0105031:	83 c4 10             	add    $0x10,%esp
f0105034:	eb 03                	jmp    f0105039 <vprintfmt+0x3a1>
f0105036:	83 ef 01             	sub    $0x1,%edi
f0105039:	80 7f ff 25          	cmpb   $0x25,-0x1(%edi)
f010503d:	75 f7                	jne    f0105036 <vprintfmt+0x39e>
f010503f:	e9 7a fc ff ff       	jmp    f0104cbe <vprintfmt+0x26>
				/* do nothing */;
			break;
		}
	}
}
f0105044:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105047:	5b                   	pop    %ebx
f0105048:	5e                   	pop    %esi
f0105049:	5f                   	pop    %edi
f010504a:	5d                   	pop    %ebp
f010504b:	c3                   	ret    

f010504c <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f010504c:	55                   	push   %ebp
f010504d:	89 e5                	mov    %esp,%ebp
f010504f:	83 ec 18             	sub    $0x18,%esp
f0105052:	8b 45 08             	mov    0x8(%ebp),%eax
f0105055:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0105058:	89 45 ec             	mov    %eax,-0x14(%ebp)
f010505b:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f010505f:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0105062:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0105069:	85 c0                	test   %eax,%eax
f010506b:	74 26                	je     f0105093 <vsnprintf+0x47>
f010506d:	85 d2                	test   %edx,%edx
f010506f:	7e 22                	jle    f0105093 <vsnprintf+0x47>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0105071:	ff 75 14             	pushl  0x14(%ebp)
f0105074:	ff 75 10             	pushl  0x10(%ebp)
f0105077:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010507a:	50                   	push   %eax
f010507b:	68 5e 4c 10 f0       	push   $0xf0104c5e
f0105080:	e8 13 fc ff ff       	call   f0104c98 <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0105085:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0105088:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f010508b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010508e:	83 c4 10             	add    $0x10,%esp
f0105091:	eb 05                	jmp    f0105098 <vsnprintf+0x4c>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0105093:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0105098:	c9                   	leave  
f0105099:	c3                   	ret    

f010509a <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010509a:	55                   	push   %ebp
f010509b:	89 e5                	mov    %esp,%ebp
f010509d:	83 ec 08             	sub    $0x8,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01050a0:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01050a3:	50                   	push   %eax
f01050a4:	ff 75 10             	pushl  0x10(%ebp)
f01050a7:	ff 75 0c             	pushl  0xc(%ebp)
f01050aa:	ff 75 08             	pushl  0x8(%ebp)
f01050ad:	e8 9a ff ff ff       	call   f010504c <vsnprintf>
	va_end(ap);

	return rc;
}
f01050b2:	c9                   	leave  
f01050b3:	c3                   	ret    

f01050b4 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01050b4:	55                   	push   %ebp
f01050b5:	89 e5                	mov    %esp,%ebp
f01050b7:	57                   	push   %edi
f01050b8:	56                   	push   %esi
f01050b9:	53                   	push   %ebx
f01050ba:	83 ec 0c             	sub    $0xc,%esp
f01050bd:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

#if JOS_KERNEL
	if (prompt != NULL)
f01050c0:	85 c0                	test   %eax,%eax
f01050c2:	74 11                	je     f01050d5 <readline+0x21>
		cprintf("%s", prompt);
f01050c4:	83 ec 08             	sub    $0x8,%esp
f01050c7:	50                   	push   %eax
f01050c8:	68 ed 6f 10 f0       	push   $0xf0106fed
f01050cd:	e8 3d e7 ff ff       	call   f010380f <cprintf>
f01050d2:	83 c4 10             	add    $0x10,%esp
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
	echoing = iscons(0);
f01050d5:	83 ec 0c             	sub    $0xc,%esp
f01050d8:	6a 00                	push   $0x0
f01050da:	e8 ad b6 ff ff       	call   f010078c <iscons>
f01050df:	89 c7                	mov    %eax,%edi
f01050e1:	83 c4 10             	add    $0x10,%esp
#else
	if (prompt != NULL)
		fprintf(1, "%s", prompt);
#endif

	i = 0;
f01050e4:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01050e9:	e8 8d b6 ff ff       	call   f010077b <getchar>
f01050ee:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01050f0:	85 c0                	test   %eax,%eax
f01050f2:	79 29                	jns    f010511d <readline+0x69>
			if (c != -E_EOF)
				cprintf("read error: %e\n", c);
			return NULL;
f01050f4:	b8 00 00 00 00       	mov    $0x0,%eax
	i = 0;
	echoing = iscons(0);
	while (1) {
		c = getchar();
		if (c < 0) {
			if (c != -E_EOF)
f01050f9:	83 fb f8             	cmp    $0xfffffff8,%ebx
f01050fc:	0f 84 9b 00 00 00    	je     f010519d <readline+0xe9>
				cprintf("read error: %e\n", c);
f0105102:	83 ec 08             	sub    $0x8,%esp
f0105105:	53                   	push   %ebx
f0105106:	68 9f 7b 10 f0       	push   $0xf0107b9f
f010510b:	e8 ff e6 ff ff       	call   f010380f <cprintf>
f0105110:	83 c4 10             	add    $0x10,%esp
			return NULL;
f0105113:	b8 00 00 00 00       	mov    $0x0,%eax
f0105118:	e9 80 00 00 00       	jmp    f010519d <readline+0xe9>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f010511d:	83 f8 7f             	cmp    $0x7f,%eax
f0105120:	0f 94 c2             	sete   %dl
f0105123:	83 f8 08             	cmp    $0x8,%eax
f0105126:	0f 94 c0             	sete   %al
f0105129:	08 c2                	or     %al,%dl
f010512b:	74 1a                	je     f0105147 <readline+0x93>
f010512d:	85 f6                	test   %esi,%esi
f010512f:	7e 16                	jle    f0105147 <readline+0x93>
			if (echoing)
f0105131:	85 ff                	test   %edi,%edi
f0105133:	74 0d                	je     f0105142 <readline+0x8e>
				cputchar('\b');
f0105135:	83 ec 0c             	sub    $0xc,%esp
f0105138:	6a 08                	push   $0x8
f010513a:	e8 2c b6 ff ff       	call   f010076b <cputchar>
f010513f:	83 c4 10             	add    $0x10,%esp
			i--;
f0105142:	83 ee 01             	sub    $0x1,%esi
f0105145:	eb a2                	jmp    f01050e9 <readline+0x35>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0105147:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f010514d:	7f 23                	jg     f0105172 <readline+0xbe>
f010514f:	83 fb 1f             	cmp    $0x1f,%ebx
f0105152:	7e 1e                	jle    f0105172 <readline+0xbe>
			if (echoing)
f0105154:	85 ff                	test   %edi,%edi
f0105156:	74 0c                	je     f0105164 <readline+0xb0>
				cputchar(c);
f0105158:	83 ec 0c             	sub    $0xc,%esp
f010515b:	53                   	push   %ebx
f010515c:	e8 0a b6 ff ff       	call   f010076b <cputchar>
f0105161:	83 c4 10             	add    $0x10,%esp
			buf[i++] = c;
f0105164:	88 9e c0 da 1d f0    	mov    %bl,-0xfe22540(%esi)
f010516a:	8d 76 01             	lea    0x1(%esi),%esi
f010516d:	e9 77 ff ff ff       	jmp    f01050e9 <readline+0x35>
		} else if (c == '\n' || c == '\r') {
f0105172:	83 fb 0d             	cmp    $0xd,%ebx
f0105175:	74 09                	je     f0105180 <readline+0xcc>
f0105177:	83 fb 0a             	cmp    $0xa,%ebx
f010517a:	0f 85 69 ff ff ff    	jne    f01050e9 <readline+0x35>
			if (echoing)
f0105180:	85 ff                	test   %edi,%edi
f0105182:	74 0d                	je     f0105191 <readline+0xdd>
				cputchar('\n');
f0105184:	83 ec 0c             	sub    $0xc,%esp
f0105187:	6a 0a                	push   $0xa
f0105189:	e8 dd b5 ff ff       	call   f010076b <cputchar>
f010518e:	83 c4 10             	add    $0x10,%esp
			buf[i] = 0;
f0105191:	c6 86 c0 da 1d f0 00 	movb   $0x0,-0xfe22540(%esi)
			return buf;
f0105198:	b8 c0 da 1d f0       	mov    $0xf01ddac0,%eax
		}
	}
}
f010519d:	8d 65 f4             	lea    -0xc(%ebp),%esp
f01051a0:	5b                   	pop    %ebx
f01051a1:	5e                   	pop    %esi
f01051a2:	5f                   	pop    %edi
f01051a3:	5d                   	pop    %ebp
f01051a4:	c3                   	ret    

f01051a5 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01051a5:	55                   	push   %ebp
f01051a6:	89 e5                	mov    %esp,%ebp
f01051a8:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01051ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01051b0:	eb 03                	jmp    f01051b5 <strlen+0x10>
		n++;
f01051b2:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01051b5:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01051b9:	75 f7                	jne    f01051b2 <strlen+0xd>
		n++;
	return n;
}
f01051bb:	5d                   	pop    %ebp
f01051bc:	c3                   	ret    

f01051bd <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01051bd:	55                   	push   %ebp
f01051be:	89 e5                	mov    %esp,%ebp
f01051c0:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01051c3:	8b 45 0c             	mov    0xc(%ebp),%eax
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01051c6:	ba 00 00 00 00       	mov    $0x0,%edx
f01051cb:	eb 03                	jmp    f01051d0 <strnlen+0x13>
		n++;
f01051cd:	83 c2 01             	add    $0x1,%edx
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01051d0:	39 c2                	cmp    %eax,%edx
f01051d2:	74 08                	je     f01051dc <strnlen+0x1f>
f01051d4:	80 3c 11 00          	cmpb   $0x0,(%ecx,%edx,1)
f01051d8:	75 f3                	jne    f01051cd <strnlen+0x10>
f01051da:	89 d0                	mov    %edx,%eax
		n++;
	return n;
}
f01051dc:	5d                   	pop    %ebp
f01051dd:	c3                   	ret    

f01051de <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01051de:	55                   	push   %ebp
f01051df:	89 e5                	mov    %esp,%ebp
f01051e1:	53                   	push   %ebx
f01051e2:	8b 45 08             	mov    0x8(%ebp),%eax
f01051e5:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01051e8:	89 c2                	mov    %eax,%edx
f01051ea:	83 c2 01             	add    $0x1,%edx
f01051ed:	83 c1 01             	add    $0x1,%ecx
f01051f0:	0f b6 59 ff          	movzbl -0x1(%ecx),%ebx
f01051f4:	88 5a ff             	mov    %bl,-0x1(%edx)
f01051f7:	84 db                	test   %bl,%bl
f01051f9:	75 ef                	jne    f01051ea <strcpy+0xc>
		/* do nothing */;
	return ret;
}
f01051fb:	5b                   	pop    %ebx
f01051fc:	5d                   	pop    %ebp
f01051fd:	c3                   	ret    

f01051fe <strcat>:

char *
strcat(char *dst, const char *src)
{
f01051fe:	55                   	push   %ebp
f01051ff:	89 e5                	mov    %esp,%ebp
f0105201:	53                   	push   %ebx
f0105202:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0105205:	53                   	push   %ebx
f0105206:	e8 9a ff ff ff       	call   f01051a5 <strlen>
f010520b:	83 c4 04             	add    $0x4,%esp
	strcpy(dst + len, src);
f010520e:	ff 75 0c             	pushl  0xc(%ebp)
f0105211:	01 d8                	add    %ebx,%eax
f0105213:	50                   	push   %eax
f0105214:	e8 c5 ff ff ff       	call   f01051de <strcpy>
	return dst;
}
f0105219:	89 d8                	mov    %ebx,%eax
f010521b:	8b 5d fc             	mov    -0x4(%ebp),%ebx
f010521e:	c9                   	leave  
f010521f:	c3                   	ret    

f0105220 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0105220:	55                   	push   %ebp
f0105221:	89 e5                	mov    %esp,%ebp
f0105223:	56                   	push   %esi
f0105224:	53                   	push   %ebx
f0105225:	8b 75 08             	mov    0x8(%ebp),%esi
f0105228:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f010522b:	89 f3                	mov    %esi,%ebx
f010522d:	03 5d 10             	add    0x10(%ebp),%ebx
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105230:	89 f2                	mov    %esi,%edx
f0105232:	eb 0f                	jmp    f0105243 <strncpy+0x23>
		*dst++ = *src;
f0105234:	83 c2 01             	add    $0x1,%edx
f0105237:	0f b6 01             	movzbl (%ecx),%eax
f010523a:	88 42 ff             	mov    %al,-0x1(%edx)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f010523d:	80 39 01             	cmpb   $0x1,(%ecx)
f0105240:	83 d9 ff             	sbb    $0xffffffff,%ecx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0105243:	39 da                	cmp    %ebx,%edx
f0105245:	75 ed                	jne    f0105234 <strncpy+0x14>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0105247:	89 f0                	mov    %esi,%eax
f0105249:	5b                   	pop    %ebx
f010524a:	5e                   	pop    %esi
f010524b:	5d                   	pop    %ebp
f010524c:	c3                   	ret    

f010524d <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f010524d:	55                   	push   %ebp
f010524e:	89 e5                	mov    %esp,%ebp
f0105250:	56                   	push   %esi
f0105251:	53                   	push   %ebx
f0105252:	8b 75 08             	mov    0x8(%ebp),%esi
f0105255:	8b 4d 0c             	mov    0xc(%ebp),%ecx
f0105258:	8b 55 10             	mov    0x10(%ebp),%edx
f010525b:	89 f0                	mov    %esi,%eax
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f010525d:	85 d2                	test   %edx,%edx
f010525f:	74 21                	je     f0105282 <strlcpy+0x35>
f0105261:	8d 44 16 ff          	lea    -0x1(%esi,%edx,1),%eax
f0105265:	89 f2                	mov    %esi,%edx
f0105267:	eb 09                	jmp    f0105272 <strlcpy+0x25>
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0105269:	83 c2 01             	add    $0x1,%edx
f010526c:	83 c1 01             	add    $0x1,%ecx
f010526f:	88 5a ff             	mov    %bl,-0x1(%edx)
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0105272:	39 c2                	cmp    %eax,%edx
f0105274:	74 09                	je     f010527f <strlcpy+0x32>
f0105276:	0f b6 19             	movzbl (%ecx),%ebx
f0105279:	84 db                	test   %bl,%bl
f010527b:	75 ec                	jne    f0105269 <strlcpy+0x1c>
f010527d:	89 d0                	mov    %edx,%eax
			*dst++ = *src++;
		*dst = '\0';
f010527f:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0105282:	29 f0                	sub    %esi,%eax
}
f0105284:	5b                   	pop    %ebx
f0105285:	5e                   	pop    %esi
f0105286:	5d                   	pop    %ebp
f0105287:	c3                   	ret    

f0105288 <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0105288:	55                   	push   %ebp
f0105289:	89 e5                	mov    %esp,%ebp
f010528b:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010528e:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0105291:	eb 06                	jmp    f0105299 <strcmp+0x11>
		p++, q++;
f0105293:	83 c1 01             	add    $0x1,%ecx
f0105296:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0105299:	0f b6 01             	movzbl (%ecx),%eax
f010529c:	84 c0                	test   %al,%al
f010529e:	74 04                	je     f01052a4 <strcmp+0x1c>
f01052a0:	3a 02                	cmp    (%edx),%al
f01052a2:	74 ef                	je     f0105293 <strcmp+0xb>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01052a4:	0f b6 c0             	movzbl %al,%eax
f01052a7:	0f b6 12             	movzbl (%edx),%edx
f01052aa:	29 d0                	sub    %edx,%eax
}
f01052ac:	5d                   	pop    %ebp
f01052ad:	c3                   	ret    

f01052ae <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01052ae:	55                   	push   %ebp
f01052af:	89 e5                	mov    %esp,%ebp
f01052b1:	53                   	push   %ebx
f01052b2:	8b 45 08             	mov    0x8(%ebp),%eax
f01052b5:	8b 55 0c             	mov    0xc(%ebp),%edx
f01052b8:	89 c3                	mov    %eax,%ebx
f01052ba:	03 5d 10             	add    0x10(%ebp),%ebx
	while (n > 0 && *p && *p == *q)
f01052bd:	eb 06                	jmp    f01052c5 <strncmp+0x17>
		n--, p++, q++;
f01052bf:	83 c0 01             	add    $0x1,%eax
f01052c2:	83 c2 01             	add    $0x1,%edx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01052c5:	39 d8                	cmp    %ebx,%eax
f01052c7:	74 15                	je     f01052de <strncmp+0x30>
f01052c9:	0f b6 08             	movzbl (%eax),%ecx
f01052cc:	84 c9                	test   %cl,%cl
f01052ce:	74 04                	je     f01052d4 <strncmp+0x26>
f01052d0:	3a 0a                	cmp    (%edx),%cl
f01052d2:	74 eb                	je     f01052bf <strncmp+0x11>
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01052d4:	0f b6 00             	movzbl (%eax),%eax
f01052d7:	0f b6 12             	movzbl (%edx),%edx
f01052da:	29 d0                	sub    %edx,%eax
f01052dc:	eb 05                	jmp    f01052e3 <strncmp+0x35>
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01052de:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01052e3:	5b                   	pop    %ebx
f01052e4:	5d                   	pop    %ebp
f01052e5:	c3                   	ret    

f01052e6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01052e6:	55                   	push   %ebp
f01052e7:	89 e5                	mov    %esp,%ebp
f01052e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01052ec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01052f0:	eb 07                	jmp    f01052f9 <strchr+0x13>
		if (*s == c)
f01052f2:	38 ca                	cmp    %cl,%dl
f01052f4:	74 0f                	je     f0105305 <strchr+0x1f>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01052f6:	83 c0 01             	add    $0x1,%eax
f01052f9:	0f b6 10             	movzbl (%eax),%edx
f01052fc:	84 d2                	test   %dl,%dl
f01052fe:	75 f2                	jne    f01052f2 <strchr+0xc>
		if (*s == c)
			return (char *) s;
	return 0;
f0105300:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105305:	5d                   	pop    %ebp
f0105306:	c3                   	ret    

f0105307 <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0105307:	55                   	push   %ebp
f0105308:	89 e5                	mov    %esp,%ebp
f010530a:	8b 45 08             	mov    0x8(%ebp),%eax
f010530d:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0105311:	eb 03                	jmp    f0105316 <strfind+0xf>
f0105313:	83 c0 01             	add    $0x1,%eax
f0105316:	0f b6 10             	movzbl (%eax),%edx
		if (*s == c)
f0105319:	84 d2                	test   %dl,%dl
f010531b:	74 04                	je     f0105321 <strfind+0x1a>
f010531d:	38 ca                	cmp    %cl,%dl
f010531f:	75 f2                	jne    f0105313 <strfind+0xc>
			break;
	return (char *) s;
}
f0105321:	5d                   	pop    %ebp
f0105322:	c3                   	ret    

f0105323 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0105323:	55                   	push   %ebp
f0105324:	89 e5                	mov    %esp,%ebp
f0105326:	57                   	push   %edi
f0105327:	56                   	push   %esi
f0105328:	53                   	push   %ebx
f0105329:	8b 7d 08             	mov    0x8(%ebp),%edi
f010532c:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f010532f:	85 c9                	test   %ecx,%ecx
f0105331:	74 36                	je     f0105369 <memset+0x46>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0105333:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0105339:	75 28                	jne    f0105363 <memset+0x40>
f010533b:	f6 c1 03             	test   $0x3,%cl
f010533e:	75 23                	jne    f0105363 <memset+0x40>
		c &= 0xFF;
f0105340:	0f b6 55 0c          	movzbl 0xc(%ebp),%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0105344:	89 d3                	mov    %edx,%ebx
f0105346:	c1 e3 08             	shl    $0x8,%ebx
f0105349:	89 d6                	mov    %edx,%esi
f010534b:	c1 e6 18             	shl    $0x18,%esi
f010534e:	89 d0                	mov    %edx,%eax
f0105350:	c1 e0 10             	shl    $0x10,%eax
f0105353:	09 f0                	or     %esi,%eax
f0105355:	09 c2                	or     %eax,%edx
f0105357:	89 d0                	mov    %edx,%eax
f0105359:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f010535b:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f010535e:	fc                   	cld    
f010535f:	f3 ab                	rep stos %eax,%es:(%edi)
f0105361:	eb 06                	jmp    f0105369 <memset+0x46>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0105363:	8b 45 0c             	mov    0xc(%ebp),%eax
f0105366:	fc                   	cld    
f0105367:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0105369:	89 f8                	mov    %edi,%eax
f010536b:	5b                   	pop    %ebx
f010536c:	5e                   	pop    %esi
f010536d:	5f                   	pop    %edi
f010536e:	5d                   	pop    %ebp
f010536f:	c3                   	ret    

f0105370 <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0105370:	55                   	push   %ebp
f0105371:	89 e5                	mov    %esp,%ebp
f0105373:	57                   	push   %edi
f0105374:	56                   	push   %esi
f0105375:	8b 45 08             	mov    0x8(%ebp),%eax
f0105378:	8b 75 0c             	mov    0xc(%ebp),%esi
f010537b:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f010537e:	39 c6                	cmp    %eax,%esi
f0105380:	73 35                	jae    f01053b7 <memmove+0x47>
f0105382:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0105385:	39 d0                	cmp    %edx,%eax
f0105387:	73 2e                	jae    f01053b7 <memmove+0x47>
		s += n;
		d += n;
f0105389:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
f010538c:	89 d6                	mov    %edx,%esi
f010538e:	09 fe                	or     %edi,%esi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0105390:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0105396:	75 13                	jne    f01053ab <memmove+0x3b>
f0105398:	f6 c1 03             	test   $0x3,%cl
f010539b:	75 0e                	jne    f01053ab <memmove+0x3b>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f010539d:	83 ef 04             	sub    $0x4,%edi
f01053a0:	8d 72 fc             	lea    -0x4(%edx),%esi
f01053a3:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01053a6:	fd                   	std    
f01053a7:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01053a9:	eb 09                	jmp    f01053b4 <memmove+0x44>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01053ab:	83 ef 01             	sub    $0x1,%edi
f01053ae:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01053b1:	fd                   	std    
f01053b2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01053b4:	fc                   	cld    
f01053b5:	eb 1d                	jmp    f01053d4 <memmove+0x64>
f01053b7:	89 f2                	mov    %esi,%edx
f01053b9:	09 c2                	or     %eax,%edx
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01053bb:	f6 c2 03             	test   $0x3,%dl
f01053be:	75 0f                	jne    f01053cf <memmove+0x5f>
f01053c0:	f6 c1 03             	test   $0x3,%cl
f01053c3:	75 0a                	jne    f01053cf <memmove+0x5f>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01053c5:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01053c8:	89 c7                	mov    %eax,%edi
f01053ca:	fc                   	cld    
f01053cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01053cd:	eb 05                	jmp    f01053d4 <memmove+0x64>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01053cf:	89 c7                	mov    %eax,%edi
f01053d1:	fc                   	cld    
f01053d2:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01053d4:	5e                   	pop    %esi
f01053d5:	5f                   	pop    %edi
f01053d6:	5d                   	pop    %ebp
f01053d7:	c3                   	ret    

f01053d8 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f01053d8:	55                   	push   %ebp
f01053d9:	89 e5                	mov    %esp,%ebp
	return memmove(dst, src, n);
f01053db:	ff 75 10             	pushl  0x10(%ebp)
f01053de:	ff 75 0c             	pushl  0xc(%ebp)
f01053e1:	ff 75 08             	pushl  0x8(%ebp)
f01053e4:	e8 87 ff ff ff       	call   f0105370 <memmove>
}
f01053e9:	c9                   	leave  
f01053ea:	c3                   	ret    

f01053eb <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01053eb:	55                   	push   %ebp
f01053ec:	89 e5                	mov    %esp,%ebp
f01053ee:	56                   	push   %esi
f01053ef:	53                   	push   %ebx
f01053f0:	8b 45 08             	mov    0x8(%ebp),%eax
f01053f3:	8b 55 0c             	mov    0xc(%ebp),%edx
f01053f6:	89 c6                	mov    %eax,%esi
f01053f8:	03 75 10             	add    0x10(%ebp),%esi
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01053fb:	eb 1a                	jmp    f0105417 <memcmp+0x2c>
		if (*s1 != *s2)
f01053fd:	0f b6 08             	movzbl (%eax),%ecx
f0105400:	0f b6 1a             	movzbl (%edx),%ebx
f0105403:	38 d9                	cmp    %bl,%cl
f0105405:	74 0a                	je     f0105411 <memcmp+0x26>
			return (int) *s1 - (int) *s2;
f0105407:	0f b6 c1             	movzbl %cl,%eax
f010540a:	0f b6 db             	movzbl %bl,%ebx
f010540d:	29 d8                	sub    %ebx,%eax
f010540f:	eb 0f                	jmp    f0105420 <memcmp+0x35>
		s1++, s2++;
f0105411:	83 c0 01             	add    $0x1,%eax
f0105414:	83 c2 01             	add    $0x1,%edx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0105417:	39 f0                	cmp    %esi,%eax
f0105419:	75 e2                	jne    f01053fd <memcmp+0x12>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f010541b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105420:	5b                   	pop    %ebx
f0105421:	5e                   	pop    %esi
f0105422:	5d                   	pop    %ebp
f0105423:	c3                   	ret    

f0105424 <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0105424:	55                   	push   %ebp
f0105425:	89 e5                	mov    %esp,%ebp
f0105427:	8b 45 08             	mov    0x8(%ebp),%eax
f010542a:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	const void *ends = (const char *) s + n;
f010542d:	89 c2                	mov    %eax,%edx
f010542f:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0105432:	eb 07                	jmp    f010543b <memfind+0x17>
		if (*(const unsigned char *) s == (unsigned char) c)
f0105434:	38 08                	cmp    %cl,(%eax)
f0105436:	74 07                	je     f010543f <memfind+0x1b>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0105438:	83 c0 01             	add    $0x1,%eax
f010543b:	39 d0                	cmp    %edx,%eax
f010543d:	72 f5                	jb     f0105434 <memfind+0x10>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f010543f:	5d                   	pop    %ebp
f0105440:	c3                   	ret    

f0105441 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0105441:	55                   	push   %ebp
f0105442:	89 e5                	mov    %esp,%ebp
f0105444:	57                   	push   %edi
f0105445:	56                   	push   %esi
f0105446:	53                   	push   %ebx
f0105447:	8b 4d 08             	mov    0x8(%ebp),%ecx
f010544a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010544d:	eb 03                	jmp    f0105452 <strtol+0x11>
		s++;
f010544f:	83 c1 01             	add    $0x1,%ecx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0105452:	0f b6 01             	movzbl (%ecx),%eax
f0105455:	3c 09                	cmp    $0x9,%al
f0105457:	74 f6                	je     f010544f <strtol+0xe>
f0105459:	3c 20                	cmp    $0x20,%al
f010545b:	74 f2                	je     f010544f <strtol+0xe>
		s++;

	// plus/minus sign
	if (*s == '+')
f010545d:	3c 2b                	cmp    $0x2b,%al
f010545f:	75 0a                	jne    f010546b <strtol+0x2a>
		s++;
f0105461:	83 c1 01             	add    $0x1,%ecx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0105464:	bf 00 00 00 00       	mov    $0x0,%edi
f0105469:	eb 10                	jmp    f010547b <strtol+0x3a>
f010546b:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0105470:	3c 2d                	cmp    $0x2d,%al
f0105472:	75 07                	jne    f010547b <strtol+0x3a>
		s++, neg = 1;
f0105474:	8d 49 01             	lea    0x1(%ecx),%ecx
f0105477:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f010547b:	85 db                	test   %ebx,%ebx
f010547d:	0f 94 c0             	sete   %al
f0105480:	f7 c3 ef ff ff ff    	test   $0xffffffef,%ebx
f0105486:	75 19                	jne    f01054a1 <strtol+0x60>
f0105488:	80 39 30             	cmpb   $0x30,(%ecx)
f010548b:	75 14                	jne    f01054a1 <strtol+0x60>
f010548d:	80 79 01 78          	cmpb   $0x78,0x1(%ecx)
f0105491:	0f 85 82 00 00 00    	jne    f0105519 <strtol+0xd8>
		s += 2, base = 16;
f0105497:	83 c1 02             	add    $0x2,%ecx
f010549a:	bb 10 00 00 00       	mov    $0x10,%ebx
f010549f:	eb 16                	jmp    f01054b7 <strtol+0x76>
	else if (base == 0 && s[0] == '0')
f01054a1:	84 c0                	test   %al,%al
f01054a3:	74 12                	je     f01054b7 <strtol+0x76>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f01054a5:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01054aa:	80 39 30             	cmpb   $0x30,(%ecx)
f01054ad:	75 08                	jne    f01054b7 <strtol+0x76>
		s++, base = 8;
f01054af:	83 c1 01             	add    $0x1,%ecx
f01054b2:	bb 08 00 00 00       	mov    $0x8,%ebx
	else if (base == 0)
		base = 10;
f01054b7:	b8 00 00 00 00       	mov    $0x0,%eax
f01054bc:	89 5d 10             	mov    %ebx,0x10(%ebp)

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01054bf:	0f b6 11             	movzbl (%ecx),%edx
f01054c2:	8d 72 d0             	lea    -0x30(%edx),%esi
f01054c5:	89 f3                	mov    %esi,%ebx
f01054c7:	80 fb 09             	cmp    $0x9,%bl
f01054ca:	77 08                	ja     f01054d4 <strtol+0x93>
			dig = *s - '0';
f01054cc:	0f be d2             	movsbl %dl,%edx
f01054cf:	83 ea 30             	sub    $0x30,%edx
f01054d2:	eb 22                	jmp    f01054f6 <strtol+0xb5>
		else if (*s >= 'a' && *s <= 'z')
f01054d4:	8d 72 9f             	lea    -0x61(%edx),%esi
f01054d7:	89 f3                	mov    %esi,%ebx
f01054d9:	80 fb 19             	cmp    $0x19,%bl
f01054dc:	77 08                	ja     f01054e6 <strtol+0xa5>
			dig = *s - 'a' + 10;
f01054de:	0f be d2             	movsbl %dl,%edx
f01054e1:	83 ea 57             	sub    $0x57,%edx
f01054e4:	eb 10                	jmp    f01054f6 <strtol+0xb5>
		else if (*s >= 'A' && *s <= 'Z')
f01054e6:	8d 72 bf             	lea    -0x41(%edx),%esi
f01054e9:	89 f3                	mov    %esi,%ebx
f01054eb:	80 fb 19             	cmp    $0x19,%bl
f01054ee:	77 16                	ja     f0105506 <strtol+0xc5>
			dig = *s - 'A' + 10;
f01054f0:	0f be d2             	movsbl %dl,%edx
f01054f3:	83 ea 37             	sub    $0x37,%edx
		else
			break;
		if (dig >= base)
f01054f6:	3b 55 10             	cmp    0x10(%ebp),%edx
f01054f9:	7d 0f                	jge    f010550a <strtol+0xc9>
			break;
		s++, val = (val * base) + dig;
f01054fb:	83 c1 01             	add    $0x1,%ecx
f01054fe:	0f af 45 10          	imul   0x10(%ebp),%eax
f0105502:	01 d0                	add    %edx,%eax
		// we don't properly detect overflow!
	}
f0105504:	eb b9                	jmp    f01054bf <strtol+0x7e>
f0105506:	89 c2                	mov    %eax,%edx
f0105508:	eb 02                	jmp    f010550c <strtol+0xcb>
f010550a:	89 c2                	mov    %eax,%edx

	if (endptr)
f010550c:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0105510:	74 0d                	je     f010551f <strtol+0xde>
		*endptr = (char *) s;
f0105512:	8b 75 0c             	mov    0xc(%ebp),%esi
f0105515:	89 0e                	mov    %ecx,(%esi)
f0105517:	eb 06                	jmp    f010551f <strtol+0xde>
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0105519:	84 c0                	test   %al,%al
f010551b:	75 92                	jne    f01054af <strtol+0x6e>
f010551d:	eb 98                	jmp    f01054b7 <strtol+0x76>
		// we don't properly detect overflow!
	}

	if (endptr)
		*endptr = (char *) s;
	return (neg ? -val : val);
f010551f:	f7 da                	neg    %edx
f0105521:	85 ff                	test   %edi,%edi
f0105523:	0f 45 c2             	cmovne %edx,%eax
}
f0105526:	5b                   	pop    %ebx
f0105527:	5e                   	pop    %esi
f0105528:	5f                   	pop    %edi
f0105529:	5d                   	pop    %ebp
f010552a:	c3                   	ret    
f010552b:	90                   	nop

f010552c <mpentry_start>:
.set PROT_MODE_DSEG, 0x10	# kernel data segment selector

.code16           
.globl mpentry_start
mpentry_start:
	cli            
f010552c:	fa                   	cli    

	xorw    %ax, %ax
f010552d:	31 c0                	xor    %eax,%eax
	movw    %ax, %ds
f010552f:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105531:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105533:	8e d0                	mov    %eax,%ss

	lgdt    MPBOOTPHYS(gdtdesc)
f0105535:	0f 01 16             	lgdtl  (%esi)
f0105538:	74 70                	je     f01055aa <mpsearch1+0x3>
	movl    %cr0, %eax
f010553a:	0f 20 c0             	mov    %cr0,%eax
	orl     $CR0_PE, %eax
f010553d:	66 83 c8 01          	or     $0x1,%ax
	movl    %eax, %cr0
f0105541:	0f 22 c0             	mov    %eax,%cr0

	ljmpl   $(PROT_MODE_CSEG), $(MPBOOTPHYS(start32))
f0105544:	66 ea 20 70 00 00    	ljmpw  $0x0,$0x7020
f010554a:	08 00                	or     %al,(%eax)

f010554c <start32>:

.code32
start32:
	movw    $(PROT_MODE_DSEG), %ax
f010554c:	66 b8 10 00          	mov    $0x10,%ax
	movw    %ax, %ds
f0105550:	8e d8                	mov    %eax,%ds
	movw    %ax, %es
f0105552:	8e c0                	mov    %eax,%es
	movw    %ax, %ss
f0105554:	8e d0                	mov    %eax,%ss
	movw    $0, %ax
f0105556:	66 b8 00 00          	mov    $0x0,%ax
	movw    %ax, %fs
f010555a:	8e e0                	mov    %eax,%fs
	movw    %ax, %gs
f010555c:	8e e8                	mov    %eax,%gs

	# Set up initial page table. We cannot use kern_pgdir yet because
	# we are still running at a low EIP.
	movl    $(RELOC(entry_pgdir)), %eax
f010555e:	b8 00 e0 11 00       	mov    $0x11e000,%eax
	movl    %eax, %cr3
f0105563:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl    %cr0, %eax
f0105566:	0f 20 c0             	mov    %cr0,%eax
	orl     $(CR0_PE|CR0_PG|CR0_WP), %eax
f0105569:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl    %eax, %cr0
f010556e:	0f 22 c0             	mov    %eax,%cr0

	# Switch to the per-cpu stack allocated in boot_aps()
	movl    mpentry_kstack, %esp
f0105571:	8b 25 c4 de 1d f0    	mov    0xf01ddec4,%esp
	movl    $0x0, %ebp       # nuke frame pointer
f0105577:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Call mp_main().  (Exercise for the reader: why the indirect call?)
	movl    $mp_main, %eax
f010557c:	b8 b9 01 10 f0       	mov    $0xf01001b9,%eax
	call    *%eax
f0105581:	ff d0                	call   *%eax

f0105583 <spin>:

	# If mp_main returns (it shouldn't), loop.
spin:
	jmp     spin
f0105583:	eb fe                	jmp    f0105583 <spin>
f0105585:	8d 76 00             	lea    0x0(%esi),%esi

f0105588 <gdt>:
	...
f0105590:	ff                   	(bad)  
f0105591:	ff 00                	incl   (%eax)
f0105593:	00 00                	add    %al,(%eax)
f0105595:	9a cf 00 ff ff 00 00 	lcall  $0x0,$0xffff00cf
f010559c:	00 92 cf 00 17 00    	add    %dl,0x1700cf(%edx)

f01055a0 <gdtdesc>:
f01055a0:	17                   	pop    %ss
f01055a1:	00 5c 70 00          	add    %bl,0x0(%eax,%esi,2)
	...

f01055a6 <mpentry_end>:
	.word   0x17				# sizeof(gdt) - 1
	.long   MPBOOTPHYS(gdt)			# address gdt

.globl mpentry_end
mpentry_end:
	nop
f01055a6:	90                   	nop

f01055a7 <mpsearch1>:
}

// Look for an MP structure in the len bytes at physical address addr.
static struct mp *
mpsearch1(physaddr_t a, int len)
{
f01055a7:	55                   	push   %ebp
f01055a8:	89 e5                	mov    %esp,%ebp
f01055aa:	57                   	push   %edi
f01055ab:	56                   	push   %esi
f01055ac:	53                   	push   %ebx
f01055ad:	83 ec 0c             	sub    $0xc,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01055b0:	8b 0d c8 de 1d f0    	mov    0xf01ddec8,%ecx
f01055b6:	89 c3                	mov    %eax,%ebx
f01055b8:	c1 eb 0c             	shr    $0xc,%ebx
f01055bb:	39 cb                	cmp    %ecx,%ebx
f01055bd:	72 12                	jb     f01055d1 <mpsearch1+0x2a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01055bf:	50                   	push   %eax
f01055c0:	68 24 60 10 f0       	push   $0xf0106024
f01055c5:	6a 57                	push   $0x57
f01055c7:	68 3d 7d 10 f0       	push   $0xf0107d3d
f01055cc:	e8 6f aa ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01055d1:	8d 98 00 00 00 f0    	lea    -0x10000000(%eax),%ebx
	struct mp *mp = KADDR(a), *end = KADDR(a + len);
f01055d7:	01 d0                	add    %edx,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01055d9:	89 c2                	mov    %eax,%edx
f01055db:	c1 ea 0c             	shr    $0xc,%edx
f01055de:	39 d1                	cmp    %edx,%ecx
f01055e0:	77 12                	ja     f01055f4 <mpsearch1+0x4d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01055e2:	50                   	push   %eax
f01055e3:	68 24 60 10 f0       	push   $0xf0106024
f01055e8:	6a 57                	push   $0x57
f01055ea:	68 3d 7d 10 f0       	push   $0xf0107d3d
f01055ef:	e8 4c aa ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f01055f4:	8d b0 00 00 00 f0    	lea    -0x10000000(%eax),%esi

	for (; mp < end; mp++)
f01055fa:	eb 2f                	jmp    f010562b <mpsearch1+0x84>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f01055fc:	83 ec 04             	sub    $0x4,%esp
f01055ff:	6a 04                	push   $0x4
f0105601:	68 4d 7d 10 f0       	push   $0xf0107d4d
f0105606:	53                   	push   %ebx
f0105607:	e8 df fd ff ff       	call   f01053eb <memcmp>
f010560c:	83 c4 10             	add    $0x10,%esp
f010560f:	85 c0                	test   %eax,%eax
f0105611:	75 15                	jne    f0105628 <mpsearch1+0x81>
f0105613:	89 da                	mov    %ebx,%edx
f0105615:	8d 7b 10             	lea    0x10(%ebx),%edi
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
		sum += ((uint8_t *)addr)[i];
f0105618:	0f b6 0a             	movzbl (%edx),%ecx
f010561b:	01 c8                	add    %ecx,%eax
f010561d:	83 c2 01             	add    $0x1,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105620:	39 fa                	cmp    %edi,%edx
f0105622:	75 f4                	jne    f0105618 <mpsearch1+0x71>
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
f0105624:	84 c0                	test   %al,%al
f0105626:	74 0e                	je     f0105636 <mpsearch1+0x8f>
static struct mp *
mpsearch1(physaddr_t a, int len)
{
	struct mp *mp = KADDR(a), *end = KADDR(a + len);

	for (; mp < end; mp++)
f0105628:	83 c3 10             	add    $0x10,%ebx
f010562b:	39 f3                	cmp    %esi,%ebx
f010562d:	72 cd                	jb     f01055fc <mpsearch1+0x55>
		if (memcmp(mp->signature, "_MP_", 4) == 0 &&
		    sum(mp, sizeof(*mp)) == 0)
			return mp;
	return NULL;
f010562f:	b8 00 00 00 00       	mov    $0x0,%eax
f0105634:	eb 02                	jmp    f0105638 <mpsearch1+0x91>
f0105636:	89 d8                	mov    %ebx,%eax
}
f0105638:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010563b:	5b                   	pop    %ebx
f010563c:	5e                   	pop    %esi
f010563d:	5f                   	pop    %edi
f010563e:	5d                   	pop    %ebp
f010563f:	c3                   	ret    

f0105640 <mp_init>:
	return conf;
}

void
mp_init(void)
{
f0105640:	55                   	push   %ebp
f0105641:	89 e5                	mov    %esp,%ebp
f0105643:	57                   	push   %edi
f0105644:	56                   	push   %esi
f0105645:	53                   	push   %ebx
f0105646:	83 ec 1c             	sub    $0x1c,%esp
	struct mpconf *conf;
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
f0105649:	c7 05 e0 e3 1d f0 40 	movl   $0xf01de040,0xf01de3e0
f0105650:	e0 1d f0 
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105653:	83 3d c8 de 1d f0 00 	cmpl   $0x0,0xf01ddec8
f010565a:	75 16                	jne    f0105672 <mp_init+0x32>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010565c:	68 00 04 00 00       	push   $0x400
f0105661:	68 24 60 10 f0       	push   $0xf0106024
f0105666:	6a 6f                	push   $0x6f
f0105668:	68 3d 7d 10 f0       	push   $0xf0107d3d
f010566d:	e8 ce a9 ff ff       	call   f0100040 <_panic>
	// The BIOS data area lives in 16-bit segment 0x40.
	bda = (uint8_t *) KADDR(0x40 << 4);

	// [MP 4] The 16-bit segment of the EBDA is in the two bytes
	// starting at byte 0x0E of the BDA.  0 if not present.
	if ((p = *(uint16_t *) (bda + 0x0E))) {
f0105672:	0f b7 05 0e 04 00 f0 	movzwl 0xf000040e,%eax
f0105679:	85 c0                	test   %eax,%eax
f010567b:	74 16                	je     f0105693 <mp_init+0x53>
		p <<= 4;	// Translate from segment to PA
f010567d:	c1 e0 04             	shl    $0x4,%eax
		if ((mp = mpsearch1(p, 1024)))
f0105680:	ba 00 04 00 00       	mov    $0x400,%edx
f0105685:	e8 1d ff ff ff       	call   f01055a7 <mpsearch1>
f010568a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010568d:	85 c0                	test   %eax,%eax
f010568f:	75 3c                	jne    f01056cd <mp_init+0x8d>
f0105691:	eb 20                	jmp    f01056b3 <mp_init+0x73>
			return mp;
	} else {
		// The size of base memory, in KB is in the two bytes
		// starting at 0x13 of the BDA.
		p = *(uint16_t *) (bda + 0x13) * 1024;
f0105693:	0f b7 05 13 04 00 f0 	movzwl 0xf0000413,%eax
f010569a:	c1 e0 0a             	shl    $0xa,%eax
		if ((mp = mpsearch1(p - 1024, 1024)))
f010569d:	2d 00 04 00 00       	sub    $0x400,%eax
f01056a2:	ba 00 04 00 00       	mov    $0x400,%edx
f01056a7:	e8 fb fe ff ff       	call   f01055a7 <mpsearch1>
f01056ac:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01056af:	85 c0                	test   %eax,%eax
f01056b1:	75 1a                	jne    f01056cd <mp_init+0x8d>
			return mp;
	}
	return mpsearch1(0xF0000, 0x10000);
f01056b3:	ba 00 00 01 00       	mov    $0x10000,%edx
f01056b8:	b8 00 00 0f 00       	mov    $0xf0000,%eax
f01056bd:	e8 e5 fe ff ff       	call   f01055a7 <mpsearch1>
f01056c2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
mpconfig(struct mp **pmp)
{
	struct mpconf *conf;
	struct mp *mp;

	if ((mp = mpsearch()) == 0)
f01056c5:	85 c0                	test   %eax,%eax
f01056c7:	0f 84 5a 02 00 00    	je     f0105927 <mp_init+0x2e7>
		return NULL;
	if (mp->physaddr == 0 || mp->type != 0) {
f01056cd:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01056d0:	8b 70 04             	mov    0x4(%eax),%esi
f01056d3:	85 f6                	test   %esi,%esi
f01056d5:	74 06                	je     f01056dd <mp_init+0x9d>
f01056d7:	80 78 0b 00          	cmpb   $0x0,0xb(%eax)
f01056db:	74 15                	je     f01056f2 <mp_init+0xb2>
		cprintf("SMP: Default configurations not implemented\n");
f01056dd:	83 ec 0c             	sub    $0xc,%esp
f01056e0:	68 b0 7b 10 f0       	push   $0xf0107bb0
f01056e5:	e8 25 e1 ff ff       	call   f010380f <cprintf>
f01056ea:	83 c4 10             	add    $0x10,%esp
f01056ed:	e9 35 02 00 00       	jmp    f0105927 <mp_init+0x2e7>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01056f2:	89 f0                	mov    %esi,%eax
f01056f4:	c1 e8 0c             	shr    $0xc,%eax
f01056f7:	3b 05 c8 de 1d f0    	cmp    0xf01ddec8,%eax
f01056fd:	72 15                	jb     f0105714 <mp_init+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01056ff:	56                   	push   %esi
f0105700:	68 24 60 10 f0       	push   $0xf0106024
f0105705:	68 90 00 00 00       	push   $0x90
f010570a:	68 3d 7d 10 f0       	push   $0xf0107d3d
f010570f:	e8 2c a9 ff ff       	call   f0100040 <_panic>
	return (void *)(pa + KERNBASE);
f0105714:	8d 9e 00 00 00 f0    	lea    -0x10000000(%esi),%ebx
		return NULL;
	}
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
f010571a:	83 ec 04             	sub    $0x4,%esp
f010571d:	6a 04                	push   $0x4
f010571f:	68 52 7d 10 f0       	push   $0xf0107d52
f0105724:	53                   	push   %ebx
f0105725:	e8 c1 fc ff ff       	call   f01053eb <memcmp>
f010572a:	83 c4 10             	add    $0x10,%esp
f010572d:	85 c0                	test   %eax,%eax
f010572f:	74 15                	je     f0105746 <mp_init+0x106>
		cprintf("SMP: Incorrect MP configuration table signature\n");
f0105731:	83 ec 0c             	sub    $0xc,%esp
f0105734:	68 e0 7b 10 f0       	push   $0xf0107be0
f0105739:	e8 d1 e0 ff ff       	call   f010380f <cprintf>
f010573e:	83 c4 10             	add    $0x10,%esp
f0105741:	e9 e1 01 00 00       	jmp    f0105927 <mp_init+0x2e7>
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f0105746:	0f b7 43 04          	movzwl 0x4(%ebx),%eax
f010574a:	66 89 45 e2          	mov    %ax,-0x1e(%ebp)
f010574e:	0f b7 f8             	movzwl %ax,%edi
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f0105751:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f0105756:	b8 00 00 00 00       	mov    $0x0,%eax
f010575b:	eb 0d                	jmp    f010576a <mp_init+0x12a>
		sum += ((uint8_t *)addr)[i];
f010575d:	0f b6 8c 30 00 00 00 	movzbl -0x10000000(%eax,%esi,1),%ecx
f0105764:	f0 
f0105765:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f0105767:	83 c0 01             	add    $0x1,%eax
f010576a:	39 c7                	cmp    %eax,%edi
f010576c:	75 ef                	jne    f010575d <mp_init+0x11d>
	conf = (struct mpconf *) KADDR(mp->physaddr);
	if (memcmp(conf, "PCMP", 4) != 0) {
		cprintf("SMP: Incorrect MP configuration table signature\n");
		return NULL;
	}
	if (sum(conf, conf->length) != 0) {
f010576e:	84 d2                	test   %dl,%dl
f0105770:	74 15                	je     f0105787 <mp_init+0x147>
		cprintf("SMP: Bad MP configuration checksum\n");
f0105772:	83 ec 0c             	sub    $0xc,%esp
f0105775:	68 14 7c 10 f0       	push   $0xf0107c14
f010577a:	e8 90 e0 ff ff       	call   f010380f <cprintf>
f010577f:	83 c4 10             	add    $0x10,%esp
f0105782:	e9 a0 01 00 00       	jmp    f0105927 <mp_init+0x2e7>
		return NULL;
	}
	if (conf->version != 1 && conf->version != 4) {
f0105787:	0f b6 43 06          	movzbl 0x6(%ebx),%eax
f010578b:	3c 04                	cmp    $0x4,%al
f010578d:	74 1d                	je     f01057ac <mp_init+0x16c>
f010578f:	3c 01                	cmp    $0x1,%al
f0105791:	74 19                	je     f01057ac <mp_init+0x16c>
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
f0105793:	83 ec 08             	sub    $0x8,%esp
f0105796:	0f b6 c0             	movzbl %al,%eax
f0105799:	50                   	push   %eax
f010579a:	68 38 7c 10 f0       	push   $0xf0107c38
f010579f:	e8 6b e0 ff ff       	call   f010380f <cprintf>
f01057a4:	83 c4 10             	add    $0x10,%esp
f01057a7:	e9 7b 01 00 00       	jmp    f0105927 <mp_init+0x2e7>
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01057ac:	0f b7 7b 28          	movzwl 0x28(%ebx),%edi
f01057b0:	0f b7 4d e2          	movzwl -0x1e(%ebp),%ecx
static uint8_t
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
f01057b4:	ba 00 00 00 00       	mov    $0x0,%edx
	for (i = 0; i < len; i++)
f01057b9:	b8 00 00 00 00       	mov    $0x0,%eax
f01057be:	01 ce                	add    %ecx,%esi
f01057c0:	eb 0d                	jmp    f01057cf <mp_init+0x18f>
		sum += ((uint8_t *)addr)[i];
f01057c2:	0f b6 8c 06 00 00 00 	movzbl -0x10000000(%esi,%eax,1),%ecx
f01057c9:	f0 
f01057ca:	01 ca                	add    %ecx,%edx
sum(void *addr, int len)
{
	int i, sum;

	sum = 0;
	for (i = 0; i < len; i++)
f01057cc:	83 c0 01             	add    $0x1,%eax
f01057cf:	39 c7                	cmp    %eax,%edi
f01057d1:	75 ef                	jne    f01057c2 <mp_init+0x182>
	}
	if (conf->version != 1 && conf->version != 4) {
		cprintf("SMP: Unsupported MP version %d\n", conf->version);
		return NULL;
	}
	if ((sum((uint8_t *)conf + conf->length, conf->xlength) + conf->xchecksum) & 0xff) {
f01057d3:	89 d0                	mov    %edx,%eax
f01057d5:	02 43 2a             	add    0x2a(%ebx),%al
f01057d8:	74 15                	je     f01057ef <mp_init+0x1af>
		cprintf("SMP: Bad MP configuration extended checksum\n");
f01057da:	83 ec 0c             	sub    $0xc,%esp
f01057dd:	68 58 7c 10 f0       	push   $0xf0107c58
f01057e2:	e8 28 e0 ff ff       	call   f010380f <cprintf>
f01057e7:	83 c4 10             	add    $0x10,%esp
f01057ea:	e9 38 01 00 00       	jmp    f0105927 <mp_init+0x2e7>
	struct mpproc *proc;
	uint8_t *p;
	unsigned int i;

	bootcpu = &cpus[0];
	if ((conf = mpconfig(&mp)) == 0)
f01057ef:	85 db                	test   %ebx,%ebx
f01057f1:	0f 84 30 01 00 00    	je     f0105927 <mp_init+0x2e7>
		return;
	ismp = 1;
f01057f7:	c7 05 00 e0 1d f0 01 	movl   $0x1,0xf01de000
f01057fe:	00 00 00 
	lapicaddr = conf->lapicaddr;
f0105801:	8b 43 24             	mov    0x24(%ebx),%eax
f0105804:	a3 00 f0 21 f0       	mov    %eax,0xf021f000

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105809:	8d 7b 2c             	lea    0x2c(%ebx),%edi
f010580c:	be 00 00 00 00       	mov    $0x0,%esi
f0105811:	e9 85 00 00 00       	jmp    f010589b <mp_init+0x25b>
		switch (*p) {
f0105816:	0f b6 07             	movzbl (%edi),%eax
f0105819:	84 c0                	test   %al,%al
f010581b:	74 06                	je     f0105823 <mp_init+0x1e3>
f010581d:	3c 04                	cmp    $0x4,%al
f010581f:	77 55                	ja     f0105876 <mp_init+0x236>
f0105821:	eb 4e                	jmp    f0105871 <mp_init+0x231>
		case MPPROC:
			proc = (struct mpproc *)p;
			if (proc->flags & MPPROC_BOOT)
f0105823:	f6 47 03 02          	testb  $0x2,0x3(%edi)
f0105827:	74 11                	je     f010583a <mp_init+0x1fa>
				bootcpu = &cpus[ncpu];
f0105829:	6b 05 e4 e3 1d f0 74 	imul   $0x74,0xf01de3e4,%eax
f0105830:	05 40 e0 1d f0       	add    $0xf01de040,%eax
f0105835:	a3 e0 e3 1d f0       	mov    %eax,0xf01de3e0
			if (ncpu < NCPU) {
f010583a:	a1 e4 e3 1d f0       	mov    0xf01de3e4,%eax
f010583f:	83 f8 07             	cmp    $0x7,%eax
f0105842:	7f 13                	jg     f0105857 <mp_init+0x217>
				cpus[ncpu].cpu_id = ncpu;
f0105844:	6b d0 74             	imul   $0x74,%eax,%edx
f0105847:	88 82 40 e0 1d f0    	mov    %al,-0xfe21fc0(%edx)
				ncpu++;
f010584d:	83 c0 01             	add    $0x1,%eax
f0105850:	a3 e4 e3 1d f0       	mov    %eax,0xf01de3e4
f0105855:	eb 15                	jmp    f010586c <mp_init+0x22c>
			} else {
				cprintf("SMP: too many CPUs, CPU %d disabled\n",
f0105857:	83 ec 08             	sub    $0x8,%esp
f010585a:	0f b6 47 01          	movzbl 0x1(%edi),%eax
f010585e:	50                   	push   %eax
f010585f:	68 88 7c 10 f0       	push   $0xf0107c88
f0105864:	e8 a6 df ff ff       	call   f010380f <cprintf>
f0105869:	83 c4 10             	add    $0x10,%esp
					proc->apicid);
			}
			p += sizeof(struct mpproc);
f010586c:	83 c7 14             	add    $0x14,%edi
			continue;
f010586f:	eb 27                	jmp    f0105898 <mp_init+0x258>
		case MPBUS:
		case MPIOAPIC:
		case MPIOINTR:
		case MPLINTR:
			p += 8;
f0105871:	83 c7 08             	add    $0x8,%edi
			continue;
f0105874:	eb 22                	jmp    f0105898 <mp_init+0x258>
		default:
			cprintf("mpinit: unknown config type %x\n", *p);
f0105876:	83 ec 08             	sub    $0x8,%esp
f0105879:	0f b6 c0             	movzbl %al,%eax
f010587c:	50                   	push   %eax
f010587d:	68 b0 7c 10 f0       	push   $0xf0107cb0
f0105882:	e8 88 df ff ff       	call   f010380f <cprintf>
			ismp = 0;
f0105887:	c7 05 00 e0 1d f0 00 	movl   $0x0,0xf01de000
f010588e:	00 00 00 
			i = conf->entry;
f0105891:	0f b7 73 22          	movzwl 0x22(%ebx),%esi
f0105895:	83 c4 10             	add    $0x10,%esp
	if ((conf = mpconfig(&mp)) == 0)
		return;
	ismp = 1;
	lapicaddr = conf->lapicaddr;

	for (p = conf->entries, i = 0; i < conf->entry; i++) {
f0105898:	83 c6 01             	add    $0x1,%esi
f010589b:	0f b7 43 22          	movzwl 0x22(%ebx),%eax
f010589f:	39 c6                	cmp    %eax,%esi
f01058a1:	0f 82 6f ff ff ff    	jb     f0105816 <mp_init+0x1d6>
			ismp = 0;
			i = conf->entry;
		}
	}

	bootcpu->cpu_status = CPU_STARTED;
f01058a7:	a1 e0 e3 1d f0       	mov    0xf01de3e0,%eax
f01058ac:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
	if (!ismp) {
f01058b3:	83 3d 00 e0 1d f0 00 	cmpl   $0x0,0xf01de000
f01058ba:	75 26                	jne    f01058e2 <mp_init+0x2a2>
		// Didn't like what we found; fall back to no MP.
		ncpu = 1;
f01058bc:	c7 05 e4 e3 1d f0 01 	movl   $0x1,0xf01de3e4
f01058c3:	00 00 00 
		lapicaddr = 0;
f01058c6:	c7 05 00 f0 21 f0 00 	movl   $0x0,0xf021f000
f01058cd:	00 00 00 
		cprintf("SMP: configuration not found, SMP disabled\n");
f01058d0:	83 ec 0c             	sub    $0xc,%esp
f01058d3:	68 d0 7c 10 f0       	push   $0xf0107cd0
f01058d8:	e8 32 df ff ff       	call   f010380f <cprintf>
		return;
f01058dd:	83 c4 10             	add    $0x10,%esp
f01058e0:	eb 45                	jmp    f0105927 <mp_init+0x2e7>
	}
	cprintf("SMP: CPU %d found %d CPU(s)\n", bootcpu->cpu_id,  ncpu);
f01058e2:	83 ec 04             	sub    $0x4,%esp
f01058e5:	ff 35 e4 e3 1d f0    	pushl  0xf01de3e4
f01058eb:	0f b6 00             	movzbl (%eax),%eax
f01058ee:	50                   	push   %eax
f01058ef:	68 57 7d 10 f0       	push   $0xf0107d57
f01058f4:	e8 16 df ff ff       	call   f010380f <cprintf>

	if (mp->imcrp) {
f01058f9:	83 c4 10             	add    $0x10,%esp
f01058fc:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01058ff:	80 78 0c 00          	cmpb   $0x0,0xc(%eax)
f0105903:	74 22                	je     f0105927 <mp_init+0x2e7>
		// [MP 3.2.6.1] If the hardware implements PIC mode,
		// switch to getting interrupts from the LAPIC.
		cprintf("SMP: Setting IMCR to switch from PIC mode to symmetric I/O mode\n");
f0105905:	83 ec 0c             	sub    $0xc,%esp
f0105908:	68 fc 7c 10 f0       	push   $0xf0107cfc
f010590d:	e8 fd de ff ff       	call   f010380f <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105912:	ba 22 00 00 00       	mov    $0x22,%edx
f0105917:	b8 70 00 00 00       	mov    $0x70,%eax
f010591c:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010591d:	b2 23                	mov    $0x23,%dl
f010591f:	ec                   	in     (%dx),%al
		outb(0x22, 0x70);   // Select IMCR
		outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
f0105920:	83 c8 01             	or     $0x1,%eax
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0105923:	ee                   	out    %al,(%dx)
f0105924:	83 c4 10             	add    $0x10,%esp
	}
}
f0105927:	8d 65 f4             	lea    -0xc(%ebp),%esp
f010592a:	5b                   	pop    %ebx
f010592b:	5e                   	pop    %esi
f010592c:	5f                   	pop    %edi
f010592d:	5d                   	pop    %ebp
f010592e:	c3                   	ret    

f010592f <lapicw>:
physaddr_t lapicaddr;        // Initialized in mpconfig.c
volatile uint32_t *lapic;

static void
lapicw(int index, int value)
{
f010592f:	55                   	push   %ebp
f0105930:	89 e5                	mov    %esp,%ebp
	lapic[index] = value;
f0105932:	8b 0d 04 f0 21 f0    	mov    0xf021f004,%ecx
f0105938:	8d 04 81             	lea    (%ecx,%eax,4),%eax
f010593b:	89 10                	mov    %edx,(%eax)
	lapic[ID];  // wait for write to finish, by reading
f010593d:	a1 04 f0 21 f0       	mov    0xf021f004,%eax
f0105942:	8b 40 20             	mov    0x20(%eax),%eax
}
f0105945:	5d                   	pop    %ebp
f0105946:	c3                   	ret    

f0105947 <cpunum>:
	lapicw(TPR, 0);
}

int
cpunum(void)
{
f0105947:	55                   	push   %ebp
f0105948:	89 e5                	mov    %esp,%ebp
	if (lapic)
f010594a:	a1 04 f0 21 f0       	mov    0xf021f004,%eax
f010594f:	85 c0                	test   %eax,%eax
f0105951:	74 08                	je     f010595b <cpunum+0x14>
		return lapic[ID] >> 24;
f0105953:	8b 40 20             	mov    0x20(%eax),%eax
f0105956:	c1 e8 18             	shr    $0x18,%eax
f0105959:	eb 05                	jmp    f0105960 <cpunum+0x19>
	return 0;
f010595b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0105960:	5d                   	pop    %ebp
f0105961:	c3                   	ret    

f0105962 <lapic_init>:
}

void
lapic_init(void)
{
	if (!lapicaddr)
f0105962:	a1 00 f0 21 f0       	mov    0xf021f000,%eax
f0105967:	85 c0                	test   %eax,%eax
f0105969:	0f 84 21 01 00 00    	je     f0105a90 <lapic_init+0x12e>
	lapic[ID];  // wait for write to finish, by reading
}

void
lapic_init(void)
{
f010596f:	55                   	push   %ebp
f0105970:	89 e5                	mov    %esp,%ebp
f0105972:	83 ec 10             	sub    $0x10,%esp
	if (!lapicaddr)
		return;

	// lapicaddr is the physical address of the LAPIC's 4K MMIO
	// region.  Map it in to virtual memory so we can access it.
	lapic = mmio_map_region(lapicaddr, 4096);
f0105975:	68 00 10 00 00       	push   $0x1000
f010597a:	50                   	push   %eax
f010597b:	e8 27 ba ff ff       	call   f01013a7 <mmio_map_region>
f0105980:	a3 04 f0 21 f0       	mov    %eax,0xf021f004

	// Enable local APIC; set spurious interrupt vector.
	lapicw(SVR, ENABLE | (IRQ_OFFSET + IRQ_SPURIOUS));
f0105985:	ba 27 01 00 00       	mov    $0x127,%edx
f010598a:	b8 3c 00 00 00       	mov    $0x3c,%eax
f010598f:	e8 9b ff ff ff       	call   f010592f <lapicw>

	// The timer repeatedly counts down at bus frequency
	// from lapic[TICR] and then issues an interrupt.  
	// If we cared more about precise timekeeping,
	// TICR would be calibrated using an external time source.
	lapicw(TDCR, X1);
f0105994:	ba 0b 00 00 00       	mov    $0xb,%edx
f0105999:	b8 f8 00 00 00       	mov    $0xf8,%eax
f010599e:	e8 8c ff ff ff       	call   f010592f <lapicw>
	lapicw(TIMER, PERIODIC | (IRQ_OFFSET + IRQ_TIMER));
f01059a3:	ba 20 00 02 00       	mov    $0x20020,%edx
f01059a8:	b8 c8 00 00 00       	mov    $0xc8,%eax
f01059ad:	e8 7d ff ff ff       	call   f010592f <lapicw>
	lapicw(TICR, 10000000); 
f01059b2:	ba 80 96 98 00       	mov    $0x989680,%edx
f01059b7:	b8 e0 00 00 00       	mov    $0xe0,%eax
f01059bc:	e8 6e ff ff ff       	call   f010592f <lapicw>
	//
	// According to Intel MP Specification, the BIOS should initialize
	// BSP's local APIC in Virtual Wire Mode, in which 8259A's
	// INTR is virtually connected to BSP's LINTIN0. In this mode,
	// we do not need to program the IOAPIC.
	if (thiscpu != bootcpu)
f01059c1:	e8 81 ff ff ff       	call   f0105947 <cpunum>
f01059c6:	6b c0 74             	imul   $0x74,%eax,%eax
f01059c9:	05 40 e0 1d f0       	add    $0xf01de040,%eax
f01059ce:	83 c4 10             	add    $0x10,%esp
f01059d1:	39 05 e0 e3 1d f0    	cmp    %eax,0xf01de3e0
f01059d7:	74 0f                	je     f01059e8 <lapic_init+0x86>
		lapicw(LINT0, MASKED);
f01059d9:	ba 00 00 01 00       	mov    $0x10000,%edx
f01059de:	b8 d4 00 00 00       	mov    $0xd4,%eax
f01059e3:	e8 47 ff ff ff       	call   f010592f <lapicw>

	// Disable NMI (LINT1) on all CPUs
	lapicw(LINT1, MASKED);
f01059e8:	ba 00 00 01 00       	mov    $0x10000,%edx
f01059ed:	b8 d8 00 00 00       	mov    $0xd8,%eax
f01059f2:	e8 38 ff ff ff       	call   f010592f <lapicw>

	// Disable performance counter overflow interrupts
	// on machines that provide that interrupt entry.
	if (((lapic[VER]>>16) & 0xFF) >= 4)
f01059f7:	a1 04 f0 21 f0       	mov    0xf021f004,%eax
f01059fc:	8b 40 30             	mov    0x30(%eax),%eax
f01059ff:	c1 e8 10             	shr    $0x10,%eax
f0105a02:	3c 03                	cmp    $0x3,%al
f0105a04:	76 0f                	jbe    f0105a15 <lapic_init+0xb3>
		lapicw(PCINT, MASKED);
f0105a06:	ba 00 00 01 00       	mov    $0x10000,%edx
f0105a0b:	b8 d0 00 00 00       	mov    $0xd0,%eax
f0105a10:	e8 1a ff ff ff       	call   f010592f <lapicw>

	// Map error interrupt to IRQ_ERROR.
	lapicw(ERROR, IRQ_OFFSET + IRQ_ERROR);
f0105a15:	ba 33 00 00 00       	mov    $0x33,%edx
f0105a1a:	b8 dc 00 00 00       	mov    $0xdc,%eax
f0105a1f:	e8 0b ff ff ff       	call   f010592f <lapicw>

	// Clear error status register (requires back-to-back writes).
	lapicw(ESR, 0);
f0105a24:	ba 00 00 00 00       	mov    $0x0,%edx
f0105a29:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105a2e:	e8 fc fe ff ff       	call   f010592f <lapicw>
	lapicw(ESR, 0);
f0105a33:	ba 00 00 00 00       	mov    $0x0,%edx
f0105a38:	b8 a0 00 00 00       	mov    $0xa0,%eax
f0105a3d:	e8 ed fe ff ff       	call   f010592f <lapicw>

	// Ack any outstanding interrupts.
	lapicw(EOI, 0);
f0105a42:	ba 00 00 00 00       	mov    $0x0,%edx
f0105a47:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105a4c:	e8 de fe ff ff       	call   f010592f <lapicw>

	// Send an Init Level De-Assert to synchronize arbitration ID's.
	lapicw(ICRHI, 0);
f0105a51:	ba 00 00 00 00       	mov    $0x0,%edx
f0105a56:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105a5b:	e8 cf fe ff ff       	call   f010592f <lapicw>
	lapicw(ICRLO, BCAST | INIT | LEVEL);
f0105a60:	ba 00 85 08 00       	mov    $0x88500,%edx
f0105a65:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105a6a:	e8 c0 fe ff ff       	call   f010592f <lapicw>
	while(lapic[ICRLO] & DELIVS)
f0105a6f:	8b 15 04 f0 21 f0    	mov    0xf021f004,%edx
f0105a75:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105a7b:	f6 c4 10             	test   $0x10,%ah
f0105a7e:	75 f5                	jne    f0105a75 <lapic_init+0x113>
		;

	// Enable interrupts on the APIC (but not on the processor).
	lapicw(TPR, 0);
f0105a80:	ba 00 00 00 00       	mov    $0x0,%edx
f0105a85:	b8 20 00 00 00       	mov    $0x20,%eax
f0105a8a:	e8 a0 fe ff ff       	call   f010592f <lapicw>
}
f0105a8f:	c9                   	leave  
f0105a90:	f3 c3                	repz ret 

f0105a92 <lapic_eoi>:

// Acknowledge interrupt.
void
lapic_eoi(void)
{
	if (lapic)
f0105a92:	83 3d 04 f0 21 f0 00 	cmpl   $0x0,0xf021f004
f0105a99:	74 13                	je     f0105aae <lapic_eoi+0x1c>
}

// Acknowledge interrupt.
void
lapic_eoi(void)
{
f0105a9b:	55                   	push   %ebp
f0105a9c:	89 e5                	mov    %esp,%ebp
	if (lapic)
		lapicw(EOI, 0);
f0105a9e:	ba 00 00 00 00       	mov    $0x0,%edx
f0105aa3:	b8 2c 00 00 00       	mov    $0x2c,%eax
f0105aa8:	e8 82 fe ff ff       	call   f010592f <lapicw>
}
f0105aad:	5d                   	pop    %ebp
f0105aae:	f3 c3                	repz ret 

f0105ab0 <lapic_startap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapic_startap(uint8_t apicid, uint32_t addr)
{
f0105ab0:	55                   	push   %ebp
f0105ab1:	89 e5                	mov    %esp,%ebp
f0105ab3:	56                   	push   %esi
f0105ab4:	53                   	push   %ebx
f0105ab5:	8b 75 08             	mov    0x8(%ebp),%esi
f0105ab8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0105abb:	ba 70 00 00 00       	mov    $0x70,%edx
f0105ac0:	b8 0f 00 00 00       	mov    $0xf,%eax
f0105ac5:	ee                   	out    %al,(%dx)
f0105ac6:	b2 71                	mov    $0x71,%dl
f0105ac8:	b8 0a 00 00 00       	mov    $0xa,%eax
f0105acd:	ee                   	out    %al,(%dx)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0105ace:	83 3d c8 de 1d f0 00 	cmpl   $0x0,0xf01ddec8
f0105ad5:	75 19                	jne    f0105af0 <lapic_startap+0x40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0105ad7:	68 67 04 00 00       	push   $0x467
f0105adc:	68 24 60 10 f0       	push   $0xf0106024
f0105ae1:	68 98 00 00 00       	push   $0x98
f0105ae6:	68 74 7d 10 f0       	push   $0xf0107d74
f0105aeb:	e8 50 a5 ff ff       	call   f0100040 <_panic>
	// and the warm reset vector (DWORD based at 40:67) to point at
	// the AP startup code prior to the [universal startup algorithm]."
	outb(IO_RTC, 0xF);  // offset 0xF is shutdown code
	outb(IO_RTC+1, 0x0A);
	wrv = (uint16_t *)KADDR((0x40 << 4 | 0x67));  // Warm reset vector
	wrv[0] = 0;
f0105af0:	66 c7 05 67 04 00 f0 	movw   $0x0,0xf0000467
f0105af7:	00 00 
	wrv[1] = addr >> 4;
f0105af9:	89 d8                	mov    %ebx,%eax
f0105afb:	c1 e8 04             	shr    $0x4,%eax
f0105afe:	66 a3 69 04 00 f0    	mov    %ax,0xf0000469

	// "Universal startup algorithm."
	// Send INIT (level-triggered) interrupt to reset other CPU.
	lapicw(ICRHI, apicid << 24);
f0105b04:	c1 e6 18             	shl    $0x18,%esi
f0105b07:	89 f2                	mov    %esi,%edx
f0105b09:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b0e:	e8 1c fe ff ff       	call   f010592f <lapicw>
	lapicw(ICRLO, INIT | LEVEL | ASSERT);
f0105b13:	ba 00 c5 00 00       	mov    $0xc500,%edx
f0105b18:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b1d:	e8 0d fe ff ff       	call   f010592f <lapicw>
	microdelay(200);
	lapicw(ICRLO, INIT | LEVEL);
f0105b22:	ba 00 85 00 00       	mov    $0x8500,%edx
f0105b27:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b2c:	e8 fe fd ff ff       	call   f010592f <lapicw>
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105b31:	c1 eb 0c             	shr    $0xc,%ebx
f0105b34:	80 cf 06             	or     $0x6,%bh
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105b37:	89 f2                	mov    %esi,%edx
f0105b39:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b3e:	e8 ec fd ff ff       	call   f010592f <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105b43:	89 da                	mov    %ebx,%edx
f0105b45:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b4a:	e8 e0 fd ff ff       	call   f010592f <lapicw>
	// Regular hardware is supposed to only accept a STARTUP
	// when it is in the halted state due to an INIT.  So the second
	// should be ignored, but it is part of the official Intel algorithm.
	// Bochs complains about the second one.  Too bad for Bochs.
	for (i = 0; i < 2; i++) {
		lapicw(ICRHI, apicid << 24);
f0105b4f:	89 f2                	mov    %esi,%edx
f0105b51:	b8 c4 00 00 00       	mov    $0xc4,%eax
f0105b56:	e8 d4 fd ff ff       	call   f010592f <lapicw>
		lapicw(ICRLO, STARTUP | (addr >> 12));
f0105b5b:	89 da                	mov    %ebx,%edx
f0105b5d:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b62:	e8 c8 fd ff ff       	call   f010592f <lapicw>
		microdelay(200);
	}
}
f0105b67:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105b6a:	5b                   	pop    %ebx
f0105b6b:	5e                   	pop    %esi
f0105b6c:	5d                   	pop    %ebp
f0105b6d:	c3                   	ret    

f0105b6e <lapic_ipi>:

void
lapic_ipi(int vector)
{
f0105b6e:	55                   	push   %ebp
f0105b6f:	89 e5                	mov    %esp,%ebp
	lapicw(ICRLO, OTHERS | FIXED | vector);
f0105b71:	8b 55 08             	mov    0x8(%ebp),%edx
f0105b74:	81 ca 00 00 0c 00    	or     $0xc0000,%edx
f0105b7a:	b8 c0 00 00 00       	mov    $0xc0,%eax
f0105b7f:	e8 ab fd ff ff       	call   f010592f <lapicw>
	while (lapic[ICRLO] & DELIVS)
f0105b84:	8b 15 04 f0 21 f0    	mov    0xf021f004,%edx
f0105b8a:	8b 82 00 03 00 00    	mov    0x300(%edx),%eax
f0105b90:	f6 c4 10             	test   $0x10,%ah
f0105b93:	75 f5                	jne    f0105b8a <lapic_ipi+0x1c>
		;
}
f0105b95:	5d                   	pop    %ebp
f0105b96:	c3                   	ret    

f0105b97 <__spin_initlock>:
}
#endif

void
__spin_initlock(struct spinlock *lk, char *name)
{
f0105b97:	55                   	push   %ebp
f0105b98:	89 e5                	mov    %esp,%ebp
f0105b9a:	8b 45 08             	mov    0x8(%ebp),%eax
	lk->locked = 0;
f0105b9d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
#ifdef DEBUG_SPINLOCK
	lk->name = name;
f0105ba3:	8b 55 0c             	mov    0xc(%ebp),%edx
f0105ba6:	89 50 04             	mov    %edx,0x4(%eax)
	lk->cpu = 0;
f0105ba9:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
#endif
}
f0105bb0:	5d                   	pop    %ebp
f0105bb1:	c3                   	ret    

f0105bb2 <spin_lock>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
f0105bb2:	55                   	push   %ebp
f0105bb3:	89 e5                	mov    %esp,%ebp
f0105bb5:	56                   	push   %esi
f0105bb6:	53                   	push   %ebx
f0105bb7:	8b 5d 08             	mov    0x8(%ebp),%ebx

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105bba:	83 3b 00             	cmpl   $0x0,(%ebx)
f0105bbd:	74 14                	je     f0105bd3 <spin_lock+0x21>
f0105bbf:	8b 73 08             	mov    0x8(%ebx),%esi
f0105bc2:	e8 80 fd ff ff       	call   f0105947 <cpunum>
f0105bc7:	6b c0 74             	imul   $0x74,%eax,%eax
f0105bca:	05 40 e0 1d f0       	add    $0xf01de040,%eax
// other CPUs to waste time spinning to acquire it.
void
spin_lock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (holding(lk))
f0105bcf:	39 c6                	cmp    %eax,%esi
f0105bd1:	74 07                	je     f0105bda <spin_lock+0x28>
xchg(volatile uint32_t *addr, uint32_t newval)
{
	uint32_t result;

	// The + in "+m" denotes a read-modify-write operand.
	asm volatile("lock; xchgl %0, %1" :
f0105bd3:	ba 01 00 00 00       	mov    $0x1,%edx
f0105bd8:	eb 20                	jmp    f0105bfa <spin_lock+0x48>
		panic("CPU %d cannot acquire %s: already holding", cpunum(), lk->name);
f0105bda:	8b 5b 04             	mov    0x4(%ebx),%ebx
f0105bdd:	e8 65 fd ff ff       	call   f0105947 <cpunum>
f0105be2:	83 ec 0c             	sub    $0xc,%esp
f0105be5:	53                   	push   %ebx
f0105be6:	50                   	push   %eax
f0105be7:	68 84 7d 10 f0       	push   $0xf0107d84
f0105bec:	6a 41                	push   $0x41
f0105bee:	68 e8 7d 10 f0       	push   $0xf0107de8
f0105bf3:	e8 48 a4 ff ff       	call   f0100040 <_panic>

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
		asm volatile ("pause");
f0105bf8:	f3 90                	pause  
f0105bfa:	89 d0                	mov    %edx,%eax
f0105bfc:	f0 87 03             	lock xchg %eax,(%ebx)
#endif

	// The xchg is atomic.
	// It also serializes, so that reads after acquire are not
	// reordered before it. 
	while (xchg(&lk->locked, 1) != 0)
f0105bff:	85 c0                	test   %eax,%eax
f0105c01:	75 f5                	jne    f0105bf8 <spin_lock+0x46>
		asm volatile ("pause");

	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
f0105c03:	e8 3f fd ff ff       	call   f0105947 <cpunum>
f0105c08:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c0b:	05 40 e0 1d f0       	add    $0xf01de040,%eax
f0105c10:	89 43 08             	mov    %eax,0x8(%ebx)
	get_caller_pcs(lk->pcs);
f0105c13:	83 c3 0c             	add    $0xc,%ebx
get_caller_pcs(uint32_t pcs[])
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
f0105c16:	89 ea                	mov    %ebp,%edx
	for (i = 0; i < 10; i++){
f0105c18:	b8 00 00 00 00       	mov    $0x0,%eax
f0105c1d:	eb 0b                	jmp    f0105c2a <spin_lock+0x78>
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
f0105c1f:	8b 4a 04             	mov    0x4(%edx),%ecx
f0105c22:	89 0c 83             	mov    %ecx,(%ebx,%eax,4)
		ebp = (uint32_t *)ebp[0]; // saved %ebp
f0105c25:	8b 12                	mov    (%edx),%edx
{
	uint32_t *ebp;
	int i;

	ebp = (uint32_t *)read_ebp();
	for (i = 0; i < 10; i++){
f0105c27:	83 c0 01             	add    $0x1,%eax
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
f0105c2a:	83 f8 09             	cmp    $0x9,%eax
f0105c2d:	7f 14                	jg     f0105c43 <spin_lock+0x91>
f0105c2f:	81 fa ff ff 7f ef    	cmp    $0xef7fffff,%edx
f0105c35:	77 e8                	ja     f0105c1f <spin_lock+0x6d>
f0105c37:	eb 0a                	jmp    f0105c43 <spin_lock+0x91>
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
		pcs[i] = 0;
f0105c39:	c7 04 83 00 00 00 00 	movl   $0x0,(%ebx,%eax,4)
		if (ebp == 0 || ebp < (uint32_t *)ULIM)
			break;
		pcs[i] = ebp[1];          // saved %eip
		ebp = (uint32_t *)ebp[0]; // saved %ebp
	}
	for (; i < 10; i++)
f0105c40:	83 c0 01             	add    $0x1,%eax
f0105c43:	83 f8 09             	cmp    $0x9,%eax
f0105c46:	7e f1                	jle    f0105c39 <spin_lock+0x87>
	// Record info about lock acquisition for debugging.
#ifdef DEBUG_SPINLOCK
	lk->cpu = thiscpu;
	get_caller_pcs(lk->pcs);
#endif
}
f0105c48:	8d 65 f8             	lea    -0x8(%ebp),%esp
f0105c4b:	5b                   	pop    %ebx
f0105c4c:	5e                   	pop    %esi
f0105c4d:	5d                   	pop    %ebp
f0105c4e:	c3                   	ret    

f0105c4f <spin_unlock>:

// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
f0105c4f:	55                   	push   %ebp
f0105c50:	89 e5                	mov    %esp,%ebp
f0105c52:	57                   	push   %edi
f0105c53:	56                   	push   %esi
f0105c54:	53                   	push   %ebx
f0105c55:	83 ec 4c             	sub    $0x4c,%esp
f0105c58:	8b 75 08             	mov    0x8(%ebp),%esi

// Check whether this CPU is holding the lock.
static int
holding(struct spinlock *lock)
{
	return lock->locked && lock->cpu == thiscpu;
f0105c5b:	83 3e 00             	cmpl   $0x0,(%esi)
f0105c5e:	74 18                	je     f0105c78 <spin_unlock+0x29>
f0105c60:	8b 5e 08             	mov    0x8(%esi),%ebx
f0105c63:	e8 df fc ff ff       	call   f0105947 <cpunum>
f0105c68:	6b c0 74             	imul   $0x74,%eax,%eax
f0105c6b:	05 40 e0 1d f0       	add    $0xf01de040,%eax
// Release the lock.
void
spin_unlock(struct spinlock *lk)
{
#ifdef DEBUG_SPINLOCK
	if (!holding(lk)) {
f0105c70:	39 c3                	cmp    %eax,%ebx
f0105c72:	0f 84 a5 00 00 00    	je     f0105d1d <spin_unlock+0xce>
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
f0105c78:	83 ec 04             	sub    $0x4,%esp
f0105c7b:	6a 28                	push   $0x28
f0105c7d:	8d 46 0c             	lea    0xc(%esi),%eax
f0105c80:	50                   	push   %eax
f0105c81:	8d 5d c0             	lea    -0x40(%ebp),%ebx
f0105c84:	53                   	push   %ebx
f0105c85:	e8 e6 f6 ff ff       	call   f0105370 <memmove>
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
f0105c8a:	8b 46 08             	mov    0x8(%esi),%eax
	if (!holding(lk)) {
		int i;
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
f0105c8d:	0f b6 38             	movzbl (%eax),%edi
f0105c90:	8b 76 04             	mov    0x4(%esi),%esi
f0105c93:	e8 af fc ff ff       	call   f0105947 <cpunum>
f0105c98:	57                   	push   %edi
f0105c99:	56                   	push   %esi
f0105c9a:	50                   	push   %eax
f0105c9b:	68 b0 7d 10 f0       	push   $0xf0107db0
f0105ca0:	e8 6a db ff ff       	call   f010380f <cprintf>
f0105ca5:	83 c4 20             	add    $0x20,%esp
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
f0105ca8:	8d 7d a8             	lea    -0x58(%ebp),%edi
f0105cab:	eb 54                	jmp    f0105d01 <spin_unlock+0xb2>
f0105cad:	83 ec 08             	sub    $0x8,%esp
f0105cb0:	57                   	push   %edi
f0105cb1:	50                   	push   %eax
f0105cb2:	e8 d6 eb ff ff       	call   f010488d <debuginfo_eip>
f0105cb7:	83 c4 10             	add    $0x10,%esp
f0105cba:	85 c0                	test   %eax,%eax
f0105cbc:	78 27                	js     f0105ce5 <spin_unlock+0x96>
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
f0105cbe:	8b 06                	mov    (%esi),%eax
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
			struct Eipdebuginfo info;
			if (debuginfo_eip(pcs[i], &info) >= 0)
				cprintf("  %08x %s:%d: %.*s+%x\n", pcs[i],
f0105cc0:	83 ec 04             	sub    $0x4,%esp
f0105cc3:	89 c2                	mov    %eax,%edx
f0105cc5:	2b 55 b8             	sub    -0x48(%ebp),%edx
f0105cc8:	52                   	push   %edx
f0105cc9:	ff 75 b0             	pushl  -0x50(%ebp)
f0105ccc:	ff 75 b4             	pushl  -0x4c(%ebp)
f0105ccf:	ff 75 ac             	pushl  -0x54(%ebp)
f0105cd2:	ff 75 a8             	pushl  -0x58(%ebp)
f0105cd5:	50                   	push   %eax
f0105cd6:	68 f8 7d 10 f0       	push   $0xf0107df8
f0105cdb:	e8 2f db ff ff       	call   f010380f <cprintf>
f0105ce0:	83 c4 20             	add    $0x20,%esp
f0105ce3:	eb 12                	jmp    f0105cf7 <spin_unlock+0xa8>
					info.eip_file, info.eip_line,
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
f0105ce5:	83 ec 08             	sub    $0x8,%esp
f0105ce8:	ff 36                	pushl  (%esi)
f0105cea:	68 0f 7e 10 f0       	push   $0xf0107e0f
f0105cef:	e8 1b db ff ff       	call   f010380f <cprintf>
f0105cf4:	83 c4 10             	add    $0x10,%esp
f0105cf7:	83 c3 04             	add    $0x4,%ebx
		uint32_t pcs[10];
		// Nab the acquiring EIP chain before it gets released
		memmove(pcs, lk->pcs, sizeof pcs);
		cprintf("CPU %d cannot release %s: held by CPU %d\nAcquired at:", 
			cpunum(), lk->name, lk->cpu->cpu_id);
		for (i = 0; i < 10 && pcs[i]; i++) {
f0105cfa:	8d 45 e8             	lea    -0x18(%ebp),%eax
f0105cfd:	39 c3                	cmp    %eax,%ebx
f0105cff:	74 08                	je     f0105d09 <spin_unlock+0xba>
f0105d01:	89 de                	mov    %ebx,%esi
f0105d03:	8b 03                	mov    (%ebx),%eax
f0105d05:	85 c0                	test   %eax,%eax
f0105d07:	75 a4                	jne    f0105cad <spin_unlock+0x5e>
					info.eip_fn_namelen, info.eip_fn_name,
					pcs[i] - info.eip_fn_addr);
			else
				cprintf("  %08x\n", pcs[i]);
		}
		panic("spin_unlock");
f0105d09:	83 ec 04             	sub    $0x4,%esp
f0105d0c:	68 17 7e 10 f0       	push   $0xf0107e17
f0105d11:	6a 67                	push   $0x67
f0105d13:	68 e8 7d 10 f0       	push   $0xf0107de8
f0105d18:	e8 23 a3 ff ff       	call   f0100040 <_panic>
	}

	lk->pcs[0] = 0;
f0105d1d:	c7 46 0c 00 00 00 00 	movl   $0x0,0xc(%esi)
	lk->cpu = 0;
f0105d24:	c7 46 08 00 00 00 00 	movl   $0x0,0x8(%esi)
f0105d2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0105d30:	f0 87 06             	lock xchg %eax,(%esi)
	// Paper says that Intel 64 and IA-32 will not move a load
	// after a store. So lock->locked = 0 would work here.
	// The xchg being asm volatile ensures gcc emits it after
	// the above assignments (and after the critical section).
	xchg(&lk->locked, 0);
}
f0105d33:	8d 65 f4             	lea    -0xc(%ebp),%esp
f0105d36:	5b                   	pop    %ebx
f0105d37:	5e                   	pop    %esi
f0105d38:	5f                   	pop    %edi
f0105d39:	5d                   	pop    %ebp
f0105d3a:	c3                   	ret    
f0105d3b:	66 90                	xchg   %ax,%ax
f0105d3d:	66 90                	xchg   %ax,%ax
f0105d3f:	90                   	nop

f0105d40 <__udivdi3>:
f0105d40:	55                   	push   %ebp
f0105d41:	57                   	push   %edi
f0105d42:	56                   	push   %esi
f0105d43:	83 ec 10             	sub    $0x10,%esp
f0105d46:	8b 54 24 2c          	mov    0x2c(%esp),%edx
f0105d4a:	8b 7c 24 20          	mov    0x20(%esp),%edi
f0105d4e:	8b 74 24 24          	mov    0x24(%esp),%esi
f0105d52:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0105d56:	85 d2                	test   %edx,%edx
f0105d58:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0105d5c:	89 34 24             	mov    %esi,(%esp)
f0105d5f:	89 c8                	mov    %ecx,%eax
f0105d61:	75 35                	jne    f0105d98 <__udivdi3+0x58>
f0105d63:	39 f1                	cmp    %esi,%ecx
f0105d65:	0f 87 bd 00 00 00    	ja     f0105e28 <__udivdi3+0xe8>
f0105d6b:	85 c9                	test   %ecx,%ecx
f0105d6d:	89 cd                	mov    %ecx,%ebp
f0105d6f:	75 0b                	jne    f0105d7c <__udivdi3+0x3c>
f0105d71:	b8 01 00 00 00       	mov    $0x1,%eax
f0105d76:	31 d2                	xor    %edx,%edx
f0105d78:	f7 f1                	div    %ecx
f0105d7a:	89 c5                	mov    %eax,%ebp
f0105d7c:	89 f0                	mov    %esi,%eax
f0105d7e:	31 d2                	xor    %edx,%edx
f0105d80:	f7 f5                	div    %ebp
f0105d82:	89 c6                	mov    %eax,%esi
f0105d84:	89 f8                	mov    %edi,%eax
f0105d86:	f7 f5                	div    %ebp
f0105d88:	89 f2                	mov    %esi,%edx
f0105d8a:	83 c4 10             	add    $0x10,%esp
f0105d8d:	5e                   	pop    %esi
f0105d8e:	5f                   	pop    %edi
f0105d8f:	5d                   	pop    %ebp
f0105d90:	c3                   	ret    
f0105d91:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105d98:	3b 14 24             	cmp    (%esp),%edx
f0105d9b:	77 7b                	ja     f0105e18 <__udivdi3+0xd8>
f0105d9d:	0f bd f2             	bsr    %edx,%esi
f0105da0:	83 f6 1f             	xor    $0x1f,%esi
f0105da3:	0f 84 97 00 00 00    	je     f0105e40 <__udivdi3+0x100>
f0105da9:	bd 20 00 00 00       	mov    $0x20,%ebp
f0105dae:	89 d7                	mov    %edx,%edi
f0105db0:	89 f1                	mov    %esi,%ecx
f0105db2:	29 f5                	sub    %esi,%ebp
f0105db4:	d3 e7                	shl    %cl,%edi
f0105db6:	89 c2                	mov    %eax,%edx
f0105db8:	89 e9                	mov    %ebp,%ecx
f0105dba:	d3 ea                	shr    %cl,%edx
f0105dbc:	89 f1                	mov    %esi,%ecx
f0105dbe:	09 fa                	or     %edi,%edx
f0105dc0:	8b 3c 24             	mov    (%esp),%edi
f0105dc3:	d3 e0                	shl    %cl,%eax
f0105dc5:	89 54 24 08          	mov    %edx,0x8(%esp)
f0105dc9:	89 e9                	mov    %ebp,%ecx
f0105dcb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105dcf:	8b 44 24 04          	mov    0x4(%esp),%eax
f0105dd3:	89 fa                	mov    %edi,%edx
f0105dd5:	d3 ea                	shr    %cl,%edx
f0105dd7:	89 f1                	mov    %esi,%ecx
f0105dd9:	d3 e7                	shl    %cl,%edi
f0105ddb:	89 e9                	mov    %ebp,%ecx
f0105ddd:	d3 e8                	shr    %cl,%eax
f0105ddf:	09 c7                	or     %eax,%edi
f0105de1:	89 f8                	mov    %edi,%eax
f0105de3:	f7 74 24 08          	divl   0x8(%esp)
f0105de7:	89 d5                	mov    %edx,%ebp
f0105de9:	89 c7                	mov    %eax,%edi
f0105deb:	f7 64 24 0c          	mull   0xc(%esp)
f0105def:	39 d5                	cmp    %edx,%ebp
f0105df1:	89 14 24             	mov    %edx,(%esp)
f0105df4:	72 11                	jb     f0105e07 <__udivdi3+0xc7>
f0105df6:	8b 54 24 04          	mov    0x4(%esp),%edx
f0105dfa:	89 f1                	mov    %esi,%ecx
f0105dfc:	d3 e2                	shl    %cl,%edx
f0105dfe:	39 c2                	cmp    %eax,%edx
f0105e00:	73 5e                	jae    f0105e60 <__udivdi3+0x120>
f0105e02:	3b 2c 24             	cmp    (%esp),%ebp
f0105e05:	75 59                	jne    f0105e60 <__udivdi3+0x120>
f0105e07:	8d 47 ff             	lea    -0x1(%edi),%eax
f0105e0a:	31 f6                	xor    %esi,%esi
f0105e0c:	89 f2                	mov    %esi,%edx
f0105e0e:	83 c4 10             	add    $0x10,%esp
f0105e11:	5e                   	pop    %esi
f0105e12:	5f                   	pop    %edi
f0105e13:	5d                   	pop    %ebp
f0105e14:	c3                   	ret    
f0105e15:	8d 76 00             	lea    0x0(%esi),%esi
f0105e18:	31 f6                	xor    %esi,%esi
f0105e1a:	31 c0                	xor    %eax,%eax
f0105e1c:	89 f2                	mov    %esi,%edx
f0105e1e:	83 c4 10             	add    $0x10,%esp
f0105e21:	5e                   	pop    %esi
f0105e22:	5f                   	pop    %edi
f0105e23:	5d                   	pop    %ebp
f0105e24:	c3                   	ret    
f0105e25:	8d 76 00             	lea    0x0(%esi),%esi
f0105e28:	89 f2                	mov    %esi,%edx
f0105e2a:	31 f6                	xor    %esi,%esi
f0105e2c:	89 f8                	mov    %edi,%eax
f0105e2e:	f7 f1                	div    %ecx
f0105e30:	89 f2                	mov    %esi,%edx
f0105e32:	83 c4 10             	add    $0x10,%esp
f0105e35:	5e                   	pop    %esi
f0105e36:	5f                   	pop    %edi
f0105e37:	5d                   	pop    %ebp
f0105e38:	c3                   	ret    
f0105e39:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0105e40:	3b 4c 24 04          	cmp    0x4(%esp),%ecx
f0105e44:	76 0b                	jbe    f0105e51 <__udivdi3+0x111>
f0105e46:	31 c0                	xor    %eax,%eax
f0105e48:	3b 14 24             	cmp    (%esp),%edx
f0105e4b:	0f 83 37 ff ff ff    	jae    f0105d88 <__udivdi3+0x48>
f0105e51:	b8 01 00 00 00       	mov    $0x1,%eax
f0105e56:	e9 2d ff ff ff       	jmp    f0105d88 <__udivdi3+0x48>
f0105e5b:	90                   	nop
f0105e5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105e60:	89 f8                	mov    %edi,%eax
f0105e62:	31 f6                	xor    %esi,%esi
f0105e64:	e9 1f ff ff ff       	jmp    f0105d88 <__udivdi3+0x48>
f0105e69:	66 90                	xchg   %ax,%ax
f0105e6b:	66 90                	xchg   %ax,%ax
f0105e6d:	66 90                	xchg   %ax,%ax
f0105e6f:	90                   	nop

f0105e70 <__umoddi3>:
f0105e70:	55                   	push   %ebp
f0105e71:	57                   	push   %edi
f0105e72:	56                   	push   %esi
f0105e73:	83 ec 20             	sub    $0x20,%esp
f0105e76:	8b 44 24 34          	mov    0x34(%esp),%eax
f0105e7a:	8b 4c 24 30          	mov    0x30(%esp),%ecx
f0105e7e:	8b 7c 24 38          	mov    0x38(%esp),%edi
f0105e82:	89 c6                	mov    %eax,%esi
f0105e84:	89 44 24 10          	mov    %eax,0x10(%esp)
f0105e88:	8b 44 24 3c          	mov    0x3c(%esp),%eax
f0105e8c:	89 4c 24 1c          	mov    %ecx,0x1c(%esp)
f0105e90:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0105e94:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105e98:	89 74 24 18          	mov    %esi,0x18(%esp)
f0105e9c:	85 c0                	test   %eax,%eax
f0105e9e:	89 c2                	mov    %eax,%edx
f0105ea0:	75 1e                	jne    f0105ec0 <__umoddi3+0x50>
f0105ea2:	39 f7                	cmp    %esi,%edi
f0105ea4:	76 52                	jbe    f0105ef8 <__umoddi3+0x88>
f0105ea6:	89 c8                	mov    %ecx,%eax
f0105ea8:	89 f2                	mov    %esi,%edx
f0105eaa:	f7 f7                	div    %edi
f0105eac:	89 d0                	mov    %edx,%eax
f0105eae:	31 d2                	xor    %edx,%edx
f0105eb0:	83 c4 20             	add    $0x20,%esp
f0105eb3:	5e                   	pop    %esi
f0105eb4:	5f                   	pop    %edi
f0105eb5:	5d                   	pop    %ebp
f0105eb6:	c3                   	ret    
f0105eb7:	89 f6                	mov    %esi,%esi
f0105eb9:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105ec0:	39 f0                	cmp    %esi,%eax
f0105ec2:	77 5c                	ja     f0105f20 <__umoddi3+0xb0>
f0105ec4:	0f bd e8             	bsr    %eax,%ebp
f0105ec7:	83 f5 1f             	xor    $0x1f,%ebp
f0105eca:	75 64                	jne    f0105f30 <__umoddi3+0xc0>
f0105ecc:	8b 6c 24 14          	mov    0x14(%esp),%ebp
f0105ed0:	39 6c 24 0c          	cmp    %ebp,0xc(%esp)
f0105ed4:	0f 86 f6 00 00 00    	jbe    f0105fd0 <__umoddi3+0x160>
f0105eda:	3b 44 24 18          	cmp    0x18(%esp),%eax
f0105ede:	0f 82 ec 00 00 00    	jb     f0105fd0 <__umoddi3+0x160>
f0105ee4:	8b 44 24 14          	mov    0x14(%esp),%eax
f0105ee8:	8b 54 24 18          	mov    0x18(%esp),%edx
f0105eec:	83 c4 20             	add    $0x20,%esp
f0105eef:	5e                   	pop    %esi
f0105ef0:	5f                   	pop    %edi
f0105ef1:	5d                   	pop    %ebp
f0105ef2:	c3                   	ret    
f0105ef3:	90                   	nop
f0105ef4:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105ef8:	85 ff                	test   %edi,%edi
f0105efa:	89 fd                	mov    %edi,%ebp
f0105efc:	75 0b                	jne    f0105f09 <__umoddi3+0x99>
f0105efe:	b8 01 00 00 00       	mov    $0x1,%eax
f0105f03:	31 d2                	xor    %edx,%edx
f0105f05:	f7 f7                	div    %edi
f0105f07:	89 c5                	mov    %eax,%ebp
f0105f09:	8b 44 24 10          	mov    0x10(%esp),%eax
f0105f0d:	31 d2                	xor    %edx,%edx
f0105f0f:	f7 f5                	div    %ebp
f0105f11:	89 c8                	mov    %ecx,%eax
f0105f13:	f7 f5                	div    %ebp
f0105f15:	eb 95                	jmp    f0105eac <__umoddi3+0x3c>
f0105f17:	89 f6                	mov    %esi,%esi
f0105f19:	8d bc 27 00 00 00 00 	lea    0x0(%edi,%eiz,1),%edi
f0105f20:	89 c8                	mov    %ecx,%eax
f0105f22:	89 f2                	mov    %esi,%edx
f0105f24:	83 c4 20             	add    $0x20,%esp
f0105f27:	5e                   	pop    %esi
f0105f28:	5f                   	pop    %edi
f0105f29:	5d                   	pop    %ebp
f0105f2a:	c3                   	ret    
f0105f2b:	90                   	nop
f0105f2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0105f30:	b8 20 00 00 00       	mov    $0x20,%eax
f0105f35:	89 e9                	mov    %ebp,%ecx
f0105f37:	29 e8                	sub    %ebp,%eax
f0105f39:	d3 e2                	shl    %cl,%edx
f0105f3b:	89 c7                	mov    %eax,%edi
f0105f3d:	89 44 24 18          	mov    %eax,0x18(%esp)
f0105f41:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105f45:	89 f9                	mov    %edi,%ecx
f0105f47:	d3 e8                	shr    %cl,%eax
f0105f49:	89 c1                	mov    %eax,%ecx
f0105f4b:	8b 44 24 0c          	mov    0xc(%esp),%eax
f0105f4f:	09 d1                	or     %edx,%ecx
f0105f51:	89 fa                	mov    %edi,%edx
f0105f53:	89 4c 24 10          	mov    %ecx,0x10(%esp)
f0105f57:	89 e9                	mov    %ebp,%ecx
f0105f59:	d3 e0                	shl    %cl,%eax
f0105f5b:	89 f9                	mov    %edi,%ecx
f0105f5d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0105f61:	89 f0                	mov    %esi,%eax
f0105f63:	d3 e8                	shr    %cl,%eax
f0105f65:	89 e9                	mov    %ebp,%ecx
f0105f67:	89 c7                	mov    %eax,%edi
f0105f69:	8b 44 24 1c          	mov    0x1c(%esp),%eax
f0105f6d:	d3 e6                	shl    %cl,%esi
f0105f6f:	89 d1                	mov    %edx,%ecx
f0105f71:	89 fa                	mov    %edi,%edx
f0105f73:	d3 e8                	shr    %cl,%eax
f0105f75:	89 e9                	mov    %ebp,%ecx
f0105f77:	09 f0                	or     %esi,%eax
f0105f79:	8b 74 24 1c          	mov    0x1c(%esp),%esi
f0105f7d:	f7 74 24 10          	divl   0x10(%esp)
f0105f81:	d3 e6                	shl    %cl,%esi
f0105f83:	89 d1                	mov    %edx,%ecx
f0105f85:	f7 64 24 0c          	mull   0xc(%esp)
f0105f89:	39 d1                	cmp    %edx,%ecx
f0105f8b:	89 74 24 14          	mov    %esi,0x14(%esp)
f0105f8f:	89 d7                	mov    %edx,%edi
f0105f91:	89 c6                	mov    %eax,%esi
f0105f93:	72 0a                	jb     f0105f9f <__umoddi3+0x12f>
f0105f95:	39 44 24 14          	cmp    %eax,0x14(%esp)
f0105f99:	73 10                	jae    f0105fab <__umoddi3+0x13b>
f0105f9b:	39 d1                	cmp    %edx,%ecx
f0105f9d:	75 0c                	jne    f0105fab <__umoddi3+0x13b>
f0105f9f:	89 d7                	mov    %edx,%edi
f0105fa1:	89 c6                	mov    %eax,%esi
f0105fa3:	2b 74 24 0c          	sub    0xc(%esp),%esi
f0105fa7:	1b 7c 24 10          	sbb    0x10(%esp),%edi
f0105fab:	89 ca                	mov    %ecx,%edx
f0105fad:	89 e9                	mov    %ebp,%ecx
f0105faf:	8b 44 24 14          	mov    0x14(%esp),%eax
f0105fb3:	29 f0                	sub    %esi,%eax
f0105fb5:	19 fa                	sbb    %edi,%edx
f0105fb7:	d3 e8                	shr    %cl,%eax
f0105fb9:	0f b6 4c 24 18       	movzbl 0x18(%esp),%ecx
f0105fbe:	89 d7                	mov    %edx,%edi
f0105fc0:	d3 e7                	shl    %cl,%edi
f0105fc2:	89 e9                	mov    %ebp,%ecx
f0105fc4:	09 f8                	or     %edi,%eax
f0105fc6:	d3 ea                	shr    %cl,%edx
f0105fc8:	83 c4 20             	add    $0x20,%esp
f0105fcb:	5e                   	pop    %esi
f0105fcc:	5f                   	pop    %edi
f0105fcd:	5d                   	pop    %ebp
f0105fce:	c3                   	ret    
f0105fcf:	90                   	nop
f0105fd0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0105fd4:	29 f9                	sub    %edi,%ecx
f0105fd6:	19 c6                	sbb    %eax,%esi
f0105fd8:	89 4c 24 14          	mov    %ecx,0x14(%esp)
f0105fdc:	89 74 24 18          	mov    %esi,0x18(%esp)
f0105fe0:	e9 ff fe ff ff       	jmp    f0105ee4 <__umoddi3+0x74>
