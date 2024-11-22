<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - 皎月连一键内网穿透</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">

<link rel="shortcut icon" href="images/favicon.ico">
<link rel="icon" href="images/favicon.png">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/bootstrap.min.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/main.css">
<link rel="stylesheet" type="text/css" href="/bootstrap/css/engage.itoggle.css">

<script type="text/javascript" src="/jquery.js"></script>
<script type="text/javascript" src="/bootstrap/js/bootstrap.min.js"></script>
<script type="text/javascript" src="/bootstrap/js/engage.itoggle.min.js"></script>
<script type="text/javascript" src="/state.js"></script>
<script type="text/javascript" src="/general.js"></script>
<script type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();

<% natpierce_status(); %>
$j(document).ready(function() {

	init_itoggle('natpierce_enable');
	$j("#tab_natpierce_cfg, #tab_natpierce_log").click(
	function () {
		var newHash = $j(this).attr('href').toLowerCase();
		showTab(newHash);
		return false;
	});

});

</script>
<script>

function initial(){
	show_banner(2);
	show_menu(5,28,0);
	fill_status(natpierce_status());
	show_footer();

}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("natpierce_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

var arrHashes = ["cfg","log"];
function showTab(curHash) {
	var obj = $('tab_natpierce_' + curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
	curHash = '#cfg';
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_natpierce_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_natpierce_' + arrHashes[i]).show();
		} else {
			$j('#wnd_natpierce_' + arrHashes[i]).hide();
			$j('#tab_natpierce_' + arrHashes[i]).parents('li').removeClass('active');
			}
		}
	window.location.hash = curHash;
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_natpierce.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}


function done_validating(action){
	refreshpage();
}

function button_restartJYL(){
    	var $j = jQuery.noConflict();
    	$j.post('/apply.cgi',
    	{
        		'action_mode': ' RestartJYL ',
    	});
}

</script>
</head>

<body onload="initial();" onunLoad="return unload_body();">

<div id="Loading" class="popup_bg"></div>

<div class="wrapper">
	<div class="container-fluid" style="padding-right: 0px">
		<div class="row-fluid">
			<div class="span3"><center><div id="logo"></div></center></div>
			<div class="span9" >
				<div id="TopBanner"></div>
			</div>
		</div>
	</div>

	<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>

	<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">

	<input type="hidden" name="current_page" value="Advanced_natpierce.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="NATPIERCE;LANHostConfig;General;">
	<input type="hidden" name="group_id" value="">
	<input type="hidden" name="action_mode" value="">
	<input type="hidden" name="action_script" value="">
	
	<div class="container-fluid">
	<div class="row-fluid">
	<div class="span3">
	<!--Sidebar content-->
	<!--=====Beginning of Main Menu=====-->
	<div class="well sidebar-nav side_nav" style="padding: 0px;">
	<ul id="mainMenu" class="clearfix"></ul>
	<ul class="clearfix">
	<li>
	<div id="subMenu" class="accordion"></div>
	</li>
	</ul>
	</div>
	</div>
	<div class="span9">
	<!--Body content-->
	<div class="row-fluid">
	<div class="span12">
	<div class="box well grad_colour_dark_blue">
	<h2 class="box_head round_top">皎月连</h2>
	<div class="round_bottom">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a id="tab_natpierce_cfg" href="#cfg">基本设置</a></li>
	<li><a id="tab_natpierce_log" href="#log">运行日志</a></li>
	</ul>
	</div>
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div id="wnd_natpierce_cfg">
	<div class="alert alert-info" style="margin: 10px;">
	皎月连一键内网穿透可应用于家庭摄像头直连、NAS访问、远程控制或远程游戏联机、串流等各种应用场景<br>
	<div>【官网】：<a href="https://www.natpierce.cn/" target="blank">www.natpierce.cn</a>&nbsp;&nbsp;【皎月连官方交流群】：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=tJWahgBG-seTFayorJLLekwyx31lnyh1&authKey=2sNj03o1Mba%2FeKcsC%2FYYLgCOmBG1Fnx7CqbVOmir8ODxJ68SfjsqIQZEotcNRT4g&noverify=0&group_code=376940436" target="blank">376940436</a></div>
	
	</div>
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th><#running_status#>
	</th>
	<td colspan="4" id="natpierce_status"></td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用皎月连</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="natpierce_enable_on_of">
		<input type="checkbox" id="natpierce_enable_fake" <% nvram_match_x("", "natpierce_enable", "1", "value=1 checked"); %><% nvram_match_x("", "natpierce_enable", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="natpierce_enable" id="natpierce_enable_1" class="input" value="1" <% nvram_match_x("", "natpierce_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="natpierce_enable" id="natpierce_enable_0" class="input" value="0" <% nvram_match_x("", "natpierce_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restartJYL" value="重启" onclick="button_restartJYL()" />
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">访问端口</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="5" class="input" size="15" name="natpierce_port" id="natpierce_port" placeholder="33272" value="<% nvram_get_x("","natpierce_port"); %>" onKeyPress="return is_number(this,event);"/>
	&nbsp;<span style="color:#888;">[33272]</span>
	</div>
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">管理界面:</th>
	<td style="border-top: 0 none;"><a href="<% nvram_get_x("", "natpierce_login"); %>"><% nvram_get_x("", "natpierce_login"); %></a>
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">程序路径</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<textarea maxlength="1024" class="input" name="natpierce_bin" id="natpierce_bin" placeholder="/tmp/jyl/natpierce" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","natpierce_bin"); %></textarea>
	</div><span style="color:#888;">指定natpierce程序路径和程序名</span>
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">程序链接</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<textarea maxlength="1024" class="input" name="natpierce_url" id="natpierce_url" placeholder="https://natpierce.oss-cn-beijing.aliyuncs.com/linux/natpierce-mipsel-v1.03.tar.gz" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","natpierce_url"); %></textarea>
	</div><span style="color:#888;">下载地址：<a href="https://www.natpierce.cn/pc/downloads/index_new.html" target="blank">Linux二进制文件</a>&nbsp;&nbsp;选 mipsel 右键复制链接</span>
	</td>
	</tr>			
	<tr>
	<td colspan="4">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr>																	
	</table>
	</div>
	</div>
	
	</div>
	<div id="wnd_natpierce_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("natpierce.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.reload()" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	</tr>
	</table>
	</div>
	</div>
	</div>
	</div>
	</div>
	</div>
	</form>
	<div id="footer"></div>
	</div>
</body>

</html>
