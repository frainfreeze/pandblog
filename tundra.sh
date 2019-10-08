#!/bin/sh
# tundra.sh v0.5

########## Configuration ###########
AUTHOR="frainfreeze"
BLOG_TITLE="frainfreeze's example blog for tundra.sh"

#              paths (edit me!)
# $_PATH points to folder with $ source files
# $_RES points to theme in res folder for $
# $PAGES contains names of files that will be built into
# standalone pages and linked into navbar
ROOT=`pwd`
INDEX_PATH=$ROOT/README.md
INDEX_RES=$ROOT/res/basic

POSTS_PATH=$ROOT/posts
POSTS_RES=$ROOT/res/bootstrap

DOCS_PATH=$ROOT/docs
DOCS_RES=$ROOT/res/bootstrap

PAGES_PATH=$ROOT/pages
PAGES_RES=$ROOT/res/basic

#               misc
# MD_FLAVOUR tells pandoc what markdown flavour to use,
# +yaml_met... turns on yaml meta data option in pandoc
MD_FLAVOUR="markdown_github+yaml_metadata_block"


######### Implementation ##########
usage() {
    echo "Static site generator using pandoc."
    echo "./tundra.sh"
    echo "   -h --help \tDisplays this page."
    echo "   -b --build \tGenerates HTML from the sources."
    echo "   -c --clean \tDeletes HTML files"
    echo ""
}

gen_archive(){
    echo "Generating archive"
    cd $POSTS_PATH
    cat $ROOT/res/basic/blog-index.Thtml > index.html
    echo "<input class=\"button-shadow\" type=\"button\" id=\"test\" value=\"sort by date\"/>" >> index.html
    echo "<input class=\"button-shadow\" type=\"button\" id=\"test1\" value=\"sort by title\"/>" >> index.html
    echo "<ul id=\"list\">" >> index.html

    for url in *.html; do
        if [ "$url" != "index.html" ]
        then
            title=`awk -vRS="</title>" '/<title>/{gsub(/.*<title>|\n+/,"");print;exit}' $url`
            date=`awk -vRS="</p></li>" '/<li><p class="navbar-text date">/{gsub(/.*<li><p class="navbar-text date">|\n+/,"");print;exit}' $url`
            echo "<li><span class=\"date\">$date</span> - <a href=\"$url\"><span class="post-title">$title</span></a></li>" >> index.html
        fi
    done

    echo "</ul></body></html>" >> index.html
    sed -i "s/blog-title/$BLOG_TITLE/g" index.html

    cd $ROOT
}

build_sources() {
    echo "Building sources..."
    START_TIME=$(date +%s)
    
    # build index
    if [ ! -z ${INDEX_PATH+x} ]; 
    then
        echo "\tBuilding index"
        pandoc -f $MD_FLAVOUR $INDEX_PATH -o "index.html" --template $INDEX_RES/index.Thtml --css $INDEX_RES/style.css #--toc
    fi

    # build blog
    if [ ! -z ${POSTS_PATH+x} ]; 
    then
        echo "\tBuilding blog"
        
        cd $POSTS_PATH
        
        for f in *.md; do 
            pandoc -f $MD_FLAVOUR "$f" -s -o "${f%.*}.html" --template $POSTS_RES/blog.Thtml --css $POSTS_RES/style.css --toc --toc-depth 3; 
        done
        
        cd $ROOT
        gen_archive
    fi

    # build static pages
    if [ ! -z ${PAGES_PATH+x} ]; 
    then
        echo "\tBuilding static pages"
        cd $PAGES_PATH
        for page in *.md;
        do
            pandoc -f $MD_FLAVOUR $page -o "${page%.*}.html" --template $INDEX_RES/index.Thtml --css $INDEX_RES/style.css
        done
        cd $ROOT
    fi

    # build docs
    if [ ! -z ${DOCS_PATH+x} ]; 
    then
        echo "\tBuilding docs"
        cd $DOCS_PATH
        for page in *.md;
        do
            pandoc -f $MD_FLAVOUR $page -o "${page%.*}.html" --template $INDEX_RES/index.Thtml --css $INDEX_RES/style.css
        done
        cd $ROOT
    fi

    END_TIME=$(($(date +%s) - $START_TIME))
    echo "Sources built in $(($END_TIME/60)) min $(($END_TIME%60)) sec" 
}

if [ -z "$1" ] 
then
  usage
  exit 1
fi

while [ "$1" != "" ]; do
    PARAM=`echo $1 | awk -F= '{print $1}'`
    VALUE=`echo $1 | awk -F= '{print $2}'`
    case $PARAM in
        -h | --help)
            usage
            exit 0
            ;;
        -b | --build)
            build_sources
            exit 0
            ;;
        -c | --clean)
            find . -type f -iname "*.html" -delete
            echo "Deleted all html files!"
            exit 0
            ;;
        *)
            echo "ERROR: unknown parameter \"$PARAM\""
            usage
            exit 1
            ;;
    esac
    shift
done

##### notes
# pandoc index.md -s | lynx -stdin
# find * -name "*.md" -type f -exec sh -c 'pandoc "${0}" -o "${0%.md}.html" --template res/basic.Thtml --css res/basic.css --self-contained --toc --toc-depth 3' {} \;