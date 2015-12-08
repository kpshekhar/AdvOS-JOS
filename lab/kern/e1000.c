#include <kern/e1000.h>
#include <inc/assert.h>
#include <inc/error.h>
#include <inc/stdio.h>
#include <inc/string.h>
#include <kern/pmap.h>

// LAB 6: Your driver code here

struct tx_desc tx_descArray[E1000_TX_DESCTR] __attribute__ ((aligned (16)));
struct tx_pckt tx_pcktBuffer[E1000_TX_DESCTR];
struct rx_desc rx_descArray[E1000_RX_DESCTR] __attribute__ ((aligned (16)));
struct rx_pckt rx_pcktBuffer[E1000_RX_DESCTR];

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
	
	//Receive initalization
	// Initialize rcv desc buffer array
	memset(rx_descArray, 0x0, sizeof(struct rx_desc) * E1000_RX_DESCTR);
	memset(rx_pcktBuffer, 0x0, sizeof(struct rx_pckt) * E1000_RX_DESCTR);
	for (i = 0; i < E1000_RX_DESCTR; i++) {
		rx_descArray[i].addr = PADDR(rx_pcktBuffer[i].buffer);
	}

	//Receive program initalization 

	/*Program the Receive Address Register(s) (RAL/RAH) with the desired Ethernet addresses. 
	RAL[0]/RAH[0] should always be used to store the Individual Ethernet MAC address of the Ethernet controller.*/
	e1000[E1000_RAL] |= 0x12005452;  //52:54:00:12
 	e1000[E1000_RAH] |= 0x5634;  //34:56
	e1000[E1000_RAH] |= E1000_RAH_AV;  //Enable Address Valid, given as a hint in the LAB writeup

	//Initialize the MTA (Multicast Table Array) to 0b
	e1000[E1000_MTA] = 0;

	/*Allocate a region of memory for the receive descriptor list. Software should insure this memory is
aligned on a paragraph (16-byte) boundary. Program the Receive Descriptor Base Address
(RDBAL/RDBAH) register(s) with the address of the region. RDBAL is used for 32-bit addresses
and both RDBAL and RDBAH are used for 64-bit addresses.*/

	e1000[E1000_RDBAL] = PADDR(rx_descArray);     
	e1000[E1000_RDBAH] = 0;
	
/*Set the Receive Descriptor Length (RDLEN) register to the size (in bytes) of the descriptor ring.
This register must be 128-byte aligned.*/
	e1000[E1000_RDLEN] = sizeof(struct rx_desc) * E1000_RX_DESCTR ;

/*The Receive Descriptor Head and Tail registers are initialized (by hardware) to 0b after a power-on
or a software-initiated Ethernet controller reset. Receive buffers of appropriate size should be
allocated and pointers to these buffers should be stored in the receive descriptor ring. Software
initializes the Receive Descriptor Head (RDH) register and Receive Descriptor Tail (RDT) with the
appropriate head and tail addresses. Head should point to the first valid receive descriptor in the
descriptor ring and tail should point to one descriptor beyond the last valid descriptor in the
descriptor ring.*/
	e1000[E1000_RDH] = 0;
	e1000[E1000_RDT] = E1000_RX_DESCTR -1;


//Register settings

	e1000[E1000_RCTL] =0;


	e1000[E1000_RCTL] |= E1000_RCTL_EN ;  //Set the receiver Enable (RCTL.EN) bit to 1b for normal operation.
	e1000[E1000_RCTL] &= ~E1000_RCTL_LPE; //Set the Long Packet Enable (RCTL.LPE) bit to 1b
	e1000[E1000_RCTL] |= E1000_RCTL_LBM_NO ; //Loopback Mode (RCTL.LBM) should be set to 00b

	e1000[E1000_RCTL] |= E1000_RCTL_RDMTS_HALF;  //Configure the Receive Descriptor Minimum Threshold Size (RCTL.RDMTS) bits to the desired value.
	e1000[E1000_RCTL] |= E1000_RCTL_MO_0;//Configure the Multicast Offset (RCTL.MO) bits to the desired value.

	e1000[E1000_RCTL] |= E1000_RCTL_BAM ; // Set the Broadcast Accept Mode (RCTL.BAM) bit to 1b allowing the hardware to accept broadcast packets.

/*Configure the Receive Buffer Size (RCTL.BSIZE) bits to reflect the size of the receive buffers
software provides to hardware. Also configure the Buffer Extension Size (RCTL.BSEX) bits if
receive buffer needs to be larger than 2048 bytes.*/
 	e1000[E1000_RCTL] |= E1000_RCTL_SZ_2048 ; //buffer size 2048bytes
	e1000[E1000_RCTL] &= ~E1000_RCTL_BSEX ;  //no size extension
	
/*Set the Strip Ethernet CRC (RCTL.SECRC) bit if the desire is for hardware to strip the CRC
prior to DMA-ing the receive packet to host memory.*/
	e1000[E1000_RCTL] |= E1000_RCTL_SECRC;  //Strip CRC from incoming packet
	
	

	
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


int e1000_Receive_data(char *data) //Receive a packet of data
{
	
	uint32_t rdt_tail;
	uint32_t length;
	rdt_tail = e1000[E1000_RDT];  //Tail
	rdt_tail = (rdt_tail+1)%E1000_RX_DESCTR;  //assign the tail 
	
	if (rx_descArray[rdt_tail].status & E1000_RXD_STAT_DD) {  //Check if the buffer is empty
		if (!(rx_descArray[rdt_tail].status & E1000_RXD_STAT_EOP)) { //Condition for jumbo frame check
			panic("Don't allow extended frames!\n");
		}
		length = rx_descArray[rdt_tail].length; 
		cprintf ("Length is: %d\n",length);
		memcpy(data, rx_pcktBuffer[rdt_tail].buffer, length); //Copy the data from the buffer
		
		rx_descArray[rdt_tail].status &= ~E1000_RXD_STAT_DD;
		rx_descArray[rdt_tail].status &= ~E1000_RXD_STAT_EOP;
		e1000[E1000_RDT] = rdt_tail;	//Update the tail

		return length;	//Return the number of bytes
	}

	return -E_RX_Q_EMPTY;  //Buffer is empty 

}


