<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - v2RayA</title>
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
<% v2raya_status(); %>
<% login_state_hook(); %>
$j(document).ready(function() {

	init_itoggle('v2raya_enable',change_v2raya_enable);

	$j("#tab_v2_cfg, #tab_v2_sta, #tab_v2_log").click(
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
	show_menu(5, 35, 0);
	show_footer();
	fill_status(v2raya_status());
	change_v2raya_enable(1);
	if (!login_safe())
        		$j('#btn_password').attr('disabled', 'disabled');

}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("v2raya_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}


var arrHashes = ["cfg","sta","log"];
function showTab(curHash) {
	var obj = $('tab_v2_' + curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
	curHash = '#cfg';
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_v2_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_v2_' + arrHashes[i]).show();
		} else {
			$j('#wnd_v2_' + arrHashes[i]).hide();
			$j('#tab_v2_' + arrHashes[i]).parents('li').removeClass('active');
			}
		}
	window.location.hash = curHash;
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_v2raya.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}

function done_validating(action){
	refreshpage();
}

//function textarea_scripts_enabled(v){
    	//inputCtrl(document.form['scripts.v2raya.toml'], v);
//}


function change_v2raya_enable(mflag){
	var m = document.form.v2raya_enable.value;
	var is_v2raya_enable = (m == "1") ? "重启" : "更新";
	document.form.restartv2raya.value = is_v2raya_enable;
}

function button_restartv2raya() {
    var m = document.form.v2raya_enable.value;

    var actionMode = (m == "1") ? ' Restartv2raya ' : ' Updatev2raya ';

    change_v2raya_enable(m); 

    var $j = jQuery.noConflict(); 
    $j.post('/apply.cgi', {
        'action_mode': actionMode 
    });
}

function clearLog(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', {
		'action_mode': ' Clearv2rayaLog ',
		'next_host': 'Advanced_v2raya.asp#log'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_v2_password(){
	if (!login_safe())
		return false;
	var $j = jQuery.noConflict();
	$j('#btn_password').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' v2rayaRESET ',
		'next_host': 'Advanced_v2raya.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_v2_config(){
	var $j = jQuery.noConflict();
	$j('#btn_config').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' v2rayaConfig ',
		'next_host': 'Advanced_v2raya.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_v2_connection(){
	var $j = jQuery.noConflict();
	$j('#btn_connection').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' v2rayaConnection ',
		'next_host': 'Advanced_v2raya.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_v2_kernel(){
	var $j = jQuery.noConflict();
	$j('#btn_kernel').attr('disabled', 'disabled');
	$j.post('/apply.cgi', {
		'action_mode': ' v2rayaKernel ',
		'next_host': 'Advanced_v2raya.asp#sta'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
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

	<input type="hidden" name="current_page" value="Advanced_v2raya.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="V2RAYA;LANHostConfig;General;">
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
	<h2 class="box_head round_top">v2RayA</h2>
	<div class="round_bottom">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a id="tab_v2_cfg" href="#cfg">基本配置</a></li>
	<li><a id="tab_v2_sta" href="#sta">配置报告</a></li>
	<li><a id="tab_v2_log" href="#log">运行日志</a></li>
	</ul>
	</div>
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div id="wnd_v2_cfg">
	<div class="alert alert-info" style="margin: 10px;">
	v2RayA 是一个支持全局透明代理的 V2Ray 客户端，同时兼容 SS、SSR、Trojan(trojan-go)、Tuic 与 <a href="https://github.com/juicity" target="blank">Juicity</a>协议。 <a href="https://github.com/v2rayA/dist/shadowsocksR/blob/master/README.md#ss-encrypting-algorithm" target="blank"> [SSR支持清单]</a><br>
	v2RayA 致力于提供最简单的操作，满足绝大部分需求。<br>
	<div>项目地址：<a href="https://github.com/v2rayA/v2rayA" target="blank">https://github.com/v2rayA/v2rayA</a>&nbsp;&nbsp;&nbsp;&nbsp;官网文档：<a href="https://v2raya.org/" target="blank">https://v2raya.org/</a></div>
	<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "v2raya_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "v2raya_ver_n"); %></span>】 </div>
	</div>
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">开关</th>
	</tr>
	<tr>
	<th><#running_status#>
	</th>
	<td id="v2raya_status"></td><td></td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用v2RayA</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="v2raya_enable_on_of">
	<input type="checkbox" id="v2raya_enable_fake" <% nvram_match_x("", "v2raya_enable", "1", "value=1 checked"); %><% nvram_match_x("", "v2raya_enable", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="v2raya_enable" id="v2raya_enable_1" class="input" value="1" onClick="change_v2raya_enable(1);" <% nvram_match_x("", "v2raya_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="v2raya_enable" id="v2raya_enable_0" class="input" value="0" onClick="change_v2raya_enable(1);" <% nvram_match_x("", "v2raya_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restartv2raya" value="更新" onclick="button_restartv2raya()" />
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">参数设置</th>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="web服务监听地址（默认 0.0.0.0:2017）">监听地址</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="0.0.0.0:2017" id="v2raya_address" name="v2raya_address" value="<% nvram_get_x("","v2raya_address"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" value="Web界面" onclick="window.open('http://<% nvram_get_x("", "v2raya_web"); %>', '_blank')" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="v2rayA 的配置文件目录">v2rayA配置目录</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_config" id="v2raya_config" placeholder="/etc/storage/v2raya_config" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_config"); %></textarea>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="额外的 v2ray 配置目录，其中的文件将与 v2rayA 生成的配置文件合并">v2ray配置目录</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_confdir" id="v2raya_confdir" placeholder="/etc/storage/v2raya_config" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_confdir"); %></textarea>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="v2ray-core 资源目录，用于搜索和下载如 geoip.dat 等文件和存放v2ray-core拓展规则库 .dat 等文件的目录">资源目录</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_assetsdir" id="v2raya_assetsdir" placeholder="/etc/storage/v2raya_config" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_assetsdir"); %></textarea>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="在透明代理生命周期中运行的可执行文件。v2rayA 将传递 --transparent-type (tproxy, redirect) 和 --stage (pre-start, post-start, pre-stop, post-stop) 参数">透明代理hook</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_transparent" id="v2raya_transparent" placeholder="/etc/storage/v2raya_config/transparent-hook.sh" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_transparent"); %></textarea>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="在 v2ray-core 生命周期中运行的可执行文件。v2rayA 将传递 --stage (pre-start, post-start, pre-stop, post-stop) 参数">核心hook</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_core_hook" id="v2raya_core_hook" placeholder="/etc/storage/v2raya_config/core-hook.sh" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_core_hook"); %></textarea>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="在 v2ray-core 生命周期中运行的插件管理程序。v2rayA 将传递 --stage (pre-start, post-start, pre-stop, post-stop) 参数">插件管理器</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_plugin" id="v2raya_plugin" placeholder="/etc/storage/v2raya_config/plugin-manager.sh" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_plugin"); %></textarea>
	</tr><td colspan="3"></td>
	<tr> 
	<th width="30%" style="border-top: 0 none;" title="确保您的固件支持 IPv6 网络正常工作后再开启此选项">IPV6支持</th>
	<td style="border-top: 0 none;">
	<select name="v2raya_ipv6" class="input" style="width: 218px;">
	<option value="auto" <% nvram_match_x("","v2raya_ipv6", "auto","selected"); %>>auto</option>
	<option value="on" <% nvram_match_x("","v2raya_ipv6", "on","selected"); %>>on</option>
	<option value="off" <% nvram_match_x("","v2raya_ipv6", "off","selected"); %>>off</option>
	</select>
	</td>
	</tr><td colspan="3"></td>
	<tr> 
	<th width="30%" style="border-top: 0 none;">日志等级</th>
	<td style="border-top: 0 none;">
	<select name="v2raya_log" class="input" style="width: 218px;">
	<option value="info" <% nvram_match_x("","v2raya_log", "info","selected"); %>>info</option>
	<option value="trace" <% nvram_match_x("","v2raya_log", "trace","selected"); %>>trace</option>
	<option value="debug" <% nvram_match_x("","v2raya_log", "debug","selected"); %>>debug</option>
	<option value="warn" <% nvram_match_x("","v2raya_log", "warn","selected"); %>>warn</option>
	<option value="error" <% nvram_match_x("","v2raya_log", "error","selected"); %>>error</option>
	</select>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="主程序v2raya的路径，不是单独目录要包含程序名，填写绝对路径">主程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_bin" id="v2raya_bin" placeholder="/etc/storage/bin/v2raya" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义v2raya的存放路径，填写完整的路径和程序名称</span>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="可执行的 v2ray 二进制文件路径。如果留空，将自动检测">v2ray路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_v2ray" id="v2raya_v2ray" placeholder="/etc/storage/bin/v2ray" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_v2ray"); %></textarea>
	</div><br><span style="color:#888;">自定义v2ray的存放路径，填写完整的路径和程序名称</span>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="在以上基础上增加额外命令行启动参数">额外参数</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_cmd" id="v2raya_cmd" placeholder="--passcheckroot --log-max-days 1" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_cmd"); %></textarea>
	</div>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;" title="在以上参数留空，增加自定义环境变量">环境变量</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024" class="input" name="v2raya_env" id="v2raya_env" placeholder="V2RAYA_PLUGINLISTENPORT=32346" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","v2raya_env"); %></textarea>
	</div><br><span style="color:#888;">如果有多个请使用换行进行分隔</span>
	</div>
	</tr><td colspan="3"></td>
	
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
	
	<!-- 配置报告 -->
	<div id="wnd_v2_sta" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
		<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
			<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("v2raya_repo.log",""); %></textarea>
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center;">
			<input class="btn btn-success" id="btn_config" style="width:100px; margin-right: 10px;" type="button" name="v2_config" value="配置信息" onclick="button_v2_config()" />
			<input class="btn btn-success" id="btn_connection" style="width:100px; margin-right: 10px;" type="button" name="v2_connection" value="连接信息" onclick="button_v2_connection()" />
			<input class="btn btn-success" id="btn_kernel" style="width:100px; margin-right: 10px;" type="button" name="v2_kernel" value="内核信息" onclick="button_v2_kernel()" />
			<input class="btn btn-success" id="btn_password" style="width:100px; margin-right: 10px;" type="button" name="v2_password" value="重置密码" onclick="button_v2_password()" />
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 5px;">
			<span style="color:#888;">🔄 点击上方按钮刷新查看,重置密码将会重启一次插件</span>
		</td>
	</tr>
	</table>
	</div>

	<!-- 日志 -->
	<div id="wnd_v2_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("v2raya.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.reload()" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog();" value="清除日志" class="btn btn-info" style="width: 200px">
	</td>
	</tr>
	<br><td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 4px;">
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


