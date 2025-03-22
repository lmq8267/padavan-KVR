<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - 菜单设置</title>
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
<script type="text/javascript" src="/client_function.js"></script>
<script type="text/javascript" src="/popup.js"></script>
<script type="text/javascript" src="/help.js"></script>
<script>
var $j = jQuery.noConflict();

$j(document).ready(function() {
    init_itoggle('w_ai');
	init_itoggle('w_vpn_s');
	init_itoggle('w_vpn_c');
	init_itoggle('w_wnet');
	init_itoggle('w_sys');
	init_itoggle('w_usb');
	init_itoggle('w_net');
	init_itoggle('w_log');
	init_itoggle('w_scu');
	init_itoggle('w_dnsf');
	init_itoggle('w_ss');
	init_itoggle('w_men');
	init_itoggle('w_adbyby');
	init_itoggle('w_pdnsd');
	init_itoggle('w_aliddns');
	init_itoggle('w_frp');
	init_itoggle('w_caddy');
	init_itoggle('w_wyy');
	init_itoggle('w_aldriver');
	init_itoggle('w_uuplugin');
	init_itoggle('w_lucky');
	init_itoggle('w_wxsend');
	init_itoggle('w_cloudflared');
	init_itoggle('w_vnts');
	init_itoggle('w_vntcli');
	init_itoggle('w_natpierce');
	init_itoggle('w_tailscale');
	init_itoggle('w_alist');
	init_itoggle('w_cloudflare');
	init_itoggle('w_easytier');
	init_itoggle('w_bafa');
	init_itoggle('w_virtualhere');

});
</script>
<script>
<% login_state_hook(); %>
function initial(){
	show_banner(2);
	show_menu(5,8,4);
	show_footer();
	
	if (found_app_shadowsocks()){
	showhide_div('row_wss', true);
}
if (found_app_scutclient()){
	showhide_div('row_wscu', true);
}
if (found_app_dnsforwarder()){
	showhide_div('row_wdnsf', true);
}
if (found_app_mentohust()){
	showhide_div('row_wmen', true);
}
if (found_app_adbyby() || found_app_koolproxy()){
	showhide_div('row_wadbyby', true);
}
if (found_app_smartdns() || found_app_adguardhome()){
	showhide_div('row_wpdnsd', true);
}
if (found_app_aliddns() || found_app_ddnsto() || found_app_zerotier() || found_app_wireguard()){
	showhide_div('row_waliddns', true);
}
if (found_app_frp()){
	showhide_div('row_wfrp', true);
}
if (found_app_caddy()){
	showhide_div('row_wcaddy', true);
}
if (found_app_wyy()){
	showhide_div('row_wwyy', true);
}
if (found_app_aldriver()){
	showhide_div('row_waldriver', true);
}
if (found_app_uuplugin()){
	showhide_div('row_wuuplugin', true);
}
if (found_app_lucky()){
	showhide_div('row_wlucky', true);
}
if (found_app_wxsend()){
	showhide_div('row_wwxsend', true);
}
if (found_app_cloudflared()){
	showhide_div('row_wcloudflared', true);
}
if (found_app_vnts()){
	showhide_div('row_wvnts', true);
}
if (found_app_vntcli()){
	showhide_div('row_wvntcli', true);
}
if (found_app_natpierce()){
	showhide_div('row_wnatpierce', true);
}
if (found_app_tailscale()){
	showhide_div('row_wtailscale', true);
}
if (found_app_alist()){
	showhide_div('row_walist', true);
}
if (found_app_cloudflare()){
	showhide_div('row_wcloudflare', true);
}
if (found_app_easytier()){
	showhide_div('row_weasytier', true);
}
if (found_app_bafa()){
	showhide_div('row_wbafa', true);
}
if (found_app_virtualhere()){
	showhide_div('row_wvirtualhere', true);
}

}


function applyRule(){
	//if(validForm()){
		showLoading();
		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "Advanced_web.asp";
		document.form.next_page.value = "";
		document.form.submit();
	//}
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

	<input type="hidden" name="current_page" value="Advanced_web.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="DwebConf;">
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
							<h2 class="box_head round_top">自定义菜单选项</h2>
							<div class="round_bottom">
								<div class="row-fluid">
									<div id="tabMenu" class="submenuBlock"></div>
									<div class="alert alert-info" style="margin: 10px;">把你不想在网页上显示的菜单选项关闭，适用于重度强迫症......<br />
									<div>此选项只能屏蔽页面的显示，并不会删除程序。</div>
									</div>
									<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
										<tr >
											<th width="50%">VPN服务器</th>
											<td>
													<div class="main_itoggle">
													<div id="w_vpn_s_on_of">
														<input type="checkbox" id="w_vpn_s_fake" <% nvram_match_x("", "w_vpn_s", "1", "value=1 checked"); %><% nvram_match_x("", "w_vpn_s", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_vpn_s" id="w_vpn_s_1" class="input" <% nvram_match_x("", "w_vpn_s", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_vpn_s" id="w_vpn_s_0" class="input" <% nvram_match_x("", "w_vpn_s", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
																				<tr >
											<th width="50%">VPN客户端</th>
											<td>
													<div class="main_itoggle">
													<div id="w_vpn_c_on_of">
														<input type="checkbox" id="w_vpn_c_fake" <% nvram_match_x("", "w_vpn_c", "1", "value=1 checked"); %><% nvram_match_x("", "w_vpn_c", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_vpn_c" id="w_vpn_c_1" class="input" <% nvram_match_x("", "w_vpn_c", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_vpn_c" id="w_vpn_c_0" class="input" <% nvram_match_x("", "w_vpn_c", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr >
											<th width="50%">网络流量</th>
											<td>
													<div class="main_itoggle">
													<div id="w_wnet_on_of">
														<input type="checkbox" id="w_wnet_fake" <% nvram_match_x("", "w_wnet", "1", "value=1 checked"); %><% nvram_match_x("", "w_wnet", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_wnet" id="w_wnet_1" class="input" <% nvram_match_x("", "w_wnet", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_wnet" id="w_wnet_0" class="input" <% nvram_match_x("", "w_wnet", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr >
											<th width="50%">系统信息</th>
											<td>
													<div class="main_itoggle">
													<div id="w_sys_on_of">
														<input type="checkbox" id="w_sys_fake" <% nvram_match_x("", "w_sys", "1", "value=1 checked"); %><% nvram_match_x("", "w_sys", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_sys" id="w_sys_1" class="input" <% nvram_match_x("", "w_sys", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_sys" id="w_sys_0" class="input" <% nvram_match_x("", "w_sys", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr >
											<th width="50%">USB应用</th>
											<td>
													<div class="main_itoggle">
													<div id="w_usb_on_of">
														<input type="checkbox" id="w_usb_fake" <% nvram_match_x("", "w_usb", "1", "value=1 checked"); %><% nvram_match_x("", "w_usb", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_usb" id="w_usb_1" class="input" <% nvram_match_x("", "w_usb", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_usb" id="w_usb_0" class="input" <% nvram_match_x("", "w_usb", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr >
											<th width="50%">网络信息</th>
											<td>
													<div class="main_itoggle">
													<div id="w_net_on_of">
														<input type="checkbox" id="w_net_fake" <% nvram_match_x("", "w_net", "1", "value=1 checked"); %><% nvram_match_x("", "w_net", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_net" id="w_net_1" class="input" <% nvram_match_x("", "w_net", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_net" id="w_net_0" class="input" <% nvram_match_x("", "w_net", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr >
											<th width="50%">系统日志</th>
											<td>
													<div class="main_itoggle">
													<div id="w_log_on_of">
														<input type="checkbox" id="w_log_fake" <% nvram_match_x("", "w_log", "1", "value=1 checked"); %><% nvram_match_x("", "w_log", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_log" id="w_log_1" class="input" <% nvram_match_x("", "w_log", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_log" id="w_log_0" class="input" <% nvram_match_x("", "w_log", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wscu" style="display:none">
											<th width="50%">Scutclient</th>
											<td>
													<div class="main_itoggle">
													<div id="w_scu_on_of">
														<input type="checkbox" id="w_scu_fake" <% nvram_match_x("", "w_scu", "1", "value=1 checked"); %><% nvram_match_x("", "w_scu", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_scu" id="w_scu_1" class="input" <% nvram_match_x("", "w_scu", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_scu" id="w_scu_0" class="input" <% nvram_match_x("", "w_scu", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										
										<tr id="row_wdnsf" style="display:none">
											<th width="50%" >DNS-forwarder</th>
											<td>
													<div class="main_itoggle">
													<div id="w_dnsf_on_of">
														<input type="checkbox" id="w_dnsf_fake" <% nvram_match_x("", "w_dnsf", "1", "value=1 checked"); %><% nvram_match_x("", "w_dnsf", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_dnsf" id="w_dnsf_1" class="input" <% nvram_match_x("", "w_dnsf", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_dnsf" id="w_dnsf_0" class="input" <% nvram_match_x("", "w_dnsf", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wss" style="display:none">
											<th width="50%">科学上网</th>
											<td>
													<div class="main_itoggle">
													<div id="w_ss_on_of">
														<input type="checkbox" id="w_ss_fake" <% nvram_match_x("", "w_ss", "1", "value=1 checked"); %><% nvram_match_x("", "w_ss", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_ss" id="w_ss_1" class="input" <% nvram_match_x("", "w_ss", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_ss" id="w_ss_0" class="input" <% nvram_match_x("", "w_ss", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wmen" style="display:none">
											<th width="50%" >Mentohust</th>
											<td>
													<div class="main_itoggle">
													<div id="w_men_on_of">
														<input type="checkbox" id="w_men_fake" <% nvram_match_x("", "w_men", "1", "value=1 checked"); %><% nvram_match_x("", "w_men", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_men" id="w_men_1" class="input" <% nvram_match_x("", "w_men", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_men" id="w_men_0" class="input" <% nvram_match_x("", "w_men", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wadbyby" style="display:none">
											<th width="50%">广告管理</th>
											<td>
													<div class="main_itoggle">
													<div id="w_adbyby_on_of">
														<input type="checkbox" id="w_adbyby_fake" <% nvram_match_x("", "w_adbyby", "1", "value=1 checked"); %><% nvram_match_x("", "w_adbyby", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_adbyby" id="w_adbyby_1" class="input" <% nvram_match_x("", "w_adbyby", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_adbyby" id="w_adbyby_0" class="input" <% nvram_match_x("", "w_adbyby", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wpdnsd" style="display:none">
											<th width="50%" >DNS服务</th>
											<td>
													<div class="main_itoggle">
													<div id="w_pdnsd_on_of">
														<input type="checkbox" id="w_pdnsd_fake" <% nvram_match_x("", "w_pdnsd", "1", "value=1 checked"); %><% nvram_match_x("", "w_pdnsd", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_pdnsd" id="w_pdnsd_1" class="input" <% nvram_match_x("", "w_pdnsd", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_pdnsd" id="w_pdnsd_0" class="input" <% nvram_match_x("", "w_pdnsd", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_waliddns" style="display:none">
											<th width="50%" >穿透服务</th>
											<td>
													<div class="main_itoggle">
													<div id="w_aliddns_on_of">
														<input type="checkbox" id="w_aliddns_fake" <% nvram_match_x("", "w_aliddns", "1", "value=1 checked"); %><% nvram_match_x("", "w_aliddns", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_aliddns" id="w_aliddns_1" class="input" <% nvram_match_x("", "w_aliddns", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_aliddns" id="w_aliddns_0" class="input" <% nvram_match_x("", "w_aliddns", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wfrp" style="display:none">
											<th width="50%" >内网穿透</th>
											<td>
													<div class="main_itoggle">
													<div id="w_frp_on_of">
														<input type="checkbox" id="w_frp_fake" <% nvram_match_x("", "w_frp", "1", "value=1 checked"); %><% nvram_match_x("", "w_frp", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_frp" id="w_frp_1" class="input" <% nvram_match_x("", "w_frp", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_frp" id="w_frp_0" class="input" <% nvram_match_x("", "w_frp", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wcaddy" style="display:none">
											<th width="50%" >文件管理</th>
											<td>
													<div class="main_itoggle">
													<div id="w_caddy_on_of">
														<input type="checkbox" id="w_caddy_fake" <% nvram_match_x("", "w_caddy", "1", "value=1 checked"); %><% nvram_match_x("", "w_caddy", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_caddy" id="w_caddy_1" class="input" <% nvram_match_x("", "w_caddy", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_caddy" id="w_caddy_0" class="input" <% nvram_match_x("", "w_caddy", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wwyy" style="display:none">
											<th width="50%" >音乐解锁</th>
											<td>
													<div class="main_itoggle">
													<div id="w_wyy_on_of">
														<input type="checkbox" id="w_wyy_fake" <% nvram_match_x("", "w_wyy", "1", "value=1 checked"); %><% nvram_match_x("", "w_wyy", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_wyy" id="w_wyy_1" class="input" <% nvram_match_x("", "w_wyy", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_wyy" id="w_wyy_0" class="input" <% nvram_match_x("", "w_wyy", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_waldriver" style="display:none">
											<th width="50%" >阿里云盘</th>
											<td>
													<div class="main_itoggle">
													<div id="w_aldriver_on_of">
														<input type="checkbox" id="w_aldriver_fake" <% nvram_match_x("", "w_aldriver", "1", "value=1 checked"); %><% nvram_match_x("", "w_aldriver", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_aldriver" id="w_aldriver_1" class="input" <% nvram_match_x("", "w_aldriver", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_aldriver" id="w_aldriver_0" class="input" <% nvram_match_x("", "w_aldriver", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wuuplugin" style="display:none">
											<th width="50%" >UU加速器</th>
											<td>
													<div class="main_itoggle">
													<div id="w_uuplugin_on_of">
														<input type="checkbox" id="w_uuplugin_fake" <% nvram_match_x("", "w_uuplugin", "1", "value=1 checked"); %><% nvram_match_x("", "w_uuplugin", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_uuplugin" id="w_uuplugin_1" class="input" <% nvram_match_x("", "w_uuplugin", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_uuplugin" id="w_uuplugin_0" class="input" <% nvram_match_x("", "w_uuplugin", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wlucky" style="display:none">
											<th width="50%" >Lucky</th>
											<td>
													<div class="main_itoggle">
													<div id="w_lucky_on_of">
														<input type="checkbox" id="w_lucky_fake" <% nvram_match_x("", "w_lucky", "1", "value=1 checked"); %><% nvram_match_x("", "w_lucky", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_lucky" id="w_lucky_1" class="input" <% nvram_match_x("", "w_lucky", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_lucky" id="w_lucky_0" class="input" <% nvram_match_x("", "w_lucky", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wwxsend" style="display:none">
											<th width="50%" >微信推送</th>
											<td>
													<div class="main_itoggle">
													<div id="w_wxsend_on_of">
														<input type="checkbox" id="w_wxsend_fake" <% nvram_match_x("", "w_wxsend", "1", "value=1 checked"); %><% nvram_match_x("", "w_wxsend", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_wxsend" id="w_wxsend_1" class="input" <% nvram_match_x("", "w_wxsend", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_wxsend" id="w_wxsend_0" class="input" <% nvram_match_x("", "w_wxsend", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wcloudflared" style="display:none">
											<th width="50%" >CloudFlared</th>
											<td>
													<div class="main_itoggle">
													<div id="w_cloudflared_on_of">
														<input type="checkbox" id="w_cloudflared_fake" <% nvram_match_x("", "w_cloudflared", "1", "value=1 checked"); %><% nvram_match_x("", "w_cloudflared", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_cloudflared" id="w_cloudflared_1" class="input" <% nvram_match_x("", "w_cloudflared", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_cloudflared" id="w_cloudflared_0" class="input" <% nvram_match_x("", "w_cloudflared", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wvnts" style="display:none">
											<th width="50%" >VNT服务器</th>
											<td>
													<div class="main_itoggle">
													<div id="w_vnts_on_of">
														<input type="checkbox" id="w_vnts_fake" <% nvram_match_x("", "w_vnts", "1", "value=1 checked"); %><% nvram_match_x("", "w_vnts", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_vnts" id="w_vnts_1" class="input" <% nvram_match_x("", "w_vnts", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_vnts" id="w_vnts_0" class="input" <% nvram_match_x("", "w_vnts", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wvntcli" style="display:none">
											<th width="50%" >VNT客户端</th>
											<td>
													<div class="main_itoggle">
													<div id="w_vntcli_on_of">
														<input type="checkbox" id="w_vntcli_fake" <% nvram_match_x("", "w_vntcli", "1", "value=1 checked"); %><% nvram_match_x("", "w_vntcli", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_vntcli" id="w_vntcli_1" class="input" <% nvram_match_x("", "w_vntcli", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_vntcli" id="w_vntcli_0" class="input" <% nvram_match_x("", "w_vntcli", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wnatpierce" style="display:none">
											<th width="50%" >皎月连</th>
											<td>
													<div class="main_itoggle">
													<div id="w_natpierce_on_of">
														<input type="checkbox" id="w_natpierce_fake" <% nvram_match_x("", "w_natpierce", "1", "value=1 checked"); %><% nvram_match_x("", "w_natpierce", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_natpierce" id="w_natpierce_1" class="input" <% nvram_match_x("", "w_natpierce", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_natpierce" id="w_natpierce_0" class="input" <% nvram_match_x("", "w_natpierce", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wtailscale" style="display:none">
											<th width="50%" >Tailscale</th>
											<td>
													<div class="main_itoggle">
													<div id="w_tailscale_on_of">
														<input type="checkbox" id="w_tailscale_fake" <% nvram_match_x("", "w_tailscale", "1", "value=1 checked"); %><% nvram_match_x("", "w_tailscale", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_tailscale" id="w_tailscale_1" class="input" <% nvram_match_x("", "w_tailscale", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_tailscale" id="w_tailscale_0" class="input" <% nvram_match_x("", "w_tailscale", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_walist" style="display:none">
											<th width="50%" >Alist</th>
											<td>
													<div class="main_itoggle">
													<div id="w_alist_on_of">
														<input type="checkbox" id="w_alist_fake" <% nvram_match_x("", "w_alist", "1", "value=1 checked"); %><% nvram_match_x("", "w_alist", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_alist" id="w_alist_1" class="input" <% nvram_match_x("", "w_alist", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_alist" id="w_alist_0" class="input" <% nvram_match_x("", "w_alist", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wcloudflare" style="display:none">
											<th width="50%" >CF域名解析</th>
											<td>
													<div class="main_itoggle">
													<div id="w_cloudflare_on_of">
														<input type="checkbox" id="w_cloudflare_fake" <% nvram_match_x("", "w_cloudflare", "1", "value=1 checked"); %><% nvram_match_x("", "w_cloudflare", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_cloudflare" id="w_cloudflare_1" class="input" <% nvram_match_x("", "w_cloudflare", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_cloudflare" id="w_cloudflare_0" class="input" <% nvram_match_x("", "w_cloudflare", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_weasytier" style="display:none">
											<th width="50%" >EasyTier</th>
											<td>
													<div class="main_itoggle">
													<div id="w_easytier_on_of">
														<input type="checkbox" id="w_easytier_fake" <% nvram_match_x("", "w_easytier", "1", "value=1 checked"); %><% nvram_match_x("", "w_easytier", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_easytier" id="w_easytier_1" class="input" <% nvram_match_x("", "w_easytier", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_easytier" id="w_easytier_0" class="input" <% nvram_match_x("", "w_easytier", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wbafa" style="display:none">
											<th width="50%" >巴法云</th>
											<td>
													<div class="main_itoggle">
													<div id="w_bafa_on_of">
														<input type="checkbox" id="w_bafa_fake" <% nvram_match_x("", "w_bafa", "1", "value=1 checked"); %><% nvram_match_x("", "w_bafa", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_bafa" id="w_bafa_1" class="input" <% nvram_match_x("", "w_bafa", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_bafa" id="w_bafa_0" class="input" <% nvram_match_x("", "w_bafa", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										<tr id="row_wvirtualhere" style="display:none">
											<th width="50%" >VirtualHere</th>
											<td>
													<div class="main_itoggle">
													<div id="w_virtualhere_on_of">
														<input type="checkbox" id="w_virtualhere_fake" <% nvram_match_x("", "w_virtualhere", "1", "value=1 checked"); %><% nvram_match_x("", "w_virtualhere", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="w_virtualhere" id="w_virtualhere_1" class="input" <% nvram_match_x("", "w_virtualhere", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="w_virtualhere" id="w_virtualhere_0" class="input" <% nvram_match_x("", "w_virtualhere", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
										</tr>
										
											<td colspan="2">
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
<form method="post" name="adbyby_action" action="">
    <input type="hidden" name="connect_action" value="">
</form>
</body>
</html>
