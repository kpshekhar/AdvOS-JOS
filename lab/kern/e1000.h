#ifndef JOS_KERN_E1000_H
#define JOS_KERN_E1000_H

#include <kern/pci.h>

volatile uint32_t *e1000; // MMIO address to access E1000 BAR

#define E1000_VENDOR_ID 0x8086  //Vendor id
#define E1000_DEVICE_ID 0x100e  //Device Id




int e1000_attach_device(struct pci_func *pcif);

#endif	// JOS_KERN_E1000_H
