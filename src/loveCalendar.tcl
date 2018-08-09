#!/bin/sh
package require Tk
package require Thread

namespace eval my {}

source -encoding utf-8 draw.tcl
source -encoding utf-8 weather.tcl
source -encoding utf-8 memory.tcl


set datetime_old(year) -1
set datetime_old(month) -1
set datetime_old(day) -1
set datetime_old(hour) -1
set datetime_old(minute) -1
set datetime_old(week) -1

# 退出
proc ::my::doExit {} {
	if {[tsv::get app usekindle] == 1} {
    	# 关闭屏保
    	exec lipc-set-prop com.lab126.powerd preventScreenSaver 0
    }
	tsv::set app runLoop 0
	exit
}

# 获取电池状态
proc ::my::getStatus {} {
	global battery
	set status [exec lipc-get-prop com.lab126.powerd status]
	regexp "Battery Level: (\[0-9]{1,3})%" $status all battery(level)
	regexp "Charging: (\[A-z]{2,3})" $status all battery(charging)
}

# 日期差值
proc ::my::deltaDay {dateString} {
	set unixTime [clock scan $dateString -format "%Y-%m-%d"]
	set now [clock seconds]
	set days [expr ($now - $unixTime)/3600/24]
}

# 设置窗口
proc ::my::setWindow {toplevel} {
	# 设定分辨率和标题栏
	# 本句话用来兼容windows（加上后只支持kindle）
	$toplevel configure -background white
	if {[tsv::get app usekindle] == 1} {
		wm overrideredirect $toplevel on
	}
	wm geometry $toplevel 600x800
	tkwait window $toplevel
}

# wait wifi connect
proc ::my::waitWifiConnect {} {
	if {[tsv::get app usekindle] == 0} {
		return 1
	}
	for {set i 0} {$i<45} {incr i} {
		::my::waitMenuButton
        if {[catch {
			set connect [exec lipc-get-prop com.lab126.wifid cmState | grep CONNECTED]
        }]} {
			set connect 0
			continue
        }
		if {$connect == "CONNECTED"} {
			return 1
		}
	}
	return 0
}

proc ::my::waitWifiDisconnect {} {
	if {[tsv::get app usekindle] == 0} {
		return
	}
	for {set i 0} {$i<20} {incr i} {
		::my::waitMenuButton
		if {[catch {
			set connect [exec lipc-get-prop com.lab126.wifid cmState | grep CONNECTED]
		}]} {
			return
		}
		if {$connect == "CONNECTED"} {
			continue
		} else {
			return
		}
	}
}

# 等待Menu按钮按下
proc ::my::waitMenuButton {} {
	# set now [clock seconds]
	# puts "$now waiting Button"
	catch {
		exec lipc-wait-event com.lab126.appmgrd appStateChange -s 1
		::my::doExit
	}
}

# 等待Menu按钮按下
proc ::my::waitMenuButtonTime {tm} {
	# set now [clock seconds]
	# puts "$now waiting Button"
	catch {
		exec lipc-wait-event com.lab126.appmgrd appStateChange -s $tm
		::my::doExit
	}
}

# wifi switch
proc ::my::wifiSet {power} {
	if {[tsv::get app usekindle] == 1} {
		catch {
			exec lipc-set-prop com.lab126.wifid enable $power
		}
	}
}

# 自动对时
proc ::my::timeset {} {
	if {[tsv::get app usekindle] == 1} {
		catch {
			exec ntpdate time.nist.gov
		}
	}
}

# 更新纪念日
proc ::my::updateMemorial {} {
	set day_describe [::memory::nearestDay]
	if {[lindex $day_describe 0] <= 10} {
		set ::textNotify [lindex $day_describe 1]
	} else {
		set ::textNotify [::memory::randWords]
	}
}

proc ::my::update {} {
	global datetime
	global datetime_old
	# 读取当前时间
	set now [clock format [clock seconds] -format "%Y-%m-%d %H:%M %w"]
	regexp "(\[0-9]{4,4})-(\[0-9]{1,2})-(\[0-9]{1,2}) (\[0-9]{1,2}):(\[0-9]{1,2}) (\[0-9]{1,1})" $now \
	all datetime(year) datetime(month) datetime(day) datetime(hour) datetime(minute) datetime(week)
	# 首次运行
	if {$datetime_old(month) == -1} {
	}
	# 按月变化
	if {$datetime_old(month) != $datetime(month)} {
	}
	# 按星期变化
	if {$datetime_old(week) != $datetime(week)} {
	}
	# 按天变化
	if {$datetime_old(day) != $datetime(day)} {
	}
	# 按小时变化
	if {$datetime_old(hour) != $datetime(hour)} {
		# 更新天气
		catch { ::my::updateWeather 1 }
	}
	# 按分钟变化
	if {$datetime_old(minute) != $datetime(minute)} {
		# 更新当前时间
		if {[catch {::draw::showCurrentTime} e]} {puts $e}
		# 更新电量信息
		if {[catch {::draw::showInfo} e]} {puts $e}
	}
	# 更新上次时间
	regexp "(\[0-9]{4,4})-(\[0-9]{1,2})-(\[0-9]{1,2}) (\[0-9]{1,2}):(\[0-9]{1,2}) (\[0-9]{1,1})" $now \
	all datetime_old(year) datetime_old(month) datetime_old(day) datetime_old(hour) datetime_old(minute) datetime_old(week)
}

proc ::my::layoutForcast {canvas i width} {
	label $canvas.date -textvariable fc_date$i -bg white -font fontTitle
	label $canvas.week -textvariable fc_week$i -bg white -font fontTitle
	label $canvas.temp -textvariable fc_temp$i -bg white -font fontTitle
	place $canvas.date -x 0 -y 10 -width $width
	place $canvas.week -x 0 -y 35 -width $width
	place $canvas.temp -x 0 -y 190 -width $width
}

proc ::my::layout {} {
	# 四个页面的高度
	set totalHeight 0
	set h_time 284
	set h_dayforcast 226
	set h_notification 30
	set h_hourforcast 180
	set h_hourlabel 80
	# 时间版面
	canvas .frmTime -bg white -highlightthickness 0
	canvas .frmTime.time -bg white -highlightthickness 0
	canvas .frmTime.comic -bg white -highlightthickness 0
	canvas .frmTime.info -bg white -highlightthickness 0
	grid .frmTime.comic -column 0 -row 0 -stick nswe
	grid .frmTime.time -column 1 -row 0 -stick nswe
	grid .frmTime.info -column 2 -row 0 -stick nswe
	grid rowconfigure .frmTime 0 -weight 1 -uniform a
	grid columnconfigure .frmTime 1 -weight 2 -uniform a
	grid columnconfigure .frmTime {0 2} -weight 1 -uniform a
	place .frmTime -x 0 -y $totalHeight -anchor nw -height $h_time -width 600
	label .frmTime.info.date -bg white -textvariable infoDate -font fontTitle 
	label .frmTime.info.tempNow -bg white -textvariable infoTempNow -font fontTitle
	label .frmTime.info.humidity -bg white -textvariable infoHumidity -font fontTitle
	label .frmTime.info.windspeed -bg white -textvariable infoWindspeed -font fontTitle
	label .frmTime.info.battery -bg white -textvariable infoBattery -font fontTitle
	set info_init_y 100
	place .frmTime.info.date -width 150 -anchor w -y $info_init_y
	place .frmTime.info.tempNow -width 150 -anchor w -y [expr $info_init_y+30]
	place .frmTime.info.humidity -width 150 -anchor w -y [expr $info_init_y+60]
	place .frmTime.info.windspeed -width 150 -anchor w -y [expr $info_init_y+90]
	place .frmTime.info.battery -width 150 -anchor w -y [expr $info_init_y+120]
	set totalHeight $h_time
	
	# 4日天气预报版面
	frame .frmDayForcast -bg white
	for {set i 0} {$i < 4} {incr i} {
		canvas .frmDayForcast.forcast$i -highlightthickness 0 -bg white
		grid .frmDayForcast.forcast$i -column $i -row 0
		::my::layoutForcast .frmDayForcast.forcast$i $i 150
	}
	grid rowconfigure .frmDayForcast 0 -weight 1 -uniform a
	grid columnconfigure .frmDayForcast {0 1 2 3} -weight 2 -uniform a
	place .frmDayForcast -x 0 -y $totalHeight -anchor nw -height $h_dayforcast -width 600
	set totalHeight [expr $totalHeight+$h_dayforcast]
	
	# 文字提示
	label .labelNotify -font fontNote -textvariable textNotify
	place .labelNotify -x 0 -y $totalHeight -anchor nw -height $h_notification -width 600
	set totalHeight [expr $totalHeight+$h_notification]
	
	# 曲线页面
	canvas .frmHourForcast -bg white -highlightthickness 0
	place .frmHourForcast -x 0 -y $totalHeight -anchor nw -height $h_hourforcast -width 600
	set totalHeight [expr $totalHeight+$h_hourforcast]

	# 小时刻度
	frame .frmHourLabel -bg yellow -highlightthickness 0
	place .frmHourLabel -x 0 -y $totalHeight -anchor nw -height $h_hourlabel -width 600
	set totalHeight [expr $totalHeight+$h_hourlabel]
	
	# 小时刻度里面的内容
	for {set i 0} {$i<11} {incr i} {
		# 第一行
		label .frmHourLabel.labelHour$i -bg white -textvariable varLabelHour$i
		grid .frmHourLabel.labelHour$i -column [expr $i+1] -row 0 -stick nswe
		# 第二行
		canvas .frmHourLabel.canvas$i -bg white -highlightthickness 0
		grid .frmHourLabel.canvas$i -column [expr $i+1] -row 1 -stick nswe
		# 第三行
		label .frmHourLabel.labelStatus$i -bg white -textvariable varLabelStatus$i
		grid .frmHourLabel.labelStatus$i -column [expr $i+1] -row 2 -stick nswe
	}
	canvas .frmHourLabel.cleft -bg white -highlightthickness 0
	canvas .frmHourLabel.cright -bg white -highlightthickness 0
	grid .frmHourLabel.cleft -column 0 -row 0 -rowspan 3 -stick nswe
	grid .frmHourLabel.cright -column 12 -row 0 -rowspan 3 -stick nswe
	grid rowconfigure .frmHourLabel 0 -weight 1 -uniform a
	grid rowconfigure .frmHourLabel 1 -weight 2 -uniform a
	grid rowconfigure .frmHourLabel 2 -weight 1 -uniform a
	grid columnconfigure .frmHourLabel {0 12} -weight 2 -uniform b
	grid columnconfigure .frmHourLabel {1 2 3 4 5 6 7 8 9 10 11} -weight 3 -uniform b
}

proc ::my::updateWeather {inital} {
#	# 开启wifi
#	::my::wifiSet 1
#	# 确定wifi已经连接
	set connect [::my::waitWifiConnect]
	if {$connect == 1} {
    	set ::textNotify "正在更新天气数据"
		set now [clock seconds]
		puts "connected ok, updating at $now"
		# 更新数据
		# 以下函数内存检测完毕
		if {[catch {::my::timeset} e]} {puts $e}
		# 请求openweather更新天气
		if {[catch {::weather::refresh} e]} {puts $e}
		# 关闭wifi
		::my::wifiSet 0
		# 更新天气曲线
		if {[catch {::draw::showCurve} e]} {puts $e}
		# 更新小时天气预报
		if {[catch {::draw::showHourCast} e]} {puts $e}
		# 更新4天天气预报
		if {[catch {::draw::showDaysNext} e]} {puts $e}
		# 更新当前时间
		if {[catch {::draw::showCurrentTime} e]} {puts $e}
		# 更新左侧漫画
		if {[catch {::draw::showComic} e]} {puts $e}
		# 更新右侧信息
		if {[catch {::draw::showInfo} e]} {puts $e}
		# 更新纪念日提示
		if {[catch {::my::updateMemorial} e]} {puts $e}
	} else {
		puts "failed to connect wifi"
		if {$inital == 1} {
			::my::doExit
		}
	}
#	# 再次关闭wifi
#	::my::wifiSet 0
#	# 等待wifi关闭
#	::my::waitWifiDisconnect
}

proc ::my::createTask {} {
	# 设定标志位
	tsv::set app runLoop 1
	thread::create {
		if {[catch {
			while {[tsv::get app runLoop]} {
				# 执行主线程中的函数，阻塞
				thread::send [tsv::get app mainID ] ::my::update
				# 等待1s
				thread::send [tsv::get app mainID ] ::my::waitMenuButton
				# 当前秒数
				set s_now [clock format [clock seconds] -format "%S"]
				set s_left [tcl::mathfunc::int [expr 60-$s_now.0]]
				# 等待1
				if {[tsv::get app usekindle] == 0} { continue }
				if {$s_left == 0} {continue}
				# 不休眠的代码
				thread::send [tsv::get app mainID ] ::my::waitMenuButtonTime $s_left
				after 500
				# 休眠的代码
				# exec echo -n $s_left > /sys/devices/platform/mxc_rtc.0/wakeup_enable
				# after 500
				# exec echo mem > /sys/power/state
			   } 
			} e
		]} {
		   puts $e
		   thread::send [tsv::get app mainID ] ::my::doExit
	   }
	}
}

proc ::my::my {toplevel args} {
	global battery
	global datetime
	global datetime_old
	global runTime
	
	# 确定运行平台
	if {[catch ::my::getStatus]} {
		tsv::set app usekindle 0
	} else {
		tsv::set app usekindle 1
	}
	
	font create fontNote -size 12
	font create fontTitle -size 14
	
	if {[tsv::get app usekindle] == 1} {
		# 关闭屏保
		exec lipc-set-prop com.lab126.powerd preventScreenSaver 1
	}

	::my::layout
	
	puts running...
	
	# 取当前线程id
	tsv::set app mainID [thread::id]

	set ::textNotify "正在更新天气数据"
	thread::create {
		after 100
		thread::send [tsv::get app mainID ] ::my::createTask
	}
	# 显示窗口
	setWindow $toplevel
    return
}

::my::my .

