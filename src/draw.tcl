#!/bin/sh

package require Tk

namespace eval ::draw {
	variable version 1.0
}

# 初始化
font create fontHour -family "Helvetica Neue LT" -size 120 -weight bold
font create fontMin -family "Helvetica Neue LT" -size 80 -weight bold

proc ::draw::showCurrentTime {} {
	set canvas .frmTime.time 
	set hour [clock format [clock seconds] -format "%H"]
	set minute [clock format [clock seconds] -format "%M"]
	global w_current
	global bgimg
	# 设置背景
	# 防止内存泄露
	catch { image delete $bgimg }
	if {[catch {
    	set wid [lindex $w_current 0]
		set bgimg [image create photo -file image/big/$wid.gif]
	}]} {
		set bgimg [image create photo -file image/big/0d.gif]
	}
	$canvas delete all
	$canvas create image 150 128 -image $bgimg
	# 显示时间
	$canvas create text 175 300 -text $hour -font fontHour -anchor se
	$canvas create text 175 290 -text $minute -font fontMin -anchor sw
}

# 显示温度变化曲线图
proc ::draw::showCurve {} {
	set canvas .frmHourForcast
	# const 
	set index_temp 1
	set index_temp_min 2
	set index_temp_max 3
	set index_rain 7
	
	# weather list
	global w_current
	global w_5day3hour
	set x_start 55
	set x_start_l 33
	set x_step 48.5
	set x_end [expr $x_start+$x_step*10]
	set x_end_l [expr 600-$x_start_l]
	set y_start 175
	set y_total 170
	set y_end [expr $y_start - $y_total]
	set r 4
	set l 10
	# 读取变化曲线
	set temp_min 1000
	set temp_max -1000
	set rain_min 0
	set rain_max 1
	for {set i 0} {$i<11} {incr i} {
		set weather [lindex $w_5day3hour $i]
		if {$temp_min > [lindex $weather $index_temp_min]} {
			set temp_min [lindex $weather $index_temp_min]
		}
		if {$temp_max < [lindex $weather $index_temp_max]} {
			set temp_max [lindex $weather $index_temp_max]
		}
		if {$rain_max < [lindex $weather $index_rain]} {
			set rain_max [tcl::mathfunc::ceil [lindex $weather $index_rain]]
		}
	}
	# 凑整
	while {[tcl::mathfunc::int $temp_min.0] % 5 != 0} {
		set temp_min [expr $temp_min-1]
	}
	while {[tcl::mathfunc::int $temp_max.0] % 5 != 0} {
		set temp_max [expr $temp_max+1]
	}
	set temp_min [expr $temp_min]
	set temp_max [expr $temp_max]
	# 设置关键点
	for {set i 0} {$i<11} {incr i} {
		set weather [lindex $w_5day3hour $i]
		set x [expr $x_start + $i*$x_step]
		set temp [lindex $weather $index_temp]
		set y [expr $y_start - ($temp-$temp_min)*$y_total/($temp_max-$temp_min)]
		set rain_vol [lindex $weather $index_rain]
		set rain_y [expr $y_start - ($rain_vol-$rain_min)*$y_total/($rain_max-$rain_min)]
		lappend coordListLine $x $y
		lappend coordListRing [list [expr $x-$r] [expr $y-$r] [expr $x+$r] [expr $y+$r]]
		lappend coordListBox [list [expr $x-$l] $y_start [expr $x+$l+5] $rain_y]
	}
	# 清除
	$canvas delete all
	catch {
		$canvas delete $lines
		foreach oval $ovals {$canvas delete $oval}
		foreach ax $axis {$canvas delete $ax}
		foreach text $textList {$canvas delete $text}
		foreach rect $rects {$canvas delete $rect}
	}
	# 画坐标轴
	for {set y $y_start} {$y >= $y_end} {set y [expr $y-($y_start-$y_end)/4]} {
		lappend axis [$canvas create line $x_start_l $y $x_end_l $y -width 1 -fill red]
	}
	for {set x $x_start_l} {$x < $x_end_l} {set x [expr $x+$x_step]} {
		lappend axis [$canvas create line $x $y_start $x [expr $y_start+5] -width 1 -fill red]
	}
	# 画雨量
	foreach rect $coordListBox {
		lappend rects [$canvas create rectangle $rect -fill gray]
	}
	# 画曲线
	set lines [$canvas create line $coordListLine -width 2 -fill blue]
	foreach ring $coordListRing {
		lappend ovals [$canvas create oval $ring -outline blue -width 2 -fill white]
	}
	# 画字符
	for {set i 0} {$i<5} {incr i} {
		lappend textList [$canvas create text [expr $x_start_l - 8] [expr $y_start-$i*($y_start-$y_end)/4] \
			-text [expr $temp_min + ($temp_max-$temp_min)*$i/4] -anchor e]
	}
	for {set i 0} {$i<3} {incr i} {
		lappend textList [$canvas create text [expr $x_end_l + 26] [expr $y_start-$i*($y_start-$y_end)/2] \
			-text [expr ($rain_max-$rain_min)*$i/2.0] -anchor e]
	}
}

# 显示小时图片和湿度
proc ::draw::showHourCast {} {
	set index_time 0
	set index_humidity 4
	set index_pressure 5
	set index_icon 6
	global w_5day3hour
	# 否则报错
	global imageArraySHC	
	if {[catch {
		foreach img $imageArraySHC {
			image delete $img
		}
	} e]} { }
	set imageArraySHC [list]
	for {set i 0} {$i < 11} {incr i} {
		set canvas .frmHourLabel.canvas$i
		$canvas delete all
		set weather [lindex $w_5day3hour $i]
		set tm [lindex $weather $index_time]
		set hour [clock format $tm -format "%H"]
		set ::varLabelHour$i $hour:00
		set ::varLabelStatus$i [lindex $weather $index_humidity]%
		set iconFile [lindex $weather $index_icon]
		set imghour [image create photo -file image/h48/$iconFile.gif]
		$canvas create image 24 24 -image $imghour
		lappend imageArraySHC $imghour
	}
	# 写文字
	set canvasL .frmHourLabel.cleft
	set canvasR .frmHourLabel.cright
	$canvasL delete all
	$canvasR delete all
	$canvasL create text 20	50 -text "温\n度\n"
	$canvasR create text 15	40 -text "降\n水\n量"
}

# 显示后四天的预报
proc ::draw::showDaysNext {} {
	global w_16days
	global imgMidArray
	catch {
        	foreach imgMid $imgMidArray {
        		image delete $imgMid
        	}
	}
	set imgMidArray [list]
	for {set i 0} {$i < 4} {incr i} {
		set canvas .frmDayForcast.forcast$i
		# 读数据
		if {[catch {set weather [lindex $w_16days [expr $i+1]]}]} {
			break;
        	}
		# 图案
		set ww [::json::get-arg $weather weather 0]
		set iconfile [::json::get-arg [lindex $ww 0] icon "0d"]
		set imgMidIcon [image create photo -file image/mid/$iconfile.gif]
		$canvas create image 75 128 -image $imgMidIcon
		lappend imgMidArray $imgMidIcon
		# 温度
		if {[catch {
        		set temp [::json::get-arg $weather temp N/A]
        		set tmax [tcl::mathfunc::round [::json::get-arg $temp max N/A]]
        		set tmin [tcl::mathfunc::round [::json::get-arg $temp min N/A]]
        		set ::fc_temp$i $tmax°C/$tmin°C
        	}]} {
			set ::fc_temp$i N/A	
        	}
		# 星期
		if {[catch {
			set dt [::json::get-arg $weather dt 0]
			set wkstring [::draw::getWeekDay $dt]
			set ::fc_week$i "星期$wkstring"
		}]} {
			set ::fc_week$i "星期?"
		}
		# 日期
		if {[catch {
			set tm [::json::get-arg $weather dt N/A]
			set ::fc_date$i [clock format $tm -format "%m月%d日"]
		}]} {
			set ::fc_date$i N/A
		}
	}
}

# 绘制左侧图案
proc ::draw::showComic {} {
	global imgComic
	set canvas .frmTime.comic
	set totalComic 103
	tcl::mathfunc::srand [clock seconds]
	set comicId [tcl::mathfunc::int [expr [tcl::mathfunc::rand]*$totalComic + 1]]
	catch {image delete $imgComic}
	set imgComic [image create photo -file image/comic/$comicId.gif]
	$canvas delete all
	$canvas create image 0 0 -image $imgComic -anchor nw
}

proc ::draw::getWeekDay {timestamp} {
	if {[catch {
        	set week [list 日 一 二 三 四 五 六]
        	set wkstring [lindex $week [clock format $timestamp -format "%w"]]
	}]} {
		set wkstring "?"
	}
    	return $wkstring
}

# 获取室内温度
proc ::draw::getTemperature {} {
	if {[tsv::get app usekindle] == 1} {
		if {[catch {
			set temp [exec cat /sys/devices/system/yoshi_battery/yoshi_battery0/battery_temperature]
		} e]} {
			puts "getTemperature error: $e"
			set temp 70
		}
	} else {
		set temp 70
	}
	set temp10 [expr ($temp - 32)/1.8*10]
	return [expr [tcl::mathfunc::int $temp10]/10.0]
}

# 更新右侧信息
proc ::draw::showInfo {} {
	global w_current
	if {[catch {
		set wkstring [::draw::getWeekDay [clock seconds]]
		set ::infoDate [clock format [clock seconds] -format "%m月%d日 星期$wkstring"]
		set tempIndoor [::draw::getTemperature]
		set tempNow [lindex $w_current 1]
		set ::infoTempNow "外$tempNow°C/内$tempIndoor°C"
		set ::infoHumidity "湿度: [lindex $w_current 2]%"
		set ::infoWindspeed "风速: [lindex $w_current 3]m/s"
		} e]} {
		puts "showInfo step 1 error: $e"
		set ::infoWindspeed "error1"
	}
	if {[catch {
		# 获取电池信息
		set battery_level [exec cat /sys/devices/system/yoshi_battery/yoshi_battery0/battery_capacity]
		set ::infoBattery "电量: $battery_level"
	} e]} {
		puts "showInfo step 2 error: $e"
		set ::infoWindspeed "error2"
	}
}

