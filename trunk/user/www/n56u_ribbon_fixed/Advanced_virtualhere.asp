<!DOCTYPE html>
<html>
<head>
<title><#Web_Title#> - virtualhere</title>
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

    init_itoggle('virtualhere_enable');

});

</script>
<script>
<% virtualhere_status(); %>
<% login_state_hook(); %>

function initial(){
    show_banner(2);
    show_menu(5,34,0);
    fill_status(virtualhere_status());
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
	$("virtualhere_status").innerHTML = '<span class="label label-' + (status_code != 0 ? 'success' : 'warning') + '">' + stext + '</span>';
}

function textarea_scripts_enabled(v){
	inputCtrl(document.form['scripts.virtualhere.ini'], v);
}

function applyRule(){
//    if(validForm()){
        showLoading();
        
        document.form.action_mode.value = " Apply ";
        document.form.current_page.value = "/Advanced_virtualhere.asp";
        document.form.next_page.value = "";
        
        document.form.submit();
//    }
}

function done_validating(action){
    refreshpage();
}

function button_restartvirtualhere(){
	var $j = jQuery.noConflict();
	$j.post('/apply.cgi',
	{
		'action_mode': ' Restartvhusbd ',
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

    <input type="hidden" name="current_page" value="Advanced_virtualhere.asp">
    <input type="hidden" name="next_page" value="">
    <input type="hidden" name="next_host" value="">
    <input type="hidden" name="sid_list" value="VIRTUAHERE;LANHostConfig;General;">
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
                            <h2 class="box_head round_top">virtualhere</h2>
                            <div class="round_bottom">
                                <div class="row-fluid">
                                    <div id="tabMenu" class="submenuBlock"></div>
                                    <div class="alert alert-info" style="margin: 10px;">欢迎使用 virtualhere，让我们可以通过网络（局域网、互联网）远程使用USB设备，就像在本地连接一样。
                                    <div>项目地址：<a href="http://www.virtualhere.com" target="blank">http://www.virtualhere.com</a></div>
                                    <div>服务器配置FAQ：<a href="http://www.virtualhere.com/configuration_faq" target="blank">http://www.virtualhere.com/configuration_faq</a></div>
                                    <div>客户端使用教程：<a href="http://www.virtualhere.com/usb_client_software" target="blank">http://www.virtualhere.com/usb_client_software</a></div>
                                    <div>客户端下载地址：<a href="http://www.virtualhere.com/sites/default/files/usbclient/vhui32.exe" target="blank">【电脑客户端32位】 </a>
                                    <a href="http://www.virtualhere.com/sites/default/files/usbclient/vhui64.exe" target="blank"> 【电脑客户端64位】 </a>
                                    <a href="http://www.virtualhere.com/usb_client_software" target="blank"> 【其他客户端】</a></div>
                                    <div>当前版本:【<% nvram_get_x("", "vhusbd_ver"); %>】 </div>
                                    <span style="color:#FF0000;" class=""></span></div>

                                    <table width="100%" align="center" cellpadding="4" cellspacing="0" class="table">
                                        <tr>
					<th><#running_status#>
					</th>
					<td colspan="4" id="virtualhere_status"></td>
					</tr>
					<tr>
                                        <tr id="virtualhere_enable_tr" >
                                            <th width="30%">virtualhere 开关</th>
                                            <td>
                                                    <div class="main_itoggle">
                                                    <div id="virtualhere_enable_on_of">
                                                        <input type="checkbox" id="virtualhere_enable_fake" <% nvram_match_x("", "virtualhere_enable", "1", "value=1 checked"); %><% nvram_match_x("", "virtualhere_enable", "0", "value=0"); %>  />
                                                    </div>
                                                </div>
                                                <div style="position: absolute; margin-left: -10000px;">
                                                    <input type="radio" value="1" name="virtualhere_enable" id="virtualhere_enable_1" class="input" value="1" <% nvram_match_x("", "virtualhere_enable", "1", "checked"); %> /><#checkbox_Yes#>
                                                    <input type="radio" value="0" name="virtualhere_enable" id="virtualhere_enable_0" class="input" value="0" <% nvram_match_x("", "virtualhere_enable", "0", "checked"); %> /><#checkbox_No#>
                                                </div>
                                            </td>
                                            <td colspan="3">
                                                <input class="btn btn-success" style="width:150px" type="button" name="updatevirtualhere" value="重启" onclick="button_restartvirtualhere()" />
                                            </td>
                                        </tr>
                                        <tr>
                                            <th width="30%" style="border-top: 0 none;">WAN 接入</th>
                                            <td style="border-top: 0 none;" colspan="2">
                                                <select name="virtualhere_wan" class="input">
                                                    <option value="0" <% nvram_match_x("","virtualhere_wan", "0","selected"); %>>禁止</option>
                                                    <option value="1" <% nvram_match_x("","virtualhere_wan", "1","selected"); %>>允许</option>
                                                </select>
                                            </td>
                                        </tr>
					<tr>
                                            <th width="30%" style="border-top: 0 none;">启用IPV6</th>
                                            <td style="border-top: 0 none;" colspan="2">
                                                <select name="virtualhere_v6" class="input">
                                                    <option value="0" <% nvram_match_x("","virtualhere_v6", "0","selected"); %>>否</option>
                                                    <option value="1" <% nvram_match_x("","virtualhere_v6", "1","selected"); %>>是</option>
                                                </select>
                                            </td>
                                        </tr>
					<tr>
					<th width="30%" style="border-top: 0 none;">程序路径</th>
						<td style="border-top: 0 none;">
						<div class="input-append">
						<textarea maxlength="1024" class="input" name="virtualhere_bin" id="virtualhere_bin" placeholder="/etc/storage/bin/virtualhere" style="width: 210px; height: 20px; resize: both; overflow: auto;"><% nvram_get_x("","virtualhere_bin"); %></textarea>
						</div><span style="color:#888;">指定virtualhere程序路径和程序名，完整路径</span>
						</td>
					</tr>
                                        <tr id="vhusbd_script" colspan="4">
                                            <td colspan="4" style="border-top: 0 none;">
                                                <i class="icon-hand-right"></i> <a href="javascript:spoiler_toggle('vhusbd_s')"><span style="color:#888;">编辑 /etc/storage/virtualhere.ini 配置参数。</span></a>
						&nbsp;&nbsp;<a style="color:#888;" href="https://kanochan.net/archives/800.html" target="blank">配置文件说明</a>
                                                <div id="vhusbd_s" >
                                                    <textarea rows="13" wrap="off" spellcheck="false" maxlength="18192" class="span12" name="scripts.virtualhere.ini" style="font-family:'Courier New'; font-size:12px;"><% nvram_dump("scripts.virtualhere.ini",""); %></textarea>
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


