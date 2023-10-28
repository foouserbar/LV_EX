#Requires AutoHotkey v2.0
#Include <LV_EX\Sources\LV_EX>

mainGui := Gui("+Resize")
mainGui.Title := "LV_EX Groups Sample"

lv := mainGui.Add("ListView", "xm w500 r10 Grid", ["Col 1", "Col 2", "Col 3"])
HLV := lv.Hwnd

Loop 10 {
   Zeroes := SubStr("000", 1, 3 - StrLen(A_Index))
   lv.Add("", "A" . Zeroes . A_Index, "B" . Zeroes . A_Index, "C" . Zeroes . A_Index)
}
Loop lv.GetCount("Column")
   lv.ModifyCol(A_Index, "AutoHdr")
   
   
   
LV_EX_GroupInsert(HLV, 10, "Group 1")
LV_EX_GroupInsert(HLV, 20, "Group 2", 2, 9999)

Loop 5
   LV_EX_SetGroup(HLV, A_Index, 10)
Loop 5
   LV_EX_SetGroup(HLV, A_Index + 5, 20)
   
LV_EX_GroupSetState(HLV, 10, "Collapsible")
LV_EX_GroupSetState(HLV, 20, "Collapsible")

LV_EX_EnableGroupView(HLV)



cbgv := mainGui.Add("CheckBox", "Checked", "GroupView")
cbgv.OnEvent("Click", GroupView)

mainGui.Show()


MsgBox "GoupID 10 = " . LV_EX_HasGroup(HLV, 10), "HasGroup", 0
MsgBox "Row 2 = " . LV_EX_GetGroup(HLV, 2), "GetGroup", 0



GroupView(*) {
	LV_EX_EnableGroupView(HLV, cbgv.Value)
}


