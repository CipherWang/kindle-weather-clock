package require Tk
package require http
source json.tcl

namespace eval ::weather {
	variable version 1.0
}

global w_current
global w_5day3hour

proc ::weather::getHttpData {url} {
	# HTTP请求
	set response 0
	if {[catch {
    		set request [http::geturl $url -timeout 8000]
    		regexp "(200)" [::http::code $request] all result
    		if {$result != 200} {
			puts "error network $result"
    			error "error network"
    		}
    		set response [http::data $request]
    		http::cleanup $request
	}]} {
		puts "::weather::getHttpData error $url"
		return 0
	}
	# 如果访问失败
	return $response
}

proc ::weather::parse {jsonStr} {
	if {[catch {
		set result [::json::parse $jsonStr]
	}]} {
		puts "::weather::parse error"
		return 0
	}
	return $result
}

proc ::weather::refresh {} {
	global w_current
	global w_5day3hour
	global w_16days
	set url_days "http://api.openweathermap.org/data/2.5/forecast?id=1816670&appid=6fe5968d84a06746a932a654b3e1a4eb&units=metric"
	set url_now "http://api.openweathermap.org/data/2.5/weather?id=1816670&appid=6fe5968d84a06746a932a654b3e1a4eb&units=metric"
	set url_ndays "http://api.openweathermap.org/data/2.5/forecast/daily?id=1816670&appid=6fe5968d84a06746a932a654b3e1a4eb&units=metric"
	
	# 获取当前天气
	if {[catch {
            set raw_json_now [::weather::getHttpData $url_now]
            set json_now [::weather::parse $raw_json_now]
            set list_w [::json::get-arg $json_now "weather" 0]
            set n_w [lindex $list_w 0]
            set w(icon) [::json::get-arg $n_w "icon" 0]
            set n_main [::json::get-arg $json_now "main" 0]
            set w(temp) [::json::get-arg $n_main "temp" "?"]
            set w(humidity) [::json::get-arg $n_main "humidity" "?"]
            set n_wind [::json::get-arg $json_now "wind" 0]
            set w(wspeed) [::json::get-arg $n_wind "speed" "?"]
            set w(wdeg) [::json::get-arg $n_wind "deg" "?"]
            set n_sun [::json::get-arg $json_now "sys" 0]
            set i_sun1 [::json::get-arg $n_sun "sunrise" 0]
            set i_sun2 [::json::get-arg $n_sun "sunset" 0]
            set tm_sun1 [clock format $i_sun1 -format "%H:%M"]
            set tm_sun2 [clock format $i_sun2 -format "%H:%M"]
            set w_current [list $w(icon) $w(temp) $w(humidity) $w(wspeed) $w(wdeg) $tm_sun1 $tm_sun2]
		} e]} {
    		puts "cannot get weather url_now, $e"
	}
	# 获取预报天气
	if {[catch {
		set raw_json_days [::weather::getHttpData $url_days]
		set json_days [::weather::parse $raw_json_days]
		set json_w_list [::json::get-arg $json_days "list" 0]
		set w_5day3hour [list ]
		foreach w_3hour $json_w_list {
			set w_item(time) [::json::get-arg $w_3hour "dt" 0]
			set w_main [::json::get-arg $w_3hour "main" 0]
			set w_item(temp) [tcl::mathfunc::int [::json::get-arg $w_main "temp" 0]]
			set w_item(temp_min) [tcl::mathfunc::int [::json::get-arg $w_main "temp_min" 0]]
			set w_item(temp_max) [tcl::mathfunc::int [::json::get-arg $w_main "temp_max" 0]]
			set w_item(humidity) [::json::get-arg $w_main "humidity" 0]
			set w_item(pressure) [::json::get-arg $w_main "pressure" 0]
			set w_w [::json::get-arg $w_3hour "weather" 0]
			set w_item(icon) [::json::get-arg [lindex $w_w 0] icon 0]
			# rain vol
			if {[catch {
				set snow [::json::get-arg $w_3hour snow 0]
				set rain_vol [::json::get-arg $snow "3h" 0]
			}]} {
				set rain_vol 0
			}
			catch {
				set rain [::json::get-arg $w_3hour rain 0]
				set rain_vol [expr $rain_vol + [::json::get-arg $rain "3h" 0]]
			}
			set item [list \
			 	$w_item(time) $w_item(temp) $w_item(temp_min) \
			 	$w_item(temp_max) $w_item(humidity) $w_item(pressure) \
				$w_item(icon) $rain_vol]
			lappend w_5day3hour $item
		}
	} e]} {
			puts "cannot get weather url_days, $e"
	}
	# 获取16天天气
	if {[catch {
		set raw_json_ndays [::weather::getHttpData $url_ndays]
		set json_ndays [::json::parse $raw_json_ndays]
		set w_16days [::json::get-arg $json_ndays "list" 0]
	} e]} {
		puts "cannot get weather url_days, $e"
	}
}

