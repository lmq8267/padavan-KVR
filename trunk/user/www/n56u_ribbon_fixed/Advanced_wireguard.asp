<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - <#menu5_35#></title>
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
<script type="text/javascript" src="/help_b.js"></script>
<script>
var $j = jQuery.noConflict();
<% login_state_hook(); %>
$j(document).ready(function() {
	
	init_itoggle('wireguard_enable');

});

</script>
<script>

<% login_state_hook(); %>


function initial(){
	show_banner(2);
	show_menu(5,17,0);
	showmenu();
	show_footer();
	if (!login_safe())
        		textarea_scripts_enabled(0);
}

function showmenu(){
	showhide_div('allink', found_app_aliddns());
	showhide_div('dtolink', found_app_ddnsto());
	showhide_div('zelink', found_app_zerotier());
}

function textarea_scripts_enabled(v){
	inputCtrl(document.form['scripts.wg0.conf'], v);
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Restart ";
	document.form.current_page.value = "/Advanced_wireguard.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}

function done_validating(action){
	refreshpage();
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

	<input type="hidden" name="current_page" value="Advanced_wireguard.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="WIREGUARD;">
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
							<h2 class="box_head round_top"><#menu5_35_1#> - <#menu5_30#></h2>
							<div class="round_bottom">
							<div>
							    <ul class="nav nav-tabs" style="margin-bottom: 10px;">
								<li id="allink" style="display:none">
								    <a href="Advanced_aliddns.asp"><#menu5_23_1#></a>
								</li>
								<li id="dtolink" style="display:none">
								    <a href="Advanced_ddnsto.asp"><#menu5_32_2#></a>
								</li>
								<li id="zelink" style="display:none">
								    <a href="Advanced_zerotier.asp"><#menu5_32_1#></a>
								</li>
								<li class="active">
								    <a href="Advanced_wireguard.asp"><#menu5_35_1#></a>
								</li>
							    </ul>
							</div>
								<div class="row-fluid">
									<div id="tabMenu" class="submenuBlock"></div>
									<div class="alert alert-info" style="margin: 10px;">
									<p>WireGuard 是一个易于配置、快速且安全的开源VPN<br>
									</p>
									</div>



									<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">


										<td colspan="5"></td><tr>
										<th width="30%" style="border-top: 0 none;">启用wireguard客户端</th>
											<td style="border-top: 0 none;">
													<div class="main_itoggle">
													<div id="wireguard_enable_on_of">
														<input type="checkbox" id="wireguard_enable_fake" <% nvram_match_x("", "wireguard_enable", "1", "value=1 checked"); %><% nvram_match_x("", "wireguard_enable", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="wireguard_enable" id="wireguard_enable_1" class="input" value="1" <% nvram_match_x("", "wireguard_enable", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="wireguard_enable" id="wireguard_enable_0" class="input" value="0" <% nvram_match_x("", "wireguard_enable", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
											<td style="border-top: 0 none;">
												<input class="btn btn-success" style="width:150px" type="button" name="restartwg" value="重启" onclick="button_restartwg()" />
												</td>

										</tr><td colspan="5"></td>
										<tr>
										<th style="border-top: 0 none;">接口IPV4</th>
										<td style="border-top: 0 none;">
											<input type="text" class="input" name="wireguard_localip" id="wireguard_localip" style="width: 200px" value="<% nvram_get_x("","wireguard_localip"); %>" />
										&nbsp;<span style="color:#888;">（格式 10.0.0.2/24）</span>
										</td>
										</tr><td colspan="5"></td>
										<tr>
										<th style="border-top: 0 none;">接口IPV6</th>
										<td style="border-top: 0 none;">
											<input type="text" class="input" name="wireguard_localip" id="wireguard_localip6" style="width: 200px" value="<% nvram_get_x("","wireguard_localip6"); %>" />
										&nbsp;<span style="color:#888;">（格式 fd69::1/64）</span>
										</td>
										</tr><td colspan="5"></td>
										<tr>
										<th style="border-top: 0 none;">自定义接口</th>
										<td style="border-top: 0 none;">
												<input type="text" maxlength="20" class="input" name="wireguard_tun" placeholder="wg0" id="wireguard_tun" style="width: 200px" value="<% nvram_get_x("","wireguard_tun"); %>" />
										</td>
										</tr><td colspan="5"></td>
										<tr>
										<th style="border-top: 0 none;">自定义MTU </th>
										<td style="border-top: 0 none;">
											<input type="text" maxlength="4" class="input" name="wireguard_mtu" placeholder="1420" id="wireguard_mtu" style="width: 200px" value="<% nvram_get_x("","wireguard_mtu"); %>" />
										</td>
										</tr><td colspan="5"></td>
										<tr>
										<td colspan="5" style="border-top: 0 none;">
											<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('scripts.wireguard')"><span>点此编辑 /etc/storage/wg0.conf 配置文件</span></a>
										<div id="scripts.wireguard" style="display:none;">
											<textarea rows="18" wrap="off" spellcheck="false" maxlength="209715" class="span12" name="scripts.wg0.conf" style="font-family:'Courier New'; font-size:12px; height: 200px;""><% nvram_dump("scripts.wg0.conf",""); %></textarea>
											<div>⚠️&nbsp;&nbsp;<span style="color: #ff8100;">注意：</span><span style="color:#888;">配置文件不支持Post脚本规则&nbsp;&nbsp;&nbsp;&nbsp;在线生成配置文件：<a href="https://www.wireguardconfig.com/" target="blank">点此</a></span></div>
										</div>
										</td>
										</tr><td colspan="4"></td>
										<td colspan="3"></td>
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

