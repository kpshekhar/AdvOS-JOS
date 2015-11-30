#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <kern/pci.h>

volatile uint32_t *e1000; // MMIO address to access E1000 BAR

#define E1000_VENDOR_ID 0x8086  //Vendor id
#define E1000_DEVICE_ID 0x100e  //Device Id

/*BAR 0 is smaller than 4MB, so you could use the gap between KSTACKTOP and KERNBASE; or you could map it well above KERNBASE (but don't overwrite the mapping used by the LAPIC). */
#define E1000_MMIO_ADDR KSTACKTOP 

#define E1000_TX_DESCTR 64  /* Transmit Descriptor of maximum 64 descriptors*/
#define E1000_TX_PCKT_SIZE 1518   /* Transmit Packet Size Maximum */

//Registers
#define E1000_STATUS   0x00008/4  /* Device Status - RO */

/*Transmit  registers */
#define E1000_TDBAL    0x03800/4  /* TX Descriptor Base Address Low - RW */
#define E1000_TDBAH    0x03804/4  /* TX Descriptor Base Address High - RW */
#define E1000_TDLEN    0x03808/4  /* TX Descriptor Length - RW */
#define E1000_TDH      0x03810/4  /* TX Descriptor Head - RW */
#define E1000_TDT      0x03818/4  /* TX Descripotr Tail - RW */

#define E1000_TCTL     0x00400/4  /* TX Control - RW */
#define E1000_TCTL_EN     0x00000002    /* enable tx */
#define E1000_TCTL_PSP    0x00000008    /* pad short packets */
#define E1000_TCTL_CT     0x00000ff0    /* collision threshold */
#define E1000_TCTL_COLD   0x003ff000    /* collision distance */

#define E1000_TIPG     0x00410/4  /* TX Inter-packet gap -RW */

#define E1000_TXD_STAT_DD    0x00000001 /* Descriptor Done */
#define E1000_TXD_CMD_EOP    0x00000001 /* End of Packet */
#define E1000_TXD_STAT_DD    0x00000001 /* Descriptor Done */
#define E1000_TXD_CMD_RS     0x00000008 /* Report Status */
int e1000_attach_device(struct pci_func *pcif);
int e1000_Transmit_packet(char *data, int length); //Transmit a packet of length and data

struct tx_desc
{
	uint64_t addr;
	uint16_t length;
	uint8_t cso;
	uint8_t cmd;
	uint8_t status;
	uint8_t css;
	uint16_t special;
}__attribute__((packed));


struct tx_pckt
{
	uint8_t buf[E1000_TX_PCKT_SIZE];
}__attribute__((packed));

#endif	// JOS_KERN_E1000_H
