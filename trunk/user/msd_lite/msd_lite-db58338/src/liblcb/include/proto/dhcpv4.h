/*
 * Copyright (c) 2011 - 2022 Rozhuk Ivan <rozhuk.im@gmail.com>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 */


#ifndef __DHCP4_MESSAGE_H__
#define __DHCP4_MESSAGE_H__


#include <sys/types.h>
#include <inttypes.h>
#include <errno.h>
#include <netinet/in.h>
#include <string.h>

#ifndef nitems
#	define nitems(__X)	(sizeof(__X) / sizeof(__X[0]))
#endif


//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
// http://www.iana.org/assignments/bootp-dhcp-parameters/bootp-dhcp-parameters.xml#bootp-dhcp-parameters-1
//
// RFC 1542	Clarifications and Extensions for BOOTP
// RFC 2131	Dynamic Host Configuration Protocol
// RFC 2132	DHCP Options and BOOTP Vendor Extensions
// RFC 3203	DHCP reconfigure extension (FORCERENEW)
// RFC 3679	Unused DHCP Option Codes
// RFC 3942	Reclassifying DHCPv4 Options
//
// RFC 3046	DHCP Relay Agent Information Option (sub opt 1-2)
// RFC 3256	The DOCSIS (Data-Over-Cable Service Interface Specifications) Device Class DHCP (Dynamic Host Configuration Protocol) Relay Agent Information Sub-option (add subopt 4 to RFC 3046)
// RFC 3527	Link Selection sub-option (add subopt 5 to RFC 3046)
// RFC 3993	Subscriber-ID Suboption (add subopt 6 to RFC 3046)
// RFC 4014	RADIUS Attributes Suboption (add subopt 7 to RFC 3046)
// RFC 4030	Authentication Suboption (add subopt 8 to RFC 3046)
// RFC 4243	Vendor-Specific Relay Suboption (add subopt 9 to RFC 3046)
// RFC 5010	Relay Agent Flags Suboption (add subopt 10 to RFC 3046)
// RFC 5107	Server ID Override Suboption (add subopt 11 to RFC 3046)
//
// RFC 2241	DHCP Options for Novell Directory Services
// RFC 2242	NetWare/IP Domain Name and Information
// RFC 2485	DHCP Option for The Open Group's User Authentication Protocol
// RFC 2563	DHCP Option to Disable Stateless Auto-Configuration in IPv4 Clients
// RFC 2610	DHCP Options for Service Location Protocol
// RFC 2937	The Name Service Search Option for DHCP
// RFC 2939	Procedures for New DHCP Options
// RFC 3004	The User Class Option for DHCP
// RFC 3011	The IPv4 Subnet Selection Option for DHCP
// RFC 3118	Authentication for DHCP Messages
// RFC 3442	Classless Static Route Option for DHCPv4
// RFC 3495	DHCP Option for CableLabs Clients
// RFC 3594	Security Ticket Control (add subopt to RFC 3495)
// RFC 3825	DHCP Option for Coordinate LCI
// RFC 4174	DHCP Option Number for iSNS
// RFC 4280	DHCP Options for BMCS
// RFC 4361	Node-specific Identifiers for DHCPv4
// RFC 4578	DHCP PXE Options
// RFC 4702	The DHCP Client FQDN Option
// RFC 4776	Option for Civic Addresses Configuration Information
// RFC 4833	Timezone Options for DHCP
// RFC 5071	PXELINUX Options
// RFC 5192	PAA DHCP Options
// RFC 5223	DHCP-Based LoST Discovery
// RFC 5678	Mobility Services for DCHP Options
// RFC 5859	TFTP Server Address
// RFC 7710	Captive-Portal Identification Using DHCP or Router Advertisements (RAs)
// http://www.iana.org/numbers.htm
// http://msdn.microsoft.com/en-us/library/cc227274(v=PROT.10).aspx
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////


#define DHCP4_SRV_PORT		67
#define DHCP4_CLI_PORT		68
#define DHCP4_MIN_PACKET_LENGTH	300 /* RFC 1542 2.1. */


typedef struct dhcp4_hdr_flags_s {
	uint8_t mbz:7;	/* -- // MUST BE ZERO (reserved for future use). */
	uint8_t b:1;	/* C- // BROADCAST. */
} __attribute__((__packed__)) dhcp4_hdr_flags_t, *dhcp4_hdr_flags_p;

typedef struct dhcp4_header_s {
	uint8_t		op;	/* Message op code / message type. */
	uint8_t		htype;	/* Hardware address type, see ARP section in "Assigned Numbers" RFC; e.g., '1' = 10mb ethernet. */
	uint8_t		hlen;	/* Hardware address length (e.g.  '6' for 10mb ethernet). */
	uint8_t		hops;	/* Client sets to zero, optionally used by relay agents when booting via a relay agent. */
	uint32_t	xid;	/* Transaction ID, a random number chosen by the client, used by the client and server to associate messages and responses between a client and a server. */
	uint16_t	secs;	/* Filled in by client, seconds elapsed since client began address acquisition or renewal process. */
	dhcp4_hdr_flags_t flags; /* Flags. */
	uint8_t		mbz;	/* MUST BE ZERO (reserved for future use). */
	uint32_t	ciaddr;	/* Client IP address; only filled in if client is in BOUND, RENEW or REBINDING state and can respond to ARP requests. */
	uint32_t	yiaddr;	/* 'your' (client) IP address. */
	uint32_t	siaddr;	/* IP address of next server to use in bootstrap; returned in DHCPOFFER, DHCPACK by server. */
	uint32_t	giaddr;	/* Relay agent IP address, used in booting via a relay agent. */
	uint8_t		chaddr[16];/* Client hardware address. */
	uint8_t		sname[64];/* Optional server host name, null terminated string. */
	uint8_t		file[128];/* Boot file name, null terminated string; "generic" name or null in DHCPDISCOVER, fully qualified directory-path name in DHCPOFFER. */
	uint8_t		magic_cookie[4];
	/* Optional parameters field. */
} __attribute__((__packed__)) dhcp4_hdr_t, *dhcp4_hdr_p;

/* Message op code / message type. */
#define DHCP4_HDR_OP_BOOTREQUEST	1
#define DHCP4_HDR_OP_BOOTREPLY		2
#define DHCP4_HDR_HTYPE_MAX		38
#define DHCP4_HDR_HLEN_MAX		16

static const char *dhcp4_header_op[] = {
/*   0 */	NULL,
/*   1 */	"BOOTREQUEST",
/*   2 */	"BOOTREPLY",
};

static const char *dhcp4_header_htype[] = {
/*   0 */	"Reserved",
/*   1 */	"Ethernet (10Mb)",
/*   2 */	"Experimental Ethernet (3Mb)",
/*   3 */	"Amateur Radio AX.25",
/*   4 */	"Proteon ProNET Token Ring",
/*   5 */	"Chaos",
/*   6 */	"IEEE 802 Networks",
/*   7 */	"ARCNET",
/*   8 */	"Hyperchannel",
/*   9 */	"Lanstar",
/*  10 */	"Autonet Short Address",
/*  11 */	"LocalTalk",
/*  12 */	"LocalNet (IBM PCNet or SYTEK LocalNET)",
/*  13 */	"Ultra link",
/*  14 */	"SMDS",
/*  15 */	"Frame Relay",
/*  16 */	"Asynchronous Transmission Mode (ATM)",
/*  17 */	"HDLC",
/*  18 */	"Fibre Channel",
/*  19 */	"Asynchronous Transmission Mode (ATM)",
/*  20 */	"Serial Line",
/*  21 */	"Asynchronous Transmission Mode (ATM)",
/*  22 */	"MIL-STD-188-220",
/*  23 */	"Metricom",
/*  24 */	"IEEE 1394.1995",
/*  25 */	"MAPOS",
/*  26 */	"Twinaxial",
/*  27 */	"EUI-64",
/*  28 */	"HIPARP",
/*  29 */	"IP and ARP over ISO 7816-3",
/*  30 */	"ARPSec",
/*  31 */	"IPsec tunnel",
/*  32 */	"InfiniBand (TM)",
/*  33 */	"TIA-102 Project 25 Common Air Interface (CAI)",
/*  34 */	"Wiegand Interface",
/*  35 */	"Pure IP",
/*  36 */	"HW_EXP1",
/*  37 */	"HFI",
};

static const uint8_t dhcp4_hdr_magic_cookie[4] = {
	0x63, 0x82, 0x53, 0x63
};



/* DHCP Standard Options. */
/* RFC 2132 */
/* 3. RFC 1497 Vendor Extensions. */
#define DHCP4_OPT_PAD			0
#define DHCP4_OPT_SUBNET_MASK		1
#define DHCP4_OPT_TIME_OFFSET		2  /* Deprecated by RFC 4833 (100, 101). */
#define DHCP4_OPT_ROUTER_ADDRESS	3
#define DHCP4_OPT_TIME_SERVERS		4
#define DHCP4_OPT_IEN116_NAME_SERVERS	5
#define DHCP4_OPT_DOMAIN_NAME_SERVERS	6
#define DHCP4_OPT_LOG_SERVERS		7
#define DHCP4_OPT_COOKIE_SERVERS	8
#define DHCP4_OPT_LPR_SERVERS		9
#define DHCP4_OPT_IMPRESS_SERVERS	10
#define DHCP4_OPT_RLP_SERVERS		11
#define DHCP4_OPT_HOST_NAME		12
#define DHCP4_OPT_BOOT_FILE_SIZE	13
#define DHCP4_OPT_MERIT_DUMP_FILE	14
#define DHCP4_OPT_DOMAIN_NAME		15
#define DHCP4_OPT_SWAP_SERVER		16
#define DHCP4_OPT_ROOT_PATH		17
#define DHCP4_OPT_EXTENSIONS_PATH	18
/* 4. IP Layer Parameters per Host. */
#define DHCP4_OPT_IP_FORWARD_ENABLE	19
#define DHCP4_OPT_NON_LOCAL_SOURCE_ROUTING 20
#define DHCP4_OPT_POLICY_FILTER		21
#define DHCP4_OPT_MAX_DATAGRAM_REASSEMBLY_SZ 22
#define DHCP4_OPT_IP_DEFAULT_TTL	23
#define DHCP4_OPT_PMTU_AGING_TIMEOUT	24
#define DHCP4_OPT_PMTU_PLATEAU_TABLE	25
/* 5. IP Layer Parameters per Interface. */
#define DHCP4_OPT_INTERFACE_MTU		26
#define DHCP4_OPT_ALL_SUBNETS_LOCAL	27
#define DHCP4_OPT_BROADCAST_ADDRESS	28
#define DHCP4_OPT_PERFORM_MASK_DISCOVERY 29
#define DHCP4_OPT_PROVIDE_MASK_TO_OTHERS 30
#define DHCP4_OPT_PERFORM_ROUTER_DISCOVERY 31
#define DHCP4_OPT_ROUTER_SOLICITATION_ADDR 32
#define DHCP4_OPT_STATIC_ROUTES		33
/* 6. Link Layer Parameters per Interface. */
#define DHCP4_OPT_TRAILER_ENCAPSULATION	34
#define DHCP4_OPT_ARP_CACHE_TIMEOUT	35
#define DHCP4_OPT_ETHERNET_ENCAPSULATION 36
/* 7. TCP Parameters. */
#define DHCP4_OPT_DEFAULT_TCP_TTL	37
#define DHCP4_OPT_KEEP_ALIVE_INTERVAL	38
#define DHCP4_OPT_KEEP_ALIVE_GARBAGE	39
/* 8. Application and Service Parameters. */
#define DHCP4_OPT_NIS_DOMAIN_NAME	40
#define DHCP4_OPT_NIS_SERVERS		41
#define DHCP4_OPT_NTP_SERVERS		42
/* 8.4. Vendor Specific Information. */
#define DHCP4_OPT_VENDOR_SPEC_INFO	43	/* http://msdn.microsoft.com/en-us/library/cc227275%28v=PROT.10%29.aspx */
/* NetBIOS over TCP/IP Name server option. */
#define DHCP4_OPT_NETBIOS_NAME_SERVERS	44
#define DHCP4_OPT_NETBIOS_DGM_DIST_SERVER 45
#define DHCP4_OPT_NETBIOS_NODE_TYPE	46
#define DHCP4_OPT_NETBIOS_SCOPE_OPTION	47
/* X Window System Options. */
#define DHCP4_OPT_X_WINDOW_FONT_SERVER	48
#define DHCP4_OPT_X_WINDOW_DISPLAY_MANAGER 49
/* 9. DHCP Extensions. */
#define DHCP4_OPT_REQUESTED_IP_ADDRESS	50
#define DHCP4_OPT_IP_ADDRESS_LEASE_TIME	51
#define DHCP4_OPT_OVERLOAD		52
/* */
#define DHCP4_OPT_MESSAGE_TYPE		53
#define DHCP4_OPT_MESSAGE_TYPE_DISCOVER		1	/* RFC 2132 DHCP Options and BOOTP Vendor Extensions. */
#define DHCP4_OPT_MESSAGE_TYPE_OFFER		2	/* RFC 2132 DHCP Options and BOOTP Vendor Extensions. */
#define DHCP4_OPT_MESSAGE_TYPE_REQUEST		3	/* RFC 2132 DHCP Options and BOOTP Vendor Extensions. */
#define DHCP4_OPT_MESSAGE_TYPE_DECLINE		4	/* RFC 2132 DHCP Options and BOOTP Vendor Extensions. */
#define DHCP4_OPT_MESSAGE_TYPE_ACK		5	/* RFC 2132 DHCP Options and BOOTP Vendor Extensions. */
#define DHCP4_OPT_MESSAGE_TYPE_NAK		6	/* RFC 2132 DHCP Options and BOOTP Vendor Extensions. */
#define DHCP4_OPT_MESSAGE_TYPE_RELEASE		7	/* RFC 2132 DHCP Options and BOOTP Vendor Extensions. */
#define DHCP4_OPT_MESSAGE_TYPE_INFORM		8	/* RFC 2132 DHCP Options and BOOTP Vendor Extensions. */
#define DHCP4_OPT_MESSAGE_TYPE_FORCE_RENEW	9	/* RFC 3203 DHCP reconfigure extension. */
#define DHCP4_OPT_MESSAGE_TYPE_DHCPLEASEQUERY	10	/* RFC 4388 DHCP Leasequery. */
#define DHCP4_OPT_MESSAGE_TYPE_DHCPLEASEUNASSIGNED 11	/* RFC 4388 DHCP Leasequery. */
#define DHCP4_OPT_MESSAGE_TYPE_DHCPLEASEUNKNOWN	12	/* RFC 4388 DHCP Leasequery. */
#define DHCP4_OPT_MESSAGE_TYPE_DHCPLEASEACTIVE	13	/* RFC 4388 DHCP Leasequery. */
/* */
#define DHCP4_OPT_DHCP4_SERVER_IDENTIFIER 54
#define DHCP4_OPT_PARAMETER_REQUEST_LIST 55
#define DHCP4_OPT_MESSAGE		56
#define DHCP4_OPT_DHCP_MAXIMUM_MSG_SIZE	57
#define DHCP4_OPT_RENEWAL_TIME		58	/* T1. */
#define DHCP4_OPT_REBINDING_TIME	59	/* T2. */
#define DHCP4_OPT_VENDOR_CLASS_IDENTIFIER 60
#define DHCP4_OPT_DHCP4_CLIENT_IDENTIFIER 61	/* upd: RFC 4361 Node-specific Identifiers for DHCPv4. */
#define DHCP4_OPT_NETWARE_DOMAIN_NAME	62	/* RFC 2242 NetWare/IP Domain Name and Information. */
#define DHCP4_OPT_NETWARE_SUB_OPTIONS	63	/* RFC 2242 NetWare/IP Domain Name and Information. */
#define DHCP4_OPT_NIS_CLIENT_DOMAIN_NAME 64
#define DHCP4_OPT_NIS_SERVER_ADDRESS	65
#define DHCP4_OPT_TFTP_SERVER_NAME	66
#define DHCP4_OPT_BOOTFILE_NAME		67
#define DHCP4_OPT_HOME_AGENT_ADDRESS	68
#define DHCP4_OPT_SMTP_SERVER_ADDRESS	69
#define DHCP4_OPT_POP3_SERVER_ADDRESS	70
#define DHCP4_OPT_NNTP_SERVER_ADDRESS	71
#define DHCP4_OPT_WWW_SERVER_ADDRESS	72
#define DHCP4_OPT_FINGER_SERVER_ADDRESS	73
#define DHCP4_OPT_IRC_SERVER_ADDRESS	74
#define DHCP4_OPT_STREETTALK_SERVER_ADDRESS 75
#define DHCP4_OPT_STREETTALK_DIRECTORY_ASSIST_SRV 76
#define DHCP4_OPT_USER_CLASS		77	/* RFC 3004 The User Class Option for DHCP. */
#define DHCP4_OPT_SLP_DIRECTORY_AGENT	78	/* RFC 2610 DHCP Options for Service Location Protocol. */
#define DHCP4_OPT_SLP_SERVICE_SCOPE	79	/* RFC 2610 DHCP Options for Service Location Protocol. */
#define DHCP4_OPT_RAPID_COMMIT		80	/* RFC 4039 Rapid Commit Option for DHCPv4. */
#define DHCP4_OPT_CLIENT_FQDN		81	/* RFC 4702 The DHCP Client FQDN Option. */
typedef struct dhcp4_opt_client_fqdn_flags_s {
	uint8_t mbz:4;	/* MUST BE ZERO (reserved for future use). */
	uint8_t n:1;	/* CS // indicates the encoding of the Domain Name field. */
	uint8_t e:1;	/* CS // indicates whether the server SHOULD NOT perform any DNS updates. */
	uint8_t o:1;	/* -S // indicates whether the server has overridden the client's preference for the "S" bit. */
	uint8_t s:1;	/* CS // indicates whether the server SHOULD or SHOULD NOT perform the A RR (FQDN-to-address) DNS updates. */
} __attribute__((__packed__)) dhcp4_opt_client_fqdn_flags_t, *dhcp4_opt_client_fqdn_flags_p;
/* */
#define DHCP4_OPT_RELAY_AGENT_INFO	82	/* RFC 3046 DHCP Relay Agent Information Option. */
#define DHCP4_OPT_RELAY_AGENT_INFO_CIRCUIT_ID		1	/* RFC 3046 DHCP Relay Agent Information Option. */
#define DHCP4_OPT_RELAY_AGENT_INFO_REMOTE_ID		2	/* RFC 3046 DHCP Relay Agent Information Option. */
#define DHCP4_OPT_RELAY_AGENT_INFO_DOCSIS_DEVICE_CLASS	4	/* RFC 3046 DHCP Relay Agent Information Option. */
#define DHCP4_OPT_RELAY_AGENT_INFO_RELAY_LINK_SELECTION	5	/* RFC 3046 DHCP Relay Agent Information Option. */
#define DHCP4_OPT_RELAY_AGENT_INFO_SUBSCRIBER_ID	6	/* RFC 3046 DHCP Relay Agent Information Option. */
#define DHCP4_OPT_RELAY_AGENT_INFO_RADIUS_ATTRIBUTES	7	/* RFC 3046 DHCP Relay Agent Information Option. */
#define DHCP4_OPT_RELAY_AGENT_INFO_AUTHENTICATION_INFO	8	/* */
#define DHCP4_OPT_RELAY_AGENT_INFO_VENDOR_SPECIFIC_INFO	9	/* */
#define DHCP4_OPT_RELAY_AGENT_INFO_RELAY_AGENT_FLAGS	10	/* */
#define DHCP4_OPT_RELAY_AGENT_INFO_SERVER_ID_OVERRIDE	11	/* */ 
/* */
#define DHCP4_OPT_ISNS			83	/* RFC 4174 DHCP Option Number for iSNS. */
/* */
#define DHCP4_OPT_NDS_SERVERS		85	/* DHCP Options for Novell Directory Services. */
#define DHCP4_OPT_NDS_TREE_NAME		86	/* DHCP Options for Novell Directory Services. */
#define DHCP4_OPT_NDS_CONTEXT		87	/* DHCP Options for Novell Directory Services. */
#define DHCP4_OPT_BCMCS_CTRL_DOMAIN_NAME_LST 88	/* RFC 3679 // RFC 4280 DHCP Options for BMCS. */
#define DHCP4_OPT_BCMCS_CTRL_IPV4_ADDRESS 89	/* RFC 3679 // RFC 4280 DHCP Options for BMCS. */
#define DHCP4_OPT_AUTHENTICATION	90	/* RFC 3118 Authentication for DHCP Messages. */
#define DHCP4_OPT_CLI_LAST_TRANSACTION_TIME 91	/* RFC 3679 // RFC 4388 DHCP Leasequery. */
#define DHCP4_OPT_ASSOCIATED_IP		92	/* RFC 3679 // RFC 4388 DHCP Leasequery. */
#define DHCP4_OPT_CLIENT_SYSTEM_ARCHITECTURE 93	/* RFC 4578 DHCP PXE Options. */
#define DHCP4_OPT_CLIENT_NET_INTERFACE_ID 94	/* RFC 4578 DHCP PXE Options. */
/* */
#define DHCP4_OPT_CLIENT_MACHINE_ID	97	/* RFC 4578 DHCP PXE Options. */
#define DHCP4_OPT_UAP			98	/* RFC 2485 DHCP Option for The Open Group's User Authentication Protocol. */
#define DHCP4_OPT_GEOCONF_CIVIC		99	/* RFC 4776 Option for Civic Addresses Configuration Information. */
#define DHCP4_OPT_TZ_POSIX_STRING	100	/* RFC 4833 Timezone Options for DHCP. */
#define DHCP4_OPT_TZ_DATABASE_STRING	101	/* RFC 4833 Timezone Options for DHCP. */
/* */
#define DHCP4_OPT_AUTO_CONFIGURE	116	/* RFC 2563 DHCP Option to Disable Stateless Auto-Configuration in IPv4 Clients. */
#define DHCP4_OPT_NAME_SERVICE_SEARCH	117	/* RFC 2937 The Name Service Search Option for DHCP. */
#define DHCP4_OPT_SUBNET_SELECTION	118	/* RFC 3011 The IPv4 Subnet Selection Option for DHCP. */
/* */
#define DHCP4_OPT_CLASSLESS_STATIC_ROUTE 121	/* RFC 3442 Classless Static Route Option for DHCPv4. */
#define DHCP4_OPT_CABLELABS_CLIENT_CONFIG 122	/* RFC 3495 DHCP Option for CableLabs Clients. */
#define DHCP4_OPT_LOCATION_CONFIG_INFO	123	/* RFC 3825 DHCP Option for Coordinate LCI. */
/* */
#define DHCP4_OPT_PANA_AUTHENTICATION_AGENT 136	/* RFC 5192 PAA DHCP Options. */
#define DHCP4_OPT_LOST_SERVER		137	/* RFC 5223 DHCP-Based LoST Discovery. */
/* */
#define DHCP4_OPT_MOS_ADDRESS		139	/* RFC 5678 Mobility Services for DCHP Options. */
#define DHCP4_OPT_MOS_DOMAIN_NAME_LIST	140	/* RFC 5678 Mobility Services for DCHP Options. */
/* */
#define DHCP4_OPT_TFTP_SERVER_IP_ADDRESSES 150	/* RFC 5859 TFTP Server Address. */
/* */
#define DHCP4_OPT_PXELINUX_MAGIC	208	/* RFC 5071 PXELINUX Options. F1:00:74:7E */
#define DHCP4_OPT_PXELINUX_CONFIG_FILE	209	/* RFC 5071 PXELINUX Options. */
#define DHCP4_OPT_PXELINUX_PATH_PREFIX	210	/* RFC 5071 PXELINUX Options. */
#define DHCP4_OPT_PXELINUX_REBOOT_TIME	211	/* RFC 5071 PXELINUX Options. */
/* */
#define DHCP4_OPT_END			255


typedef struct dhcp4_option_data_s {
	uint8_t		code;	/* DHCP4_OPT_* (Assigned by IANA.). */
	uint8_t		len;	/* Size (in octets) of OPTION-DATA. */
	/* data: varies per OPTION-CODE. */
} __attribute__((__packed__)) dhcp4_opt_data_t, *dhcp4_opt_data_p;


/* Struct describes options for app internal use. */
typedef struct dhcp4_option_params_s {
	const char	*disp_name;	/* User friendly display name. */
	uint8_t		len;		/* Len. */
	uint8_t		type;		/* Data type - parser hint. */
	uint8_t		flags;		/* Flags with additional info. */
	const void	*data_vals;	/* Extra data for parsing. */
	size_t		data_vals_cnt;	/* Extra data items count. */
} dhcp4_opt_params_t, *dhcp4_opt_params_p;

/* Type. */
#define DHCP4_OPTP_T_NONE	  0
#define DHCP4_OPTP_T_SUBOPTS	  1 /* data_vals points to dhcp4_opt_params_t array. */
#define DHCP4_OPTP_T_BOOL	  2 /* uint8_t: 0/1. */
#define DHCP4_OPTP_T_1BYTE	  3 /* uint8_t */
#define DHCP4_OPTP_T_2BYTE	  4 /* uint16_t */
#define DHCP4_OPTP_T_2TIME	  5 /* uint16_t */
#define DHCP4_OPTP_T_4BYTE	  6 /* uint32_t */
#define DHCP4_OPTP_T_4TIME	  7 /* uint32_t */
#define DHCP4_OPTP_T_IPADDR	  8 /* uint32_t */
#define DHCP4_OPTP_T_IPIPADDR	  9 /* uint32_t[2] */
#define DHCP4_OPTP_T_STR	 10 /* char array. */
#define DHCP4_OPTP_T_STRUTF8	 11 /* char array. */
#define DHCP4_OPTP_T_STRRR	 12 /* DNS string format. */
#define DHCP4_OPTP_T_BYTES	 13 /* uint8_t array. */
#define DHCP4_OPTP_T_ADV	 14 /* Option have specific format. */
#define DHCP4_OPTP_T_PAD	254
#define DHCP4_OPTP_T_END	255

/* Flags. */
#define DHCP4_OPTP_F_NONE	0
#define DHCP4_OPTP_F_NOLEN	(((uint8_t)1) << 0) /* Option does not have len field. */
#define DHCP4_OPTP_F_FIXEDLEN	(((uint8_t)1) << 1) /* Option len have fixed value. */
#define DHCP4_OPTP_F_MINLEN	(((uint8_t)1) << 2) /* Minimum option len is known. */
#define DHCP4_OPTP_F_ARRAY	(((uint8_t)1) << 3) /* In case (FIXEDLEN + ARRAY), Len = sizeof 1 element. */



#define DHCP4_OPT_PARAMS_UNKNOWN {					\
	.disp_name = "Unknown",						\
	.len = 0,							\
	.type = DHCP4_OPTP_T_BYTES,					\
	.flags = DHCP4_OPTP_F_MINLEN,					\
	.data_vals = NULL,						\
	.data_vals_cnt = 0,						\
}
#define DHCP4_OPT_PARAMS_PAD {						\
	.disp_name = "PAD",						\
	.len = 0,							\
	.type = DHCP4_OPTP_T_PAD,					\
	.flags = DHCP4_OPTP_F_NOLEN,					\
	.data_vals = NULL,						\
	.data_vals_cnt = 0,						\
}
#define DHCP4_OPT_PARAMS_END {						\
	.disp_name = "END",						\
	.len = 0,							\
	.type = DHCP4_OPTP_T_END,					\
	.flags = DHCP4_OPTP_F_NOLEN,					\
	.data_vals = NULL,						\
	.data_vals_cnt = 0,						\
}

static const dhcp4_opt_params_t dhcp4_opt_params_unknown = DHCP4_OPT_PARAMS_UNKNOWN;
static const dhcp4_opt_params_t dhcp4_opt_params_pad = DHCP4_OPT_PARAMS_PAD;
static const dhcp4_opt_params_t dhcp4_opt_params_end = DHCP4_OPT_PARAMS_END;



static const char *dhcp4_opt_enabledisable[] = {
/*   0 */	"disabled",
/*   1 */	"enabled"
};


static const char *dhcp4_opt36[] = {
/*   0 */	"Ethernet version 2",
/*   1 */	"IEEE 802.3",
};


static const char *dhcp4_opt46[] = {
/*   0 */	NULL,
/*   1 */	"B-node",
/*   2 */	"P-node",
/*   3 */	NULL,
/*   4 */	"M-node",
/*   5 */	NULL,
/*   6 */	NULL,
/*   7 */	NULL,
/*   8 */	"H-node",
};


static const char *dhcp4_opt52[] = {
/*  0 */	NULL,
/*  1 */	"file field holds options",
/*  2 */	"sname field holds options",
/*  3 */	"file and sname field holds options",
};


static const char *dhcp4_opt53[] = {
/*   0 */	NULL,
/*   1 */	"DISCOVER",
/*   2 */	"OFFER",
/*   3 */	"REQUEST",
/*   4 */	"DECLINE",
/*   5 */	"ACK",
/*   6 */	"NAK",
/*   7 */	"RELEASE",
/*   8 */	"INFORM",
/*   9 */	"FORCE RENEW",
/*  10 */	"DHCPLEASEQUERY",
/*  11 */	"DHCPLEASEUNASSIGNED",
/*  12 */	"DHCPLEASEUNKNOWN",
/*  13 */	"DHCPLEASEACTIVE",
/*  14 */	"DHCPBULKLEASEQUERY",
/*  15 */	"DHCPLEASEQUERYDONE",
/*  16 */	"DHCPACTIVELEASEQUERY",
/*  17 */	"DHCPLEASEQUERYSTATUS",
/*  18 */	"DHCPTLS",
};


/* XXX: need init on first use, map to dhcp4_options[]->disp_name. */
static const char *dhcp4_opt55[256] = { NULL };


/* http://technet.microsoft.com/en-us/library/cc977371.aspx */
static const char *dhcp4_opt43_MSFT_1[] = {
/*   0 */	NULL,
/*   1 */	"enabled", /* NetBT remains enabled. */
/*   2 */	"disabled" /* Disable NetBIOS over TCP/IP (NetBT) for Windows 2000 DHCP clients. */
};

static const dhcp4_opt_params_t dhcp4_opt43_MSFT[] = {
/*   0 */	DHCP4_OPT_PARAMS_PAD,
/*   1 */	{
			.disp_name = "NetBIOS over TCP/IP (NetBT)",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
			.data_vals = dhcp4_opt43_MSFT_1,
			.data_vals_cnt = nitems(dhcp4_opt43_MSFT_1),
		},
/*   2 */	{
			.disp_name = "Release DHCP Lease on Shutdown",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
			.data_vals = dhcp4_opt_enabledisable,
			.data_vals_cnt = nitems(dhcp4_opt_enabledisable),
		},
/*   3 */	{
			.disp_name = "Default Router Metric Base",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*   4 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*   5 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*   6 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*   7 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*   8 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*   9 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  10 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  11 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  12 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  13 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  14 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  15 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  16 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  17 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  18 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  19 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  20 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  21 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  22 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  23 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  24 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  25 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  26 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  27 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  28 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  29 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  30 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  31 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  32 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  33 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  34 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  35 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  36 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  37 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  38 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  39 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  40 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  41 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  42 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  43 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  44 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  45 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  46 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  47 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  48 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  49 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  50 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  51 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  52 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  53 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  54 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  55 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  56 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  57 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  58 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  59 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  60 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  61 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  62 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  63 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  64 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  65 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  66 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  67 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  68 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  69 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  70 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  71 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  72 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  73 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  74 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  75 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  76 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  77 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  78 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  79 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  80 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  81 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  82 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  83 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  84 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  85 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  86 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  87 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  88 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  89 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  90 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  91 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  92 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  93 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  94 */	{ /* http://msdn.microsoft.com/en-us/library/ee808389%28v=PROT.10%29.aspx */
			.disp_name = "Rogue Detection Request",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  95 */	{ /* http://msdn.microsoft.com/en-us/library/ee791538%28v=PROT.10%29.aspx */
			.disp_name = "Rogue Detection Reply",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  96 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  97 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  98 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*  99 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 100 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 101 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 102 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 103 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 104 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 105 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 106 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 107 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 108 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 109 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 110 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 111 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 112 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 113 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 114 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 115 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 116 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 117 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 118 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 119 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 120 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 121 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 122 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 123 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 124 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 125 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 126 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 127 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 128 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 129 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 130 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 131 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 132 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 133 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 134 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 135 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 136 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 137 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 138 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 139 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 140 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 141 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 142 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 143 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 144 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 145 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 146 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 147 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 148 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 149 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 150 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 151 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 152 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 153 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 154 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 155 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 156 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 157 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 158 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 159 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 160 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 161 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 162 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 163 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 164 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 165 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 166 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 167 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 168 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 169 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 170 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 171 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 172 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 173 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 174 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 175 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 176 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 177 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 178 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 179 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 180 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 181 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 182 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 183 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 184 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 185 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 186 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 187 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 188 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 189 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 190 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 191 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 192 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 193 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 194 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 195 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 196 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 197 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 198 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 199 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 200 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 201 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 202 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 203 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 204 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 205 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 206 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 207 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 208 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 209 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 210 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 211 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 212 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 213 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 214 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 215 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 216 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 217 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 218 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 219 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 220 */	{ /* http://technet.microsoft.com/en-us/library/cc227332(PROT.10).aspx */
			.disp_name = "NAP-SoH",
			.len = 0,
			.type = DHCP4_OPTP_T_BYTES,
			.flags = 0, /* XXX: check this. */
		},
/* 221 */	{
			.disp_name = "NAP-Mask",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/* 222 */	{
			.disp_name = "NAP-CoID",
			.len = 130,
			.type = DHCP4_OPTP_T_BYTES,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/* 223 */	{
			.disp_name = "NAP-IPv6",
			.len = 1,
			.type = DHCP4_OPTP_T_BYTES,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
};


static const dhcp4_opt_params_t dhcp4_opt82_1[] = {
/*   0 */	{ /* RFC 3046 DHCP Relay Agent Information Option. */
			.disp_name = "VLAN(xx)/Module(x)/Port(x)",
			.len = 4,
			.type = DHCP4_OPTP_T_BYTES,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
};

static const dhcp4_opt_params_t dhcp4_opt82_2[] = {
/*   0 */	{ /* RFC 3046 DHCP Relay Agent Information Option. */
			.disp_name = "MAC address",
			.len = 6,
			.type = DHCP4_OPTP_T_BYTES,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*   1 */	{ /* RFC 3046 DHCP Relay Agent Information Option. */
			.disp_name = "User-defined string",
			.len = 1,
			.type = DHCP4_OPTP_T_BYTES/*DHCP4_OPTP_T_STR*/,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
};

static const dhcp4_opt_params_t dhcp4_opt82[] = {
/*   0 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*   1 */	{ /* RFC 3046 DHCP Relay Agent Information Option. */
			.disp_name = "Circuit ID",
			.len = 2,
			.type = DHCP4_OPTP_T_SUBOPTS,
			.flags = DHCP4_OPTP_F_MINLEN,
			.data_vals = (const void*)dhcp4_opt82_1,
			.data_vals_cnt = nitems(dhcp4_opt82_1),
		},
/*   2 */	{ /* RFC 3046 DHCP Relay Agent Information Option. */
			.disp_name = "Remote ID",
			.len = 2,
			.type = DHCP4_OPTP_T_SUBOPTS,
			.flags = DHCP4_OPTP_F_MINLEN,
			.data_vals = (const void*)dhcp4_opt82_2,
			.data_vals_cnt = nitems(dhcp4_opt82_2),
		},
/*   3 */	DHCP4_OPT_PARAMS_UNKNOWN,
/*   4 */	{ /* RFC 3256 The DOCSIS Device Class DHCP. */
			.disp_name = "DOCSIS Device Class",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*   5 */	{ /* RFC 3527 Link Selection sub-option. */
			.disp_name = "Link selection",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*   6 */	{ /* RFC 3993 Subscriber-ID Suboption. */
			.disp_name = "Subscriber-ID",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*   7 */	{ /* RFC 4014 RADIUS Attributes Suboption. */
			.disp_name = "RADIUS Attributes",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*   8 */	{ /* RFC 4030 Authentication Suboption. */
			.disp_name = "Authentication",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*   9 */	{ /* RFC 4243 Vendor-Specific Relay Suboption. */
			.disp_name = "Vendor-Specific",
			.len = 4,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  10 */	{ /* RFC 5010 Relay Agent Flags Suboption. */
			.disp_name = "Flags",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  11 */	{ /* RFC 5107 Server ID Override Suboption, see opt 54 - DHCP Server identifier. */
			.disp_name = "Server ID Override",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
};


static const dhcp4_opt_params_t dhcp4_options[256] = {
/* Start RFC 2132. */
/*   0 */	DHCP4_OPT_PARAMS_PAD,
/*   1 */	{
			.disp_name = "Subnet mask",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*   2 */	{ /* Deprecated by RFC 4833 (see opt: 100, 101). */
			.disp_name = "Time offset",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*   3 */	{
			.disp_name = "Routers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*   4 */	{
			.disp_name = "Time servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*   5 */	{
			.disp_name = "Name servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*   6 */	{
			.disp_name = "DNS servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*   7 */	{
			.disp_name = "Log servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*   8 */	{
			.disp_name = "Cookie servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*   9 */	{
			.disp_name = "LPR servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  10 */	{
			.disp_name = "Impress servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  11 */	{
			.disp_name = "Resource location servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  12 */	{
			.disp_name = "Host name",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  13 */	{
			.disp_name = "Boot file size",
			.len = 2,
			.type = DHCP4_OPTP_T_2BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  14 */	{
			.disp_name = "Merit dump file",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  15 */	{
			.disp_name = "Domain Name",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  16 */	{
			.disp_name = "Swap server",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  17 */	{
			.disp_name = "Root path",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  18 */	{
			.disp_name = "Extensions path",
			.len = 1,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  19 */	{
			.disp_name = "IP forwarding",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  20 */	{
			.disp_name = "Non-local source routing",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  21 */	{
			.disp_name = "Policy filter (dst net/mask)",
			.len = 8,
			.type = DHCP4_OPTP_T_IPIPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  22 */	{
			.disp_name = "Max dgram reassembly size",
			.len = 2,
			.type = DHCP4_OPTP_T_2BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  23 */	{
			.disp_name = "Default IP TTL",
			.len = 1,
			.type = DHCP4_OPTP_T_1BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  24 */	{
			.disp_name = "Path MTU aging timeout",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  25 */	{
			.disp_name = "Path MTU plateau table",
			.len = 2,
			.type = DHCP4_OPTP_T_2BYTE,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  26 */	{
			.disp_name = "Interface MTU",
			.len = 2,
			.type = DHCP4_OPTP_T_2BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  27 */	{
			.disp_name = "All subnets local",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  28 */	{
			.disp_name = "Broadcast address",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  29 */	{
			.disp_name = "Perform mask discovery",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  30 */	{
			.disp_name = "Mask supplier",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  31 */	{
			.disp_name = "Perform router discovery",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  32 */	{
			.disp_name = "Router solicitation",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  33 */	{
			.disp_name = "Static route (dst host/router)",
			.len = 8,
			.type = DHCP4_OPTP_T_IPIPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  34 */	{
			.disp_name = "Trailer encapsulation",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  35 */	{
			.disp_name = "ARP cache timeout",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  36 */	{
			.disp_name = "Ethernet encapsulation",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
			.data_vals = dhcp4_opt36,
			.data_vals_cnt = nitems(dhcp4_opt36),
		},
/*  37 */	{
			.disp_name = "TCP default TTL",
			.len = 1,
			.type = DHCP4_OPTP_T_1BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  38 */	{
			.disp_name = "TCP keepalive interval",
			.len = 4,
			.type = DHCP4_OPTP_T_4TIME,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  39 */	{
			.disp_name = "TCP keepalive garbage",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  40 */	{
			.disp_name = "NIS domain",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  41 */	{
			.disp_name = "NIS servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  42 */	{
			.disp_name = "NTP servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  43 */	{ /* http://msdn.microsoft.com/en-us/library/cc227275%28v=PROT.10%29.aspx */
			.disp_name = "Vendor specific info",
			.len = 1,
			.type = DHCP4_OPTP_T_SUBOPTS,
			.flags = DHCP4_OPTP_F_MINLEN,
			.data_vals = (const void*)dhcp4_opt43_MSFT,
			.data_vals_cnt = nitems(dhcp4_opt43_MSFT),
		},
/*  44 */	{
			.disp_name = "NetBIOS name servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  45 */	{
			.disp_name = "NetBIOS dgram distrib servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  46 */	{
			.disp_name = "NetBIOS node type",
			.len = 1,
			.type = DHCP4_OPTP_T_1BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
			.data_vals = dhcp4_opt46,
			.data_vals_cnt = nitems(dhcp4_opt46),
		},
/*  47 */	{
			.disp_name = "NetBIOS scope",
			.len = 1,
			.type = DHCP4_OPTP_T_BYTES,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  48 */	{
			.disp_name = "X Window font servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  49 */	{
			.disp_name = "X Window display servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  50 */	{
			.disp_name = "Request IP address",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  51 */	{
			.disp_name = "IP address lease time",
			.len = 4,
			.type = DHCP4_OPTP_T_4TIME,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  52 */	{
			.disp_name = "Option overload",
			.len = 1,
			.type = DHCP4_OPTP_T_1BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
			.data_vals = dhcp4_opt52,
			.data_vals_cnt = nitems(dhcp4_opt52),
		},
/*  53 */	{
			.disp_name = "DHCP message type",
			.len = 1,
			.type = DHCP4_OPTP_T_1BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
			.data_vals = dhcp4_opt53,
			.data_vals_cnt = nitems(dhcp4_opt53),
		},
/*  54 */	{
			.disp_name = "DHCP Server identifier",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  55 */	{
			.disp_name = "Parameter Request List",
			.len = 1,
			.type = DHCP4_OPTP_T_1BYTE,
			.flags = (DHCP4_OPTP_F_MINLEN | DHCP4_OPTP_F_ARRAY),
			.data_vals = dhcp4_opt55,
			.data_vals_cnt = nitems(dhcp4_opt55),
		},
/*  56 */	{
			.disp_name = "Message",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  57 */	{
			.disp_name = "Maximum DHCP message size",
			.len = 2,
			.type = DHCP4_OPTP_T_2BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  58 */	{
			.disp_name = "Renew time (T1)",
			.len = 4,
			.type = DHCP4_OPTP_T_4TIME,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  59 */	{
			.disp_name = "Rebind time (T2)",
			.len = 4,
			.type = DHCP4_OPTP_T_4TIME,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  60 */	{
			.disp_name = "Vendor class identifier",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  61 */	{ /* upd: RFC 4361. */
			.disp_name = "DHCP Client identifier",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  62 */	{ /* RFC 2242. */
			.disp_name = "Netware/IP domain name",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  63 */	{ /* RFC 2242. */
			.disp_name = "Netware/IP domain info",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  64 */	{
			.disp_name = "NIS+ domain",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  65 */	{
			.disp_name = "NIS+ servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  66 */	{
			.disp_name = "TFTP server name",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  67 */	{
			.disp_name = "Bootfile name",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  68 */	{
			.disp_name = "Mobile IP home agent",
			.len = 0,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  69 */	{
			.disp_name = "SMTP servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  70 */	{
			.disp_name = "POP3 servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  71 */	{
			.disp_name = "NNTP servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  72 */	{
			.disp_name = "WWW servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  73 */	{
			.disp_name = "Finger servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  74 */	{
			.disp_name = "IRC servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  75 */	{
			.disp_name = "StreetTalk servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  76 */	{
			.disp_name = "StreetTalk dir assist srv",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* End RFC 2132. */
/*  77 */	{ /* RFC 3004 The User Class Option for DHCP. */
			.disp_name = "User Class",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  78 */	{ /* RFC 2610 DHCP Options for Service Location Protocol. */
			.disp_name = "SLP Directory Agent",
			.len = 5,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  79 */	{ /* RFC 2610 DHCP Options for Service Location Protocol. */
			.disp_name = "SLP Service Scope",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  80 */	{ /* RFC 3679 // RFC 4039 Rapid Commit Option for DHCPv4. */
			.disp_name = "Rapid Commit",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  81 */	{ /* RFC 4702 The DHCP Client FQDN Option. */
			.disp_name = "Client FQDN",
			.len = 3,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  82 */	{ /* RFC 3046 DHCP Relay Agent Information Option. */
			.disp_name = "Relay Agent Information",
			.len = 2,
			.type = DHCP4_OPTP_T_SUBOPTS,
			.flags = DHCP4_OPTP_F_MINLEN,
			.data_vals = (const void*)dhcp4_opt82,
			.data_vals_cnt = nitems(dhcp4_opt82),
		},
/*  83 */	{ /* RFC 3679 // RFC 4174 DHCP Option Number for iSNS. */
			.disp_name = "iSNS",
			.len = 18,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  84 */	DHCP4_OPT_PARAMS_UNKNOWN, /* RFC 3679. */
/*  85 */	{ /* RFC 2241 DHCP Options for Novell Directory Services. */
			.disp_name = "NDS server",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  86 */	{ /* RFC 2241 DHCP Options for Novell Directory Services. */
			.disp_name = "NDS tree name",
			.len = 2,
			.type = DHCP4_OPTP_T_STRUTF8,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  87 */	{ /* RFC 2241 DHCP Options for Novell Directory Services. */
			.disp_name = "NDS context",
			.len = 2,
			.type = DHCP4_OPTP_T_STRUTF8,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  88 */	{ /* RFC 3679 // RFC 4280 DHCP Options for BMCS. */
			.disp_name = "BCMCS ctrl Domain Name List",
			.len = 0,
			.type = DHCP4_OPTP_T_STRRR,
			.flags = DHCP4_OPTP_F_ARRAY,
		},
/*  89 */	{ /* RFC 3679 // RFC 4280 DHCP Options for BMCS. */
			.disp_name = "BCMCS ctrl IPv4 Address",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  90 */	{ /* RFC 3118. */
			.disp_name = "Authentication",
			.len = 8,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  91 */	{ /* RFC 3679 // RFC 4388 DHCP Leasequery. */
			.disp_name = "Client last transaction time",
			.len = 4,
			.type = DHCP4_OPTP_T_4TIME,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  92 */	{ /* RFC 3679 // RFC 4388 DHCP Leasequery. */
			.disp_name = "Associated IP",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  93 */	{ /* RFC 3679 // RFC 4578 DHCP PXE Options. */
			.disp_name = "PXE Cli System Architecture",
			.len = 2,
			.type = DHCP4_OPTP_T_2BYTE,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  94 */	{ /* RFC 3679 // RFC 4578 DHCP PXE Options. */
			.disp_name = "PXE Cli Network Interface Id",
			.len = 3,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/*  95 */	{ /* RFC 3679. */
			.disp_name = "LDAP Servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/*  96 */	DHCP4_OPT_PARAMS_UNKNOWN, /* RFC 3679. */
/*  97 */	{ /* RFC 3679 // RFC 4578 DHCP PXE Options. */
			.disp_name = "PXE Client Machine Id",
			.len = 1,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  98 */	{ /* RFC 2485 DHCP Option for The Open Group's User Authentication Protocol. */
			.disp_name = "UAP servers",
			.len = 4,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/*  99 */	{ /* RFC 4776 Option for Civic Addresses Configuration Information. */
			.disp_name = "Civic Location",
			.len = 3,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 100 */	{ /* RFC 3679 // RFC 4833 Timezone Options for DHCP. */
			.disp_name = "Timezone IEEE 1003.1 String",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 101 */	{ /* RFC 3679 // RFC 4833 Timezone Options for DHCP. */
			.disp_name = "Reference to the TZ Database",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 102 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 103 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 104 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 105 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 106 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 107 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 108 */	DHCP4_OPT_PARAMS_UNKNOWN, /* RFC 3679. */
/* 109 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 110 */	DHCP4_OPT_PARAMS_UNKNOWN, /* RFC 3679. */
/* 111 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 112 */	{
			.disp_name = "Netinfo Address",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 113 */	{
			.disp_name = "Netinfo Tag",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 114 */	{ /* RFC 3679. */
			.disp_name = "URL",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 115 */	DHCP4_OPT_PARAMS_UNKNOWN, /* RFC 3679. */
/* 116 */	{ /* RFC 2563 DHCP Option to Disable Stateless Auto-Configuration in IPv4 Clients. */
			.disp_name = "Auto Configure",
			.len = 1,
			.type = DHCP4_OPTP_T_BOOL,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/* 117 */	{ /* RFC 2937 The Name Service Search Option for DHCP. */
			.disp_name = "Name Service Search",
			.len = 2,
			.type = DHCP4_OPTP_T_2BYTE,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 118 */	{ /* RFC 3011 The IPv4 Subnet Selection Option for DHCP. */
			.disp_name = "Subnet selection",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/* 119 */	{
			.disp_name = "Domain Search",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 120 */	{
			.disp_name = "SIP Servers",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 121 */	{ /* RFC 3442 Classless Static Route Option for DHCPv4. */
			.disp_name = "Classless Static Route",
			.len = 5,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 122 */	{ /* RFC 3495 DHCP Option for CableLabs Clients. */
			.disp_name = "CableLabs Client Config",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 123 */	{ /* RFC 3825 DHCP Option for Coordinate LCI. */
			.disp_name = "Location Configuration Info",
			.len = 16,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/* 124 */	{// UNDONE!!!!
			.disp_name = "V-I-Vendor Class",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 125 */	{// UNDONE!!!!
			.disp_name = "V-I-Vendor Specific",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 126 */	{
			.disp_name = "Extension 126",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 127 */	{
			.disp_name = "Extension 127",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 128 */	{// UNDONE!!!!
			.disp_name = "TFTP Srv IP Addr (Etherboot)",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 129 */	{// UNDONE!!!!
			.disp_name = "Call Server IP address",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 130 */	{// UNDONE!!!!
			.disp_name = "Ethernet Interface",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 131 */	{// UNDONE!!!!
			.disp_name = "Remote Stats Svr IP Address",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 132 */	{// UNDONE!!!!
			.disp_name = "IEEE 802.1Q L2 Priority",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 133 */	{// UNDONE!!!!
			.disp_name = "IEEE 802.1P VLAN ID",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 134 */	{// UNDONE!!!!
			.disp_name = "Diffserv Code Point",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 135 */	{// UNDONE!!!!
			.disp_name = "HTTP Proxy",
			.len = 0,
			.type = DHCP4_OPTP_T_NONE,
			.flags = DHCP4_OPTP_F_NONE,
		},
/* 136 */	{ /* RFC 5192 PAA DHCP Options. */
			.disp_name = "PANA Authentication Agent",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 137 */	{ /* RFC 5223 DHCP-Based LoST Discovery. */
			.disp_name = "LoST Server",
			.len = 1,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 138 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 139 */	{ /* RFC 5678 Mobility Services for DCHP Options. */
			.disp_name = "MoS IPv4 Address",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 140 */	{ /* RFC 5678 Mobility Services for DCHP Options. */
			.disp_name = "MoS Domain Name List",
			.len = 2,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 141 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 142 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 143 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 144 */	{
			.disp_name = "HP - TFTP file",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 145 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 146 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 147 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 148 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 149 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 150 */	{ /* RFC 5859 TFTP Server Address. */
			.disp_name = "TFTP Server IP Addresses",
			.len = 4,
			.type = DHCP4_OPTP_T_IPADDR,
			.flags = (DHCP4_OPTP_F_FIXEDLEN | DHCP4_OPTP_F_ARRAY),
		},
/* 151 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 152 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 153 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 154 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 155 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 156 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 157 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 158 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 159 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 160 */	{ /* RFC 7710. */
			.disp_name = "Captive-Portal",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 161 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 162 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 163 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 164 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 165 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 166 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 167 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 168 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 169 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 170 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 171 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 172 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 173 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 174 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 175 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 176 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 177 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 178 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 179 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 180 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 181 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 182 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 183 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 184 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 185 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 186 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 187 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 188 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 189 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 190 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 191 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 192 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 193 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 194 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 195 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 196 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 197 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 198 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 199 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 200 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 201 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 202 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 203 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 204 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 205 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 206 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 207 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 208 */	{ /* RFC 5071 PXELINUX Options. F1:00:74:7E */
			.disp_name = "PXELINUX magic",
			.len = 4,
			.type = DHCP4_OPTP_T_4BYTE,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/* 209 */	{ /* RFC 5071 PXELINUX Options. */
			.disp_name = "PXELINUX Config File",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 210 */	{ /* RFC 5071 PXELINUX Options. */
			.disp_name = "PXELINUX Path Prefix",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 211 */	{ /* RFC 5071 PXELINUX Options. */
			.disp_name = "PXELINUX Reboot Time",
			.len = 4,
			.type = DHCP4_OPTP_T_4TIME,
			.flags = DHCP4_OPTP_F_FIXEDLEN,
		},
/* 212 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 213 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 214 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 215 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 216 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 217 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 218 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 219 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 220 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 221 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 222 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 223 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* Site-specific options. */
/* 224 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 225 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 226 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 227 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 228 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 229 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 230 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 231 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 232 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 233 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 234 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 235 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 236 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 237 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 238 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 239 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 240 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 241 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 242 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 243 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 244 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 245 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 246 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 247 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 248 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 249 */	{ /* MSFT - Classless routes. */
			.disp_name = "MSFT - Classless route",
			.len = 5,
			.type = DHCP4_OPTP_T_ADV,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 250 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 251 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 252 */	{
			.disp_name = "MSFT - Web Proxy Auto Detect",
			.len = 1,
			.type = DHCP4_OPTP_T_STR,
			.flags = DHCP4_OPTP_F_MINLEN,
		},
/* 253 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 254 */	DHCP4_OPT_PARAMS_UNKNOWN,
/* 255 */	DHCP4_OPT_PARAMS_END /* RFC 2132. */
};


//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////


/* Call this before first other code use. */
static inline void
dhcp4_static_init(void) {

	if (NULL == dhcp4_opt55[0]) {
		for (size_t i = 0; i < nitems(dhcp4_options); i ++) {
			dhcp4_opt55[i] = dhcp4_options[i].disp_name;
		}
	}
}


static inline int
dhcp4_hdr_check(const void *buf, const size_t buf_size) {
	const struct dhcp4_header_s *hdr = buf;

	if (NULL == buf ||
	    sizeof(dhcp4_hdr_t) > buf_size)
		return (EINVAL);

	switch (hdr->op) {
	case DHCP4_HDR_OP_BOOTREQUEST:
	case DHCP4_HDR_OP_BOOTREPLY:
		break;
	default:
		return (EBADMSG);
	}
	if (0 == hdr->htype ||
	    DHCP4_HDR_HTYPE_MAX < hdr->htype ||
	    DHCP4_HDR_HLEN_MAX < hdr->hlen ||
	    0 != memcmp(dhcp4_hdr_magic_cookie, hdr->magic_cookie,
	    sizeof(dhcp4_hdr_magic_cookie)))
		return (EBADMSG);

	return (0);
}


#endif /* __DHCP4_MESSAGE_H__ */
