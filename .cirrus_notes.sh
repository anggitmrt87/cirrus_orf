#!/usr/bin/env bash

# Create release notes
echo "
## OrangeFox Recovery Build - Unofficial
🖥 OrangeFox Branch: ${FOX_SYNC_BRANCH}
📱 Device: ${DEVICE}
📝 CodeName: ${DEVICE_NAME}
📂 Size: ${ORF_SIZE}
👩‍💻 Top Commit: ${DT_COMMIT}
📕 MD5: ${ORF_MD5}
📘 SHA1: ${ORF_SHA1}
" >> ./release-notes.md

# Create README.md from template
if [[ -f ".cirrus_readme_template.md" ]]; then
    echo "Creating README.md from template..."
    
    # Read template and replace variables
    README_CONTENT=$(cat .cirrus_readme_template.md | \
        sed "s/{{DEVICE}}/${DEVICE}/g" | \
        sed "s/{{DEVICE_NAME}}/${DEVICE_NAME}/g" | \
        sed "s/{{FOX_SYNC_BRANCH}}/${FOX_SYNC_BRANCH}/g" | \
        sed "s/{{BUILD_DATE}}/${BUILD_DATE}/g" | \
        sed "s/{{ORF_SIZE}}/${ORF_SIZE}/g" | \
        sed "s/{{ORF_MD5}}/${ORF_MD5}/g" | \
        sed "s/{{ORF_SHA1}}/${ORF_SHA1}/g" | \
        sed "s/{{DT_COMMIT}}/${DT_COMMIT}/g" | \
        sed "s/{{ORF_ACTOR}}/${ORF_ACTOR}/g" | \
        sed "s/{{ORF_REPONAME}}/${ORF_REPONAME}/g" | \
        sed "s/{{ORF_ID}}/${ORF_ID}/g" | \
        sed "s/{{ORF_TIME}}/${ORF_TIME}/g")
    
    echo "$README_CONTENT" > README.md
    echo "README.md created successfully!"
else
    echo "Template file not found, creating basic README.md..."
    
    cat > README.md << EOF
# OrangeFox Recovery for ${DEVICE} (${DEVICE_NAME})

## Build Information
- **Device**: ${DEVICE}
- **Codename**: ${DEVICE_NAME} 
- **OrangeFox Branch**: ${FOX_SYNC_BRANCH}
- **Build Date**: ${BUILD_DATE}
- **Size**: ${ORF_SIZE}

## Download
[GitHub Releases](https://github.com/${ORF_ACTOR}/${ORF_REPONAME}/releases/tag/${ORF_ID})

## Verification
- **MD5**: ${ORF_MD5}
- **SHA1**: ${ORF_SHA1}

---
*Built automatically with Cirrus CI*
EOF
fi
