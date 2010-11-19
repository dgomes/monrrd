WAN_ENABLED=true

#####################################################################
# Configuration End                                                 #
#####################################################################
date
plugin=$1
tmp=${plugin%.*}
self=${tmp##*/}

echo "Loading $self ..."

if [ "${WAN_ENABLED}" == "true" ]; then
	WANIF="zonhub"
	echo "WAN Interface: ${WANIF}"
	WANRRD="${RRDDATA}/${WANIF}.rrd"
	RRD_FILES="${RRD_FILES} ${WANRRD}"
fi

CreateRRD ()
{
if [ -f "${RRDTOOL}" ]; then	
	${RRDTOOL} create "${1}" --step 300 \
	DS:inBytes:COUNTER:600:0:125000000 \
	DS:outBytes:COUNTER:600:0:125000000 \
	RRA:AVERAGE:0.5:1:576 \
	RRA:AVERAGE:0.5:6:672 \
	RRA:AVERAGE:0.5:24:732 \
	RRA:AVERAGE:0.5:144:1460
fi

rrdfile=$1
tmp=${rrdfile%.*}
dev=${tmp##*/}
echo "<option value='${dev}&type=$self'>${dev}</option>" >> ${RRDTOOL_SCRIPTS_DIR}/options

}

# $1 = RRDfile 
UpdateRRD ()
{
	rrdfile=$1
	if [ -f "${RRDUPDATE}" ]; then	
		echo "Update ${rrdfile%.*}"
		tmp=${rrdfile%.*}
		dev=${tmp##*/}
		OUT=`upnpc-static -s -u http://192.168.1.1:2555/upnp/88642177-fdf1-3066-a209-ba9922068791/desc.xml | grep Bytes | awk -F ":" '{print $3}' | awk -F " " '{print $1}'`
		IN=`upnpc-static -s -u http://192.168.1.1:2555/upnp/88642177-fdf1-3066-a209-ba9922068791/desc.xml | grep Bytes | awk -F ":" '{print $4}' | awk -F " " '{print $1}'`
		`${RRDUPDATE} "${1}" -t inBytes:outBytes N:"${IN}":"${OUT}"`
	fi
}

# $1 = RRDfile
ExportRRD()
{
TITLE=" Traffic (kbps)"
XML=`\
${RRDTOOL} xport \
--start now-$WHEN --end now \
DEF:inBytes=${RRDDATA}/$1.rrd:inBytes:AVERAGE \
DEF:outBytes=${RRDDATA}/$1.rrd:outBytes:AVERAGE \
CDEF:in_kbits=inBytes,8,*,1000,/ \
CDEF:out_kbits=outBytes,8,*,1000,/ \
XPORT:in_kbits:"Incoming (kbps)" \
XPORT:out_kbits:"Outgoing (kbps)" \
| sed '1d' | sed '1d' | sed '1d'\
`
}
