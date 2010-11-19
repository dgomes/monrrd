
#####################################################################
# Configuration End                                                 #
#####################################################################
date

plugin=$1
tmp=${plugin%.*}
self=${tmp##*/}
echo "Loading $self ..."

WANRRD="${RRDDATA}/energy.rrd"
RRD_FILES="${RRD_FILES} ${WANRRD}"

CreateRRD ()
{
if [ -f "${RRDTOOL}" ]; then	
	${RRDTOOL} create "${1}" \
	DS:energy:GAUGE:600:0:U \
	DS:power:GAUGE:600:0:U \
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
		ENERGY=`wget -q -O - http://192.168.1.103/listdev.htm | grep Wh | cut -b 25- | cut -d \  -f 1`
		POWER=`wget -q -O - http://192.168.1.103/listdev.htm | grep "W&nbsp" | cut -b 25- | cut -d \  -f 1`
		`${RRDUPDATE} "${1}" -t energy:power N:"${ENERGY}":"${POWER}"`
	fi
}

# $1 = RRDfile
ExportRRD()
{
TITLE=" Power measured"            
XML=`${RRDTOOL} xport \
--start now-$WHEN --end now \
DEF:power=${RRDDATA}/$1.rrd:power:AVERAGE \
XPORT:power:'Power (W)' \
XPORT:power:'Power (W)' \
| sed '1d' | sed '1d' | sed '1d'\
`
}
