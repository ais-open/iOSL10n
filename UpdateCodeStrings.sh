#!/bin/sh

#  FindInFile.sh
#  
#
#  Created by Gregory Hill on 2/28/13.
#
# Usage:
# ./FindInFile.sh <baseDir>
#	e.g. ~/Desktop/Code/Pandora/dev/Pandora


baseDir=$1

localeDirExt=".lproj"
stringsFile="Localizable.strings"

baseDirLength=$(echo ${#baseDir})

if [ $baseDirLength -eq 0 ]; then
	echo "FindInFile.sh <baseDir>"
else

	# First, loop through all *.m files and find any occurance of NSLocalizedString().
	# Write anything found to output.txt.  This will be the source for the English versions of all
	#	key/value localized strings.

	fullPath="$baseDir"

	clear

	echo "************************************************************************************"
	echo "************************************************************************************"
	echo "grepping NSLocalizedString(,) occurrences."
	echo "Start: $fullPath"

	# change directory into fullPath
	cd "$fullPath"
	pwd

	find . -type f -name "*.m*" -print > listOfFiles.txt

	cat listOfFiles.txt |tr '\n' '\0' |xargs -0 grep -o "NSLocalizedString(@\"[[:alnum:]]*\", @\"[a-zA-Z0-9 !@#\$%\^&\*()\.,-\+']*\")" > output.txt

	# Next, get all locale strings folders.  If Localizable.strings found, append to existing file; otherwise, create a new one.

	for localeStringsDir in `find . -name "*$localeDirExt" -print`
	do
		echo "\n**************************************************"
		echo "Found Locale File.\n"
		echo "strings dir: $localeStringsDir"

		foundDir=$(echo $localeStringsDir | grep -o "Base.lproj")
		length=$(echo ${#foundDir})

		# Make sure we aren't touching Base.lproj directory
		if [ $length -eq 0 ]; then
			# change directory into localeStringsDir
			cd "$localeStringsDir"

			echo "cd down to:"
			pwd

			if [ -f $stringsFile ]; then
				echo "File $localeStringsDir/$stringsFile exists"
			else
				echo "File $localeStringsDir/$stringsFile does not exist"

				echo "" > $stringsFile
			fi

			# For each Localizable.strings file, loop through output.txt and parse out the key/value pairs for the localized strings.
			# If the key already exists in the file, then skip; otherwise, append the key/value (in proper format) to the end of the file.

			while read LINE
			do
				foundLocalizedString=$(echo "$LINE" | grep -o "NSLocalizedString(@\"[[:alnum:]]*\", @\"[a-zA-Z0-9 !@#\$%\^&\*()\.,-\+']*\")")

				foundKey=$(echo "$foundLocalizedString" | grep -o "(@\"[[:alnum:]]*\"")
				keyStart="\""
				finalKey=$(echo "$foundKey" | grep -o "$keyStart.*")

				$(grep -q "$finalKey" $stringsFile)

				if [ $? -eq 1 ]; then
					echo "****** key is New: $finalKey"

					foundComment=$(echo "$foundLocalizedString" | grep -o "@\"[a-zA-Z0-9 !@#\$%\^&\*()\.,-\+']*\")")
					commentStart="\""
					intermediateComment=$(echo "$foundComment" | grep -o "$commentStart.*")

					finalComment=$(echo "$intermediateComment" | sed "s/)//")

					echo "/* $finalComment */" >> $stringsFile
					echo "$finalKey = $finalComment;\n" >> $stringsFile
				else
					echo "key Exists: $finalKey"
				fi

			done < "../../output.txt"

			# change directory back to baseDir
			cd ../..

			echo "cd back up ..:"
			pwd

			echo "*!*!*!*!!!!"

		else
			echo "Ignoring: $localeStringsDir"
		fi
	done

	echo "\nDone."
fi

