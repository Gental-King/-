;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;~ 作         者:  河许人
;~ 脚本说明： 影子输入法，承影（texter热字符串）_hello_srf柚子输入法，输入要做的就是
;~ 环境 版本:   Autohotkey v1.1.23.05
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



#NoEnv
#SingleInstance, Force
#Include lib\EasyIni.ahk
#Include lib\Gdip.ahk

#Include lib\Class_SQLiteDB.ahk
if(A_Is64bitOS==1)
{
	FileMove,sqlite364.dll,sqlite3.dll
}
else
{
	FileMove,sqlite386.dll,sqlite3.dll
}

SendMode Input
SetWorkingDir %A_ScriptDir%
CoordMode,Caret,Screen
CoordMode,ToolTip,Screen

;~ ;升权
iAhkPID := DllCall("GetCurrentProcessId")
Process, Priority, , High
SetBatchLines, -1

;~ 

; ======================================================================================================================
;初始化
; ======================================================================================================================
FileDelete,temp32.exe
FileDelete,temp64.exe
;读取配置
;~ IfExist,%A_AppData%\AutoAHK.ini
global yzini:= new EasyIni
IfExist,yz.ini
{
	Yzini:= class_EasyIni("yz.ini") ;配置
	Version:=yzIni.Version["Version"]
	lm_xl:=yzIni.settings["lm_xl"]
	zi_fu_ir:=yzIni.settings["zi_fu_ir"]
	yy_xk:=yzIni.settings["yy_xk"]
}
else
{
	Yzini:= class_EasyIni("yz.ini") ;配置
	Yzini.addSection("Version","Version","0.0.1") 
	Yzini.addSection("settings","lm_xl",1) 
	Yzini["settings","zi_fu_ir"]:=0
	Yzini["settings","yy_xk"]:=0
	Yzini["settings","ciku"]:="pinyin"
	Yzini.save()
}

DBFileName := A_ScriptDir . "\ciku.DB"
application_name:="影子输入法"
Yz_Abort:="影子输入法是由河许人和天黑请闭眼联合开发的简单、简洁、高度自定义输入法。影子输入法起源于AutoHotkey高手群Hello_srf开发的柚子输入法,融合了承影和jip输入法的理念。影子输入法为开源、绿色、安全的输入法。请放心使用!"
ArrayCount:=0
waitnum:=0

x:=A_ScreenWidth-400
y:=A_ScreenHeight-300
;~ fengefu:="†-------†-------†-------†----------★----------†--------†-------†-------†----------★----------†--------†-------†-------†----------★----------†--------†-------†-------†----------★----------†--------†-------†-------†----------★----------†--------†-------†-------†----------★----------†--------†-------†-------†----------★----------†--------†-------†-------†"
fengefu:="------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
;更新
;获取更新信息
URLDownloadToFile,https://autohotkey.oss-cn-qingdao.aliyuncs.com/AutoAHKScript/Scripts/yz/xnyj.ini,xnyj.ini
if (ErrorLevel==1)
{
	MsgBox,无法联网,将无法更新脚本!
}
else
{
	xnyjini:= class_EasyIni("xnyj.ini") ;配置
	if(Yzini.Version["Version"]<xnyjini.Version["Version"])
	{
		MsgBox,4,,影子输入法有新版本了!是否更新?
		IfMsgBox Yes
		{
			Gui,4:font, s12, Courier New
			Gui,4: +ToolWindow +AlwaysOnTop
			Gui,4:Add,Text,xm ym w500 h100 vLabel1, 正在更新文件。。。	请稍后。。。
			Gui,4:show,,更新
			IfExist,影子输入法32.exe
			{
				FileMove,影子输入法32.exe,temp32.exe
				FileMove,影子输入法64.exe,temp64.exe
			}
			URLDownloadToFile,https://autohotkey.oss-cn-qingdao.aliyuncs.com/AutoAHKScript/Scripts/yz/影子输入法32.exe,影子输入法32.exe
			URLDownloadToFile,https://autohotkey.oss-cn-qingdao.aliyuncs.com/AutoAHKScript/Scripts/yz/影子输入法64.exe,影子输入法64.exe
			loop,1200
			{
				IfExist,影子输入法32.exe
				{
					break
				}
				else
				{
					Sleep,100
				}
			}
			if (ErrorLevel=0)
			{
				IfExist,影子输入法32.exe
				{
					FileDelete,temp32.exe
					FileDelete,temp64.exe
				}
				Yzini.Version["Version"]:=xnyjini.Version["Version"]
				Yzini.save()
				GuiControl,4:Text,Label1,恭喜您，更新成功！即将重启!!重要提醒,本次更新后需要将您的hotstrings、fuctions库`n导出并重新导入!

				Sleep,1000
				Gui,4:Destroy
				Reload
			}
			else
			{
				GuiControl,4:Text,Label1,更新失败！
				FileMove,temp32.exe,影子输入法32.exe
				FileMove,temp64.exe,影子输入法64.exe
				Gui,4:Destroy
			}
		}
		else
		{
			ToolTip,您选择了暂不更新,祝您使用愉快!!
		}
	}
}


;画主窗口
if !pToken := Gdip_Startup()
{
	MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
	ExitApp
}
OnExit, Exit
Gui,2: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
Gui,2: Show,NA
hwnd1 := WinExist()
pBitmap1 := Gdip_CreateBitmapFromFile("yzt.png")
if !pBitmap1
{
	MsgBox, 48, File loading error!, Could not load 'yzt.png'
	ExitApp
}
Width := Gdip_GetImageWidth(pBitmap1), Height := Gdip_GetImageHeight(pBitmap1)
hbm := CreateDIBSection(Width//2, Height//2)
hdc := CreateCompatibleDC()
obm := SelectObject(hdc, hbm)
G := Gdip_GraphicsFromHDC(hdc)
Gdip_SetInterpolationMode(G, 7)
Gdip_DrawImage(G, pBitmap1, 0, 0, Width//2, Height//2, 0, 0, Width, Height)
OnMessage(0x201, "WM_LBUTTONDOWN")
UpdateLayeredWindow(hwnd1, hdc,x , y, Width//2, Height//2)
SelectObject(hdc, obm)
DeleteObject(hbm)
DeleteDC(hdc)
Gdip_DeleteGraphics(G)
Gdip_DisposeImage(pBitmap1)
Gui,2: Hide
gosub,LoadLogo
gosub,TRAYMENU
;参考kaiwen的智能输入法
HKL := IME_Return_0E1C()
lang := (HKL = 1) ? "cn" : "en"
if(lang=="cn")
{
	SwitchToEngIME()
}
;~
LShift & LButton::Send +{LButton}


; 界面
;------------------------------------------------------------------------------------------------------------------------
;托盘按钮
TRAYMENU:
	Menu,TRAY,NoStandard                                         ;去掉标准托盘按钮
	Menu,TRAY,DeleteAll                                              ;清空托盘按钮
	Menu,TRAY,Add,影子输入法（&Y）,LoadLogo
	Menu,TRAY, Icon,影子输入法（&Y）, resources\yz.ico
	Menu,TRAY,Add
	Menu,TRAY,Add,词库管理（&M）,ci_ku_Manager
	Menu,TRAY,Add
	Menu,TRAY,Add,参数选项（&P）,PREFERENCES

	Menu,TRAY,Add
	Menu,Tray,Add,帮助(&H),Help
	Menu,TRAY,Add,关于（&A）,ABOUT
	Menu,TRAY,Add,退出（&E）,EXIT
	Menu,TRAY,Default,影子输入法（&Y）
	Menu,Tray,Tip,影子
	Menu,TRAY,Icon,resources\yz.ico
	Menu,Tray,Click,1
return

;加载logo
LoadLogo:
	if !pToken := Gdip_Startup()
	{
		MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
		ExitApp
	}
	OnExit, Exit
	Gui, 1: -Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs
	Gui, 1: Show, CEnter NA, 影子
	hwnd1 := WinExist()
	pBitmap := Gdip_CreateBitmapFromFile("yz.png")
	if !pBitmap
	{
		MsgBox, 48, File loading error!, Could not load 'yz.png'
		ExitApp
	}
	Width := Gdip_GetImageWidth(pBitmap), Height := Gdip_GetImageHeight(pBitmap)
	hbm := CreateDIBSection(Width//2, Height//2)
	hdc := CreateCompatibleDC()
	obm := SelectObject(hdc, hbm)
	G := Gdip_GraphicsFromHDC(hdc)
	Gdip_SetInterpolationMode(G, 7)
	Gdip_DrawImage(G, pBitmap, 0, 0, Width//2, Height//2, 0, 0, Width, Height)
	logo_x:=A_ScreenWidth//2-Width//4
	logo_y:=A_ScreenHeight//2- Height//4
	UpdateLayeredWindow(hwnd1, hdc,logo_x , logo_y, Width//2, Height//2)
	SelectObject(hdc, obm)
	DeleteObject(hbm)
	DeleteDC(hdc)
	Gdip_DeleteGraphics(G)
	Gdip_DisposeImage(pBitmap)

	;检验加载
	DB := new SQLiteDB
	Sleep, 1000
	if !DB.OpenDB(DBFileName)
	{
		MsgBox, 16, 数据库错误, % "消息:`t" . DB.ErrorMsg . "`n代码:`t" . DB.ErrorCode
		ExitApp
	}
	Gdip_Shutdown(pToken)
	Gui,Destroy
return

#Include lib\Ciku_Manager.ahk   ;词库管理

Help:
	Gui,96:Destroy
	Gui,96:Margin,20,20
	Gui,99:Add,Picture,xm w13 h-1 ,%A_ScriptDir%\resources\yz.ico
	Gui,96:Font,Bold,kaiti
	Gui,96:Add,Text,x+10 yp+10,%application_name% v %Version%
	Gui,96:Font
	Gui,96:Font,,kaiti
	Gui,96:Add,Text,y+10,简易帮助
	Gui,96:Add,Text,y+5,- Shift打开输入法
	Gui,96:Add,Text,y+5,- Space首行上屏,Enter英文字符上屏
	Gui,96:Add,Text,y+5,- 逗号热字符串上屏
	Gui,96:Add,Text,y+5,- 句号运行命令
	Gui,96:Add,Text,y+5,- 1、2、3、……候选上屏
	Gui,96:Font
	Gui,96:Add,Picture,xm y+20 w13 h-1 ,%A_ScriptDir%\resources\House.ico
	Gui,96:Font,Bold,kaiti
	Gui,96:Add,Text,x+10 yp+10,详细帮助
	Gui,96:Font
	Gui,96:Font,,kaiti
	Gui,96:Add,Text,y+10,这里有更多信息
	Gui,96:Font
	Gui,96:Font,CBlue Underline
	Gui,96:Add,Text,y+5 gAutoAHK_yz,https://www.autoahk.com/archives/15117
	Gui,96:Font
 
	Gui,96:Show,,%application_name% v %Version% 帮助
	hCurs:=DllCall("LoadCursor","UInt",NULL,"Int",32649,"UInt") ;IDC_HAND
	OnMessage(0x200,"WM_MouseMove")
return

AutoAHK_yz:
	Run,https://www.autoahk.com/archives/15117
return

ABOUT:
	Gui,99:Destroy
	Gui,99:Margin,20,20
	Gui,99:Add,Picture,xm w13 h-1 ,%A_ScriptDir%\resources\yz.ico
	Gui,99:Font,Bold,KaiTi
	Gui,99:Add,Text,x+10 yp+10,%application_name% v %Version%
	Gui,99:Font
	Gui,99:Font,,KaiTi
	Gui,99:Add,Text,y+10 w300, %A_Space%%A_Space%%A_Space%%A_Space%%Yz_Abort%
	Gui,99:Font
	Gui,99:Add,Picture,xm y+20 w13 h-1 ,%A_ScriptDir%\resources\House.ico
	Gui,99:Font,Bold,KaiTi

	Gui,99:Add,Text,x+10 yp+10,大本营
	Gui,99:Font
	Gui,99:Font,,KaiTi
	Gui,99:Add,Text,y+10,这里有更多精美的工具和脚本.
	Gui,99:Font,,KaiTi
	Gui,99:Font,CBlue Underline
	Gui,99:Add,Text,y+5 gAutoAHK,www.autoahk.com
	Gui,99:Font

	Gui,99:Add,Picture,xm y+20  w13 h-1,%A_ScriptDir%\resources\Love.ico
	Gui,99:Font,Bold,KaiTi
	Gui,99:Add,Text,x+10 yp+10,赠人玫瑰,手留余香!
	Gui,99:Font
	Gui,99:Font,,KaiTi
	Gui,99:Add,Text,y+10,感谢您的支持!
	Gui,99:Font
	Gui,99:Font,CBlue Underline
	Gui,99:Add,Text,y+5 gBuyAutoAHK ,http://buy.autoahk.com
	Gui,99:Font

	Gui,99:Add,Picture,xm y+20 w13 h-1,%A_ScriptDir%\resources\Internet.ico
	Gui,99:Font,Bold,KaiTi
	Gui,99:Add,Text,x+10 yp+10,感谢
	Gui,99:Font
	Gui,99:Font,,KaiTi
	Gui,99:Add,Text,y+10 w300,非常感谢大家的支持,感谢Hello_srf、胡杨、jeff、is1or0、心如止水
	Gui,99:Font

	Gui,99:Show,,%application_name% v %Version% 关于
	hCurs:=DllCall("LoadCursor","UInt",NULL,"Int",32649,"UInt") ;IDC_HAND
	OnMessage(0x200,"WM_MouseMove")
return

AutoAHK:
	Run,www.autoahk.com
return
BuyAutoAHK:
	Run,http://buy.autoahk.com
return
AutoHotKey:
	Run,www.autoHotkey.com
return
;词库管理
FunctionsManager:
	Run,functions.ini
return
HotStringsManager:
	Run,hotstrings.ini
return
XiaoHeManager:
	Run,xiaohe.ini
return
WubiManager:
	Run,wubi86.ini
return

;------------------------------------------------------------------------------------------------------------------------
; 选项
;------------------------------------------------------------------------------------------------------------------------
PREFERENCES:
	Gui,3: Destroy
	Gui,3: +owner
	Gui,3:Font, s10, Arial
	XiaoHeMode:=0
	WuBiMode:=0
	PinyinMode:=0
	XiaoHeShuangpinMode:=0
	ziranmashuangpinMode:=0
	weiruanshuangpinMode:=0
	abcshuangpinMode:=0
	if(yzIni.settings["ciku"]=="xiaohe")
	{
		XiaoHeMode:=1
	}
	else if(yzIni.settings["ciku"]=="wubi86")
	{
		WuBiMode:=1
	}
	else if(yzIni.settings["ciku"]=="pinyin")
	{
		PinyinMode:=1
	}
	else if(yzIni.settings["ciku"]=="xiaoheshuangpin")
	{
		XiaoHeShuangpinMode:=1
	}
	else if(yzIni.settings["ciku"]=="ziranmashuangpin")
	{
		ziranmashuangpinMode:=1
	}
	else if(yzIni.settings["ciku"]=="weiruanshuangpin")
	{
		weiruanshuangpinMode:=1
	}
	else if(yzIni.settings["ciku"]=="abcshuangpin")
	{
		abcshuangpinMode:=1
	}
	
Gui,3:Add,GroupBox,xm+10 ym+10 w300 h240,输入方案选择
Gui,3: Add,Radio, xp+10 yp+25 vWuBiRadio gWuBiRadio Checked%WuBiMode%,五笔86方案 --------对应wubi86词库
Gui,3: Add,Radio,xp yp+30 vXiaoHeRadio gXiaoHeRadio Checked%XiaoHeMode%,小鹤音形方案 ---- 对应xiaohe词库
Gui,3:add,Radio,xp yp+30 vXiaoHeShuangpinRadio gXiaoHeShuangpinRadio Checked%XiaoHeShuangpinMode%,小鹤双拼方案 ---- 对应pinyin词库
Gui,3:add,Radio,xp yp+30 vziranmashuangpinRadio gziranmashuangpinRadio Checked%ziranmashuangpinMode%,自然码双拼方案 - 对应pinyin词库
Gui,3:add,Radio,xp yp+30 vweiruanshuangpinRadio gweiruanshuangpinRadio Checked%weiruanshuangpinMode%,微软双拼方案 ---- 对应pinyin词库
Gui,3:add,Radio,xp yp+30 vabcshuangpinRadio gabcshuangpinRadio Checked%abcshuangpinMode%,abc双拼方案 ----- 对应pinyin词库
Gui,3:add,Radio,xp yp+30 vPinYinRadio gPinYinRadio Checked%PinyinMode%,拼音方案 ---------- 对应pinyin词库
Gui,3:Add,GroupBox,xm+10 yp+50 w300 h100,辅助功能选项
Gui,3:add,Checkbox,xp+10 yp+25 vlm_xl glm_xl_jmia Checked%lm_xl%,是否联想?
Gui,3:add,Checkbox,xp yp+25 vzi_fu_ir gzi_fu_ir_jmia Checked%zi_fu_ir%,是否开启魔法字符串功能?
Gui,3:add,Checkbox,xp yp+25 vyy_xk gyy_xk_jmia Checked%yy_xk%,是否开启超级运行功能?
Gui,3:show,,%application_name% v %Version% 选项
return

XiaoHeRadio:
	YzIni.settings["ciku"] :="xiaohe"
	YzIni.save()
return

WuBiRadio:
	YzIni.settings["ciku"] :="wubi86"
	YzIni.save()
return
PinYinRadio:
	YzIni.settings["ciku"] :="pinyin"
	YzIni.save()
return
XiaoHeShuangpinRadio:
	YzIni.settings["ciku"] :="xiaoheshuangpin"
	YzIni.save()
return
ziranmashuangpinRadio:
	YzIni.settings["ciku"] :="ziranmashuangpin"
	YzIni.save()
return
weiruanshuangpinRadio:
	YzIni.settings["ciku"] :="weiruanshuangpin"
	YzIni.save()
return
abcshuangpinRadio:
	YzIni.settings["ciku"] :="abcshuangpin"
	YzIni.save()
return


lm_xl_jmia:
	Gui,3:Submit,NoHide
	YzIni.settings["lm_xl"] :=lm_xl
	YzIni.save()
return
zi_fu_ir_jmia:
	Gui,3:Submit,NoHide
	YzIni.settings["zi_fu_ir"] :=zi_fu_ir
	YzIni.save()
return
yy_xk_jmia:
	Gui,3:Submit,NoHide
	YzIni.settings["yy_xk"] :=yy_xk
	YzIni.save()
return

Lshift::
	srf_mode := !srf_mode
	HKL := IME_Return_0E1C()
	lang := (HKL = 1) ? "cn" : "en"

	if  srf_mode
	{
		if(lang=="cn")
		{
			SwitchToEngIME()
		}
		Gui, 2: Show, NA
	}
	else
	{
		Gui, 2: Hide
		;~ if(lang=="en")
		;~ {
			;~ SwitchToChsIME()
		;~ }
	}
return
; srf_for_select_array0模式 空格、逗号、句号 定义
#If srf_for_select_array0
Space::srf_select(1)
	,::srf_HotStringSelect(hotstring_for_select)
.::srf_RunSelect(Function_for_select)
1::srf_select(1)
2::srf_select(2)
3::srf_select(3)
4::srf_select(4)
5::srf_select(5)
6::srf_select(6)
7::srf_select(7)
8::srf_select(8)
9::srf_select(9)
0::srf_select(10)
]::gosub MoreWait
[::gosub lessWait
#If
;srf_all_input模式 backspace键、esc键、enter键、Lshift键 定义
#If srf_all_Input
; backspace
backspace::
	srf_all_Input := SubStr(srf_all_Input, 1, -1)
	jichu_for_show=
	if srf_all_Input =
	{
		gosub srf_value_off
	}
	else
	{
		jichu_for_select=
		gosub srf_tooltip
	}
return
;

esc::gosub srf_value_off

enter::
	Send %srf_all_Input%
	gosub srf_value_off
return

Lshift::
	Send %srf_all_Input%
	Gui,2:Hide
	gosub srf_value_off
	srf_mode =
return

#If
; srf_mode模式 a-z键、esc键、中文符号 定义
#If srf_mode
; 设置热键
; a-z定义
; 设置热键
a::
b::
c::
d::
e::
f::
g::
h::
i::
j::
k::
l::
m::
n::
o::
p::
q::
r::
s::
t::
u::
v::
w::
x::
y::
z::
	srf_all_Input := srf_all_Input . A_ThisHotkey
	gosub srf_tooltip
return
;
esc::
	WinSet, TransColor, FF0000  0 , srf_icon,
	srf_mode =
return

,::send {，}
.::Send {。}
\::send {、}
/::Send {/}
?::send {？}
!::Send {！}
^::send,……
`::Send {·}
|::send {|}
`;::Send {；}
:::Send {：}

+'::send {“}{”}{left}
#If
	;输入法上屏函数
	srf_select(list_num)
	{
		global
		SendInput % Trim(jichu_for_select_Array[list_num+10*waitnum] ,A_Space)
		if(list_num==1)and(waitnum==0)
		{
		}
		else
		{
			Table:=yzIni.settings["ciku"]
			if(Table=="xiaoheshuangpin")
			{
				Table:="pinyin"
			}
			valuename:=jichu_for_select_Array[list_num+10*waitnum]
			if(Table=="pinyin")
			{
				if (!DB.Exec(SQL:="UPDATE " . Table . " SET weight = weight*1.3 WHERE value = '" . valuename . "';"))
				{
					MsgBox, 16, 数据库写入错误, % "消息:`t" . DB.ErrorMsg . "`n代码:`t" . DB.ErrorCode
				}
			}
		}
		gosub srf_value_off
	}
;热字
srf_HotStringSelect(hotstrings)
{
	global
	hotstring:=strReplace(hotstrings[1],"``n","`n")
	temp:=Clipboard
	Clipboard:=strReplace(hotstring,"``t","`t")
	SendInput,^v
	Clipboard:=temp
	gosub srf_value_off
}
srf_RunSelect(function)
{
	global
	Run,% function[1,1]
	gosub srf_value_off
}
MoreWait:
	waitnum+=1
	gosub,srf_tooltip
return
lessWait:
	waitnum-=1
	gosub,srf_tooltip
return
;标签srf_tooltip
srf_tooltip:
	;新算法：loop匹配，每次去除一个字符，匹配到保存一个字段（保存字段对应的候选输出），剩余的重复之前操作，直到结束；
	;匹配结束后，字段对应候选数组排列组合输出；
	;最新算法：每种方案单独设计
	save_field:=[]
	field_Num:=0
	save_field_array:=[]
	srf_all_Input_for_trim:=srf_all_Input
	srf_all_Input_trim_off:=""
	jichu_Check:=""
	;循环
	loop_num:=0
	lianxiangarray:=[]
	;xiaohe yin xing循环
	if(yzIni.settings["ciku"]=="xiaohe")
	{
		#Include lib\suanfa_xiaohe.ahk
	}
	else if(yzIni.settings["ciku"]=="wubi86")
	{
		#Include lib\suanfa_wubi.ahk
	}
	else if(yzIni.settings["ciku"]=="xiaoheshuangpin")
	{
		#Include lib\suanfa_xiaoheshuangpin.ahk
	}
	else if(yzIni.settings["ciku"]=="ziranmashuangpin")
	{
		#Include lib\suanfa_ziranmashuangpin.ahk
	}
	else if(yzIni.settings["ciku"]=="pinyin")
	{
		#Include lib\suanfa_pinyin.ahk
	}
	else if(yzIni.settings["ciku"]=="weiruanshuangpin")
	{
		#Include lib\suanfa_weiruanshuangpin.ahk
	}
	else if(yzIni.settings["ciku"]=="abcshuangpin")
	{
		#Include lib\suanfa_abcshuangpin.ahk
	}
return

WM_LBUTTONDOWN()
{
	PostMessage, 0xA1, 2
}

; 标签 srf_value_off
srf_value_off:
	jichu_for_select=
	srf_for_select_array0=
	srf_for_select_array=
	jichu_for_select_Array=
	jichu_for_array=
	jichu_for_show=
	ToolTip, , , ,16
	srf_all_Input=
	ArrayCount:=0
	waitnum:=0
	Function_for_select:=[]
	hotstring_for_select:=[]
return

EXIT:
	EmptyMem()
	ExitApp


	; 来源: http://www.autohotkey.com/forum/topic32876.html
	EmptyMem(PID="AHK Rocks")
	{
		pid:=(pid="AHK Rocks") ? DllCall("GetCurrentProcessId") : pid
		h:=DllCall("OpenProcess", "UInt", 0x001F0FFF, "Int", 0, "Int", pid)
		DllCall("SetProcessWorkingSetSize", "UInt", h, "Int", -1, "Int", -1)
		DllCall("CloseHandle", "Int", h)
	}
; Lshift键切换模式

SwitchToEngIME()
{
	; 下方代码可只保留一个
	SwitchIME(0x04090409) ; 英语(美国) 美式键盘
}
SwitchToChsIME()
{
	; 下方代码可只保留一个
	;~ SwitchIME(0x04090409) ; 英语(美国) 美式键盘
	;~ SwitchIME(0x08040804) ; 中文(中国) 简体中文-美式键盘
	PostMessage, 0x50, 0, 0x8040804, , A
	if !IME_Return_0E1C()
		SendInput, #{Space}
}
SwitchIME(dwLayout)
{
	HKL := DllCall("LoadKeyboardLayout", Str, dwLayout, UInt, 1)
	ControlGetFocus, ctl, A
	SendMessage, 0x50, 0, HKL, %ctl%, A
}

IME_Return_0E1C(WinTitle="A"){			;借鉴了某日本人脚本中的获取输入法状态的内容,减少了不必要的切换,切换更流畅了
	;~ ifEqual WinTitle,,  SetEnv,WinTitle,A
	WinGet,hWnd,ID,%WinTitle%
	DefaultIMEWnd := DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hWnd, Uint)

	;Message : WM_IME_CONTROL  wParam:IMC_GETOPENSTATUS
	DetectSave := A_DetectHiddenWindows
	DetectHiddenWindows,ON
	SendMessage 0x283, 0x005,0,,ahk_id %DefaultIMEWnd%
	DetectHiddenWindows,%DetectSave%
	return ErrorLevel
}

get_word_lianxiang(DB,input,cikuname,num:=5)
{
	Input:=StrReplace(Input,"'","''")
	;~ Input:=Trim(RegExReplace(StrReplace(Input, "'", "''"), "'([a-z]h?)'", "'$1%'"), "'") ;单声母匹配
	;~ Trim(RegExReplace(StrReplace(str, "'", "''"), "'([csz])h?", "'$1%"), "'") ;sh,ch,zh模糊音
	;~ Trim(RegExReplace(StrReplace(str, "'", "''"), "([ae])ng?'", "$1n%'"), "'") ;ang,eng模糊音
	;~ SQL :=jianpinsql(Input)
	if(cikuname=="hotstrings")
	{
		SQL := "SELECT value FROM " . cikuname . " where key >= '" . Input . "' ORDER by key ASC limit " . num . ";"
	}
	else if(cikuname=="functions")
	{
		SQL := "SELECT value,comment FROM " . cikuname . " where key >= '" . Input . "' ORDER by key ASC limit " . num . ";"
	}
	else
	{
		SQL := "SELECT value FROM " . cikuname . " where key >= '" . Input . "' ORDER by key ASC,weight DESC  limit " . num . ";"
	}
	Result :=[]
	Final_array:=[]
	if !DB.GetTable(SQL, Result)
		MsgBox, 16, 获取数据表错误, % "消息:`t" . DB.ErrorMsg . "`n代码:`t" . DB.ErrorCode
	loop,% Result.Rows.MaxIndex()
	{
		if(cikuname=="functions")
		{
			Final_array[A_Index]:=Result.Rows[A_Index]
		}
		else
		{
			Final_array[A_Index]:=Result.Rows[A_Index,1]
		}
	}
	return,Final_array
}

get_word(DB,input,cikuname)
{
	Input:=StrReplace(Input,"'","''")
	if(cikuname=="hotstrings")
	{
		SQL := "SELECT value FROM " . cikuname . " where key = '" . Input . "';"
	}
	else if(cikuname=="functions")
	{
		SQL := "SELECT value FROM " . cikuname . " where key = '" . Input . "';"
	}
	else
	{
		SQL := "SELECT value FROM " . cikuname . " where key = '" . Input . "' ORDER BY weight DESC;"
	}
	Result :=[]
	Final_array:=[]
	if !DB.GetTable(SQL, Result)
		MsgBox, 16, 获取数据表错误, % "消息:`t" . DB.ErrorMsg . "`n代码:`t" . DB.ErrorCode
	loop,% Result.Rows.MaxIndex()
	{
		Final_array[A_Index]:=Result.Rows[A_Index,1]
	}
	return,Final_array
}
