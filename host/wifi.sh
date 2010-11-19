
#####################################################################
# Configuration End                                                 #
#####################################################################
date

plugin=$1
tmp=${plugin%.*}
self=${tmp##*/}
echo "Loading $self ..."

WANRRD="${RRDDATA}/wifi.rrd"
RRD_FILES="${RRD_FILES} ${WANRRD}"

CreateRRD ()
{
if [ -f "${RRDTOOL}" ]; then	
	${RRDTOOL} create "${1}" \
	DS:n_cli:GAUGE:600:0:U \
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
		N_CLI=`/opt/bin/snmpget -v 2c -c jigvaga 192.168.2.150 .1.3.6.1.4.1.63.501.3.2.1.0 | cut -d \  -f 4`
		OTHER=`echo 0`
		`${RRDUPDATE} "${1}" -t n_cli:other N:"${N_CLI}":"${OTHER}"`
	fi
}

# $1 = RRDfile
ExportRRD()
{
TITLE=" # of Wireless Clients"            
XML=`${RRDTOOL} xport \
--start now-$WHEN --end now \
DEF:n_cli=${RRDDATA}/$1.rrd:n_cli:AVERAGE \
DEF:other=${RRDDATA}/$1.rrd:other:AVERAGE \
XPORT:n_cli:'Wireless Stations' \
XPORT:other:'' \
| sed '1d' | sed '1d' | sed '1d'\
`
}
