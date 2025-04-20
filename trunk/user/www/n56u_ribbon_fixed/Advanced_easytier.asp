<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - EasyTier</title>
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
<% easytier_status(); %>
<% easytier_web_status(); %>
<% login_state_hook(); %>
$j(document).ready(function() {

	init_itoggle('easytier_web_enable');

	$j("#tab_et_cfg, #tab_et_web, #tab_et_sta, #tab_et_log").click(
	function () {
		var newHash = $j(this).attr('href').toLowerCase();
		showTab(newHash);
		return false;
	});

});

</script>
<script>
var isMenuopen = 0;
function initial(){
	show_banner(2);
	show_menu(5, 32, 0);
	show_footer();
	fill_status(easytier_status());
	fill_statusweb(easytier_web_status());
	change_easytier_enable(1);
	if (!login_safe())
        		textarea_scripts_enabled(0);

}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("easytier_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function fill_statusweb(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("easytier_web_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

var arrHashes = ["cfg","web","sta","log"];
function showTab(curHash) {
	var obj = $('tab_et_' + curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
	curHash = '#cfg';
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_et_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_et_' + arrHashes[i]).show();
		} else {
			$j('#wnd_et_' + arrHashes[i]).hide();
			$j('#tab_et_' + arrHashes[i]).parents('li').removeClass('active');
			}
		}
	window.location.hash = curHash;
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_easytier.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}

function done_validating(action){
	refreshpage();
}

function textarea_scripts_enabled(v){
    	inputCtrl(document.form['scripts.easytier.toml'], v);
}


function change_easytier_enable(mflag){
	var m = document.form.easytier_enable.value;
	var is_easytier_enable = (m == "1" || m == "2") ? "重启" : "更新";
	document.form.restarteasytier.value = is_easytier_enable;

	var is_easytier_file = (m == "2") ? 1 : 0;
	showhide_div("easytier_file_tr", is_easytier_file);
	showhide_div("easytier_file_td", is_easytier_file);
	
	var is_config_server = (m == "1") ? 1 : 0;
	showhide_div("config_server_tr", is_config_server);
	showhide_div("config_server_td", is_config_server);

}

function button_restarteasytier() {
    var m = document.form.easytier_enable.value;

    var actionMode = (m == "1" || m == "2") ? ' Restarteasytier ' : ' Updateeasytier ';

    change_easytier_enable(m); 

    var $j = jQuery.noConflict(); 
    $j.post('/apply.cgi', {
        'action_mode': actionMode 
    });
}

function clearLog(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', {
		'action_mode': ' CleareasytierLog ',
		'next_host': 'Advanced_easytier.asp#log'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_peer(){
	var $j = jQuery.noConflict();
	$j('#btn_peer').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetpeer ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_connector(){
	var $j = jQuery.noConflict();
	$j('#btn_connector').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetconnector ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_stun(){
	var $j = jQuery.noConflict();
	$j('#btn_stun').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetstun ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_route(){
	var $j = jQuery.noConflict();
	$j('#btn_route').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetroute ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_peer_center(){
	var $j = jQuery.noConflict();
	$j('#btn_peer_center').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetpeer_center ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_vpn_portal(){
	var $j = jQuery.noConflict();
	$j('#btn_vpn_portal').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetvpn_portal ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_node(){
	var $j = jQuery.noConflict();
	$j('#btn_node').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetnode ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_proxy(){
	var $j = jQuery.noConflict();
	$j('#btn_proxy').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetproxy ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_et_status() {
	var $j = jQuery.noConflict();
	$j('#btn_status').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' CMDetstatus ',
		'next_host': 'Advanced_easytier.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_etweb(){
	var port = document.form.easytier_html_port.value;
	if (port == '')
	var port = '11210';
	var porturl =window.location.protocol + '//' + window.location.hostname + ":" + port;
	//alert(porturl);
	window.open(porturl,'easytier-web');
}

</script>
</head>

<body onload="initial();" onunLoad="return unload_body();">

<div class="wrapper">
	<div class="container-fluid" style="padding-right: 0px">
	<div class="row-fluid">
	<div class="span3"><center><div id="logo"></div></center></div>
	<div class="span9" >
	<div id="TopBanner"></div>
	</div>
	</div>
	</div>

	<div id="Loading" class="popup_bg"></div>

	<iframe name="hidden_frame" id="hidden_frame" src="" width="0" height="0" frameborder="0"></iframe>

	<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">

	<input type="hidden" name="current_page" value="Advanced_easytier.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="EASYTIER;LANHostConfig;General;">
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
	<h2 class="box_head round_top">EasyTier</h2>
	<div class="round_bottom">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a id="tab_et_cfg" href="#cfg">基本设置</a></li>
	<li><a id="tab_et_web" href="#web">自建WEB</a></li>
	<li><a id="tab_et_sta" href="#sta">运行状态</a></li>
	<li><a id="tab_et_log" href="#log">运行日志</a></li>

	</ul>
	</div>
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div id="wnd_et_cfg">
	<div class="alert alert-info" style="margin: 10px;">
	由 Rust 和 Tokio 驱动✨ 一个简单、安全、去中心化的异地组网方案。<br>
	<div>项目地址：<a href="https://github.com/EasyTier/Easytier" target="blank">github.com/EasyTier/Easytier</a>&nbsp;&nbsp;&nbsp;&nbsp;官网：<a href="https://easytier.cn/" target="blank">easytier.cn</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=6fJoWLm7bKKBHnx0uPKjFBeQz-UVpCVZ&authKey=Zp4K7V7UQfADF6UJdP%2FgoGAhuv%2FT5qGlx%2FZEuQsOmIiiF1p8piy6lfDZnoxTaKH6&noverify=0&group_code=949700262" target="blank">949700262</a></div>
	<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "easytier_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "easytier_ver_n"); %></span>】 </div>
	</div>
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">开关</th>
	</tr>
	<tr>
	<th><#running_status#>
	</th>
	<td id="easytier_status"></td><td></td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用easytier</th>
	<td style="border-top: 0 none;">
	<select name="easytier_enable" class="input" onChange="change_easytier_enable();" style="width: 218px;">
	<option value="0" <% nvram_match_x("","easytier_enable", "0","selected"); %>>【关闭】</option>
	<option value="1" <% nvram_match_x("","easytier_enable", "1","selected"); %>>【开启】WEB配置</option>
	<option value="2" <% nvram_match_x("","easytier_enable", "2","selected"); %>>【开启】配置文件</option>
	</select>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restarteasytier" value="更新" onclick="button_restarteasytier()" />
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">基本设置</th>
	</tr>
	<tr id="easytier_file_tr">
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('scripts.easytier')"><span>点此修改 /etc/storage/easytier.toml 配置文件</span></a>&nbsp;&nbsp;&nbsp;&nbsp;配置文件生成器：<a href="https://easytier.cn/web/index.html#/config_generator" target="blank">点此跳转</a>
	<div id="scripts.easytier" style="display: none;">
	<textarea rows="18" wrap="off" spellcheck="false" maxlength="2097152" class="span12" name="scripts.easytier.toml" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.easytier.toml",""); %></textarea>
	</div>
	</td>
	</tr><tr id="easytier_file_td"><td colspan="3"></td></tr>
	<tr id="config_server_tr">
	<th width="30%" style="border-top: 0 none;" title="-w  配置Web服务器地址。格式：①完整URL： udp://127.0.0.1:22020/admin  ②仅用户名： admin，将使用官方的服务器">Web服务器地址</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="admin" id="easytier_config_server" name="easytier_config_server" value="<% nvram_get_x("","easytier_config_server"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" value="官方Web控制台" onclick="window.open('https://easytier.cn/web', '_blank')" />
	</td>
	</tr><tr id="config_server_td"><td colspan="3"></td></tr>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_bin" id="easytier_bin" placeholder="/etc/storage/bin/easytier-core" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr><td colspan="3"></td>
	<tr id="log_tr"> 
	<th width="30%" style="border-top: 0 none;" title="--console-log-level  控制台日志级别">日志等级</th>
	<td style="border-top: 0 none;">
	<select name="easytier_log" class="input" style="width: 218px;">
	<option value="0" <% nvram_match_x("","easytier_log", "0","selected"); %>>默认</option>
	<option value="1" <% nvram_match_x("","easytier_log", "1","selected"); %>>警告</option>
	<option value="2" <% nvram_match_x("","easytier_log", "2","selected"); %>>信息</option>
	<option value="3" <% nvram_match_x("","easytier_log", "3","selected"); %>>调试</option>
	<option value="4" <% nvram_match_x("","easytier_log", "4","selected"); %>>跟踪</option>
	<option value="5" <% nvram_match_x("","easytier_log", "5","selected"); %>>错误</option>
	</select>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="使用配置文件和WEB控制台时务必填写一致，用于自动放行所需的端口，默认放行ipv4和ipv6的。">端口放行</th>
	<td style="border-top: 0 none;">
	<textarea maxlength="256" class="input" name="easytier_ports" id="easytier_ports" placeholder="11010" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_ports"); %></textarea>
	<br>&nbsp;<span style="color:#888;">多个端口使用换行分隔</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="--dev-name  指定TUN接口名称，使用配置文件和WEB控制台时务必填写一致，用于放行防火墙">TUN网卡名</th>
	<td style="border-top: 0 none;">
	<input name="easytier_tunname" type="text" class="input" id="easytier_tunname" placeholder="tun0" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_tunname"); %>" size="32" maxlength="15" /></td>
	</td>
	</tr>
	</table>
	<tr>
	<td colspan="4" style="border-top: 0 none; padding-bottom: 20px;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr><br>																
	</table>
	</div>
	</div>
	</div>
	<!-- WEB设置 -->
	<div id="wnd_et_web" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
<div class="alert alert-info" style="margin: 10px;">
	自建WEB服务器，需要自行下载easytier-web-embed程序并更名为easytier-web上传并指定路径，也会自动在线下载。<br>
	</div>
	<table id="web_table" width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">开关</th>
	</tr>
	<tr>
	<th><#running_status#>
	</th>
	<td id="easytier_web_status"></td><td></td>
	</tr>
	<tr>
	<th style="border-top: 0 none;">启用WEB</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="easytier_web_enable_on_of">
	<input type="checkbox" id="easytier_web_enable_fake" <% nvram_match_x("", "easytier_web_enable", "1", "value=1 checked"); %><% nvram_match_x("", "easytier_web_enable", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="easytier_web_enable" id="easytier_web_enable_1" class="input" value="1" <% nvram_match_x("", "easytier_web_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="easytier_web_enable" id="easytier_web_enable_0" class="input" value="0" <% nvram_match_x("", "easytier_web_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">基本设置</th>
	</tr>
	<td colspan="2"></td>
	<tr>
	<th style="border: 0 none;" title="-d  sqlite3数据库文件路径, 用于保存所有数据">数据库路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_web_db" id="easytier_web_db" placeholder="/etc/storage/easytier/et.db" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_web_db"); %></textarea>
	</div><br><span style="color:#888;">自定义数据库的存放路径，填写完整的路径和文件名称</span>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="-c  配置服务器的监听端口，用于被 easytier-core 连接">服务端口</th>
	<td style="border-top: 0 none;">
	<input name="easytier_web_port" type="text" class="input" id="easytier_web_port" placeholder="22020" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_web_port"); %>" size="32" maxlength="55" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="-p   配置服务器的监听协议，用于被 easytier-core 连接, 可能的值：udp, tcp">监听协议</th>
	<td style="border-top: 0 none;">
	<input name="easytier_web_protocol" type="text" class="input" id="easytier_web_protocol" placeholder="udp" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_web_protocol"); %>" size="32" maxlength="15" /></td>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="-a  restful 服务器的监听端口，作为 ApiHost 并被 web 前端使用">API端口</th>
	<td style="border-top: 0 none;">
	<input name="easytier_web_api" type="text" class="input" id="easytier_web_api" placeholder="11211" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_web_api"); %>" size="32" maxlength="55" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="-l  web 前端使用的端口">WEB端口</th>
	<td style="border-top: 0 none;">
	<input name="easytier_html_port" type="text" class="input" id="easytier_html_port" placeholder="11210" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","easytier_html_port"); %>" size="32" maxlength="55" />
	&nbsp;<input class="btn btn-success" style="" type="button" value="打开WEB控制台" onclick="button_etweb()" />
	</td>
	</tr><td colspan="3"></td>	
	<tr> 
	<th width="30%" style="border-top: 0 none;" title="--console-log-level  控制台日志级别">日志等级</th>
	<td style="border-top: 0 none;">
	<select name="easytier_web_log" class="input" style="width: 218px;">
	<option value="0" <% nvram_match_x("","easytier_web_log", "0","selected"); %>>默认</option>
	<option value="1" <% nvram_match_x("","easytier_web_log", "1","selected"); %>>警告</option>
	<option value="2" <% nvram_match_x("","easytier_web_log", "2","selected"); %>>信息</option>
	<option value="3" <% nvram_match_x("","easytier_web_log", "3","selected"); %>>调试</option>
	<option value="4" <% nvram_match_x("","easytier_web_log", "4","selected"); %>>跟踪</option>
	<option value="5" <% nvram_match_x("","easytier_web_log", "5","selected"); %>>错误</option>
	</select>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<!-- <th style="border: 0 none;">html路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_web_html" id="easytier_web_html" placeholder="/etc/storage/easytier/web.html" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_web_html"); %></textarea>
	</div><br><span style="color:#888;">自定义前端html的存放路径，填写完整的路径和文件名称</span>
	</tr><td colspan="3"></td> -->
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="easytier_web_bin" id="easytier_web_bin" placeholder="/etc/storage/bin/easytier-web" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","easytier_web_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr>	<td style="border-top: 0 none;">


	<tr>
	<td colspan="5" style="border-top: 0 none; padding-bottom: 20px;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('weblog')"><span>查看WEB日志 /tmp/easytier_web.log</span></a>
	<div id="weblog" style="display: none;">
		<textarea rows="21" class="span12" style="height:219px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("easytier_web.log",""); %></textarea>
	</div>
	</td>
	</tr>
	</table>
	</table>
	</div>
	<!-- 状态 -->
	<div id="wnd_et_sta" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
		<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
			<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("easytier_cmd.log",""); %></textarea>
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center;">
			<!-- 按钮并排显示 -->
			<input class="btn btn-success" id="btn_peer" style="width:100px; margin-right: 10px;" type="button" name="et_peer" value="对等节点信息" onclick="button_et_peer()" />
			<input class="btn btn-success" id="btn_connector" style="width:100px; margin-right: 10px;" type="button" name="et_connector" value="管理连接器" onclick="button_et_connector()" />
		<input class="btn btn-success" id="btn_stun" style="width:100px; margin-right: 10px;" type="button" name="et_stun" value="STUN 测试" onclick="button_et_stun()" />
			<input class="btn btn-success" id="btn_route" style="width:100px; margin-right: 10px;" type="button" name="et_route" value="显示路由信息" onclick="button_et_route()" />
			<input class="btn btn-success" id="btn_peer_center" style="width:100px; margin-right: 10px;" type="button" name="et_peer_center" value="全局对等信息" onclick="button_et_peer_center()" />
			<input class="btn btn-success" id="btn_vpn_portal" style="width:100px; margin-right: 10px;" type="button" name="et_vpn_portal" value="WireGuard信息" onclick="button_et_vpn_portal()" />
			<input class="btn btn-success" id="btn_node" style="width:100px; margin-right: 10px;" type="button" name="et_node" value="本机核心信息" onclick="button_et_node()" />
			<input class="btn btn-success" id="btn_proxy" style="width:100px; margin-right: 10px;" type="button" name="et_proxy" value="TCP/KCP代理" onclick="button_et_proxy()" />
			<input class="btn btn-success" id="btn_status" style="width:100px; margin-right: 10px;" type="button" name="et_status" value="运行状态信息" onclick="button_et_status()" />
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 5px;">
			<span style="color:#888;">🔄 点击上方按钮刷新查看</span>
		</td>
	</tr>
	</table>
	</div>

	<!-- 日志 -->
	<div id="wnd_et_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("easytier.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.reload()" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.href='easytier.log'" value="<#CTL_onlysave#>" class="btn btn-success" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog();" value="清除日志" class="btn btn-info" style="width: 200px">
	</td>
	</tr>
	<br><td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 4px;">
	<span style="color:#888;">🚫注意：日志可能包含一些隐私信息，切勿随意分享！</span>
	</td>
	</table>
	</div>

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

