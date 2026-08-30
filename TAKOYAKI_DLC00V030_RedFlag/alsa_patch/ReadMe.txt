
1.打开Kernel config：make menuconfig  （默认没开）

A. 音频框架的配置需要Power Manager支持：

Power management options

     ---> [*]  Device power management core functionality /* 需要替换内核 */

B. 配置选项如下(编译成模块)：

Device Drivers

       ---> <M> Sound card support ---> /* 下一级目录下均不选择默认会生成soundcore.ko和snd.ko */

              ---> <M> Advanced Linux Sound Architecture ---> /* 会生成snd-pcm.ko，snd-pcm-oss.ko */

                      ---><M> OSS PCM (digital audio) API /* 会生成snd-timer.ko */ 

2.重编kernel后生成所需ko，需要insmod：通过insmod方法要注意加载模块的顺序

insmod soundcore.ko

insmod snd.ko

insmod snd-timer.ko

insmod snd-pcm.ko

insmod mi_alsa.ko