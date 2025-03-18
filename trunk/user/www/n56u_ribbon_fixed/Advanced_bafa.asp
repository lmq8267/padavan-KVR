<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - 巴法云物联网</title>
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

<% bafa_status(); %>
<% login_state_hook(); %>
$j(document).ready(function() {

	init_itoggle('bafa_enable');
	init_itoggle('bafa_show');
	$j("#tab_bafa_cfg, #tab_bafa_log").click(
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
	show_menu(5,33,0);
	fill_status(bafa_status());
	show_footer();
	if (!login_safe())
        		textarea_scripts_enabled(0);

}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("bafa_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

var arrHashes = ["cfg","log"];
function showTab(curHash) {
	var obj = $('tab_bafa_' + curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
	curHash = '#cfg';
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_bafa_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_bafa_' + arrHashes[i]).show();
		} else {
			$j('#wnd_bafa_' + arrHashes[i]).hide();
			$j('#tab_bafa_' + arrHashes[i]).parents('li').removeClass('active');
			}
		}
	window.location.hash = curHash;
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_bafa.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}


function done_validating(action){
	refreshpage();
}

function textarea_scripts_enabled(v){
    	inputCtrl(document.form['scripts.bafa_script.sh'], v);
}

function button_restartBAFA(){
    	var $j = jQuery.noConflict();
    	$j.post('/apply.cgi',
    	{
        		'action_mode': ' RestartBAFA ',
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

	<input type="hidden" name="current_page" value="Advanced_bafa.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="BAFA;LANHostConfig;General;">
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
	<h2 class="box_head round_top">巴法云</h2>
	<div class="round_bottom">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a id="tab_bafa_cfg" href="#cfg">基本设置</a></li>
	<li><a id="tab_bafa_log" href="#log">运行日志</a></li>
	</ul>
	</div>
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div id="wnd_bafa_cfg">
	<div class="alert alert-info" style="margin: 10px;">
	通过MQTT协议连接巴法云，可接入米家等智能家居控制系统，实现远程控制语言控制设备。<br>
	<div>【官网】：<a href="https://cloud.bemfa.com/" target="blank">cloud.bemfa.com</a>&nbsp;&nbsp;【控制台】：<a href="https://cloud.bemfa.com/tcp/devicemqtt.html" target="blank">cloud.bemfa.com/tcp/devicemqtt.html</a></div>
	
	</div>
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th><#running_status#>
	</th>
	<td colspan="4" id="bafa_status"></td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用巴法云</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="bafa_enable_on_of">
		<input type="checkbox" id="bafa_enable_fake" <% nvram_match_x("", "bafa_enable", "1", "value=1 checked"); %><% nvram_match_x("", "bafa_enable", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="bafa_enable" id="bafa_enable_1" class="input" value="1" <% nvram_match_x("", "bafa_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="bafa_enable" id="bafa_enable_0" class="input" value="0" <% nvram_match_x("", "bafa_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restartJYL" value="重启" onclick="button_restartBAFA()" />
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">主题</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<textarea maxlength="1024" class="input" name="bafa_topics" id="bafa_topics" placeholder="test001,test002" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","bafa_topics"); %></textarea>
	</div><span style="color:#888;">多个主题使用英文逗号分隔</span>
	</td>
	</tr><td colspan="4"></td>	
	<tr>
	<th width="30%" style="border-top: 0 none;">私钥</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input name="bafa_token" type="text" class="input" id="bafa_token" placeholder="666b5v2b71d34bf74aa3b3560666d8gg" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","bafa_token"); %>" size="32" maxlength="32" />
	</div>
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">QOS等级</th>
	<td style="border-top: 0 none;">
	<select name="bafa_qos" class="input">
	<option value="0" <% nvram_match_x("","bafa_qos", "0","selected"); %>>0</option>
	<option value="1" <% nvram_match_x("","bafa_qos", "1","selected"); %>>1</option>
	<option value="2" <% nvram_match_x("","bafa_qos", "2","selected"); %>>2</option>
	  </select>
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">服务器地址</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input name="bafa_host" type="text" class="input" id="bafa_host" placeholder="bemfa.com" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","bafa_host"); %>" size="32" maxlength="128" />
	</div>
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">端口</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="5" class="input" size="15" name="bafa_port" id="bafa_port" placeholder="9501" value="<% nvram_get_x("","bafa_port"); %>" onKeyPress="return is_number(this,event);"/>
	&nbsp;<span style="color:#888;">[9501]</span>
	</div>
	</td>
	</tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;" title="在接收到消息的时候输出主题名，此时$1为主题名 $2才是消息内容">输出主题名</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="bafa_show_on_of">
	<input type="checkbox" id="bafa_show_fake" <% nvram_match_x("", "bafa_show", "1", "value=1 checked"); %><% nvram_match_x("", "bafa_show", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="bafa_show" id="bafa_show_1" class="input" value="1" <% nvram_match_x("", "bafa_show", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="bafa_show" id="bafa_show_0" class="input" value="0" <% nvram_match_x("", "bafa_show", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="4"></td>	
	<tr>
	<th width="30%" style="border-top: 0 none;">程序路径</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<textarea maxlength="1024" class="input" name="bafa_bin" id="bafa_bin" placeholder="/etc/storage/bin/stdoutsubc" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","bafa_bin"); %></textarea>
	</div><span style="color:#888;">指定stdoutsubc程序路径和程序名，完整路径</span>
	</td>
	</tr>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('bfscript')"><span>点这里自定义 /etc/storage/bafa_script.sh 脚本</span></a>
	<div id="bfscript" style="display:none;">
	<textarea rows="24" wrap="off" spellcheck="false" maxlength="81920" class="span12" name="scripts.bafa_script.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.bafa_script.sh",""); %></textarea>
	</div>
	</td>
	</tr>			
	<tr>
	<td colspan="4">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr>																	
	</table>
	</div>
	</div>
	
	</div>
	<div id="wnd_bafa_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("bafayun.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.reload()" value="刷新日志" class="btn btn-primary" style="width: 200px">
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

