# removes all files and directories except uploads/
echo "moving into /var/www/html/ . . ."
cd /var/www/html/
echo " "
echo "before clean-up:"
ls
rm -rf assets preview stylesheets *.css *.html *.ini *.md *.php *.sh
echo " "
echo "after clean-up:"
ls
