#!/bin/bash
my_dir=`dirname $0`
apikey="" #put your comicvine key here
coverDownload=true #scrapes Comixology for thumbnail
coverCreate=false #imageMagick must be installed for this to work

if [ -z "$apikey" ]; then
    echo "No Comicvine API key entered."
    exit 1
else
    if ([[ $1 == *"cvinfo" ]] && [[ -f "$1" ]]) || ([[ $1 == *"CVInfo" ]] && [[ -f "$1" ]]); then
        if [ ! -f "$(dirname "$1")/folder-info.html" ] || [ ! -f "$(dirname "$1")/folder.jpg" ]; then
            urlInput=`cat "$1"`
            if [ -z "$urlInput" ]; then
                echo Missing URL in cvinfo file
                exit 1
            fi
            IFS='/' read -a url <<< "$urlInput"
            echo "Downloading comic data"
            rawDesc=`curl -s "http://comicvine.gamespot.com/api/issues/?api_key="$apikey"&field_list=description&format=json&filter=issue_number:1,volume:"${url[4]##*-} | $my_dir/jq '.results[0].description'`
            description=`echo "${rawDesc#\"}" | awk -F'<h4>List of covers' '{print $1}' | sed -e 's/<[^>]*>//g' -e 's/"$//' -e 's/[”“]/\"/g' | sed 's/[\]//g'`
            pubinfo=`curl -s "http://comicvine.gamespot.com/api/volume/"4050-${url[4]##*-}"/?api_key="$apikey"&field_list=name,start_year,publisher,image&format=json"`
            coverurl=`echo "$pubinfo" | $my_dir/jq .results.image.medium_url | tr -d '"'`
            name=`echo "$pubinfo" | $my_dir/jq .results.name | tr -d '"'`
            publisher=`echo "$pubinfo" | $my_dir/jq .results.publisher.name | tr -d '"'`
            start_year=`echo "$pubinfo" | $my_dir/jq .results.start_year | tr -d '"'`
            if [ ! -f "$(dirname "$1")/folder-info.html" ]; then
                echo "Building comic page"
                cat $my_dir/PageTemplate/Template.html > $my_dir/temp/${url[4]##*-}.html
                systemCheck=`uname -s`
                if [[[ $systemCheck == *"Darwin"* ]||[ $systemCheck == *"FreeBSD"* ]]]; then
                    sed -i '' 's~\*\*PUBLISHER\*\*~'"${publisher//&/\\&}"'~' $my_dir/temp/${url[4]##*-}.html
                    sed -i '' 's~\*\*NAME\*\*~'"${name//&/\\&} ($start_year)"'~' $my_dir/temp/${url[4]##*-}.html
                    sed -i '' 's~\*\*DESCRIPTION\*\*~'"${description//&/\\&}"'~' $my_dir/temp/${url[4]##*-}.html
                else
                    sed -i 's~\*\*PUBLISHER\*\*~'"${publisher//&/\\&}"'~' $my_dir/temp/${url[4]##*-}.html
                    sed -i 's~\*\*NAME\*\*~'"${name//&/\\&} ($start_year)"'~' $my_dir/temp/${url[4]##*-}.html
                    sed -i 's~\*\*DESCRIPTION\*\*~'"${description//&/\\&}"'~' $my_dir/temp/${url[4]##*-}.html
                fi
                mv $my_dir/temp/${url[4]##*-}.html "$(dirname "$1")/folder-info.html"
                cp $my_dir/PageTemplate/folder.css "$(dirname "$1")/"
            else
                echo "folder-info.html already exists, skipping"
            fi
            if [ ! -f "$(dirname "$1")/folder.jpg" ]; then
                if $coverDownload; then
                    $my_dir/imageGet.sh -c "$name" -d "$start_year"
                    name="${name//:/}"
                    name="${name////-}"  
                    if [ -f "$my_dir/$name $start_year.jpg" ]; then
                        mv "$my_dir/$name $start_year.jpg" "$(dirname "$1")/folder.jpg"
                        echo "Done!"
                    fi
                    if [ -f "$my_dir/$name.jpg" ]; then
                        mv "$my_dir/$name.jpg" "$(dirname "$1")/folder.jpg"
                        echo "Done!"
                    fi
                fi
                if $coverCreate; then
                    if [ ! -f "$(dirname "$1")/folder.jpg" ]; then
                        if [ ! -f "$(dirname "$1")/cover.jpg" ]; then
                            echo "File cover.jpg not found. Downloading from comicvine."
                            curl -# -o "$(dirname "$1")/cover.jpg" $coverurl
                        fi
                        if [ -f "$(dirname "$1")/cover.jpg" ]; then
                            echo "Manually creating thumbnail "$(dirname "$1")/folder.jpg""
                            convert "$(dirname "$1")/cover.jpg" -resize 640 "$(dirname "$1")/folder.jpg"
                            mogrify -gravity north -extent 640x640 "$(dirname "$1")/folder.jpg"
                            echo "Done!"
                        else
                            echo "No cover.jpg found. Maybe try manually adding one and trying again."
                        fi
                    fi
                fi
            else
                echo "folder.jpg already exists, skipping"
            fi
        else
            echo "folder-info.html and folder.jpg already exist"
        fi
    else
        echo "No cvinfo file found"
    fi
fi