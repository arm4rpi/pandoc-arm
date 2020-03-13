#!/bin/bash

CIDIR=".github/workflows"
HACKAGE="http://hackage.haskell.org/package"
ITEMS=("pandoc" "pandoc-citeproc" "pandoc-crossref" "pandoc-citeproc-dep" "pandoc-crossref-dep")

[ ! -d $CIDIR ] && mkdir -p $CIDIR

for id in ${ITEMS[@]};do
	for ARCH in aarch64 armv7l;do
		cat > $CIDIR/${id}-${ARCH}.yml <<EOF
name: $id-$ARCH 
on: [push]
jobs:
EOF
	done
done

function addJob() {
	id=$1
	name=`echo $id |sed 's/\-dep//g'`
	dep=""
	echo $id |grep dep && dep="-dep"
	arch=$2
	qemuarch=aarch64
	ubuntuarch=arm64
	[ "$arch"x == "armv7l"x ] && qemuarch="arm" && ubuntuarch="armhf"

	cat >> $CIDIR/${id}-${arch}.yml <<EOF

  $arch-$id:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: build
      run: |
        mkdir rootfs
        export pkg=\`curl -s "$HACKAGE/$name" |grep "base href" |awk -F'"' '{print \$2}' |sed 's/\/$//g' |awk -F'/' '{print \$NF}'\`
        curl -s -L "https://github.com/arm4rpi/pandoc-arm/releases/download/v0.1/$arch-\$pkg.tar.gz" -o rootfs/$arch-\$pkg.tar.gz
        MIME=\`file -b --mime-type rootfs/$arch-\$pkg.tar.gz\`
        echo \$MIME
        [ "\$MIME"x == "application/gzip"x ] && echo "Already exists" && exit 0 || echo "Not exists"
        sudo dd if=/dev/zero of=/mnt/swapfile bs=1M count=12288
        sudo dd if=/dev/zero of=/home/swapfile bs=1M count=10240
        sudo mkswap /mnt/swapfile
        sudo mkswap /home/swapfile
        sudo swapon /mnt/swapfile
        sudo swapon /home/swapfile
        free -m
        df -h
        sudo apt-get update
        sudo apt-get install -y qemu-user-static aria2
        aria2c -x 16 http://cdimage.ubuntu.com/ubuntu-base/releases/19.10/release/ubuntu-base-19.10-base-$ubuntuarch.tar.gz
        cd rootfs
        echo "decompression rootfs"
        tar xvf ../ubuntu-base-19.10-base-$ubuntuarch.tar.gz &>/dev/null && echo "decompression rootfs successfull"
        cp /usr/bin/qemu-$qemuarch-static usr/bin
        cp /etc/resolv.conf etc
        cp ../build.sh \${pkg}${dep}
        sudo mount -t devtmpfs devtmpfs dev
        sudo mount -t devpts devpts dev/pts
        sudo mount -t sysfs sysfs sys
        sudo mount -t tmpfs tmpfs tmp
        sudo mount -t proc proc proc
        echo "chroot to arm"
        sudo chroot . /\${pkg}${dep}
        echo "Upload Asset"
        for id in \`ls $arch-*.tar.gz\`;do
        curl -H "Authorization: token \${{ secrets.TOKEN }}" -H "Content-Type: application/x-gzip" "https://uploads.github.com/repos/arm4rpi/pandoc-arm/releases/24024627/assets?name=\$id" --data-binary @\$id
        done
EOF
}

for id in ${ITEMS[@]};do
	addJob $id aarch64
	addJob $id armv7l
done
