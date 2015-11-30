#include "ns.h"

extern union Nsipc nsipcbuf;

void
output(envid_t ns_envid)
{
	binaryname = "ns_output";
	int status; 
	// LAB 6: Your code here:
	// 	- read a packet from the network server
	//	- send the packet to the device driver
	while (true) { 
		status = sys_ipc_recv(&nsipcbuf);
	//If not the right enivronment continue in loop 
		if ((thisenv->env_ipc_from != ns_envid) ||
		    (thisenv->env_ipc_value != NSREQ_OUTPUT)) {
			continue;
		}

		while ((status = sys_net_tx_packet(nsipcbuf.pkt.jp_data, nsipcbuf.pkt.jp_len)) != 0);
	}



}
