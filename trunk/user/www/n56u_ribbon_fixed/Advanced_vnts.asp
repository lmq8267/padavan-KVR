<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - VNTS服务器</title>
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
<% vnts_status(); %>
<% login_state_hook(); %>
$j(document).ready(function() {

	init_itoggle('vnts_enable',change_vnts_enable);
	init_itoggle('vnts_log');
	init_itoggle('vnts_web_enable',change_vnts_web_enable_bridge);
	init_itoggle('vnts_web_wan');
	init_itoggle('vnts_sfinger');
	$j("#tab_vnts_cfg, #tab_vnts_log").click(
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
	show_menu(5, 26, 0);
	show_footer();
	fill_status(vnts_status());
	change_vnts_enable(1);
	change_vnts_web_enable_bridge(1);

}

function change_vnts_web_enable_bridge(mflag){
	var m = document.form.vnts_web_enable[0].checked;
	showhide_div("vnts_web_port_tr", m);
	showhide_div("vnts_web_user_tr", m);
	showhide_div("vnts_web_pass_tr", m);
	showhide_div("vnts_web_wan_tr", m);
}

var arrHashes = ["cfg","log"];
function showTab(curHash) {
	var obj = $('tab_vnts_' + curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
	curHash = '#cfg';
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_vnts_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_vnts_' + arrHashes[i]).show();
		} else {
			$j('#wnd_vnts_' + arrHashes[i]).hide();
			$j('#tab_vnts_' + arrHashes[i]).parents('li').removeClass('active');
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
	$("vnts_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_vnts.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}

function done_validating(action){
	refreshpage();
}

function change_vnts_enable(mflag){
	var m = document.form.vnts_enable.value;
	var is_vnts_enable = (m == "1") ? "重启" : "更新";
	document.form.restartvnts.value = is_vnts_enable;
}
function button_restartvnts() {
    var m = document.form.vnts_enable.value;

    var actionMode = (m == "1") ? ' Restartvnts ' : ' Updatevnts ';

    change_vnts_enable(m); 

    var $j = jQuery.noConflict(); 
    $j.post('/apply.cgi', {
        'action_mode': actionMode 
    });
}

function clearLog(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi', {
		'action_mode': ' ClearvntsLog ',
		'next_host': 'Advanced_vnts.asp#log'
	}).always(function() {
		setTimeout(function() {
			location.reload(); 
		}, 3000);
	});
}

function button_vnts_web(){
	var port = document.form.vnts_web_port.value;
	if (port == '')
	var port = '29870';
	var porturl =window.location.protocol + '//' + window.location.hostname + ":" + port;
	//alert(porturl);
	window.open(porturl,'vnts_web');
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

	<input type="hidden" name="current_page" value="Advanced_vnts.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="VNTS;LANHostConfig;General;">
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
	<h2 class="box_head round_top">VNTS服务器</h2>
	<div class="round_bottom">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a id="tab_vnts_cfg" href="#cfg">基本设置</a></li>
	<li><a id="tab_vnts_log" href="#log">运行日志</a></li>
	</ul>
	</div>
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div id="wnd_vnts_cfg">
	<div class="alert alert-info" style="margin: 10px;">这是<a href="https://github.com/vnt-dev/vnt" target="blank">vnt-cli</a>的服务端。&nbsp;&nbsp;&nbsp;&nbsp;安卓、Windows客户端：<a href="https://github.com/vnt-dev/VntApp" target="blank">VntApp</a><br>
	<div>项目地址：<a href="https://github.com/vnt-dev/vnts" target="blank">github.com/vnt-dev/vnts</a>&nbsp;&nbsp;&nbsp;&nbsp;官网：<a href="https://rustvnt.com" target="blank">rustvnt.com</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群1：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=9aa1l03sqBPU-rMIzJ52gcmjq9HsO0tA&authKey=FFA0UdK6Dg1wAvL4e9FvyEu3DxekIlYp9W4NaQ54DO2dzQM%2BKS3rShUSwt9BN0bL&noverify=0&group_code=1034868233" target="blank">1034868233</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群2：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=H4czBrp-IUxgTJ9wem0eXFHPdADkKTVW&authKey=JXU4v4ZQSXupcHOYUCOVgU0rDUdEe1ZfGVWzRVqRecxXY4cg%2BgfHl7n%2F%2F6nGSDH2&noverify=0&group_code=950473757" target="blank">950473757</a></div>
	<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "vnts_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "vnts_ver_n"); %></span>】 </div>
	
	<span style="color:#FF0000;" class=""></span></div>

	<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr> <th><#running_status#></th>
            <td id="vnts_status" colspan="2"></td>
          </tr>
	<tr id="vnts_enable_tr" >
	<th width="30%">启用vnts</th>
	<td>
	<div class="main_itoggle">
	<div id="vnts_enable_on_of">
	<input type="checkbox" id="vnts_enable_fake" <% nvram_match_x("", "vnts_enable", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_enable", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_enable" id="vnts_enable_1" class="input" value="1" onClick="change_vnts_enable(1);" <% nvram_match_x("", "vnts_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_enable" id="vnts_enable_0" class="input" value="0" onClick="change_vnts_enable(1);" <% nvram_match_x("", "vnts_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	<td>
	<input class="btn btn-success" style="width:150px" type="button" name="restartvnts" value="更新" onclick="button_restartvnts()" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border-top: 0 none;">服务端口</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="5" class="input" size="15" name="vnts_port" id="vnts_port" placeholder="29872" value="<% nvram_get_x("","vnts_port"); %>" onKeyPress="return is_number(this,event);"/>
	&nbsp;<span style="color:#888;">[29872]</span>
	</div>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border-top: 0 none;">token白名单</th>
	<td colspan="3" style="border-top: 0 none;">
	<div class="input-append">
	<textarea maxlength="2048" class="input" name="vnts_token" id="vnts_token" placeholder="" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vnts_token"); %></textarea>
	</div><span style="color:#888;">限制指定token的客户端才可以连接此服务器，留空则没有限制。<br>如有多个token作为白名单请使用换行来进行分隔。</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;">虚拟网关</th>
	<td style="border: 0 none;"><input name="vnts_subnet" placeholder="10.26.0.1" type="text" class="input" id="vnts_subnet" onkeypress="return is_ipaddr(this,event);" value="<% nvram_get_x("","vnts_subnet"); %>" size="32" maxlength="15"/>
	<br /><span style="color:#888;">分配给客户端的虚拟IP网段</span></td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;">子网掩码</th>
	<td style="border: 0 none;">
	<input name="vnts_netmask" type="text" class="input" id="vnts_netmask" placeholder="<% nvram_get_x("","lan_netmask"); %>" onkeypress="return is_ipaddr(this,event);" value="<% nvram_get_x("","vnts_netmask"); %>" size="32" maxlength="15"/>
	<br />
	</td>
	</tr><td colspan="3"></td>
	<tr id="vnts_sfinger_tr" >
	<th style="border-top: 0 none;">启用数据指纹校验</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_sfinger_on_of">
	<input type="checkbox" id="vnts_sfinger_fake" <% nvram_match_x("", "vnts_sfinger", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_sfinger", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_sfinger" id="vnts_sfinger_1" class="input" value="1" <% nvram_match_x("", "vnts_sfinger", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_sfinger" id="vnts_sfinger_0" class="input" value="0" <% nvram_match_x("", "vnts_sfinger", "0", "checked"); %> /><#checkbox_No#>
	</div><span style="color:#888;">启用数据指纹校验后只会转发指纹正确的客户端数据包，增强安全性，但这会损失一部分性能。(启用后客户端也须开启)</span></td>
	</td>
	</tr><td colspan="3"></td>
	<tr id="vnts_web_enable_tr" >
	<th style="border-top: 0 none;">启用WEB页面</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_web_enable_on_of">
	<input type="checkbox" id="vnts_web_enable_fake" <% nvram_match_x("", "vnts_web_enable", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_web_enable", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_web_enable" id="vnts_web_enable_1" class="input" value="1" onClick="change_vnts_web_enable_bridge(1);" <% nvram_match_x("", "vnts_web_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_web_enable" id="vnts_web_enable_0" class="input" value="0" onClick="change_vnts_web_enable_bridge(1);" <% nvram_match_x("", "vnts_web_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr id="vnts_web_port_tr" style="display:none;">
	<th style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;端口:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="5" class="input" size="15" name="vnts_web_port" id="vnts_port" placeholder="29870" value="<% nvram_get_x("","vnts_web_port"); %>" onKeyPress="return is_number(this,event);"/>
	&nbsp;<span style="color:#888;">[29870]</span>
	</div>
	</td>
	<td style="border-top: 0 none;">
	&nbsp;<input class="btn btn-success" style="" type="button" value="打开管理页面" onclick="button_vnts_web()" />
	</td>
	</tr>
	<tr id="vnts_web_user_tr" style="display:none;">
	<th style="border: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;用户名:</th>
	<td style="border: 0 none;"><input name="vnts_web_user" type="text" class="input" id="vnts_web_user" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vnts_web_user"); %>" size="32" maxlength="128" /></td>
	</tr>
	<tr id="vnts_web_pass_tr" style="display:none;">
	<th style="border: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;密码:</th>
	<td style="border: 0 none;">
	<input maxlength="512" type="password" class="input" size="32" name="vnts_web_pass" id="vnts_web_pass" value="<% nvram_get_x("","vnts_web_pass"); %>" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('vnts_web_pass')"><i class="icon-eye-close"></i></button>
	</div>
	</td>
	</tr>
	<tr id="vnts_web_wan_tr" style="display:none;">
	<th style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;启用外网访问:</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_web_wan_on_of">
	<input type="checkbox" id="vnts_web_wan_fake" <% nvram_match_x("", "vnts_web_wan", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_web_wan", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_web_wan" id="vnts_web_wan_1" class="input" value="1" <% nvram_match_x("", "vnts_web_wan", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_web_wan" id="vnts_web_wan_0" class="input" value="0" <% nvram_match_x("", "vnts_web_wan", "0", "checked"); %> /><#checkbox_No#>
	</div>&nbsp;<span style="color:#888;">注意：启用后防火墙将放行WEB端口，公网IP外网将可访问，请慎重选择，须使用强密码，并定期更换！</span>
	</td>
	</tr><td colspan="3"></td>
	</tr>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024"class="input" name="vnts_bin" id="vnts_bin" placeholder="/etc/storage/bin/vnts" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vnts_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr><td colspan="3"></td>
	<tr id="vnts_log_tr" >
	<th style="border-top: 0 none;">启用程序日志</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vnts_log_on_of">
	<input type="checkbox" id="vnts_log_fake" <% nvram_match_x("", "vnts_log", "1", "value=1 checked"); %><% nvram_match_x("", "vnts_log", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vnts_log" id="vnts_log_1" class="input" value="1" <% nvram_match_x("", "vnts_log", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vnts_log" id="vnts_log_0" class="input" value="0" <% nvram_match_x("", "vnts_log", "0", "checked"); %> /><#checkbox_No#>
	</div>
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
	<div id="wnd_vnts_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("vnts.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.reload()" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.href='vnts.log'" value="<#CTL_onlysave#>" class="btn btn-success" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog();" value="清除日志" class="btn btn-info" style="width: 200px">
	</td>
	</tr>
	<br><td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 4px;">
	<span style="color:#888;">🚫注意：日志可能包含部分隐私信息，切勿随意分享！</span>
	</td>
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

