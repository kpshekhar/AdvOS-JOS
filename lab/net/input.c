#include "ns.h"

extern union Nsipc nsipcbuf;

#define BUFR_LENGTH 2048

void
input(envid_t ns_envid)
{
	binaryname = "ns_input";

	// LAB 6: Your code here:
	// 	- read a packet from the device driver
	//	- send it to the network server
	// Hint: When you IPC a page to the network server, it will be
	// reading from it for a while, so don't immediately receive
	// another packet in to the same physical page.


	
	char buf[BUFR_LENGTH];

	int len, err;
	int perm = PTE_U | PTE_P | PTE_W;
	len = BUFR_LENGTH -1;
	unsigned now, end;

	while (true) {
		if ((err = sys_net_rx_data(buf)) < 0) {
			sys_yield();
			continue;
		}
		len = err; //If err is more than 0 that means it contains length 

		//Calling the same page reference will automatically deallocate earlier page and reallocate new page
		while ((err = sys_page_alloc(0, &nsipcbuf, perm)) < 0);

		nsipcbuf.pkt.jp_len = len;
		memmove(nsipcbuf.pkt.jp_data, buf, len);
		
	//IPC_SEND the data buffer. 
		ipc_send(ns_envid, (uint32_t)NSREQ_INPUT, &nsipcbuf, perm);

	//Tried to insert a small delay before reading another packet. Might not be an effective solution
		now = sys_time_msec();
		end = now + 1 * 100;
		while (sys_time_msec() < end);
	}
}
