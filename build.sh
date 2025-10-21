#!/usr/bin/env bash

# Source config functions
source .cirrus_config.sh

timeStart
cd $CIRRUS_WORKING_DIR/OrangeFox/fox_${FOX_SYNC_BRANCH}

echo -e "\033[0;36m##########################################\033[0m"
echo -e "\033[0;36m$(figlet "OrangeFox")\033[0m"
echo -e "\033[0;36m##########################################\033[0m"

source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true

BUILDLOG="build.log"
DEVICE=$(grep "PRODUCT_MODEL :=" ${DEVICE_PATH}/twrp_*.mk -m 1 | cut -d = -f 2)

build_message "lunch twrp_${DEVICE_NAME}-eng"
lunch twrp_${DEVICE_NAME}-eng
sleep 5

build_message "Building... 🛠️"
mkfifo -m 644 reading
tee -a ${BUILDLOG} < reading & progress & mka adbd ${BUILD_TARGET}image -j$(nproc --all) > reading
retVal=$?

timeEnd
statusBuild

# Extract build information
EV1=$(TZ=Asia/Jakarta date +%Y%m%d)
EV2=$(grep "PRODUCT_MODEL :=" ${DEVICE_PATH}/twrp_*.mk -m 1 | cut -d = -f 2)
EV3=$(ls -lh out/target/product/${DEVICE_NAME}/OrangeFox*.zip | cut -d ' ' -f5)
EV4=$(md5sum out/target/product/${DEVICE_NAME}/OrangeFox*.zip | cut -d ' ' -f1)
EV5=$(sha1sum out/target/product/${DEVICE_NAME}/OrangeFox*.zip | cut -d ' ' -f1)
EV6=$(cd ${DEVICE_PATH} && git log --pretty=format:'%s' -1)
EV10=$(grep "#### build completed successfully" ${BUILDLOG} -m 1 | cut -d '(' -f 2)

export BUILD_DATE=${EV1}
export DEVICE=${EV2}
export ORF_SIZE=${EV3}
export ORF_MD5=${EV4}
export ORF_SHA1=${EV5}
export DT_COMMIT=${EV6}
export ORF_ACTOR=${CIRRUS_REPO_OWNER}
export ORF_REPONAME=${CIRRUS_REPO_NAME}
export ORF_ID=${CIRRUS_BUILD_ID}
export ORF_TIME=${EV10}

if [[ "${GH_RELEASE}" == "true" ]] && [[ -n "$GH_TOKEN" ]]; then
    source .cirrus_config.sh
    bash .cirrus_notes.sh
    
    # Create release with assets
    echo "Creating GitHub release..."
    gh release create ${CIRRUS_BUILD_ID} \
        out/target/product/${DEVICE_NAME}/OrangeFox*.img \
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
    git push origin main
    
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
