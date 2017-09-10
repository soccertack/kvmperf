
KERNEL_NAME=linux-3.17
KERNEL="/tmp/$KERNEL_NAME"
KERNEL_TAR="$KERNEL.tar.gz"
KERNEL_XZ="$KERNEL.tar.xz"
KERNEL_BZ="$KERNEL.tar.xz.bz2"

pushd /tmp
if [[ -d $KERNEL ]]; then
	echo "$KERNEL is here"
else
	if [[ -f $KERNEL_TAR ]]; then
		echo "$KERNEL_TAR is here"
	else
		echo "$KERNEL_TAR is not here"
		wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.17.tar.gz
		sync
	fi
	echo "Extracing kernel tar..."
	tar xfz $KERNEL_TAR
fi

: '
if [[ -f $KERNEL_XZ ]]; then
	echo "$KERNEL_XZ is here"
else
	echo "$KERNEL_XZ is not here"
	wget https://www.kernel.org/pub/linux/kernel/v3.x/linux-3.17.tar.xz
	sync
fi

if [[ -f $KERNEL_BZ ]]; then
	echo "$KERNEL_BZ is here"
else
	echo "$KERNEL_BZ is not here"
	pbzip2 -k -p2 -m500 $KERNEL_XZ
	sync
fi
'
popd
