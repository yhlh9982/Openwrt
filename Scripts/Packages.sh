#!/bin/bash

#更新软件包
UPDATE_PACKAGE() {
	local PKG_NAME=$1
	local PKG_REPO=$2
	local PKG_BRANCH=$3
	local PKG_SPECIAL=$4
	local REPO_NAME=$(echo $PKG_REPO | cut -d '/' -f 2)

	rm -rf $(find ../feeds/luci/ -type d -iname "*$PKG_NAME*" -prune)

	git clone --depth=1 --single-branch --branch $PKG_BRANCH "https://github.com/$PKG_REPO.git"
        git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/openwrt-passwall
        git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall package/luci-app-passwall
	git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall2 package/luci-app-passwall2
        git clone --depth=1 -b lede https://github.com/pymumu/luci-app-smartdns package/luci-app-smartdns
        git clone --depth=1 https://github.com/pymumu/openwrt-smartdns package/smartdns
	git clone --depth=1 https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
 

	if [[ $PKG_SPECIAL == "pkg" ]]; then
		cp -rf $(find ./$REPO_NAME/ -type d -iname "*$PKG_NAME*" -prune) ./
		rm -rf ./$REPO_NAME
	elif [[ $PKG_SPECIAL == "name" ]]; then
		mv -f $REPO_NAME $PKG_NAME
	fi
}

UPDATE_PACKAGE "design" "gngpp/luci-theme-design" "$([[ $WRT_URL == *"lede"* ]] && echo "main" || echo "js")"
UPDATE_PACKAGE "design-config" "gngpp/luci-app-design-config" "master"
UPDATE_PACKAGE "argon" "jerrykuku/luci-theme-argon" "$([[ $WRT_URL == *"lede"* ]] && echo "18.06" || echo "master")"
UPDATE_PACKAGE "argon-config" "jerrykuku/luci-app-argon-config" "$([[ $WRT_URL == *"lede"* ]] && echo "18.06" || echo "master")"

UPDATE_PACKAGE "helloworld" "fw876/helloworld" "master"
UPDATE_PACKAGE "openclash" "vernesong/OpenClash" "dev"
UPDATE_PACKAGE "openwrt-passwall" "xiaoruoji/openwrt-passwall" "main"
UPDATE_PACKAGE "openwrt-passwall2" "xiaoruoji/openwrt-passwall2" "main"
UPDATE_PACKAGE "smartdns" "pymumu/smartdns" "master" 
UPDATE_PACKAGE "luci-app-mosdns" "sbwml/luci-app-mosdns" "v5"


if [[ $WRT_URL == *"immortalwrt"* ]]; then
	UPDATE_PACKAGE "homeproxy" "immortalwrt/homeproxy" "dev"
fi

#更新软件包版本
UPDATE_VERSION() {
	local PKG_NAME=$1
	local NEW_VER=$2
	local NEW_HASH=$3
	local PKG_FILE=$(find ../feeds/packages/*/$PKG_NAME/ -type f -name "Makefile" 2>/dev/null)

	if [ -f "$PKG_FILE" ]; then
		local OLD_VER=$(grep -Po "PKG_VERSION:=\K.*" $PKG_FILE)
		if dpkg --compare-versions "$OLD_VER" lt "$NEW_VER"; then
			sed -i "s/PKG_VERSION:=.*/PKG_VERSION:=$NEW_VER/g" $PKG_FILE
			sed -i "s/PKG_HASH:=.*/PKG_HASH:=$NEW_HASH/g" $PKG_FILE
			echo "$PKG_NAME ver has updated!"
		else
			echo "$PKG_NAME ver is latest!"
		fi
	else
		echo "$PKG_NAME not found!"
	fi
}

UPDATE_VERSION "sing-box" "1.9.0-rc.12" "14ddbee9a648e45b831f78d941ac0b2a7fc7f99ff5649964356c71a8d4b6cb6e"
