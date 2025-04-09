<!DOCTYPE html>
<!--Copyright by hiboy-->
<html>
<head>
<title><#Web_Title#> - 微信推送</title>
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
<% wxsend_status(); %>
<% login_state_hook(); %>

</script>
<script>

function initial(){
	show_banner(2);
	show_menu(5, 24, 0);
	show_footer();
	fill_status(wxsend_status());
	change_wxsend_enable();
	if (!login_safe())
        		textarea_scripts_enabled(0);

}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("wxsend_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function applyRule(){
//	if(validForm()){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_wxsend.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
//	}
}

function done_validating(action){
	refreshpage();
}

function textarea_scripts_enabled(v){
    	inputCtrl(document.form['scripts.wxsend_script.sh'], v);
}

function change_wxsend_enable(){
	var m = document.form.wxsend_enable.value;
	var is_wxsend_enable = (m == "1" || m == "2") ? "重启" : "清空以往接入设备名称";
	document.form.restartwxsend.value = is_wxsend_enable;
	
	if (m == "1") {
		showhide_div("appid_tr", 1);
		showhide_div("appsecret_tr", 1);
		showhide_div("touser_tr", 1);
		showhide_div("template_tr", 1);
		
    		showhide_div("webhook_tr", 0);   
	} 
	if (m == "2") {
		showhide_div("appid_tr", 0);
		showhide_div("appsecret_tr", 0);
		showhide_div("touser_tr", 0);
		showhide_div("template_tr", 0);
		
    		showhide_div("webhook_tr", 1);  
	} 
}
function button_restartwxsend() {
    var m = document.form.wxsend_enable.value;

    var actionMode = (m == "1" || m == "2") ? ' Restartwxsend ' : ' Delwxsend ';

    change_wxsend_enable(); 

    var $j = jQuery.noConflict(); 
    $j.post('/apply.cgi', {
        'action_mode': actionMode 
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

	<input type="hidden" name="current_page" value="Advanced_wxsend.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="WXSEND;LANHostConfig;General;">
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
	<h2 class="box_head round_top">微信推送</h2>
	<div class="round_bottom">
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div class="alert alert-info" style="margin: 10px;">欢迎使用 微信推送 - 这是一个使用微信官方的接口权限推送微信消息的工具，可以发送路由日志消息到手机，也可部署 api 提供外部程序使用消息推送。
	<br><div>①自建微信推送：查看 <a href="https://developers.weixin.qq.com/doc/offiaccount/Message_Management/Template_Message_Interface.html" target="blank">【发送模板消息接口文档】</a> ，打开图文教程设置测试号信息【<a href="https://opt.cn2qq.com/opt-file/测试号配置.pdf" target="blank">https://opt.cn2qq.com/opt-file/测试号配置.pdf</a>】（每日调用上限：100000次）</div>
	<div>②企业微信推送：下载企业微信APP，查看<a href="https://open.work.weixin.qq.com/wwopen/helpguide/detail?t=register" target="blank">【创建&注册文档】</a> 无需认证，然后在群里新建机器人，<a href="https://work.weixin.qq.com/wework_admin/frame#/profile/wxPlugin" target="blank">打开【PC端管理平台】</a>，普通微信扫描二维码接收消息推送<a href="https://open.work.weixin.qq.com/help/wap/detail?docid=14797" target="blank">【接收微信插件消息】</a>（每分钟调用上限：20次）</div>
	<span style="color:#FF0000;" class=""></span></div>

	<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr> <th><#running_status#></th>
            <td id="wxsend_status" colspan="2"></td>
          </tr>
	<tr id="wxsend_enable_tr" >
	<th width="30%">启用微信推送</th>
	<td>
	<select name="wxsend_enable" class="input" onChange="change_wxsend_enable();" style="width: 185px;">
	<option value="0" <% nvram_match_x("","wxsend_enable", "0","selected"); %>>【关闭】</option>
	<option value="1" <% nvram_match_x("","wxsend_enable", "1","selected"); %>>【自建微信推送】</option>
	<option value="2" <% nvram_match_x("","wxsend_enable", "2","selected"); %>>【企业微信推送】</option>
	</select>
	</td>
	<td>
	<input class="btn btn-success" style="width:150px" type="button" name="restartwxsend" value="清空以往接入设备名称" onclick="button_restartwxsend()" />
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;" >账户信息</th>
	</tr>
	<tr id="appid_tr" style="display:none;">
	<th style="border-top: 0 none;">appID:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="512" class="input" size="15" name="wxsend_appid" id="wxsend_appid" placeholder="wx664325dd223" style="width: 175px;" value="<% nvram_get_x("","wxsend_appid"); %>" onKeyPress="return is_string(this,event);"/>
	</div>
	</td>
	<td style="border-top: 0 none;">
	&nbsp;<span style="color:#888;"><a href="https://mp.weixin.qq.com/debug/cgi-bin/sandbox?t=sandbox/login" target="_blank">测试号管理（申请）页面</a></span>
	</td>
	</tr>
	<tr id="appsecret_tr" style="display:none;">
	<th style="border-top: 0 none;">appsecret:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="512" class="input" size="15" name="wxsend_appsecret" id="wxsend_appsecret" placeholder="51745687314624" style="width: 175px;" value="<% nvram_get_x("","wxsend_appsecret"); %>" onKeyPress="return is_string(this,event);"/>
	</div>
	</td>
	</tr>
	<tr id="touser_tr" style="display:none;">
	<th style="border-top: 0 none;">微信号:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="512" class="input" size="15" name="wxsend_touser" id="wxsend_touser" placeholder="o3Knhvl4ehk4aBLTiIgr7x4CQL2Y" style="width: 175px;" value="<% nvram_get_x("","wxsend_touser"); %>" onKeyPress="return is_string(this,event);"/>
	</div>
	</td>
	</tr>
	<tr id="template_tr" style="display:none;">
	<th style="border-top: 0 none;">模板ID:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="512" class="input" size="15" name="wxsend_template_id" id="wxsend_template_id" placeholder="13HLGhTDVTbG" style="width: 175px;" value="<% nvram_get_x("","wxsend_template_id"); %>" onKeyPress="return is_string(this,event);"/>
	</div>
	</td>
	</tr>
	<tr id="webhook_tr" style="display:none;">
	<th style="border-top: 0 none;">webhook地址:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="512" class="input" size="15" name="wxsend_webhook" id="wxsend_webhook" placeholder="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=693axxx6-7aoc-4bc4-97a0-0ec2sifa5aaa" style="width: 175px;" value="<% nvram_get_x("","wxsend_webhook"); %>" onKeyPress="return is_string(this,event);"/>
	</div>
	</td>
	</tr>
	<tr>
	<th style="border-top: 0 none;">消息标记:</th>
	<td style="border-top: 0 none;">
	<div class="input-append">
	<input maxlength="512" class="input" size="15" name="wxsend_title" id="wxsend_title" placeholder="<% nvram_get_x("","computer_name"); %>" style="width: 175px;" value="<% nvram_get_x("","wxsend_title"); %>" onKeyPress="return is_string(this,event);"/>
	</div>
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;" >在线发送（测试消息）</th>
	</tr>
	<tr>
	<th style="border: 0 none;">消息内容:</th>
	<td style="border: 0 none;" colspan="3">
	<textarea rows="3" wrap="off" spellcheck="false" maxlength="65536" class="span12" name="wxsend_content" id="wxsend_content" placeholder="消息内容 | 或换行分割消息：单个字段内容不超过 20 个字,最多 6 段字符" value="<% nvram_get_x("","wxsend_content"); %>" onKeyPress="return is_string(this,event);"></textarea>
	</td>
	</tr>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<center><input class="btn btn-success" style="width: 219px" type="button" value="发送消息" onclick="applyRule()" /></center>
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;" >通知提醒</th>
	</tr>
	<tr>
	<th style="border: 0 none;" width="30%">互联网 IP 变动:</th>
	<td style="border-top: 0 none;">
	<select name="wxsend_notify_1" class="input">
	<option value="0" <% nvram_match_x("","wxsend_notify_1", "0","selected"); %>>关闭</option>
	<option value="1" <% nvram_match_x("","wxsend_notify_1", "1","selected"); %>>开启 IPv4</option>
	<option value="2" <% nvram_match_x("","wxsend_notify_1", "2","selected"); %>>开启 IPv6</option>
	<option value="3" <% nvram_match_x("","wxsend_notify_1", "3","selected"); %>>开启 IPv4 & IPv6</option>
	  </select>
	</td>
	</tr>
	<tr>
	<th style="border: 0 none;" width="30%">设备接入提醒:</th>
	<td style="border-top: 0 none;">
	<select name="wxsend_notify_2" class="input">
	<option value="0" <% nvram_match_x("","wxsend_notify_2", "0","selected"); %>>关闭</option>
	<option value="1" <% nvram_match_x("","wxsend_notify_2", "1","selected"); %>>开启</option>
	  </select>
	</td>
	</tr>
	<tr>
	<th style="border: 0 none;" width="30%">设备上、下线提醒:</th>
	<td style="border-top: 0 none;">
	<select name="wxsend_notify_3" class="input">
	<option value="0" <% nvram_match_x("","wxsend_notify_3", "0","selected"); %>>关闭</option>
	<option value="1" <% nvram_match_x("","wxsend_notify_3", "1","selected"); %>>开启</option>
	  </select>
	</td>
	</tr>
	<tr>
	<th style="border: 0 none;" width="30%">管理界面登录提醒:</th>
	<td style="border-top: 0 none;">
	<select name="wxsend_login" class="input">
	<option value="0" <% nvram_match_x("","wxsend_login", "0","selected"); %>>关闭</option>
	<option value="1" <% nvram_match_x("","wxsend_login", "1","selected"); %>>登录成功</option>
	<option value="2" <% nvram_match_x("","wxsend_login", "2","selected"); %>>验证失败</option>
	<option value="3" <% nvram_match_x("","wxsend_login", "3","selected"); %>>登录成功 & 验证失败</option>
	  </select>
	</td>
	</tr>
	<tr>
	<th style="border: 0 none;" width="30%">SSH登录提醒:</th>
	<td style="border-top: 0 none;">
	<select name="wxsend_ssh" class="input">
	<option value="0" <% nvram_match_x("","wxsend_ssh", "0","selected"); %>>关闭</option>
	<option value="1" <% nvram_match_x("","wxsend_ssh", "1","selected"); %>>登录成功</option>
	<option value="2" <% nvram_match_x("","wxsend_ssh", "2","selected"); %>>验证失败</option>
	<option value="3" <% nvram_match_x("","wxsend_ssh", "3","selected"); %>>登录成功 & 验证失败</option>
	  </select>
	</td>
	</tr>
	<tr>
	<th style="border: 0 none;" width="30%">自定义提醒:</th>
	<td style="border-top: 0 none;">
	<select name="wxsend_notify_4" class="input">
	<option value="0" <% nvram_match_x("","wxsend_notify_4", "0","selected"); %>>关闭</option>
	<option value="1" <% nvram_match_x("","wxsend_notify_4", "1","selected"); %>>开启</option>
	  </select><br><span style="color:#888;">自行修改下方脚本里的自定义提醒区域</span>
	</td>
	</tr>
	<tr id="serverchan_config">
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('wxscript')"><span>点这里自定义 /etc/storage/wxsend_script.sh 脚本</span></a>
	<div id="wxscript" style="display:none;">
	<textarea rows="24" wrap="off" spellcheck="false" maxlength="81920" class="span12" name="scripts.wxsend_script.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.wxsend_script.sh",""); %></textarea>
	</div>
	</td>
	</tr>
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


