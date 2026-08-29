sudo apt-get install subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache \
 gettext libssl-dev xsltproc libxml-parser-perl \
 gengetopt default-jre-headless ocaml-nox sharutils texinfo

sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install zlib1g:i386 libstdc++6:i386 libc6:i386 libc6-dev-i386

git clone https://github.com/wireless-tag-com/openwrt-ssd20x.git

sudo tar -xvf wt-gcc-arm-8.2-2018.08-x86_64-arm-linux-gnueabihf.tag.gz -C /opt/

echo PATH="/opt/gcc-arm-8.2-2018.08-x86_64-arm-linux-gnueabihf/bin:$PATH" >>~/.profile
source ~/.profile

arm-linux-gnueabihf-gcc --version

cd openwrt-ssd20x
git config http.sslVerify false
cd 18.06
./scripts/feeds update -a
./scripts/feeds install -a -f
make WT2022_wt
make V=s -j2


curl -Lo log2ram.tar.gz https://github.com/azlux/log2ram/archive/master.tar.gz
tar xf log2ram.tar.gz
cd log2ram-master
chmod +x install.sh && sudo ./install.sh
cd ..
rm -r log2ram-master
systemctl disable log2ram-daily.timer

sudo nano /etc/log2ram.conf
