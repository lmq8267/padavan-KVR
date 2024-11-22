<!DOCTYPE html>
<!--Copyright by hiboy-->
<html>
<head>
<title><#Web_Title#> - Alist-文件列表</title>
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
<script type="text/javascript" src="/itoggle.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();

$j(document).ready(function() {
	init_itoggle('alist_enable',change_alist_enable);
	init_itoggle('alist_https');
	init_itoggle('alist_log_enable',change_alist_log_enable_bridge);
	init_itoggle('alist_log_compress');
	init_itoggle('alist_s3',change_alist_s3_bridge);
	init_itoggle('alist_s3_ssl');
	init_itoggle('alist_upx');
	$j("#tab_alist_cfg, #tab_alist_log").click(
	function () {
		var newHash = $j(this).attr('href').toLowerCase();
		showTab(newHash);
		return false;
	});

});

</script>
<script>
<% alist_status(); %>
<% login_state_hook(); %>
function initial(){
	show_banner(2);
	show_menu(5, 30, 0);
	show_footer();
	fill_status(alist_status());
	change_alist_enable();
	if (!login_safe())
        		$j('#btn_exec').attr('disabled', 'disabled');

}

function change_alist_log_enable_bridge(mflag){
	var m = document.form.alist_log_enable[0].checked;
	showhide_div("log_size_tr", m);
	showhide_div("log_size_td", m);
	showhide_div("log_name_tr", m);
	showhide_div("log_compress_tr", m);
}

function change_alist_s3_bridge(mflag){
	var m = document.form.alist_s3[0].checked;
	showhide_div("s3_port_tr", m);
	showhide_div("s3_ssl_tr", m);
}

var arrHashes = ["cfg","log"];
function showTab(curHash) {
	var obj = $('tab_alist_' + curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
	curHash = '#cfg';
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_alist_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_alist_' + arrHashes[i]).show();
		} else {
			$j('#wnd_alist_' + arrHashes[i]).hide();
			$j('#tab_alist_' + arrHashes[i]).parents('li').removeClass('active');
			}
		}
	window.location.hash = curHash;
}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("alist_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_alist.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}

function done_validating(action){
	refreshpage();
}

function change_alist_enable(mflag){
	var m = document.form.alist_enable.value;
	var is_alist_enable = (m == "1") ? "重启" : "更新";
	document.form.restartalist.value = is_alist_enable;
}
function button_restartalist() {
    var m = document.form.alist_enable.value;

    var actionMode = (m == "1") ? ' Restartalist ' : ' Updatealist ';

    change_alist_enable(m); 

    var $j = jQuery.noConflict(); 
    $j.post('/apply.cgi', {
        'action_mode': actionMode 
    });
}

function resetpass(){
	if (!login_safe())
		return false;
	$j('#btn_exec').attr('disabled', 'disabled');
	$j.post('/apply.cgi',
	{
		'action_mode': ' AlistReset ',
		'current_page': 'Advanced_alist.asp#log',
		'next_page': 'Advanced_alist.asp#log',
	})
	
	.done(function(response) {
		if (response.sys_result === 1) {
			alert(response.message); 
		} else {
			alert(response.message);
		}
	})
	.fail(function(xhr, status, error) {
		alert("请求失败，请重试！");
	})
	.always(function() {
		$('#btn_exec').removeAttr('disabled');
	});
}

function button_alist(){
	var port = document.form.alist_port.value;
	if (port == '')
	var port = '5244';
	var porturl =window.location.protocol + '//' + window.location.hostname + ":" + port;
	//alert(porturl);
	window.open(porturl,'alist');
}

function clearLog(){
	document.form.current_page.value = "Advanced_alist.asp#log";
	document.form.next_host.value = "Advanced_alist.asp#log";
	document.form.action_mode.value = " ClearalistLog ";
	document.form.submit();
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

	<input type="hidden" name="current_page" value="Advanced_alist.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="ALIST;LANHostConfig;General;">
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
	<h2 class="box_head round_top">Alist 文件列表</h2>
	<div class="round_bottom">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a id="tab_alist_cfg" href="#cfg">基本设置</a></li>
	<li><a id="tab_alist_log" href="#log">运行日志</a></li>
	</ul>
	</div>
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div id="wnd_alist_cfg">
	<div class="alert alert-info" style="margin: 10px;">🗂️ 一个支持多种存储的文件列表程序，使用 Gin 和 Solidjs。
	<div>项目地址：<a href="https://github.com/AlistGo/alist" target="blank">https://github.com/AlistGo/alist</a></div>
	<div>官方文档：<a href="https://alist.nn.ci/zh/" target="blank">https://alist.nn.ci/zh/</a></div>
  		<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "alist_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "alist_ver_n"); %></span>】
	</div>
	<span style="color:#FF0000;" class=""></span></div>
	<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">开关</th>
	</tr>
	<tr>
	<th><#running_status#>
	</th>
	<td id="alist_status"></td>
	</tr>
	<tr>
	<th>启用Alist</th>
	<td>
	<div class="main_itoggle">
	<div id="alist_enable_on_of">
	<input type="checkbox" id="alist_enable_fake" <% nvram_match_x("", "alist_enable", "1", "value=1 checked"); %><% nvram_match_x("", "alist_enable", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="alist_enable" id="alist_enable_1" class="input" value="1" onClick="change_alist_enable(1);" <% nvram_match_x("", "alist_enable", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="alist_enable" id="alist_enable_0" class="input" value="0" onClick="change_alist_enable(1);" <% nvram_match_x("", "alist_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	<td colspan="4">
	<input class="btn btn-success" style="width:150px" type="button" name="restartalist" value="更新" onclick="button_restartalist()" />
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">全局配置</th>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">网站URL</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="256" class="input" size="15" placeholder="" id="alist_site_url" name="alist_site_url" value="<% nvram_get_x("","alist_site_url"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">CDN地址</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="256" class="input" size="15" placeholder="" id="alist_cdn" name="alist_cdn" value="<% nvram_get_x("","alist_cdn"); %>" onKeyPress="return is_string(this,event);" />
	<br>&nbsp;<span style="color:#888;">链接结尾请勿携带 /</span></div>
	</td>
	</tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">登录过期时间</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_expires" maxlength="10" class="input" placeholder="48" size="5" value="<% nvram_get_x("","alist_expires"); %>" onkeypress="return is_number(this,event);"/> 
          &nbsp;<span style="color:#888;">小时</span></div>
	</td>
          </tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">数据库配置</th>
	</tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">数据库类型</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_sqlite" maxlength="20" class="input" placeholder="sqlite3" size="5" value="<% nvram_get_x("","alist_sqlite"); %>" onkeypress="return is_number(this,event);"/> 
	</td>
          </tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">数据库路径</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_db_file" maxlength="1024" class="input" placeholder="/etc/storage/alist/data.db" size="5" value="<% nvram_get_x("","alist_db_file"); %>" onkeypress="return is_number(this,event);"/> 
	<br>&nbsp;<span style="color:#888;">sqlite3使用的</span></div></td>
          </tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">远程数据库地址</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="256" class="input" size="15" placeholder="" id="alist_sqlite_host" name="alist_sqlite_host" value="<% nvram_get_x("","alist_sqlite_host"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">远程数据库端口</th>
          <td style="border-top: 0 none;">
          <input type="number" name="alist_sqlite_port" maxlength="5" class="input" placeholder="0" size="5" min="0" max="65535" value="<% nvram_get_x("","alist_sqlite_port"); %>" onkeypress="return is_number(this,event);"/> 
	</td>
          </tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">远程数据库用户名</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="50" class="input" size="15" placeholder="" id="alist_sqlite_user" name="alist_sqlite_user" value="<% nvram_get_x("","alist_sqlite_user"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">远程数据库密码</th>
	<td style="border-top: 0 none;">
		<input type="password" maxlength="128" class="input" size="15" id="alist_sqlite_pass" name="alist_sqlite_pass" style="width: 175px;" value="<% nvram_get_x("","alist_sqlite_pass"); %>" onKeyPress="return is_string(this,event);" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('alist_sqlite_pass')"><i class="icon-eye-close"></i></button>
	</td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">远程数据库名</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="128" class="input" size="15" placeholder="" id="alist_sqlite_name" name="alist_sqlite_name" value="<% nvram_get_x("","alist_sqlite_name"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">远程数据库表名前缀</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="128" class="input" size="15" placeholder="x_" id="alist_sqlite_tab" name="alist_sqlite_tab" value="<% nvram_get_x("","alist_sqlite_tab"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">访问配置</th>
	</tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">监听地址</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_address" maxlength="256" class="input" placeholder="0.0.0.0" size="5" value="<% nvram_get_x("","alist_address"); %>" onkeypress="return is_number(this,event);"/> 
	</td>
          </tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">http端口</th>
          <td style="border-top: 0 none;">
          <input type="number" name="alist_port" maxlength="5" class="input" placeholder="5244" size="5" min="-1" max="65535" value="<% nvram_get_x("","alist_port"); %>" onkeypress="return is_number(this,event);"/> 
	&nbsp;<span style="color:#888;">-1 禁用</span></td><td style="border-top: 0 none;">
	&nbsp;<input class="btn btn-success" style="" type="button" value="打开WEB界面" onclick="button_alist()" />
	</td>
          </tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">https端口</th>
          <td style="border-top: 0 none;">
          <input type="number" name="alist_sport" maxlength="5" class="input" placeholder="-1" size="5" min="-1" max="65535" value="<% nvram_get_x("","alist_sport"); %>" onkeypress="return is_number(this,event);"/> 
	&nbsp;<span style="color:#888;">-1 禁用</span>
	</td>
          </tr>
	<tr>
	<th style="border-top: 0 none;">强制https</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="alist_https_on_of">
	<input type="checkbox" id="alist_https_fake" <% nvram_match_x("", "alist_https", "1", "value=1 checked"); %><% nvram_match_x("", "alist_https", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="alist_https" id="alist_https_1" class="input" value="1" <% nvram_match_x("", "alist_https", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="alist_https" id="alist_https_0" class="input" value="0" <% nvram_match_x("", "alist_https", "0", "checked"); %> /><#checkbox_No#>
	</div><br>&nbsp;<span style="color:#888;">强制使用 HTTPS 协议,只能通过 HTTPS 访问</span></div>
	</td>
	</tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">证书路径</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_cert" maxlength="256" class="input" placeholder="/etc/storage/alist/cert.crt" size="5" value="<% nvram_get_x("","alist_cert"); %>" onkeypress="return is_number(this,event);"/> 
	</td>
          </tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">证书密钥路径</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_key" maxlength="256" class="input" placeholder="/etc/storage/alist/key.key" size="5" value="<% nvram_get_x("","alist_key"); %>" onkeypress="return is_number(this,event);"/> 
	</td>
          </tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">目录配置</th>
	</tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">缓存目录</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_temp" maxlength="256" class="input" placeholder="/tmp/temp" size="5" value="<% nvram_get_x("","alist_temp"); %>" onkeypress="return is_number(this,event);"/> 
	</td>
          </tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">索引目录</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_bleve" maxlength="256" class="input" placeholder="/etc/storage/alist/bleve" size="5" value="<% nvram_get_x("","alist_bleve"); %>" onkeypress="return is_number(this,event);"/> 
	</td>
          </tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">日志配置</th>
	</tr>
	<tr>
	<th style="border-top: 0 none;">启用日志</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="alist_log_enable_on_of">
	<input type="checkbox" id="alist_log_enable_fake" <% nvram_match_x("", "alist_log_enable", "1", "value=1 checked"); %><% nvram_match_x("", "alist_log_enable", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="alist_log_enable" id="alist_log_enable_1" class="input" value="1" onClick="change_alist_log_enable_bridge(1);" <% nvram_match_x("", "alist_log_enable", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="alist_log_enable" id="alist_log_enable_0" class="input" value="0" onClick="change_alist_log_enable_bridge(1);" <% nvram_match_x("", "alist_log_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr id="log_size_tr" style="display:none;">
          <th width="30%" style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;日志大小</th>
          <td style="border-top: 0 none;">
          <input type="number" name="alist_log_size" maxlength="2" class="input" placeholder="10" size="5" min="1" max="99" value="<% nvram_get_x("","alist_log_size"); %>" onkeypress="return is_number(this,event);"/> 
	&nbsp;<span style="color:#888;">MB</span></div></td>
          </tr>
	<tr id="log_name_tr" style="display:none;">
          <th width="30%" style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;日志路径</th>
          <td style="border-top: 0 none;">
          <input type="text" name="alist_log_name" maxlength="100" class="input" placeholder="/tmp/alist.log" size="5" value="<% nvram_get_x("","alist_log_name"); %>" onkeypress="return is_number(this,event);"/> 
	</td>
          </tr>
	<tr id="log_compress_tr" style="display:none;">
	<th style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;压缩日志</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="alist_log_compress_on_of">
		<input type="checkbox" id="alist_log_compress_fake" <% nvram_match_x("", "alist_log_compress", "1", "value=1 checked"); %><% nvram_match_x("", "alist_log_compress", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="alist_log_compress" id="alist_log_compress_1" class="input" value="1" <% nvram_match_x("", "alist_log_compress", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="alist_log_compress" id="alist_log_compress_0" class="input" value="0" <% nvram_match_x("", "alist_log_compress", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">启动配置</th>
	</tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">延时启动</th>
          <td style="border-top: 0 none;">
          <input type="number" name="alist_delayed" maxlength="5" class="input" placeholder="0" size="5" min="0" value="<% nvram_get_x("","alist_delayed"); %>" onkeypress="return is_number(this,event);"/> 
	&nbsp;<span style="color:#888;">秒</span></div></td>
          </tr>
	<tr>
          <th width="30%" style="border-top: 0 none;">最大连接数</th>
          <td style="border-top: 0 none;">
          <input type="number" name="alist_connections" maxlength="5" class="input" placeholder="0" size="5" min="0" value="<% nvram_get_x("","alist_connections"); %>" onkeypress="return is_number(this,event);"/> 
	<br>&nbsp;<span style="color:#888;">同时最多的连接数(并发)，默认为 0 即不限制.</span></div></td>
          </tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">S3配置</th>
	</tr>
	<tr>
	<th style="border-top: 0 none;">启用S3存储</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="alist_s3_on_of">
	<input type="checkbox" id="alist_s3_fake" <% nvram_match_x("", "alist_s3", "1", "value=1 checked"); %><% nvram_match_x("", "alist_s3", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="alist_s3" id="alist_s3_1" class="input" value="1" onClick="change_alist_s3_bridge(1);" <% nvram_match_x("", "alist_s3", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="alist_s3" id="alist_s3_0" class="input" value="0" onClick="change_alist_s3_bridge(1);" <% nvram_match_x("", "alist_s3", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr id="s3_port_tr" style="display:none;">
          <th width="30%" style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;端口号</th>
          <td style="border-top: 0 none;">
          <input type="number" name="alist_s3_port" maxlength="5" class="input" placeholder="5246" size="5" min="1" max="65535" value="<% nvram_get_x("","alist_s3_port"); %>" onkeypress="return is_number(this,event);"/> 
          </tr>
	<tr id="s3_ssl_tr" style="display:none;">
	<th style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;启用https</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="alist_s3_ssl_on_of">
	<input type="checkbox" id="alist_s3_ssl_fake" <% nvram_match_x("", "alist_s3_ssl", "1", "value=1 checked"); %><% nvram_match_x("", "alist_s3_ssl", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="alist_s3_ssl" id="alist_s3_ssl_1" class="input" value="1" <% nvram_match_x("", "alist_s3_ssl", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="alist_s3_ssl" id="alist_s3_ssl_0" class="input" value="0" <% nvram_match_x("", "alist_s3_ssl", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">其他配置</th>
	</tr>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
		<textarea maxlength="1024"class="input" name="alist_bin" id="alist_bin" placeholder="/tmp/alist" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","alist_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr>
	<tr>
	<th style="border-top: 0 none;">下载压缩程序</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="alist_upx_on_of">
	<input type="checkbox" id="alist_upx_fake" <% nvram_match_x("", "alist_upx", "1", "value=1 checked"); %><% nvram_match_x("", "alist_upx", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="alist_upx" id="alist_upx_1" class="input" value="1" <% nvram_match_x("", "alist_upx", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="alist_upx" id="alist_upx_0" class="input" value="0" <% nvram_match_x("", "alist_upx", "0", "checked"); %> /><#checkbox_No#>
	</div><br><span style="color:#888;">在线下载程序，官方原版（接近80M），启用后下载UPX压缩版（接近30M）</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td>
	</tr>
	
	</table>
	</div>
	</div>
	</div>
	<div id="wnd_alist_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
		<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("alist.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.reload()" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" id="btn_exec" onClick="resetpass();" value="重置密码" class="btn btn-success" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog();" value="清除日志" class="btn btn-info" style="width: 200px">
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

