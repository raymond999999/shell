# Rocky、AlmaLinux、CentOS、Ubuntu、Debian、openEuler、AnolisOS、OpenCloudOS、openSUSE、银河麒麟（Kylin Server）和统信（UOS Server）系统初始化脚本

![reset](https://raymond-1302897408.cos.ap-beijing.myqcloud.com/images/blog/reset/20251020182859999.jpg)

**Shell脚本源码地址：**

```
Gitee：https://gitee.com/raymond9/shell
Github：https://github.com/raymond999999/shell
```

您可以从上方的Gitee或Github代码仓库中拉取脚本。

**支持的功能：**

| **支持的功能**                  | 备注                                                         |
| ------------------------------- | ------------------------------------------------------------ |
| 1.设置root用户登录              |                                                              |
| 2.修改网卡名                    | openSUSE Leap 15操作系统默认网卡名就是eth0、eth1不用修改     |
| 3.设置网络                      | 包括设置IP地址、子网掩码位数、网关地址和DNS地址，包括单网卡和双网卡 |
| 4.设置主机名                    |                                                              |
| 5.设置镜像仓库                  | Kylin Server和UOS Server操作系统只有官方镜像仓库，没有合适的第三方镜像仓库，不用设置 |
| 6.建议安装软件                  |                                                              |
| 7.关闭防火墙                    | Ubuntu操作系统默认安装的防火墙的防火墙是ufw，Debian操作系统默认没有安装防火墙，其它操作系统默认安装的防火墙都是firewall |
| 8.禁用SELinux                   | Ubuntu、Debian和openSUSE Leap 15操作系统默认没有安装SELinux，不用设置 |
| 9.禁用AppArmor                  | 只有openSUSE Leap 15操作系统默认安装AppArmor，其它操作系统都不用设置 |
| 10.禁用SWAP                     |                                                              |
| 11.设置系统时区                 |                                                              |
| 12.优化资源限制参数             |                                                              |
| 13.优化内核参数                 |                                                              |
| 14.优化SSH                      |                                                              |
| 15.更改SSH端口号                |                                                              |
| 16.设置系统别名                 |                                                              |
| 17.设置vimrc配置文件            |                                                              |
| 18.安装邮件服务并配置           |                                                              |
| 19.设置PS1                      |                                                              |
| 20.设置默认文本编辑器为vim      |                                                              |
| 21.设置history格式              |                                                              |
| 22.禁用ctrl+alt+del重启系统功能 |                                                              |
| 23.Ubuntu卸载无用软件包         | 只支持Ubuntu操作系统                                         |
| 24.Ubuntu卸载snap               | 只支持Ubuntu操作系统                                         |

**支持的操作系统：**

| 版本           | **支持的操作系统**                                           | 脚本地址                                                     |
| -------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| v10版          | Rocky Linux 8/9/10、AlmaLinux 8/9/10、CentOS 7、CentOS Stream 8/9/10、Ubuntu Server 18.04/20.04/22.04/24.04 LTS、Debian 11/12/13 | https://gitee.com/raymond9/shell/tree/main/reset/reset_v10   |
| openEuler版    | openEuler 22.03/24.03 LTS                                    | https://gitee.com/raymond9/shell/tree/main/reset/reset_openeuler |
| AnolisOS版     | AnolisOS 8/23                                                | https://gitee.com/raymond9/shell/tree/main/reset/reset_anolisos |
| OpenCloudOS版  | OpenCloudOS 8/9                                              | https://gitee.com/raymond9/shell/tree/main/reset/reset_opencloudos |
| openSUSE版     | openSUSE Leap 15/16                                          | https://gitee.com/raymond9/shell/tree/main/reset/reset_opensuse |
| Kylin Server版 | 银河麒麟（Kylin Server） V10/V11                             | https://gitee.com/raymond9/shell/tree/main/reset/reset_kylin_server |
| UOS Server版   | 统信（UOS Server） V20                                       | https://gitee.com/raymond9/shell/tree/main/reset/reset_uos_server |

**版本更新日志：**

| 版本                     | 功能                                                         |
| ------------------------ | ------------------------------------------------------------ |
| v10版更新内容            | 1.为Rocky Linux 9、AlmaLinux 9、CentOS Stream 9和10添加了修改网卡命名为`eth0`、`eth1`等传统命名方式的功能； |
|                          | 2.由于Rocky Linux 9、AlmaLinux 9、CentOS Stream 9和10对网卡命名规则进行了更改，使用nmcli命令来修改IP地址的方法不再适用。因此，我们采用了通过配置文件来设置IP地址的方式。同时，对单网卡和双网卡的配置进行了统一处理，能够自动识别当前是单网卡还是双网卡环境，并据此进行相应的配置设置； |
|                          | 3.在UEFI引导系统中，通过修改GRUB配置文件来更改网卡名时，需注意“grub.cfg”文件的位置已发生改变，已添加了相关功能以适应这一变化； |
|                          | 4.优化了Ubuntu和Debian系统更改IP地址的操作方法；             |
|                          | 5.修复了Ubuntu Server 22.04  LTS的IP地址修改完，系统重启后IP被重置问题； |
|                          | 6.修复了修改网卡名的bug；                                    |
|                          | 7.添加了对Rocky Linux 10和AlmaLinux 10系统的支持；           |
|                          | 8.添加了对Debian 13系统的支持；                              |
|                          | 9.修改了某些bug。                                            |
| Uos Server版更新的内容   | 1.添加了对统信（UOS Server）V20系统的支持；                  |
|                          | 2.通过修改GRUB配置文件来修改网卡名时，如果是UEFI引导系统，“grub.cfg”文件位置发生了改变，添加了相关功能； |
|                          | 3.修复了修改网卡名的bug；                                    |
|                          | 4.修改了某些bug。                                            |
| Kylin Server版更新的内容 | 1.添加了对银河麒麟（Kylin Server）V10系统的支持；            |
|                          | 2.通过修改GRUB配置文件来修改网卡名时，如果是UEFI引导系统，“grub.cfg”文件位置发生了改变，添加了相关功能； |
|                          | 3.修复了修改网卡名的bug；                                    |
|                          | 4.添加了对银河麒麟（Kylin Server）V11系统的支持；            |
|                          | 5.修改了某些bug。                                            |
| openSUSE版更新的内容     | 1.添加了对openSUSE Leap 15系统的支持；                       |
|                          | 2.修复了“禁用SWAP”不生效的问题；                             |
|                          | 3.修复了“禁用ctrl+alt+del重启系统功能”不生效的问题；         |
|                          | 4.修复了“设置PS1”不生效的问题；                              |
|                          | 5.openSUSE Leap 15系统pcre安装包名改成了pcre-tools，openssl-devel安装包名改成了libopenssl-devel； |
|                          | 6.对单网卡和双网卡的配置进行了统一处理，能够自动识别当前是单网卡还是双网卡环境，并据此进行相应的配置设置； |
|                          | 7.修复了设置网络时DNS设置不生效的问题；                      |
|                          | 8.添加了对openSUSE Leap 16系统的支持；openSUSE Leap 16需要设置root用户登录，需要修改网卡名，网卡配置文件变成了“/etc/NetworkManager/system-connections/eth0.nmconnection”，ssh服务配置文件变成了“/usr/etc/ssh/sshd_config”； |
|                          | 9.修改了某些bug。                                            |
| OpenCloudOS版更新的内容  | 1.添加了对OpenCloudOS 8和9系统的支持；                       |
|                          | 2.修复了“禁用SWAP”不生效的问题；                             |
|                          | 3.修复了“禁用ctrl+alt+del重启系统功能”不生效的问题；         |
|                          | 4.为OpenCloudOS 9添加了修改网卡命名为`eth0`、`eth1`等传统命名方式的功能； |
|                          | 5.由于OpenCloudOS 9对网卡命名规则进行了更改，使用nmcli命令来修改IP地址的方法不再适用。因此，我们采用了通过配置文件来设置IP地址的方式。同时，对单网卡和双网卡的配置进行了统一处理，能够自动识别当前是单网卡还是双网卡环境，并据此进行相应的配置设置； |
|                          | 6.通过修改GRUB配置文件来修改网卡名时，如果是UEFI引导系统，“grub.cfg”文件位置发生了改变，添加了相关功能； |
|                          | 7.修复了修改网卡名的bug；                                    |
|                          | 8.添加了启用OpenCloudOS 8 PowerTools仓库的功能；             |
|                          | 9.修改了某些bug。                                            |
| AnolisOS版更新的内容     | 1.添加了对AnolisOS 8和23系统的支持；                         |
|                          | 2.修复了“禁用SWAP”不生效的问题；                             |
|                          | 3.修复了“禁用ctrl+alt+del重启系统功能”不生效的问题；         |
|                          | 4.为AnolisOS 8和23添加了修改网卡命名为`eth0`、`eth1`等传统命名方式的功能； |
|                          | 5.由于AnolisOS 23对网卡命名规则进行了更改，使用nmcli命令来修改IP地址的方法不再适用。因此，我们采用了通过配置文件来设置IP地址的方式。同时，对单网卡和双网卡的配置进行了统一处理，能够自动识别当前是单网卡还是双网卡环境，并据此进行相应的配置设置； |
|                          | 6.通过修改GRUB配置文件来修改网卡名时，如果是UEFI引导系统，“grub.cfg”文件位置发生了改变，添加了相关功能； |
|                          | 7.修复了修改网卡名的bug；                                    |
|                          | 8.修改了某些bug。                                            |
| openEuler版更新的内容    | 1.添加了对openEuler 22.03/24.03 LTS系统的支持；              |
|                          | 2.修复了“禁用SWAP”不生效的问题；                             |
|                          | 3.修复了“禁用ctrl+alt+del重启系统功能”不生效的问题；         |
|                          | 4.对单网卡和双网卡的配置进行了统一处理，能够自动识别当前是单网卡还是双网卡环境，并据此进行相应的配置设置； |
|                          | 5.通过修改GRUB配置文件来修改网卡名时，如果是UEFI引导系统，“grub.cfg”文件位置发生了改变，添加了相关功能； |
|                          | 6.修复了修改网卡名的bug；                                    |
|                          | 7.修改了某些bug。                                            |
| v9版更新内容             | 1.由于CentOS Stream 8 已于 2024 年 5 月 31 日到期， CentOS Linux 7 的生命周期结束日期是 2024 年 6 月 30 日，将CentOS Stream 8和CentOS 7的镜像仓库都改成了centos-vault仓库；把CentOS 7的epel仓库改成了epel-archive仓库； |
|                          | 2.添加了对Ubuntu Server 24.04 LTS系统的支持；（Ubuntu Server 24.04 LTS的变更：网卡配置文件变成了“/etc/netplan/50-cloud-init.yaml”，镜像仓库格式变成了DEB822 格式，ssh服务的服务名变成了ssh；） |
|                          | 3.添加了对Debian 11和12系统的支持；                          |
|                          | 4.添加了AlmaLinux的devel仓库；                               |
|                          | 5.修复了“禁用ctrl+alt+del重启系统功能”不生效的问题；         |
|                          | 6.添加了对CentOS Stream 10系统的支持，修复了“禁用SWAP”不生效的问题，CentOS Stream 10系统pcre安装包名改成了pcre2，pcre-devel安装包名改成了pcre2-devel; |
|                          | 7.修改了某些bug。                                            |
| v8版更新内容             | 1.添加了对AlmaLinux 8和9系统的支持；                         |
|                          | 2.添加Ubuntu卸载snap的功能；                                 |
|                          | 3.修改了某些bug。                                            |
| v7版更新内容             | 1.由于v6版修改的比较仓促，其中设置镜像仓库有bug，修复了其中的bug，而且设置镜像仓库可以重复修改；修复了设置ip不能成功的bug；优化了设置系统别名的bug；修复了“优化内核参数”的bug； |
|                          | 2.分别有reset_v7_1版本（镜像仓库采用sed直接替换网址方式；修改ip地址采用nmcli命令方式）和reset_v7_2版本（镜像仓库和修改ip地址采用配置文件方式）。 |
| v6版更新内容             | 1.由于CentOS 6和8官方已经停止支持，也就移除了其相关内容；    |
|                          | 2.分别有reset_v6_1版本（镜像仓库采用sed直接替换网址方式；修改ip地址采用nmcli命令方式）和reset_v6_2版本（镜像仓库和修改ip地址采用配置文件方式）； |
|                          | 3.reset_v6_1添加了CentOS Stream 9用Perl语言更改镜像源的方法，优化了某些镜像仓库失效的bug，修改了某些bug。 |
| v5版更新内容             | 1.优化了某些镜像仓库失效的bug；                              |
|                          | 2.CentOS stream 9和Rocky Linux 9修改ip的方式更改，做了相应的修改； |
|                          | 3.分别有reset_v5_1版本（镜像仓库采用sed直接替换网址方式；修改ip地址采用nmcli命令方式）和reset_v5_2版本（镜像仓库和修改ip地址采用配置文件方式）； |
|                          | 4.把设置PS1、设置默认文本编辑器为vim和设置history格式单独分开； |
|                          | 5.修改了某些bug。                                            |
| v4版更新内容             | 1.添加对CentOS stream 9、Rocky Linux 9和Ubuntu Server 22.04 LTS系统的支持； |
|                          | 2.添加Ubuntu Server 22.04 LTS修改IP地址和网关地址、双网卡更改IP地址； |
|                          | 3.添加禁用ctrl+alt+del重启功能；                             |
|                          | 4.修改了某些bug。                                            |
| v3版更新内容             | 1.添加双网卡更改IP地址；                                     |
|                          | 2.添加设置系统时区。                                         |
| v2版更新内容             | 1.添加对CentOS stream 8系统支持，添加了CentOS stream 8镜像仓库； |
|                          | 2.由于CentOS 8已被废弃，修改成centos-vault的历史镜像仓库；   |
|                          | 3.优化Ubuntu Server 20.04 LTS禁用swap不生效的问题。          |
| v1版支持功能             | 1.支持CentOS 6/7/8、Ubuntu Server 18.04/20.04 LTS、Rocky Linux 8系统； |
|                          | 2.支持功能禁用SELinux、关闭防火墙、优化SSH、设置系统别名、设置vimrc配置文件、设置软件包仓库、Minimal安装建议安装软件、安装邮件服务并配置邮件、更改SSH端口号、修改网卡名、修改IP地址和网关地址、设置主机名、设置PS1和系统环境变量、禁用SWAP、优化内核参数、优化资源限制参数、Ubuntu设置root用户登录、Ubuntu卸载无用软件包。 |

**reset脚本在使用过程中需要注意的事项：**

1. 首先说明，脚本必须在root用户下使用。

   ```bash
   # Rocky、Almalinux、CentOS、openEuler、AnolisOS、OpencloudOS、openSUSE Leap 15、银河麒麟（Kylin Server）和统信（UOS Server）可以使用root用户登录不用设置，Ubuntu、Debian和openSUSE Leap 16必须先设置root用户登录。
   # 先安装lrzsz工具，把脚本传上去
   raymond@ubuntu2404:~$ sudo apt -y install lrzsz
   raymond@ubuntu2404:~$ rz -E
   rz waiting to receive.
   raymond@ubuntu2404:~$ ls
   reset_v10.sh
   
   # 使用bash命令运行脚本
   raymond@ubuntu2404:~$ bash reset_v10.sh 
   当然登录用户是raymond，请使用root用户登录或设置root用户登录！
   
   ********************************************************
   *            系统初始化脚本菜单                        *
   * 1.设置root用户登录   14.更改SSH端口号                *
   * 2.修改网卡名         15.设置系统别名                 *
   * 3.设置网络           16.设置vimrc配置文件            *
   * 4.设置主机名         17.安装邮件服务并配置           *
   * 5.设置镜像仓库       18.设置PS1(请进入选择颜色)      *
   * 6.建议安装软件       19.设置默认文本编辑器为vim      *
   * 7.关闭防火墙         20.设置history格式              *
   * 8.禁用SELinux        21.禁用ctrl+alt+del重启系统功能 *
   * 9.禁用SWAP           22.Ubuntu卸载无用软件包         *
   * 10.设置系统时区      23.Ubuntu卸载snap               *
   * 11.优化资源限制参数  24.重启系统                     *
   * 12.优化内核参数      25.关机                         *
   * 13.优化SSH           26.退出                         *
   ********************************************************
   
   请选择相应的编号(1-26): 1 # 输入21，设置root用户登录
   请输入密码: 123456 # 输入密码
   New password: Retype new password: passwd: password updated successfully
   Ubuntu 24.04.3 LTS操作系统，root用户登录已设置完成，请重新登录后生效！
   
   ********************************************************
   *            系统初始化脚本菜单                        *
   * 1.设置root用户登录   14.更改SSH端口号                *
   * 2.修改网卡名         15.设置系统别名                 *
   * 3.设置网络           16.设置vimrc配置文件            *
   * 4.设置主机名         17.安装邮件服务并配置           *
   * 5.设置镜像仓库       18.设置PS1(请进入选择颜色)      *
   * 6.建议安装软件       19.设置默认文本编辑器为vim      *
   * 7.关闭防火墙         20.设置history格式              *
   * 8.禁用SELinux        21.禁用ctrl+alt+del重启系统功能 *
   * 9.禁用SWAP           22.Ubuntu卸载无用软件包         *
   * 10.设置系统时区      23.Ubuntu卸载snap               *
   * 11.优化资源限制参数  24.重启系统                     *
   * 12.优化内核参数      25.关机                         *
   * 13.优化SSH           26.退出                         *
   ********************************************************
   
   请选择相应的编号(1-26): 26 # 输入26，退出脚本
   
   # 然后用root用户登录
   [C:\~]$ ssh 10.0.15.15
   
   # 把脚本从普通用户家目录移到root用户家目录，再继续后面步骤。
   root@ubuntu2404:~# mv /home/raymond/reset_v10.sh .
   ```

2. CentOS Stream 9和10修改镜像源需要注意的地方。

   ```bash
   # 先安装lrzsz工具，把脚本传上去
   [root@centos10 ~]# dnf install -y lrzsz
   [root@centos10 ~]# rz -E
   rz waiting to receive.
   [root@centos10 ~]# ls
   anaconda-ks.cfg  reset_v10.sh
   
   [root@centos10 ~]# bash reset_v10.sh 
   
   ********************************************************
   *            系统初始化脚本菜单                        *
   * 1.设置root用户登录   14.更改SSH端口号                *
   * 2.修改网卡名         15.设置系统别名                 *
   * 3.设置网络           16.设置vimrc配置文件            *
   * 4.设置主机名         17.安装邮件服务并配置           *
   * 5.设置镜像仓库       18.设置PS1(请进入选择颜色)      *
   * 6.建议安装软件       19.设置默认文本编辑器为vim      *
   * 7.关闭防火墙         20.设置history格式              *
   * 8.禁用SELinux        21.禁用ctrl+alt+del重启系统功能 *
   * 9.禁用SWAP           22.Ubuntu卸载无用软件包         *
   * 10.设置系统时区      23.Ubuntu卸载snap               *
   * 11.优化资源限制参数  24.重启系统                     *
   * 12.优化内核参数      25.关机                         *
   * 13.优化SSH           26.退出                         *
   ********************************************************
   
   请选择相应的编号(1-26): 5
   
   1)base仓库
   2)epel仓库
   3)启用CentOS Stream 9和10 crb仓库
   4)启用CentOS Stream 8 PowerTools仓库
   5)退出
   
   请输入镜像源编号(1-5): 1 # 输入1，选择设置base仓库
   由于CentOS Stream 10 (Coughlan)操作系统，系统默认镜像源是Perl语言实现的，在更改镜像源之前先确保把'update_mirror.pl'文件和reset脚本放在同一个目录下，否则后面程序会退出，默认的CentOS Stream 10 (Coughlan)操作系统，镜像源设置的是阿里云，要修改镜像源，请去'update_mirror.pl'文件里修改url变量！
   缺少update_mirror.pl文件！  # 这里提示“缺少update_mirror.pl文件”，上面的提示也写得很清楚，需要把这个文件也传到系统里
   
   [root@centos10 ~]# rz -E
   rz waiting to receive.
   [root@centos10 ~]# ls
   anaconda-ks.cfg  reset_v10.sh  update_mirror.pl
   
   [root@centos10 ~]# bash reset_v10.sh 
   
   ********************************************************
   *            系统初始化脚本菜单                        *
   * 1.设置root用户登录   14.更改SSH端口号                *
   * 2.修改网卡名         15.设置系统别名                 *
   * 3.设置网络           16.设置vimrc配置文件            *
   * 4.设置主机名         17.安装邮件服务并配置           *
   * 5.设置镜像仓库       18.设置PS1(请进入选择颜色)      *
   * 6.建议安装软件       19.设置默认文本编辑器为vim      *
   * 7.关闭防火墙         20.设置history格式              *
   * 8.禁用SELinux        21.禁用ctrl+alt+del重启系统功能 *
   * 9.禁用SWAP           22.Ubuntu卸载无用软件包         *
   * 10.设置系统时区      23.Ubuntu卸载snap               *
   * 11.优化资源限制参数  24.重启系统                     *
   * 12.优化内核参数      25.关机                         *
   * 13.优化SSH           26.退出                         *
   ********************************************************
   
   请选择相应的编号(1-26): 5 # 输入5，设置镜像仓库
   
   1)base仓库
   2)epel仓库
   3)启用CentOS Stream 9和10 crb仓库
   4)启用CentOS Stream 8 PowerTools仓库
   5)退出
   
   请输入镜像源编号(1-5): 1 # 输入1，选择设置base仓库
   由于CentOS Stream 10 (Coughlan)操作系统，系统默认镜像源是Perl语言实现的，在更改镜像源之前先确保把'update_mirror.pl'文件和reset脚本放在同一个目录下，否则后面程序会退出，默认的CentOS Stream 10 (Coughlan)操作系统，镜像源设置的是阿里云，要修改镜像源，请去'update_mirror.pl'文件里修改url变量！ 
   update_mirror.pl文件已准备好，继续后续配置！ # 现在这里提示“update_mirror.pl文件已准备好，继续后续配置！”
   安装perl工具,请稍等...
   更新镜像源中，请稍等......
   CentOS Stream 10 (Coughlan)操作系统，镜像源设置完成！
   
   1)base仓库
   2)epel仓库
   3)启用CentOS Stream 9和10 crb仓库
   4)启用CentOS Stream 8 PowerTools仓库
   5)退出
   
   请输入镜像源编号(1-5): 5 # 输入5，退出设置镜像仓库菜单
   
   ********************************************************
   *            系统初始化脚本菜单                        *
   * 1.设置root用户登录   14.更改SSH端口号                *
   * 2.修改网卡名         15.设置系统别名                 *
   * 3.设置网络           16.设置vimrc配置文件            *
   * 4.设置主机名         17.安装邮件服务并配置           *
   * 5.设置镜像仓库       18.设置PS1(请进入选择颜色)      *
   * 6.建议安装软件       19.设置默认文本编辑器为vim      *
   * 7.关闭防火墙         20.设置history格式              *
   * 8.禁用SELinux        21.禁用ctrl+alt+del重启系统功能 *
   * 9.禁用SWAP           22.Ubuntu卸载无用软件包         *
   * 10.设置系统时区      23.Ubuntu卸载snap               *
   * 11.优化资源限制参数  24.重启系统                     *
   * 12.优化内核参数      25.关机                         *
   * 13.优化SSH           26.退出                         *
   ********************************************************
   
   请选择相应的编号(1-26): 26 # 输入26，退出脚本
   ```

3. 其它功能根据需求选择，如果有需要输入的根据提示输入即可，这里不再一一演示。

