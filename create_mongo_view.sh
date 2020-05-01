#!/bin/bash

if [ -z "$1" ]
then
    # if no project directory is supplied, current is used
    PROJECT_DIR=`pwd`
else
    PROJECT_DIR=$1
fi

LOG_DIR="${PROJECT_DIR}/log"

if [[ ! -d $LOG_DIR ]]
then
    `mkdir $LOG_DIR`
fi

LOGFILE=${LOG_DIR}/create_mongo_view.log
ERRORFILE=${LOG_DIR}/create_mongo_view.err
EVENT_LOG=${LOG_DIR}/process_events_log.csv
ENV_DIR="${PROJECT_DIR}/env"
SOURCE_COLLECTION_NAME='processed'
CONFIG_FILE_NAME='src/config_mongo_inb.json'
CONDA_ENV='twcovid'
error=0

####
# Print a starting message
####
running_date=`date '+%Y-%m-%d'`
printf "\n\n#####\nStarting to create view at ${running_date}\n######\n\n" >> $LOGFILE
start_time=`date '+%Y-%m-%d %H:%M:%S'`
echo "${running_date},'starting_view_creator',${start_time}," >> $EVENT_LOG

####
# Go to project directory
####
echo "Changing directory to ${PROJECT_DIR}..."
cd $PROJECT_DIR

####
# Active virtual environment
####
if [ $? -eq 0 ]
then
    echo "Activating virtual environment..."
    if [[ -d $ENV_DIR ]]
    then
        source env/bin/activate
    else
        source /opt/conda/etc/profile.d/conda.sh
        conda activate $CONDA_ENV
    fi
else
    error=1
fi

####
# Update view
####
if [ $? -eq 0 ]
then
    echo "Creating view..."
    start_time=`date '+%Y-%m-%d %H:%M:%S'`    
    start_date=`date --date='yesterday' +%Y-%m-%d`
    start_day_month=`date --date='yesterday' +%d%m`
    end_day_month=`date --date='+5 days' +%d%m`
    view_name="week_${start_day_month}${end_day_month}"
    echo "${running_date},'creating_view_${view_name}',${start_time}," >> $EVENT_LOG
    python mongo_view_manager.py create-week-view $view_name 'processed' --start_date $start_date  --config_file $CONFIG_FILE_NAME >> $LOGFILE 2>> $ERRORFILE
else
    error=1
fi

if [[ $? -eq 0 ]] && [[ $error -eq 0 ]]
then
    end_time=`date '+%Y-%m-%d %H:%M:%S'`
    echo "${running_date},'creating_view_${view_name}',,${end_time}" >> $EVENT_LOG
else
    error=1
fi

if [[ $? -eq 0 ]] && [[ $error -eq 0 ]]
then
    echo "Process has finished successfully"
    echo "For more information, check $LOGFILE"
else
    echo "There was an error running the process"
    echo "For more information, check $ERRORFILE"
fi

exit $error