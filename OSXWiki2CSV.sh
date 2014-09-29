#!/bin/bash

#-------------------------------------#
#          OS X Wiki to CSV           #
#-------------------------------------#
#                                     #
#    Export OSX Server wiki pages     #
#               to CSV                #
#                                     #
#             Yvan Godard             #
#        godardyvan@gmail.com         #
#                                     #
#  Version 1.0 -- september, 6 2014   #
#                                     #
# Tool licenced under the MIT License #
#  http://opensource.org/licenses/MIT #
#                                     #
#        http://goo.gl/Ow90DL         #
#                                     #
#-------------------------------------#

# Variables initialisation
VERSION="OSXWiki2CSV v 1.0 - 2014, Yvan Godard [godardyvan@gmail.com] - http://goo.gl/Ow90DL"
help="no"
SCRIPT_DIR=$(dirname $0)
SCRIPT_NAME=$(basename $0)
EMAIL_REPORT="nomail"
EMAIL_LEVEL=0
LOG="/var/log/OSXWiki2CSV.log"
LOG_TEMP=$(mktemp /tmp/OSXWiki2CSV.XXXXX)
LOG_ACTIVE=0
WIKI_FULL_PATH="/Library/Collaboration"
WS_URL_PREFIX=""
EXPORT_PATH_ROOT=""
KEEP_DAILY_NUMBER="6"
KEEP_WEEKLY_NUMBER="4"
ERROR_ON_KEEP_DAILY_NUMBER=0
ERROR_ON_KEEP_WEEKLY_NUMBER=0
OLD_KEEP_DAILY_NUMBER=${KEEP_DAILY_NUMBER}
OLD_KEEP_WEEKLY_NUMBER=${KEEP_WEEKLY_NUMBER}
DATANAME="OSXWikiServerExport-$(date +%d.%m.%y@%Hh%M)"
EXPORT_WITH_DATA="no"

function help () {
    echo -e "$VERSION\n"
    echo -e "This tool is designed to export OSX Server (10.6) wiki pages to CSV and backup data."
    echo -e "This tool must be run as root: use 'sudo'."
    echo -e "This tool is licensed under the MIT License (http://opensource.org/licenses/MIT)."
    echo -e "\nDisclamer:"
    echo -e "This tool is provide without any support and guarantee."
    echo -e "\nSynopsis:"
    echo -e "./${SCRIPT_NAME} [-h]"
    echo -e "                 -p <url prefix>"
    echo -e "                 -b <export path>"
    echo -e "                 [-f <path of collaboration files>]"
    echo -e "                 [-D <backup data>]"
    echo -e "                 [-d <number of daily exports>] [-w <number of weekly exports>]"
    echo -e "                 [-e <email report option>] [-E <email address>] [-j <log file>]"
    echo -e "\nMandatory options:"
    echo -e "\t-p <url prefix>:                   the prefix to append to generated links, without spaces,"
    echo -e "\t                                   (i.e.: 'http://my-server.example.com/groups/wiki/')."
    echo -e "\t-b <export path>:                  the full path of your backup directory (i.e.: '/Users/Shared/backupWikiServer')."
    echo -e "\nOptional options:"
    echo -e "\t-h:                                prints this help then exit."
    echo -e "\t-f <path of collaboration files>:  the full path of your OS X Server collaboration files,"
    echo -e "\t                                   default '${WIKI_FULL_PATH}'."
    echo -e "\t-D <backup data>:                  type '-D yes' if you want to include all the data in your export,"
    echo -e "\t                                   not only CSV exports or '-D no' if not. Default: '-D ${EXPORT_WITH_DATA}'."
    echo -e "\t-d <number of daily exports>:      number of daily exports to keep (default: $KEEP_DAILY_NUMBER)."
    echo -e "\t-w <number of weekly exports>:     number of weekly exports to keep (default: $KEEP_WEEKLY_NUMBER)."
    echo -e "\t-e <email report option>:          settings for sending a report by email, must be 'onerror', 'forcemail' or 'nomail',"
    echo -e "\t                                   default: '${EMAIL_REPORT}'."
    echo -e "\t-E <email address>:                email address to send the report, must be filled if '-e forcemail' or '-e onerror' options is used."
    echo -e "\t-j <log file>:                     enables logging instead of standard output. Specify an argument for the full path to the log file"
    echo -e "\t                                   (i.e.: '$LOG') or use 'default' ($LOG)."
    exit 0
}

function error () {
    echo -e "\n*** Error ***"
    echo -e ${1}
    echo -e "\n"${VERSION}
    alldone 1
}

function alldone () {
    # Redirect standard outpout
    exec 1>&6 6>&-
    # Logging if needed 
    [ $LOG_ACTIVE -eq 1 ] && cat $LOG_TEMP >> $LOG
    # Print current log to standard outpout
    [ $LOG_ACTIVE -ne 1 ] && cat $LOG_TEMP
    [ $EMAIL_LEVEL -ne 0 ] && [ $1 -ne 0 ] && cat $LOG_TEMP | mail -s "[ERROR] ${SCRIPT_NAME} on ${HOSTNAME}" ${EMAIL_ADDRESS}
    [ $EMAIL_LEVEL -eq 2 ] && [ $1 -eq 0 ] && cat $LOG_TEMP | mail -s "[OK] ${SCRIPT_NAME} on ${HOSTNAME}" ${EMAIL_ADDRESS}
    # Remove temp files/folder
    [ -f ${LOG_TEMP} ] && rm -R ${LOG_TEMP}
    exit ${1}
}

function testInteger () {
    [ $1 -eq 0 ] 2>/dev/null
    if [ $? -eq 0 -o $? -eq 1 ]; then 
        echo 1
    else
        echo 0
    fi
}

optsCount=0
while getopts "hp:b:f:d:w:e:E:j:D:" OPTION
do
    case "$OPTION" in
        h)  help="yes"
                        ;;
        p)  WS_URL_PREFIX="${OPTARG%/}/"
            let optsCount=$optsCount+1
                        ;;
        b)  EXPORT_PATH_ROOT=${OPTARG%/}
            let optsCount=$optsCount+1
                        ;;
        f)  WIKI_FULL_PATH=${OPTARG%/}
                        ;;
        d)  [[ $(testInteger ${OPTARG}) -eq 1 ]] && KEEP_DAILY_NUMBER=${OPTARG} && OLD_KEEP_DAILY_NUMBER=${OPTARG}
            [[ $(testInteger ${OPTARG}) -ne 1 ]] && ERROR_ON_KEEP_DAILY_NUMBER=1 && OLD_KEEP_DAILY_NUMBER=${OPTARG}
                        ;;
        w)  [[ $(testInteger ${OPTARG}) -eq 1 ]] && KEEP_WEEKLY_NUMBER=${OPTARG} && OLD_KEEP_WEEKLY_NUMBER=${OPTARG}
            [[ $(testInteger ${OPTARG}) -ne 1 ]] && ERROR_ON_KEEP_WEEKLY_NUMBER=1 && OLD_KEEP_WEEKLY_NUMBER=${OPTARG}
                        ;;
        D)  EXPORT_WITH_DATA=${OPTARG}
                        ;;
        e)  EMAIL_REPORT=${OPTARG}
                        ;;                             
        E)  EMAIL_ADDRESS=${OPTARG}
                        ;;
        j)  [ $OPTARG != "default" ] && LOG=${OPTARG}
            LOG_ACTIVE=1
                        ;;
    esac
done

# Run as root is mandatory
if [ `whoami` != 'root' ]; then
    echo "This tool must be run as root, use 'sudo'"
    exit 1
fi

# Verifiy mandatory option
if [[ ${optsCount} != "2" ]]; then
    help
    exit 1
fi

# Help
if [[ ${help} = "yes" ]]
    then
    help
fi

# Redirect standard outpout to temp file
exec 6>&1
exec >> ${LOG_TEMP}

umask 027

# Start temp log file
echo -e "\n****************************** `date` ******************************\n"
echo -e "$0 started with options:"
echo -e "\t-p ${WS_URL_PREFIX} (prefix to append to generated links)"
echo -e "\t-b ${EXPORT_PATH_ROOT} (full path of your backup directory)"
echo -e "\t-f ${WIKI_FULL_PATH} (full path of your OS X Server collaboration files)"
echo -e "\t-D ${EXPORT_WITH_DATA} (export with or without data)" 
echo -e "\t-d ${OLD_KEEP_DAILY_NUMBER} (number of daily exports to keep)"
echo -e "\t-w ${OLD_KEEP_WEEKLY_NUMBER} (number of monthly exports to keep)\n"

# Test of sending email parameter and check the consistency of the parameter email address
if [[ ${EMAIL_REPORT} = "forcemail" ]]; then
    EMAIL_LEVEL=2
    if [[ -z $EMAIL_ADDRESS ]]; then
        echo -e "You used option '-e ${EMAIL_REPORT}' but you have not entered any email info.\n\t> We continue the process without sending email."
        EMAIL_LEVEL=0
    else
        echo "${EMAIL_ADDRESS}" | grep '^[a-zA-Z0-9._-]*@[a-zA-Z0-9._-]*\.[a-zA-Z0-9._-]*$' > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            echo -e "This address '${EMAIL_ADDRESS}' does not seem valid.\n\t> We continue the process without sending email."
            EMAIL_LEVEL=0
        fi
    fi
elif [[ ${EMAIL_REPORT} = "onerror" ]]; then
    EMAIL_LEVEL=1
    if [[ -z $EMAIL_ADDRESS ]]; then
        echo -e "You used option '-e ${EMAIL_REPORT}' but you have not entered any email info.\n\t> We continue the process without sending email."
        EMAIL_LEVEL=0
    else
        echo "${EMAIL_ADDRESS}" | grep '^[a-zA-Z0-9._-]*@[a-zA-Z0-9._-]*\.[a-zA-Z0-9._-]*$' > /dev/null 2>&1
        if [ $? -ne 0 ]; then    
            echo -e "This address '${EMAIL_ADDRESS}' does not seem valid.\n\t> We continue the process without sending email."
            EMAIL_LEVEL=0
        fi
    fi
elif [[ ${EMAIL_REPORT} != "nomail" ]]; then
    echo -e "\nOption '-e ${EMAIL_REPORT}' is not valid (must be: 'onerror', 'forcemail' or 'nomail').\n\t> We continue the process without sending email."
    EMAIL_LEVEL=0
elif [[ ${EMAIL_REPORT} = "nomail" ]]; then
    EMAIL_LEVEL=0
fi

echo ""

# Test URL 
echo "${WS_URL_PREFIX}" | grep '^http[s]*://[a-zA-Z0-9./_-]*\.[a-zA-Z0-9./_-]*/$' > /dev/null 2>&1
[ $? -ne 0 ] && error "This URL '${WS_URL_PREFIX}' does not seem valid.\nPlease verify this paramter and retry.\n"

# Test EXPORT_PATH
if [[ ! -d ${EXPORT_PATH_ROOT} ]]; then
    mkdir -p ${EXPORT_PATH_ROOT}
    [ $? -ne 0 ] && error "Error when try to create '${EXPORT_PATH_ROOT}'.\n"
fi

# Test
[[ ! -d ${WIKI_FULL_PATH}/Groups ]] && error "Please verify paramter '-f ${WIKI_FULL_PATH}' because '${WIKI_FULL_PATH}/Groups' doesn't exist.\n"
[[ ! -d ${WIKI_FULL_PATH}/Users ]] && error "Please verify paramter '-f ${WIKI_FULL_PATH}' because '${WIKI_FULL_PATH}/Users' doesn't exist.\n"

[ ! ${EXPORT_WITH_DATA} == "yes" ] && [ ! ${EXPORT_WITH_DATA} == "no" ] && EXPORT_WITH_DATA="no" && echo -e "Option '-D ${OPTARG}' is incorrect. The process will continue with '-D ${EXPORT_WITH_DATA}'.\n"

[[ ${ERROR_ON_KEEP_DAILY_NUMBER} -eq 1 ]] && echo -e "There is an error in your parameter '-d ${OLD_KEEP_DAILY_NUMBER}'.\nThe process will continue with default option: '-d ${KEEP_DAILY_NUMBER}'\n"
[[ ${ERROR_ON_KEEP_WEEKLY_NUMBER} -eq 1 ]] && echo -e "There is an error in your parameter '-w ${OLD_KEEP_WEEKLY_NUMBER}'.\nThe process will continue with default option: '-w ${KEEP_WEEKLY_NUMBER}'\n"

# Dir of the day
if [ "$( date +%w )" == "0" ]; then
        [ ! -d ${EXPORT_PATH_ROOT}/sunday ] && mkdir -p ${EXPORT_PATH_ROOT}/sunday
        EXPORT_PATH="${EXPORT_PATH_ROOT}/sunday"
        KEEP_NUMBER=$((${KEEP_WEEKLY_NUMBER}*7))
        echo "Weekly export: ${KEEP_NUMBER} days of exports will be kept."
else
        [ ! -d ${EXPORT_PATH_ROOT}/daily ] && mkdir -p ${EXPORT_PATH_ROOT}/daily
        EXPORT_PATH="${EXPORT_PATH_ROOT}/daily"
        KEEP_NUMBER=${KEEP_DAILY_NUMBER}
        echo "Daily export: ${KEEP_NUMBER} days of exports will be kept."
fi
[[ ! -d ${EXPORT_PATH} ]] && error "Error when try to create and/or access '${EXPORT_PATH}'."

# Create temp dir
DATATMP="${EXPORT_PATH_ROOT}/temp"
mkdir -p ${DATATMP}/${DATANAME}
[ $? -ne 0 ] && error "Error when try to create '${DATATMP}/${DATANAME}'."
mkdir -p ${DATATMP}/${DATANAME}/users
[ $? -ne 0 ] && error "Error when try to create '${DATATMP}/${DATANAME}/users'."
mkdir -p ${DATATMP}/${DATANAME}/groups
[ $? -ne 0 ] && error "Error when try to create '${DATATMP}/${DATANAME}/groups'."
mkdir -p ${DATATMP}/${DATANAME}/groups/blogs
[ $? -ne 0 ] && error "Error when try to create '${DATATMP}/${DATANAME}/groups/blogs'."
mkdir -p ${DATATMP}/${DATANAME}/groups/wikis
[ $? -ne 0 ] && error "Error when try to create '${DATATMP}/${DATANAME}/groups/wikis'."
mkdir -p ${DATATMP}/${DATANAME}/data
[ $? -ne 0 ] && error "Error when try to create '${DATATMP}/${DATANAME}/data'."
mkdir -p ${DATATMP}/${DATANAME}/data/Groups
[ $? -ne 0 ] && error "Error when try to create '${DATATMP}/${DATANAME}/data/Groups'."
mkdir -p ${DATATMP}/${DATANAME}/data/Users
[ $? -ne 0 ] && error "Error when try to create '${DATATMP}/${DATANAME}/data/Users'."


function extractPlistValueByKey () {
    head -n \
      $(expr 1 + `grep -n "<key>$1</key>" page.plist | cut -d ':' -f 1`) page.plist | \
        tail -n 1 | cut -d '>' -f 2 | cut -d '<' -f 1
}

function linkifyWikiServerTitle () {
    echo $1 | sed -e 's/ /_/g' -e 's/&amp;/_/g' -e 's/&gt;/_/g' -e 's/&lt;/_/g' -e 's/\?//g'
}

function formatISO8601date () {
    echo $1 | sed -e 's/T/ /' -e 's/Z$//'
}

function csvQuote () {
    echo $1 | grep -q ',' >/dev/null
    if [ $? -eq 0 ]; then # if there are commas in the string
        echo '"'"$1"'"'   # quote the value
    else
        echo "$1"         # just output the as it was received
    fi
}

function exportOSXCollaborationFiles () {
    WS_CSV_OUTFILE=pages.csv
    WS_PAGE_IDS_FILE=`mktemp ws-ids.tmp.XXXXXX`
    if [[ ${2} -eq "wiki" ]]; then
        PSTALLY=`ls -l | grep -v ^l | wc -l`
        [ $PSTALLY -gt 4 ] && ls -d [^w]*.page | sed -e 's/^\([a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]\)\.page$/\1/' > $WS_PAGE_IDS_FILE
    elif [[ ${2} -eq "weblog" ]]; then
        ls -d [^w]*.page | sed -e 's/^\([a-f0-9][a-f0-9][a-f0-9][a-f0-9][a-f0-9]\)\.page$/\1/' > $WS_PAGE_IDS_FILE
    fi
    echo "Title,ID,Date Created,Last Modified,URI,Content" > $WS_CSV_OUTFILE
    while read id; do
        cd $id.page
        title="$(extractPlistValueByKey title)"
        created_date="$(formatISO8601date $(extractPlistValueByKey createdDate))"
        modified_date="$(formatISO8601date $(extractPlistValueByKey modifiedDate))"
        link=${WS_URL_PREFIX}"$3"/"$1"/"$2"/"$id"/`linkifyWikiServerTitle "$title"`.html
        FILE_DATA=`echo $( /bin/cat page.html ) | tr ',' ' '`
        cd ..
        echo `csvQuote "$title"`,$id,$created_date,$modified_date,`csvQuote "$link"`,"$FILE_DATA" >> $WS_CSV_OUTFILE
    done < $WS_PAGE_IDS_FILE
    rm $WS_PAGE_IDS_FILE
}

for i in `ls ${WIKI_FULL_PATH}/Groups`
do
    # Export Group Wikis
    if [[ -d ${WIKI_FULL_PATH}/Groups/$i/wiki/ ]]; then
        cd ${WIKI_FULL_PATH}/Groups/$i/wiki/
        ls -d [^w]*.page > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            exportOSXCollaborationFiles $i wiki groups
            mkdir -p ${DATATMP}/${DATANAME}/groups/wikis/$i
            cp ${WIKI_FULL_PATH}/Groups/$i/wiki/pages.csv ${DATATMP}/${DATANAME}/groups/wikis/$i/
            rm ${WIKI_FULL_PATH}/Groups/$i/wiki/pages.csv
            [ ${EXPORT_WITH_DATA} == "yes" ] && mkdir -p ${DATATMP}/${DATANAME}/data/Groups/$i/wiki/ && cp -r ${WIKI_FULL_PATH}/Groups/$i/wiki/*.page ${DATATMP}/${DATANAME}/data/Groups/$i/wiki/
        fi
    fi
    # Export Group Blogs
    if [[ -d ${WIKI_FULL_PATH}/Groups/$i/weblog/ ]]; then
        cd ${WIKI_FULL_PATH}/Groups/$i/weblog/
        ls -d [^w]*.page > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            exportOSXCollaborationFiles $i weblog groups
            mkdir -p ${DATATMP}/${DATANAME}/groups/blogs/$i
            cp ${WIKI_FULL_PATH}/Groups/$i/weblog/pages.csv ${DATATMP}/${DATANAME}/groups/blogs/$i/
            rm ${WIKI_FULL_PATH}/Groups/$i/weblog/pages.csv
            [ ${EXPORT_WITH_DATA} == "yes" ] && mkdir -p ${DATATMP}/${DATANAME}/data/Groups/$i/weblog/ && cp -r ${WIKI_FULL_PATH}/Groups/$i/weblog/*.page ${DATATMP}/${DATANAME}/data/Groups/$i/weblog/
        fi
    fi
done

for i in `ls ${WIKI_FULL_PATH}/Users`
do
    # Export User Blogs
    if [[ -d ${WIKI_FULL_PATH}/Users/$i/weblog/ ]]; then
        cd ${WIKI_FULL_PATH}/Users/$i/weblog/
        ls -d [^w]*.page > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            exportOSXCollaborationFiles $i weblog users
            mkdir -p ${DATATMP}/${DATANAME}/users/$i
            cp ${WIKI_FULL_PATH}/Users/$i/weblog/pages.csv ${DATATMP}/${DATANAME}/users/$i/
            rm ${WIKI_FULL_PATH}/Users/$i/weblog/pages.csv
            [ ${EXPORT_WITH_DATA} == "yes" ] && mkdir -p ${DATATMP}/${DATANAME}/data/Users/$i/weblog/ && cp -r ${WIKI_FULL_PATH}/Users/$i/weblog/*.page ${DATATMP}/${DATANAME}/data/Users/$i/weblog/
        fi
    fi
done

## TAR Files and creating symbolic link
cd ${DATATMP}
echo -e "\nCeating tar file ${EXPORT_PATH}/${DATANAME}.gz"
tar -czf ${EXPORT_PATH}/${DATANAME}.gz ${DATANAME}
[ $? -ne 0 ] && error "Error when trying to create ${EXPORT_PATH}/${DATANAME}.gz\n"
cd ${EXPORT_PATH}
chmod 600 ${DATANAME}.gz
[ -f last.gz ] &&  rm last.gz
ln -s ${EXPORT_PATH}/${DATANAME}.gz ${EXPORT_PATH}/last.gz
 
## Removing temp dir
[ -d ${DATATMP}/${DATANAME} ] && rm -rf ${DATATMP}/${DATANAME}
[ -d ${DATATMP} ] && rm -rf ${DATATMP}
 
## On supprime les anciens backups
echo -e "\nDeleting old exports..."
find ${EXPORT_PATH} -name "*.gz" -mtime +${KEEP_NUMBER} -print -exec rm {} \;

alldone 0