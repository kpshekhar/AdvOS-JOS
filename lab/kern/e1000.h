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
#define E1000_RX_DESCTR 128		/*Receive descriptor */
#define E1000_RX_PCKT_SIZE 2048	/*Receive Buffer */


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

#define E1000_RDBAL    0x02800/4  /* RX Descriptor Base Address Low - RW */
#define E1000_RDBAH    0x02804/4  /* RX Descriptor Base Address High - RW */
#define E1000_RDLEN    0x02808/4  /* RX Descriptor Length - RW */
#define E1000_RDH      0x02810/4  /* RX Descriptor Head - RW */
#define E1000_RDT      0x02818/4  /* RX Descriptor Tail - RW */
#define E1000_RAL      0x05400/4  /* Receive Address Low - RW */
#define E1000_RAH      0x05404/4  /* Receive Address High - RW */
#define E1000_RAH_AV   0x80000000        /* Receive descriptor address valid */

#define E1000_RCTL     0x00100/4  /* RX Control - RW */
//*#define E1000_RCTL_EN             0x00000002    /* enable */
//#define E1000_RCTL_LPE            0x00000020    /* long packet enable */
//#define E1000_RCTL_LBM            0x000000C0    /* loopback mode */
//#define E1000_RCTL_RDMTS          0x00000300    /* rx min threshold size */
//#define E1000_RCTL_MO             0x00003000    /* multicast offset shift */
//#define E1000_RCTL_BAM            0x00008000    /* broadcast enable */
//#define E1000_RCTL_SZ             0x00030000    /* rx buffer size */
//#define E1000_RCTL_SECRC          0x04000000    /* Strip Ethernet CRC */

/* Receive Control */
#define E1000_RCTL_RST            0x00000001    /* Software reset */
#define E1000_RCTL_EN             0x00000002    /* enable */
#define E1000_RCTL_SBP            0x00000004    /* store bad packet */
#define E1000_RCTL_UPE            0x00000008    /* unicast promiscuous enable */
#define E1000_RCTL_MPE            0x00000010    /* multicast promiscuous enab */
#define E1000_RCTL_LPE            0x00000020    /* long packet enable */
#define E1000_RCTL_LBM_NO         0x00000000    /* no loopback mode */
#define E1000_RCTL_LBM_MAC        0x00000040    /* MAC loopback mode */
#define E1000_RCTL_LBM_SLP        0x00000080    /* serial link loopback mode */
#define E1000_RCTL_LBM_TCVR       0x000000C0    /* tcvr loopback mode */
#define E1000_RCTL_DTYP_MASK      0x00000C00    /* Descriptor type mask */
#define E1000_RCTL_DTYP_PS        0x00000400    /* Packet Split descriptor */
#define E1000_RCTL_RDMTS_HALF     0x00000000    /* rx desc min threshold size */
#define E1000_RCTL_RDMTS_QUAT     0x00000100    /* rx desc min threshold size */
#define E1000_RCTL_RDMTS_EIGTH    0x00000200    /* rx desc min threshold size */
#define E1000_RCTL_MO_SHIFT       12            /* multicast offset shift */
#define E1000_RCTL_MO_0           0x00000000    /* multicast offset 11:0 */
#define E1000_RCTL_MO_1           0x00001000    /* multicast offset 12:1 */
#define E1000_RCTL_MO_2           0x00002000    /* multicast offset 13:2 */
#define E1000_RCTL_MO_3           0x00003000    /* multicast offset 15:4 */
#define E1000_RCTL_MDR            0x00004000    /* multicast desc ring 0 */
#define E1000_RCTL_BAM            0x00008000    /* broadcast enable */
/* these buffer sizes are valid if E1000_RCTL_BSEX is 0 */
#define E1000_RCTL_SZ_2048        0x00000000    /* rx buffer size 2048 */
#define E1000_RCTL_SZ_1024        0x00010000    /* rx buffer size 1024 */
#define E1000_RCTL_SZ_512         0x00020000    /* rx buffer size 512 */
#define E1000_RCTL_SZ_256         0x00030000    /* rx buffer size 256 */
/* these buffer sizes are valid if E1000_RCTL_BSEX is 1 */
#define E1000_RCTL_SZ_16384       0x00010000    /* rx buffer size 16384 */
#define E1000_RCTL_SZ_8192        0x00020000    /* rx buffer size 8192 */
#define E1000_RCTL_SZ_4096        0x00030000    /* rx buffer size 4096 */
#define E1000_RCTL_VFE            0x00040000    /* vlan filter enable */
#define E1000_RCTL_CFIEN          0x00080000    /* canonical form enable */
#define E1000_RCTL_CFI            0x00100000    /* canonical form indicator */
#define E1000_RCTL_DPF            0x00400000    /* discard pause frames */
#define E1000_RCTL_PMCF           0x00800000    /* pass MAC control frames */
#define E1000_RCTL_BSEX           0x02000000    /* Buffer size extension */
#define E1000_RCTL_SECRC          0x04000000    /* Strip Ethernet CRC */
#define E1000_RCTL_FLXBUF_MASK    0x78000000    /* Flexible buffer size */
#define E1000_RCTL_FLXBUF_SHIFT   27            /* Flexible buffer shift */

#define E1000_RXD_STAT_DD       0x01    /* Descriptor Done */
#define E1000_RXD_STAT_EOP      0x02    /* End of Packet */

#define E1000_MTA      0x05200/4  /* Multicast Table Array - RW Array */



int e1000_attach_device(struct pci_func *pcif);
int e1000_Transmit_packet(char *data, int length); //Transmit a packet of length and data
int e1000_Receive_data(char *data); //Receive a packet of data


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


struct rx_desc
{
	uint64_t addr;
	uint16_t length;
	uint16_t chksum;
	uint8_t status;
	uint8_t errors;
	uint16_t special;
} __attribute__((packed));


struct rx_pckt
{
	uint8_t buffer[E1000_RX_PCKT_SIZE];
} __attribute__((packed));



#endif	// JOS_KERN_E1000_H
