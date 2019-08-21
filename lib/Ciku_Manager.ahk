; Tested with:    	AHK 1.1.30
; Tested on:      	Win 10 Pro (x64)
; Change History:	2019-08-06	支持格式：xnhe=小鹤=16`nulpk=双拼=49 或 aa=啊=阿=吖=嗄  （同一文件格式统一）
;					2019-08-12  加入词组导入自动生成小鹤双拼 支持格式：字符串=395499`n初始化=372767 或 字符串`n初始化
;					2019-08-15  新增小鹤双拼、全拼词条生成，能自动生成小鹤双拼、全拼词条，智能识别格式
;								一行最多包含一个key、weight值,分隔符为单字节非 a-zA-Z0-9`，如 aa 啊 阿 吖 1； 犍为,犍牛,犟劲
;								新增热字串编辑框，能更好地编辑大段文字，支持换行、Tab
;					2019-08-16  修复若干小bug
;					2019-08-17  修复小bug 对pinyin词条搜索的key进行分词搜索
;					2019-08-20	Gui优化，词库结构微调
; ci_ku_Manager###############################################################################
#Include lib\Ciku_func.ahk
ci_ku_Manager:
Gui, 97:Destroy
Gui, 97: +LastFound +OwnDialogs +hwndHGui97 ;+Disabled
Gui, 97:Margin, 10, 10
Gui, 97:Add, GroupBox, xm w780 h50, 词库管理
Gui, 97:Add, Button, xp+10 yp+20 w80 vWrite gWriteCiKu Default, 导入词库
Gui, 97:Add, Button, xp+90 yp w80 gderiveCiKu, 导出词库
Gui, 97:Add, Button, xp+90 yp w80 gDelCiku, 删除词库
Gui, 97:Add, Button, xp+90 yp w80 ghelpciku, 使用帮助
Gui, 97:Add, GroupBox, xm yp+40 w780 h430, 词条管理
Gui, 97:Add, Text, xm+10 yp+20 h20 w50 0x200, 选择词库:
Gui, 97:Add, DropDownList , xp+60 yp w700 hp vTableName r5 gGetTable, xiaohe|wubi86|pinyin|hotstrings|functions
Gui, 97:Add, Text, xm+10 yp+25 w50 h20 0x200 vTX, 查找词条:
Gui, 97:Add, Edit, xp+60 yp w700 vcitiao gGetTable,
Gui, 97:Add, ListView, xm+10 yp+30 w760 h340 vResultsLV +LV0x00010000 -ReadOnly AltSubmit gSubLV1 -Multi +hwndHLV1 -LV0x10 Grid
Gui, 97:Add, StatusBar,
Gui, 97:Show, , 词库管理
Menu, MyContextMenu, Add, 新建(&N), NewRow
Menu, MyContextMenu, Add, 删除(&D), DelRow
Menu, MyContextMenu, Add, 刷新(&R), Refresh
ICELV1:=New LV_InCellEdit(HLV1, True, True)
Gui, 97:Default
GuiControl, 97:ChooseString, TableName, hotstrings
SB_SetParts(600)
Gosub, GetTable
DB.Exec("PRAGMA auto_vacuum=1")		; db删减自动调整文件大小
return
; #########################################   Gui事件   #####################################################
vared:								; 热字串、词条生成编辑框
Gui, vared:Destroy
Gui, vared:+Resize +MinSize350x250 +Owner97 -MinimizeBox ;+AlwaysOnTop
Gui, vared:Default
Gui, vared:Add, Edit, vtx r5 WantTab HWNDedhd
Gui, vared:Add, Button, gSave, 确定
MenuItem:=A_ThisMenuItem
If (A_ThisMenuItem = "编辑(&E)"){
	Gui, vared:Show, NA w350 h250, 编辑
	GuiControl, , Edit1, % StrReplace(StrReplace(StrReplace(eddata, "``n", "`n"), "``r", "`r"), "``t", "`t")
} Else
	Gui, vared:Show, NA w350 h250, 魔法创建
ControlFocus, , ahk_id %edhd%
Return

Save:								; 热字串、词条生成编辑框 g标签
Gui, 97:Default
Gui, vared:Submit
Start:=A_TickCount
If (MenuItem = "编辑(&E)"){
	StringReplace, tx, tx, `n, ``n, All
	StringReplace, tx, tx, `t, ``t, All
	If !(eddata == tx){
		LV_Modify(lastrow, "Col3", tx)
		If DB.Exec(SQL:="UPDATE hotstrings SET value='" StrReplace(tx,"'","''") "'" " WHERE id=" indexes[tv_index] ";")
			SB_SetText("更新词条：[" tv_index ",value] " eddata "-->" tx "； 完成用时：" (A_TickCount - Start) " ms")
	}
} Else If (MenuItem = "魔法创建(&W)")&&(TableName = "hotstrings"){
	StringReplace, tx, tx, `n, ``n, All
	StringReplace, tx, tx, `t, ``t, All
	DB.Exec("INSERT INTO " TableName " VALUES (NULL,'','" tx "','');")
	Loop {
		If !indexlist[A_Index] {
			tv_index:=A_Index
			indexlist[tv_index]:=True
			Break
		}
	}
	DB.GetTable("SELECT seq FROM sqlite_sequence WHERE name='" TableName "'", Result)
	indexes[tv_index]:=Result.Rows[1][1]
	ControlGet, Focusedrow, List, Count Focused, , % "ahk_id " HLV1
	LV_Insert(Focusedrow + 1, "Select", tv_index, "", tx)
	SB_SetText("插入词条：[" tv_index ",value] " Substr(tx,1,10) "； 完成用时：" (A_TickCount - Start) " ms")
	SB_SetText("已显示：" LV_GetCount() "/" (RowsCt+=1) "条", 2)
} Else
	Gosub citiao_create
Return

varedGuiSize:						; 热字串、词条生成编辑框自适应布局
GuiControlGet, P, Pos, Button1
GuiControl, Move, Button1, % "x" A_GuiWidth-10-PW "y" A_GuiHeight-6-PH
GuiControl, Move, Edit1, % "w" A_GuiWidth-21 "h" A_GuiHeight-19-PH
Return

97GuiClose:
Gui, 97:Destroy
Return

97GuiContextMenu:					; CikuManager 列表右键菜单
if (!TableName)||(A_GuiControl != "ResultsLV")||(Newflag)
	Return
ControlGet, Selected_Count, List, Count Selected, , % "ahk_id " HLV1
If (TableName~="wubi86|xiaohe|pinyin"){
	Menu, MyContextMenu, Rename, 1&, 新建词条(&N)
	Menu, MyContextMenu, Rename, 2&, 删除词条(&D)
} Else If (TableName="hotstrings"){
	Menu, MyContextMenu, Rename, 1&, 新建热字串(&N)
	Menu, MyContextMenu, Rename, 2&, 删除热字串(&D)
} Else {
	Menu, MyContextMenu, Rename, 1&, 新建命令(&N)
	Menu, MyContextMenu, Rename, 2&, 删除命令(&D)
}
If Selected_Count
	Menu, MyContextMenu, Enable, 2&
Else
	Menu, MyContextMenu, Disable, 2&
If (TableName="hotstrings"){
	Try
		Menu, MyContextMenu, Add, 编辑(&E), vared
	If Selected_Count {
		ControlGet, lastrow, List, Count Focused, , % "ahk_id " HLV1
		LV_GetText(tv_index, lastrow, 1)
		LV_GetText(eddata, lastrow, 3)
		Menu, MyContextMenu, Enable, 编辑(&E)
	} Else
		Menu, MyContextMenu, Disable, 编辑(&E)
	Try
		Menu, MyContextMenu, Add, 魔法创建(&W), vared
} Else {
	If (TableName ~= "wubi86|pinyin"){
		Try
			Menu, MyContextMenu, Add, 魔法创建(&W), vared
	}
}
Menu, MyContextMenu, Show, % A_GuiX*A_ScreenDPI/96, % A_GuiY*A_ScreenDPI/96
Loop 2
	Try 
		Menu, MyContextMenu, Delete, 4&
Return

SubLV1:								; CikuManager 列表编辑 g标签 修改、插入、删除。。。
; Check for changes
Critical
If (A_GuiEvent == "f") {
	ControlGetText, olddata, Edit2, % "ahk_id " HGui97
	ControlGet, lastrow, List, Count Focused, , % "ahk_id " HLV1
	LV_GetText(tv_index, lastrow, 1)
	If !Newflag
		ToolTip, % StrReplace(StrReplace(StrReplace(olddata, "``n", "`n"), "``r", "`r"), "``t", "`t"), A_CaretX + 25, A_CaretY + 20
} Else If (A_GuiEvent == "F") {
	If Newflag {
		Newname:=""
		If (ICELV1["Changed"]){
			For KKK, VVV In ICELV1.Changed 									; 获取修改过的单元格对象
				Break
			ICELV1.Remove("Changed")

			If !VVV.Txt {
				LV_Delete(lastrow)
				Newflag:=False
				Return
			}
			If (!(TableName ~= "xiaohe|pinyin|wubi86"))||RegExMatch(VVV.Txt,"^([^\x00-\xff]+)$"){
				Start:=A_TickCount, tkey:=""
				If (TableName = "pinyin")
					tkey:=StrSplit(hz2qp(VVV.Txt),"=","'")[1]
				Else If (TableName = "wubi86")
					tkey:=StrSplit(hz2wb86(VVV.Txt)," ")[1]
				If (TableName ~= "xiaohe|pinyin|wubi86"){
					DB.Exec(SQL:="INSERT INTO " TableName " VALUES (NULL,'" StrReplace(tkey,"'","''") "','" VVV.Txt "',1);")
					LV_Modify(lastrow, "Col4", "1")
				} Else
					DB.Exec(SQL:="INSERT INTO " TableName " VALUES (NULL,'" StrReplace(tkey,"'","''") "','" VVV.Txt "','');")
				Loop {
					If !indexlist[A_Index] {
						tv_index:=A_Index
						indexlist[tv_index]:=True
						Break
					}
				}
				LV_Modify(lastrow, "Col1", tv_index)
				LV_Modify(lastrow, "Col2", tkey)
				DB.GetTable("SELECT seq FROM sqlite_sequence WHERE name='" TableName "'", Result)
				indexes[tv_index]:=Result.Rows[1][1]
				
				SB_SetText("插入词条：[" tv_index ",value] " VVV.Txt "； 完成用时：" (A_TickCount - Start) " ms")
				SB_SetText("已显示：" LV_GetCount() "/" (RowsCt+=1) "条", 2)
			} Else {
				LV_Delete(lastrow)
				SB_SetText("value含非法字符！！！")
			}
		} Else
			LV_Delete(lastrow)
		Newflag:=False
	} Else {
		If (ICELV1["Changed"])&&TableName {
			For KKK, VVV In ICELV1.Changed
				Break
			
			LV_GetText(Columnname, 0, VVV.Col)
			ICELV1.Remove("Changed")
			t_o_txt:=VVV.Txt
			Start:=A_TickCount
			If (t_o_txt != olddata){
				If (VVV.Col = 3){
					If DB.Exec(SQL:="UPDATE " TableName " SET " Columnname "='" StrReplace(t_o_txt,"'","''") "'" " WHERE id=" indexes[tv_index] ";")
						SB_SetText("更新词条：[" tv_index "," Columnname "] " olddata "-->" t_o_txt "； 完成用时：" (A_TickCount - Start) " ms")
				} Else If (VVV.Col = 2){
					StringLower, t_o_txt, t_o_txt
					If (TableName ~= "xiaohe|pinyin"){
						RegExMatch(Trim(t_o_txt,"'"), "([a-z']+)[^a-z']*", tva)
						t_o_txt:=tva1
						If t_o_txt {
							If !InStr(t_o_txt, "'")
								t_o_txt:=Trim(pyfenci(StrReplace(t_o_txt, "'", ""),(TableName="xiaohe"?"xh":"qp")),"'")
							DB.Exec(SQL:="UPDATE " TableName " SET " Columnname "='" StrReplace(t_o_txt,"'","''") "'" " WHERE id=" indexes[tv_index] ";")
							LV_Modify(VVV.Row, "Col" VVV.Col, t_o_txt)
							SB_SetText("更新词条：[" tv_index "," Columnname "] " olddata "-->" t_o_txt "； 完成用时：" (A_TickCount - Start) " ms")
						} Else
							LV_Modify(VVV.Row, "Col" VVV.Col, olddata)
					} Else If RegExMatch(t_o_txt,"^[a-z]+$"){
						If DB.Exec(SQL:="UPDATE " TableName " SET " Columnname "='" StrReplace(t_o_txt,"'","''") "'" " WHERE id=" indexes[tv_index] ";"){
							; LV_Modify(VVV.Row, "Col" VVV.Col, t_o_txt)
							SB_SetText("更新词条：[" tv_index "," Columnname "] " olddata "-->" t_o_txt "； 完成用时：" (A_TickCount - Start) " ms")
						}
					} Else {
						LV_Modify(VVV.Row, "Col" VVV.Col, olddata)
						SB_SetText("key为小写字符串！！")
					}
				} Else If (VVV.Col = 4){
					If (TableName ~= "xiaohe|wubi86|pinyin"){
						If RegExMatch(t_o_txt,"^(\d+)$"){
							If DB.Exec(SQL:="UPDATE " TableName " SET " Columnname "=" t_o_txt " WHERE id=" indexes[tv_index] ";")
								SB_SetText("更新词条：[" tv_index "," Columnname "] " olddata "-->" t_o_txt "； 完成用时：" (A_TickCount - Start) " ms")
						} Else {
							LV_Modify(VVV.Row, "Col" VVV.Col, olddata)
							SB_SetText("weight为整数数值！！")
						}
					} Else {
						If DB.Exec(SQL:="UPDATE " TableName " SET " Columnname "='" t_o_txt "' WHERE id=" indexes[tv_index] ";")
							SB_SetText("更新词条：[" tv_index "," Columnname "] " olddata "-->" t_o_txt "； 完成用时：" (A_TickCount - Start) " ms")
					}
				}
			}
		}
		LV_GetText(keyname, lastrow, 2)
		StringLower, keyname2, keyname
		If !(keyname2 == keyname)
			LV_Modify(lastrow, "Col2", keyname2)
	}
	ToolTip
}
Return

NewRow:							; 新建行
Gui, 97:Default
ControlGet, Focusedrow, List, Count Focused, , % "ahk_id " HLV1
LV_Insert(Focusedrow + 1, "Select", "", "", "")
VarSetCapacity(RECT, 16, 0), NumPut(2, RECT, 4, "Int")			; 获取待插入单元格坐标并进入编辑状态
SendMessage, 0x1038, % Focusedrow, % &RECT, , % "ahk_id " HLV1 ; LVM_GETSUBITEMRECT
X0:=NumGet(RECT, 0, "Int")
SendMessage, 0x1014, X0 - 100, 0, , % "ahk_id " HLV1 ; LVM_SCROLL
VarSetCapacity(RECT, 16, 0), NumPut(2, RECT, 4, "Int")
SendMessage, 0x1038, % Focusedrow, % &RECT, , % "ahk_id " HLV1 ; LVM_GETSUBITEMRECT
X0:=NumGet(RECT, 0, "Int"), Y0:=NumGet(RECT, 4, "Int"), Point:=X0 + (Y0 << 16)
Newflag:=True
SendMessage, 0x0201, 0, % Point, , % "ahk_id " HLV1 ; WM_LBUTTONDOWN
SendMessage, 0x0202, 0, % Point, , % "ahk_id " HLV1 ; WM_LBUTTONUP
SendMessage, 0x0203, 0, % Point, , % "ahk_id " HLV1 ; WM_LBUTTONDBLCLK
SendMessage, 0x0202, 0, % Point, , % "ahk_id " HLV1 ; WM_LBUTTONUP
Return

DelRow:							; 删除行
Gui, 97:Default
Gui +OwnDialogs
ControlGet, Focusedrow, List, Count Focused, , % "ahk_id " HLV1 			; 获取待删除行信息
LV_GetText(tv_index, Focusedrow, 1)
LV_GetText(tv_key, Focusedrow, 2)
LV_GetText(tv_value, Focusedrow, 3)
LV_GetText(tv_weight, Focusedrow, 4)
If Focusedrow {
	SQL:="DELETE FROM " TableName " WHERE id='" indexes[tv_index] "';"
	
	Start:=A_TickCount
	If (!DB.Exec(SQL)){
		MsgBox, 16, SQLite Error: Exec, % "Msg:`t" DB.ErrorMsg "`nCode:`t" DB.ErrorCode
	} Else {
		LV_Delete(Focusedrow)
		indexlist[tv_index]:=False
		SB_SetText("删除词条：" tv_key "," tv_value "," tv_weight "； 完成用时：" (A_TickCount - Start) " ms")
		SB_SetText("已显示：" LV_GetCount() "/" (RowsCt-=1) "条", 2)
	}	
}
Return

Refresh:							; 刷新
Gui, 97:Default
Gosub GetTable
Return

DelCiku:
Gui, 97:Submit, NoHide
Gui +OwnDialogs
MsgBox, 308, 删除词库, 确实要永久性地删除此词库吗？`n%TableName%
IfMsgBox, No
	Return

; SQL:="DELETE FROM " TableName
SQL:="DROP TABLE " TableName
Start:=A_TickCount
If (DB.Exec(SQL)){
	GuiControl, -ReDraw, ResultsLV
	LV_Delete()
	GuiControl, +ReDraw, ResultsLV
	RowsCt:=0
	SB_SetText("删除词库：" TableName "； 完成用时：" (A_TickCount - Start) " ms")
	SB_SetText("", 2)
}
; 创建空表，防止读取时报错
If (TableName ~= "xiaohe|wubi86|pinyin")
	SQL = CREATE TABLE IF NOT EXISTS "%TableName%" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"weight" INTEGER DEFAULT 0);
Else
	SQL = CREATE TABLE IF NOT EXISTS "%TableName%" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"comment" TEXT);
DB.Exec(SQL)
indexlist:=[],RowsCt:=0
Return

helpciku:
Gui +OwnDialogs
MsgBox, 64, 使用帮助, % "查找词条：`n百分号（%）代表零个、一个或多个数字或字符。`n下划线（_）代表一个数字或字符。`n这些符号可以被组合使用。`n双击单元格进入编辑模式。`n修改时切换热键：`n上：Up`n下：Down`n左：Shift Tab`n右：Tab"
Return

GetTable:
Gui +OwnDialogs
Gui, 97:Default
Gui, 97:Submit, NoHide
global RowsCt
fynum:=30
Result:=""
If (TableName="pinyin")&&RegExMatch(citiao, "^([a-z]+)$")
	citiao:=Trim(pyfenci(citiao),"'")
citiao:=StrReplace(citiao, "'", "''")
SQL:="SELECT * FROM " TableName (citiao?" WHERE value like '" citiao "' " (RegExMatch(citiao, "^([a-z'_%]+)$")?"OR key LIKE '" citiao "'":"") (TableName ~= "hotstrings|functions"?" OR comment LIKE '" citiao "'":""):"") " ORDER BY key LIMIT 0," fynum
If DB.GetTable("SELECT COUNT(*) FROM " TableName (citiao?" WHERE value like '" citiao "' " (RegExMatch(citiao, "^([a-z'_%]+)$")?" OR key LIKE '" citiao "'":""):"") " ORDER BY key ", ct){
	RowsCt:=ct.Rows[1][1]
	yenum:=(ct.Rows[1][1] + fynum -1) // fynum						; 预留分页查询
} Else {
	MsgBox, 308, 词库管理, 词库不存在！`n是否创建？
	RowsCt:=0, tv_index:=0
	IfMsgBox, No
	{
		GuiControl, -ReDraw, ResultsLV
		LV_Delete()
		ColCount:=LV_GetCount("Column")
		Loop, %ColCount%
			LV_DeleteCol(1)
		GuiControl, +ReDraw, ResultsLV
		SB_SetText("词库不存在！"), SB_SetText("", 2)
		Return
	}
	If (TableName ~= "xiaohe|wubi86|pinyin")
		T_SQL = CREATE TABLE "%TableName%" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"weight" INTEGER DEFAULT 0);
	Else
		T_SQL = CREATE TABLE "%TableName%" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"comment" TEXT);
	DB.Exec(T_SQL)
}
SB_SetText("获取数据库：" TableName), SB_SetText("", 2)
Start:=A_TickCount
If !DB.GetTable(SQL, Result)
	MsgBox, 16, SQLite错误, % "消息:`t" DB.ErrorMsg "`n代码:`t" DB.ErrorCode
SB_SetText("获取数据库：" TableName "； 完成用时：" (A_TickCount - Start) " ms")
Start:=A_TickCount
ShowTable(Result)
SB_SetText("展示词条：" TableName " 前" fynum "条； 完成用时：" (A_TickCount - Start) " ms")
SB_SetText("已显示：" LV_GetCount() "/" RowsCt "条", 2)
Return

ShowTable(Table) 
{
	Global
	Local ColCount, RowCount, Row
	GuiControl, 97:-ReDraw, ResultsLV
	LV_Delete()
	ColCount:=LV_GetCount("Column")
	Loop, %ColCount%
		LV_DeleteCol(1)
	If (Table.HasNames) 
	{
		LV_InsertCol(1, "40", "index")
		LV_InsertCol(2, "100", "key")
		LV_InsertCol(3, "300", "value")
		If (TableName ~= "xiaohe|wubi86|pinyin")
			LV_InsertCol(4, "100", "weight")
		Else
			LV_InsertCol(4, "100", "comment")
		ICELV1.SetColumns(2,3,4)					; 设置key，value，weight列可编辑
		ICELV1.OnMessage()
		If (Table.HasRows) 
		{
			indexes:=[], indexlist:=[] 
			Loop, % Table.RowCount 
			{
				RowCount:=LV_Add("", "")
				Table.Next(Row)
				LV_Modify(RowCount, "Col1", A_Index)
				indexlist[A_Index]:=True
				indexes[A_Index]:=Row[1]
				Loop, % Table.ColumnCount - 1
				{
					LV_Modify(RowCount, "Col" A_Index+1, Row[A_Index+1])
				}
			}
		}
		Loop, % Table.ColumnCount
		{
			LV_ModifyCol(A_Index, "AutoHdr")
		}
		LV_ModifyCol(1, "AutoHdr", "index")
	}
	GuiControl, 97:+ReDraw, ResultsLV
}

citiao_create:							; 全拼、wubi86词条自动生成拼音
	Gui, 97:Default
	Gui +OwnDialogs
	GuiControl, 97:-ReDraw, ResultsLV
	LV_GetText(nm, 0, 2)
	If (nm != "key"){
			LV_Delete()
		ColCount:=LV_GetCount("Column")
		Loop, %ColCount%
			LV_DeleteCol(1)
		LV_InsertCol(1, "40", "index")
		LV_InsertCol(2, "100", "key")
		LV_InsertCol(3, "300", "value")
		LV_InsertCol(4, "100", "weight")
	}
	err:="",index:=0,cizu:=[],cipin:=[],tstr:="",start:=A_TickCount,Inscount:=0
	ControlGet, lastrow, List, Count Focused, , % "ahk_id " HLV1
	SB_SetText("生成、写入词条中 ..."),SB_SetText("",2)
	DB.Exec("DROP INDEX IF EXISTS sy_" TableName ";")
	DB.Exec("BEGIN TRANSACTION;")
	tx:=StrSplit(tx, "`n", "`r")									; 词条拆分
	Loop % tx.Length()
	{
		If !(tva:=tx[A_Index])
			Continue
		RegExMatch(tva, "(['a-zA-Z]+)", tkey)						; 查找key
		RegExMatch(tva, "(\d+)", tcipin), tcipin:=tcipin?tcipin:1	; 查找词频
		RegExMatch(tva, "O)([^\x00-\xff]+)", tcizu, 1)				; 查找双字节字符
		If !tcizu.value
			Continue
		If !tkey
			cizu[index+=1]:=tcizu.value, cipin[index]:=tcipin, tstr .= tcizu.value "`n"
		Else {
			StringLower, tkey, % Trim(tkey,"'")
			If (TableName = "pinyin"){
				If !InStr(tkey, "'")									; 未分词的分词处理
					tkey:=Trim(pyfenci(tkey,"qp"),"'")
			} Else
				tkey:=StrReplace(tkey,"'","")
			DB.Exec("INSERT INTO " TableName " VALUES (NULL,'" StrReplace(tkey,"'","''") "','" tcizu.value "'," tcipin ");"),RowsCt+=1
			If (Inscount>100)										; 超过100条列表不显示
				Continue
			LV_Insert(lastrow+=1, "Select", "", tkey, tcizu.value, tcipin),Inscount+=1
			Loop {													; 生成列表index
				If !indexlist[A_Index] {
					tv_index:=A_Index
					indexlist[tv_index]:=True
					Break
				}
			}
			LV_Modify(lastrow, "Col1", tv_index)
		}
		While RegExMatch(tva, "O)([^\x00-\xff]+)", tcizu, tcizu.pos+tcizu.len){			; 查找双字节字符加入待转序列
			If !tkey
				cizu[index+=1]:=tcizu.value, cipin[index]:=tcipin,  tstr .= tcizu.value "`n"
			Else {
				DB.Exec("INSERT INTO " TableName " VALUES (NULL,'" StrReplace(tkey,"'","''") "','" tcizu.value "'," tcipin ");"),RowsCt+=1
				If (Inscount>100)
					Continue
				LV_Insert(lastrow+=1, "Select", "", tkey, tcizu.value, tcipin),Inscount+=1
				Loop {
					If !indexlist[A_Index] {
						tv_index:=A_Index
						indexlist[tv_index]:=True
						Break
					}
				}
				LV_Modify(lastrow, "Col1", tv_index)
			}
		}
	}
	If tstr&&(TableName ~= "pinyin|wubi86") {							; 转换成拼音、wubi86
		If (TableName="pinyin")
			tstr:=hz2qp(tstr)
		Else
			tstr:=hz2wb86(tstr)
		cpindex:=0,fgfu:=(TableName="pinyin"?"=":" ")
		Loop, Parse, tstr, `n, `r
		{
			If(A_LoopField=="")
				Continue
			tarr:=StrSplit(A_LoopField,fgfu,"'")
			While (cizu[cpindex+=1])&&(tarr[2] != cizu[cpindex])
				cpindex+=1
			_SQL:="Insert INTO " TableName " VALUES(NULL,'" tarr[1] "','" tarr[2] "'," (cipin[cpindex]?cipin[cpindex]:1) ");"
			DB.Exec(_SQL),RowsCt+=1
			If (Inscount>100)
				Continue
			LV_Insert(lastrow+=1, "Select", "", tarr[1], tarr[2], (cipin[cpindex]?cipin[cpindex]:0)),Inscount+=1
			Loop {
				If !indexlist[A_Index] {
					tv_index:=A_Index
					indexlist[tv_index]:=True
					Break
				}
			}
			LV_Modify(lastrow, "Col1", tv_index)
		}
		tstr:="",cizu:="",cipin:="",tarr:=""
	}
	SB_SetText("写入完毕，准备数据去重...")
	DB.Exec("DROP TABLE IF EXISTS hebing;")
	If (TableName ~= "xiaohe|wubi86|pinyin")
		_SQL = CREATE TABLE hebing ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"weight" INTEGER DEFAULT 0);
	Else
		_SQL = CREATE TABLE hebing ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"comment" TEXT);
	DB.Exec(_SQL)
	If (TableName ~= "xiaohe|wubi86|pinyin")
		_SQL:="INSERT INTO hebing SELECT NULL,key,value,sum(weight) FROM " TableName " GROUP by key,value ORDER by key,value;"
	Else
		_SQL:="INSERT INTO hebing SELECT NULL,key,value,comment FROM " TableName " GROUP by key,value ORDER by key,value;"
	If DB.Exec(_SQL)
		DB.Exec("DROP TABLE " TableName ";ALTER TABLE hebing RENAME TO " TableName ";")
	DB.Exec("CREATE INDEX sy_" TableName " ON " TableName " (key);")
	DB.Exec("COMMIT TRANSACTION;")
	SB_SetText("去重完毕，完成用时 " A_TickCount - Start " ms")
	GuiControl, 97:+ReDraw, ResultsLV
	SB_SetText("已显示：" LV_GetCount() "/" (RowsCt) "条", 2)
	cizu:=[],cipin:=[],tstr:="",zidian:=[]
	If err
		MsgBox, 48, 错误, 以下词条生成key失败！！！`n%err%
Return

WriteCiKu:
; ======================================================================================================================
; 导入词库
; ======================================================================================================================
Gui, 97:Submit, NoHide
Gui +OwnDialogs
MsgBox, 64, 导入说明, 数据文件是以待导入的词库名为前缀的文本文档。`n数据内容按顺序包括键码key、内容value、权重weight或备注comment(非必须)，以=分隔。`n导入pinyin、wubi86词库时，键码key非必须，可自动生成。格式如下：`npin'yin=拼音=16`nggtt=五笔`n影子输入法=88`n影子输入法
FileSelectFile, MaBiaoFile, 3, , 导入词库, Text Documents (*.txt)
SplitPath, MaBiaoFile, , , , filename
if MaBiaoFile =
{
	; MsgBox, 没选文件.
	return
}
else
{
	SB_SetText("选择了词库：" MaBiaoFile), SB_SetText("",2)
}
If !RegExMatch(filename, "^(xiaohe|wubi86|hotstrings|pinyin|functions)",filename){
	MsgBox, 48, 注意,词库文件名以要导入的词库名开头，请检查文件名！！！
	Return
} Else {
	If DB.GetTable("SELECT COUNT(*) FROM " filename, ct){
		If ct.Rows[1][1] {
			MsgBox, 308, 注意,是否合并词库？
			IfMsgBox No
				Return
		}
	} Else {
		If (filename ~= "xiaohe|wubi86|pinyin")
			_SQL = CREATE TABLE "%filename%" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"weight" INTEGER DEFAULT 0);
		Else
			_SQL = CREATE TABLE "%filename%" ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"comment" TEXT);
		DB.Exec(_SQL)
	}
	GuiControl, 97:ChooseString, TableName, % filename
	LV_Delete()
}
Start:=A_TickCount, temp1:=""
; ======================================================================================================================
; #######################################词组拼音生成导入###########################
; ======================================================================================================================
FileReadLine, MaBiao, %MaBiaoFile%, 1
If (filename~="pinyin|wubi86")&&(RegExMatch(MaBiao, "^[^\x20-\x7e]+(=\d+)?$",temp)){
	SB_SetText("转换词库中，请稍后..."),SB_SetText("",2)
	If temp1 {
		FileRead, MaBiao2, %MaBiaoFile%
		MaBiaoFile:="cikutemp.txt"
		FileAppend, % RegExReplace(MaBiao2, "im)(*ANYCRLF)[\x20-\xff]+", ""), cikutemp.txt
	} Else
		MaBiaoFile:="""" MaBiaoFile """"
	If (filename="pinyin")
		cmd = lib\深蓝词库转换.exe -i:word %MaBiaoFile% -o:self cikutemp.txt "-f:123'=nyyn" -ct:pinyin
	Else If (filename="wubi86")
		cmd = lib\深蓝词库转换.exe -i:word %MaBiaoFile% -o:wb86 cikutemp.txt
	ws:=ComObjCreate("WScript.Shell")
	ws.Run(cmd,0,1)
	FileRead, MaBiao, cikutemp.txt
	FileDelete, cikutemp.txt
} Else
	FileRead, MaBiao, %MaBiaoFile%
; ======================================================================================================================
; #######################################词库写入###########################
; ======================================================================================================================
SB_SetText("词库写入中，请稍后..." )
DB.Exec("DROP INDEX IF EXISTS sy_" filename ";")
DB.Exec("BEGIN TRANSACTION;")
tarr:=[], tp:=False
If temp {
	fgfu:=(filename="pinyin"?"=":" ")
	If (filename="pinyin")
		MaBiao:=StrReplace(MaBiao, "'", "''")
	If temp1
		MaBiao2:=StrSplit(MaBiao2, "`n", "`r"),mb2index:=0
	Loop, Parse, MaBiao, `n, `r
	{
		If(A_LoopField=="")
			Continue
		tarr:=StrSplit(A_LoopField,fgfu)
		If temp1 {
			tarr2:=StrSplit(MaBiao2[mb2index+=1],"=")
			While (tarr2[1])&&(tarr[2] != tarr2[1])
				tarr2:=StrSplit(MaBiao2[mb2index+=1],"=")
			_SQL:="Insert INTO " filename " VALUES(NULL,'" tarr[1] "','" tarr[2] "'," (tarr2[2]?tarr2[2]:1) ");"
		} Else
			_SQL:="Insert INTO " filename " VALUES(NULL,'" tarr[1] "','" tarr[2] "',1);"
		DB.Exec(_SQL)
	}
	MaBiao2:=MaBiao:=""
} Else {
	If InStr(MaBiao, "'")
		MaBiao:=StrReplace(MaBiao, "'", "''")
	Else If (filename="pinyin"){
		Loop, Parse, MaBiao, `n, `r
		{
			if (A_LoopField != ""){
				tarr:=StrSplit(A_LoopField,"=")
				tkey:=tarr[1]
				StringLower, tkey, tkey
				tkey:=StrReplace(Trim(pyfenci(tkey),"'"), "'", "''")
				If tp||(tp:=RegExMatch(A_LoopField,"^[^=]+=[^=]+=\d+$")) {
					_SQL:="Insert INTO " filename " VALUES(NULL,'" tkey "','" tarr[2] "','" (tarr[3]?tarr[3]:1) "');"
					DB.Exec(_SQL)
				} Else {
					loop % tarr.Length() - 1
					{
						_SQL:="Insert INTO " filename " VALUES(NULL,'" tkey "','" tarr[A_Index+1] "',1);"
						DB.Exec(_SQL)
					}
				}
			}
		}
		MaBiao:=""
	}
	Loop, Parse, MaBiao, `n, `r
	{
		if (A_LoopField != ""){
			tarr:=StrSplit(A_LoopField,"=")
			tkey:=tarr[1]
			StringLower, tkey, tkey
			If tp||(tp:=RegExMatch(A_LoopField,"^[^=]+=[^=]+=\d+$")) {
				_SQL:="Insert INTO " filename " VALUES(NULL,'" tkey "','" tarr[2] "','" (tarr[3]?tarr[3]:1) "');"
				DB.Exec(_SQL)
			} Else If (filename ~= "hotstrings|functions"){
				_SQL:="Insert INTO " filename " VALUES(NULL,'" tkey "','" tarr[2] "','" tarr[3] "');"
				DB.Exec(_SQL)
			} Else {
				loop % tarr.Length() - 1
				{
					_SQL:="Insert INTO " filename " VALUES(NULL,'" tkey "','" tarr[A_Index+1] "',1);"
					DB.Exec(_SQL)
				}
			}
		}
	}
	MaBiao:=""
}
SB_SetText("写入完毕，准备数据去重...")
DB.Exec("DROP TABLE IF EXISTS hebing;")
If (filename ~= "xiaohe|wubi86|pinyin")
	_SQL = CREATE TABLE hebing ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"weight" INTEGER DEFAULT 0);
Else
	_SQL = CREATE TABLE hebing ("id" INTEGER PRIMARY KEY AUTOINCREMENT,"key" TEXT,"value" TEXT,"comment" TEXT);
DB.Exec(_SQL)
If (filename ~= "xiaohe|wubi86|pinyin")
	_SQL:="INSERT INTO hebing SELECT NULL,key,value,sum(weight) FROM " filename " GROUP by key,value ORDER by key,value;"
Else
	_SQL:="INSERT INTO hebing SELECT NULL,key,value,comment FROM " filename " GROUP by key,value ORDER by key,value;"
If DB.Exec(_SQL)
	DB.Exec("DROP TABLE " filename ";ALTER TABLE hebing RENAME TO " filename ";")
DB.Exec("CREATE INDEX sy_" filename " ON " filename " (key);")
DB.Exec("COMMIT TRANSACTION;")
SB_SetText("去重完毕，完成用时 " A_TickCount - Start " ms")
return

deriveCiKu:													; 导出词库
	Gui +OwnDialogs
	gui,97:Default
	gui,97:Submit,NoHide
	MsgBox,% TableName
	SQL:="SELECT * FROM " TableName ";"
	start:=A_TickCount
	SB_SetText("读取数据...")
	Result:="", outputword:=""
	If !DB.GetTable(SQL, Result)
	   MsgBox, 16, 读取数据错误, % "消息:`t" DB.ErrorMsg "`n代码:`t" DB.ErrorCode
	SB_SetText("读取数据完毕，写入备份文件！" )
	loop,% Result.RowCount
	{
		If RegExMatch(Result.Rows[A_Index,2],"^([a-z]+)(\d*)$",_Newname)
			Newname:= _Newname1
		Else
			Newname:=Result.Rows[A_Index,2]
		outputword .= Newname "=" Result.Rows[A_Index,3] "=" Result.Rows[A_Index,4] "`n"
	}
	If FileExist(TableName ".txt")
		FileDelete, %TableName%.txt
	FileAppend,%outputword%,%TableName%.txt
	SB_SetText("导出完毕！完成用时：" A_TickCount - start " ms")
return
; ci_ku_Manager###############################################################################

; ======================================================================================================================
; Namespace:      LV_InCellEdit (ListView列表单元格编辑类)
; Function:       Support for in-cell ListView editing.
; Tested with:    AHK 1.1.22.09 (1.1.20+ required)
; Tested on:      Win 10 Pro (x64)
; Change History: 1.2.02.00/2015-12-14/just me - Bug fix and support for centered columns.
;                 1.2.01.00/2015-09-08/just me - Added EditUserFunc option.
;                 1.2.00.00/2015-03-29/just me - New version based on AHK 1.1.20+ features.
;                 1.1.04.00/2014-03-22/just me - Added method EditCell
;                 1.1.03.00/2012-05-05/just me - Added back option BlankSubItem for method Attach
;                 1.1.02.00/2012-05-01/just me - Added method SetColumns
;                 1.1.01.00/2012-03-18/just me
; ======================================================================================================================
; CLASS LV_InCellEdit
;
; Unlike other in-cell editing scripts, this class is using the ListViews built-in edit control.
; Advantage:
;     You don't have to care about the font and the GUI, and most of the job can be done by handling common ListView
;     notifications.
; Disadvantage:
;     I've still found no way to prevent the ListView from blanking out the first subitem of the row while editing
;     another subitem. The only known workaround is to add a hidden first column.
;
; The class provides methods to restrict editing to certain columns, to directly start editing of a specified cell,
; and to deactivate/activate the built-in message handler for WM_NOTIFY messages (see below).
;
; The message handler for WM_NOTIFY messages will be activated for the specified ListView whenever a new instance is
; created. As long as the message handler is activated a double-click on any cell will show an Edit control within this
; cell allowing to edit the current content. The default behavior for editing the first column by two subsequent single
; clicks is disabled. You have to press "Esc" to cancel editing, otherwise the content of the Edit will be stored in
; the current cell. ListViews must have the -ReadOnly option to be editable.
;
; While editing, "Esc", "Tab", "Shift+Tab", "Down", and "Up" keys are registered as hotkeys. "Esc" will cancel editing
; without changing the value of the current cell. All other hotkeys will store the content of the edit in the current
; cell and continue editing for the next (Tab), previous (Shift+Tab), upper (Up), or lower (Down) cell. You cannot use
; the keys for other purposes while editing.
;
; All changes are stored in MyInstance.Changed. You may track the changes by triggering (A_GuiEvent == "F") in the
; ListView's gLabel and checking MyInstance["Changed"] as shown in the sample scipt. If "True", MyInstance.Changed
; contains an array of objects with keys "Row" (row number), "Col" (column number), and "Txt" (new content).
; Changed is one of the two keys intended to be accessed directly from outside the class.
;
; If you want to temporarily disable in-cell editing call MyInstance.OnMessage(False). This must be done also before
; you try to destroy the instance. To enable it again, call MyInstance.OnMessage().
;
; To avoid the loss of Gui events and messages the message handler might need to be 'critical'. This can be
; achieved by setting the instance property 'Critical' to the required value (e.g. MyInstance.Critical:=100).
; New instances default to 'Critical, Off'. Though sometimes needed, ListViews or the whole Gui may become
; unresponsive under certain circumstances if Critical is set and the ListView has a g-label.
; ======================================================================================================================
Class LV_InCellEdit {
	; Instance properties -----------------------------------------------------------------------------------------------
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; META FUNCTIONS ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; ===================================================================================================================
	; __New()         Creates a new LV_InCellEdit instance for the specified ListView.
	; Parameters:     HWND           -  ListView's HWND
	;                 Optional ------------------------------------------------------------------------------------------
	;                 HiddenCol1     -  ListView with hidden first column
	;                                   Values:  True / False
	;                                   Default: False
	;                 BlankSubItem   -  Blank out subitem's text while editing
	;                                   Values:  True / False
	;                                   Default: False
	;                 EditUserFunc   -  The name of a user-defined funtion to be called from
	;                                   LVN_BEGINEDITLABEL and LVN_ENDEDITLABEL.
	;                                   The function must accept at least 6 Parameters:
	;                                      State -  The state of the edit operation: BEGIN / END
	;                                      HLV   -  The handle to the ListView.
	;                                      HED   -  The handle to the edit control.
	;                                      Row   -  The row number of the edited item.
	;                                      Col   -  The column number of the edited item.
	;                                      Text  -  The edited item's text before / after editing.
	;                                   To avoid the loss of messages the function should return as soon as possible.
	; ===================================================================================================================
	__New(HWND, HiddenCol1:=False, BlankSubItem:=False, EditUserFunc:="") {
		If (This.Base.Base.__Class) ; do not instantiate instances
			Return False
		If This.Attached[HWND] ; HWND is already attached
			Return False
		If !DllCall("IsWindow", "Ptr", HWND) ; invalid HWND
			Return False
		VarSetCapacity(Class, 512, 0)
		DllCall("GetClassName", "Ptr", HWND, "Str", Class, "Int", 256)
		If (Class <> "SysListView32") ; HWND doesn't belong to a ListView
			Return False
		If (EditUserFunc <> "") && (Func(EditUserFunc).MaxParams < 6)
			Return False
		; ----------------------------------------------------------------------------------------------------------------
		; Set LVS_EX_DOUBLEBUFFER (0x010000) style to avoid drawing issues.
		SendMessage, 0x1036, 0x010000, 0x010000, , % "ahk_id " . HWND ; LVM_SETEXTENDEDLISTVIEWSTYLE
		This.HWND:=HWND
		This.HEDIT:=0
		This.Item:=-1
		This.SubItem:=-1
		This.ItemText:=""
		This.RowCount:=0
		This.ColCount:=0
		This.Cancelled:=False
		This.Next:=False
		This.Skip0:=!!HiddenCol1
		This.Blank:=!!BlankSubItem
		This.Critical:="Off"
		This.DW:=0
		This.EX:=0
		This.EY:=0
		This.EW:=0
		This.EH:=0
		This.LX:=0
		This.LY:=0
		This.LR:=0
		This.LW:=0
		This.SW:=0
		If (EditUserFunc <> "")
			This.EditUserFunc:=Func(EditUserFunc)
		This.OnMessage()
		This.Attached[HWND]:=True
	}
	; ===================================================================================================================
	__Delete() {
		This.Attached.Remove(This.HWND, "")
		WinSet, Redraw, , % "ahk_id " . This.HWND
	}
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; PUBLIC INTERFACE ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; ===================================================================================================================
	; EditCell        Edit the specified cell, if possible.
	; Parameters:     Row   -  1-based row number
	;                 Col   -  1-based column number
	;                          Default: 0 - edit the first editable column
	; Return values:  True on success; otherwise False
	; ===================================================================================================================
	EditCell(Row, Col:=0) {
		If !This.HWND
			Return False
		ControlGet, Rows, List, Count, , % "ahk_id " . This.HWND
		This.RowCount:=Rows - 1
		ControlGet, ColCount, List, Count Col, , % "ahk_id " . This.HWND
		This.ColCount:=ColCount - 1
		If (Col = 0) {
			If (This["Columns"])
				Col:=This.Columns.MinIndex() + 1
			ELse If This.Skip0
				Col:=2
			Else
				Col:=1
		}
		If (Row < 1) || (Row > Rows) || (Col < 1) || (Col > ColCount)
			Return False
		If (Column = 1) && This.Skip0
			Col:=2
		If (This["Columns"])
			If !This.Columns[Col - 1]
				Return False
		VarSetCapacity(LPARAM, 1024, 0)
		NumPut(Row - 1, LPARAM, (A_PtrSize * 3) + 0, "Int")
		NumPut(Col - 1, LPARAM, (A_PtrSize * 3) + 4, "Int")
		This.NM_DBLCLICK(&LPARAM)
		Return True
	}
	; ===================================================================================================================
	; SetColumns      Sets the columns you want to edit
	; Parameters:     ColNumbers* -  zero or more numbers of column which shall be editable. If entirely omitted,
	;                                the ListView will be reset to enable editing of all columns.
	; Return values:  True on success; otherwise False
	; ===================================================================================================================
	SetColumns(ColNumbers*) {
		If !This.HWND
			Return False
		This.Remove("Columns")
		If (ColNumbers.MinIndex() = "")
			Return True
		ControlGet, ColCount, List, Count Col, , % "ahk_id " . This.HWND
		Indices:=[]
		For Each, Col In ColNumbers {
			If Col Is Not Integer
				Return False
			If (Col < 1) || (Col > ColCount)
				Return False
			Indices[Col - 1]:=True
		}
		This["Columns"]:=Indices
		Return True
	}
	; ===================================================================================================================
	; OnMessage       Activate / deactivate the message handler for WM_NOTIFY messages for this ListView
	; Parameters:     Apply    -  True / False
	;                             Default: True
	; Return Value:   Always True
	; ===================================================================================================================
	OnMessage(Apply:=True) {
		If !This.HWND
			Return False
		If (Apply) && !This.HasKey("NotifyFunc") {
			This.NotifyFunc:=ObjBindMethod(This, "On_WM_NOTIFY")
			OnMessage(0x004E, This.NotifyFunc) ; add the WM_NOTIFY message handler
		}
		Else If !(Apply) && This.HasKey("NotifyFunc") {
			OnMessage(0x004E, This.NotifyFunc, 0) ; remove the WM_NOTIFY message handler
			This.NotifyFunc:=""
			This.Remove("NotifyFunc")
		}
		WinSet, Redraw, , % "ahk_id " . This.HWND
		Return True
	}
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; PRIVATE PROPERTIES ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; Class properties --------------------------------------------------------------------------------------------------
	Static Attached:={}
	Static OSVersion:=DllCall("GetVersion", "UChar")
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; PRIVATE METHODS +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	; -------------------------------------------------------------------------------------------------------------------
	; WM_COMMAND message handler for edit notifications
	; -------------------------------------------------------------------------------------------------------------------
	On_WM_COMMAND(W, L, M, H) {
		; LVM_GETSTRINGWIDTHW = 0x1057, LVM_GETSTRINGWIDTHA = 0x1011
		Critical, % This.Critical
		If (L = This.HEDIT) {
			N:=(W >> 16)
			If (N = 0x0400) || (N = 0x0300) || (N = 0x0100) { ; EN_UPDATE | EN_CHANGE | EN_SETFOCUS
				If (N = 0x0100) ; EN_SETFOCUS
					SendMessage, 0x00D3, 0x01, 0, , % "ahk_id " . L ; EM_SETMARGINS, EC_LEFTMARGIN
				ControlGetText, EditText, , % "ahk_id " . L
				SendMessage, % (A_IsUnicode ? 0x1057 : 0x1011), 0, % &EditText, , % "ahk_id " . This.HWND
				EW:=ErrorLevel + This.DW
				, EX:=This.EX
				, EY:=This.EY
				, EH:=This.EH + (This.OSVersion < 6 ? 3 : 0) ; add 3 for WinXP
				If (EW < This.MinW)
					EW:=This.MinW
				If (EX + EW) > This.LR
					EW:=This.LR - EX
				DllCall("SetWindowPos", "Ptr", L, "Ptr", 0, "Int", EX, "Int", EY, "Int", EW, "Int", EH, "UInt", 0x04)
				If (N = 0x0400) ; EN_UPDATE
					Return 0
			}
		}
	}
	; -------------------------------------------------------------------------------------------------------------------
	; WM_HOTKEY message handler
	; -------------------------------------------------------------------------------------------------------------------
	On_WM_HOTKEY(W, L, M, H) {
		; LVM_CANCELEDITLABEL = 0x10B3, Hotkeys: 0x801B  (Esc -> cancel)
		If (H = This.HWND) {
			If (W = 0x801B) { ; Esc
				This.Cancelled:=True
				PostMessage, 0x10B3, 0, 0, , % "ahk_id " . H
			}
			Else {
				This.Next:=True
				SendMessage, 0x10B3, 0, 0, , % "ahk_id " . H
				This.Next:=True
				This.NextSubItem(W)
			}
			Return False
		}
	}
	; -------------------------------------------------------------------------------------------------------------------
	; WM_NOTIFY message handler
	; -------------------------------------------------------------------------------------------------------------------
	On_WM_NOTIFY(W, L) {
		Critical, % This.Critical
		If (H:=NumGet(L + 0, 0, "UPtr") = This.HWND) {
			M:=NumGet(L + (A_PtrSize * 2), 0, "Int")
			; BeginLabelEdit -------------------------------------------------------------------------------------------------
			If (M = -175) || (M = -105) ; LVN_BEGINLABELEDITW || LVN_BEGINLABELEDITA
				Return This.LVN_BEGINLABELEDIT(L)
			; EndLabelEdit ---------------------------------------------------------------------------------------------------
			If (M = -176) || (M = -106) ; LVN_ENDLABELEDITW || LVN_ENDLABELEDITA
				Return This.LVN_ENDLABELEDIT(L)
			; Double click ---------------------------------------------------------------------------------------------------
			If (M = -3) ; NM_DBLCLICK
				This.NM_DBLCLICK(L)
		}
	}
	; -------------------------------------------------------------------------------------------------------------------
	; LVN_BEGINLABELEDIT notification
	; -------------------------------------------------------------------------------------------------------------------
	LVN_BEGINLABELEDIT(L) {
		Static Indent:=4   ; indent of the Edit control, 4 seems to be reasonable for XP, Vista, and 7
		If (This.Item = -1) || (This.SubItem = -1)
			Return True
		H:=This.HWND
		SendMessage, 0x1018, 0, 0, , % "ahk_id " . H ; LVM_GETEDITCONTROL
		This.HEDIT:=ErrorLevel
		, VarSetCapacity(ItemText, 2048, 0) ; text buffer
		, VarSetCapacity(LVITEM, 40 + (A_PtrSize * 5), 0) ; LVITEM structure
		, NumPut(This.Item, LVITEM, 4, "Int")
		, NumPut(This.SubItem, LVITEM, 8, "Int")
		, NumPut(&ItemText, LVITEM, 16 + A_PtrSize, "Ptr") ; pszText in LVITEM
		, NumPut(1024 + 1, LVITEM, 16 + (A_PtrSize * 2), "Int") ; cchTextMax in LVITEM
		SendMessage, % (A_IsUnicode ? 0x1073 : 0x102D), % This.Item, % &LVITEM, , % "ahk_id " . H ; LVM_GETITEMTEXT
		This.ItemText:=StrGet(&ItemText, ErrorLevel)
		; Call the user function, if any
		If (This.EditUserFunc)
			This.EditUserFunc.Call("BEGIN", This.HWND, This.HEDIT, This.Item + 1, This.Subitem + 1, This.ItemText)
		SendMessage, 0x000C, 0, % &ItemText, , % "ahk_id " . This.HEDIT
		If (This.SubItem > 0) && (This.Blank) {
			Empty:=""
			, NumPut(&Empty, LVITEM, 16 + A_PtrSize, "Ptr") ; pszText in LVITEM
			, NumPut(0,LVITEM, 16 + (A_PtrSize * 2), "Int") ; cchTextMax in LVITEM
			SendMessage, % (A_IsUnicode ? 0x1074 : 0x102E), % This.Item, % &LVITEM, , % "ahk_id " . H ; LVM_SETITEMTEXT
		}
		VarSetCapacity(RECT, 16, 0)
		, NumPut(This.SubItem, RECT, 4, "Int")
		SendMessage, 0x1038, This.Item, &RECT, , % "ahk_id " . H ; LVM_GETSUBITEMRECT
		This.EX:=NumGet(RECT, 0, "Int") + Indent
		, This.EY:=NumGet(RECT, 4, "Int")
		If (This.OSVersion < 6)
			This.EY -= 1 ; subtract 1 for WinXP
		If (This.SubItem = 0) {
			SendMessage, 0x101D, 0, 0, , % "ahk_id " . H ; LVM_GETCOLUMNWIDTH
			This.EW:=ErrorLevel
		}
		Else
			This.EW:=NumGet(RECT, 8, "Int") - NumGet(RECT, 0, "Int")
		This.EH:=NumGet(RECT, 12, "Int") - NumGet(RECT, 4, "Int")
		; Check the column alignement
		VarSetCapacity(LVCOL, 56, 0)
		, NumPut(1, LVCOL, "UInt") ; LVCF_FMT
		SendMessage, % (A_IsUnicode ? 0x105F : 0x1019), % This.SubItem, % &LVCOL, , % "ahk_id " . H ; LVM_GETCOLUMN
		If (NumGet(LVCOL, 4, "UInt") & 0x0002) { ; LVCFMT_CENTER
			SendMessage, % (A_IsUnicode ? 0x1057 : 0x1011), 0, % &ItemText, , % "ahk_id " . This.HWND ; LVM_GETSTRINGWIDTH
			EW:=ErrorLevel + This.DW
			If (EW < This.MinW)
				EW:=This.MinW
			If (EW < This.EW)
				This.EX += ((This.EW - EW) // 2) - Indent
		}
		; Register WM_COMMAND handler
		This.CommandFunc:=ObjBindMethod(This, "On_WM_COMMAND")
		, OnMessage(0x0111, This.CommandFunc)
		; Register hotkeys
		If !(This.Next)
			This.RegisterHotkeys()
		This.Cancelled:=False
		This.Next:=False
		Return False
	}
	; -------------------------------------------------------------------------------------------------------------------
	; LVN_ENDLABELEDIT notification
	; -------------------------------------------------------------------------------------------------------------------
	LVN_ENDLABELEDIT(L) {
		H:=This.HWND
		; Unregister WM_COMMAND handler
		OnMessage(0x0111, This.CommandFunc, 0)
		This.CommandFunc:=""
		; Unregister hotkeys
		If !(This.Next)
			This.RegisterHotkeys(False)
		ItemText:=This.ItemText
		If !(This.Cancelled)
			ControlGetText, ItemText, , % "ahk_id " . This.HEDIT
		If (ItemText <> This.ItemText) {
			If !(This["Changed"])
				This.Changed:=[]
			This.Changed.Insert({Row: This.Item + 1, Col: This.SubItem + 1, Txt: ItemText})
		}
		; Restore subitem's text if changed or blanked out
		If (ItemText <> This.ItemText) || ((This.SubItem > 0) && (This.Blank)) {
			VarSetCapacity(LVITEM, 40 + (A_PtrSize * 5), 0) ; LVITEM structure
			, NumPut(This.Item, LVITEM, 4, "Int")
			, NumPut(This.SubItem, LVITEM, 8, "Int")
			, NumPut(&ItemText, LVITEM, 16 + A_PtrSize, "Ptr") ; pszText in LVITEM
			SendMessage, % (A_IsUnicode ? 0x1074 : 0x102E), % This.Item, % &LVITEM, , % "ahk_id " . H ; LVM_SETITEMTEXT
		}
		If !(This.Next)
			This.Item:=This.SubItem:=-1
		This.Cancelled:=False
		This.Next:=False
		; Call the user function, if any
		If (This.EditUserFunc)
			This.EditUserFunc.Call("END", This.HWND, This.HEDIT, This.Item + 1, This.Subitem + 1, ItemText)
		Return False
	}
	; -------------------------------------------------------------------------------------------------------------------
	; NM_DBLCLICK notification
	; -------------------------------------------------------------------------------------------------------------------
	NM_DBLCLICK(L) {
		H:=This.HWND
		This.Item:=This.SubItem:=-1
		Item:=NumGet(L + (A_PtrSize * 3), 0, "Int")
		SubItem:=NumGet(L + (A_PtrSize * 3), 4, "Int")
		If (This["Columns"]) {
			If !This["Columns", SubItem]
				Return False
		}
		If (Item >= 0) && (SubItem >= 0) {
			This.Item:=Item, This.SubItem:=SubItem
			If !(This.Next) {
				ControlGet, V, List, Count, , % "ahk_id " . H
				This.RowCount:=V - 1
				ControlGet, V, List, Count Col, , % "ahk_id " . H
				This.ColCount:=V - 1
				, NumPut(VarSetCapacity(WINDOWINFO, 60, 0), WINDOWINFO)
				, DllCall("GetWindowInfo", "Ptr", H, "Ptr", &WINDOWINFO)
				, This.DX:=NumGet(WINDOWINFO, 20, "Int") - NumGet(WINDOWINFO, 4, "Int")
				, This.DY:=NumGet(WINDOWINFO, 24, "Int") - NumGet(WINDOWINFO, 8, "Int")
				, Styles:=NumGet(WINDOWINFO, 36, "UInt")
				SendMessage, % (A_IsUnicode ? 0x1057 : 0x1011), 0, % "WWW", , % "ahk_id " . H ; LVM_GETSTRINGWIDTH
				This.MinW:=ErrorLevel
				SendMessage, % (A_IsUnicode ? 0x1057 : 0x1011), 0, % "III", , % "ahk_id " . H ; LVM_GETSTRINGWIDTH
				This.DW:=ErrorLevel
				, SBW:=0
				If (Styles & 0x200000) ; WS_VSCROLL
					SysGet, SBW, 2
				ControlGetPos, LX, LY, LW, , , % "ahk_id " . H
				This.LX:=LX
				, This.LY:=LY
				, This.LR:=LX + LW - (This.DX * 2) - SBW
				, This.LW:=LW
				, This.SW:=SBW
				, VarSetCapacity(RECT, 16, 0)
				, NumPut(SubItem, RECT, 4, "Int")
				SendMessage, 0x1038, %Item%, % &RECT, , % "ahk_id " . H ; LVM_GETSUBITEMRECT
				X:=NumGet(RECT, 0, "Int")
				If (SubItem = 0) {
					SendMessage, 0x101D, 0, 0, , % "ahk_id " . H ; LVM_GETCOLUMNWIDTH
					W:=ErrorLevel
				}
				Else
					W:=NumGet(RECT, 8, "Int") - NumGet(RECT, 0, "Int")
				R:=LW - (This.DX * 2) - SBW
				If (X < 0)
					SendMessage, 0x1014, % X, 0, , % "ahk_id " . H ; LVM_SCROLL
				Else If ((X + W) > R)
					SendMessage, 0x1014, % (X + W - R + This.DX), 0, , % "ahk_id " . H ; LVM_SCROLL
			}
			PostMessage, % (A_IsUnicode ? 0x1076 : 0x1017), %Item%, 0, , % "ahk_id " . H ; LVM_EDITLABEL
		}
		Return False
	}
	; -------------------------------------------------------------------------------------------------------------------
	; Next subItem
	; -------------------------------------------------------------------------------------------------------------------
	NextSubItem(K) {
		; Hotkeys: 0x8009 (Tab -> right), 0x8409 (Shift+Tab -> left), 0x8028  (Down -> down), 0x8026 (Up -> up)
		; Find the next subitem
		H:=This.HWND
		Item:=This.Item
		SubItem:=This.SubItem
		If (K = 0x8009) ; right
			SubItem++
		Else If (K = 0x8409) { ; left
			SubItem--
			If (SubItem = 0) && This.Skip0
				SubItem--
		}
		Else If (K = 0x8028) ; down
			Item++
		Else If (K = 0x8026) ; up
			Item--
		IF (K = 0x8409) || (K = 0x8009) { ; left || right
			If (This["Columns"]) {
				If (SubItem < This.Columns.MinIndex())
					SubItem:=This.Columns.MaxIndex(), Item--
				Else If (SubItem > This.Columns.MaxIndex())
					SubItem:=This.Columns.MinIndex(), Item++
				Else {
					While (This.Columns[SubItem] = "") {
						If (K = 0x8009) ; right
							SubItem++
						Else
							SubItem--
					}
				}
			}
		}
		If (SubItem > This.ColCount)
			Item++, SubItem:=This.Skip0 ? 1 : 0
		Else If (SubItem < 0)
			SubItem:=This.ColCount, Item--
		If (Item > This.RowCount)
			Item:=0
		Else If (Item < 0)
			Item:=This.RowCount
		If (Item <> This.Item)
			SendMessage, 0x1013, % Item, False, , % "ahk_id " . H ; LVM_ENSUREVISIBLE
		VarSetCapacity(RECT, 16, 0), NumPut(SubItem, RECT, 4, "Int")
		SendMessage, 0x1038, % Item, % &RECT, , % "ahk_id " . H ; LVM_GETSUBITEMRECT
		X:=NumGet(RECT, 0, "Int"), Y:=NumGet(RECT, 4, "Int")
		If (SubItem = 0) {
			SendMessage, 0x101D, 0, 0, , % "ahk_id " . H ; LVM_GETCOLUMNWIDTH
			W:=ErrorLevel
		}
		Else
			W:=NumGet(RECT, 8, "Int") - NumGet(RECT, 0, "Int")
		R:=This.LW - (This.DX * 2) - This.SW, S:=0
		If (X < 0)
			S:=X
		Else If ((X + W) > R)
			S:=X + W - R + This.DX
		If (S)
			SendMessage, 0x1014, % S, 0, , % "ahk_id " . H ; LVM_SCROLL
		Point:=(X - S + (This.DX * 2)) + ((Y + (This.DY * 2)) << 16)
		SendMessage, 0x0201, 0, % Point, , % "ahk_id " . H ; WM_LBUTTONDOWN
		SendMessage, 0x0202, 0, % Point, , % "ahk_id " . H ; WM_LBUTTONUP
		SendMessage, 0x0203, 0, % Point, , % "ahk_id " . H ; WM_LBUTTONDBLCLK
		SendMessage, 0x0202, 0, % Point, , % "ahk_id " . H ; WM_LBUTTONUP
	}
	; -------------------------------------------------------------------------------------------------------------------
	; Register/UnRegister hotkeys
	; -------------------------------------------------------------------------------------------------------------------
	RegisterHotkeys(Register = True) {
		; WM_HOTKEY:=0x0312, MOD_SHIFT:=0x0004
		; Hotkeys: 0x801B  (Esc -> cancel, 0x8009 (Tab -> right), 0x8409 (Shift+Tab -> left)
		;          0x8028  (Down -> down), 0x8026 (Up -> up)
		H:=This.HWND
		If (Register) { ; Register
			DllCall("RegisterHotKey", "Ptr", H, "Int", 0x801B, "UInt", 0, "UInt", 0x1B)
			, DllCall("RegisterHotKey", "Ptr", H, "Int", 0x8009, "UInt", 0, "UInt", 0x09)
			, DllCall("RegisterHotKey", "Ptr", H, "Int", 0x8409, "UInt", 4, "UInt", 0x09)
			, DllCall("RegisterHotKey", "Ptr", H, "Int", 0x8028, "UInt", 0, "UInt", 0x28)
			, DllCall("RegisterHotKey", "Ptr", H, "Int", 0x8026, "UInt", 0, "UInt", 0x26)
			, This.HotkeyFunc:=ObjBindMethod(This, "On_WM_HOTKEY")
			, OnMessage(0x0312, This.HotkeyFunc) ; WM_HOTKEY
		}
		Else { ; Unregister
			DllCall("UnregisterHotKey", "Ptr", H, "Int", 0x801B)
			, DllCall("UnregisterHotKey", "Ptr", H, "Int", 0x8009)
			, DllCall("UnregisterHotKey", "Ptr", H, "Int", 0x8409)
			, DllCall("UnregisterHotKey", "Ptr", H, "Int", 0x8028)
			, DllCall("UnregisterHotKey", "Ptr", H, "Int", 0x8026)
			, OnMessage(0x0312, This.HotkeyFunc, 0) ; WM_HOTKEY
			, This.HotkeyFunc:=""
		}
	}
}