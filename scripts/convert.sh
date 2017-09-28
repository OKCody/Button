# $1 = path to unique session directory
# $2 = path to selected stylesheet
# $3 = html extension, lowercase because that's what's typically used for extensions
# $4 = pdf extension
# $5 = epub3 extension
# $6 = docx extension
# $7 = stand-alone option

# Move into unique directory created for a given session
cd $1
echo "PID: $$" > debug.txt
echo $1 >> debug.txt
echo $2 >> debug.txt
echo $3 >> debug.txt
echo $4 >> debug.txt
echo $5 >> debug.txt
echo $6 >> debug.txt
echo $7 >> debug.txt


# If a .zip file is present in unique directory, unzip it. Otherwise move on
#   to conversion.
if [ -e *.zip ]
then
  archive="$(ls *.zip)"
  unzip $archive
  dir="${archive%.zip}"
  echo "$(pwd)" >> debug.txt
  echo $archive >> debug.txt
  echo $dir >> debug.txt

  echo "__MACOSX ----" >> debug.txt
  echo "$(ls __MACOSX)" >> debug.txt
  rm -rf __MACOSX

  echo "dir/.* ----" >> debug.txt
  echo "$(ls $dir/.*)" >> debug.txt
  rm -rf $dir/.*

  echo "dir/* ----" >> debug.txt
  echo "$(ls $dir/*)" >> debug.txt
  mv $dir/* .

  echo "ls before----" >> debug.txt
  echo "$(ls)" >> debug.txt
  echo "----" >> debug.txt

  rm -rf $dir
  rm -rf $archive

  echo "ls after----" >> debug.txt
  echo "$(ls)" >> debug.txt
  echo "----" >> debug.txt
fi


# If an example stylesheet has been selected, remove all styleshees in favor of that which is selected.
#echo $2 >> debug.txt
#echo "'"$(ls *.css)"'" >> debug.txt
if [ $2 == "custom" ] && [ "$(ls *.css)" == "" ];
then
  #echo "Not using example, no custom style provided" >> debug.txt                 # Working
  example="0"
  custom="0"
  stylesheet=""
  persistentStylesheet=$stylesheet
fi
if [ $2 == "custom" ] && [ "$(ls *.css)" != "" ];
then
  #echo "Not using example, custom style provided" >> debug.txt                    # Working
  example="0"
  custom="1"
  stylesheet=$(ls *.css | head -1)
  persistentStylesheet=$stylesheet
fi
if [ $2 != "custom" ] && [ "$(ls *.css)" != "" ];
then
  #echo "Using example, custom style provided" >> debug.txt                         # Working
  example="1"
  custom="1"
  rm *.css    # Override provided stylesheet in favor of example stylesheet
  cp ../../$2 stylesheet.css
  stylesheet=$(ls *.css | head -1)
  persistentStylesheet=$stylesheet
fi
if [ $2 != "custom" ] && [ "$(ls *.css)" == "" ];  # If something other than default state is selected, do this . . .
then
  #echo "Using Example, no custom style provided" >> debug.txt                     # Working
  example="1"
  custom="0"
  rm *.css    # If an example stylesheet has been selected, remove all uploaded stylesheets
  cp ../../$2 stylesheet.css
  stylesheet=$(ls *.css | head -1)
  persistentStylesheet=$stylesheet
fi

# Repeat conversion for each of the selected output formats passed in on variables $3 - $5.
for output in $3 $4 $5 $6
do
  # Convert all .md files found in directory $1.
  # Apply only the first .css file returned by ls. Pandoc only allows 1 .css
  #   file. Others will be ignored.
  # User should condense multiple stylesheets into one as a programatic approach
  #   would willy nilly overwrite CSS attributes.
  for filename in *.md
  do
    filename=$(echo $filename | cut -f 1 -d '.')

    # HTML conversion                                                           # Working 1/8/17 1:30pm
    stylesheet=$persistentStylesheet
    if [ $output == "html" ];
    then
        if [ $example == "0" ] && [ $custom == "0" ];
        then
            #echo "HTML Not using example, no custom style provided" >> debug.txt      # Working
            stylesheet=""                                                            # Working
        fi
        if [ $example == "0" ] && [ $custom == "1" ];
        then
            #echo "HTML Not using example, custom style provided" >> debug.txt         # Working
            stylesheet="-c $stylesheet"                                              # Working
        fi
        if [ $example == "1" ] && [ $custom == "0" ];
        then
            #echo "HTML Using Example, no custom style provided" >> debug.txt          # Working
            stylesheet="-c $stylesheet"                                              # Working
        fi
        if [ $example == "1" ] && [ $custom == "1" ];
        then
            #echo "HTML Using example, custom style provided" >> debug.txt             # Working
            stylesheet="-c $stylesheet"                                              # Working
        fi
        echo "HTML Conversion ----------------------" >> debug.txt
        #echo $stylesheet >> debug.txt

        if [ $7 == "null" ];
        then
            # if not creating stand-alone pages, go ahead and use custom stylesheet
            #   if provided
            pandoc $filename.md -f markdown $stylesheet --mathjax -s -o $filename.html 2>>debug.txt
        else
            # if creating stand-alone pages, ignore all stylesheets. These should
            # be provided in the provided header
            pandoc $filename.md -f markdown -o $filename.html 2>>debug.txt
        fi
    fi
    # end HTML conversion ---------------------



    # PDF conversion                                                            #   Working 1/8/17 10:27pm
    stylesheet=$persistentStylesheet
    if [ $output == "pdf" ];
    then
        if [ $example == "0" ] && [ $custom == "0" ];
        then
            #echo "PDF Not using example, no custom style provided" >> debug.txt      # Working
            stylesheet=""                                                           # Working
        fi
        if [ $example == "0" ] && [ $custom == "1" ];
        then
            #echo "PDF Not using example, custom style provided" >> debug.txt         # Working
            stylesheet="-c $stylesheet"                                             # Working, problem with font. Maybe font needs to be embedded? test condition: skeleton.css
        fi
        if [ $example == "1" ] && [ $custom == "0" ];
        then
            #echo "PDF Using Example, no custom style provided" >> debug.txt          # Working
            stylesheet="-c $stylesheet"                                             # Working
        fi
        if [ $example == "1" ] && [ $custom == "1" ];
        then
            #echo "PDF Using example, custom style provided" >> debug.txt             # Working
            stylesheet="-c $stylesheet"                                             # Working
        fi
        echo "temp HTML Conversion -----------------" >> debug.txt
        #echo $stylesheet >> debug.txt

        pandoc $filename.md -f markdown $stylesheet --mathjax -s -o temp.html 2>>debug.txt
        # --run-script removes letter-spacing from the most common text tags.
        # WKHTMLTOPDF has a known error that causes anything other than
        # letter-spacing of 0px to be extremely exaggerated. This script sets
        # letter-spacing to 0px for most common text tags.
        if [ $OSTYPE == "linux-gnu" ];
        then
          echo "PDF Conversion -----------------------" >> debug.txt
          xvfb-run -a wkhtmltopdf --quiet --javascript-delay 1000 --user-style-sheet ../../print.css --run-script 'var elements = document.querySelectorAll("html,body,h1,h2,h3,h4,h5,h6,p,li,ol,pre,b,i,code,q,s"); for(var i = 0; i < elements.length; i++) { elements[i].style.letterSpacing = "0px"; }' temp.html $filename.pdf 2>>debug.txt
        else
          echo "PDF Conversion -----------------------" >> debug.txt
          wkhtmltopdf --quiet --javascript-delay 1000 --user-style-sheet ../../print.css --run-script 'var elements = document.querySelectorAll("html,body,h1,h2,h3,h4,h5,h6,p,li,ol,pre,b,i,code,q,s"); for(var i = 0; i < elements.length; i++) { elements[i].style.letterSpacing = "0px"; }' temp.html $filename.pdf 2>>debug.txt
        fi
        rm temp.html
    fi
    # end HTML conversion ---------------------

    # EPUB conversion                                                            # Working 1/8/17 11:25pm
    stylesheet=$persistentStylesheet
    if [ $output == "epub3" ];
    then
        if [ $example == "0" ] && [ $custom == "0" ];
        then
            #echo "EPUB Not using example, no custom style provided" >> debug.txt      # Working
            stylesheet=""                                                            # Working
        fi
        if [ $example == "0" ] && [ $custom == "1" ];
        then
            #echo "EPUB Not using example, custom style provided" >> debug.txt         # Working
            stylesheet="--epub-stylesheet $stylesheet"                               # Working
        fi
        if [ $example == "1" ] && [ $custom == "0" ];
        then
            #echo "EPUB Using Example, no custom style provided" >> debug.txt          # Working
            stylesheet="--epub-stylesheet $stylesheet"                               # Working
        fi
        if [ $example == "1" ] && [ $custom == "1" ];
        then
            #echo "EPUB Using example, custom style provided" >> debug.txt             # Working
            stylesheet="--epub-stylesheet $stylesheet"                               # Working
        fi
        echo "EPUB Conversion ----------------------" >> debug.txt
        #echo $stylesheet >> debug.txt
        pandoc $filename.md -f markdown -t epub3 $stylesheet -o $filename.epub 2>>debug.txt
    fi
    # end EPUB conversion ---------------------

    # DOCX conversion                                                            # Working 1/8/17 11:38pm
    if [ $output == "docx" ];
    then
        echo "DOCX Conversion ----------------------" >> debug.txt
        pandoc $filename.md -f markdown -o $filename.docx 2>>debug.txt                        # Working
    fi
    # end EPUB conversion ---------------------

  done
done

# stand-alone generation ---------------------
if [ $7 == "stand-alone" ];
then
    echo "Stand-Alone Generation ----------------------" >> debug.txt

    if [ -a head.html ];
    then
        echo "head.html found!" >> debug.txt
    else
        echo "head.html not found!  If you'd like to indlude a header, add a file named tail.html containing the header's contents" >> debug.txt
    fi
    if [ -a tail.html ];
    then
        echo "tail.html found!" >> debug.txt
    else
        echo "tail.html not found!  If you'd like to indlude a footer, add a file named tail.html containing the footer's contents" >> debug.txt
    fi

    mkdir stand-alone/

    for html_file in *.html
    do
      if [ $html_file == "head.html" ] || [ $html_file == "tail.html" ];
      then
          : # do nothing
      else
          cat head.html $html_file tail.html > stand-alone/$html_file
          rm $html_file
      fi
    done
fi
# end stand-alone generation ---------------------

# zip all files in working directory into an archive excluding any .zip files
zip -r converted.zip * -x *.zip
