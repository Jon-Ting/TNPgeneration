#!/bin/bash
TARGET_DIR=/scratch/q27/kl1588

dirs=$(find ../TNP -type d)
for dir in $dirs; do
	dirName=${dir:18:${#dir}}
	if [ -z $dirName ]; then continue; fi
	if test ! -d "$TARGET_DIR/$dirName"; then mkdir "$TARGET_DIR/$dirName"; fi
	files=$(find $dir -name "*.lmp")
	for file in $files; do
		tmp=${file:${#dir}:${#file}}
		fileName=${tmp:1:${#tmp}}
		tmp=$((${#fileName} - 4))
		fileDirName=${fileName:0:$tmp}
		if test ! -d "$TARGET_DIR/$dirName/$fileDirName"; then mkdir "$TARGET_DIR/$dirName/$fileDirName"; fi
		if test ! -e "$TARGET_DIR/$dirName/$fileDirName/$fileName"; then
            cp $file "$TARGET_DIR/$dirName/$fileDirName"
        else
            echo "$fileName already exists, skipped!"
            continue
        fi
		echo "Copied $fileName to $TARGET_DIR/$dirName/$fileDirName!"
	done
done
echo "All done!"
