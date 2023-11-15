﻿A_IsUnicode := 1
; ======================================================================================================================
; Namespace:      LV_EX
; Function:       Some additional functions to use with AHK ListView controls.
; Tested with:    AHK 2.0.10 (A32/U32/U64)
; Tested on:      Win 10 (x64)
; Changelog:
;     1.1.01.00/2016-04-28(just me     -  added LV_EX_GroupGetState contributed by Pulover.
;     1.1.00.00/2015-03-13/just me     -  added basic tile view support (suggested by toralf),
;                                         added basic (XP compatible) group view support,
;                                         revised code and made some minor changes.
;     1.0.00.00/2013-12-30/just me     -  initial release.
; Notes:
;     In terms of Microsoft
;        Item     stands for the whole row or the first column of the row
;        SubItem  stands for the second to last column of a row
;     All functions require the handle of the ListView (HWND). You get this handle using the 'Hwnd' option when
;     creating the control per 'Gui, Add, HwndHwndOfLV ...' or using 'GuiControlGet, HwndOfLV, Hwnd, MyListViewVar'
;     after control creation.
; Credits:
;     LV_EX tile view functions:
;        Initial idea by segalion (old forum: /board/topic/80754-listview-with-multiline-in-report-mode-help/)
;        based on code from Fabio Lucarelli (http://users.skynet.be/oleole/ListView_Tiles.htm).
; ======================================================================================================================
; This software is provided 'as-is', without any express or implied warranty.
; In no event will the authors be held liable for any damages arising from the use of this software.
; ======================================================================================================================
; ======================================================================================================================
; LV_EX_CalcViewSize - Calculates the approximate width and height required to display a given number of items.
; ======================================================================================================================
LV_EX_CalcViewSize(HLV, Rows := 0) {
   ; LVM_APPROXIMATEVIEWRECT = 0x1040 -> http://msdn.microsoft.com/en-us/library/bb774883(v=vs.85).aspx
   res := SendMessage(0x1040, Rows - 1, 0, , "ahk_id " . HLV)
   Return {W: (res & 0xFFFF), H: (res >> 16) & 0xFFFF}
}
; ======================================================================================================================
; LV_EX_EnableGroupView - Enables or disables whether the items in a list-view control display as a group.
; ======================================================================================================================
LV_EX_EnableGroupView(HLV, Enable := True) {
   ; LVM_ENABLEGROUPVIEW = 0x109D -> msdn.microsoft.com/en-us/library/bb774900(v=vs.85).aspx
   res := SendMessage(0x109D, !!Enable, 0, , "ahk_id " . HLV)
   Return (res >> 31) ? 0 : 1
}
; ======================================================================================================================
; LV_EX_FindString - Searches the first column for an item containing the specified string.
; ======================================================================================================================
LV_EX_FindString(HLV, Str, Start := 0, Partial := False) {
	; LVM_FINDITEM -> http://msdn.microsoft.com/en-us/library/bb774903(v=vs.85).aspx
	Static LVM_FINDITEM := A_IsUnicode ? 0x1053 : 0x100D ; LVM_FINDITEMW : LVM_FINDITEMA
	Static LVFISize := 40
	LVFI := Buffer(LVFISize, 0)
	Flags := 0x0002 ; LVFI_STRING
	If (Partial)
		Flags |= 0x0008 ; LVFI_PARTIAL
	NumPut("UInt", Flags, LVFI)
	Numput("Ptr", StrPtr(Str), LVFI, A_PtrSize)
	res := SendMessage(LVM_FINDITEM, Start - 1, LVFI, , "ahk_id " . HLV)
	Return (res > 0x7FFFFFFF ? 0 : res + 1)
}
; ======================================================================================================================
; LV_EX_FindStringEx - Searches all columns or the specified column for a subitem containing the specified string.
; ======================================================================================================================
LV_EX_FindStringEx(HLV, Str, Column := 0, Start := 0, Partial := False) {
	Len := StrLen(Str)
	Row := Col := 0
	ItemList := ListViewGetContent( , HLV)
	Loop Parse ItemList, "`n" {
		If (A_Index > Start) {
			Row := A_Index
		 
			Columns := StrSplit(A_LoopField, "`t")
			If (Column + 0) > 0 {
				If (Partial) {
					If (SubStr(Columns[Column], 1, Len) = Str)
						Col := Column
				} Else {
					If (Columns[Column] = Str)
						Col := Column
				}
			} Else {
				For Index, ColumnText In Columns {
					If (Partial) {
						If (SubStr(ColumnText, 1, Len) = Str)
							Col := Index
					} Else {
						If (ColumnText = Str)
						Col := Index
					}
				} Until (Col > 0)
			}
		}
	} Until (Col > 0)
	Return (Col > 0) ? {Row: Row, Col: Col} : 0
}
; ======================================================================================================================
; LV_EX_GetColumnOrder - Gets the current left-to-right order of columns in a list-view control.
; ======================================================================================================================
LV_EX_GetColumnOrder(HLV) {
   ; LVM_GETCOLUMNORDERARRAY = 0x103B -> http://msdn.microsoft.com/en-us/library/bb774913(v=vs.85).aspx
   Cols := SendMessage(0x1200, 0, 0, , "ahk_id " . LV_EX_GetHeader(HLV)) ; HDM_GETITEMCOUNT
   If (Cols > 0x7FFFFFFF)
      Return False
   COA := Buffer(Cols * 4, 0)
   res := SendMessage(0x103B, Cols, COA, , "ahk_id " . HLV)
   If (res = 0) || !(res + 0)
      Return False
   ColArray := []
   Loop Cols
      ColArray.Push(NumGet(COA, 4 * (A_Index - 1), "Int") + 1)
   Return ColArray
}
; ======================================================================================================================
; LV_EX_GetColumnWidth - Gets the width of a column in report or list view.
; ======================================================================================================================
LV_EX_GetColumnWidth(HLV, Column) {
   ; LVM_GETCOLUMNWIDTH = 0x101D -> http://msdn.microsoft.com/en-us/library/bb774915(v=vs.85).aspx
   Return SendMessage(0x101D, Column - 1, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_GetExtendedStyle - Gets the extended styles that are currently in use for a given list-view control.
; ======================================================================================================================
LV_EX_GetExtendedStyle(HLV) {
   ; LVM_GETEXTENDEDLISTVIEWSTYLE = 0x1037 -> http://msdn.microsoft.com/en-us/library/bb774923(v=vs.85).aspx
   Return SendMessage(0x1037, 0, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_GetGroup - Gets the ID of the group the list-view item belongs to.
; ======================================================================================================================
LV_EX_GetGroup(HLV, Row) {
   ; LVM_GETITEMA = 0x1005 -> http://msdn.microsoft.com/en-us/library/bb774953(v=vs.85).aspx
   Static OffGroupID := 28 + (A_PtrSize * 3)
   LV_EX_LVITEM(&LVITEM, 0x00000100, Row) ; LVIF_GROUPID
   SendMessage(0x1005, 0, LVITEM, , "ahk_id " . HLV)
   Return NumGet(LVITEM, OffGroupID, "UPtr")
}
; ======================================================================================================================
; LV_EX_GetHeader - Retrieves the handle of the header control used by the list-view control.
; ======================================================================================================================
LV_EX_GetHeader(HLV) {
   ; LVM_GETHEADER = 0x101F -> http://msdn.microsoft.com/en-us/library/bb774937(v=vs.85).aspx
   Return SendMessage(0x101F, 0, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_GetIconSpacing - Determines the spacing between icons in the icon view.
; ======================================================================================================================
LV_EX_GetIconSpacing(HLV, &CX, &CY) {
   ; LVM_GETITEMSPACING = 0x1033 -> http://msdn.microsoft.com/en-us/library/bb761051(v=vs.85).aspx
   CX := CY := 0
   res := SendMessage(0x1033, 0, 0, , "ahk_id " . HLV)
   CX := res & 0xFFFF, CY := res >> 16
   Return res
}
; ======================================================================================================================
; LV_EX_GetItemParam - Retrieves the value of the item's lParam field.
; ======================================================================================================================
LV_EX_GetItemParam(HLV, Row) {
   ; LVM_GETITEM -> http://msdn.microsoft.com/en-us/library/bb774953(v=vs.85).aspx
   Static LVM_GETITEM := A_IsUnicode ? 0x104B : 0x1005 ; LVM_GETITEMW : LVM_GETITEMA
   Static OffParam := 24 + (A_PtrSize * 2)
   LV_EX_LVITEM(&LVITEM, 0x00000004, Row) ; LVIF_PARAM
   SendMessage(LVM_GETITEM, 0, LVITEM, , "ahk_id " . HLV)
   Return NumGet(LVITEM, OffParam, "UPtr")
}
; ======================================================================================================================
; LV_EX_GetItemRect - Retrieves the bounding rectangle for all or part of an item in the current view.
; ======================================================================================================================
LV_EX_GetItemRect(HLV, Row := 1, LVIR := 0, &RECT := "") {
   ; LVM_GETITEMRECT = 0x100E -> http://msdn.microsoft.com/en-us/library/bb761049(v=vs.85).aspx
   RECT := Buffer(16, 0)
   NumPut("Int", LVIR, RECT, 0)
   res := SendMessage(0x100E, Row - 1, RECT, , "ahk_id " . HLV)
   If (res = 0)
      Return False
   Result := {}
   Result.X := NumGet(RECT,  0, "Int")
   Result.Y := NumGet(RECT,  4, "Int")
   Result.R := NumGet(RECT,  8, "Int")
   Result.B := NumGet(RECT, 12, "Int")
   Result.W := Result.R - Result.X
   Result.H := Result.B - Result.Y
   Return Result
}
; ======================================================================================================================
; LV_EX_GetItemState - Retrieves the state of a list-view item.
; ======================================================================================================================
LV_EX_GetItemState(HLV, Row) {
   ; LVM_GETITEMSTATE = 0x102C -> http://msdn.microsoft.com/en-us/library/bb761053(v=vs.85).aspx
   Static LVIS := {Cut: 0x04, DropHilited: 0x08, Focused: 0x01, Selected: 0x02, Checked: 0x2000}
   States := SendMessage(0x102C, Row - 1, 0xFFFF, , "ahk_id " . HLV) ; all states
   Result := {}
   For Key, Value In LVIS.OwnProps()
      Result.%Key% := States & Value
   Return Result
}
; ======================================================================================================================
; LV_EX_GetRowHeight - Gets the height of the specified row.
; ======================================================================================================================
LV_EX_GetRowHeight(HLV, Row := 1) {
   Return LV_EX_GetItemRect(HLV, Row).H
}
; ======================================================================================================================
; LV_EX_GetRowsPerPage - Calculates the number of items that can fit vertically in the visible area of a list-view
;                        control when in list or report view. Only fully visible items are counted.
; ======================================================================================================================
LV_EX_GetRowsPerPage(HLV) {
   ; LVM_GETCOUNTPERPAGE = 0x1028 -> http://msdn.microsoft.com/en-us/library/bb774917(v=vs.85).aspx
   Return SendMessage(0x1028, 0, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_GetSubItemRect - Retrieves information about the bounding rectangle for a subitem in a list-view control.
; ======================================================================================================================
LV_EX_GetSubItemRect(HLV, Column, Row := 1, LVIR := 0, &RECT := "") {
   ; LVM_GETSUBITEMRECT = 0x1038 -> http://msdn.microsoft.com/en-us/library/bb761075(v=vs.85).aspx
   RECT := Buffer(16, 0)
   NumPut("Int", LVIR, RECT, 0)
   NumPut("Int", Column - 1, RECT, 4)
   res := SendMessage(0x1038, Row - 1, RECT, , "ahk_id " . HLV)
   If (res = 0)
      Return False
   If (Column = 1) && ((LVIR = 0) || (LVIR = 3))
      NumPut("Int", NumGet(RECT, 0, "Int") + LV_EX_GetColumnWidth(HLV, 1), RECT, 8)
   Result := {}
   Result.X := NumGet(RECT,  0, "Int"), Result.Y := NumGet(RECT,  4, "Int")
   Result.R := NumGet(RECT,  8, "Int"), Result.B := NumGet(RECT, 12, "Int")
   Result.W := Result.R - Result.X,     Result.H := Result.B - Result.Y
   Return Result
}
; ======================================================================================================================
; LV_EX_GetSubItemText - Retrieves the text of the specified item and subitem.
; ======================================================================================================================
LV_EX_GetSubItemText(HLV, Row, Column := 1, MaxChars := 257) {
   ; LVM_GETITEMTEXT -> http://msdn.microsoft.com/en-us/library/bb761055(v=vs.85).aspx
   Static LVM_GETITEMTEXT := A_IsUnicode ? 0x1073 : 0x102D ; LVM_GETITEMTEXTW : LVM_GETITEMTEXTA
   Static Encoding := A_IsUnicode ? "UTF-16" : "CP0"
   Static OffText := 16 + A_PtrSize
   Static OffTextMax := OffText + A_PtrSize
   ItemText := Buffer(MaxChars << !!A_IsUnicode, 0)
   LV_EX_LVITEM(&LVITEM, , Row, Column)
   NumPut("Ptr", ItemText.Ptr, LVITEM, OffText)
   NumPut("Int", MaxChars, LVITEM, OffTextMax)
   SendMessage(LVM_GETITEMTEXT, Row - 1, LVITEM, , "ahk_id " . HLV)
   Return StrGet(ItemText, encoding)
}
; ======================================================================================================================
; LV_EX_GetTileViewLines - Retrieves the maximum number of additional text lines in each tile, not counting the title.
; ======================================================================================================================
LV_EX_GetTileViewLines(HLV) {
   ; LVM_GETTILEVIEWINFO = 0x10A3 -> http://msdn.microsoft.com/en-us/library/bb774768(v=vs.85).aspx
   Static SizeLVTVI := 40
   Static OffLines := 20
   LVTVI := Buffer(SizeLVTVI, 0)   ; LVTILEVIEWINFO
   NumPut("UInt", SizeLVTVI, LVTVI, 0)   ; cbSize
   NumPut("UInt", 0x00000002, LVTVI, 4)  ; dwMask = LVTVIM_COLUMNS
   SendMessage(0x10A3, 0, LVTVI, , "ahk_id " . HLV) ; LVM_GETTILEVIEWINFO
   Lines := NumGet(LVTVI, OffLines, "Int")
   Return (Lines > 0 ? --Lines : 0)
}
; ======================================================================================================================
; LV_EX_GetTopIndex - Retrieves the index of the topmost visible item when in list or report view.
; ======================================================================================================================
LV_EX_GetTopIndex(HLV) {
   ; LVM_GETTOPINDEX = 0x1027 -> http://msdn.microsoft.com/en-us/library/bb761087(v=vs.85).aspx
   res := SendMessage(0x1027, 0, 0, , "ahk_id " . HLV)
   Return (res + 1)
}
; ======================================================================================================================
; LV_EX_GetView - Retrieves the current view of a list-view control.
; ======================================================================================================================
LV_EX_GetView(HLV) {
   ; LVM_GETVIEW = 0x108F -> http://msdn.microsoft.com/en-us/library/bb761091(v=vs.85).aspx
   Static Views := {0: "Icon", 1: "Report", 2: "IconSmall", 3: "List", 4: "Tile"}
   res := SendMessage(0x108F, 0, 0, , "ahk_id " . HLV)
   Return Views.%res%
}
; ======================================================================================================================
; LV_EX_GroupGetHeader - Gets the header text of a group by group ID
; ======================================================================================================================
LV_EX_GroupGetHeader(HLV, GroupID, MaxChars := 1024) {
   ; LVM_GETGROUPINFO = 0x1095
   Static SizeOfLVGROUP := (4 * 6) + (A_PtrSize * 4)
   Static LVGF_HEADER := 0x00000001
   Static OffHeader := 8
   Static OffHeaderMax := 8 + A_PtrSize
   HeaderText := Buffer(MaxChars * 2, 0)
   LVGROUP := Buffer(SizeOfLVGROUP, 0)
   NumPut("UInt", SizeOfLVGROUP, LVGROUP, 0)
   NumPut("UInt", LVGF_HEADER, LVGROUP, 4)
   NumPut("Ptr", HeaderText.Ptr, LVGROUP, OffHeader)
   NumPut("Int", MaxChars, LVGROUP, OffHeaderMax)
   SendMessage(0x1095, GroupID, LVGROUP, , "ahk_id " . HLV)
   Return StrGet(HeaderText, MaxChars, "UTF-16")
}
; ======================================================================================================================
; LV_EX_GroupGetState - Get group states (requires Win Vista+ for most states).
; ======================================================================================================================
LV_EX_GroupGetState(HLV, GroupID, &Collapsed := "", &Collapsible := "", &Focused := "", &Hidden := ""
                  , &NoHeader := "", &Normal := "", &Selected := "") {
   ; LVM_GETGROUPINFO = 0x1095 -> msdn.microsoft.com/en-us/library/bb774932(v=vs.85).aspx
   Static OS := DllCall("GetVersion", "UChar")
   Static LVGS5 := {Collapsed: 0x01, Hidden: 0x02, Normal: 0x00}
   Static LVGS6 := {Collapsed: 0x01, Collapsible: 0x08, Focused: 0x10, Hidden: 0x02, NoHeader: 0x04, Normal: 0x00, Selected: 0x20}
   Static LVGF := 0x04 ; LVGF_STATE
   Static SizeOfLVGROUP := (4 * 6) + (A_PtrSize * 4)
   Static OffStateMask := 8 + (A_PtrSize * 3) + 8
   Static OffState := OffStateMask + 4
   SetStates := 0
   LVGS := OS > 5 ? LVGS6 : LVGS5
   For Each, State In LVGS.OwnProps()
      SetStates |= State
   LVGROUP := Buffer(SizeOfLVGROUP, 0)
   NumPut("UInt", SizeOfLVGROUP, LVGROUP, 0)
   NumPut("UInt", LVGF, LVGROUP, 4)
   NumPut("UInt", SetStates, LVGROUP, OffStateMask)
   res := SendMessage(0x1095, GroupID, LVGROUP, , "ahk_id " . HLV)
   States := NumGet(LVGROUP, OffState, "UInt")
   
   For Each, State in LVGS.OwnProps()
      %Each% := States & State ? True : False
   Return res
}
; ======================================================================================================================
; LV_EX_GroupInsert - Inserts a group into a list-view control.
; ======================================================================================================================
LV_EX_GroupInsert(HLV, GroupID, Header, Align := "", Index := -1) {
   ; LVM_INSERTGROUP = 0x1091 -> msdn.microsoft.com/en-us/library/bb761103(v=vs.85).aspx
   Static Alignment := {1: 1, 2: 2, 4: 4, C: 2, L: 1, R: 4}
   Static SizeOfLVGROUP := (4 * 6) + (A_PtrSize * 4)
   Static OffHeader := 8
   Static OffGroupID := OffHeader + (A_PtrSize * 3) + 4
   Static OffAlign := OffGroupID + 12
   Static LVGF := 0x11 ; LVGF_GROUPID | LVGF_HEADER | LVGF_STATE
   Static LVGF_ALIGN := 0x00000008
   Align := Alignment.HasOwnProp(SubStr(Align, 1, 1)) ? Alignment.%SubStr(Align, 1, 1)% : 0
   ; Align := (A := Alignment[SubStr(Align, 1, 1)]) ? A : 0
   Mask := LVGF | (Align ? LVGF_ALIGN : 0)
   PHeader := A_IsUnicode ? StrPtr(Header) : LV_EX_PWSTR(Header, &WHeader)
   ; VarSetCapacity(LVGROUP, SizeOfLVGROUP, 0)
   LVGROUP := Buffer(SizeOfLVGROUP, 0)
   NumPut("UInt", SizeOfLVGROUP, LVGROUP)
   NumPut("UInt", Mask, LVGROUP, 4)
   NumPut("Ptr", PHeader, LVGROUP, OffHeader)
   NumPut("Int", GroupID, LVGROUP, OffGroupID)
   NumPut("UInt", Align, LVGROUP, OffAlign)
   Return SendMessage(0x1091, Index, LVGROUP, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_GroupRemove - Removes a group from a list-view control.
; ======================================================================================================================
LV_EX_GroupRemove(HLV, GroupID) {
   ; LVM_REMOVEGROUP = 0x1096 -> msdn.microsoft.com/en-us/library/bb761149(v=vs.85).aspx
   Return SendMessage(0x10A0, GroupID, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_GroupRemoveAll - Removes all groups from a list-view control.
; ======================================================================================================================
LV_EX_GroupRemoveAll(HLV) {
   ; LVM_REMOVEALLGROUPS = 0x10A0 -> msdn.microsoft.com/en-us/library/bb761147(v=vs.85).aspx
   Return SendMessage(0x10A0, 0, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_GroupSetState - Set group state (requires Win Vista+ for most states).
; ======================================================================================================================
LV_EX_GroupSetState(HLV, GroupID, States*) {
   ; LVM_SETGROUPINFO = 0x1093 -> msdn.microsoft.com/en-us/library/bb761167(v=vs.85).aspx
   Static OS := DllCall("GetVersion", "UChar")
   Static LVGS5 := {Collapsed: 0x01, Hidden: 0x02, Normal: 0x00, 0: 0, 1: 1, 2: 2}
   Static LVGS6 := {Collapsed: 0x01, Collapsible: 0x08, Focused: 0x10, Hidden: 0x02, NoHeader: 0x04, Normal: 0x00
                 , Selected: 0x20, 0: 0, 1: 1, 2: 2, 4: 4, 8: 8, 16: 16, 32: 32}
   Static LVGF := 0x04 ; LVGF_STATE
   Static SizeOfLVGROUP := (4 * 6) + (A_PtrSize * 4)
   Static OffStateMask := 8 + (A_PtrSize * 3) + 8
   Static OffState := OffStateMask + 4
   SetStates := 0
   LVGS := OS > 5 ? LVGS6 : LVGS5
   For Each, State In States {
      If !LVGS.HasOwnProp(State)
         Return False
      SetStates |= LVGS.%State%
   }
   LVGROUP := Buffer(SizeOfLVGROUP, 0)
   NumPut("UInt", SizeOfLVGROUP, LVGROUP, 0)
   NumPut("UInt", LVGF, LVGROUP, 4)
   NumPut("UInt", SetStates, LVGROUP, OffStateMask)
   NumPut("UInt", SetStates, LVGROUP, OffState)
   Return SendMessage(0x1093, GroupID, LVGROUP, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_HasGroup - Determines whether the list-view control has a specified group.
; ======================================================================================================================
LV_EX_HasGroup(HLV, GroupID) {
   ; LVM_HASGROUP = 0x10A1 -> msdn.microsoft.com/en-us/library/bb761097(v=vs.85).aspx
   Return SendMessage(0x10A1, GroupID, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_IsGroupViewEnabled - Checks whether the list-view control has group view enabled.
; ======================================================================================================================
LV_EX_IsGroupViewEnabled(HLV) {
   ; LVM_ISGROUPVIEWENABLED = 0x10AF -> msdn.microsoft.com/en-us/library/bb761133(v=vs.85).aspx
   Return SendMessage(0x10AF, 0, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_IsRowChecked - Indicates if a row in the list-view control is checked.
; ======================================================================================================================
LV_EX_IsRowChecked(HLV, Row) {
   Return LV_EX_GetItemState(HLV, Row).Checked
}
; ======================================================================================================================
; LV_EX_IsRowFocused - Indicates if a row in the list-view control is focused.
; ======================================================================================================================
LV_EX_IsRowFocused(HLV, Row) {
   Return LV_EX_GetItemState(HLV, Row).Focused
}
; ======================================================================================================================
; LV_EX_IsRowSelected - Indicates if a row in the list-view control is selected.
; ======================================================================================================================
LV_EX_IsRowSelected(HLV, Row) {
   Return LV_EX_GetItemState(HLV, Row).Selected
}
; ======================================================================================================================
; LV_EX_IsRowVisible - Indicates if a row in the list-view control is visible.
; ======================================================================================================================
LV_EX_IsRowVisible(HLV, Row) {
   ; LVM_ISITEMVISIBLE = 0x10B6 -> http://msdn.microsoft.com/en-us/library/bb761135(v=vs.85).aspx
   Return SendMessage(0x10B6, Row - 1, 0, , "ahk_id " . HLV)
}
; ======================================================================================================================
; CommCtrl.h:
; // These next to methods make it easy to identify an item that can be repositioned
; // within listview. For example: Many developers use the lParam to store an identifier that is
; // unique. Unfortunatly, in order to find this item, they have to iterate through all of the items
; // in the listview. Listview will maintain a unique identifier.  The upper bound is the size of a DWORD.
; ======================================================================================================================
; LV_EX_MapIDToIndex - Maps the ID of an item to an index.
; ======================================================================================================================
LV_EX_MapIDToIndex(HLV, ID) {
   ; LVM_MAPIDTOINDEX = 0x10B5 -> http://msdn.microsoft.com/en-us/library/bb761137(v=vs.85).aspx
   res := SendMessage(0x10B5, ID, 0, , "ahk_id " . HLV)
   Return (res + 1)
}
; ======================================================================================================================
; LV_EX_MapIndexToID - Maps the index of an item to an unique ID.
; ======================================================================================================================
LV_EX_MapIndexToID(HLV, Index) {
   ; LVM_MAPINDEXTOID = 0x10B4 -> http://msdn.microsoft.com/en-us/library/bb761139(v=vs.85).aspx
   Return SendMessage(0x10B4, Index - 1, 0, , "ahk_id " . HLV)
}
; ================================================================================================================================
; LV_EX_MoveRow
; Moves a complete row within an own ListView control.
;     HLV            -  the handle to the ListView
;     RowNumber      -  the number of the row to be moved
;     InsertBefore   -  the number of the row to insert the moved row before
;     MaxTextLength  -  maximum length of item/subitem text being retrieved
; Returns the new row number of the moved row on success, otherwise zero (False).
; ================================================================================================================================
; SOURCE: https://www.autohotkey.com/boards/viewtopic.php?p=228092&sid=56ba922d89f48156db466a31b579c37a#p228092
LV_EX_MoveRow(lvCtrl, RowNumber, InsertBefore, MaxTextLength := 257) {
   Static LVM_GETITEM := A_IsUnicode ? 0x104B : 0x1005
   Static LVM_INSERTITEM := A_IsUnicode ? 0x104D : 0x1007
   Static LVM_SETITEM := A_IsUnicode ? 0x104C : 0x1006
   Static OffMask := 0
        , OffItem := OffMask + 4
        , OffSubItem := OffItem + 4
        , OffState := OffSubItem + 4
        , OffStateMask := OffState + 4
        , OffText := OffStateMask + A_PtrSize
        , OffTextLen := OffText + A_PtrSize
   HLV := lvCtrl.Hwnd
   ; Some checks -----------------------------------------------------------------------------------------------------------------
   If (RowNumber = InsertBefore)
      Return False
   Rows := DllCall("SendMessage", "Ptr", HLV, "UInt", 0x1004, "Ptr", 0, "Ptr", 0, "Int") ; LVM_GETITEMCOUNT
   If (RowNumber < 1) || (InsertBefore < 1) || (RowNumber > Rows)
      Return False
   ; Move it, if possible --------------------------------------------------------------------------------------------------------
   lvCtrl.Opt("-Redraw")
   HHD := DllCall("SendMessage", "Ptr", HLV, "UInt", 0x101F, "Ptr", 0, "Ptr", 0, "UPtr") ; LVM_GETHEADER
   Columns := DllCall("SendMessage", "Ptr", HHD, "UInt", 0x1200, "Ptr", 0, "Ptr", 0, "Int") ; HDM_GETITEMCOUNT
   Item := RowNumber - 1
   StructSize := 88 + (MaxTextLength << !!A_IsUnicode)
   LVITEM := Buffer(StructSize, 0)
   NumPut("UInt", 0x01031F, LVITEM, OffMask) ; might need to be adjusted for Win XP/Vista
   NumPut("Int", Item, LVITEM, OffItem)
   NumPut("UInt", -1, LVITEM, OffStateMask)
   NumPut("Ptr", LVITEM.Ptr + 88, LVITEM, OffText)
   NumPut("Int", MaxTextLength, LVITEM, OffTextLen)
   If !DllCall("SendMessage", "Ptr", HLV, "UInt", LVM_GETITEM, "Ptr", 0, "Ptr", LVITEM.Ptr, "Int")
      Return False
   NumPut("Int", InsertBefore - 1, LVITEM, OffItem)
   NewItem := DllCall("SendMessage", "Ptr", HLV, "UInt", LVM_INSERTITEM, "Ptr", 0, "Ptr", LVITEM.Ptr, "Int")
   If (NewItem = -1)
      Return False
   DllCall("SendMessage", "Ptr", HLV, "UInt", 0x102B, "Ptr", NewItem, "Ptr", LVITEM.Ptr) ; LVM_SETITEMSTATE
   If (InsertBefore <= RowNumber)
      Item++
   LVITEM := Buffer(StructSize, 0) ; reinitialize
   Loop Columns {
      NumPut("UInt", 0x03, LVITEM, OffMask)
      NumPut("Int", Item, LVITEM, OffItem)
      NumPut("Int", A_Index, LVITEM, OffSubItem)
      NumPut("Ptr", LVITEM.Ptr + 88, LVITEM, OffText)
      NumPut("Int", MaxTextLength, LVITEM, OffTextLen)
      If !DllCall("SendMessage", "Ptr", HLV, "UInt", LVM_GETITEM, "Ptr", 0, "Ptr", LVITEM.Ptr, "Int")
         Return False
      NumPut("Int", NewItem, LVITEM, OffItem)
      DllCall("SendMessage", "Ptr", HLV, "UInt", LVM_SETITEM, "Ptr", 0, "Ptr", LVITEM.Ptr, "Int")
   }
   Result := DllCall("SendMessage", "Ptr", HLV, "UInt", 0x1008, "Ptr", Item, "Ptr", 0) ; LVM_DELETEITEM
   lvCtrl.Opt("+Redraw")
   Return (Result ? (NewItem + 1) : 0)
}
; ======================================================================================================================
; LV_EX_RedrawRows - Forces a list-view control to redraw a range of items.
; ======================================================================================================================
LV_EX_RedrawRows(HLV, First := 0, Last := "") {
   ; LVM_REDRAWITEMS = 0x1015 -> http://msdn.microsoft.com/en-us/library/bb761145(v=vs.85).aspx
   If (First > 0) {
      If (Last = "")
         Last := First
   }
   Else {
      First := LV_EX_GetTopIndex(HLV)
      Last := First + LV_EX_GetRowsPerPage(HLV) - 1
   }
   res := SendMessage(0x1015, First - 1, Last - 1, , "ahk_id " . HLV)
   If (res)
      Return DllCall("User32.dll\UpdateWindow", "Ptr", HLV, "UInt")
   Return False
}
; ======================================================================================================================
; LV_EX_SetBkImage - Sets the background image in a list-view control.
; ======================================================================================================================
LV_EX_SetBkImage(HLV, ImgPath, Width := "", Height := "") {
   ; LVM_SETBKIMAGEA := 0x1044 -> http://msdn.microsoft.com/en-us/library/bb761155(v=vs.85).aspx
   Static XAlign := {C: 50, L: 0, R: 100}, YAlign := {B: 100, C: 50, T: 0}
   Static KnownCtrls := Map()
   Static OSVERSION := DllCall("Kernel32.dll\GetVersion", "UInt") & 0xFF
   HBITMAP := 0
   If ((ImgPath) && FileExist(ImgPath)) {
      If ((Width = "") && (Height = "")) {
         RECT := Buffer(16, 0)
         DllCall("User32.dll\GetClientRect", "Ptr", HLV, "Ptr", RECT)
         Width := NumGet(RECT, 8, "Int"), Height := NumGet(RECT, 12, "Int")
      }
      HMOD := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
      SI := Buffer(24, 0), NumPut("UInt", 1, SI)
      DllCall("Gdiplus.dll\GdiplusStartup", "UPtr*", &Token:=0, "Ptr", SI, "Ptr", 0)
	  DllCall("Gdiplus.dll\GdipCreateBitmapFromFile", "WStr", ImgPath, "PtrP", &Bitmap:=0)
      DllCall("Gdiplus.dll\GdipCreateHBITMAPFromBitmap", "Ptr", Bitmap, "UPtr*", &HBITMAP, "UInt", 0x00FFFFFF)
      DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", Bitmap)
      DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", Token)
      DllCall("Kernel32.dll\FreeLibrary", "Ptr", HMOD)
      HBITMAP := DllCall("User32.dll\CopyImage"
                       , "Ptr", HBITMAP, "UInt", 0, "Int", Width, "Int", Height, "UInt", 0x2008, "UPtr")
      If !(HBITMAP)
         Return False
   }
   ; Set extended style LVS_EX_DOUBLEBUFFER to avoid drawing issues
   If !KnownCtrls.Has(HLV) {
      LV_EX_SetExtendedStyle(HLV, 0x00010000, 0x00010000) ; LVS_EX_DOUBLEBUFFER = 0x00010000
      KnownCtrls[HLV] := True
   }
   Flags := 0x10000000 ; LVBKIF_TYPE_WATERMARK
   If ((HBITMAP) && (OSVERSION >= 6)) ; LVBKIF_FLAG_ALPHABLEND prevents that the image will be shown on WinXP
      Flags |= 0x20000000 ; LVBKIF_FLAG_ALPHABLEND
   LVBKIMAGESize :=  A_PtrSize = 8 ? 40 : 24
   LVBKIMAGE := Buffer(LVBKIMAGESize , 0)
   NumPut("UInt", Flags, LVBKIMAGE, 0)
   NumPut("UPtr", HBITMAP, LVBKIMAGE, A_PtrSize)
   Return SendMessage(0x1044, 0, LVBKIMAGE, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_SetColumnOrder - Sets the left-to-right order of columns in a list-view control.
; ======================================================================================================================
LV_EX_SetColumnOrder(HLV, ColArray) {
   ; LVM_SETCOLUMNORDERARRAY = 0x103A -> http://msdn.microsoft.com/en-us/library/bb761161(v=vs.85).aspx
   Cols := ColArray.Length
   COA := Buffer(Cols * 4, 0)
   For I, C In ColArray
      NumPut("Int", C - 1, COA, (I - 1) * 4)
   Return SendMessage(0x103A, Cols, COA, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_SetExtendedStyle - Sets extended styles in list-view controls.
; ======================================================================================================================
LV_EX_SetExtendedStyle(HLV, StyleMsk, Styles) {
   ; LVM_SETEXTENDEDLISTVIEWSTYLE = 0x1036 -> http://msdn.microsoft.com/en-us/library/bb761165(v=vs.85).aspx
   Return SendMessage(0x1036, StyleMsk, Styles, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_SetGroup - Assigns a list-view item to an existing group.
; ======================================================================================================================
LV_EX_SetGroup(HLV, Row, GroupID) {
   ; LVM_SETITEMA = 0x1006 -> http://msdn.microsoft.com/en-us/library/bb761186(v=vs.85).aspx
   Static OffGroupID := 28 + (A_PtrSize * 3)
   LV_EX_LVITEM(&LVITEM, 0x00000100, Row) ; LVIF_GROUPID
   NumPut("Uptr", GroupID, LVITEM, OffGroupID)
   Return SendMessage(0x1006, 0, LVITEM, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_SetIconSpacing - Sets the spacing between icons in the icon view.
; ======================================================================================================================
LV_EX_SetIconSpacing(HLV, CX, CY) {
   ; LVM_SETICONSPACING = 0x1035 -> http://msdn.microsoft.com/en-us/library/bb761176(v=vs.85).aspx
   If ((CX < 4) && (CX != -1))
      CX := 4
   If ((CY < 4) && (CY != -1))
      CY := 4
   Return SendMessage(0x1035, 0, (CX & 0xFFFF) | ((CY & 0xFFFF) << 16), , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_SetItemIndent - Sets the indent of the first column to the specified number of icon widths.
; ======================================================================================================================
LV_EX_SetItemIndent(HLV, Row, NumIcons) {
   ; LVM_SETITEMA = 0x1006 -> http://msdn.microsoft.com/en-us/library/bb761186(v=vs.85).aspx
   Static OffIndent := 24 + (A_PtrSize * 3)
   LV_EX_LVITEM(&LVITEM, 0x00000010, Row) ; LVIF_INDENT
   NumPut("Int", NumIcons, LVITEM, OffIndent)
   Return SendMessage(0x1006, 0, LVITEM, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_SetItemParam - Sets the lParam field of the item to the specified value.
; ======================================================================================================================
LV_EX_SetItemParam(HLV, Row, Value) {
   ; LVM_SETITEMA = 0x1006 -> http://msdn.microsoft.com/en-us/library/bb761186(v=vs.85).aspx
   Static OffParam := 24 + (A_PtrSize * 2)
   LV_EX_LVITEM(&LVITEM, 0x00000004, Row) ; LVIF_PARAM
   NumPut("UPtr", Value, LVITEM, OffParam)
   Return SendMessage(0x1006, 0, LVITEM, , "ahk_id " . HLV)
}

; ======================================================================================================================
; LV_EX_SetSubItemImage - Assigns an image from the list-view's image list to this subitem.
; ======================================================================================================================
LV_EX_SetSubItemImage(HLV, Row, Column, Index) {
   ; LVM_SETITEMA = 0x1006 -> http://msdn.microsoft.com/en-us/library/bb761186(v=vs.85).aspx
   Static KnownCtrls := Map()
   Static OffImage := 20 + (A_PtrSize * 2)
   If !KnownCtrls.Has(HLV) {
      LV_EX_SetExtendedStyle(HLV, 0x00000002, 0x00000002) ; LVS_EX_SUBITEMIMAGES = 0x00000002
      KnownCtrls[HLV] := True
   }
   LV_EX_LVITEM(&LVITEM, 0x00000002, Row, Column) ; LVIF_IMAGE
   NumPut("Int", Index - 1, LVITEM, OffImage)
   Return SendMessage(0x1006, 0, LVITEM, , "ahk_id " . HLV)
}
; ======================================================================================================================
; LV_EX_SetTileInfo - Sets the additional columns displayed for this tile, and the order of those columns.
; ======================================================================================================================
LV_EX_SetTileInfo(HLV, Row, Columns*) {
   ; Row      : The 1-based row number. If you specify a number less than 1, the tile info will be set for all rows.
   ; Colomns* : Array of column indices, specifying which columns are displayed for this item, and the order of those
   ;            columns. Indices should be greater than 1, because column 1, the item name, is already displayed.
   ; LVM_SETTILEINFO = 0x10A4 -> http://msdn.microsoft.com/en-us/library/bb761210(v=vs.85).aspx
   Static SizeLVTI := (4 * 2) + (A_PtrSize * 2)
   Static OffItem := 4
   Static OffCols := 8
   Static OffColArr := OffCols + A_PtrSize
   ColCount := Columns.Length
   Lines := LV_EX_GetTileViewLines(HLV)
   If (((Row = 0) && (ColCount != Lines)) || ((Row != 0) && (ColCount >= Lines)))
      LV_EX_SetTileViewLines(HLV, ColCount)
   ColArr := Buffer(4 * (ColCount + 1), 0)
   For I, Column In Columns
      NumPut("UInt", Column - 1, ColArr, 4 * (I - 1))
   LVTI := Buffer(SizeLVTI, 0)       ; LVTILEINFO
   NumPut("UInt", SizeLVTI, LVTI, 0)       ; cbSize
   NumPut("UInt", ColCount, LVTI, OffCols) ; cColumns
   NumPut("Ptr", ColArr.Ptr, LVTI, OffColArr) ; puColumns
   If (Row > 0) {
      NumPut("Int", Row - 1, LVTI, OffItem) ; iItem
      Return SendMessage(0x10A4, 0, LVTI, , "ahk_id " . HLV) ; LVM_SETTILEINFO
   }
   res := SendMessage(0x1004, 0, 0, , "ahk_id " . HLV) ; LVM_GETITEMCOUNT
   Loop res {
      NumPut("Int", A_Index - 1, LVTI, OffItem) ; iItem
      res2 := SendMessage(0x10A4, 0, LVTI, , "ahk_id " . HLV) ; LVM_SETTILEINFO
      If (!res2)
         Return res2
   }
   Return True
}
; ======================================================================================================================
; LV_EX_SetTileViewLines - Sets the maximum number of additional text lines in each tile, not counting the title.
; ======================================================================================================================
LV_EX_SetTileViewLines(HLV, Lines) {
   ; Lines : Maximum number of text lines in each item label, not counting the title.
   ; LVM_GETTILEVIEWINFO = 0x10A3 -> http://msdn.microsoft.com/en-us/library/bb761083(v=vs.85).aspx
   ; LVM_SETTILEVIEWINFO = 0x10A2 -> http://msdn.microsoft.com/en-us/library/bb761212(v=vs.85).aspx
   ; One line is added internally because the item might be wrapped to two lines!
   Static SizeLVTVI := 40
   Static OffLines := 20
   If (Lines > 0)
      Lines++
   LVTVI := Buffer(SizeLVTVI, 0)     ; LVTILEVIEWINFO
   NumPut("UInt", SizeLVTVI, LVTVI, 0)     ; cbSize
   NumPut("UInt", 0x00000003, LVTVI, 4)    ; dwMask = LVTVIM_TILESIZE | LVTVIM_COLUMNS
   NumPut("Int", Lines, LVTVI, OffLines) ; c_lines: max lines below first line
   Return SendMessage(0x10A2, 0, LVTVI, , "ahk_id " . HLV) ; LVM_SETTILEVIEWINFO
}
; ======================================================================================================================
; LV_EX_SubItemHitTest - Gets the column (subitem) at the passed coordinates or the position of the mouse cursor.
; ======================================================================================================================
LV_EX_SubItemHitTest(HLV, X := -1, Y := -1) {
   ; LVM_SUBITEMHITTEST = 0x1039 -> http://msdn.microsoft.com/en-us/library/bb761229(v=vs.85).aspx
   LVHTI := Buffer(24, 0) ; LVHITTESTINFO
   If (X = -1) || (Y = -1) {
      DllCall("User32.dll\GetCursorPos", "Ptr", &LVHTI)
      DllCall("User32.dll\ScreenToClient", "Ptr", HLV, "Ptr", &LVHTI)
   } Else {
      NumPut("Int", X, LVHTI, 0)
      NumPut("Int", Y, LVHTI, 4)
   }
   res := SendMessage(0x1039, 0, LVHTI, , "ahk_id " . HLV)
   Return (res > 0x7FFFFFFF ? 0 : NumGet(LVHTI, 16, "Int") + 1)
}
; ======================================================================================================================
; ======================================================================================================================
; Function for internal use ============================================================================================
; ======================================================================================================================
; ======================================================================================================================
LV_EX_LVITEM(&LVITEM, Mask := 0, Row := 1, Col := 1) {
   Static LVITEMSize := 48 + (A_PtrSize * 3)
   LVITEM := Buffer(LVITEMSize, 0)
   NumPut("UInt", Mask, LVITEM), NumPut("Int", Row - 1, LVITEM , 4), NumPut("Int", Col - 1, LVITEM, 8)
}
; ----------------------------------------------------------------------------------------------------------------------
LV_EX_PWSTR(Str, &WSTR) { ; ANSI to Unicode
   WSTR := Buffer(StrPut(Str, "UTF-16") * 2, 0)
   StrPut(Str, WSTR, "UTF-16")
   Return &WSTR
}