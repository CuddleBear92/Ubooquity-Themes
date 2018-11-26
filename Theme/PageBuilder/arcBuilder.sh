#!/bin/bash
my_dir=`dirname $0`
arc_dir='/mnt/user/Comics/__Story Arcs/'
apikey="" #put your comicvine key here
coverDownload=true #scrapes Comixology for thumbnail
coverCreate=false #imageMagick must be installed for this to work

if [ -z "$apikey" ]; then
    echo "No Comicvine API key entered."
    exit 1
else
    webquery="$@"
    [ -z "$webquery" ] && exit 1  # insufficient arguments
    webquery="${webquery//&/%26}"
    webquery="${webquery//:/%3A}"
    webquery="${webquery// /%20}"  
    webquery="${webquery//+/%2B}"  
    webquery="${webquery////%2F}"  
    getInitial=`curl -s "http://comicvine.gamespot.com/api/story_arcs/?api_key="$apikey"&format=json&field_list=id,name,deck,publisher,image&filter=name:"${webquery}`
    getID=`echo $getInitial | $my_dir/jq '.results[0].id'`
    description=`echo $getInitial | $my_dir/jq '.results[0].deck' | tr -d '"'`
    arcName=`echo $getInitial | $my_dir/jq '.results[0].name' | tr -d '"'`
    coverurl=`echo "$getInitial" | $my_dir/jq .results[0].image.medium_url | tr -d '"'`
    dirName="${arcName//:/}"
    dirName="${dirName////-}"  
    dirName="${arc_dir}${dirName}"
    publisher=`echo $getInitial | $my_dir/jq '.results[0].publisher.name' | tr -d '"'`
    echo Publisher:$publisher
    publisherUID=$(idGet.sh "comics/" "$publisher")
    if [ -z "$publisherUID" ]; then
        echo "idGet failed, probably using an invalid cookie"
        exit 1
    fi
    echo $publisherUID
    echo Story Arc ID:$getID
    if [ ! -d "${dirName}/" ]; then
        mkdir -p "${dirName}/"
    fi
    if [ ! -f "${dirName}/folder-info.html" ]; then
        echo "Building comic page"
        cat $my_dir/ArcTemplate/Template.html > $my_dir/temp/${getID}.html
        systemCheck=`uname -s`
        if [[ $systemCheck == *"Darwin"* ]||[ $systemCheck == *"FreeBSD"* ]]; then
            sed -i '' 's~\*\*NAME\*\*~'"${arcName//&/\\&}"'~' $my_dir/temp/${getID}.html
            sed -i '' 's~\*\*DESCRIPTION\*\*~'"${description//&/\\&}"'~' $my_dir/temp/${getID}.html
        else
            sed -i 's~\*\*NAME\*\*~'"${arcName//&/\\&}"'~' $my_dir/temp/${getID}.html
            sed -i 's~\*\*DESCRIPTION\*\*~'"${description//&/\\&}"'~' $my_dir/temp/${getID}.html
        fi
        mv $my_dir/temp/${getID}.html "${dirName}/folder-info.html"
        cp $my_dir/ArcTemplate/folder.css "${dirName}/"
    else
        echo "folder-info.html already exists, skipping"
    fi

    if [ ! -f "${dirName}/folder.jpg" ]; then
        if $coverDownload; then
            $my_dir/imageGet.sh -c "$arcName" -t "arc"
            arcName="${arcName//:/}"
            arcName="${arcName////-}"  
            if [ -f "$my_dir/$arcName.jpg" ]; then
                mv "$my_dir/$arcName.jpg" "${dirName}/folder.jpg"
                echo "Done!"
            fi
        fi
        if $coverCreate; then
            if [ ! -f "${dirName}/folder.jpg" ]; then
                if [ ! -f "${dirName}/cover.jpg" ]; then
                    echo "File cover.jpg not found. Downloading from comicvine."
                    curl -# -o "${dirName}/cover.jpg" $coverurl
                fi
                if [ -f "${dirName}/cover.jpg" ]; then
                    echo "Manually creating thumbnail "${dirName}/folder.jpg""
                    convert "${dirName}/cover.jpg" -resize 640 "${dirName}/folder.jpg"
                    mogrify -gravity north -extent 640x640 "${dirName}/folder.jpg"
                    echo "Done!"
                else
                    echo "No cover.jpg found. Maybe try manually adding one and trying again."
                fi
            fi
        fi
    else
        echo "folder.jpg already exists, skipping"
    fi
        
    if [ ! -f "${dirName}/arclist.csv" ]; then
        echo "Generating arclist"
        sleep 1
        getIssues=`curl -s "http://comicvine.gamespot.com/api/story_arc/"$getID"/?api_key="$apikey"&format=json&field_list=issues"`
        issueCount=`echo $getIssues  | $my_dir/jq '. .results.issues | length'`
        echo $issueCount issues
        getIssues=`echo $getIssues | $my_dir/jq '. .results.issues | .[].id'`
        if [ -f "$my_dir/temp/${getID}.csv" ]; then
            rm -f "$my_dir/temp/${getID}.csv"
        fi
        sleep 1
        COUNTER=1
        seriesID=""
        for in in $getIssues; do
            issueID=`echo $getIssues | cut -f $COUNTER -d " "`
            issueDetails=`curl -s "http://comicvine.gamespot.com/api/issue/4000-"$issueID"/?api_key="$apikey"&format=json&field_list=issue_number,volume,cover_date"`
            name=`echo $issueDetails | $my_dir/jq .results.volume.name | tr -d '"'`
            seriesIDtmp=`echo $issueDetails | $my_dir/jq .results.volume.id`
            if [ "$seriesID" != "$seriesIDtmp" ]; then
                seriesID=$seriesIDtmp
                sleep 1
                pubinfo=`curl -s "http://comicvine.gamespot.com/api/volume/"4050-${seriesID}"/?api_key="$apikey"&field_list=name,start_year&format=json"`
                seriesName=`echo "$pubinfo" | $my_dir/jq .results.name | tr -d '"'`
                seriesName="${seriesName//:/}"
                seriesName="${seriesName// - / }" 
                start_year=`echo "$pubinfo" | $my_dir/jq .results.start_year | tr -d '"'`
                fullSeriesName=`echo $seriesName" ("$start_year")"`
                seriesUID=$(idGet.sh "comics/$publisherUID/" "${fullSeriesName}")
                echo $fullSeriesName
                echo $seriesUID 
            fi
            issueNum=`echo $issueDetails | $my_dir/jq .results.issue_number | tr -d '"' | xargs printf %03d`
            coverDate=`echo $issueDetails | $my_dir/jq .results.cover_date | cut -f1 -d"-" | tr -d '"'`
            issueName=$name" "$issueNum" "$coverDate
            issueName="${issueName//:/}"
            issueName="${issueName// - / }" 
            issueString=$(idGet.sh "comics/$seriesUID/" "${issueName}")
            echo "$issueName"
            if [ ! -f "$my_dir/temp/${getID}.csv" ]; then
                echo $issueString > $my_dir/temp/${getID}.csv
            else
                if [ "$COUNTER" != "$issueCount" ]; then
                    echo $issueString >> $my_dir/temp/${getID}.csv
                else
                    echo -n $issueString >> $my_dir/temp/${getID}.csv 
                fi
            fi
            let COUNTER=COUNTER+1 
            sleep 1
        done
        mv $my_dir/temp/${getID}.csv "${dirName}/arclist.csv"
    else
        echo "arclist.csv already exists, skipping"
    fi
fi