#!/bin/bash

tutorialPath="../tutorials"
tutorialDestination="source/_static/tutorials"
rstDestination="source/tutorials"
mkdir -p "$tutorialDestination"

declare -a tutorials

nTutorial=0
for path in $tutorialPath/*
do
    if ! [[ -d "${path}" ]]; then
        continue  # if not a directory, skip
    fi
    for tutorial in ${path}/*.html; do
        if ! [[ -f "$tutorial" ]]; then
            break
        fi
        let "nTutorial+=1"
        tutorials[$nTutorial]="$tutorial"
    done
done

# clean destination folder
echo "Cleaning destination folders for html and rst files"
find "$tutorialDestination" -name "tutorial*.html" -exec rm -f {} \;
find "$rstDestination" -name "tutorial*.rst" -exec rm -f {} \;

## now loop through the above array
echo "Preparing tutorial"
echo >> $rstDestination/index.rst
echo >> $rstDestination/index.rst
echo ".. toctree::" >> $rstDestination/index.rst
echo >> $rstDestination/index.rst

for tutorial in "${tutorials[@]}"
do
    tutorialDir=${tutorial%/*}
    tutorialName=${tutorial##*/}
    tutorialName="${tutorialName%.*}"
    tutorialTitle=`awk '/<title>/ { show=1 } show; /<\/title>/ { show=0 }'  $tutorialPath/$tutorialDir/$tutorialName.html | sed -e 's#.*<title>\(.*\)</title>.*#\1#'`

    echo "  - $tutorialTitle"

    foo="${tutorialName:9}"

    tutorialLongTitle="${tutorialName:0:8}${foo^}"
    chrlen=${#tutorialTitle}
    underline=`printf '=%.0s' $(seq 1 $chrlen);`

    sed 's#<html><head>#&<script type="text/javascript" src="../js/iframeResizer.contentWindow.min.js"></script>#' "$tutorialPath/$tutorialDir/$tutorialName.html" > "$tutorialDestination/$tutorialName.html"
    sed "s/#tutorialLongTitle#/$tutorialLongTitle/" "$rstDestination/template.rst" > "$rstDestination/$tutorialLongTitle.rst"
    sed -i.bak "s/#tutorialTitle#/$tutorialTitle/" "$rstDestination/$tutorialLongTitle.rst"
    sed -i.bak "s/#underline#/$underline/" "$rstDestination/$tutorialLongTitle.rst"
    sed -i.bak "s/#tutorialName#/$tutorialName.html/" "$rstDestination/$tutorialLongTitle.rst"
    rm "$rstDestination/$tutorialLongTitle.rst.bak"

    echo "   $tutorialLongTitle" >> $rstDestination/index.rst
done

if [[ ${HOME} = *"jenkins"* ]]; then
    # Removing files on develop branch
    echo "Removing html tutorial files"
    nRemovedFiles=0
    for tutorial in "${tutorials[@]}"
    do
        tutorialDir=${tutorial%/*}
        tutorialName=${tutorial##*/}
        tutorialName="${tutorialName%.*}"
        if [[ -f "$tutorialPath/$tutorialDir/$tutorialName.html" ]]; then
            git rm "$tutorialPath/$tutorialDir/$tutorialName.html"
            let "nRemovedFiles+=1"
        fi
    done

    if [ $nRemovedFiles -ne 0 ]; then
        git commit -m "removing html files from tutorial folder."
    fi
else
    echo "skipping cleaning of the html files on the tutorial folder."
fi
