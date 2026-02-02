#!/usr/bin/env bash

# Source config functions
source $CIRRUS_WORKING_DIR/.cirrus_config.sh

timeStart
cd $CIRRUS_WORKING_DIR/OrangeFox/fox_${FOX_SYNC_BRANCH}

echo -e "\033[0;36m##########################################\033[0m"
echo -e "\033[0;36m$(figlet "OrangeFox")\033[0m"
echo -e "\033[0;36m##########################################\033[0m"

# Setup CCache dengan logging yang lebih baik
echo -e "\033[0;36mSetting up CCache...\033[0m"
export USE_CCACHE="1"
export CCACHE_DIR="/cirrus/ccache"
ccache -M 20G
ccache -o compression=true
ccache -o compression_level=6

# Show detailed CCache stats before build
echo -e "\033[0;36m=== CCache Stats Before Build ===\033[0m"
ccache -s
echo -e "\033[0;36m=================================\033[0m"

# Info cache directory
echo -e "\033[0;36mCCache directory: ${CCACHE_DIR}\033[0m"
echo -e "\033[0;36mCCache contents:\033[0m"
ls -la ${CCACHE_DIR} 2>/dev/null | head -10 || echo "Cache directory is empty"

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES="true"

BUILDLOG="build.log"
DEVICE=$(grep "PRODUCT_MODEL :=" ${DEVICE_PATH}/twrp_*.mk -m 1 | cut -d = -f 2)

build_message "lunch twrp_${DEVICE_NAME}-eng"
lunch twrp_${DEVICE_NAME}-eng
sleep 5

build_message "Building... 🛠️"
mkfifo -m 644 reading
tee -a ${BUILDLOG} < reading & progress & mka adbd ${BUILD_TARGET}image -j$(nproc --all) CCACHE=1 > reading
retVal=$?

# Show detailed CCache stats after build
echo -e "\033[0;36m=== CCache Stats After Build ===\033[0m"
ccache -s
echo -e "\033[0;36m================================\033[0m"

# Show cache effectiveness
echo -e "\033[0;36mCache Effectiveness:\033[0m"
ccache -s | grep -E "hit rate|hit ratio"

timeEnd
statusBuild

# Extract build information
EV1=$(TZ=Asia/Jakarta date +%Y%m%d)
EV2=$(grep "PRODUCT_MODEL :=" ${DEVICE_PATH}/twrp_*.mk -m 1 | cut -d = -f 2)
EV3=$(ls -lh out/target/product/${DEVICE_NAME}/OrangeFox*.zip | cut -d ' ' -f5)
EV4=$(md5sum out/target/product/${DEVICE_NAME}/OrangeFox*.zip | cut -d ' ' -f1)
EV5=$(sha1sum out/target/product/${DEVICE_NAME}/OrangeFox*.zip | cut -d ' ' -f1)
EV6=$(cd ${DEVICE_PATH} && git log --pretty=format:'%s' -1)
EV7=$(ls out/target/product/${DEVICE_NAME}/OrangeFox*.zip)
EV10=$(grep "#### build completed successfully" ${BUILDLOG} -m 1 | cut -d '(' -f 2)

export BUILD_DATE="${EV1}"
export DEVICE="${EV2}"
export ORF_SIZE="${EV3}"
export ORF_MD5="${EV4}"
export ORF_SHA1="${EV5}"
export DT_COMMIT="${EV6}"
export ORF_ZIPNAME="${EV7}"
export ORF_ACTOR="${CIRRUS_REPO_OWNER}"
export ORF_REPONAME="${CIRRUS_REPO_NAME}"
export ORF_ID="${CIRRUS_BUILD_ID}"
export ORF_TIME="${EV10}"

if [[ "${GH_RELEASE}" == "true" ]] && [[ -n "$GH_TOKEN" ]]; then
    bash $CIRRUS_WORKING_DIR/.cirrus_notes.sh
    
    # Create release with assets
    echo "Creating GitHub release..."
    mv out/target/product/${DEVICE_NAME}/OrangeFox*.img out/target/product/${DEVICE_NAME}/recovery.img
    gh release create ${CIRRUS_BUILD_ID} \
        out/target/product/${DEVICE_NAME}/recovery.img \
        out/target/product/${DEVICE_NAME}/OrangeFox*.zip \
        out/target/product/${DEVICE_NAME}/OrangeFox*.zip.md5 \
        --title "🦊 OrangeFox Recovery for ${DEVICE} (${DEVICE_NAME}) // ${BUILD_DATE}" \
        -F ./release-notes.md \
        -R "${REPO_PUBLISH}"
    
    # Push README.md to repository
    echo "Pushing README.md to repository..."
    
    # Setup git
    git config --global user.name "${USER_NAME}"
    git config --global user.email "${USER_EMAIL}"
    
    # Clone target repository
    TEMP_DIR=$(mktemp -d)
    git clone "https://${USER_NAME}:${GH_TOKEN}@github.com/${REPO_PUBLISH}.git" "${TEMP_DIR}"
    cd "${TEMP_DIR}"
    
    # Copy and commit README
    cp "${CIRRUS_WORKING_DIR}/README.md" ./
    git add README.md
    git commit -m "docs: Update README for ${DEVICE} (${DEVICE_NAME}) - ${BUILD_DATE}" || echo "No changes to commit"
    git push origin -f
    
    # Cleanup
    cd "${CIRRUS_WORKING_DIR}"
    rm -rf "${TEMP_DIR}"
    
    echo "README.md successfully pushed to repository!"
    
    post_message
else
    echo -e "\033[0;36m##########################################\033[0m"
    echo -e "\033[0;36m$(figlet "OrangeFox")\033[0m"
    echo -e "\033[0;36m##########################################\033[0m"
fi
