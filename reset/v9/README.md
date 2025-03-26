**v9_1和v9_2版本的区别：**

v9_1和v9_2版本实现的功能都是一样的，只是实现的方式不同。

| v9_1                                                         | v9_2                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1.Rocky、Almalinux、CentOS系统修改ip地址采用nmcli命令方式；  | 1.Rocky、Almalinux、CentOS系统修改ip地址采用的是配置文件方式； |
| 2.Rocky、Almalinux、CentOS、Ubuntu和Debian系统修改镜像仓库采用sed直接替换网址方式； | 2.Rocky、Almalinux、CentOS、Ubuntu和Debian系统修改镜像仓库采用的是配置文件方式； |
| 3.设置系统时区采用timedatectl命令方式。                      | 3.设置系统时区采用软链接方式。                               |

