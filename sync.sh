#!/usr/bin/env bash

# Source config functions
source .cirrus_config.sh

timeStart
echo -e "\033[0;36mSync OrangeFox Recovery...\033[0m"

mkdir -p $CIRRUS_WORKING_DIR/OrangeFox && cd $CIRRUS_WORKING_DIR/OrangeFox
git config --global user.name "${USER_NAME}"
git config --global user.email "${USER_EMAIL}"

echo "${GH_TOKEN}" >> ikitoken.txt
unset GH_TOKEN
gh auth login --with-token < ikitoken.txt

git clone ${FOX_SYNC} $CIRRUS_WORKING_DIR/sync && cd $CIRRUS_WORKING_DIR/sync
./orangefox_sync.sh --branch ${FOX_SYNC_BRANCH} --path $CIRRUS_WORKING_DIR/OrangeFox/fox_${FOX_SYNC_BRANCH}
cd $CIRRUS_WORKING_DIR/OrangeFox/fox_${FOX_SYNC_BRANCH}

# Add required components
if [[ ! -d bootable/recovery/gui/theme ]]; then
    echo -e "\033[0;36mAdding Theme...\033[0m"
    git clone https://gitlab.com/OrangeFox/misc/theme.git bootable/recovery/gui/theme
fi

if [[ ! -d external/nano ]]; then
    echo -e "\033[0;36mAdding Nano Library...\033[0m"
    git clone https://github.com/LineageOS/android_external_nano -b lineage-19.1 external/nano
fi

if [[ ! -d external/libncurses ]]; then
    echo -e "\033[0;36mAdding libncurses Library...\033[0m"
    git clone https://github.com/LineageOS/android_external_libncurses -b lineage-19.1 external/libncurses
fi

if [[ ! -d external/bash ]]; then
    echo -e "\033[0;36mAdding Bash Library...\033[0m"
    git clone https://github.com/LineageOS/android_external_bash -b lineage-19.1 external/bash
fi

if [[ ! -d external/lptools ]]; then
    echo -e "\033[0;36mAdding lptools Library...\033[0m"
    git clone https://github.com/phhusson/vendor_lptools external/lptools
fi

if [[ -n "${MAINTAINER_URL}" ]]; then
    echo -e "\033[0;36mChange Maintainer Profile...\033[0m"
    wget ${MAINTAINER_URL} -O maintainer.png
    cp -r maintainer.png bootable/recovery/gui/theme/portrait_hdpi/images/Default/About/
fi

if [[ -n "${KERNEL_TREE}" ]]; then
    echo -e "\033[0;36mCloning Kernel Tree...\033[0m"
    git clone ${KERNEL_TREE} -b ${KERNEL_BRANCH} ${KERNEL_PATH}
fi

if [[ -n "${COMMON_TREE}" ]]; then
    echo -e "\033[0;36mCloning Common Tree...\033[0m"
    git clone ${COMMON_TREE} -b ${COMMON_BRANCH} ${COMMON_PATH}
fi

if [[ -n "${DEVICE_TREE}" ]]; then
    echo -e "\033[0;36mCloning Device Tree...\033[0m"
    git clone ${DEVICE_TREE} -b ${DEVICE_TREE_BRANCH} ${DEVICE_PATH}
fi
timeEnd
