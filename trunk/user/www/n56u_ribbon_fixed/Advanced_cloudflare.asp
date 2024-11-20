<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - Cloudflare 域名解析</title>
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

	init_itoggle('cloudflare_enable',change_cloudflare_enable_bridge);

});

</script>
<script>

<% login_state_hook(); %>

function initial(){
	show_banner(2);
	show_menu(5,31,0);
	show_footer();

	change_cloudflare_enable_bridge(1);

	if (!login_safe())
		textarea_scripts_enabled(0);
}

function textarea_scripts_enabled(v){
	inputCtrl(document.form['scripts.ddns_script.sh'], v);
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_cloudflare.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}


function done_validating(action){
	refreshpage();
}

function change_cloudflare_enable_bridge(mflag){
	var m = document.form.cloudflare_enable[0].checked;
	showhide_div("cloudflare_interval_tr", m);
	showhide_div("cloudflare_token_tr", m);
	showhide_div("cloudflare_Email_tr", m);
	showhide_div("cloudflare_Key_tr", m);
	//showhide_div("cloudflare_CA_Key_tr", m);
	showhide_div("cloudflare_domian_tr", m);
	showhide_div("cloudflare_domian2_tr", m);
	showhide_div("cloudflare_domian6_tr", m);
	showhide_div("row_post_wan_script", m);
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

	<input type="hidden" name="current_page" value="Advanced_cloudflare.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="CLOUDFLARE;LANHostConfig;General;">
	<input type="hidden" name="group_id" value="">
	<input type="hidden" name="action_mode" value="">
	<input type="hidden" name="action_script" value="">
	<input type="hidden" name="wan_ipaddr" value="<% nvram_get_x("", "wan0_ipaddr"); %>" readonly="1">
	<input type="hidden" name="wan_netmask" value="<% nvram_get_x("", "wan0_netmask"); %>" readonly="1">
	<input type="hidden" name="dhcp_start" value="<% nvram_get_x("", "dhcp_start"); %>">
	<input type="hidden" name="dhcp_end" value="<% nvram_get_x("", "dhcp_end"); %>">

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
	<h2 class="box_head round_top">Cloudflare 域名解析</h2>
	<div class="round_bottom">
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div class="alert alert-info" style="margin: 10px;">使用 Cloudflare 实现顶级个人域名的 ddns 服务。 <a href="https://www.cloudflare.com" target="blank"><i><u>https://www.cloudflare.com</u></i></a>
	<ul style="padding-top:5px;margin-top:10px;float: left;">
	<li><a href="https://www.cloudflare.com" target="blank"><i><u>ddns 项目地址：https://www.cloudflare.com</u></i></a></li>
	<li>使用前需要将域名添加到 Cloudflare 中，并添加一条A记录，使用之后将自动更新ip</li>
	<li>点 <a href="https://dash.cloudflare.com/profile/api-tokens" target="blank"><i><u>【Get your API key】</u></i></a> 查看官方说明以及如何获取 Cloudflare 的 API 令牌和 Global API Key 。</li>
	<li>万能的 Email·Global API Key 和各自权限的 API 令牌 选填一组，推荐用 API 令牌，可以保护账户安全</li>
	</ul></div>

	<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	
	<tr>
	<th width="30%" style="border-top: 0 none;">启用 Cloudflare 域名解析</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="cloudflare_enable_on_of">
	<input type="checkbox" id="cloudflare_enable_fake" <% nvram_match_x("", "cloudflare_enable", "1", "value=1 checked"); %><% nvram_match_x("", "cloudflare_enable", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="cloudflare_enable" id="cloudflare_enable_1" class="input" value="1" onClick="change_cloudflare_enable_bridge(1);" <% nvram_match_x("", "cloudflare_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="cloudflare_enable" id="cloudflare_enable_0" class="input" value="0" onClick="change_cloudflare_enable_bridge(1);" <% nvram_match_x("", "cloudflare_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr id="cloudflare_interval_tr" style="display:none;">
	<th width="30%" style="border-top: 0 none;">检查周期(秒) :</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="5" class="input" size="15" id="cloudflare_interval" name="cloudflare_interval" placeholder="600" value="<% nvram_get_x("","cloudflare_interval"); %>"  onkeypress="return is_number(this,event);" />
	</td>
	</tr>
	<tr id="cloudflare_token_tr" style="display:none;">
	<th width="30%" style="border-top: 0 none;">用户 API 令牌 (Token) :</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input type="password" maxlength="512" class="input" size="15" name="cloudflare_token" id="cloudflare_token" style="width: 175px;" placeholder="API Token" value="<% nvram_get_x("","cloudflare_token"); %>" onKeyPress="return is_string(this,event);"/>
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('cloudflare_token')"><i class="icon-eye-close"></i></button>
	</div>
	</td>
	</tr>
	<tr id="cloudflare_Email_tr" style="display:none;">
	<th width="30%" style="border-top: 0 none;">用户 Email Address :</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="255" class="input" size="15" id="cloudflare_Email" name="cloudflare_Email" value="<% nvram_get_x("","cloudflare_Email"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr id="cloudflare_Key_tr" style="display:none;">
	<th width="30%" style="border-top: 0 none;">用户 Global API Key :</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input type="password" maxlength="512" class="input" size="15" name="cloudflare_Key" id="cloudflare_Key" style="width: 175px;" placeholder="Global API Key" value="<% nvram_get_x("","cloudflare_Key"); %>" onKeyPress="return is_string(this,event);"/>
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('cloudflare_Key')"><i class="icon-eye-close"></i></button>
	</div>
	</td>
	</tr>
	<tr id="cloudflare_CA_Key_tr" style="display:none;">
	<th width="30%" style="border-top: 0 none;">用户 Origin CA Key:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input type="password" maxlength="512" class="input" size="15" name="cloudflare_CA_Key" id="cloudflare_CA_Key" style="width: 175px;" value="<% nvram_get_x("","cloudflare_CA_Key"); %>" onKeyPress="return is_string(this,event);"/>
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('cloudflare_CA_Key')"><i class="icon-eye-close"></i></button>
	</div>
	</td>
	</tr>
	<tr id="cloudflare_domian_tr" style="display:none;">
	<th width="30%" style="border-top: 0 none;">顶级域名1</th>
	<td style="border-top: 0 none;">
	<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_host" name="cloudflare_host" placeholder="www" value="<% nvram_get_x("","cloudflare_host"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_domian" name="cloudflare_domian" placeholder="google.com" value="<% nvram_get_x("","cloudflare_domian"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr id="cloudflare_domian2_tr" style="display:none;">
	<th width="30%" style="border-top: 0 none;">顶级域名2</th>
	<td style="border-top: 0 none;">
	<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_host2" name="cloudflare_host2" placeholder="www" value="<% nvram_get_x("","cloudflare_host2"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_domian2" name="cloudflare_domian2" placeholder="google.com" value="<% nvram_get_x("","cloudflare_domian2"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr id="cloudflare_domian6_tr" style="display:none;">
	<th width="30%" style="border-top: 0 none;">顶级域名3[IPv6]</th>
	<td style="border-top: 0 none;">
	<input style="width: 80px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_host6" name="cloudflare_host6" placeholder="www" value="<% nvram_get_x("","cloudflare_host6"); %>" onKeyPress="return is_string(this,event);" /> . <input style="width: 110px;" type="text" maxlength="255" class="input" size="15" id="cloudflare_domian6" name="cloudflare_domian6" placeholder="google.com" value="<% nvram_get_x("","cloudflare_domian6"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr>
	<tr id="row_post_wan_script" style="display:none;">
	<td colspan="2" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('script2')"><span>cloudflare脚本-基于cloudflare用户API实现的纯Shell动态域名客户端</span></a>
	<div id="script2" style="display:none;">
	<textarea rows="18" wrap="off" spellcheck="false" maxlength="2097152" class="span12" name="scripts.ddns_script.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.ddns_script.sh",""); %></textarea>
	</div>
	</td>
	</tr>
	

	<tr>
	<td colspan="2" style="border-top: 0 none;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td>
	</tr>
	</table>
	</div>
	</div>
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


