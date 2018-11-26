#!/bin/bash
my_dir=`dirname $0`
urlBase="http://127.0.0.1:2202/ubooquity/" #Path to Ubooquity (ie. "http://yourdomain.whatever/ubooquity/")
cookie="c2Nvb3RlciM3MjAwMzMwNjgxNjc0NjU2Mzc2" #I personally used Cookie Inspector for Chrome
serverURL=$1
searchval=$2
itemsPerPage=48
maxPages=20

function urldecode(){
    echo -e "$(sed 's/+/ /g; s/%/\\x/g')"
}

function getIDs(){
    pageNum=$1
    pageIndex=`expr $pageNum \* $itemsPerPage`
    jsonConvert=`curl -s -L --cookie "UbooquitySession=$cookie" --insecure $urlBase$serverURL"?index="$pageIndex | $my_dir/pup '.cell json{}'`
    if [ "$jsonConvert" = "[]" ]; then
        echo ""
        exit 1
    fi
    hrefs=`echo $jsonConvert | $my_dir/jq '.[].children[].children[0].href | select(length > 0)'`
    onclicks=`echo $jsonConvert | $my_dir/jq '.[].children[].children[0].onclick | select(length > 0)'| sed s/"\&#39;"/"'"/g`
    pageIDs=`printf "$hrefs" | cut -d \/ -f 4`
    rawfilenames=`echo $jsonConvert | jq '.[].children[].children[0].children[0].src | select(length > 0)'`
    filenames=`echo $jsonConvert | jq '.[].children[].children[0].children[0].src | select(length > 0)' | tr -d '"' | cut -d \/ -f 5 | rev | cut -c12- | rev | urldecode`
    issueTest=`echo "$pageIDs" | sed -n "1p"`
    pageLabels=`echo $jsonConvert | $my_dir/jq .[].children[1].text`
    if [[ $issueTest != *"#"* ]]; then
        resultArray=`paste -d',' <(printf "${pageLabels}") <(printf "$pageIDs")`
        index=`printf "$resultArray" | grep -n -ow "\"${searchval}\""`
    else
        cellDataArray=`paste -d',' <(printf "${hrefs}") <(printf "${onclicks}") <(echo "${rawfilenames}") <(printf "${pageLabels}")`
        resultArray=`paste -d',' <(printf "${pageLabels}") <(printf "$filenames")`
        searchval="${searchval// /.*}"
        index=`printf "$resultArray" | grep -n -o "${searchval}"`
    fi
    if [ ! -z "$index" ]; then
        index=`printf "$index" | sed -n "1p" | cut -d ":" -f1`
        if [[ $issueTest != *"#"* ]]; then
            printf "$resultArray" | sed -n "${index}p" | sed 's@.*,@@'
        else
            echo "$cellDataArray" | sed -n "${index}p"
        fi
    else
        let pageNum=pageNum+1 
        if [ "$pageNum" -le "$maxPages" ]; then
            getIDs $pageNum
        else
            echo "0"
        fi
    fi
}

getIDs 0