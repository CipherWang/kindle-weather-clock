package require Tk

namespace eval ::memory {
	variable version 1.0
}


set randomPerson [list \
	"萌呆傻纸说：" \
	"多啦猫说：" \
	"哆啦咪听柯南说：" \
	"柯南偷偷说说：" \
	"大脚怪叫到：" \
	"白雪公主说：" \
	"葫芦娃听爷爷说：" \
	"门口大爷说：" \
	"自由女神说：" \
	"王凯说：" \
	"靳东说：" \
	"霍建华说：" \
	"妈妈说：" \
	"爸爸说：" \
	"老公说：" \
	"男朋友说：" \
	"学霸说：" \
	"学渣听学霸说：" \
	"阿拉蕾说：" \
	"瓢瓢说："
]
set randomString [list \
	"瓢瓢真漂亮啊~~" \
	"瓢瓢是小细腿小细腰美女！" \
	"瓢瓢今天心情真好~" \
	"瓢瓢的老公最帅。" \
	"瓢瓢要保持心情好，每天漂亮一点点。" \
	"也许我不是最优秀的，但我是最努力的。" \
	"没有永远的胜利，只有永远的努力。" \
	"艰苦是面临，挫折是经验，努力是桥梁，成功是彼岸。" \
	"对别人宽容是一种储蓄，对自己宽容是一次透支。" \
	"为草应做兰，为木应做松。" \
	"成功是优点的发挥，失败是缺点的累积。" \
	"学习使人丰富知识，知识使人提升才能，才能使人创造业绩。" \
	"不管是金点子，还是银点子，得不到落实都是空点子。" \
	"不怕难字当道，就怕懒字沾身。" \
	"闪光的未必都是金子，而沉默的也不一定就是石头。" \
	"今天的成绩是昨天的汗水，明天的成功还须今天的努力。" \
	"平视自己，仰视他人。" \
	"站起来做人，弯下腰做事。" \
	"在人之上要自重，在人之下要自尊。" \
	"懒惰者等待机遇，勤奋者创造机遇。" \
	"欲师者，温故而知新。欲达者，吐故而纳新。欲强者，明故而创新。" \
	"外求真金莫于内求真心。" \
	"生命的意义在于燃烧自己的同时能否照亮自己。" \
	"诚信是做人之母，务实乃成功之道。" \
	"贵在坚持难在坚持成在坚持。" \
	"凡事若等明天做，机遇便从眼前过。" \
	"为人贵在实，工作贵在专，学习贵在恒。" \
	"一个能思想的人，才是一个力量无边的人。" \
	"做人要像竹子一样每前进一步，都要做一次小结。" \
	"用金银装饰自己，不如用知识充实自己。" \
	"想法决定做法，思路决定出路。" \
	"学习与创造是人生的两只脚。" \
	"在顺境中执着，在逆境中沉着。" \
	"失败对于强者是逗号，对于弱者是句号。" \
	"诚实+守信，树立自身形象；勤奋+努力，实现自身价值。" \
	"舍弃有限，赢得无限。" \
	"平平淡淡看世界，踏踏实实写人生。" \
	"名字是父母给的，人生是自己走的。" \
	"人生只有现场直播，没有彩排。" \
	"抓住现实中的一分一秒，胜过想像中的一月一年。" \
	"把机遇留给朋友，把幸运留给亲人，把勤奋留给自己。" \
	"别人的缺点是自己的镜子。" \
	"人生就像一首歌。用心去唱才会动听。" \
	"惟宽可容人，惟厚可载人。" \
	"知识是永远的流行色。" \
	"微笑是两个人之间最短的距离。" \
	"最好的节约是珍惜时间，最大的浪费是虚度年华。" \
	"努力了不一定能够成功，但不努力永远不会有成功。" \
	"如果你真的想要做一件事情，全世界都会帮你。" \
	"再牛逼的梦想也抵不住你傻逼的坚持。" \
	"生活不是等待风暴过去，而是学会在雨中翩翩起舞。" \
	"人生只有走出来的美丽，没有等出来的辉煌。" \
	"勿忘初心，方得始终。" \
	"天再高又怎样，只要垫起脚尖就会更接近太阳。" \
	"抱怨没有用。凭的是实力。" \
	"耐得住寂寞才守得住繁华。" \
	"永远面向阳光，这样你就看不见阴影了" \
	"要想成功，你还需要有那么一点与众不同。" \
	"所有的努力，都是为了遇见更好的自己。" \
	"猪肉都可以涨价，凭什么梦想比猪肉都廉价。" \
	"人无志向，和迷途的盲人一样。" \
	"当一个人有高飞的冲动时，他就不会再在地上爬。" \
]

set memoralDay [list \
	"01-01" "元旦" \
	"02-07" "亲亲老公生日" \
	"02-14" "相遇纪念日" \
	"03-07" "女生节" \
	"04-01" "愚人节" \
	"04-26" "结婚纪念日" \
	"05-01" "劳动放假节" \
	"06-01" "儿童节" \
	"10-01" "十一放假节" \
	"12-24" "平安夜" \
	"12-26" "可爱老婆生日"
]

proc ::memory::nearestDay {} {
	global memoralDay
	set now [clock format [clock seconds] -format "%Y-%m-%d"]
	regexp "(\[0-9]{4,4})-(\[0-9]{1,2})-(\[0-9]{1,2})" $now all year month day
	set nearestDistance 365
	for {set i 0} {$i < [llength $memoralDay]} {set i [expr $i+2]} {
		set dateString $year-[lindex $memoralDay $i]
		set unixTime [clock scan $dateString -format "%Y-%m-%d"]
		set unixNow [clock scan $year-$month-$day -format "%Y-%m-%d"]
		if {[expr $unixTime - $unixNow] < 0} {
			set dateString [expr $year+1]-[lindex $memoralDay $i]
			set unixTime [clock scan $dateString -format "%Y-%m-%d"]
		}
		set day_distance [tcl::mathfunc::int [expr ($unixTime - $unixNow)/24/3600]]
		if {$nearestDistance > $day_distance} {
			set nearestDistance $day_distance
			set nearestDay [lindex $memoralDay $i]
			set nearestDiscribe [lindex $memoralDay [expr $i+1]]
		}
	}
	if {$nearestDistance == 0} {
		# 当天
		return [list 0 "今天是$nearestDiscribe，记得庆祝啊！"]
	} else {
		return [list $nearestDistance "距离  $nearestDiscribe 还有 $nearestDistance 天~~"]
	}
}

proc ::memory::randWords {} {
	global randomPerson
	global randomString
	set lperson [llength $randomPerson]
	set lwords [llength $randomString]
	tcl::mathfunc::srand [clock seconds]
	set r1 [tcl::mathfunc::rand]
	set r2 [tcl::mathfunc::rand]
	set ip [tcl::mathfunc::int [expr $r1*$lperson]]
	set iw [tcl::mathfunc::int [expr $r2*$lwords]]
	set p [lindex $randomPerson $ip]
	set w [lindex $randomString $iw]
	return "$p$w"
}

