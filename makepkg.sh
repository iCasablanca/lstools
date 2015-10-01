#!/bin/sh
# Make release package
# $Id$

VERSION="0.4.0"
PACKAGE="blstools"

# Create package
DIR=release
PKG="${PACKAGE}-${VERSION}"
mkdir $DIR 2> /dev/null
svn export --force . $DIR/$PKG
rm -rf $DIR/$PKG/release
rm $DIR/$PKG/makepkg.sh 
echo "$VERSION" > $DIR/$PKG/VERSION
cd $DIR
rm $PKG.tar.gz 2> /dev/null
tar zcf $PKG.tar.gz $PKG
rm -rf $PKG

echo "Package $PKG created in directory $DIR"

# Done

