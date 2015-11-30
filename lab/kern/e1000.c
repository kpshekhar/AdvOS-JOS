#include <kern/e1000.h>
#include <inc/assert.h>
#include <inc/error.h>
#include <inc/stdio.h>
#include <inc/string.h>
#include <kern/pmap.h>

// LAB 6: Your driver code here

struct tx_desc tx_descArray[E1000_TX_DESCTR] __attribute__ ((aligned (16)));
struct tx_pckt tx_pcktBuffer[E1000_TX_DESCTR];

int
e1000_attach_device(struct pci_func *pcif)
{
	uint32_t i;

	// Enable PCI device
	pci_func_enable(pcif);
	
	//Mapping MMIO region 
	//boot_map_region(kern_pgdir, E1000_MMIO_ADDR,
	//		pcif->reg_size[0], pcif->reg_base[0], 
	//		PTE_PCD | PTE_PWT | PTE_W);
	e1000 = (void *) mmio_map_region(pcif->reg_base[0], pcif->reg_size[0]);
	
	assert(e1000[E1000_STATUS] == 0x80080783);
	cprintf("E1000 status value: %08x\n", e1000[E1000_STATUS]);


	//Transmit Initlialization
	//Clear the areas allocated by the software for the descriptors and buffers 
	memset(tx_descArray, 0x0, sizeof(struct tx_desc) * E1000_TX_DESCTR);
	memset(tx_pcktBuffer, 0x0, sizeof(struct tx_pckt) * E1000_TX_DESCTR);
	for (i = 0; i < E1000_TX_DESCTR; i++) {
		tx_descArray[i].addr = PADDR(tx_pcktBuffer[i].buf);
		tx_descArray[i].status |= E1000_TXD_STAT_DD;
	}


	/*Program the Transmit Descriptor Base Address (TDBAL/TDBAH) register(s) with the address of the region.*/
	e1000[E1000_TDBAL] = PADDR(tx_descArray);	
	e1000[E1000_TDBAH] = 0x0;

	/*Set the Transmit Descriptor Length (TDLEN) register to the size (in bytes) of the descriptor ring.
	This register must be 128-byte aligned.*/
	e1000[E1000_TDLEN] = sizeof(struct tx_desc) * E1000_TX_DESCTR;

	/*The Transmit Descriptor Head and Tail (TDH/TDT) registers are initialized (by hardware) to 0.
	Software should write 0b to both these registers to ensure this.*/
	e1000[E1000_TDH] = 0x0;
	e1000[E1000_TDT] = 0x0;

	/*Initialize the Transmit Control Register (TCTL) for desired operation to include the following:

	• Set the Enable (TCTL.EN) bit to 1b for normal operation. */
	e1000[E1000_TCTL] |= E1000_TCTL_EN;

	/*• Set the Pad Short Packets (TCTL.PSP) bit to 1b.*/
	e1000[E1000_TCTL] |= E1000_TCTL_PSP;

	/*Configure the Collision Threshold (TCTL.CT) to the desired value.The value is 10h*/
	e1000[E1000_TCTL] &= ~E1000_TCTL_CT;	//Clear the specified bits first
	e1000[E1000_TCTL] |= (0x10) << 4;		//Set the values as required to 10h

	/*Configure the Collision Distance (TCTL.COLD) to its expected value.For full duplex
	operation, this value should be set to 40h */
	e1000[E1000_TCTL] &= ~E1000_TCTL_COLD;	//Clear the specified bits first
	e1000[E1000_TCTL] |= (0x40) << 12;		//Set the value to 40h for full duplex

	/*Program the Transmit IPG (TIPG) register*/
	e1000[E1000_TIPG] = 0x0;
	
	/*IPG Receive Time 2
	Specifies the total length of the IPG time for non back-to-back
	transmissions.
	IPGR2 In order to calculate the actual IPG value, a value of six should be added to the IPGR2 value*/
	e1000[E1000_TIPG] |= (0x6) << 20; 
	
	/*IPG Receive Time 1
	Specifies the length of the first part of the IPG time for non back-
	to-back transmissions. During this time, the internal IPG counter
	restarts if any carrier event occurs. Once the time specified in
	IPGR1 has elapsed, carrier sense does not affect the IPG
	counter.
	According to the IEEE802.3 standard, IPGR1 should be 2/3 of IPGR2 value.*/
	e1000[E1000_TIPG] |= (0x4) << 10; // IPGR1

	/*PG Transmit Time
	Specifies the IPG time for back-to-back packet transmissions*/
	e1000[E1000_TIPG] |= 0xA; // IPGT should be 10
	
	/* Test data 
	char a[] = "Hello";
	char b[] = "This is a test function";
	e1000_Transmit_packet(a, sizeof(a));
	e1000_Transmit_packet(b, sizeof(b));
	*/
	return 0;
}



int e1000_Transmit_packet(char *data, int length) //Transmit a packet of length and data
{
	//Make sure the length is within the limits
	if (length > E1000_TX_PCKT_SIZE)
		return -E_PCKT_LONG;

	/*Note that TDT is an index into the transmit descriptor array, not a byte offset;*/
	uint32_t tdt = e1000[E1000_TDT]; //Transmit descriptor tail register. 
	
	//Checking if the TX queue has descriptors available
	if (tx_descArray[tdt].status & E1000_TXD_STAT_DD) {
		memmove(tx_pcktBuffer[tdt].buf, data, length);
		tx_descArray[tdt].length = length;

		tx_descArray[tdt].status &= ~E1000_TXD_STAT_DD;
		tx_descArray[tdt].cmd |= E1000_TXD_CMD_RS;
		tx_descArray[tdt].cmd |= E1000_TXD_CMD_EOP;

		//Update the TDT register to point to next array
		e1000[E1000_TDT] = (tdt + 1) % E1000_TX_DESCTR;
	}
	
	else
		return -E_TX_Q_FULL;
	
	return 0;
}

