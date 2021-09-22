#!/usr/bin/env bash
set -e

FONTS_GENERATION="false"
find /var/www/$COMPANY_NAME/documentserver/core-fonts/ -type f \( -name "*.ttf" -o -name "*.otf" \) | rev | sed 's!/.*!!' | rev > /var/www/$COMPANY_NAME/documentserver/core-fonts/current_fonts
if [ ! -f /var/www/$COMPANY_NAME/documentserver/core-fonts/generated_fonts ] || [ -n "$(diff /var/www/$COMPANY_NAME/documentserver/core-fonts/current_fonts /var/www/$COMPANY_NAME/documentserver/core-fonts/generated_fonts)" ]; then 
	bash /usr/bin/documentserver-generate-allfonts.sh true 
	FONTS_GENERATION="true"
fi
mv -f /var/www/$COMPANY_NAME/documentserver/core-fonts/current_fonts /var/www/$COMPANY_NAME/documentserver/core-fonts/generated_fonts
