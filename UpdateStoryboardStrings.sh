#!/bin/sh

# cls.sh - script to  Create Locale Strings auto
#  
#
#  Created by Gregory Hill on 2/27/13.
#  Copyright (c) 2013 Gregory Hill. All rights reserved.

clear

baseDir=$1

baseDirLength=$(echo ${#baseDir})

if [ $baseDirLength -eq 0 ]; then
	echo "cls.sh <rootPath>"
else
	storyboardExt=".storyboard"
	stringsExt=".strings"
	newStringsExt=".strings.new"
	oldStringsExt=".strings.old"
	localeDirExt=".lproj"

	isNewStringsFile=false

	echo "********************************************"
	echo "Starting 'Create Locale Strings'"
	echo "Moving to dir: $baseDir"

	cd $baseDir

	# Find storyboard file full path inside project folder
	for storyboardPath in `find . -name "*$storyboardExt" -print`
	do
		# Get Base strings file full path
		baseStringsPath=$(echo "$storyboardPath" | sed "s/$storyboardExt/$stringsExt/")

		echo "\nstoryboardPath: $storyboardPath"
		echo "\nbaseStringsPath: $baseStringsPath\n"

		find . -type f -name "$baseStringsPath" -print > listOfFiles.txt

		if [ -f $baseStringsPath ]; then
			echo "File $baseStringsPath exists"

			isNewStringsFile=false
		else
			echo "$baseStringsPath file doesn't exist; create"

			ibtool --export-strings-file $baseStringsPath $storyboardPath

			isNewStringsFile=true
		fi

		# Create strings file only when storyboard file newer
		if $isNewStringsFile || find $storyboardPath -prune -newer $baseStringsPath -print | grep -q .; then
			echo "$storyboardPath is modified; update $baseStringsPath"

			# Get storyboard file name and folder
			storyboardFile=$(basename "$storyboardPath")
			storyboardDir=$(dirname "$storyboardPath")

			# Get New Base strings file full path and strings file name
			newBaseStringsPath=$(echo "$storyboardPath" | sed "s/$storyboardExt/$newStringsExt/")
			stringsFile=$(basename "$baseStringsPath")

			ibtool --export-strings-file $newBaseStringsPath $storyboardPath

			iconv -f UTF-16 -t UTF-8 $newBaseStringsPath > $baseStringsPath

			rm $newBaseStringsPath

			# Get all locale strings folder
			for localeStringsDir in `find . -name "*$localeDirExt" -print`
			do
				echo "******* \nlocaleStringsDir: $localeStringsDir"

				# Skip Base strings folder
				if [ $localeStringsDir != $storyboardDir ]; then
					localeStringsPath=$localeStringsDir/$stringsFile

					echo "localeStringsPath: $localeStringsPath\n"

					# Just copy base strings file on first time
					if [ ! -e $localeStringsPath ]; then
						cp $baseStringsPath $localeStringsPath
					else
						oldLocaleStringsPath=$(echo "$localeStringsPath" | sed "s/$stringsExt/$oldStringsExt/")
						cp $localeStringsPath $oldLocaleStringsPath

						# Merge baseStringsPath to localeStringsPath
						awk 'NR == FNR && /^\/\*/ {x=$0; getline; a[x]=$0; next} /^\/\*/ {x=$0; print; getline; $0=a[x]?a[x]:$0; printf $0"\n\n"}' $oldLocaleStringsPath $baseStringsPath > $localeStringsPath

						rm $oldLocaleStringsPath
					fi
				fi
			done
		else
			echo "$storyboardPath file not modified."
		fi
	done
fi

