<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - 网易UU游戏加速器</title>
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

	init_itoggle('uu_enable',change_uu_enable_bridge);

});

</script>
<script>
<% uuplugin_status(); %>
<% login_state_hook(); %>

function initial(){
	show_banner(2);
	show_menu(5,23,0);
	showUUPlatform(uu_admin);
	fill_status(uuplugin_status());
	show_footer();

}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("uuplugin_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_uuplugin.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}


function done_validating(action){
	refreshpage();
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

	<input type="hidden" name="current_page" value="Advanced_uuplugin.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="LANHostConfig;General;">
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
							<h2 class="box_head round_top">网易UU游戏加速器</h2>
							<div class="round_bottom">
							<div>
                            <ul class="nav nav-tabs" style="margin-bottom: 10px;">
			
                            </ul>
                        </div>
								<div class="row-fluid">
									<div id="tabMenu" class="submenuBlock"></div>
									<div class="alert alert-info" style="margin: 10px;">
									<p>一款由网易公司开发的游戏加速器软件，旨在提升游戏网络连接的稳定性和速度。该加速器支持多种平台，包括PC、iOS、Android、PS、Xbox和NS等，几乎覆盖了所有主流游戏平台。<br>
									<br>首次绑定设备请启动后打开下方的UU云平台进行绑定，后续可使用手机下载 UU主机加速 APP进行管理。
									</p>
									</div>
								<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
									<tr> <th><#running_status#></th>
                                            <td id="uuplugin_status" colspan="3"></td>
                                        </tr>
										<tr>
											<th width="30%" style="border-top: 0 none;">启用UU加速器</th>
											<td style="border-top: 0 none;">
													<div class="main_itoggle">
													<div id="uu_enable_on_of">
														<input type="checkbox" id="uu_enable_fake" <% nvram_match_x("", "uu_enable", "1", "value=1 checked"); %><% nvram_match_x("", "uu_enable", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="uu_enable" id="uu_enable_1" class="input" value="1" <% nvram_match_x("", "uu_enable", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="uu_enable" id="uu_enable_0" class="input" value="0" <% nvram_match_x("", "uu_enable", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr>
											<th>绑定设备:</th>
											<td><a href="<% nvram_get_x("", "uu_admin"); %>">UU云平台</a>
											</td>
										</tr>
</div>
</body>
</html>

