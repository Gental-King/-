; Ciku_Manager函数
; pyfenci(str,pinyintype:="qp",switch:=False) pinyintype = "qp"(全拼)|"xh"(小鹤双拼); switch = True(转换成全拼格式)|False(不转换)
; pinyin2xiaohe(str) 	转换分词过的字符串成小鹤双拼  'hao'de' --> 'hc'de'
; hz2qp(str)			转换汉字字符成全拼   好的 --> 'hao'de'
; hz2wb86(str)			转换汉字字符成 wubi86
; Change History:		2019-08-16
;						2019-08-17	pyfenci通过添加双拼码表可以兼容其他双拼方案
;						2019-08-18	加入自然码、智能abc、微软双拼方案
;						2019-08-19	简拼SQL搜索语句生成函数jianpinsql
;						2019-08-20	修复hz2qp、hz2wb86可能卡住的bug
pyfenci(str,pinyintype:="qp",switch:=False,zidinyimabiao:=""){
static lastpy,ymb,ymmaxlen,lsmmd	; 记录上次分词类型，减少加载
static lsm:=["a","ai","an","ang","ao","e","ei","en","eng","er","o","ou"]	; 零声母
; 小鹤双拼键盘布局
static xhjm:= {"0":"1","ai":"d","an":"j","ang":"h","ao":"c","ch":"i","ei":"w","en":"f","eng":"g","er":"e","ia":"x","ian":"m","iang":"l","iao":"n","ie":"p","in":"b","ing":"k","iong":"s","iu":"q","ong":"s","ou":"z","sh":"u","ua":"x","uai":"k","uan":"r","uang":"l","ue":"t","ui":"v","un":"y","uo":"o","v":"v","ve":"t","zh":"v"}
; 自然码键盘布局
static zrmjm:={"0":"1","ai":"l","an":"j","ang":"h","ao":"k","ch":"i","ei":"z","en":"f","eng":"g","er":"e","ia":"w","ian":"m","iang":"d","iao":"c","ie":"x","in":"n","ing":"y","iong":"s","iu":"q","ong":"s","ou":"b","sh":"u","ua":"w","uai":"y","uan":"r","uang":"d","ue":"t","ui":"v","un":"p","uo":"o","v":"v","ve":"t","zh":"v"}
; 智能abc键盘布局
static abcjm:={"0":"o","ai":"l","an":"j","ang":"h","ao":"k","ch":"e","ei":"q","en":"f","eng":"g","er":"r","ia":"d","ian":"w","iang":"t","iao":"z","ie":"x","in":"c","ing":"y","iong":"s","iu":"r","ong":"s","ou":"b","sh":"v","ua":"d","uai":"c","uan":"p","uang":"t","ue":"m","ui":"m","un":"n","uo":"o","v":"v","ve":"v","zh":"a"}
; 微软双拼键盘布局
static wrjm:= {"0":"o","ai":"l","an":"j","ang":"h","ao":"k","ch":"i","ei":"z","en":"f","eng":"g","er":"e","ia":"w","ian":"m","iang":"d","iao":"c","ie":"x","in":"n","ing":";","iong":"s","iu":"q","ong":"s","ou":"b","sh":"u","ua":"w","uai":"y","uan":"e","uang":"d","ue":"t","ui":"v","un":"p","uo":"o","v":"y","ve":"v","zh":"v"}

	; If zidinyimabiao													; 自定义键盘布局
	; 	%pinyintype%jm:=zidinyimabiao
	If (lastpy != pinyintype){											; 加载键盘布局
		; 全拼声母韵母组合表
		quanpinbiao = 
		(
			{"b" :{"1":"b","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","ei":"ei","en":"en","eng":"eng","i":"i","ian":"ian","iao":"iao","ie":"ie","in":"in","ing":"ing","o":"o","u":"u"}
			,"a" :{"1":"a","ai":"i","an":"n","ang":"ng","ao":"o"}
			,"c" :{"1":"c","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","en":"en","eng":"eng","i":"i","ong":"ong","ou":"ou","u":"u","uan":"uan","ui":"ui","un":"un","uo":"uo"}
			,"ch":{"1":"ch","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","en":"en","eng":"eng","i":"i","ong":"ong","ou":"ou","u":"u","ua":"ua","uai":"uai","uan":"uan","uang":"uang","ui":"ui","un":"un","uo":"uo"}
			,"d" :{"1":"d","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","en":"en","ei":"ei","eng":"eng","i":"i","ia":"ia","ian":"ian","iao":"iao","ie":"ie","ing":"ing","iu":"iu","ong":"ong","ou":"ou","u":"u","uan":"uan","ui":"ui","un":"un","uo":"uo"}
			,"e" :{"1":"e","ei":"i","en":"n","eng":"ng","er":"r"}
			,"f" :{"1":"f","a":"a","an":"an","ang":"ang","ei":"ei","en":"en","eng":"eng","o":"o","ou":"ou","u":"u"}
			,"g" :{"1":"g","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","ei":"ei","en":"en","eng":"eng","ong":"ong","ou":"ou","u":"u","ua":"ua","uai":"uai","uan":"uan","uang":"uang","ui":"ui","un":"un","uo":"uo"}
			,"h" :{"1":"h","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","ei":"ei","en":"en","eng":"eng","ong":"ong","ou":"ou","u":"u","ua":"ua","uai":"uai","uan":"uan","uang":"uang","ui":"ui","un":"un","uo":"uo"}
			,"j" :{"1":"j","i":"i","ia":"ia","ian":"ian","iang":"iang","iao":"iao","ie":"ie","in":"in","ing":"ing","iong":"iong","iu":"iu","u":"u","uan":"uan","ue":"ue","un":"un"}
			,"k" :{"1":"k","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","en":"en","eng":"eng","ong":"ong","ou":"ou","u":"u","ua":"ua","uai":"uai","uan":"uan","uang":"uang","ui":"ui","un":"un","uo":"uo"}
			,"l" :{"1":"l","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","ei":"ei","eng":"eng","i":"i","ia":"ia","ian":"ian","iang":"iang","iao":"iao","ie":"ie","in":"in","ing":"ing","iu":"iu","ong":"ong","ou":"ou","u":"u","v":"v","uan":"uan","ue":"ue","ve":"ve","un":"un","uo":"uo"}
			,"m" :{"1":"m","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","ei":"ei","en":"en","eng":"eng","i":"i","ian":"ian","iao":"iao","ie":"ie","in":"in","ing":"ing","iu":"iu","o":"o","ou":"ou","u":"u"}
			,"n" :{"1":"n","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","ei":"ei","en":"en","eng":"eng","i":"i","ian":"ian","iang":"iang","iao":"iao","ie":"ie","in":"in","ing":"ing","iu":"iu","ong":"ong","ou":"ou","u":"u","v":"v","uan":"uan","ve":"ve","uo":"uo","un":"un"}
			,"o" :{"1":"o","ou":"u"}
			,"p" :{"1":"p","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","ei":"ei","en":"en","eng":"eng","i":"i","ian":"ian","iao":"iao","ie":"ie","in":"in","ing":"ing","o":"o","ou":"ou","u":"u"}
			,"q" :{"1":"q","i":"i","ia":"ia","ian":"ian","iang":"iang","iao":"iao","ie":"ie","in":"in","ing":"ing","iong":"iong","iu":"iu","u":"u","uan":"uan","ue":"ue","un":"un"}
			,"r" :{"1":"r","an":"an","ang":"ang","ao":"ao","e":"e","en":"en","eng":"eng","i":"i","ong":"ong","ou":"ou","u":"u","uan":"uan","ui":"ui","un":"un","uo":"uo"}
			,"s" :{"1":"s","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","en":"en","eng":"eng","i":"i","ong":"ong","ou":"ou","u":"u","uan":"uan","ui":"ui","un":"un","uo":"uo"}
			,"sh":{"1":"sh","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","ei":"ei","en":"en","eng":"eng","i":"i","ou":"ou","u":"u","ua":"ua","uai":"uai","uan":"uan","uang":"uang","ui":"ui","un":"un","uo":"uo"}
			,"t" :{"1":"t","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","eng":"eng","i":"i","ian":"ian","iao":"iao","ie":"ie","ing":"ing","ong":"ong","ou":"ou","u":"u","uan":"uan","ui":"ui","un":"un","uo":"uo"}
			,"w" :{"1":"w","a":"a","ai":"ai","an":"an","ang":"ang","ei":"ei","en":"en","eng":"eng","o":"o","u":"u"}
			,"x" :{"1":"x","i":"i","ia":"ia","ian":"ian","iang":"iang","iao":"iao","ie":"ie","in":"in","ing":"ing","iong":"iong","iu":"iu","u":"u","uan":"uan","ue":"ue","un":"un"}
			,"y" :{"1":"y","a":"a","an":"an","ang":"ang","ao":"ao","e":"e","i":"i","in":"in","ing":"ing","o":"o","ong":"ong","ou":"ou","u":"u","uan":"uan","ue":"ue","un":"un"}
			,"z" :{"1":"z","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","ei":"ei","en":"en","eng":"eng","i":"i","ong":"ong","ou":"ou","u":"u","uan":"uan","ui":"ui","un":"un","uo":"uo"}
			,"zh":{"1":"zh","a":"a","ai":"ai","an":"an","ang":"ang","ao":"ao","e":"e","ei":"ei","en":"en","eng":"eng","i":"i","ong":"ong","ou":"ou","u":"u","uan":"uan","ui":"ui","un":"un","uo":"uo","ua":"ua","uai":"uai","uang":"uang"}}
		)
		lastpy:=pinyintype
		If (pinyintype="qp"){
			ymmaxlen:=4
			ymb:=JSON.Load(quanpinbiao)
			For key,value In lsm
				If (StrLen(value)>1){
					ymb[t1:=SubStr(value, 1, 1)].Delete(value)
					ymb[t1][t2:=SubStr(value, 2)]:=t2
				}
		} Else {													; 替换成双拼声母韵母组合表
			ymmaxlen:=1
			shuangpinbiao:=quanpinbiao,lsmmd:=%pinyintype%jm["0"]	; 零声母模式
			For kk,vv In %pinyintype%jm
				If (kk != "0")
					shuangpinbiao:=RegExReplace(shuangpinbiao, "im)(*ANYCRLF)""(" kk ")"":", """" vv """:")
			If InStr("a|o|e|i|u|v|;", lsmmd)						; 零声母 固定零声母 删除a*、e*、o*默认布局
				For kk,vv In ["a","o","e"]
					shuangpinbiao:=RegExReplace(shuangpinbiao, ",""" vv """ :{""1"":""" vv """[^}]+}", "")
			ymb:=JSON.Load(shuangpinbiao)
			If (lsmmd != "2"){
				If InStr("a|o|e|i|u|v|;", lsmmd)
					ObjRawSet(ymb, lsmmd, {})						; 添加固定零声母子键
				For key,value In lsm
				{
					If InStr("a|o|e|i|u|v|;", lsmmd)||(StrLen(value)=2)
						ymb[t1:=SubStr(value, 1, 1)].Delete(%pinyintype%jm[value])
					If (lsmmd = "1")&&(StrLen(value)=2)				; 零声母 两个字母的韵母为全拼 如"ang"="h" ah-->ang an-->an ee-->e
						ymb[t1][t2:=SubStr(value, 2, 1)]:=t2
					Else If InStr("a|o|e|i|u|v|;", lsmmd)			; 零声母 固定零声母 如固定零声母o "ai"="d" od-->ai "ang"="h" oh-->ang oe-->e
						ymb[lsmmd][%pinyintype%jm[value]]:=value
				}
				If InStr("a|o|e|i|u|v|;", lsmmd)
					ymb[lsmmd]["a"]:="a",ymb[lsmmd]["o"]:="o",ymb[lsmmd]["e"]:="e"
			} Else {}												; 零声母 首字母+韵母所在键 如"ai"="d" ad-->ai "ang"="h" ah-->ang ee-->e
		}
	}
	
	index:=1,fc:="'",strlen:=StrLen(str)
	Loop
	{
		If ((tsm:=SubStr(str, index, 1)) != "'"){					; 声母
			index+=1
			If (pinyintype="qp"){
				If (InStr("csz", tsm)&&(SubStr(str, index, 1)="h"))
					index+=1,tsm .= "h"
				Else If (InStr("aeo", tsm)){
					SubStr(str, index-1, 2)
				}
			} Else If (lsmmd="1")||(lsmmd="2"){
				If (InStr("aoe", tsm)&&(SubStr(str, index, 1)=tsm)){
					index+=1,fc .= tsm (switch?"":tsm) "'"
					Continue
				}
			} Else If InStr("a|o|e|i|u|v|;", lsmmd){
				If (tsm=lsmmd){
					tym:=SubStr(str, index, 1)
					If (ymb[lsmmd][tym])
						index+=1,fc .= (switch?ymb[lsmmd][tym]:tsm tym) "'"
					Else
						fc .= tsm "'"
					Continue
				} Else If (!ymb[tsm]){
					fc .= tsm "'"
					Continue
				}
			}
			tym:="",tymlen:=0
			Loop													; 韵母
			{
				If (index+ymmaxlen-A_Index>strlen)
					Continue
				tym:=SubStr(str, index, tymlen:=ymmaxlen+1-A_Index)
				If (ymb[tsm][tym])
					Break
			} Until A_Index=ymmaxlen+1
			If (pinyintype="qp")&&ttym&&(!tym){						; 智能分词
				tym:=SubStr(ttym,1,-1)
				If (ymb[ttsm][tym])
				{
					tfc:=LTrim(pyfenci(SubStr(str,index-2)),"'")
					If (InStr(tfc, "'")>2)
						Return SubStr(fc,1,-2) "'" tfc
					Else
						tym:=""
				}
			}
			If (!switch)||(pinyintype = "qp")						; 转全拼显示
				ttym:=tym,ttsm:=tsm,fc .= tsm tym "'"
			Else
				ttym:=tym,ttsm:=tsm,fc .= (ymb[tsm][1]!=lsmmd?ymb[tsm][1]:"") ymb[tsm][tym] "'"
			index+=tymlen
		} Else
			index+=1
	} Until index>strlen
	Return fc
}

pinyin2xhsp(str){
	static spsm:={"ch":"i","sh":"u","zh":"v"}
	static spym:={"iu":"q","ei":"w","er":"e","uan":"r","ue":"t","ve":"t","un":"y","uo":"o","ie":"p","iong":"s","ong":"s","ai":"d","en":"f","eng":"g","ang":"h","an":"j","ing":"k","uai":"k","iang":"l","uang":"l","ou":"z","ia":"x","ua":"x","ao":"c","ui":"v","in":"b","iao":"n","ian":"m"}
	For sm,xh in spsm 												; 声母替换
		str:=RegExReplace(str, "im)(*ANYCRLF)'" sm "([a-z]+')", "'" xh "$1")
	For ym, xh in spym												; 韵母替换
		str:=RegExReplace(str, "im)(*ANYCRLF)('[a-z])" ym "'", "$1" xh "'")
	str:=RegExReplace(str, "im)(*ANYCRLF)'ang'", "'ah'")			; 零声母替换
	str:=RegExReplace(str, "im)(*ANYCRLF)'eng'", "'eg'")
	str:=RegExReplace(str, "im)(*ANYCRLF)'a'", "'aa'")
	str:=RegExReplace(str, "im)(*ANYCRLF)'o'", "'oo'")
	str:=RegExReplace(str, "im)(*ANYCRLF)'e'", "'ee'")
	Return str
}

hz2qp(str){															; 深蓝词库全拼生成cmd命令
	FileDelete, temp.txt
	FileAppend, %str%, temp.txt
	RunWait, lib\深蓝词库转换.exe -i:word temp.txt -o:self temp.txt "-f:123'=byyn" -ct:pinyin, , Hide
	FileRead, str, temp.txt
	FileDelete, temp.txt
	Return str
}

hz2wb86(str){														; 深蓝词库五笔86生成cmd命令
	FileDelete, temp.txt
	FileAppend, %str%, temp.txt
	RunWait, lib\深蓝词库转换.exe -i:word temp.txt -o:wb86 temp.txt, , Hide
	FileRead, str, temp.txt
	FileDelete, temp.txt
	Return str
}

jianpinsql(str){
    static pylen:={"a":[1,3],"b":[2,4],"c":[2,5],"d":[2,4],"e":[1,3],"f":[2,4],"g":[2,5],"h":[2,5],"i":[0,0],"j":[2,5],"k":[2,5],"l":[2,5],"m":[2,4],"n":[2,5],"o":[1,2],"p":[2,4],"q":[2,5],"r":[2,4],"s":[2,6],"t":[2,4],"u":[0,0],"v":[0,0],"w":[2,4],"x":[2,5],"y":[2,4],"z":[2,4],"ch":[3,6],"sh":[3,6],"zh":[3,6]}
    minlen:=0,maxlen:=0,index:=1,str:=Trim(str, "'"),strarr:=StrSplit(str, "'"),szm:=strarr[1]
    Loop % strarr.Length()
    {
        tsm:=strarr[A_Index]
        minlen+=pylen[tsm][1]
        maxlen+=pylen[tsm][2]
    }
    sql := "SELECT id,value FROM (SELECT * FROM pinyin WHERE key >= '" szm "'" (SubStr(szm, 0)="z"?"":" AND key < '" SubStr(szm, 1, -1) Chr(Ord(SubStr(szm, 0))+1) "'") " AND LENGTH(key)>=" minlen " AND LENGTH(key)<=" maxlen ") WHERE key REGEXP '^" RTrim(RegExReplace(str "'", "'", "[a-z]*''"),"'") "$' ORDER by weight DESC LIMIT 5"
    Return sql
}

jianpinsql2(str){
    str:=Trim(str, "'"),strarr:=StrSplit(str, "'"),szm:=strarr[1]
    sql := "SELECT id,value FROM (SELECT * FROM pinyin WHERE key >= '" szm "'" (SubStr(szm, 0)="z"?"":" AND key < '" SubStr(szm, 1, -1) Chr(Ord(SubStr(szm, 0))+1) "'") " AND LENGTH(value)=" strarr.Length() ") WHERE key REGEXP '^" RTrim(RegExReplace(str "'", "'", "[a-z]*''"),"'") "$' ORDER by weight DESC LIMIT 5"
	Return sql
}

/****************************************************************************************************************************
 * Lib: JSON.ahk
 *     JSON lib for AutoHotkey.
 * Version:
 *     v2.1.3 [updated 04/18/2016 (MM/DD/YYYY)]
 * License:
 *     WTFPL [http://wtfpl.net/]
 * Requirements:
 *     Latest version of AutoHotkey (v1.1+ or v2.0-a+)
 * Installation:
 *     Use #Include JSON.ahk or copy into a function library folder and then
 *     use #Include <JSON>
 * Links:
 *     GitHub:     - https://github.com/cocobelgica/AutoHotkey-JSON
 *     Forum Topic - http://goo.gl/r0zI8t
 *     Email:      - cocobelgica <at> gmail <dot> com
 */


/**
 * Class: JSON
 *     The JSON object contains methods for parsing JSON and converting values
 *     to JSON. Callable - NO; Instantiable - YES; Subclassable - YES;
 *     Nestable(via #Include) - NO.
 * Methods:
 *     Load() - see relevant documentation before method definition header
 *     Dump() - see relevant documentation before method definition header
 */
class JSON
{
	/**
	 * Method: Load
	 *     Parses a JSON string into an AHK value
	 * Syntax:
	 *     value := JSON.Load( text [, reviver ] )
	 * Parameter(s):
	 *     value      [retval] - parsed value
	 *     text    [in, ByRef] - JSON formatted string
	 *     reviver   [in, opt] - function object, similar to JavaScript's
	 *                           JSON.parse() 'reviver' parameter
	 */
	class Load extends JSON.Functor
	{
		Call(self, ByRef text, reviver:="")
		{
			this.rev := IsObject(reviver) ? reviver : false
		; Object keys(and array indices) are temporarily stored in arrays so that
		; we can enumerate them in the order they appear in the document/text instead
		; of alphabetically. Skip if no reviver function is specified.
			this.keys := this.rev ? {} : false

			static quot := Chr(34), bashq := "\" . quot
			     , json_value := quot . "{[01234567890-tfn"
			     , json_value_or_array_closing := quot . "{[]01234567890-tfn"
			     , object_key_or_object_closing := quot . "}"

			key := ""
			is_key := false
			root := {}
			stack := [root]
			next := json_value
			pos := 0

			while ((ch := SubStr(text, ++pos, 1)) != "") {
				if InStr(" `t`r`n", ch)
					continue
				if !InStr(next, ch, 1)
					this.ParseError(next, text, pos)

				holder := stack[1]
				is_array := holder.IsArray

				if InStr(",:", ch) {
					next := (is_key := !is_array && ch == ",") ? quot : json_value

				} else if InStr("}]", ch) {
					ObjRemoveAt(stack, 1)
					next := stack[1]==root ? "" : stack[1].IsArray ? ",]" : ",}"

				} else {
					if InStr("{[", ch) {
					; Check if Array() is overridden and if its return value has
					; the 'IsArray' property. If so, Array() will be called normally,
					; otherwise, use a custom base object for arrays
						static json_array := Func("Array").IsBuiltIn || ![].IsArray ? {IsArray: true} : 0
					
					; sacrifice readability for minor(actually negligible) performance gain
						(ch == "{")
							? ( is_key := true
							  , value := {}
							  , next := object_key_or_object_closing )
						; ch == "["
							: ( value := json_array ? new json_array : []
							  , next := json_value_or_array_closing )
						
						ObjInsertAt(stack, 1, value)

						if (this.keys)
							this.keys[value] := []
					
					} else {
						if (ch == quot) {
							i := pos
							while (i := InStr(text, quot,, i+1)) {
								value := StrReplace(SubStr(text, pos+1, i-pos-1), "\\", "\u005c")

								static tail := A_AhkVersion<"2" ? 0 : -1
								if (SubStr(value, tail) != "\")
									break
							}

							if (!i)
								this.ParseError("'", text, pos)

							  value := StrReplace(value,  "\/",  "/")
							, value := StrReplace(value, bashq, quot)
							, value := StrReplace(value,  "\b", "`b")
							, value := StrReplace(value,  "\f", "`f")
							, value := StrReplace(value,  "\n", "`n")
							, value := StrReplace(value,  "\r", "`r")
							, value := StrReplace(value,  "\t", "`t")

							pos := i ; update pos
							
							i := 0
							while (i := InStr(value, "\",, i+1)) {
								if !(SubStr(value, i+1, 1) == "u")
									this.ParseError("\", text, pos - StrLen(SubStr(value, i+1)))

								uffff := Abs("0x" . SubStr(value, i+2, 4))
								if (A_IsUnicode || uffff < 0x100)
									value := SubStr(value, 1, i-1) . Chr(uffff) . SubStr(value, i+6)
							}

							if (is_key) {
								key := value, next := ":"
								continue
							}
						
						} else {
							value := SubStr(text, pos, i := RegExMatch(text, "[\]\},\s]|$",, pos)-pos)

							static number := "number", integer :="integer"
							if value is %number%
							{
								if value is %integer%
									value += 0
							}
							else if (value == "true" || value == "false")
								value := %value% + 0
							else if (value == "null")
								value := ""
							else
							; we can do more here to pinpoint the actual culprit
							; but that's just too much extra work.
								this.ParseError(next, text, pos, i)

							pos += i-1
						}

						next := holder==root ? "" : is_array ? ",]" : ",}"
					} ; If InStr("{[", ch) { ... } else

					is_array? key := ObjPush(holder, value) : holder[key] := value

					if (this.keys && this.keys.HasKey(holder))
						this.keys[holder].Push(key)
				}
			
			} ; while ( ... )

			return this.rev ? this.Walk(root, "") : root[""]
		}

		ParseError(expect, ByRef text, pos, len:=1)
		{
			static quot := Chr(34), qurly := quot . "}"
			
			line := StrSplit(SubStr(text, 1, pos), "`n", "`r").Length()
			col := pos - InStr(text, "`n",, -(StrLen(text)-pos+1))
			msg := Format("{1}`n`nLine:`t{2}`nCol:`t{3}`nChar:`t{4}"
			,     (expect == "")     ? "Extra data"
			    : (expect == "'")    ? "Unterminated string starting at"
			    : (expect == "\")    ? "Invalid \escape"
			    : (expect == ":")    ? "Expecting ':' delimiter"
			    : (expect == quot)   ? "Expecting object key enclosed in double quotes"
			    : (expect == qurly)  ? "Expecting object key enclosed in double quotes or object closing '}'"
			    : (expect == ",}")   ? "Expecting ',' delimiter or object closing '}'"
			    : (expect == ",]")   ? "Expecting ',' delimiter or array closing ']'"
			    : InStr(expect, "]") ? "Expecting JSON value or array closing ']'"
			    :                      "Expecting JSON value(string, number, true, false, null, object or array)"
			, line, col, pos)

			static offset := A_AhkVersion<"2" ? -3 : -4
			throw Exception(msg, offset, SubStr(text, pos, len))
		}

		Walk(holder, key)
		{
			value := holder[key]
			if IsObject(value) {
				for i, k in this.keys[value] {
					; check if ObjHasKey(value, k) ??
					v := this.Walk(value, k)
					if (v != JSON.Undefined)
						value[k] := v
					else
						ObjDelete(value, k)
				}
			}
			
			return this.rev.Call(holder, key, value)
		}
	}

	/**
	 * Method: Dump
	 *     Converts an AHK value into a JSON string
	 * Syntax:
	 *     str := JSON.Dump( value [, replacer, space ] )
	 * Parameter(s):
	 *     str        [retval] - JSON representation of an AHK value
	 *     value          [in] - any value(object, string, number)
	 *     replacer  [in, opt] - function object, similar to JavaScript's
	 *                           JSON.stringify() 'replacer' parameter
	 *     space     [in, opt] - similar to JavaScript's JSON.stringify()
	 *                           'space' parameter
	 */
	class Dump extends JSON.Functor
	{
		Call(self, value, replacer:="", space:="")
		{
			this.rep := IsObject(replacer) ? replacer : ""

			this.gap := ""
			if (space) {
				static integer := "integer"
				if space is %integer%
					Loop, % ((n := Abs(space))>10 ? 10 : n)
						this.gap .= " "
				else
					this.gap := SubStr(space, 1, 10)

				this.indent := "`n"
			}

			return this.Str({"": value}, "")
		}

		Str(holder, key)
		{
			value := holder[key]

			if (this.rep)
				value := this.rep.Call(holder, key, ObjHasKey(holder, key) ? value : JSON.Undefined)

			if IsObject(value) {
			; Check object type, skip serialization for other object types such as
			; ComObject, Func, BoundFunc, FileObject, RegExMatchObject, Property, etc.
				static type := A_AhkVersion<"2" ? "" : Func("Type")
				if (type ? type.Call(value) == "Object" : ObjGetCapacity(value) != "") {
					if (this.gap) {
						stepback := this.indent
						this.indent .= this.gap
					}

					is_array := value.IsArray
				; Array() is not overridden, rollback to old method of
				; identifying array-like objects. Due to the use of a for-loop
				; sparse arrays such as '[1,,3]' are detected as objects({}). 
					if (!is_array) {
						for i in value
							is_array := i == A_Index
						until !is_array
					}

					str := ""
					if (is_array) {
						Loop, % value.Length() {
							if (this.gap)
								str .= this.indent
							
							v := this.Str(value, A_Index)
							str .= (v != "") ? v . "," : "null,"
						}
					} else {
						colon := this.gap ? ": " : ":"
						for k in value {
							v := this.Str(value, k)
							if (v != "") {
								if (this.gap)
									str .= this.indent

								str .= this.Quote(k) . colon . v . ","
							}
						}
					}

					if (str != "") {
						str := RTrim(str, ",")
						if (this.gap)
							str .= stepback
					}

					if (this.gap)
						this.indent := stepback

					return is_array ? "[" . str . "]" : "{" . str . "}"
				}
			
			} else ; is_number ? value : "value"
				return ObjGetCapacity([value], 1)=="" ? value : this.Quote(value)
		}

		Quote(string)
		{
			static quot := Chr(34), bashq := "\" . quot

			if (string != "") {
				  string := StrReplace(string,  "\",  "\\")
				; , string := StrReplace(string,  "/",  "\/") ; optional in ECMAScript
				, string := StrReplace(string, quot, bashq)
				, string := StrReplace(string, "`b",  "\b")
				, string := StrReplace(string, "`f",  "\f")
				, string := StrReplace(string, "`n",  "\n")
				, string := StrReplace(string, "`r",  "\r")
				, string := StrReplace(string, "`t",  "\t")

				static rx_escapable := A_AhkVersion<"2" ? "O)[^\x20-\x7e]" : "[^\x20-\x7e]"
				while RegExMatch(string, rx_escapable, m)
					string := StrReplace(string, m.Value, Format("\u{1:04x}", Ord(m.Value)))
			}

			return quot . string . quot
		}
	}

	/**
	 * Property: Undefined
	 *     Proxy for 'undefined' type
	 * Syntax:
	 *     undefined := JSON.Undefined
	 * Remarks:
	 *     For use with reviver and replacer functions since AutoHotkey does not
	 *     have an 'undefined' type. Returning blank("") or 0 won't work since these
	 *     can't be distnguished from actual JSON values. This leaves us with objects.
	 *     Replacer() - the caller may return a non-serializable AHK objects such as
	 *     ComObject, Func, BoundFunc, FileObject, RegExMatchObject, and Property to
	 *     mimic the behavior of returning 'undefined' in JavaScript but for the sake
	 *     of code readability and convenience, it's better to do 'return JSON.Undefined'.
	 *     Internally, the property returns a ComObject with the variant type of VT_EMPTY.
	 */
	Undefined[]
	{
		get {
			static empty := {}, vt_empty := ComObject(0, &empty, 1)
			return vt_empty
		}
	}

	class Functor
	{
		__Call(method, ByRef arg, args*)
		{
		; When casting to Call(), use a new instance of the "function object"
		; so as to avoid directly storing the properties(used across sub-methods)
		; into the "function object" itself.
			if IsObject(method)
				return (new this).Call(method, arg, args*)
			else if (method == "")
				return (new this).Call(arg, args*)
		}
	}
}