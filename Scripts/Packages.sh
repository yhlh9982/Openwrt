#!/bin/bash

#安装和更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)

	rm -rf $(find ../feeds/luci/ ../feeds/packages/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune)
# 移除要替换的包
rm -rf feeds/packages/lang/golang
rm -rf feeds/packages/net/v2ray-geodata
rm -rf feeds/packages/net/mosdns
rm -rf feeds/luci/applications/luci-app-mosdns
rm -rf feeds/packages/net/smartdns
rm -rf feeds/packages/net/msd_lite
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/themes/luci-theme-netgear
rm -rf feeds/luci/applications/luci-app-netdata
rm -rf feeds/luci/applications/luci-app-serverchan


	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"

	if [[ $PKG_SPECIAL == "pkg" ]]; then
		cp -rf $(find ./$REPO_NAME/*/ -maxdepth 3 -type d -iname "*$PKG_NAME*" -prune) ./
		rm -rf ./$REPO_NAME/
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

#UPDATE_PACKAGE "包名" "项目地址" "项目分支" "pkg/name，可选，pkg为从大杂烩中单独提取包名插件；name为重命名为包名"
UPDATE_PACKAGE "design" "gngpp/luci-theme-design" "$([[ $WRT_URL == *"lede"* ]] && echo "main" || echo "js")"
UPDATE_PACKAGE "design-config" "gngpp/luci-app-design-config" "master"
UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "$([[ $WRT_URL == *"lede"* ]] && echo "18.06" || echo "master")"
UPDATE_PACKAGE "argon-config" "jerrykuku/luci-app-argon-config" "$([[ $WRT_URL == *"lede"* ]] && echo "18.06" || echo "master")"

UPDATE_PACKAGE "natedate" "Jason6111/luci-app-netdata" "master"
UPDATE_PACKAGE "poweroff" "esirplayground/luci-app-poweroff" "master"
UPDATE_PACKAGE "luci-app-msd_lite" "ximiTech/luci-app-msd_lite" "master"
UPDATE_PACKAGE "msd_lite" "ximiTech/msd_lite" "master"
UPDATE_PACKAGE "Alist" "sbwml/luci-app-alist" "master"

#smartdns相关
UPDATE_PACKAGE "smartdns" "pymumu/openwrt-smartdns" "master"
#mosdns
UPDATE_PACKAGE "v2ray-geodata" "sbwml/v2ray-geodata" "master"
UPDATE_PACKAGE "mosdns" "sbwml/luci-app-mosdns" "v5"
#科学插件
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev" "pkg"
UPDATE_PACKAGE "ssr-plus" "fw876/helloworld" "master"
UPDATE_PACKAGE "passwall-packages" "xiaorouji/openwrt-passwall-packages" "main"
UPDATE_PACKAGE "passwall" "xiaorouji/openwrt-passwall" "main"
#UPDATE_PACKAGE "passwall" "xiaorouji/openwrt-passwall" "luci-smartdns-dev"
UPDATE_PACKAGE "passwall2" "xiaorouji/openwrt-passwall2" "main"

UPDATE_PACKAGE "gecoosac" "lwb1978/openwrt-gecoosac" "main"

if [[ $WRT_URL != *"lede"* ]]; then
        UPDATE_PACKAGE "luci-app-smartdns" "pymumu/luci-app-smartdns" "lede"
	UPDATE_PACKAGE "lang_golang" "sbwml/packages_lang_golang" "21.x"
fi

if [[ $WRT_URL == *"openwrt-6.x"* ]]; then
	UPDATE_PACKAGE "qmi-wwan" "immortalwrt/wwan-packages" "master" "pkg"
        UPDATE_PACKAGE "luci-app-smartdns" "pymumu/luci-app-smartdns" "master"
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_MARK=${3:-not}
	local PKG_FILES=$(find ./ ../feeds/packages/ -maxdepth 3 -type f -wholename "*/$PKG_NAME/Makefile")

    echo " "

    if [ -z "$PKG_FILES" ]; then
        echo "$PKG_NAME not found!"
        return
    fi

    echo "$PKG_NAME version update has started!"

    local PKG_VER=$(curl -sL "https://api.github.com/repos/$PKG_REPO/releases" | jq -r "map(select(.prerelease|$PKG_MARK)) | first | .tag_name")
    local NEW_VER=$(echo $PKG_VER | sed "s/.*v//g; s/_/./g")
    local NEW_HASH=$(curl -sL "https://codeload.github.com/$PKG_REPO/tar.gz/$PKG_VER" | sha256sum | cut -b -64)

    for PKG_FILE in $PKG_FILES; do
        local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" "$PKG_FILE")

        echo "$OLD_VER $PKG_VER $NEW_VER $NEW_HASH"

        if [[ $NEW_VER =~ ^[0-9].* ]] && dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
            sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" "$PKG_FILE"
            sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" "$PKG_FILE"
            echo "$PKG_FILE version has been updated!"
        else
            echo "$PKG_FILE version is already the latest!"
        fi
    done
}
