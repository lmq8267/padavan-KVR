<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - 文件管理</title>
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
<% caddy_status(); %>
<% disk_pool_mapping_info(); %>


$j(document).ready(function() {
    init_itoggle('caddy_enable');
	init_itoggle('caddy_wan');
	init_itoggle('caddy_wip6');
	init_itoggle('caddy_file');
	init_itoggle('caddy_dwan');
	init_itoggle('caddy_dwip6');

});

</script>
<script>

<% login_state_hook(); %>

function initial(){
	show_banner(2);
	show_menu(5,19);
	show_footer();
switch_caddy_type();
fill_status(caddy_status());
	if (!login_safe())
		textarea_scripts_enabled(0);
}

function textarea_scripts_enabled(v){
	inputCtrl(document.form['scripts.caddy_script.sh'], v);
}

function fill_status(status_code){
	var stext = "Unknown";
	if (status_code == 0)
		stext = "<#Stopped#>";
	else if (status_code == 1)
		stext = "<#Running#>";
	$("caddy_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function applyRule(){
//	if(validForm()){
		showLoading();
		
		document.form.action_mode.value = " Apply ";
		document.form.current_page.value = "/Advanced_caddy.asp";
		document.form.next_page.value = "";
		
		document.form.submit();
//	}
}


function done_validating(action){
	refreshpage();
}

function switch_caddy_type(){
var b = document.form.caddy_file.value;
if (b=="0"){
	var v=0;
	showhide_div('row_ftit', 1);
	showhide_div('row_wtit', 0);
	showhide_div('row_wname', 0);
	showhide_div('row_wpassword', 0);
	showhide_div('row_davpath', 0);
	showhide_div('row_davport', 0);
	showhide_div('row_wandav', 0);
	showhide_div('row_wan6dav', 0);
	showhide_div('row_fname', 0);
	showhide_div('row_fpassword', 0);
	showhide_div('row_fpath', 1);
	showhide_div('row_fport', 1);
	showhide_div('row_fwan', 1);
	showhide_div('row_fwan6', 1);
}
if (b=="1"){
	var v=1;
	showhide_div('row_ftit', 0);
	showhide_div('row_wtit', 1);
	showhide_div('row_wname', 1);
	showhide_div('row_wpassword', 1);
	showhide_div('row_davpath', 1);
	showhide_div('row_davport', 1);
	showhide_div('row_wandav', 1);
	showhide_div('row_wan6dav', 1);
	showhide_div('row_fname', 0);
	showhide_div('row_fpassword', 0);
	showhide_div('row_fpath', 0);
	showhide_div('row_fport', 0);
	showhide_div('row_fwan', 0);
	showhide_div('row_fwan6', 0);
}
if (b=="2"){
	var v=1;
	showhide_div('row_ftit', 1);
	showhide_div('row_wtit', 1);
	showhide_div('row_wname', 1);
	showhide_div('row_wpassword', 1);
	showhide_div('row_davpath', 1);
	showhide_div('row_davport', 1);
	showhide_div('row_wandav', 1);
	showhide_div('row_wan6dav', 1);
	showhide_div('row_fname', 0);
	showhide_div('row_fpassword', 0);
	showhide_div('row_fpath', 1);
	showhide_div('row_fport', 1);
	showhide_div('row_fwan', 1);
	showhide_div('row_fwan6', 1);
}
if (b=="3"){
	var v=1;
	showhide_div('row_ftit', 1);
	showhide_div('row_wtit', 0);
	showhide_div('row_wname', 0);
	showhide_div('row_wpassword', 0);
	showhide_div('row_davpath', 0);
	showhide_div('row_davport', 0);
	showhide_div('row_wandav', 0);
	showhide_div('row_wan6dav', 0);
	showhide_div('row_fname', 1);
	showhide_div('row_fpassword', 1);
	showhide_div('row_fpath', 1);
	showhide_div('row_fport', 1);
	showhide_div('row_fwan', 1);
	showhide_div('row_fwan6', 1);
	
}
if (b=="4"){
	var v=1;
	showhide_div('row_ftit', 0);
	showhide_div('row_wtit', 1);
	showhide_div('row_wname', 1);
	showhide_div('row_wpassword', 1);
	showhide_div('row_davpath', 1);
	showhide_div('row_davport', 1);
	showhide_div('row_wandav', 1);
	showhide_div('row_wan6dav', 1);
	showhide_div('row_fname', 0);
	showhide_div('row_fpassword', 0);
	showhide_div('row_fpath', 0);
	showhide_div('row_fport', 0);
	showhide_div('row_fwan', 0);
	showhide_div('row_fwan6', 0);

}
if (b=="5"){
	var v=1;
	showhide_div('row_ftit', 1);
	showhide_div('row_wtit', 1);
	showhide_div('row_wname', 1);
	showhide_div('row_wpassword', 1);
	showhide_div('row_davpath', 1);
	showhide_div('row_davport', 1);
	showhide_div('row_wandav', 1);
	showhide_div('row_wan6dav', 1);
	showhide_div('row_fname', 1);
	showhide_div('row_fpassword', 1);
	showhide_div('row_fpath', 1);
	showhide_div('row_fport', 1);
	showhide_div('row_fwan', 1);
	showhide_div('row_fwan6', 1);

}
}
function on_caddyf_wan_port(){
	var port = document.form.caddyf_wan_port.value;
	if (port == '')
	var port = '12101';
	var porturl =window.location.protocol + '//' + window.location.hostname + ":" + port;
	//alert(porturl);
	window.open(porturl,'alist');
}
function on_caddyw_wan_port(){
	var port = document.form.caddyw_wan_port.value;
	if (port == '')
	var port = '12102';
	var porturl =window.location.protocol + '//' + window.location.hostname + ":" + port;
	//alert(porturl);
	window.open(porturl,'alist');
}
function button_restartcaddy(){
    	var $j = jQuery.noConflict();
    	$j.post('/apply.cgi',
    	{
        		'action_mode': ' Restartcaddy ',
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

	<input type="hidden" name="current_page" value="Advanced_caddy.asp">
	<input type="hidden" name="next_page" value="">
	<input type="hidden" name="next_host" value="">
	<input type="hidden" name="sid_list" value="CaddyConf;">
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
	<h2 class="box_head round_top">在线文件管理</h2>
	<div class="round_bottom">
	<div class="row-fluid">
	<div id="tabMenu" class="submenuBlock"></div>
	<div class="alert alert-info" style="margin: 10px;">File Browser是一个基于GO的轻量级文件管理系统支持登录系统 角色系统、在线PDF、图片、视频浏览、上传下载、打包下载等功能。
	WEBDAV 是一种文件服务，类似的服务有 SMB、NFS、FTP 等，特点是基于 HTTP/HTTPS 协议。
									
	</div>

	<table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
	<tr> <th><#running_status#></th>
          <td id="caddy_status" colspan="4"></td>
          </tr><td colspan="4"></td>
	<tr>
	<th width="30%" style="border-top: 0 none;">总开关</th>
	<td style="border-top: 0 none;">
	<div class="main_itoggle">
	<div id="caddy_enable_on_of">
	<input type="checkbox" id="caddy_enable_fake" <% nvram_match_x("", "caddy_enable", "1", "value=1 checked"); %><% nvram_match_x("", "caddy_enable", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="caddy_enable" id="caddy_enable_1" class="input" value="1" <% nvram_match_x("", "caddy_enable", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="caddy_enable" id="caddy_enable_0" class="input" value="0" <% nvram_match_x("", "caddy_enable", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	<td colspan="4" style="border-top: 0 none;">
	<input class="btn btn-success" style="width:150px" type="button" name="restartcaddy" value="重启" onclick="button_restartcaddy()" />
	</td>
	</tr>
	</tr>
	<tr>
         <th width="30%">启动模式:</th>
         <td colspan="2">
         <select id="caddy_file" name="caddy_file" class="input" onchange="switch_caddy_type()">
         <option value="0" <% nvram_match_x("","caddy_file", "0","selected"); %>>File Browser</option>
         <option value="1" <% nvram_match_x("","caddy_file", "1","selected"); %>>WebDAV</option>
	<option value="2" <% nvram_match_x("","caddy_file", "2","selected"); %>>File Browser+WebDAV</option>
	<option value="3" <% nvram_match_x("","caddy_file", "3","selected"); %>>新版Caddy File Browser</option>
	<option value="4" <% nvram_match_x("","caddy_file", "4","selected"); %>>新版Caddy WebDAV</option>
	<option value="5" <% nvram_match_x("","caddy_file", "5","selected"); %>>新版Caddy File Browser+WebDAV</option>
         </select>
         </td>
         </tr>
	<tr>
          <th width="30%">程序路径</th>
          <td colspan="2">
          <div class="input-append">
	<input name="caddy_dir" type="text" class="input" id="caddy_dir" placeholder="/tmp/var/caddy_filebrowser" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","caddy_dir"); %>" size="32" maxlength="128" />
	</div><br><span style="color:#888;">自定义程序的存放路径，填写完整的路径和程序名称</span>
         </td>
         </tr>
	<tr id="row_ftit" style="display:none;">
	<th colspan="4" style="background-color: #756c78;" >File Browser配置</th>
	</tr>
	<tr id="row_fpath" style="display:none;">
         <th width="30%">File Browser共享目录</th>
         <td colspan="2">
	<div class="input-append">
	<input name="caddy_storage" type="text" class="input" id="caddy_storage" placeholder="/media/AiDisk_a1" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","caddy_storage"); %>" size="32" maxlength="128" />
	</div>
          </select>
         </td>
          </tr>
	<tr id="row_fport" style="display:none;">
          <th  width="30%">File Browser端口:</th>
          <td colspan="2">
          <input type="text" name="caddyf_wan_port" maxlength="5"  class="input" placeholder="12101" size="60" value="<% nvram_get_x("","caddyf_wan_port"); %>" />
	<input class="btn btn-success" style="" type="button" value="File Browser界面" onclick="on_caddyf_wan_port()" /></td>
          </td>
          </tr>
	<tr id="row_fwan" style="display:none;">
	<th width="30%">外网IPV4访问File Browser</th>
	<td colspan="2">
	<div class="main_itoggle">
	<div id="caddy_wan_on_of">
	<input type="checkbox" id="caddy_wan_fake" <% nvram_match_x("", "caddy_wan", "1", "value=1 checked"); %><% nvram_match_x("", "caddy_wan", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="caddy_wan" id="caddy_wan_1" class="input" value="1" <% nvram_match_x("", "caddy_wan", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="caddy_wan" id="caddy_wan_0" class="input" value="0" <% nvram_match_x("", "caddy_wan", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr id="row_fwan6" style="display:none;">
	<th width="30%">外网IPV6访问File Browser</th>
	<td colspan="2">
	<div class="main_itoggle">
	<div id="caddy_wip6_on_of">
	<input type="checkbox" id="caddy_wip6_fake" <% nvram_match_x("", "caddy_wip6", "1", "value=1 checked"); %><% nvram_match_x("", "caddy_wip6", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="caddy_wip6" id="caddy_wip6_1" class="input" value="1" <% nvram_match_x("", "caddy_wip6", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="caddy_wip6" id="caddy_wip6_0" class="input" value="0" <% nvram_match_x("", "caddy_wip6", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr id="row_fname" style="display:none;">
          <th width="30%">File Browser用户名:</th>
          <td colspan="2">
          <input type="text" name="caddy_Fname" maxlength="8"  class="input" size="60" value="<% nvram_get_x("","caddy_Fname"); %>" />
          </td>
          </tr>
	<tr id="row_fpassword" style="display:none;">  
	<th width="30%">File Browser密码</th>
	<td colspan="2">
	<input type="password" class="input" size="32" name="caddy_Fpassword" id="F_key" value="<% nvram_get_x("","caddy_Fpassword"); %>" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('F_key')"><i class="icon-eye-close"></i></button>
	</td>
	</tr>
	<tr id="row_wtit" style="display:none;">
	<th colspan="4" style="background-color: #756c78;" >Webdav配置</th>
	</tr>
	<tr id="row_davpath" style="display:none;">
         <th width="30%">Webdav共享目录</th>
         <td colspan="2">
	<div class="input-append">
	<input name="caddy_webdav" type="text" class="input" id="caddy_webdav" placeholder="/media/AiDisk_a1" onkeypress="return is_string(this,event);" value="<% nvram_get_x("","caddy_webdav"); %>" size="32" maxlength="128" />
	</div>
         </td>
          </tr>
	<tr id="row_davport" style="display:none;">
          <th  width="30%">Webdav端口</th>
          <td colspan="2">
          <input type="text" name="caddyw_wan_port" maxlength="5"  class="input" size="60" placeholder="12102" value="<% nvram_get_x("","caddyw_wan_port"); %>" />
          <input class="btn btn-success" style="" type="button" value="Webdav 界面" onclick="on_caddyw_wan_port()" /></td>
          </tr>
	<tr id="row_wandav" style="display:none;">
	<th width="30%">外网IPV4访问Webdav</th>
	<td colspan="2">
	<div class="main_itoggle">
	<div id="caddy_dwan_on_of">
	<input type="checkbox" id="caddy_dwan_fake" <% nvram_match_x("", "caddy_dwan", "1", "value=1 checked"); %><% nvram_match_x("", "caddy_dwan", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="caddy_dwan" id="caddy_dwan_1" class="input" value="1" <% nvram_match_x("", "caddy_dwan", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="caddy_dwan" id="caddy_dwan_0" class="input" value="0" <% nvram_match_x("", "caddy_dwan", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	<tr id="row_wan6dav" style="display:none;">
	<th width="30%">外网IPV6访问Webdav</th>
	<td colspan="2">
	<div class="main_itoggle">
	<div id="caddy_dwip6_on_of">
	<input type="checkbox" id="caddy_dwip6_fake" <% nvram_match_x("", "caddy_dwip6", "1", "value=1 checked"); %><% nvram_match_x("", "caddy_dwip6", "0", "value=0"); %>  />
	</div>
	</div>
	<div style="position: absolute; margin-left: -10000px;">
	<input type="radio" value="1" name="caddy_dwip6" id="caddy_dwip6_1" class="input" value="1" <% nvram_match_x("", "caddy_dwip6", "1", "checked"); %> /><#checkbox_Yes#>
	<input type="radio" value="0" name="caddy_dwip6" id="caddy_dwip6_0" class="input" value="0" <% nvram_match_x("", "caddy_dwip6", "0", "checked"); %> /><#checkbox_No#>
	</div>
	</td>
	</tr>
	
	<tr id="row_wname" style="display:none;">
          <th width="30%">webdav用户名</th>
          <td colspan="2">
          <input type="text" name="caddy_wname" maxlength="8"  class="input" size="60" value="<% nvram_get_x("","caddy_wname"); %>" />
          </td>
          </tr>
	<tr id="row_wpassword" style="display:none;">  
	<th width="30%">webdav密码</th>
	<td colspan="2">
	<input type="password" class="input" size="32" name="caddy_wpassword" id="w_key" value="<% nvram_get_x("","caddy_wpassword"); %>" />
	<button style="margin-left: -5px;" class="btn" type="button" onclick="passwordShowHide('w_key')"><i class="icon-eye-close"></i></button>
	</td>
	</tr>
	<tr>
	<th colspan="4" style="background-color: #756c78;" >配置文件脚本</th>
	</tr>
	<tr id="row_post_wan_script">
	<td colspan="4">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('script2')"><span>caddy脚本-不懂请不要乱改！！！</span></a>
	<div id="script2">
	<textarea rows="18" wrap="off" spellcheck="false" maxlength="314571" class="span12" name="scripts.caddy_script.sh" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.caddy_script.sh",""); %></textarea>
	</div>
	</td>
	</tr>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('caddylog')"><span>查看caddy日志 /tmp/caddy.log</span></a>
	<div id="caddylog" style="display: none;">
	<textarea rows="21" class="span12" style="height:219px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("caddy.log",""); %></textarea>
	</div>
	</td>
	</tr>
	<tr>
	<td colspan="4" style="border-top: 0 none;">
	<i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('caddyfile')"><span>查看caddy配置文件 /tmp/Caddyfile</span></a>
	<div id="caddyfile" style="display: none;">
	<textarea rows="21" class="span12" style="height:219px; font-family:'Courier New', Courier, mono; font-size:13px;" readonly="readonly" wrap="off" id="textarea"><% nvram_dump("Caddyfile",""); %></textarea>
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
