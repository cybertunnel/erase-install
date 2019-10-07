#!/bin/bash

#  ValidatePackage.sh
#  Shredder
#
#  Created by Arnold Nefkens on 10/01/2019.
#  Copyright © 2019 Pro Warehouse. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

export PATH=/usr/bin:/bin:/usr/sbin:/sbin

# tests a pkg file if it is a product archive
# i.e. a Distribution pkg with a product key in the xml

filepath=${1:?"no file argument"}

# first, check for .pkg extension
if [[ $filepath != *.pkg ]]; then
echo "file has no pkg extension"
exit 2
fi

# then, extract Distribution XML
distributionxml=$(tar -xOf "$filepath" Distribution 2>/dev/null )
if [[ $? != 0 ]]; then
echo "couldn't extract Distribution xml, this might not be a distribution pkg"
exit 3
fi

# get identifier out of distribution XML
identifier=$(xmllint --xpath "string(//installer-gui-script/product/@id)" - <<<${distributionxml})
if [[ $? != 0 ]]; then
echo "couldn't get product identifier"
exit 4
fi

# get version out of distribution XML
version=$(xmllint --xpath "string(//installer-gui-script/product/@version)" - <<<${distributionxml})
if [[ $? != 0 ]]; then
echo "couldn't get product version"
exit 5
fi

echo "Product Archive, identifier: ${identifier}, version: ${version}"
exit 0
