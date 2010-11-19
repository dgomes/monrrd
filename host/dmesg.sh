
#####################################################################
# Configuration End                                                 #
#####################################################################
date

plugin=$1
tmp=${plugin%.*}
self=${tmp##*/}
echo "Loading $self ..."

WANRRD="${RRDDATA}/dmesg.rrd"
RRD_FILES="${RRD_FILES} ${WANRRD}"

CreateRRD ()
{
if [ -f "${RRDTOOL}" ]; then	
	${RRDTOOL} create "${1}" \
	DS:drop:GAUGE:600:0:U \
	DS:other:GAUGE:600:0:U \
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
		DROP=`dmesg | grep -c DROP `
		OTHER=`dmesg -c | grep -cv DROP `
		`${RRDUPDATE} "${1}" -t drop:other N:"${DROP}":"${OTHER}"`
	fi
}

# $1 = RRDfile
ExportRRD()
{
TITLE=" # of Dropped Connections"
XML=`\
${RRDTOOL} xport \
--start now-$WHEN --end now \
DEF:drop=${RRDDATA}/$1.rrd:drop:AVERAGE \
DEF:other=${RRDDATA}/$1.rrd:other:AVERAGE \
XPORT:drop:"Dropped Packets" \
XPORT:other:"Other occurences" \
| sed '1d' | sed '1d' | sed '1d'\
`
}
