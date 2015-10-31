// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).

	// LAB 4: Your code here.
	pte_t ft_pte;
	ft_pte = uvpt[PGNUM(addr)];
	if (!(err & FEC_WR) || !(ft_pte & PTE_COW) )
		panic("PGfault: %x does not have write access to copy-on-write page");

	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.

	// LAB 4: Your code here.
	//Allocate a page to the temp location
	r = sys_page_alloc(0, PFTEMP, PTE_U | PTE_P | PTE_W);
	if (r < 0) {
		panic("Pgfault on sys_page_alloc :%e",r);
	}
	
	//copy the fault page content to temp page
	void* addr_rounddown = ROUNDDOWN(addr, PGSIZE);
	memmove(PFTEMP, addr_rounddown, PGSIZE);
 
	//Map the new page
	r=sys_page_map(0, (void *)PFTEMP,0, addr_rounddown ,PTE_P|PTE_U|PTE_W);	
	if (r< 0)
	    panic("Fault on sys_page_map:%e\n",r);
	
	
	r = sys_page_unmap(0, (void*)PFTEMP);
	if (r < 0)
		panic("Fault on sys_page_unmap: %e \n", r);
	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	int r;

	// LAB 4: Your code here.
	//panic("duppage not implemented");
	pte_t pte;

	pte = uvpt[pn];
	void* va = (void*)(pn * PGSIZE);
	
	//Check if the page is writable or copy_on_write page
	if ((pte & PTE_W) || (pte & PTE_COW))
	{
		//setting the page as readonly and copy-on-write
		if ((r= sys_page_map(0, va, envid, va , PTE_U|PTE_P|PTE_COW))<0)
			panic("Duppage error on sys_page_map -1: readonly and COW mapping error: %e \n",r);
		
		//Remapping the page 
		if ((r= sys_page_map(envid, va, 0, va , PTE_U|PTE_P|PTE_COW))<0)
			panic("Duppage error on sys_page_map -2: readonly and COW remapping error: %e \n",r);
	}
	else
	{// if it is only read-only page
		if ((r= sys_page_map(0, va, envid, va , PTE_U|PTE_P))<0)
			panic("Duppage error on sys_page_map -3: readonly mapping error: %e \n",r);
	
	}
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: Your code here.
	//panic("fork not implemented");
	
	//set parent process fault handler
	set_pgfault_handler(pgfault);

	envid_t envid;
	envid = sys_exofork(); // Creating a child process
	if (envid <  0)
		panic("Fork process error %e \n", envid);
	
	if (envid == 0)
	{ //This is the child process, hence thisenv pointing is actually representing parent enivd
	 //we will have to change this
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0; //this is all for child, we can return 0 and exit
	}
	
	//This is the parent process. We will do the mapping of parent's pages to child's pages
	 // copy "mapping"
	uint32_t pnBeg = UTEXT >> PTXSHIFT;
	uint32_t pnEnd = USTACKTOP >> PTXSHIFT;  
	for (; pnBeg < pnEnd; ++pnBeg) 
	{
		// check whether current page is present
		if (!(uvpd[pnBeg >> 10] & PTE_P)) {
			continue;
		}

		if (!(uvpt[pnBeg] & (PTE_P | PTE_U))) {
			continue;
		}

		duppage(envid, pnBeg);
	}
	int r;
	// set child process's page fault upcall entry point just like the parent
	if ((r = sys_env_set_pgfault_upcall(envid, thisenv->env_pgfault_upcall)) < 0) {
		panic("Fork error on sys_env_set_pgfault_upcall: %e\n", r);
	}

	// allocate page for child's process exception stack
	if ((r = sys_page_alloc(envid, (void*)(UXSTACKTOP - PGSIZE), PTE_U | PTE_P | PTE_W)) < 0) {
		panic("Fork error on sys_page_alloc: %e\n", r);
	}

	if ((r = sys_env_set_status(envid, ENV_RUNNABLE)) < 0) {
		panic("Fork error on sys_env_set_status: %e \n", r);
	}

	return envid;

	
	
}


// allocate a new env for child process with kernel part mapping
	

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
