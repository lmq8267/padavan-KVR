// SoftEther VPN Source Code - Stable Edition Repository
// Kernel Device Driver
// 
// SoftEther VPN Server, Client and Bridge are free software under the Apache License, Version 2.0.
// 
// Copyright (c) Daiyuu Nobori.
// Copyright (c) SoftEther VPN Project, University of Tsukuba, Japan.
// Copyright (c) SoftEther Corporation.
// Copyright (c) all contributors on SoftEther VPN project in GitHub.
// 
// All Rights Reserved.
// 
// http://www.softether.org/
// 
// This stable branch is officially managed by Daiyuu Nobori, the owner of SoftEther VPN Project.
// Pull requests should be sent to the Developer Edition Master Repository on https://github.com/SoftEtherVPN/SoftEtherVPN
// 
// License: The Apache License, Version 2.0
// https://www.apache.org/licenses/LICENSE-2.0
// 
// DISCLAIMER
// ==========
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
// 
// THIS SOFTWARE IS DEVELOPED IN JAPAN, AND DISTRIBUTED FROM JAPAN, UNDER
// JAPANESE LAWS. YOU MUST AGREE IN ADVANCE TO USE, COPY, MODIFY, MERGE, PUBLISH,
// DISTRIBUTE, SUBLICENSE, AND/OR SELL COPIES OF THIS SOFTWARE, THAT ANY
// JURIDICAL DISPUTES WHICH ARE CONCERNED TO THIS SOFTWARE OR ITS CONTENTS,
// AGAINST US (SOFTETHER PROJECT, SOFTETHER CORPORATION, DAIYUU NOBORI OR OTHER
// SUPPLIERS), OR ANY JURIDICAL DISPUTES AGAINST US WHICH ARE CAUSED BY ANY KIND
// OF USING, COPYING, MODIFYING, MERGING, PUBLISHING, DISTRIBUTING, SUBLICENSING,
// AND/OR SELLING COPIES OF THIS SOFTWARE SHALL BE REGARDED AS BE CONSTRUED AND
// CONTROLLED BY JAPANESE LAWS, AND YOU MUST FURTHER CONSENT TO EXCLUSIVE
// JURISDICTION AND VENUE IN THE COURTS SITTING IN TOKYO, JAPAN. YOU MUST WAIVE
// ALL DEFENSES OF LACK OF PERSONAL JURISDICTION AND FORUM NON CONVENIENS.
// PROCESS MAY BE SERVED ON EITHER PARTY IN THE MANNER AUTHORIZED BY APPLICABLE
// LAW OR COURT RULE.
// 
// USE ONLY IN JAPAN. DO NOT USE THIS SOFTWARE IN ANOTHER COUNTRY UNLESS YOU HAVE
// A CONFIRMATION THAT THIS SOFTWARE DOES NOT VIOLATE ANY CRIMINAL LAWS OR CIVIL
// RIGHTS IN THAT PARTICULAR COUNTRY. USING THIS SOFTWARE IN OTHER COUNTRIES IS
// COMPLETELY AT YOUR OWN RISK. THE SOFTETHER VPN PROJECT HAS DEVELOPED AND
// DISTRIBUTED THIS SOFTWARE TO COMPLY ONLY WITH THE JAPANESE LAWS AND EXISTING
// CIVIL RIGHTS INCLUDING PATENTS WHICH ARE SUBJECTS APPLY IN JAPAN. OTHER
// COUNTRIES' LAWS OR CIVIL RIGHTS ARE NONE OF OUR CONCERNS NOR RESPONSIBILITIES.
// WE HAVE NEVER INVESTIGATED ANY CRIMINAL REGULATIONS, CIVIL LAWS OR
// INTELLECTUAL PROPERTY RIGHTS INCLUDING PATENTS IN ANY OF OTHER 200+ COUNTRIES
// AND TERRITORIES. BY NATURE, THERE ARE 200+ REGIONS IN THE WORLD, WITH
// DIFFERENT LAWS. IT IS IMPOSSIBLE TO VERIFY EVERY COUNTRIES' LAWS, REGULATIONS
// AND CIVIL RIGHTS TO MAKE THE SOFTWARE COMPLY WITH ALL COUNTRIES' LAWS BY THE
// PROJECT. EVEN IF YOU WILL BE SUED BY A PRIVATE ENTITY OR BE DAMAGED BY A
// PUBLIC SERVANT IN YOUR COUNTRY, THE DEVELOPERS OF THIS SOFTWARE WILL NEVER BE
// LIABLE TO RECOVER OR COMPENSATE SUCH DAMAGES, CRIMINAL OR CIVIL
// RESPONSIBILITIES. NOTE THAT THIS LINE IS NOT LICENSE RESTRICTION BUT JUST A
// STATEMENT FOR WARNING AND DISCLAIMER.
// 
// READ AND UNDERSTAND THE 'WARNING.TXT' FILE BEFORE USING THIS SOFTWARE.
// SOME SOFTWARE PROGRAMS FROM THIRD PARTIES ARE INCLUDED ON THIS SOFTWARE WITH
// LICENSE CONDITIONS WHICH ARE DESCRIBED ON THE 'THIRD_PARTY.TXT' FILE.
// 
// 
// SOURCE CODE CONTRIBUTION
// ------------------------
// 
// Your contribution to SoftEther VPN Project is much appreciated.
// Please send patches to us through GitHub.
// Read the SoftEther VPN Patch Acceptance Policy in advance:
// http://www.softether.org/5-download/src/9.patch
// 
// 
// DEAR SECURITY EXPERTS
// ---------------------
// 
// If you find a bug or a security vulnerability please kindly inform us
// about the problem immediately so that we can fix the security problem
// to protect a lot of users around the world as soon as possible.
// 
// Our e-mail address for security reports is:
// softether-vpn-security [at] softether.org
// 
// Please note that the above e-mail address is not a technical support
// inquiry address. If you need technical assistance, please visit
// http://www.softether.org/ and ask your question on the users forum.
// 
// Thank you for your cooperation.
// 
// 
// NO MEMORY OR RESOURCE LEAKS
// ---------------------------
// 
// The memory-leaks and resource-leaks verification under the stress
// test has been passed before release this source code.


// Neo6.c
// Driver Main Program

#include <GlobalConst.h>

#define	NEO_DEVICE_DRIVER

#include "Neo6.h"

// Whether Win8
extern bool g_is_win8;

// Neo driver context
static NEO_CTX static_ctx;
NEO_CTX *ctx = &static_ctx;

// Read the packet data from the transmit packet queue
void NeoRead(void *buf)
{
	NEO_QUEUE *q;
	UINT num;
	BOOL left;
	// Validate arguments
	if (buf == NULL)
	{
		return;
	}

	// Copy the packets one by one from the queue
	num = 0;
	left = TRUE;
	NeoLockPacketQueue();
	{
		while (TRUE)
		{
			if (num >= NEO_MAX_PACKET_EXCHANGE)
			{
				if (ctx->PacketQueue == NULL)
				{
					left = FALSE;
				}
				break;
			}
			q = NeoGetNextQueue();
			if (q == NULL)
			{
				left = FALSE;
				break;
			}
			NEO_SIZE_OF_PACKET(buf, num) = q->Size;
			NeoCopy(NEO_ADDR_OF_PACKET(buf, num), q->Buf, q->Size);
			num++;
			NeoFreeQueue(q);
		}
	}
	NeoUnlockPacketQueue();

	NEO_NUM_PACKET(buf) = num;
	NEO_LEFT_FLAG(buf) = left;

	if (left == FALSE)
	{
		NeoReset(ctx->Event);
	}
	else
	{
		NeoSet(ctx->Event);
	}

	return;
}

// Process the received packet
void NeoWrite(void *buf)
{
	UINT num, i, size;
	UCHAR *packet_buf;
	NET_BUFFER_LIST *nbl_chain = NULL;
	NET_BUFFER_LIST *nbl_tail = NULL;
	UINT num_nbl_chain = 0;
	// Validate arguments
	if (buf == NULL)
	{
		return;
	}

	// Number of packets
	num = NEO_NUM_PACKET(buf);
	if (num > NEO_MAX_PACKET_EXCHANGE)
	{
		// Number of packets is too many
		return;
	}
	if (num == 0)
	{
		// No packet
		return;
	}

	if (ctx->Halting != FALSE)
	{
		// Stopping
		return;
	}

	if (ctx->Paused)
	{
		// Paused
		return;
	}

	if (ctx->Opened == FALSE)
	{
		// Not connected
		return;
	}

	for (i = 0;i < num;i++)
	{
		PACKET_BUFFER *p = ctx->PacketBuffer[i];
		void *dst;
		NET_BUFFER_LIST *nbl = ctx->PacketBuffer[i]->NetBufferList;
		NET_BUFFER *nb = NET_BUFFER_LIST_FIRST_NB(nbl);

		nbl->SourceHandle = ctx->NdisMiniport;

		NET_BUFFER_LIST_NEXT_NBL(nbl) = NULL;

		size = NEO_SIZE_OF_PACKET(buf, i);
		if (size > NEO_MAX_PACKET_SIZE)
		{
			size = NEO_MAX_PACKET_SIZE;
		}
		if (size < NEO_PACKET_HEADER_SIZE)
		{
			size = NEO_PACKET_HEADER_SIZE;
		}

		packet_buf = (UCHAR *)(NEO_ADDR_OF_PACKET(buf, i));

		if (OK(NdisRetreatNetBufferDataStart(nb, size, 0, NULL)))
		{
			// Buffer copy
			dst = NdisGetDataBuffer(nb,
				size,
				NULL,
				1,
				0);

			if (dst != NULL)
			{
				NeoCopy(dst, packet_buf, size);

				if (nbl_chain == NULL)
				{
					nbl_chain = nbl;
				}

				if (nbl_tail != NULL)
				{
					NET_BUFFER_LIST_NEXT_NBL(nbl_tail) = nbl;
				}

				nbl_tail = nbl;

				num_nbl_chain++;
			}
		}

		nbl->Status = NDIS_STATUS_RESOURCES;

		ctx->Status.Int64BytesRecvTotal += (UINT64)size;

		if (packet_buf[0] & 0x40)
		{
			ctx->Status.Int64NumRecvBroadcast++;
			ctx->Status.Int64BytesRecvBroadcast += (UINT64)size;
		}
		else
		{
			ctx->Status.Int64NumRecvUnicast++;
			ctx->Status.Int64BytesRecvUnicast += (UINT64)size;
		}
	}

	if (nbl_chain == NULL)
	{
		return;
	}

	// Notify that it has received
	ctx->Status.NumPacketRecv += num_nbl_chain;

	NdisMIndicateReceiveNetBufferLists(ctx->NdisMiniport,
		nbl_chain, 0, num_nbl_chain, NDIS_RECEIVE_FLAGS_RESOURCES);

	if (true)
	{
		// Restore the packet buffer
		NET_BUFFER_LIST *nbl = nbl_chain;

		while (nbl != NULL)
		{
			NET_BUFFER *nb = NET_BUFFER_LIST_FIRST_NB(nbl);

			if (nb != NULL)
			{
				UINT size = NET_BUFFER_DATA_LENGTH(nb);

				NdisAdvanceNetBufferDataStart(nb, size, false, NULL);
			}

			nbl = NET_BUFFER_LIST_NEXT_NBL(nbl);
		}
	}
}

// Get the number of queue items
UINT NeoGetNumQueue()
{
	return ctx->NumPacketQueue;
}

// Insert the queue
void NeoInsertQueue(void *buf, UINT size)
{
	NEO_QUEUE *p;
	// Validate arguments
	if (buf == NULL || size == 0)
	{
		return;
	}

	// Prevent the packet accumulation in large quantities in the queue
	if (ctx->NumPacketQueue > NEO_MAX_PACKET_QUEUED)
	{
		NeoFree(buf);
		return;
	}

	// Create a queue
	p = NeoMalloc(sizeof(NEO_QUEUE));
	p->Next = NULL;
	p->Size = size;
	p->Buf = buf;

	// Append to the queue
	if (ctx->PacketQueue == NULL)
	{
		ctx->PacketQueue = p;
	}
	else
	{
		NEO_QUEUE *q = ctx->Tail;
		q->Next = p;
	}

	ctx->Tail = p;

	ctx->NumPacketQueue++;
}

// Get the next queued item
NEO_QUEUE *NeoGetNextQueue()
{
	NEO_QUEUE *q;
	if (ctx->PacketQueue == NULL)
	{
		// Empty queue
		return NULL;
	}

	// Get the next queued item
	q = ctx->PacketQueue;
	ctx->PacketQueue = ctx->PacketQueue->Next;
	q->Next = NULL;
	ctx->NumPacketQueue--;

	if (ctx->PacketQueue == NULL)
	{
		ctx->Tail = NULL;
	}

	return q;
}

// Release the buffer of the queue
void NeoFreeQueue(NEO_QUEUE *q)
{
	// Validate arguments
	if (q == NULL)
	{
		return;
	}
	NeoFree(q->Buf);
	NeoFree(q);
}

// Lock the packet queue
void NeoLockPacketQueue()
{
	NeoLock(ctx->PacketQueueLock);
}

// Unlock the packet queue
void NeoUnlockPacketQueue()
{
	NeoUnlock(ctx->PacketQueueLock);
}

// Initialize the packet queue
void NeoInitPacketQueue()
{
	// Create a lock
	ctx->PacketQueueLock = NeoNewLock();
	// Initialize the packet queue
	ctx->PacketQueue = NULL;
	ctx->NumPacketQueue = 0;
	ctx->Tail = NULL;
}

// Delete all the packets from the packet queue
void NeoClearPacketQueue(bool no_lock)
{
	// Release the memory of the packet queue
	if (no_lock == false)
	{
		NeoLock(ctx->PacketQueueLock);
	}
	if (true)
	{
		NEO_QUEUE *q = ctx->PacketQueue;
		NEO_QUEUE *qn;
		while (q != NULL)
		{
			qn = q->Next;
			NeoFree(q->Buf);
			NeoFree(q);
			q = qn;
		}
		ctx->PacketQueue = NULL;
		ctx->Tail = NULL;
		ctx->NumPacketQueue = 0;
	}
	if (no_lock == false)
	{
		NeoUnlock(ctx->PacketQueueLock);
	}
}

// Release the packet queue
void NeoFreePacketQueue()
{
	// Delete all packets
	NeoClearPacketQueue(false);

	// Delete the lock
	NeoFreeLock(ctx->PacketQueueLock);
	ctx->PacketQueueLock = NULL;
}

// Start the adapter
void NeoStartAdapter()
{
	// Initialize the packet queue
	NeoInitPacketQueue();
}

// Stop the adapter
void NeoStopAdapter()
{
	// Delete the packet queue
	NeoFreePacketQueue();
}

// Initialization
BOOL NeoInit()
{
	// Initialize the context
	NeoZero(ctx, sizeof(NEO_CTX));

	// Initialize the status information
	NeoNewStatus(&ctx->Status);

	return TRUE;
}

// Shutdown
void NeoShutdown()
{
	if (ctx == NULL)
	{
		// Uninitialized
		return;
	}

	// Relaese the status information
	NeoFreeStatus(&ctx->Status);

	NeoZero(ctx, sizeof(NEO_CTX));
}

// Create a status information
void NeoNewStatus(NEO_STATUS *s)
{
	// Validate arguments
	if (s == NULL)
	{
		return;
	}

	// Memory initialization
	NeoZero(s, sizeof(NEO_STATUS));
}

// Release the status information
void NeoFreeStatus(NEO_STATUS *s)
{
	// Validate arguments
	if (s == NULL)
	{
		return;
	}

	// Memory initialization
	NeoZero(s, sizeof(NEO_STATUS));
}

