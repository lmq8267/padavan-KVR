<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - VNT客户端</title>
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

$j(document).ready(function() {

	init_itoggle('vntcli_log');
	init_itoggle('vntcli_proxy');
	init_itoggle('vntcli_wg');
	init_itoggle('vntcli_first');
	init_itoggle('vntcli_finger');
	init_itoggle('vntcli_serverw');
	$j("#tab_vntcli_cfg, #tab_vntcli_pri, #tab_vntcli_sta, #tab_vntcli_log, #tab_vntcli_help").click(
	function () {
		var newHash = $j(this).attr('href').toLowerCase();
		showTab(newHash);
		return false;
	});

});

</script>
<script>
<% vntcli_status(); %>
<% login_state_hook(); %>
var m_routelist = [<% get_nvram_list("VNTCLI", "VNTCLIroute"); %>];
var mroutelist_ifield = 4;
if(m_routelist.length > 0){
	var m_routelist_ifield = m_routelist[0].length;
	for (var i = 0; i < m_routelist.length; i++) {
		m_routelist[i][mroutelist_ifield] = i;
	}
}

var m_mapplist = [<% get_nvram_list("VNTCLI", "VNTCLImapp"); %>];
var mmapplist_ifield = 5;
if(m_mapplist.length > 0){
	var m_mapplist_ifield = m_mapplist[0].length;
	for (var i = 0; i < m_mapplist.length; i++) {
		m_mapplist[i][mmapplist_ifield] = i;
	}
}

var isMenuopen = 0;
function initial(){
	show_banner(2);
	show_menu(5, 27, 0);
	showROUTEList();
	showMAPPList();
	show_footer();
	fill_status(vntcli_status());
	change_vntcli_enable(1);
	change_vntcli_model(1);
	if (!login_safe())
        		textarea_scripts_enabled(0);

}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("vntcli_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

var arrHashes = ["cfg","pri","sta","log","help"];
function showTab(curHash) {
	var obj = $('tab_vntcli_' + curHash.slice(1));
	if (obj == null || obj.style.display == 'none')
	curHash = '#cfg';
	for (var i = 0; i < arrHashes.length; i++) {
		if (curHash == ('#' + arrHashes[i])) {
			$j('#tab_vntcli_' + arrHashes[i]).parents('li').addClass('active');
			$j('#wnd_vntcli_' + arrHashes[i]).show();
		} else {
			$j('#wnd_vntcli_' + arrHashes[i]).hide();
			$j('#tab_vntcli_' + arrHashes[i]).parents('li').removeClass('active');
			}
		}
	window.location.hash = curHash;
}

function applyRule(){
	showLoading();
	
	document.form.action_mode.value = " Apply ";
	document.form.current_page.value = "/Advanced_vnt.asp";
	document.form.next_page.value = "";
	
	document.form.submit();
}

function done_validating(action){
	refreshpage();
}

function textarea_scripts_enabled(v){
    	inputCtrl(document.form['scripts.vnt.conf'], v);
}


function change_vntcli_model(mflag){
	var m = document.form.vntcli_model.value;
	var Showmodel = (m >= 1 && m <= 7);


	showhide_div("vntcli_key_tr", Showmodel);
	showhide_div("vntcli_key_td", Showmodel);
}

function change_vntcli_enable(mflag){
	var m = document.form.vntcli_enable.value;
	var is_vntcli_enable = (m == "1" || m == "2") ? "重启" : "更新";
	document.form.restartvntcli.value = is_vntcli_enable;

	var is_vntcli_file = (m == "2") ? 1 : 0;
	showhide_div("vntcli_file_tr", is_vntcli_file);
	
	var is_vntcli_log = (m == "1" || m == "2") ? 1 : 0;
	showhide_div("vntcli_log_tr", is_vntcli_log);
	showhide_div("vntcli_log_td", is_vntcli_log);

	var is_vntcli_cmd = (m == "1") ? 1 : 0;
	showhide_div("vntcli_token_tr", is_vntcli_cmd);
	showhide_div("vntcli_token_td", is_vntcli_cmd);
	showhide_div("vntcli_ip_tr", is_vntcli_cmd);
	showhide_div("vntcli_ip_td", is_vntcli_cmd);
	showhide_div("vntcli_localadd_tr", is_vntcli_cmd);
	showhide_div("vntcli_localadd_td", is_vntcli_cmd);
	showhide_div("vntcli_serip_tr", is_vntcli_cmd);
	showhide_div("vntcli_serip_td", is_vntcli_cmd);
	showhide_div("vntcli_model_tr", is_vntcli_cmd);
	showhide_div("vntcli_model_td", is_vntcli_cmd);
	showhide_div("vntcli_subnet_table", is_vntcli_cmd);
	showhide_div("vntcli_pri_table", is_vntcli_cmd);
	showhide_div("vntcli_mapping_table", is_vntcli_cmd);

	var is_vntcli_mtu = (m == "1") ? 1 : 0;
	if(is_vntcli_mtu){
		o_mtu = document.form.vntcli_mtu;
		if (o_mtu && parseInt(o_mtu.value) == 0)
			o_mtu.value = "";
		if (o_mtu && parseInt(o_mtu.value) > 1500)
			o_mru.value = "1500";
	}
}

function button_restartvntcli() {
    var m = document.form.vntcli_enable.value;

    var actionMode = (m == "1" || m == "2") ? ' Restartvntcli ' : ' Updatevntcli ';

    change_vntcli_enable(m); 

    var $j = jQuery.noConflict(); 
    $j.post('/apply.cgi', {
        'action_mode': actionMode 
    });
}

function markrouteRULES(o, c, b) {
	document.form.group_id.value = "VNTCLIroute";
	if(b == " Add "){
		if (document.form.vntcli_routenum_x_0.value >= c){
			alert("<#JS_itemlimit1#> " + c + " <#JS_itemlimit2#>");
			return false;
		}else if (document.form.vntcli_route_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_route_x_0.focus();
			document.form.vntcli_route_x_0.select();
			return false;
		}else if(document.form.vntcli_ip_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_ip_x_0.focus();
			document.form.vntcli_ip_x_0.select();
			return false;
		}else{
			for(i=0; i<m_routelist.length; i++){
				if(document.form.vntcli_route_x_0.value==m_routelist[i][1]) {
				if(document.form.vntcli_ip_x_0.value==m_routelist[i][2]) {
					alert('<#JS_duplicate#>' + ' (' + m_routelist[i][1] + ')' );
					document.form.vntcli_route_x_0.focus();
					document.form.vntcli_ip_x_0.select();
					return false;
					}
				}
			}
		}
	}
	pageChanged = 0;
	document.form.action_mode.value = b;
	return true;
}

function markmappRULES(o, c, b) {
	document.form.group_id.value = "VNTCLImapp";
	if(b == " Add "){
		if (document.form.vntcli_mappnum_x_0.value >= c){
			alert("<#JS_itemlimit1#> " + c + " <#JS_itemlimit2#>");
			return false;
		}else if (document.form.vntcli_mappport_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_mappport_x_0.focus();
			document.form.vntcli_mappport_x_0.select();
			return false;
		}else if(document.form.vntcli_mappip_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_mappip_x_0.focus();
			document.form.vntcli_mappip_x_0.select();
			return false;
		}else if(document.form.vntcli_mapeerport_x_0.value==""){
			alert("<#JS_fieldblank#>");
			document.form.vntcli_mapeerport_x_0.focus();
			document.form.vntcli_mapeerport_x_0.select();
			return false;
		}else{
			for(i=0; i<m_mapplist.length; i++){
				if(document.form.vntcli_mappnet_x_0.value==m_mapplist[i][0]) {
					if(document.form.vntcli_mappport_x_0.value==m_mapplist[i][1]) {
						if(document.form.vntcli_mappip_x_0.value==m_mapplist[i][2]) {
							if(document.form.vntcli_mapeerport_x_0.value==m_mapplist[i][3]) {
								alert('<#JS_duplicate#>' + ' (' + m_mapplist[i][1] + ')' );
								document.form.vntcli_mapeerport_x_0.focus();
								document.form.vntcli_mapeerport_x_0.select();
								return false;
							}
						}
					}
				}
			}
		}
	}
	pageChanged = 0;
	document.form.action_mode.value = b;
	return true;
}

function showROUTEList(){
	var code = '<table width="100%" cellspacing="0" cellpadding="4" class="table table-list">';
	if(m_routelist.length == 0)
		code +='<tr><td colspan="5" style="text-align: center;"><div class="alert alert-info"><#IPConnection_VSList_Norule#></div></td></tr>';
	else{
	    for(var i = 0; i < m_routelist.length; i++){
		code +='<tr id="rowrl' + i + '">';
		code +='<td width="30%">&nbsp;' + m_routelist[i][0] + '</td>';
		code +='<td width="40%">&nbsp;' + m_routelist[i][1] + '</td>';
		code +='<td width="40%">' + m_routelist[i][2] + '</td>';
		code +='<td width="50%"></td>';
		code +='<center><td width="20%" style="text-align: center;"><input type="checkbox" name="VNTCLIroute_s" value="' + m_routelist[i][mroutelist_ifield] + '" onClick="changeBgColorrl(this,' + i + ');" id="check' + m_routelist[i][mroutelist_ifield] + '"></td></center>';
		
		code +='</tr>';
	    }
		code += '<tr>';
		code += '<td colspan="5">&nbsp;</td>'
		code += '<td><button class="btn btn-danger" type="submit" onclick="markrouteRULES(this, 64, \' Del \');" name="VNTCLIroute"><i class="icon icon-minus icon-white"></i></button></td>';
		code += '</tr>'
	}
	code +='</table>';
	$("MrouteRULESList_Block").innerHTML = code;
}

function showMAPPList(){
	var code = '<table width="100%" cellspacing="0" cellpadding="4" class="table table-list">';
	if(m_mapplist.length == 0)
		code +='<tr><td colspan="5" style="text-align: center;"><div class="alert alert-info"><#IPConnection_VSList_Norule#></div></td></tr>';
	else{
	    for(var i = 0; i < m_mapplist.length; i++){
		if(m_mapplist[i][0] == 0)
		vntcli_mappnet="TCP";
		else{
		vntcli_mappnet="UDP";
		}
		code +='<tr id="rowrl' + i + '">';
		code +='<td width="15%">&nbsp;' + vntcli_mappnet + '</td>';
		code +='<td width="25%">&nbsp;' + m_mapplist[i][1] + '</td>';
		code +='<td width="30%">' + m_mapplist[i][2] + '</td>';
		code +='<td width="20%">&nbsp;' + m_mapplist[i][3] + '</td>';
		code +='<td width="50%"></td>';
		code +='<center><td width="20%" style="text-align: center;"><input type="checkbox" name="VNTCLImapp_s" value="' + m_mapplist[i][mmapplist_ifield] + '" onClick="changeBgColorrl(this,' + i + ');" id="check' + m_mapplist[i][mmapplist_ifield] + '"></td></center>';
		
		code +='</tr>';
	    }
		code += '<tr>';
		code += '<td colspan="5">&nbsp;</td>'
		code += '<td><button class="btn btn-danger" type="submit" onclick="markmappRULES(this, 64, \' Del \');" name="VNTCLImapp"><i class="icon icon-minus icon-white"></i></button></td>';
		code += '</tr>'
	}
	code +='</table>';
	$("MmappRULESList_Block").innerHTML = code;
}

function clearLog(){
	document.form.current_page.value = "Advanced_vnt.asp#log";
	document.form.next_host.value = "Advanced_vnt.asp#log";
	document.form.action_mode.value = " ClearvntcliLog ";
	document.form.submit();
}

function button_vntcli_info(){
	document.form.next_host.value = "Advanced_vnt.asp";
	document.form.action_mode.value = " CMDvntinfo ";
	document.form.submit();
}

function button_vntcli_all(){
	document.form.next_host.value = "Advanced_vnt.asp#sta";
	document.form.action_mode.value = " CMDvntall ";
	document.form.submit();
}

function button_vntcli_list(){
	document.form.next_host.value = "Advanced_vnt.asp#sta";
	document.form.action_mode.value = " CMDvntlist ";
	document.form.submit();
}

function button_vntcli_route(){
	document.form.next_host.value = "Advanced_vnt.asp#sta";
	document.form.action_mode.value = " CMDvntroute ";
	document.form.submit();
}

function button_vntcli_status(){
	document.form.next_host.value = "Advanced_vnt.asp#sta";
	document.form.action_mode.value = " CMDvntstatus ";
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

	<input type="hidden" name="current_page" value="Advanced_vnt.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="VNTCLI;LANHostConfig;General;">
	<input type="hidden" name="group_id" value="VNTCLIroute;VNTCLImapp">
	<input type="hidden" name="action_mode" value="">
	<input type="hidden" name="action_script" value="">
	<input type="hidden" name="vntcli_routenum_x_0" value="<% nvram_get_x("VNTCLIroute", "vntcli_routenum_x"); %>" readonly="1" />
	<input type="hidden" name="vntcli_mappnum_x_0" value="<% nvram_get_x("VNTCLImapp", "vntcli_mappnum_x"); %>" readonly="1" />

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
	<h2 class="box_head round_top">VNT客户端</h2>
	<div class="round_bottom">
	<div>
	<ul class="nav nav-tabs" style="margin-bottom: 10px;">
	<li class="active"><a id="tab_vntcli_cfg" href="#cfg">基本设置</a></li>
	<li><a id="tab_vntcli_pri" href="#pri">高级设置</a></li>
	<li><a id="tab_vntcli_sta" href="#sta">运行状态</a></li>
	<li><a id="tab_vntcli_log" href="#log">运行日志</a></li>
	<li><a id="tab_vntcli_help" href="#help">帮助说明</a></li>

	</ul>
	</div>
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div id="wnd_vntcli_cfg">
	<div class="alert alert-info" style="margin: 10px;">
	vnt是一个简便高效的异地组网、内网穿透工具。&nbsp;&nbsp;&nbsp;&nbsp;安卓、Windows客户端：<a href="https://github.com/vnt-dev/VntApp" target="blank">VntApp</a><br>
	<div>项目地址：<a href="https://github.com/vnt-dev/vnt" target="blank">github.com/vnt-dev/vnt</a>&nbsp;&nbsp;&nbsp;&nbsp;官网：<a href="https://rustvnt.com" target="blank">rustvnt.com</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群1：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=9aa1l03sqBPU-rMIzJ52gcmjq9HsO0tA&authKey=FFA0UdK6Dg1wAvL4e9FvyEu3DxekIlYp9W4NaQ54DO2dzQM%2BKS3rShUSwt9BN0bL&noverify=0&group_code=1034868233" target="blank">1034868233</a>&nbsp;&nbsp;&nbsp;&nbsp;QQ群2：<a href="http://qm.qq.com/cgi-bin/qm/qr?_wv=1027&k=H4czBrp-IUxgTJ9wem0eXFHPdADkKTVW&authKey=JXU4v4ZQSXupcHOYUCOVgU0rDUdEe1ZfGVWzRVqRecxXY4cg%2BgfHl7n%2F%2F6nGSDH2&noverify=0&group_code=950473757" target="blank">950473757</a></div>
	<br><div>当前版本:【<span style="color: #FFFF00;"><% nvram_get_x("", "vntcli_ver"); %></span>】&nbsp;&nbsp;最新版本:【<span style="color: #FD0187;"><% nvram_get_x("", "vntcli_ver_n"); %></span>】 </div>
	</div>
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">开关</th>
	</tr>
	<tr>
	<th><#running_status#>
	</th>
	<td id="vntcli_status"></td><td></td>
	</tr>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用vnt-cli</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_enable" class="input" onChange="change_vntcli_enable();" style="width: 185px;">
	<option value="0" <% nvram_match_x("","vntcli_enable", "0","selected"); %>>【关闭】</option>
	<option value="1" <% nvram_match_x("","vntcli_enable", "1","selected"); %>>【开启】</option>
	<option value="2" <% nvram_match_x("","vntcli_enable", "2","selected"); %>>【开启】配置文件</option>
	</select>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restartvntcli" value="更新" onclick="button_restartvntcli()" />
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;">基础设置</th>
	</tr>
	<tr id="vntcli_file_tr">
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('scripts.vnt')"><span>点此修改 /etc/storage/vnt.conf 配置文件</span></a>&nbsp;&nbsp;&nbsp;&nbsp;配置文件模板：<a href="https://github.com/vnt-dev/vnt/blob/main/vnt-cli/README.md#-f-conf" target="blank">点此查看</a>
	<div id="scripts.vnt">
	<textarea rows="18" wrap="off" spellcheck="false" maxlength="2097152" class="span12" name="scripts.vnt.conf" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.vnt.conf",""); %></textarea>
	</div>
	</td>
	</tr>
	<tr id="vntcli_token_tr">
	<th width="30%" style="border-top: 0 none;">Token</th>
	<td style="border-top: 0 none;">
	<input type="password" maxlength="63" class="input" size="15" id="vntcli_token" name="vntcli_token" style="width: 175px;" value="<% nvram_get_x("","vntcli_token"); %>" onKeyPress="return is_string(this,event);" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('vntcli_token')"><i class="icon-eye-close"></i></button>&nbsp;<span style="color:#888;">必填项</span>
	</td>
	</tr><tr id="vntcli_token_td"><td colspan="3"></td></tr>
	<tr id="vntcli_ip_tr">
	<th width="30%" style="border-top: 0 none;">接口IP</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="10.26.0.2" id="vntcli_ip" name="vntcli_ip" value="<% nvram_get_x("","vntcli_ip"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr><tr id="vntcli_ip_td"><td colspan="3"></td></tr>
	<tr id="vntcli_localadd_tr">
	<th width="30%" style="border-top: 0 none;">本地网段</th>
	<td style="border-top: 0 none;">
	<textarea maxlength="256" class="input" name="vntcli_localadd" id="vntcli_localadd" placeholder="192.168.2.0/24" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vntcli_localadd"); %></textarea>
	<br>&nbsp;<span style="color:#888;">多个网段使用换行分隔</span>
	</td>
	</tr><tr id="vntcli_localadd_td"><td colspan="3"></td></tr>
	<tr id="vntcli_serip_tr">
	<th width="30%" style="border-top: 0 none;">服务器地址</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="tcp://vnt.wherewego.top:29872" id="vntcli_serip" name="vntcli_serip" value="<% nvram_get_x("","vntcli_serip"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr><tr id="vntcli_serip_td"><td colspan="3"></td></tr>
	<tr id="vntcli_model_tr">
	<th width="30%" style="border-top: 0 none;">加密方式</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_model" class="input" onChange="change_vntcli_model();" style="width: 185px;">
	<option value="0" <% nvram_match_x("","vntcli_model", "0","selected"); %>>不加密</option>
	<option value="1" <% nvram_match_x("","vntcli_model", "1","selected"); %>>xor</option>
	<option value="2" <% nvram_match_x("","vntcli_model", "2","selected"); %>>aes_ecb</option>
	<option value="3" <% nvram_match_x("","vntcli_model", "3","selected"); %>>chacha20</option>
	<option value="4" <% nvram_match_x("","vntcli_model", "4","selected"); %>>chacha20_poly1305</option>
	<option value="5" <% nvram_match_x("","vntcli_model", "5","selected"); %>>sm4_cbc</option>
	<option value="6" <% nvram_match_x("","vntcli_model", "6","selected"); %>>aes_cbc</option>
	<option value="7" <% nvram_match_x("","vntcli_model", "7","selected"); %>>aes_gcm</option>
	</select>
	</td>
	</tr>
	<tr id="vntcli_key_tr">
	<th width="30%" style="border-top: 0 none;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;密码</th>
	<td style="border-top: 0 none;">
	<input type="password" maxlength="256" class="input" size="15" id="vntcli_key" name="vntcli_key" style="width: 175px;" value="<% nvram_get_x("","vntcli_key"); %>" onKeyPress="return is_string(this,event);" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('vntcli_key')"><i class="icon-eye-close"></i></button><br>&nbsp;<span style="color:#888;">不要使用 <span style="color: yellow;">;</span> 符号</span>
	</td>
	</tr><tr id="vntcli_log_td"><td colspan="3"></td></tr>
	<tr id="vntcli_log_tr">
	<th style="border-top: 0 none;">启用日志</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_log_on_of">
	<input type="checkbox" id="vntcli_log_fake" <% nvram_match_x("", "vntcli_log", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_log", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_log" id="vntcli_log_1" class="input" value="1" <% nvram_match_x("", "vntcli_log", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_log" id="vntcli_log_0" class="input" value="0" <% nvram_match_x("", "vntcli_log", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><tr id="vntcli_log_td"><td colspan="3"></td></tr>
	<table id="vntcli_subnet_table" width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr> <th colspan="4" style="background-color: #756c78;">子网配置 (访问对端内网设备，还需对端配置本地网段)</th></tr>
	<tr id="row_rules_caption">
	<th width="10%"> 备注名称 </th>
	<th width="20%">对端目标网段 </th>
	<th width="20%">对端接口IP </th>
	<th width="5%"><center><i class="icon-th-list"></i></center></th>
	</tr>
	<tr>
	<th><input type="text" placeholder="可留空" maxlength="128" class="span12" style="width: 100px" size="200" name="vntcli_name_x_0" value="<% nvram_get_x("", "vntcli_name_x_0"); %>"/></th>
	<th><input type="text" placeholder="192.168.2.0/24" maxlength="255" class="span12" style="width: 150px" size="200" name="vntcli_route_x_0" value="<% nvram_get_x("", "vntcli_route_x_0"); %>"/></th>
	<th><input type="text" placeholder="10.26.0.2" maxlength="255" class="span12" style="width: 150px" size="200" name="vntcli_ip_x_0" value="<% nvram_get_x("", "vntcli_ip_x_0"); %>" /></th>
	<th><button class="btn" style="max-width: 219px" type="submit" onclick="return markrouteRULES(this, 64, ' Add ');" name="markrouteRULES2" value="<#CTL_add#>" size="12"><i class="icon icon-plus"></i></button></th>
	</tr>
	<tr id="row_rules_body" >
	<td colspan="4" style="border-top: 0 none; padding: 0px;">
	<div id="MrouteRULESList_Block"></div>
	</td>
	</tr>
	</table>
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
	<!-- 高级设置 -->
	<div id="wnd_vntcli_pri" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<table id="vntcli_pri_table" width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<th colspan="4" style="background-color: #756c78;">进阶设置</th>
	</tr>
	<tr id="vntcli_proxy_tr" >
	<th style="border-top: 0 none;">启用IP转发</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_proxy_on_of">
	<input type="checkbox" id="vntcli_proxy_fake" <% nvram_match_x("", "vntcli_proxy", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_proxy", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_proxy" id="vntcli_proxy_1" class="input" value="1" <% nvram_match_x("", "vntcli_proxy", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_proxy" id="vntcli_proxy_0" class="input" value="0" <% nvram_match_x("", "vntcli_proxy", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2"></td>
	<tr>
	<th style="border-top: 0 none;">启用优化传输</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_first_on_of">
	<input type="checkbox" id="vntcli_first_fake" <% nvram_match_x("", "vntcli_first", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_first", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_first" id="vntcli_first_1" class="input" value="1" <% nvram_match_x("", "vntcli_first", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_first" id="vntcli_first_0" class="input" value="0" <% nvram_match_x("", "vntcli_first", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2"></td>
	<tr>
	<th style="border-top: 0 none;">允许WireGuard访问</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_wg_on_of">
	<input type="checkbox" id="vntcli_wg_fake" <% nvram_match_x("", "vntcli_wg", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_wg", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_wg" id="vntcli_wg_1" class="input" value="1" <% nvram_match_x("", "vntcli_wg", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_wg" id="vntcli_wg_0" class="input" value="0" <% nvram_match_x("", "vntcli_wg", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2"></td>
	<tr>
	<th style="border-top: 0 none;">启用数据指纹校验</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_finger_on_of">
	<input type="checkbox" id="vntcli_finger_fake" <% nvram_match_x("", "vntcli_finger", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_finger", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_finger" id="vntcli_finger_1" class="input" value="1" <% nvram_match_x("", "vntcli_finger", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_finger" id="vntcli_finger_0" class="input" value="0" <% nvram_match_x("", "vntcli_finger", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2"></td>
	<tr>
	<th style="border-top: 0 none;">启用服务端客户端加密</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="vntcli_serverw_on_of">
	<input type="checkbox" id="vntcli_serverw_fake" <% nvram_match_x("", "vntcli_serverw", "1", "value=1 checked"); %><% nvram_match_x("", "vntcli_serverw", "0", "value=0"); %> />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="vntcli_serverw" id="vntcli_serverw_1" class="input" value="1" <% nvram_match_x("", "vntcli_serverw", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="vntcli_serverw" id="vntcli_serverw_0" class="input" value="0" <% nvram_match_x("", "vntcli_serverw", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr><td colspan="2"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">设备名称</th>
	<td style="border-top: 0 none;">
	<input name="vntcli_desname" type="text" class="input" id="vntcli_desname" placeholder="<% nvram_get_x("","computer_name"); %>" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vntcli_desname"); %>" size="32" maxlength="15" /></td>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">设备ID</th>
	<td style="border-top: 0 none;">
	<input type="text" maxlength="128" class="input" size="15" placeholder="建议与接口IP一致" id="vntcli_id" name="vntcli_id" value="<% nvram_get_x("","vntcli_id"); %>" onKeyPress="return is_string(this,event);" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">TUN网卡名</th>
	<td style="border-top: 0 none;">
	<input name="vntcli_tunname" type="text" class="input" id="vntcli_tunname" placeholder="vnt-tun" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vntcli_tunname"); %>" size="32" maxlength="15" /></td>
	</td>
	</tr><td colspan="3"></td>
	<tr>
          <th width="30%" style="border-top: 0 none;">MTU</th>
          <td style="border-top: 0 none;">
          <input type="text" name="vntcli_mtu" maxlength="4" class="input" placeholder="1450" size="5" value="<% nvram_get_x("","vntcli_mtu"); %>" onkeypress="return is_number(this,event);"/> 
          </td>
          </tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">自定义DNS</th>
	<td style="border-top: 0 none;">
	<textarea maxlength="128" class="input" name="vntcli_dns" id="vntcli_dns" placeholder="223.5.5.5" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vntcli_dns"); %></textarea>
	<br>&nbsp;<span style="color:#888;">多个DNS使用换行分隔</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">STUN服务地址</th>
	<td style="border-top: 0 none;">
	<textarea maxlength="128" class="input" name="vntcli_stun" id="vntcli_stun" placeholder="stun.qq.com:3478" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vntcli_stun"); %></textarea>
	<br>&nbsp;<span style="color:#888;">多个STUN地址使用换行分隔</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">监听端口</th>
	<td style="border-top: 0 none;">
	<input name="vntcli_port" type="text" class="input" id="vntcli_port" placeholder="0,0" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vntcli_port"); %>" size="32" maxlength="55" />
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">出口网卡名</th>
	<td style="border-top: 0 none;">
	<input name="vntcli_wan" type="text" class="input" id="vntcli_wan" placeholder="eth2.2" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","vntcli_wan"); %>" size="32" maxlength="12" />
	<br>⚠️&nbsp;<span style="color:#888;">错误网卡名将导致无法上网</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">打洞模式</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_punch" class="input" style="width: 185px;">
	<option value="0" <% nvram_match_x("","vntcli_punch", "0","selected"); %>>自动选择</option>
	<option value="ipv4" <% nvram_match_x("","vntcli_punch", "ipv4","selected"); %>>仅IPV4-TCP/UDP</option>
	<option value="ipv4-tcp" <% nvram_match_x("","vntcli_punch", "ipv4-tcp","selected"); %>>仅IPV4-TCP</option>
	<option value="ipv4-udp" <% nvram_match_x("","vntcli_punch", "ipv4-udp","selected"); %>>仅IPV4-UDP</option>
	<option value="ipv6" <% nvram_match_x("","vntcli_punch", "ipv6","selected"); %>>仅IPV6-TCP/UDP</option>
	<option value="ipv6-tcp" <% nvram_match_x("","vntcli_punch", "ipv6-tcp","selected"); %>>仅IPV6-TCP</option>
	<option value="ipv6-udp" <% nvram_match_x("","vntcli_punch", "ipv6-udp","selected"); %>>仅IPV6-UDP</option>
	</select>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">启用压缩</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_comp" class="input" style="width: 185px;">
	<option value="0" <% nvram_match_x("","vntcli_comp", "0","selected"); %>>不使用</option>
	<option value="lz4" <% nvram_match_x("","vntcli_comp", "lz4","selected"); %>>启用lz4压缩</option>
	<option value="zstd" <% nvram_match_x("","vntcli_comp", "zstd","selected"); %>>启用zstd压缩</option>
	</select><br>⚠️&nbsp;<span style="color:#888;">启用zstd压缩请自行编译程序</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">传输模式</th>
	<td style="border-top: 0 none;">
	<select name="vntcli_relay" class="input" style="width: 185px;">
	<option value="0" <% nvram_match_x("","vntcli_relay", "0","selected"); %>>自动选择</option>
	<option value="relay" <% nvram_match_x("","vntcli_relay", "relay","selected"); %>>仅中继转发</option>
	<option value="p2p" <% nvram_match_x("","vntcli_relay", "p2p","selected"); %>>仅P2P直连</option>
	</select><br>⚠️&nbsp;<span style="color:#888;">无法P2P的网络下选择仅P2P直连将会无法连接对端</span>
	</td>
	</tr><td colspan="3"></td>
	<tr>
	<th style="border: 0 none;">程序路径</th>
	<td style="border: 0 none;">
	<textarea maxlength="1024"class="input" name="vntcli_bin" id="vntcli_bin" placeholder="/etc/storage/bin/vnt-cli" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","vntcli_bin"); %></textarea>
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
	</tr>
	</table>
	<table  id="vntcli_mapping_table" width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr> <th colspan="5" style="background-color: #756c78;">端口映射 (将本地服务的端口映射到对端进行访问)</th></tr>
	<tr id="row_rules_caption">
	<th width="10%">服务协议 </th>
	<th width="20%">本地服务端口 </th>
	<th width="20%">对端接口IP地址 </th>
	<th width="25%">对端访问端口 </th>
          <th width="5%"><center><i class="icon-th-list"></i></center></th>
          </tr>
          <tr>
          <th>
          <select name="vntcli_mappnet_x_0" class="input" style="width: 60px"> 
	<option value="0" <% nvram_match_x("","vntcli_mappnet_x_0", "0","selected"); %>>TCP</option>
	<option value="1" <% nvram_match_x("","vntcli_mappnet_x_0", "0","selected"); %>>UDP</option>
	</select>
	</th>
	<th>
          <input maxlength="5" class="input" style="width: 80px" size="15" name="vntcli_mappport_x_0" id="vntcli_mappport_x_0" placeholder="80" value="<% nvram_get_x("","vntcli_mappport_x_0"); %>" onKeyPress="return is_number(this,event);"/>
	</th>
	<th><input type="text" maxlength="255" class="span12" style="width: 150px" size="200" name="vntcli_mappip_x_0" placeholder="10.26.0.22" value="<% nvram_get_x("", "vntcli_mappip_x_0"); %>"/>
	</th>
	<th>
	<input maxlength="5" class="input" style="width: 80px" size="15" name="vntcli_mapeerport_x_0" id="vntcli_mapeerport_x_0" placeholder="8080" value="<% nvram_get_x("","vntcli_mapeerport_x_0"); %>" onKeyPress="return is_number(this,event);"/>
	</th>
	<th>
	<button class="btn" style="max-width: 219px" type="submit" onclick="return markmappRULES(this, 64, ' Add ');" name="markmappRULES2" value="<#CTL_add#>" size="12"><i class="icon icon-plus"></i></button>
	</th>
	</td>
	</tr>
	<tr id="row_rules_body" >
	<td colspan="5" style="border-top: 0 none; padding: 0px;">
	<div id="MmappRULESList_Block"></div>
	</td>
	</tr>
	<tr>
	<td colspan="5" style="border-top: 0 none; padding-bottom: 20px;">
	<br />
	<center><input class="btn btn-primary" style="width: 219px" type="button" value="<#CTL_apply#>" onclick="applyRule()" /></center>
	</td></td>
	</tr>
	</table>
	</table>
	</div>
	<!-- 状态 -->
	<div id="wnd_vntcli_sta" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
		<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
			<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("vnt-cli_cmd.log",""); %></textarea>
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center;">
			<!-- 按钮并排显示 -->
			<input class="btn btn-success" style="width:100px; margin-right: 10px;" type="button" name="vntcli_info" value="本机设备信息" onclick="button_vntcli_info()" />
			<input class="btn btn-success" style="width:100px; margin-right: 10px;" type="button" name="vntcli_all" value="所有设备信息" onclick="button_vntcli_all()" />
			<input class="btn btn-success" style="width:100px; margin-right: 10px;" type="button" name="vntcli_list" value="所有设备列表" onclick="button_vntcli_list()" />
			<input class="btn btn-success" style="width:100px; margin-right: 10px;" type="button" name="vntcli_route" value="路由转发信息" onclick="button_vntcli_route()" />
			<input class="btn btn-success" style="width:100px; margin-right: 10px;" type="button" name="vntcli_status" value="运行状态信息" onclick="button_vntcli_status()" />
		</td>
	</tr>
	<tr>
		<td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 5px;">
			<span style="color:#888;">🔄 点击上方按钮刷新查看</span>
		</td>
	</tr>
	</table>
	</div>

	<!-- 日志 -->
	<div id="wnd_vntcli_log" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<tr>
	<td colspan="3" style="border-top: 0 none; padding-bottom: 0px;">
	<textarea rows="21" class="span12" style="height:377px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("vnt-cli.log",""); %></textarea>
	</td>
	</tr>
	<tr>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.reload()" value="刷新日志" class="btn btn-primary" style="width: 200px">
	</td>
	<td width="15%" style="text-align: left; padding-bottom: 0px;">
	<input type="button" onClick="location.href='vnt-cli.log'" value="<#CTL_onlysave#>" class="btn btn-success" style="width: 200px">
	</td>
	<td width="75%" style="text-align: right; padding-bottom: 0px;">
	<input type="button" onClick="clearLog();" value="清除日志" class="btn btn-info" style="width: 200px">
	</td>
	</tr>
	<br><td colspan="5" style="border-top: 0 none; text-align: center; padding-top: 4px;">
	<span style="color:#888;">🚫注意：日志包含 token 和 密码 等隐私信息，切勿随意分享！</span>
	</td>
	</table>
	</div>
	<!-- 帮助说明 -->
	<div id="wnd_vntcli_help" style="display:none">
	<table width="100%" cellpadding="4" cellspacing="0" class="table">
	<table width="100%" align="center" cellpadding="4" cellspacing="0" style="background-color: transparent;">
	<tr>
	<th colspan="2" style="background-color: rgba ( 171 , 168 , 167 , 0.2 ); color: white;">对应参数功能介绍</th>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78; text-align: left;">基础设置</th>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	Token
        </td>
        <td style="color: white; width: 85%; text-align: left;">
	【-k】连接相同的服务器时，相同token的设备才会组建一个虚拟局域网。这是必须填写的，否则无法启动
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	接口IP
        </td>
        <td style="color: white; width: 85%; text-align: left;">
	【--ip】指定本机的虚拟IP地址，每个客户端的IP不能相同，为空不指定则由服务器自动分配IP（不指定IP每次重启后IP地址将随机变化）
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	本地网段
	</td>
	<td style="color: white; width: 85%; text-align: left;">
	【-o】使本机局域网内的其他设备也能被对端访问，例如本机局域网IP为192.168.1.1则填 192.168.1.0/24 多个网段使用换行分隔（使本机作为出口节点还需添加 0.0.0.0/0）
	</td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	服务器地址
	</td>
	<td style="color: white; width: 85%; text-align: left;">
	【-s】填写域名或IP地址，相同的服务器，相同token的设备才会组成一个局域网，协议支持使用tcp://和ws://和wss://和txt://,不填协议默认为udp://<br>如果使用txt记录，需要选择协议的话 需要提前将协议前缀连同IP和端口一并记录到txt记录值里
	</td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	加密方式
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--model】通常情况aes_gcm安全性高、aes_ecb性能更好，在低性能设备上aes_ecb和xor速度最快，xor对速度基本没有影响。
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	密码
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-w】如果加密那么每个客户端都必须使用相同的 加密方式 和 密码 ，要么都不使用加密。客户端和客户端之间的加密
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用日志
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	生成程序运行的日志，用来查找bug错误，正常使用无需开启，开启影响些许性能
        </td>
	</tr>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	子网配置
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-i】相当于路由表，设置对端的lan网段和对端的接口IP地址，方便直接使用对端的内网IP地址即可访问对方内网其他设备
        </td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78; text-align: left;">进阶设置</th>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用IP转发
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--no-proxy】内置的IP代理较为简单，而且一般来说直接使用网卡NAT转发性能会更高,所以默认开启IP转发关闭内置的ip代理 
        </td>
	</tr>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用优化传输
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--first_latency】优先使用低延迟通道，默认情况下优先使用p2p通道，某些情况下可能p2p比客户端中继延迟更高，可启用此参数进行优化传输 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	允许WireGuard访问
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--allow-wg】在VNTS服务端的管理界面添加了WireGuard客户端时，本机需要被WG客户端访问才开启，默认不允许WG访问 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用数据指纹校验
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--finger】开启数据指纹校验，可增加安全性，如果服务端开启指纹校验，则客户端也必须开启，开启会损耗一部分性能。<br>注意：默认情况下服务端不会对中转的数据做校验，如果要对中转的数据做校验，则需要客户端、服务端都开启此参数 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用服务端客户端加密
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-W】这是客户端和服务端之间的加密，开启后和服务端通信的数据就会加密，采用rsa+aes256gcm加密客户端和服务端之间通信的数据，可以避免token泄漏、中间人攻击 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	设备名称
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-n】本机设备名称，方便区分不同设备 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	设备ID
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-d】设备唯一标识符,不填写接口IP时,服务端凭此参数分配虚拟ip,注意不能和其他客户端重复，建议和接口IP保持一致<br>如果填写了接口IP 请务必填写此参数，为了防止重启后IP变化，脚本也会自动将接口IP作为设备ID 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	TUN网卡名
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--nic】指定虚拟网卡名称，默认tun模式使用vnt-tun 在多开进程的时候需要指定不同网卡名 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	MTU
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-u】设置虚拟网卡的mtu值，大多数情况下使用默认值效率会更高，也可根据实际情况微调这个值，不加密默认为1450，加密默认为1410 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	自定义DNS
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--dns】用来解析域名服务器地址，可以设置多个（换行分隔）。如果使用TXT记录的域名，则dns默认使用223.5.5.5和114.114.114.114，端口省略值为53<br>
当域名解析失败时，会依次尝试后面的dns，直到有A记录、AAAA记录(或TXT记录)的解析结果 
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	STUN服务地址
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【-e】使用stun服务探测客户端NAT类型，不同类型有不同的打洞策略，程序已内置多个STUN地址 ，填写最多三个！
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	监听端口
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--ports】指定本地监听的端口组，多个端口使用英文逗号分隔，多个端口可以分摊流量，增加并发、减缓流量限制，tcp会监听端口组的第一个端口，用于tcp直连，端口越多越占用性能<br>例1：‘12345,12346,12347’ 表示udp监听12345、12346、12347这三个端口，tcp监听12345端口<br>例2：‘0,0’ 表示udp监听两个未使用的端口，tcp监听一个未使用的端口
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	出口网卡名
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--local-dev】指定出口网卡，当指定对端某个节点作为流量出口时，则必须指定当前的出口网卡（控制台输入 ifconfig 查看哪个网卡是走向外网的，则填哪个网卡名）<br>填写错误的网卡名将会导致无法上网，去掉选项即可恢复<br>指定流量出口：请使用子网配置里，对端lan网段填写 0.0.0.0/0 接口IP就填写对端的接口IP即可，对端还须启用作为流量出口节点，这时本机流量将从指定的对端节点出口
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	打洞模式
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--punch】选择对应的方式进行打洞，都使用自动选择合适的方式进行打洞
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	启用压缩
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--compressor】选择一种压缩方式进行压缩数据以提高带宽速度（低性能设备不建议开启，反而降低速度，若某个客户端开启了，则所有客户端都需要开启）<br>官方已发布的程序默认只带lz4 如需zstd请自行编译程序
        </td>
	</tr>
	<tr style="border-bottom: 1px solid #ccc;">
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	传输模式
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--use-channel】自动选择：自动判断合适的传输方式，优先P2P直连，无法直连的网络环境会采用服务器中继转发或其他客户端中继转发<br>仅中继转发：将不使用P2P直连，只使用服务器或客户端进行转发数据<br>仅P2P直连：只使用P2P直连进行传输，不使用服务器或其他客户端进行中继转发，如果网络环境无法P2P直连，将断开连接无法通讯。
        </td>
	</tr>
	<tr>
	<td style="color: yellow; width: 15%; padding-right: 10px; text-align: left;">
	端口映射
        </td>
        <td style="color: white; width: 85%; text-align: left;">
 	【--mapping】表示将本地服务端口的数据转发到对端地址的端口进行访问，转发的对端地址可以使用域名+端口，详情请参阅官方文档。
        </td>
	</tr>
	</table>

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
