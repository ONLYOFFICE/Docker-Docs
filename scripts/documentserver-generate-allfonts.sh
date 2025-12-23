#!/bin/sh

DIR="/var/www/onlyoffice/documentserver"

export LD_LIBRARY_PATH=/var/www/onlyoffice/documentserver/server/FileConverter/bin:$LD_LIBRARY_PATH

#Start generate AllFonts.js, font thumbnails and font_selection.bin
echo -n Generating AllFonts.js, please wait...


"$DIR/server/tools/allfontsgen"\
  --input="$DIR/core-fonts"\
  --allfonts-web="$DIR/sdkjs/common/AllFonts.js"\
  --allfonts="$DIR/server/FileConverter/bin/AllFonts.js"\
  --images="$DIR/sdkjs/common/Images"\
  --selection="$DIR/server/FileConverter/bin/font_selection.bin"\
  --output-web="$DIR/fonts"\
  --use-system="true"\
  --use-system-user-fonts="false"

echo Done

echo -n Generating presentation themes, please wait...
"$DIR/server/tools/allthemesgen"\
  --converter-dir="$DIR/server/FileConverter/bin"\
  --src="$DIR/sdkjs/slide/themes"\
  --output="$DIR/sdkjs/common/Images"

"$DIR/server/tools/allthemesgen"\
  --converter-dir="$DIR/server/FileConverter/bin"\
  --src="$DIR/sdkjs/slide/themes"\
  --output="$DIR/sdkjs/common/Images"\
  --postfix="ios"\
  --params="280,224"

"$DIR/server/tools/allthemesgen"\
  --converter-dir="$DIR/server/FileConverter/bin"\
  --src="$DIR/sdkjs/slide/themes"\
  --output="$DIR/sdkjs/common/Images"\
  --postfix="android"\
  --params="280,224"

echo Done

echo -n Generating js caches, please wait...
"$DIR/server/FileConverter/bin/x2t" -create-js-cache

echo Done

echo -n Remove gzipped files...
rm -f \
  $DIR/fonts/*.gz \
  $DIR/sdkjs/common/AllFonts.js.gz \
  $DIR/sdkjs/common/Images/*.gz \
  $DIR/sdkjs/slide/themes/themes.js.gz

echo "Fonts build is complete"
