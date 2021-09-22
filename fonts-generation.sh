#!/usr/bin/env bash
set -e

FONTS_DIR="/var/www/$COMPANY_NAME/documentserver/core-fonts"
FONTS_GENERATION="false"

find $FONTS_DIR -type f \
\( -name "*.ttf" -o -name "*.otf" -o -name "*.ttc" \) | rev | sed 's!/.*!!' | rev \
> $FONTS_DIR/current_fonts

if [ ! -f $FONTS_DIR/generated_fonts ] || [ -n "$(diff $FONTS_DIR/current_fonts $FONTS_DIR/generated_fonts)" ]; then 
	bash /usr/bin/documentserver-generate-allfonts.sh true 
	FONTS_GENERATION="true"
fi
mv -f $FONTS_DIR/current_fonts $FONTS_DIR/generated_fonts
