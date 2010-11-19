<?php
date_default_timezone_set('Europe/Lisbon');

$x_lenght=640;
$y_lenght=320;

//don't touch below
include('graph.inc');
$chart_title="";
if(array_key_exists('title',$_REQUEST) && !empty($_REQUEST[title])) 
	$chart_title=urlencode($_REQUEST[title]);
$in = "";
$out = "";
$x_axis = "|";
$chart_size=$x_lenght."x".$y_lenght;

if (array_key_exists('rrdxml',$_REQUEST)) {
    if(empty($_REQUEST[rrdxml])) exit("empty rrdxml string");
    $data_source = $_REQUEST[rrdxml];
    $xml = simplexml_load_string(($data_source));

    $rows = $xml->meta->rows;
    $start = $xml->meta->start;
    $stop = $xml->meta->stop;
    $step = $xml->meta->step;
    $in_caption = $xml->meta->legend->entry[0];
    $out_caption = $xml->meta->legend->entry[1];
    
    switch($step) {
	case 300: 
		$date_format='D H:i';
		$chart_title="Daily".$chart_title; 
		break;
	case 1800: 
		$date_format='D H:i'; 
		$chart_title="Weekly".$chart_title; 
		break;
	case 7200: 
		$date_format='d M'; 
		$chart_title="Monthly".$chart_title; 
		break;
	case 86400:
		$date_format='M Y'; 
		$chart_title="Yearly".$chart_title; 
	default:
		if($step < 1800)
			$date_format='D H:i';
		else
			$date_format='d M';
		$chart_title=$chart_title." since ".date('D j F Y',intval($start));
    }

    for($i=0; $i<=$rows; $i+=$rows/8)
	    $x_axis.= date($date_format,intval($start+$step*$i))."|";
    $x_axis = substr($x_axis,0,-1);

    for($i=0; $i<$rows; $i++) { 
	    $c_in = floatval(str_replace("e ", "e+", $xml->data->row[$i]->v[0]));
	    if($c_in>$max) $max = $c_in;
	    $in .= ",".$c_in;

	    $c_out = floatval(str_replace("e ", "e+", $xml->data->row[$i]->v[1]));
	    if($c_out>$max) $max = $c_out;
	    $out .= ",".$c_out;
    }
    $in = substr($in,1);
    $out = substr($out,1);
} else {
	exit("no rrdxml supplied");
}
?>
<img src="
<?php
$chd = google_chart_encode($in."|".$out,"e","x,y",0,$max);

echo "http://chart.apis.google.com/chart?
chtt=$chart_title
&chs=$chart_size
&chd=t:$chd
&cht=lc
&chco=00FF00,0000FF
&chdl=$in_caption|$out_caption
&chxl=0:$x_axis
&chxs=0,000055,10,0,lt,0000FF|1,004488,10
&chxtc=0,7|1,-$x_lenght
&chls=1,1,0|1,2,1
&chg=5,100,1,0,0,0
";
?>
" />
