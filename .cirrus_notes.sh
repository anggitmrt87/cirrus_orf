#!/usr/bin/env bash

echo "
## OrangeFox Recovery Build - Unofficial
🖥 OrangeFox Branch: ${FOX_BRANCH}
📱 Device: ${DEVICE}
📝 CodeName: ${DEVICE_NAME}
📂 Size: ${ORF_SIZE}
👩‍💻 Top Commit: ${DT_COMMIT}
📕 MD5: ${ORF_MD5}
📘 SHA1: ${ORF_SHA1}
" >> ./release-notes.md
