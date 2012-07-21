#!/bin/bash
# used to upload the latest DreamCatcher to the web

echo +++ Packaging and uploading binary distribution

here=`pwd`
cd build/release/
mkdir DreamCatcher
cp -r DreamCatcher.app DreamCatcher/
cp ../../gpl.txt DreamCatcher/
zip -r DreamCatcher.zip DreamCatcher
cp DreamCatcher.zip /Volumes/jameshoward/Public/
rm -r DreamCatcher DreamCatcher.zip

# create the source distribution
echo +++ Packaging and uploading source distribution

cd "$here"
cd ..
cp -r DreamCatcher /tmp/
cd /tmp/DreamCatcher
find . -type d | grep '.svn' | xargs rm -rf
rm -rf build
rm -rf libwww
./prepend.sh gpl_header.txt *.m *.h
cd ..
zip -r DreamCatcherSrc.zip DreamCatcher/
cp DreamCatcherSrc.zip /Volumes/jameshoward/Public/
rm -r DreamCatcher DreamCatcherSrc.zip

