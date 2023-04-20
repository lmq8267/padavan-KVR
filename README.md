# Padavan-KVR #

fork于fightroad的仓库 https://github.com/fightroad/Padavan-KVR.git 

最终好像也是vb1980  https://github.com/vb1980/Padavan-KVR.git

透明主题使用的是yuos-bit  https://github.com/yuos-bit/Padavan.git

想要没有改主题的可以去上面大佬主页fork

默认纯净没有添加插件，[在线云编译修改插件](.github/workflows/NEWIFI3.yml) [自定义增减插件](trunk/configs/templates/NEWIFI3.config)

[修改自己想要的背景](/trunk/user/www/n56u_ribbon_fixed/bootstrap/img/bg/wood.jpg) 替换wood.jpg文件就行

[修改自己想要的LOGO](/trunk/user/www/n56u_ribbon_fixed/bootstrap/img/asus_logo.png) 替换asus_logo.png文件就行(像素尺寸要求150×70）

[修改默认管理地址wifi名称账号密码](trunk/user/shared/defaults.h) 

默认/tmp分区改为100M[修改/tmp分区大小size_tmp="100M"](trunk/user/scripts/dev_init.sh)

修改/etc/storage分区大小[1.CONFIG_MTD_STORE_PART_SIZ=0x200000](trunk/configs/boards/NEWIFI3/kernel-3.4.x.config) ，
[2.size_etc="6M"](trunk/user/scripts/dev_init.sh) ，
[3.mtd_part_size=65536](trunk/user/scripts/mtd_storage.sh) ，
storage大小修改方法：首先确认你闪存多大，比如NEWIFI3 d2是32M闪存，再确认你编译后的固件大小，若是插件集成的多，编译后固件大小假如有28M了？那不必修改了，就剩4M了还改啥，假如你是精简的或者只集成了几个小插件，编译后固件大小比如有18M？那就32-18=14M可用，在[十进制转十六进制](https://www.sojson.com/hexconvert/10to16.html)中输入14M的十进制14M×1024×1024=14680064 ，计算得出十六进制为e00000 ，在[trunk/configs/boards/NEWIFI3/kernel-3.4.x.config](trunk/configs/boards/NEWIFI3/kernel-3.4.x.config)找到CONFIG_MTD_STORE_PART_SIZ=0x200000改为CONFIG_MTD_STORE_PART_SIZ=0xe00000 ，然后在[trunk/user/scripts/dev_init.sh](trunk/user/scripts/dev_init.sh)找到size_etc="6M"改为size_etc="14M" 最后在[trunk/user/scripts/mtd_storage.sh](trunk/user/scripts/mtd_storage.sh)找到mtd_part_size=65536 改为mtd_part_size=14680064 即可，切记storage分区大小加上编译后的固件大小必须小于路由器闪存大小，不能超过！这样你的storage就能放下更多文件了。

### UI预览 ###
![](https://github.com/lmq8267/padavan-KVR/raw/main/.github/workflows/%E6%8D%95%E8%8E%B7(1).PNG)
![](https://github.com/lmq8267/padavan-KVR/raw/main/.github/workflows/%E6%B7%BB%E5%8A%A0%E7%8A%B6%E6%80%81%E6%98%BE%E7%A4%BA%E8%AE%BE%E5%A4%87ipv6%E5%8F%96%E6%B6%88%E9%A1%B6%E9%83%A8%E5%85%B3%E6%9C%BA%E6%8C%89%E9%92%AE%E7%94%A8ttyd%E4%BB%A3%E6%9B%BF.PNG)


基于hanwckf,chongshengB以及padavanonly的源码整合而来，支持7603/7615/7915的kvr  
编译方法同其他Padavan源码，主要特点如下：  
1.采用padavanonly源码的5.0.4.0无线驱动，支持kvr  
2.添加了chongshengB源码的所有插件  
3.其他部分等同于hanwckf的源码，有少量优化来自immortalwrt的padavan源码  
4.添加了MSG1500的7615版本config  
  
以下附上他们四位的源码地址供参考  
https://github.com/hanwckf/rt-n56u  
https://github.com/chongshengB/rt-n56u  
https://github.com/padavanonly/rt-n56u  
https://github.com/immortalwrt/padavan
  
最后编译出的固件对7612无线的支持已知是有问题的，包含7612的机型比如B70是无法正常工作的  
已测试的机型为MSG1500-7615，JCG-Q20，CR660x  
  
固件默认wifi名称
 - 2.4G：机器名_mac地址最后四位，如K2P_9981
 - 5G：机器名_5G_mac地址最后四位，如K2P_5G_9981

wifi密码
 - 1234567890

管理地址
 - 192.168.2.1

管理账号密码
 - admin
 - admin

**最近的更新代码都来自于hanwckf和MelsReallyBa大佬的4.4内核代码**
- https://github.com/hanwckf/padavan-4.4
- https://github.com/MeIsReallyBa/padavan-4.4
