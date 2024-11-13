<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - CloudFlared</title>
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

	init_itoggle('cloudflared_enable',change_cloudflared_enable);

});

</script>
<script>
<% cloudflared_status(); %>
<% login_state_hook(); %>

function initial(){
	show_banner(2);
	show_menu(5,26,0);
	fill_status(cloudflared_status());
	show_footer();
	change_cloudflared_enable(1);
}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("cloudflared_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_cloudflared.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}


function done_validating(action){
	refreshpage();
}

function change_cloudflared_enable(mflag){
	var m = document.form.cloudflared_enable.value;
	var is_cloudflared_enable = (m == "1") ? "重启" : "更新";
	document.form.updatecloudflared.value = is_cloudflared_enable;
}
function button_updatecloudflared() {
    var m = document.form.cloudflared_enable.value;

    var actionMode = (m == "1") ? 'Restartcloudflared' : 'Updatecloudflared';

    change_cloudflared_enable(m); 

    var $j = jQuery.noConflict(); 
    $j.post('/apply.cgi', {
        'action_mode': actionMode 
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

	<input type="hidden" name="current_page" value="Advanced_cloudflared.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="CLOUDFLARED;LANHostConfig;General;">
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
							<h2 class="box_head round_top">CloudFlared</h2>
							<div class="round_bottom">
							<div>
                            <ul class="nav nav-tabs" style="margin-bottom: 10px;">
			
                            </ul>
                        </div>
								<div class="row-fluid">
									<div id="tabMenu" class="submenuBlock"></div>
									<div class="alert alert-info" style="margin: 10px;">
									<p>Cloudflare的隧道客户端 - 以前称为 Argo Tunnel ，免费的内网穿透，实现内网服务的外网访问.<br>
									<div>打开【<a href="https://one.dash.cloudflare.com/" target="blank">官网</a>】进入Zero Trust创建或管理您的 cloudflared 隧道。&nbsp;&nbsp;<a href="https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/install-and-setup/tunnel-guide/local/" target="blank">官方文档</a></div>
									<div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "cloudflared_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "cloudflared_ver_n"); %></span>】</div>
									</p>
									</div>
								<table width="100%" cellpadding="4" cellspacing="0" class="table">
													<tr>
														<th><#running_status#>
														</th>
														<td id="cloudflared_status"></td><td></td>
													</tr>
													
													
													<tr>
														<th>启用cloudflared</th>
														<td>
													<div class="main_itoggle">
													<div id="cloudflared_enable_on_of">
														<input type="checkbox" id="cloudflared_enable_fake" <% nvram_match_x("", "cloudflared_enable", "1", "value=1 checked"); %><% nvram_match_x("", "cloudflared_enable", "0", "value=0"); %>  />
													</div>
												</div>
												<div style="position: absolute; margin-left: -10000px;">
													<input type="radio" value="1" name="cloudflared_enable" id="cloudflared_enable_1" onClick="change_cloudflared_enable(1);" class="input" value="1" <% nvram_match_x("", "cloudflared_enable", "1", "checked"); %> /><#checkbox_Yes#>
													<input type="radio" value="0" name="cloudflared_enable" id="cloudflared_enable_0" onClick="change_cloudflared_enable(1);" class="input" value="0" <% nvram_match_x("", "cloudflared_enable", "0", "checked"); %> /><#checkbox_No#>
												</div>
											</td>
													<td colspan="4">
                                                <input class="btn btn-success" style="width:150px" type="button" name="updatecloudflared" value="更新" onclick="button_updatecloudflared()" />
                                            </td>
													</tr><td colspan="3"></td>
													<tr>
											<th style="border-top: 0 none;">自定义启动参数:</th>
											<td colspan="3" style="border-top: 0 none;">
											<div class="input-append">
												<textarea maxlength="8000" class="input" name="cloudflared_cmd" id="cloudflared_cmd" placeholder="tunnel --no-autoupdate --loglevel info --logfile /tmp/cloudflared.log run --token eyJh开头的token" style="width: 400px; height: 30px; resize: both; overflow: auto;"><% nvram_get_x("","cloudflared_cmd"); %></textarea>
											</div>不需要加程序路径和程序名，直接填写启动参数即可。<br>日志请指定--logfile /tmp/cloudflared.log &nbsp;&nbsp;<a href="https://www.toutiao.com/video/7185909714687885858/" target="blank">教程</a>
											</td>
										</tr><td colspan="3"></td>
<tr>										<tr>
											<th style="border-top: 0 none;">程序路径:</th>
											<td colspan="3" style="border-top: 0 none;">
											<div class="input-append">
												<textarea maxlength="8000" class="input" name="cloudflared_bin" id="cloudflared_bin" placeholder="/etc/storage/bin/cloudflared" style="width: 400px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","cloudflared_bin"); %></textarea>
											</div>指定cloudflared程序路径和程序名,程序下载地址：<a href="https://wwf.lanpv.com/b05evijeh" target="blank">点此下载</a>&nbsp;&nbsp;密码8267
											</td>
										</tr>
											<td colspan="4">
												<br />
												<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
											</td>
										</tr>
										<tr>
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('cflog')"><span>点击查看/tmp/cloudflared.log日志</span></a>
	<div id="cflog" style="display:none;">
	<textarea rows="24" readonly="readonly" wrap="off" spellcheck="false" class="span12" name="cloudflared.log" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("cloudflared.log",""); %></textarea>
	</div>
	</td>
	</tr>
</div>
</body>
</html>

