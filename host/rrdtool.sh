#!/bin/bash 
#
# (c) 2009 by diogogomes@gmail.com 
#

# Configuration Start 

# Directory for storing RRD Databases
RRDDATA=/tmp/monrrd

RRDTOOL_SCRIPTS_DIR=/usr/local/monrrd/host
RRDPATH=/usr/bin
BACKUP_DIR=/root
BACKUP_FILE=${BACKUP_DIR}/rrd.bck.tar.gz
RRDTOOL=$RRDPATH/rrdtool
RRDUPDATE=$RRDPATH/rrdupdate

DEFAULT_RANGE=1d
DEFAULT_RRD=zonhub
DEFAULT_TYPE=net
CONF_WEBSERVER=http://storage.local/monrrd/graph.php

#####################################################################
# Configuration End                                                 #
#####################################################################
#Output date for log...
#date

args=$1

#Restore Backup or prepare dir
if [ ! -d "${RRDDATA}" ]; then
	echo "RRD Database dir: $RRDDATA does not exist...Creating Now...."
	/bin/tar xvf $BACKUP_FILE -C / > /var/log/rrdrestore.log
	if [ $? -eq 0 ]; then
		echo "Restored an older version..."
	else
		mkdir -p "${RRDDATA}"
	fi
fi

if [ ! -z $args ]; then
	if [ $args == "backup" ]; then
		mkdir -p ${BACKUP_DIR} 
		tar cvf ${BACKUP_FILE} ${RRDDATA}/*.rrd
		exit 0
	fi
	. $RRDTOOL_SCRIPTS_DIR/$1.sh
else
	#We are being called through the webinterface! let's get jiggy with it!
	echo Content-type: text/plain
	echo ""
	if [ ${#QUERY_STRING} -gt 0 ]; then
		OPT=`echo "$QUERY_STRING" | sed -n 's/^.*opt=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
		if [ ${#OPT} -gt 0 ]; then
			cat options	
			exit 0
		fi
		WHEN=`echo "$QUERY_STRING" | sed -n 's/^.*r=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
		if [ ${#WHEN} -eq 0 ]; then
			WHEN=$DEFAULT_RANGE
		fi

		WHICH=`echo "$QUERY_STRING" | sed -n 's/^.*rrd=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
		if [ ${#WHICH} -eq 0 ]; then
			WHICH=$DEFAULT_RRD
		fi
		if [ ! -f "${RRDDATA}/${WHICH}.rrd" ]; then
			echo "RRD ${WHICH}.rrd is unavailable"
			exit 0
		fi

		TYPE=`echo "$QUERY_STRING" | sed -n 's/^.*type=\([^&]*\).*$/\1/p' | sed "s/%20/ /g"`
		if [ ${#TYPE} -eq 0 ]; then
			TYPE=$DEFAULT_TYPE
		fi
	else
		WHEN=$DEFAULT_RANGE
		WHICH=$DEFAULT_RRD
		TYPE=$DEFAULT_TYPE
	fi

	. $RRDTOOL_SCRIPTS_DIR/${TYPE}.sh
	ExportRRD ${WHICH}
	
	if [ ${#XML} -gt 0 ]; then
		curl -4 -w '<!-- Elapsed Time: %{time_total} seconds -->\n' -d "title=${TITLE}" -d "rrdxml=<xport>${XML}" ${CONF_WEBSERVER} 2>/dev/null 
	else
		echo $QUERY_STRING
		echo "<br />" 
		echo "no XML to process"
		exit 1
	fi
	#we are done doing graphs
	exit 0
fi

# Create the Databases if they don't exist                                                                                                        
for rrdfile in ${RRD_FILES}; do                                                                                                                   
	if [ ! -f "${rrdfile}" ]; then 
		echo "RRD file : ${rrdfile} does not exist...Creating Now..."                                                                      
		CreateRRD "${rrdfile}"                                                                                                             
	fi                                                                                                                                         
done     

# Update the Databases 
for rrdfile in ${RRD_FILES}; do
	if [ -f "${rrdfile}" ]; then
		UpdateRRD ${rrdfile}
	fi
done

echo "Done"
