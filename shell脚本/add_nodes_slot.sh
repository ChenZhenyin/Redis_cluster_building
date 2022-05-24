#!/bin/bash

path=$1

path_6479=$(grep -rn "6479" $path)
path_6779=$(grep -rn "6779" $path)

if [ "$path_6479" != "" ] ;then
	sed -i '/6479/s/$/ 0-5460/g' $path
	sed -i '/6480/s/$/ 5461-10921/g' $path
	sed -i '/6481/s/$/ 10922-16383/g' $path
	echo "$path 已完成"
fi

if [ "$path_6779" != "" ] ;then
	sed -i '/6779/s/$/ 0-5460/g' $path
	sed -i '/6780/s/$/ 5461-10921/g' $path
	sed -i '/6781/s/$/ 10922-16383/g' $path
	echo "$path 已完成"
fi
