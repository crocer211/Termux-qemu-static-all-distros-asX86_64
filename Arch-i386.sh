#!/data/data/com.termux/files/usr/bin/bash
pkg install proot -y
folder=arch-fs
if [ -d "$folder" ]; then
	first=1
	echo "skipping downloading"
fi
tarball="arch-rootfs.tar.xz"
if [ "$first" != 1 ];then
	if [ ! -f $tarball ]; then
		echo "Download Rootfs, this may take a while base on your internet speed."
		case `dpkg --print-architecture` in
		aarch64)
			archurl="i386";
			wget https://github.com/AllPlatform/Termux-UbuntuX86_64/raw/master/arm64/qemu-i386-static;
			chmod 777 qemu-i386-static;
			mv qemu-i386-static ~/../usr/bin ;;
		arm)
			archurl="i386";
			wget https://github.com/AllPlatform/Termux-UbuntuX86_64/raw/master/arm/qemu-i386-static;
			chmod 777 qemu-i386-static;
			mv qemu-i386-static ~/../usr/bin/ ;;
		amd64)
			archurl="amd64" ;;
		x86_64)
			archurl="amd64" ;;	
		i*86)
			archurl="i386" ;;
		x86)
			archurl="i386" ;;
		*)
			echo "unknown architecture"; exit 1 ;;
		esac
		wget "https://mirrors.acm.wpi.edu/archlinux/iso/2020.07.01/archlinux-bootstrap-2020.07.01-x86_64.tar.gz" -O $tarball
	fi
	cur=`pwd`
	mkdir -p "$folder"
	cd "$folder"
	echo "Decompressing Rootfs, please be patient."
	proot --link2symlink tar -xJf ${cur}/${tarball}||:
	cd "$cur"
fi
mkdir -p arch-binds
bin=start-arch.sh
echo "writing launch script"
cat > $bin <<- EOM
#!/bin/bash
cd \$(dirname \$0)
## unset LD_PRELOAD in case termux-exec is installed
unset LD_PRELOAD
command="proot"
command+=" --link2symlink"
command+=" -0"
command+=" -r $folder -q qemu-i386-static"
command+=" -b /dev"
command+=" -b /proc"
command+=" -b arch-fs/root:/dev/shm"
## uncomment the following line to have access to the home directory of termux
#command+=" -b /data/data/com.termux/files/home:/root"
## uncomment the following line to mount /sdcard directly to / 
#command+=" -b /sdcard"
command+=" -w /root"
command+=" /usr/bin/env -i"
command+=" HOME=/root"
command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/usr/games:/usr/local/games"
command+=" TERM=\$TERM"
command+=" LANG=C.UTF-8"
command+=" /bin/bash --login"
com="\$@"
if [ -z "\$1" ];then
    exec \$command
else
    \$command -c "\$com"
fi
EOM

echo "fixing shebang of $bin"
termux-fix-shebang $bin
echo "making $bin executable"
chmod +x $bin
echo "removing image for some space"
rm $tarball
echo "You can now launch Arch with the ./${bin} script"

