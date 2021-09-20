echo $(find /var/www/$COMPANY_NAME/documentserver/core-fonts/ -type f \( -name "*.ttf" -o -name "*.otf" \) | rev | sed 's!/.*!!' | rev) > /var/www/$COMPANY_NAME/documentserver/core-fonts/current_fonts 
if [ ! -f /var/www/$COMPANY_NAME/documentserver/core-fonts/generated_fonts ] || [ -n "$(diff /var/www/$COMPANY_NAME/documentserver/core-fonts/current_fonts /var/www/$COMPANY_NAME/documentserver/core-fonts/generated_fonts)" ]; then 
	bash /usr/bin/documentserver-generate-allfonts.sh true 
fi
mv -f /var/www/$COMPANY_NAME/documentserver/core-fonts/current_fonts /var/www/$COMPANY_NAME/documentserver/core-fonts/generated_fonts
