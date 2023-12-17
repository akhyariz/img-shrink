#!/bin/bash

# Menyimpan jumlah argumen yang diberikan
num_args=$#

# 1. Memeriksa jumlah argumen yang diberikan
if [ $num_args -eq 0 ]; then
    echo "Usage: $0 <disk_image>"
    echo "Please provide the disk image as an argument."
    exit 1
fi

# 2. Nama file disk image dimasukkan melalui command line
disk_image="$1"

# 3. Tampilkan error apabila disk image yang dimaksud tidak ada
if [ ! -f "$disk_image" ]; then
    echo "Error: Disk image '$disk_image' not found."
    exit 1
fi

# 4. Menggunakan losetup -f, simpan /dev/loop yang tersedia ke dalam variable $loopback
sudo modprobe loop
loopback=$(sudo losetup -f)

# Lalu lakukan attach disk image menggunakan losetup ke $loopback yang tersedia
sudo losetup "$loopback" "$disk_image"

# Dan lakukan scanning partisinya
sudo partprobe "$loopback"

# 5. Buka gparted terhadap $loopback untuk dilakukan resize manual oleh user
sudo gparted "$loopback"

# 6. Dapatkan nilai end sector dengan bantuan tools fdisk -l, tail -n 1 dan awk
end_sector=$(sudo fdisk -l "$loopback" | tail -n 1 | awk '{print $3}')

# 7. Simpan io size bytes dengan bantuan blockdev --getbsz /dev/loop ke dalam variable $io_size
io_size=$(sudo fdisk -l "$loopback" | grep Units | awk '{print $8}')

# 8. Lakukan truncate --size=$[(end_sector+1)*io_size]
size=$[(end_sector+1)*io_size]
sudo truncate --size=$size "$disk_image"

echo $end_sector
echo $io_size
echo $size

# Detach loopback device
sudo losetup -d "$loopback"

echo "Disk image '$disk_image' resized successfully."
