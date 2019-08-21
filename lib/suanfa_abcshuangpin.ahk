;qu ci bing qie fen
srf_all_Input_for_trim:=pyfenci(srf_all_Input_for_trim,"abc",1)
srf_all_Input_for_trim:=substr(srf_all_Input_for_trim,2,StrLen(srf_all_Input_for_trim)-2)
srf_all_Input_tooltip:=srf_all_Input_for_trim
Needle := "'"
loop
{
	jichu_for_select:=[]
	loop_num+=1
	if(loop_num>1)
	{
		cutpos:=InStr(srf_all_Input_for_trim, Needle, false, -1, loop_num-1)-1
	}
	else
	{
		cutpos:=StrLen(srf_all_Input_for_trim)
	}
	if(cutpos>0)
	{
		srf_all_Input_trim:=SubStr(srf_all_Input_for_trim,1,cutpos)		
		srf_all_Input_trim_off:=SubStr(srf_all_Input_for_trim,cutpos+1)wo ai ni
	}
	else
	{
		break
	}
	jichu_for_select:=get_word(DB,srf_all_Input_trim,"pinyin")
	if(jichu_for_select[1]=="")
	{ ;未匹配到什么都不做，进入下一轮循环
		if(srf_all_Input_trim=="")
		{ ;如果截取字符串为空，退出循环
			field_Num+=1
			save_field_array[field_Num]:=jichu_for_select
			break
		}
	}
	else
	{ ;如果匹配到，将候选切分保存
		if(srf_all_Input_trim_off=="") ;InStr(srf_all_Input_for_trim, Needle, false, -1, loop_num+1)==0
		{ ;如果剩余字符串为空，退出循环
			field_Num+=1
			save_field_array[field_Num]:=jichu_for_select
			break
		}
		else ;否则，保存已匹配内容，继续匹配剩余字段，直到完全匹配
		{
			srf_all_Input_for_trim:=SubStr(srf_all_Input_trim_off,2)
			field_Num+=1
			loop_num:=0
			save_field[field_Num]:=srf_all_Input_trim
			save_field_array[field_Num]:=jichu_for_select
		}
	}
}

;zu he
jichu_for_select:=""
jichu_for_select_Array:=[]
ArrayCount:=0
if(field_Num==1)
{ ;一段
	jichu_for_select_Array:=save_field_array[1]
}
else
{ ;二段取首选组合
	jichu_for_select_Array:=[]
	jichu_for_select_temp:=""
	loop %field_Num%
	{
		jichu_for_select_temp.=save_field_array[A_Index,1]
		jichu_for_select_Array[1]:=jichu_for_select_temp
	}
}

;联想

jichu_for_select_lianxiang:=[]
if(lm_xl)
{
	jichu_for_select_lianxiang:=get_word_lianxiang(DB,srf_all_Input_tooltip,"pinyin")
}
if(jichu_for_select_lianxiang[1]=="" )
{
}
else
{
	
	jichu_Array_num:=jichu_for_select_Array.MaxIndex()
	if(jichu_Array_num=="")
	{
		jichu_Array_num:=0
		loop,% jichu_for_select_lianxiang.MaxIndex()
		{
			jichu_for_select_Array[A_Index+jichu_Array_num]:=jichu_for_select_lianxiang[A_Index]
		}
	}
	else
	{
		loop,% jichu_for_select_lianxiang.MaxIndex()
		{
			jichu_for_select_Array[A_Index+jichu_Array_num]:=jichu_for_select_lianxiang[A_Index]
		}
	}
}

;去重

jichu_for_select_Array1:=[]
array1:=0
loop,% jichu_for_select_Array.MaxIndex()
{
	is_fu_bnji:=0
	wd_cg_uumu:=A_Index
	loop,% wd_cg_uumu-1
	{
		if(jichu_for_select_Array[wd_cg_uumu]==jichu_for_select_Array[A_Index])or (jichu_for_select_Array[wd_cg_uumu]=="")
		{
			is_fu_bnji:=1
			break
		}
	}
	if(is_fu_bnji)
	{
	}
	else
	{
		array1+=1
		jichu_for_select_Array1[array1]:=jichu_for_select_Array[wd_cg_uumu]
	}
}
jichu_for_select_Array:=[]
jichu_for_select_Array:=jichu_for_select_Array1
jichu_for_select_Array1:=[]

;限制输出长度

jichu_for_select_string:=""
for index,element in jichu_for_select_Array
{
	if(element==jichu_for_select_lianxiang)
	{
		jichu_for_select_lianxiang:=""
	}
	if(A_Index<=10*waitnum)
	{

	}
	else if(A_Index>10*waitnum)and(A_Index<=10*(waitnum+1) )
	{
		jichu_for_select_string.=A_Space . index . ". " . element
	}
	else if(A_Index>10*(waitnum+1) )
	{
		break
	}
}

; re zi fu he gong neng

if(zi_fu_ir)
{
	hotstring_for_select :=get_word_lianxiang(DB,srf_all_Input,"hotstrings")
}
if(yy_xk)
{
	Function_for_select:=get_word_lianxiang(DB,srf_all_Input,"functions")
}
if(hotstring_for_select[1]=="")and (Function_for_select[1,1]=="")
{
	srf_for_select= > %jichu_for_select_string%
}
else if(hotstring_for_select[1]=="")and ( Function_for_select[1,1]!="")
{
	Function_for_select_show:=Function_for_select[1,2]
	srf_for_select= > %jichu_for_select_string%`n>(命)%Function_for_select_show%
}
else if(hotstring_for_select[1]!="") and  (Function_for_select[1,1]=="")
{
	if(StrLen(hotstring_for_select[1])>20)
	{
		hotstring_for_select_show:=SubStr(hotstring_for_select[1],1,20) . "……"
	}
	else
	{
		hotstring_for_select_show:=hotstring_for_select[1]
	}
	srf_for_select= > %jichu_for_select_string%`n>(串)%hotstring_for_select_show%
}
else
{
	if(StrLen(hotstring_for_select[1])>20)
	{
		hotstring_for_select_show:=SubStr(hotstring_for_select[1],1,20) . "……"
	}
	else
	{
		hotstring_for_select_show:=hotstring_for_select[1]
	}
	Function_for_select_show:=Function_for_select[1,2]
	srf_for_select= > %jichu_for_select_string%`n>(串)%hotstring_for_select_show%`n>(命)%Function_for_select_show%
}
Thisfengefu:=SubStr(fengefu,1,StrLen(jichu_for_select_string)*1.5)
if (srf_for_select!="")
{
	ToolTip, %srf_all_Input%      [ %srf_all_Input_tooltip% ] `n%Thisfengefu%`n%srf_for_select%, A_CaretX + 10 , A_CaretY + 20, 16
	srf_for_select:= Trim(srf_for_select, "`n")
	StringSplit,srf_for_select_array, srf_for_select,`n,>
}
else
{
	ToolTip, %srf_all_Input_tooltip%, A_CaretX + 10 , A_CaretY + 20, 16
}