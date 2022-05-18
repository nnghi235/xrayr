#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'

version="v1.0.0"

# check root
[[ $EUID -ne 0 ]] && echo -e "  Lỗi: Bạn Chưa Cấp Quyền Root\n" && exit 1

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

confirm() {
    if [[ $# > 1 ]]; then
        echo && read -p "$1 [mặc định$2]: " temp
        if [[ x"${temp}" == x"" ]]; then
            temp=$2
        fi
    else
        read -p "$1 [y/n]: " temp
    fi
    if [[ x"${temp}" == x"y" || x"${temp}" == x"Y" ]]; then
        return 0
    else
        return 1
    fi
}

confirm_restart() {
    confirm "  Bạn Có Muốn Khởi Động Lại XrayR Không ?" "y"
    if [[ $? == 0 ]]; then
        restart
    else
        show_menu
    fi
}

before_show_menu() {
    echo && echo -n -e "  Nhấn Enter Để Quay Lại Menu Chính: ${plain}" && read temp
    show_menu
}

install() {
    bash <(curl -Ls https://raw.githubusercontent.com/nnghi235/xrayr/main/install.sh)
    if [[ $? == 0 ]]; then
        if [[ $# == 0 ]]; then
            start
        else
            start 0
        fi
    fi
}

update() {
    if [[ $# == 0 ]]; then
        echo && echo -n -e "  Nhập Phiên Bản Được Chỉ Định ( Mặc Định Phiên Bản Mới Nhất ): " && read version
    else
        version=$2
    fi
#    confirm "本功能会强制重装当前最新版，数据不会丢失，是否继续?" " n"
#    if [[ $? != 0 ]]; then
#        echo -e "${red}已取消${plain}"
#        if [[ $1 != 0 ]]; then
#            before_show_menu
#        fi
#        return 0
#    fi
    bash <(curl -Ls https://raw.githubusercontent.com/nnghi235/xrayr/main/install.sh) $version
    if [[ $? == 0 ]]; then
        echo -e "  Cập Nhật Hoàn Tất, XrayR Đã Được Khởi Động Lại Tự Động ${plain}"
        exit
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

config() {
    echo "  XrayR Sẽ Tự Động Khởi Động Lại Sau Khi Sửa Đổi Cấu Hình"
    vi /etc/XrayR/config.yml
    sleep 2
    check_status
    case $? in
        0)
            echo -e "  Trạng Thái XrayR: Đang Hoạt Động ${plain}"
            ;;
        1)
            echo -e "  ADMIN SPEED4G.XYZ Phát Hiện Bạn Không Khởi Động XrayR Hoặc XrayR Không Tự Khởi Động Lại, Bạn Có Muốn Kiểm Tra Không ? [Y/n]" && echo
            read -e -p "(mặc định: y):" yn
            [[ -z ${yn} ]] && yn="y"
            if [[ ${yn} == [Yy] ]]; then
               show_log
            fi
            ;;
        2)
            echo -e "  Trạng Thái XrayR: Chưa Được Cài Đặt ${plain}"
    esac
}

uninstall() {
    confirm "  Bạn Có Chắc Chắn Muốn Gỡ Cài Đặt XrayR Không ?" " n"
    if [[ $? != 0 ]]; then
        if [[ $# == 0 ]]; then
            show_menu
        fi
        return 0
    fi
    systemctl stop XrayR
    systemctl disable XrayR
    rm /etc/systemd/system/XrayR.service -f
    systemctl daemon-reload
    systemctl reset-failed
    rm /etc/XrayR/ -rf
    rm /usr/local/XrayR/ -rf

    echo ""
    echo -e "  Gỡ Cài Đặt Thành Công ! " # nếu bạn muốn xóa tập lệnh này, hãy chạy sau khi thoát tập lệnh rm /usr/bin/XrayR -f xóa"
    echo ""

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

start() {
    check_status
    if [[ $? == 0 ]]; then
        echo ""
        echo -e "  XrayR Đang Hoạt Động, Nếu Muốn Khởi Động Lại XrayR Vui Lòng Nhập XrayR Restart${plain}"
    else
        systemctl start XrayR
        sleep 2
        check_status
        if [[ $? == 0 ]]; then
            echo -e "  XrayR Khởi Động Thành Công ! (COPYRIGHT BY ADMIN SPEED4G.XYZ) ${plain}"
        else
            echo -e "  XrayR Khởi Động Thất Bại, Vui Lòng Sử Dụng XrayR Log Để Kiểm Tra${plain}"
        fi
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}


stop() {
    systemctl stop XrayR
    sleep 2
    check_status
    if [[ $? == 1 ]]; then
        echo -e "  XrayR Đã Dừng Thành Công !${plain}"
    else
        echo -e "  XrayR Không Dừng Được, Vui Lòng Sử Dụng XrayR Log Để Kiểm Tra${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

restart() {
    systemctl restart XrayR
    sleep 2
    check_status
    if [[ $? == 0 ]]; then
        echo -e "  XrayR Khởi Động Lại Thành Công ! (COPYRIGHT BY ADMIN SPEED4G.XYZ)${plain}"
    else
        echo -e "  XrayR Khởi Động Lại Thất Bại, Vui Lòng Sử Dụng XrayR Log Để Kiểm Tra${plain}"
    fi
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

status() {
    systemctl status XrayR --no-pager -l
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

enable() {
    systemctl enable XrayR
    if [[ $? == 0 ]]; then
        echo -e "  XrayR Tự Động Khởi Động Thành Công${plain}"
    else
        echo -e "  XrayR Tự Động Khởi Động Thất Bại${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

disable() {
    systemctl disable XrayR
    if [[ $? == 0 ]]; then
        echo -e "  Hủy XrayR Tự Khởi Động Thành Công${plain}"
    else
        echo -e "  Hủy XrayR Tự Khởi Động Thất Bại${plain}"
    fi

    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_log() {
    journalctl -u XrayR.service -e --no-pager -f
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

install_bbr() {
    bash <(curl -L -s https://raw.githubusercontent.com/nnghi235/xrayr/main/tcp.sh)
    #if [[ $? == 0 ]]; then
    #    echo ""
    #    echo -e "${green}安装 bbr 成功，请重启服务器${plain}"
    #else
    #    echo ""
    #    echo -e "${red}下载 bbr 安装脚本失败，请检查本机能否连接 Github${plain}"
    #fi

    #before_show_menu
}

update_shell() {
    wget -O /usr/bin/XrayR -N --no-check-certificate https://raw.githubusercontent.com/nnghi235/xrayr/main/XrayR.sh
    if [[ $? != 0 ]]; then
        echo ""
        echo -e "  Không Tải Được Script Xuống, Vui Lòng Kiểm Tra Xem Máy Chủ Có Thể Kết Nối Với Github Không${plain}"
        before_show_menu
    else
        chmod +x /usr/bin/XrayR
        echo -e "  Tập Lệnh Nâng Cấp Thành Công, Vui Lòng Chạy Lại Tập Lệnh ${plain}" && exit 0
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

check_enabled() {
    temp=$(systemctl is-enabled XrayR)
    if [[ x"${temp}" == x"enabled" ]]; then
        return 0
    else
        return 1;
    fi
}

check_uninstall() {
    check_status
    if [[ $? != 2 ]]; then
        echo ""
        echo -e "  XrayR Đã Được Cài Đặt, Vui Lòng Không Cài Đặt Lại${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

check_install() {
    check_status
    if [[ $? == 2 ]]; then
        echo ""
        echo -e "  Vui Lòng Cài Đặt XrayR Trước${plain}"
        if [[ $# == 0 ]]; then
            before_show_menu
        fi
        return 1
    else
        return 0
    fi
}

show_status() {
    check_status
    case $? in
        0)
            echo -e "  Trạng Thái XrayR: Đang Hoạt Động${plain}"
            show_enable_status
            ;;
        1)
            echo -e "  Trạng Thái XrayR: Không Hoạt Động${plain}"
            show_enable_status
            ;;
        2)
            echo -e "  Trạng Thái XrayR: Chưa Được Cài Đặt${plain}"
    esac
}

show_enable_status() {
    check_enabled
    if [[ $? == 0 ]]; then
        echo -e "  XrayR Đang Tự Động Khởi Động${plain}"
    else
        echo -e "  XrayR Không Tự Động Khởi Động${plain}"
    fi
}

show_XrayR_version() {
    echo -n "  Phiên Bản XrayR："
    /usr/local/XrayR/XrayR -version
    echo ""
    if [[ $# == 0 ]]; then
        before_show_menu
    fi
}

show_usage() {
    echo ''
    echo "------------[Nguyễn Nghị]------------"
	echo "---------[ADMIN SPEED4G.XYZ]---------"
    echo "  Cách sử dụng tập lệnh quản lý XrayR: "
    echo "------------------------------------------"
    echo "  XrayR                      - Hiển Thị Menu Quản Trị"
    echo "  XrayR start                - Khởi Động XrayR "
    echo "  XrayR stop                 - Dừng XrayR"
    echo "  XrayR restart              - Khởi Động Lại XrayR"
    echo "  XrayR status               - Xem Trạng Thái XrayR"
    echo "  XrayR enable               - Cài Đặt XrayR Tự Động Khởi Động"
    echo "  XrayR disable              - Hủy Tự Động Khởi Động XrayR"
    echo "  XrayR log                  - Xem Nhật Ký Hoạt Động"
    echo "  XrayR update               - Cập Nhật XrayR"
    echo "  XrayR update x.x.x         - Cập Nhật Phiên Bản XrayR Được Chỉ Định"
    echo "  XrayR install              - Cài Đặt XrayR"
    echo "  XrayR uninstall            - Gỡ Cài Đặt XrayR "
    echo "  XrayR version              - Xem Các Phiên Bản XrayR"
    echo "  nano /etc/XrayR/config.yml - Gọi Tệp Cấu Hình"
    echo "------------------------------------------"
}

show_menu() {
    echo -e "
    Các Tập Lệnh Quản Lý Phụ Trợ XrayR，Không Hoạt Động Với Docker${plain}
    ${green}--- [Nguyễn Nghị] ---${plain}
————————————————————————————————
    0. Thay Đổi Cài Đặt
————————————————————————————————
    1. Cài Đặt XrayR
————————————————————————————————
    2. Cập Nhật XrayR
————————————————————————————————
    3. Gỡ Cài Đặt XrayR
————————————————————————————————
    4. Khởi Động XrayR
————————————————————————————————
    5. Dừng XrayR
————————————————————————————————
    6. Khởi Động Lại XrayR
————————————————————————————————
    7. Xem Trạng Thái XrayR
————————————————————————————————
    8. Xem Nhật Ný XrayR
————————————————————————————————
    9. Cài Đặt XrayR Tự Khởi Động
————————————————————————————————
   10. Hủy XrayR Tự Khởi Động
————————————————————————————————
   11. Một Click Cài Đặt BBR
————————————————————————————————
   12. Xem Các Phiên Bản XrayR
————————————————————————————————
   13. Nâng Cấp Tập Lệnh Bảo Trì
————————————————————————————————   
 "
 #Các bản cập nhật tiếp theo có thể được thêm vào chuỗi trên
    show_status
    echo && read -p "  Vui Lòng Nhập Một Lựa Chọn [0-13]: " num

    case "${num}" in
        0) config
        ;;
        1) check_uninstall && install
        ;;
        2) check_install && update
        ;;
        3) check_install && uninstall
        ;;
        4) check_install && start
        ;;
        5) check_install && stop
        ;;
        6) check_install && restart
        ;;
        7) check_install && status
        ;;
        8) check_install && show_log
        ;;
        9) check_install && enable
        ;;
        10) check_install && disable
        ;;
        11) install_bbr
        ;;
        12) check_install && show_XrayR_version
        ;;
        13) update_shell
        ;;
        *) echo -e "  Vui Lòng Nhập Số Chính Xác [0-13]${plain}"
        ;;
    esac
}


if [[ $# > 0 ]]; then
    case $1 in
        "start") check_install 0 && start 0
        ;;
        "stop") check_install 0 && stop 0
        ;;
        "restart") check_install 0 && restart 0
        ;;
        "status") check_install 0 && status 0
        ;;
        "enable") check_install 0 && enable 0
        ;;
        "disable") check_install 0 && disable 0
        ;;
        "log") check_install 0 && show_log 0
        ;;
        "update") check_install 0 && update 0 $2
        ;;
        "config") config $*
        ;;
        "install") check_uninstall 0 && install 0
        ;;
        "uninstall") check_install 0 && uninstall 0
        ;;
        "version") check_install 0 && show_XrayR_version 0
        ;;
        "update_shell") update_shell
        ;;
        *) show_usage
    esac
else
    show_menu
fi
