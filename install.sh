#!/bin/bash

rm -rf $0

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

cur_dir=$(pwd)

# check root
[[ $EUID -ne 0 ]] && echo -e "  Lỗi：${plain} Bạn Chưa Cấp Quyền Root\n" && exit 1

# check os
if [[ -f /etc/redhat-release ]]; then
    release="centos"
elif cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /etc/issue | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
elif cat /proc/version | grep -Eqi "centos|red hat|redhat"; then
    release="centos"
else
    echo -e "  Phiên Bản Không Hợp Lệ Vui Lòng Liên Hệ ADMIN SPEED4g.XYZ ${plain}\n" && exit 1
fi

arch=$(arch)

if [[ $arch == "x86_64" || $arch == "x64" || $arch == "amd64" ]]; then
  arch="64"
elif [[ $arch == "aarch64" || $arch == "arm64" ]]; then
  arch="arm64-v8a"
else
  arch="64"
  echo -e "  Không Phát Hiện Được Giản Đồ, Hãy Sử Dụng Lược Đồ Mặc Định: ${arch}${plain}"
fi

echo "  Tiến Trình: ${arch}"

if [ "$(getconf WORD_BIT)" != '32' ] && [ "$(getconf LONG_BIT)" != '64' ] ; then
    echo "  Phần Mềm Này Không Hỗ Trợ Hệ Thống 32-bit (x86), Vui Lòng Sử Dụng Hệ Thống 64-bit (x86_64), Nếu Phát Hiện Sai, Vui Lòng Liên Hệ ADMIN SPEED4g.XYZ"
    exit 2
fi

os_version=""

# phiên bản của hệ điều hành
if [[ -f /etc/os-release ]]; then
    os_version=$(awk -F'[= ."]' '/VERSION_ID/{print $3}' /etc/os-release)
fi
if [[ -z "$os_version" && -f /etc/lsb-release ]]; then
    os_version=$(awk -F'[= ."]+' '/DISTRIB_RELEASE/{print $2}' /etc/lsb-release)
fi

if [[ x"${release}" == x"centos" ]]; then
    if [[ ${os_version} -le 6 ]]; then
        echo -e "  Vui lòng sử dụng CentOS 7 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"ubuntu" ]]; then
    if [[ ${os_version} -lt 16 ]]; then
        echo -e "  Vui lòng sử dụng Ubuntu 16 trở lên！${plain}\n" && exit 1
    fi
elif [[ x"${release}" == x"debian" ]]; then
    if [[ ${os_version} -lt 8 ]]; then
        echo -e "  Vui lòng sử dụng Debian 8 trở lên！${plain}\n" && exit 1
    fi
fi

install_base() {
    if [[ x"${release}" == x"centos" ]]; then
        yum install epel-release -y
        yum install wget curl unzip tar crontabs socat -y
    else
        apt update -y
        apt install wget curl unzip tar cron socat -y
    fi
}

# 0: đang chạy, 1: không chạy, 2: chưa cài đặt
check_status() {
    if [[ ! -f /etc/systemd/system/XrayR.service ]]; then
        return 2
    fi
    temp=$(systemctl status XrayR | grep Active | awk '{print $3}' | cut -d "(" -f2 | cut -d ")" -f1)
    if [[ x"${temp}" == x"running" ]]; then
        return 0
    else
        return 1
    fi
}

install_acme() {
    curl https://get.acme.sh | sh
}

install_XrayR() {
    if [[ -e /usr/local/XrayR/ ]]; then
        rm /usr/local/XrayR/ -rf
    fi

    mkdir /usr/local/XrayR/ -p
	cd /usr/local/XrayR/

    if  [ $# == 0 ] ;then
        last_version=$(curl -Ls "https://api.github.com/repos/Quoctai0209/xrayrr/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        if [[ ! -n "$last_version" ]]; then
            echo -e "  Không phát hiện được phiên bản XrayR, có thể đã vượt quá giới hạn Github API, vui lòng thử lại sau hoặc chỉ định phiên bản XrayR để cài đặt $ theo cách thủ công{plain}"
            exit 1
        fi
        echo -e "  Đã phát hiện phiên bản mới nhất của XrayR：${last_version}，bắt đầu cài đặt"
        wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip https://github.com/Quoctai0209/xrayrr/releases/download/${last_version}/XrayR-linux-${arch}.zip
        if [[ $? -ne 0 ]]; then
            echo -e "  Không tải xuống được XrayR, hãy đảm bảo máy chủ của bạn có thể tải xuống tệp Github ${plain}"
            exit 1
        fi
    else
        last_version=$1
        url="https://github.com/Quoctai0209/xrayrr/releases/download/${last_version}/XrayR-linux-${arch}.zip"
        echo -e "  Bắt Đầu Cài Đặt XrayR v$1"
        wget -N --no-check-certificate -O /usr/local/XrayR/XrayR-linux.zip ${url}
        if [[ $? -ne 0 ]]; then
            echo -e "  Không Thể Cài Đặt XrayR v $ 1, Hãy Đảm Bảo Rằng Phiên Bản Này Tồn Tại ${plain}"
            exit 1
        fi
    fi

    unzip XrayR-linux.zip
    rm XrayR-linux.zip -f
    chmod +x XrayR
    mkdir /etc/XrayR/ -p
    rm /etc/systemd/system/XrayR.service -f
    file="https://raw.githubusercontent.com/nnghi235/xrayr/main/XrayR.service"
    wget -N --no-check-certificate -O /etc/systemd/system/XrayR.service ${file}
    #cp -f XrayR.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl stop XrayR
    systemctl enable XrayR
    echo -e "  XrayR ${last_version}${plain} Cài Đặt Hoàn Tất, Nó Đã Được Thiết Lập Để Bắt Đầu Tự Động"
    cp geoip.dat /etc/XrayR/
    cp geosite.dat /etc/XrayR/ 

    if [[ ! -f /etc/XrayR/config.yml ]]; then
        cp config.yml /etc/XrayR/
        echo -e ""
        echo -e "  Nếu Không Biết Cấu Hình Vui Lòng Liên Hệ ADMIN SPEED4G.XYZ"
    else
        systemctl start XrayR
        sleep 2
        check_status
        echo -e ""
        if [[ $? == 0 ]]; then
            echo -e "  XrayR Khởi Động Thành Công ! (COPYRIGHT BY ADMIN SPEED4G.XYZ)${plain}"
        else
            echo -e "  XrayR Khởi Động Thất Bại, Vui Lòng Sử Dụng XrayR Log Để Kiểm Tra${plain}"
        fi
    fi

    if [[ ! -f /etc/XrayR/dns.json ]]; then
        cp dns.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/route.json ]]; then
        cp route.json /etc/XrayR/
    fi
    if [[ ! -f /etc/XrayR/custom_outbound.json ]]; then
        cp custom_outbound.json /etc/XrayR/
    fi
    curl -o /usr/bin/XrayR -Ls https://raw.githubusercontent.com/nnghi235/xrayr/main/XrayR.sh
    chmod +x /usr/bin/XrayR
    ln -s /usr/bin/XrayR /usr/bin/xrayr # chữ thường tương thích
    chmod +x /usr/bin/xrayr
    echo -e ""
    echo "------------[Nguyễn Nghị]------------"
    echo "---------[ADMIN SPEED4G.XYZ]---------"
    echo "  Cách Sử Dụng Tập Lệnh Quản Lý XrayR"
    echo "---------------------------------------------------------"
    echo "  XrayR                      - Hiển Thị Menu Quản Lý"
    echo "  cd ../.. && XrayR start    - Khởi Động XrayR"
    echo "  XrayR stop                 - Dừng XrayR"
    echo "  XrayR restart              - Khởi Động Lại XrayR"
    echo "  XrayR status               - Xem Trạng Thái XrayR"
    echo "  XrayR enable               - Cài Đặt XrayR Tự Động Khởi Động"
    echo "  XrayR disable              - Hủy Tự Động Khởi Động XrayR"
    echo "  XrayR log                  - Xem Nhật Ký XrayR"
    echo "  XrayR update               - Cập Nhật XrayR"
    echo "  XrayR update x.x.x         - Cập Nhật Phiên Bản XrayR Được Chỉ Định"
    echo "  XrayR config               - Hiển Thị Nội Dung Tệp Cấu Hình"
    echo "  XrayR install              - Cài Đặt XrayR"
    echo "  XrayR uninstall            - Gỡ Cài Dặt XrayR"
    echo "  XrayR version              - Xem Các Phiên Pản XrayR"
    echo "  nano /etc/XrayR/config.yml - Gọi Tệp Cấu Hình"
    echo "---------------------------------------------------------"
}

echo -e "  Bắt Đầu Cài Đặt ${plain}"
install_base
install_acme
install_XrayR $1
