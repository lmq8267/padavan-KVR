/*
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#ifndef _COMMON_H_
#define _COMMON_H_

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef ABS
#define	ABS(a)			(((a) < 0)?-(a):(a))
#endif /* ABS */

#ifndef MIN
#define	MIN(a, b)		(((a) < (b))?(a):(b))
#endif /* MIN */

#ifndef MAX
#define	MAX(a, b)		(((a) > (b))?(a):(b))
#endif /* MAX */

typedef u_int64_t u64;
typedef u_int32_t u32;
typedef u_int16_t u16;
typedef u_int8_t u8;

#define EVM_RESTART_FIREWALL			(1ULL <<  0)
#define EVM_RESTART_DHCPD			(1ULL <<  1)
#define EVM_RESTART_RADV			(1ULL <<  2)
#define EVM_RESTART_DDNS			(1ULL <<  3)
#define EVM_RESTART_UPNP			(1ULL <<  4)
#define EVM_RESTART_TIME			(1ULL <<  5)
#define EVM_RESTART_NTPC			(1ULL <<  6)
#define EVM_RESTART_SYSLOG			(1ULL <<  7)
#define EVM_RESTART_NETFILTER			(1ULL <<  8)
#define EVM_REAPPLY_VPNSVR			(1ULL <<  9)
#define EVM_RESTART_VPNSVR			(1ULL << 10)
#define EVM_RESTART_VPNCLI			(1ULL << 11)
#define EVM_RESTART_WIFI2			(1ULL << 12)
#define EVM_RESTART_WIFI5			(1ULL << 13)
#define EVM_RESTART_SWITCH_CFG			(1ULL << 14)
#define EVM_RESTART_SWITCH_VLAN			(1ULL << 15)
#define EVM_RESTART_LAN				(1ULL << 17)
#define EVM_RESTART_WAN				(1ULL << 18)
#define EVM_RESTART_IPV6			(1ULL << 19)
#define EVM_RESTART_HTTPD			(1ULL << 20)
#define EVM_RESTART_TELNETD			(1ULL << 21)
#define EVM_RESTART_SSHD			(1ULL << 22)
#define EVM_RESTART_WINS			(1ULL << 23)
#define EVM_RESTART_LLTD			(1ULL << 24)
#define EVM_RESTART_ADSC			(1ULL << 25)
#define EVM_RESTART_IPTV			(1ULL << 26) //iptv服务
#define EVM_RESTART_CROND			(1ULL << 27)
#define EVM_RESTART_SYSCTL			(1ULL << 28)
#define EVM_RESTART_TWEAKS			(1ULL << 29)
#define EVM_RESTART_WDG				(1ULL << 30)
#define EVM_RESTART_DI				(1ULL << 31)
#define EVM_RESTART_SPOOLER			(1ULL << 32)
#define EVM_RESTART_MODEM			(1ULL << 33)
#define EVM_RESTART_HDDTUNE			(1ULL << 34)
#define EVM_RESTART_FTPD			(1ULL << 35) //ftp
#define EVM_RESTART_NMBD			(1ULL << 36) //smb
#define EVM_RESTART_SMBD			(1ULL << 37) //smb

//如果你要修改的话 请注意后面的序号，每个插件对应的序号不能相同  不能超过63 你可以删掉不需要的 把序号给你需要的插件
//#define EVM_RESTART_NFSD			(1ULL << 38) //nfsd文件系统
#define EVM_RESTART_EASYTIER			(1ULL << 38) // Easyier异地组网
#define EVM_RESTART_DMS				(1ULL << 39) //Minidlna UPnP 媒体服务器
#define EVM_RESTART_ITUNES			(1ULL << 40)
//#define EVM_RESTART_TRMD			(1ULL << 41) //#TRANSMISSION
#define EVM_RESTART_CLOUDFLARE			(1ULL << 41)  //CF的ddns
#define EVM_RESTART_ARIA			(1ULL << 42) //aria2c文件下载
//#define EVM_RESTART_SCUT			(1ULL << 43) //校园网
#define EVM_RESTART_TTYD			(1ULL << 43) //ttyd网页终端
//#define EVM_RESTART_VLMCSD			(1ULL << 44) //微软服务
#define EVM_RESTART_ALIST			(1ULL << 44) //alist文件列表
#define EVM_RESTART_ALIDDNS			(1ULL << 45) //阿里ddns
#define EVM_RESTART_SMARTDNS	    		(1ULL << 46) //smartdns加速
#define EVM_RESTART_FRP	    			(1ULL << 47) //frp内网穿透
//#define EVM_RESTART_DNSFORWARDER		(1ULL << 47) //dns转发
//#define EVM_RESTART_SHADOWSOCKS		(1ULL << 48) //科学上网ss
#define EVM_RESTART_CADDY			(1ULL << 48) //caddy文件管理
//#define EVM_RESTART_SS_TUNNEL			(1ULL << 49) //科学上网插件
#define EVM_RESTART_ADGUARDHOME			(1ULL << 49) //adg去广告
//#define EVM_RESTART_MENTOHUST			(1ULL << 50) //校园认证
//#define EVM_RESTART_WYY			(1ULL << 50) //网易云
#define EVM_RESTART_BAFA			(1ULL << 50) //巴法云
//#define EVM_RESTART_ADBYBY			(1ULL << 51) //adb去广告
#define EVM_RESTART_ZEROTIER			(1ULL << 51) //zeriter异地组网
//#define EVM_RESTART_DDNSTO	    		(1ULL << 52) //ddnsto内网穿透
#define EVM_RESTART_WIREGUARD			(1ULL << 52) //wg异地组网
#define EVM_RESTART_ALDRIVER			(1ULL << 53) //阿里云盘挂载
//#define EVM_RESTART_VIRTUALHERE		(1ULL << 53) //virtualhere
#define EVM_RESTART_UUPLUGIN			(1ULL << 54) //UU加速器
//#define EVM_RESTART_KOOLPROXY			(1ULL << 55) //kp去广告
#define EVM_RESTART_LUCKY			(1ULL << 55) //lucky
#define EVM_RESTART_WXSEND			(1ULL << 56) //微信推送
#define EVM_RESTART_CLOUDFLARED			(1ULL << 57) //CF隧道免费内网穿透
#define EVM_RESTART_VNTS			(1ULL << 58) //vnt服务器
#define EVM_RESTART_VNTCLI			(1ULL << 59) //vnt客户端
//#define EVM_RESTART_NVPPROXY			(1ULL << 60) 
#define EVM_RESTART_NATPIERCE			(1ULL << 60) //皎月连
#define EVM_RESTART_TAILSCALE			(1ULL << 61) //taislacle
#define EVM_RESTART_REBOOT			(1ULL << 62) //重启
#define EVM_BLOCK_UNSAFE			(1ULL << 63) /* special case */


#define EVT_RESTART_FIREWALL		1
#define EVT_RESTART_DHCPD			1
#define EVT_RESTART_RADV			1
#define EVT_RESTART_DDNS			1
#define EVT_RESTART_UPNP			1
#define EVT_RESTART_TIME			2
#define EVT_RESTART_NTPC			1
#define EVT_RESTART_SYSLOG			1
#define EVT_RESTART_NETFILTER		1
#define EVT_REAPPLY_VPNSVR			1
#define EVT_RESTART_VPNSVR			2
#define EVT_RESTART_VPNCLI			2
#if defined (USE_RT3352_MII)
#define EVT_RESTART_WIFI2			5
#else
#define EVT_RESTART_WIFI2			3
#endif
#define EVT_RESTART_WIFI5			3
#define EVT_RESTART_SWITCH_CFG		3
#define EVT_RESTART_SWITCH_VLAN		3
#define EVT_RESTART_LAN				5
#define EVT_RESTART_WAN				5
#define EVT_RESTART_IPV6			3
#define EVT_RESTART_HTTPD			2
#define EVT_RESTART_TELNETD			1
#define EVT_RESTART_SSHD			1
#define EVT_RESTART_WINS			2
#define EVT_RESTART_LLTD			1
#define EVT_RESTART_ADSC			1
#define EVT_RESTART_CROND			1
#define EVT_RESTART_IPTV			1
#define EVT_RESTART_SYSCTL			1
#define EVT_RESTART_TWEAKS			1
#define EVT_RESTART_WDG				1
#define EVT_RESTART_DI				1
#define EVT_RESTART_SPOOLER			1
#define EVT_RESTART_MODEM			3
#define EVT_RESTART_HDDTUNE			1
#define EVT_RESTART_FTPD			1
#define EVT_RESTART_NMBD			2
#define EVT_RESTART_SMBD			2
#define EVT_RESTART_NFSD			2
#define EVT_RESTART_DMS				2
#define EVT_RESTART_ITUNES			2
#define EVT_RESTART_TRMD			3
#define EVT_RESTART_ARIA			3
#define EVT_RESTART_SCUT			1
#define EVT_RESTART_TTYD			1
#define EVT_RESTART_VLMCSD			1
#define EVT_RESTART_SHADOWSOCKS		2
#define EVT_RESTART_SS_TUNNEL		2
#define EVT_RESTART_ADBYBY			2
#define EVT_RESTART_KOOLPROXY		2
#define EVT_RESTART_DNSFORWARDER	1
#define EVT_RESTART_MENTOHUST		2
#define EVT_RESTART_PDNSD			1
#define EVT_RESTART_ALIDDNS			2
#define EVT_RESTART_SMARTDNS		1
#define EVT_RESTART_FRP      		2
#define EVT_RESTART_CADDY      		2
#define EVT_RESTART_ADGUARDHOME     1
#define EVT_RESTART_WYY      		2
#define EVT_RESTART_ZEROTIER     	2
#define EVT_RESTART_NVPPROXY     	2
#define EVT_RESTART_DDNSTO      	2
#define EVT_RESTART_ALDRIVER     	2
#define EVT_RESTART_WIREGUARD     	2
#define EVT_RESTART_UUPLUGIN    	2
#define EVT_RESTART_LUCKY	    	2
#define EVT_RESTART_WXSEND	    	2
#define EVT_RESTART_CLOUDFLARED	    	2
#define EVT_RESTART_VNTS	    	2
#define EVT_RESTART_VNTCLI	    	2
#define EVT_RESTART_NATPIERCE	    	2
#define EVT_RESTART_TAILSCALE	    	2
#define EVT_RESTART_CLOUDFLARE	    	2
#define EVT_RESTART_ALIST	    	2
#define EVT_RESTART_EASYTIER	    	2
#define EVT_RESTART_BAFA	    	2
#define EVT_RESTART_VIRTUALHERE    	2
#define EVT_RESTART_REBOOT			40

struct variable
{
	const char *name;
	const char *longname;
	char **argv;
	u64 event_mask;
};

struct svcLink
{
	const char *serviceId;
	struct variable *variables;
};

struct evDesc
{
	u64 event_mask;
	u32 max_time;
	const char* notify_cmd;
	u64 event_unmask;
};

#define ARGV(args...) ((char *[]) { args, NULL })

/* API export for UPnP function */
int LookupServiceId(char *serviceId);
const char *GetServiceId(int sid);
struct variable *GetVariables(int sid);


#endif /* _COMMON_H_ */
