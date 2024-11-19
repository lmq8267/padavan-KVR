<!DOCTYPE html>
<!--Copyright by hiboy-->
<html>
<head>
<title><#Web_Title#> - Tailsale</title>
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
<% tailscale_status(); %>
<% tailscaled_status(); %>
$j(document).ready(function() {
	init_itoggle('tailscale_dns');
	init_itoggle('tailscale_route');
	init_itoggle('tailscale_exit');
	init_itoggle('tailscale_reset');
	init_itoggle('tailscale_ssh');
	init_itoggle('tailscale_shields');
	$j("#tab_tailscale_cfg, #tab_tailscale_log").click(
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
	show_menu(5, 29, 0);
	show_footer();
	fill_status(tailscaled_status());
	fill_status2(tailscale_status());
	change_tailscale_enable();

}

var arrHashes = ["cfg","log"];
function showTab(curHash) {
	var obj = $('tab_tailscale_' + curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
	curHash = '#cfg';
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_tailscale_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_tailscale_' + arrHashes[i]).show();
		} else {
			$j('#wnd_tailscale_' + arrHashes[i]).hide();
			$j('#tab_tailscale_' + arrHashes[i]).parents('li').removeClass('active');
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
	$("tailscaled_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function fill_status2(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("tailscale_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_tailscale.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}

function done_validating(action){
	refreshpage();
}

function change_tailscale_enable(mflag){
	var m = document.form.tailscale_enable.value;
	var is_tailscale_enable = (m == "1" || m == "2") ? "重启" : "更新";
	document.form.restarttailscale.value = is_tailscale_enable;
	
	var is_tailscale_cmd = (m == "2") ? 1 : 0;
	var is_tailscale_df = (m == "1") ? 1 : 0;

	showhide_div("tailscale_cmd_tr", is_tailscale_cmd);
	showhide_div("tailscale_cmd_td", is_tailscale_cmd);

	
	showhide_div("tailscale_dns_tr", is_tailscale_df);
	showhide_div("tailscale_dns_td", is_tailscale_df);

	showhide_div("tailscale_route_tr", is_tailscale_df);
	showhide_div("tailscale_route_td", is_tailscale_df);

	showhide_div("tailscale_routes_tr", is_tailscale_df);
	showhide_div("tailscale_routes_td", is_tailscale_df);
	
	showhide_div("tailscale_exit_tr", is_tailscale_df);
	showhide_div("tailscale_exit_td", is_tailscale_df);

	showhide_div("tailscale_exitip_tr", is_tailscale_df);
	showhide_div("tailscale_exitip_td", is_tailscale_df);

	showhide_div("tailscale_server_tr", is_tailscale_df);
	showhide_div("tailscale_server_td", is_tailscale_df);

	showhide_div("tailscale_ssh_tr", is_tailscale_df);
	showhide_div("tailscale_ssh_td", is_tailscale_df);

	showhide_div("tailscale_shields_tr", is_tailscale_df);
	showhide_div("tailscale_shields_td", is_tailscale_df);

	showhide_div("tailscale_host_tr", is_tailscale_df);
	showhide_div("tailscale_host_td", is_tailscale_df);

	showhide_div("tailscale_key_tr", is_tailscale_df);
	showhide_div("tailscale_key_td", is_tailscale_df);

	showhide_div("tailscale_reset_tr", is_tailscale_df);
	showhide_div("tailscale_reset_td", is_tailscale_df);
	
	showhide_div("tailscale_cmd2_tr", is_tailscale_df);
	showhide_div("tailscale_cmd2_td", is_tailscale_df);

}
function button_restarttailscale() {
    var m = document.form.tailscale_enable.value;

    var actionMode = (m == "1" || m == "2") ? 'Restarttailscale' : 'Updatetailscale';

    change_tailscale_enable(m); 

    var $j = jQuery.noConflict(); 
    $j.post('/apply.cgi', {
        'action_mode': actionMode 
    });
}

function clearLog(){
	document.form.action="apply.cgi";
	document.form.current_page.value = "Advanced_tailscale.asp#log";
	document.form.next_host.value = "Advanced_tailscale.asp#log";
	document.form.action_mode.value = " ClearTsLog ";
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

	<input type="hidden" name="current_page" value="Advanced_tailscale.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="TAILSCALE;LANHostConfig;General;">
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
	<h2 class="box_head round_top">Tailsale</h2>
	<div class="round_bottom">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a id="tab_tailscale_cfg" href="#cfg">基本设置</a></li>
	<li><a id="tab_tailscale_log" href="#log">运行日志</a></li>
	</ul>
	</div>
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div id="wnd_tailscale_cfg">
	<div class="alert alert-info" style="margin: 10px;">Tailscale  让您可以轻松管理对私有资源的访问，快速通过 SSH 连接到您网络上的设备，网络变得简单。
	<div>项目地址：<a href="https://github.com/tailscale/tailscale" target="blank">https://github.com/tailscale/tailscale</a></div>
  		<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "tailscale_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "tailscale_ver_n"); %></span>】 &nbsp;&nbsp;<a href="<% nvram_get_x("", "tailscale_login"); %>" target="blank"><% nvram_get_x("", "tailscale_login"); %></a>
  		<br>&nbsp;<% nvram_get_x("", "tailscale_info"); %>
	</div>
	
	<span style="color:#FF0000;" class=""></span></div>

	<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">运行状态</th>
	</tr>
	<tr> <th>tailscaled</th>
            <td id="tailscaled_status" colspan="2"></td>
          </tr>
	<tr> <th>tailscale</th>
            <td id="tailscale_status" colspan="2"></td>
          </tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">程序配置</th>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用Tailscale</th>
	<td style="border-top: 0 none;">
	<select name="tailscale_enable" class="input" onChange="change_tailscale_enable();" style="width: 185px;">
	<option value="0" <% nvram_match_x("","tailscale_enable", "0","selected"); %>>【关闭】</option>
	<option value="1" <% nvram_match_x("","tailscale_enable", "1","selected"); %>>【开启】</option>
	<option value="2" <% nvram_match_x("","tailscale_enable", "2","selected"); %>>【开启】Tailscale 自定义参数</option>
	<option value="3" <% nvram_match_x("","tailscale_enable", "3","selected"); %>>【重置】恢复初始化</option>
	</select>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restarttailscale" value="更新" onclick="button_restarttailscale()" />
	</td>
	</tr><td colspan="3"></td>
	<tr id="tailscale_cmd_tr">
	<th width="30%" style="border-top: 0 none;">自定义参数启动
	</th>
	<td colspan="4" style="border-top: 0 none;">
	<textarea maxlength="1024" class="input" name="tailscale_cmd" id="tailscale_cmd" placeholder="up --accept-dns=false --accept-routes --advertise-routes=192.168.2.0/24 --advertise-exit-node --reset" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_cmd"); %></textarea>
	&nbsp;<a href="https://tailscale.com/kb/1241/tailscale-up/" target="blank">命令参数说明</a><br>&nbsp;<span style="color:#888;">直接填写启动命令 不需要路径和程序名。</span>
	</td>
	</tr><tr id="tailscale_cmd_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_dns_tr" >
	<th style="border-top: 0 none;">接受DNS设置</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_dns_on_of">
	<input type="checkbox" id="tailscale_dns_fake" <% nvram_match_x("", "tailscale_dns", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_dns", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="tailscale_dns" id="tailscale_dns_1" class="input" value="1" <% nvram_match_x("", "tailscale_dns", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="tailscale_dns" id="tailscale_dns_0" class="input" value="0" <% nvram_match_x("", "tailscale_dns", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_dns_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_route_tr" >
	<th style="border-top: 0 none;">接受路由</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_route_on_of">
	<input type="checkbox" id="tailscale_route_fake" <% nvram_match_x("", "tailscale_route", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_route", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">接受其他节点公布的子网路由</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_route" id="tailscale_route_1" class="input" value="1" <% nvram_match_x("", "tailscale_route", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_route" id="tailscale_route_0" class="input" value="0" <% nvram_match_x("", "tailscale_route", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_route_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_routes_tr">
	<th width="30%" style="border-top: 0 none;">本地子网</th>
	<td colspan="4" style="border-top: 0 none;">
		<textarea maxlength="1024" class="input" name="tailscale_routes" id="tailscale_routes" placeholder="192.168.2.0/24,192.168.123.0/24" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_routes"); %></textarea>
	<br>&nbsp;<span style="color:#888;">公布本地子网路由，多个网段使用英文,分隔</span>
	</td>
	</tr><tr id="tailscale_routes_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_exit_tr" >
	<th style="border-top: 0 none;">启用出口节点</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_exit_on_of">
	<input type="checkbox" id="tailscale_exit_fake" <% nvram_match_x("", "tailscale_exit", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_exit", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">使本机成为流量出口节点</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_exit" id="tailscale_exit_1" class="input" value="1" <% nvram_match_x("", "tailscale_exit", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_exit" id="tailscale_exit_0" class="input" value="0" <% nvram_match_x("", "tailscale_exit", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_exit_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_exitip_tr">
	<th width="30%" style="border-top: 0 none;">出口节点地址</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="128" class="input" size="15" placeholder="" id="tailscale_exitip" name="tailscale_exitip" value="<% nvram_get_x("","tailscale_exitip"); %>" onKeyPress="return is_string(this,event);" />
	<br>&nbsp;<span style="color:#888;">指定流量出口的节点</span>
	</td>
	</tr><tr id="tailscale_exitip_td"><td colspan="3"></td></tr>
	<tr id="tailscale_server_tr">
	<th width="30%" style="border-top: 0 none;">控制服务器地址</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="256" class="input" size="15" placeholder="https://controlplane.tailscale.com" id="tailscale_server" name="tailscale_server" value="<% nvram_get_x("","tailscale_server"); %>" onKeyPress="return is_string(this,event);" />
	<br>&nbsp;<span style="color:#888;">控制服务器的地址，如果您将 Headscale 用于控制服务器，请使用 Headscale 实例的 URL</span>
	</td>
	</tr><tr id="tailscale_server_td"><td colspan="3"></td></tr>
	<tr id="tailscale_ssh_tr" >
	<th style="border-top: 0 none;">启用ssh服务器</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_ssh_on_of">
	<input type="checkbox" id="tailscale_ssh_fake" <% nvram_match_x("", "tailscale_ssh", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_ssh", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">运行 Tailscale SSH 服务器</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_ssh" id="tailscale_ssh_1" class="input" value="1" <% nvram_match_x("", "tailscale_ssh", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_ssh" id="tailscale_ssh_0" class="input" value="0" <% nvram_match_x("", "tailscale_ssh", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_ssh_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_shields_tr" >
	<th style="border-top: 0 none;">仅传出连接</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_shields_on_of">
		<input type="checkbox" id="tailscale_shields_fake" <% nvram_match_x("", "tailscale_shields", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_shields", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">启用后将阻止来自 Tailscale 网络上其他设备的传入连接。对于仅建立传出连接的个人设备很有用。</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_shields" id="tailscale_shields_1" class="input" value="1" <% nvram_match_x("", "tailscale_shields", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_shields" id="tailscale_shields_0" class="input" value="0" <% nvram_match_x("", "tailscale_shields", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_shields_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_host_tr">
	<th width="30%" style="border-top: 0 none;">设备名称</th>
	<td style="border-top: 0 none;">
		<input type="text" maxlength="50" class="input" size="15" placeholder="<% nvram_get_x("","computer_name"); %>" id="tailscale_host" name="tailscale_host" value="<% nvram_get_x("","tailscale_host"); %>" onKeyPress="return is_string(this,event);" />
	<br>&nbsp;<span style="color:#888;">指定本机设备名称，方便区分设备</span>
	</td>
	</tr><tr id="tailscale_host_td"><td colspan="3"></td></tr>
	<tr id="tailscale_key_tr">
	<th width="30%" style="border-top: 0 none;">身份验证密钥</th>
	<td style="border-top: 0 none;">
		<textarea maxlength="1024" class="input" name="tailscale_key" id="tailscale_key" placeholder="" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_key"); %></textarea>
	<br>&nbsp;<span style="color:#888;">填写身份验证密钥以自动将节点验证为您的用户账户</span>
	</td>
	</tr><tr id="tailscale_key_td"><td colspan="3"></td></tr>
	<tr id="tailscale_reset_tr" >
	<th style="border-top: 0 none;">重置默认值</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="tailscale_reset_on_of">
	<input type="checkbox" id="tailscale_reset_fake" <% nvram_match_x("", "tailscale_reset", "1", "value=1 checked"); %><% nvram_match_x("", "tailscale_reset", "0", "value=0"); %> />
	&nbsp;<span style="color:#888;">将未使用的参数重置为默认值</span></div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
		<input type="radio" value="1" name="tailscale_reset" id="tailscale_reset_1" class="input" value="1" <% nvram_match_x("", "tailscale_reset", "1", "checked"); %> /><#checkbox_Yes#>
		<input type="radio" value="0" name="tailscale_reset" id="tailscale_reset_0" class="input" value="0" <% nvram_match_x("", "tailscale_reset", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="tailscale_reset_td" ><td colspan="3"></td></tr>
	<tr id="tailscale_cmd2_tr">
	<th width="30%" style="border-top: 0 none;">额外参数
	</th>
	<td colspan="4" style="border-top: 0 none;">
	<textarea maxlength="1024" class="input" name="tailscale_cmd2" id="tailscale_cmd2" placeholder="--netfilter-mode --exit-node-allow-lan-access" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_cmd2"); %></textarea>
	<br>&nbsp;<span style="color:#888;">上述选项缺少的参数，额外补充参数命令</span>
	</td>
	</tr><tr id="tailscale_cmd2_td" ><td colspan="3"></td></tr>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
		<textarea maxlength="1024"class="input" name="tailscale_bin" id="tailscale_bin" placeholder="/etc/storage/bin/tailscaled" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","tailscale_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义主程序的存放路径，填写完整的路径和主程序名称</span>
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
	<div id="wnd_tailscale_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
		<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("tailscale.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.href=location.href" value="<#CTL_refresh#>" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog();" value="<#CTL_clear#>" class="btn btn-info" style="width: 200px">
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

