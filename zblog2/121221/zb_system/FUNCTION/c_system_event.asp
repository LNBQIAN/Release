﻿<%
'///////////////////////////////////////////////////////////////////////////////
'//              Z-Blog
'// 作    者:    朱煊(zx.asd)
'// 版权所有:    RainbowSoft Studio
'// 技术支持:    rainbowsoft@163.com
'// 程序名称:
'// 程序版本:
'// 单元名称:    c_system_event.asp
'// 开始时间:    2005.02.11
'// 最后修改:
'// 备    注:
'///////////////////////////////////////////////////////////////////////////////





'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    用户登陆
'*********************************************************
Public Function Login()

	'If CheckVerifyNumber(Request.Form("edtCheckOut"))=False Then Call ShowError(38)

	BlogUser.LoginType="Self"
	BlogUser.Name=Request.Form("username")
	BlogUser.PassWord=BlogUser.GetPasswordByMD5(Request.Form("password"))

	If BlogUser.Verify=True Then

		Response.Cookies("password")=BlogUser.PassWord
		If Request.Form("savedate")<>0 Then
			Response.Cookies("password").Expires = DateAdd("d", Request.Form("savedate"), now)
		End If
		Response.Cookies("password").Path = CookiesPath()

		Login=True


	End If

	Response.Cookies("username")=escape(Request.Form("username"))
	If Request.Form("savedate")<>0 Then
		Response.Cookies("username").Expires = DateAdd("d", Request.Form("savedate"), now)
	End If
	Response.Cookies("username").Path = CookiesPath()


End Function
'*********************************************************




'*********************************************************
' 目的：    用户退出
'*********************************************************
Public Function Logout()

	Response.Cookies("username")=""
	Response.Cookies("password")=""
	Response.Cookies("username").Path = CookiesPath()
	Response.Cookies("password").Path = CookiesPath()
	
	Logout=True

End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    文件上传
'*********************************************************
Function UploadFile(bolAutoName)

	Dim objUpLoadFile
	Set objUpLoadFile=New TUpLoadFile

	objUpLoadFile.AuthorID=BlogUser.ID
	objUpLoadFile.AutoName=bolAutoName

	If objUpLoadFile.UpLoad() Then

		UploadFile=True

	End If

	Set objUpLoadFile=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Form of Send File
'*********************************************************
Function SendFile()

	Response.Write "<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd""><html><head><meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8""/><meta http-equiv=""Content-Language"" content=""zh-cn"" /><link rel=""stylesheet"" rev=""stylesheet"" href=""CSS/admin.css"" type=""text/css"" media=""screen"" /><script src=""script/common.js"" type=""text/javascript""></script></head><body>"

	Response.Write "<form border=""1"" name=""edit"" id=""edit"" method=""post"" enctype=""multipart/form-data"" action="""& BlogHost &"cmd.asp?act=FileUpload&reload=1"">"
	Response.Write "<p>"& ZC_MSG108 &": "
	Response.Write "<input type=""file"" id=""edtFileLoad"" name=""edtFileLoad"" size=""20"">  <input type=""submit"" class=""button"" value="""& ZC_MSG087 &""" name=""B1"" onclick='document.getElementById(""edit"").action=document.getElementById(""edit"").action+""&filename=""+escape(document.getElementById(""edtFileLoad"").value)' /> <input class=""button"" type=""reset"" value="""& ZC_MSG088 &""" name=""B2"" />"
	Response.Write "&nbsp;<input type=""checkbox"" onclick='if(this.checked==true){document.getElementById(""edit"").action=document.getElementById(""edit"").action+""&autoname=1"";}else{document.getElementById(""edit"").action="""& BlogHost &"cmd.asp?act=FileUpload&reload=1"";};SetCookie(""chkAutoFileName"",this.checked,365);' id=""chkAutoName"" id=""chkAutoName""/><label for=""chkAutoName"">"& ZC_MSG131 &"</label></p></form>"

	Response.Write "<script type=""text/javascript"">if(GetCookie(""chkAutoFileName"")==""true""){document.getElementById(""chkAutoName"").checked=true;document.getElementById(""edit"").action=document.getElementById(""edit"").action+""&autoname=1"";};</script></body></html>"

End Function
'*********************************************************





'*********************************************************
' 目的：     文件删除
'*********************************************************
Function DelFile(intID)

	Dim objUpLoadFile
	Set objUpLoadFile=New TUpLoadFile

	If objUpLoadFile.LoadInfoByID(intID) Then

		If (objUpLoadFile.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True) Then
			If objUpLoadFile.Del Then DelFile=True
		End If

	Else
		Exit Function
	End If

	Set objUpLoadFile=Nothing

End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Post Article
'*********************************************************
Function PostArticle()

	Dim s,i,t,k
	Dim strTag

	If Request.Form("edtID")<>"0" Then
		Dim objTestArticle
		Set objTestArticle=New TArticle
		If objTestArticle.LoadInfobyID(Request.Form("edtID")) Then
			If Not((objTestArticle.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
			strTag=objTestArticle.Tag
			objTestArticle.DelFile
		Else
			Call ShowError(9)
		End If
	End If

	Dim objArticle
	Set objArticle=New TArticle
	objArticle.ID=Request.Form("edtID")
	objArticle.CateID=Request.Form("edtCateID")
	objArticle.AuthorID=IIf(CheckRights("Root"),Request.Form("edtAuthorID"),BlogUser.ID)
	objArticle.Level=Request.Form("edtLevel")
'	objArticle.PostTime=Request.Form("edtYear") & "-" & Request.Form("edtMonth") & "-" & Request.Form("edtDay") & " " &  Request.Form("edtTime")
	objArticle.PostTime=Request.Form("edtDateTime")
	objArticle.Title=Request.Form("edtTitle")
	objArticle.Tag=ParseTag(Request.Form("edtTag"))
	objArticle.Alias=Request.Form("edtAlias")
	objArticle.Istop=IIf(CheckRights("Root"),Request.Form("edtIstop"),False)
	objArticle.TemplateName=Request.Form("edtTemplate")
	objArticle.FType=CLng(Request.Form("edtFType"))

	objArticle.Intro=Request.Form("txaIntro")

	objArticle.Content=Request.Form("txaContent")

	If objArticle.FType=ZC_POST_TYPE_ARTICLE Then
		If InStr(objArticle.Content,"<hr class=""more"" />")>0 Then
			s=objArticle.Content
			i=InStr(s,"<hr class=""more"" />")
			s=Left(s,i-1)
			objArticle.Intro=closeHTML(s)
			objArticle.Content=Replace(objArticle.Content,"<hr class=""more"" />","<!–more–>",1,1)
		End If

		If objArticle.Intro="" Then
			s=objArticle.Content
			For i =0 To UBound(Split(s,"</p>"))
				If Trim(Split(s,"</p>")(i))<>"" Then
					t=t & Split(s,"</p>")(i) & "</p>"
				End If
				If Len(t)>ZC_ARTICLE_EXCERPT_MAX Then Exit for
			Next 
			objArticle.Intro=closeHTML(t)
		End If
	ElseIf objArticle.FType=ZC_POST_TYPE_PAGE Then
		If CheckRights("Root")=False Then Call ShowError(6)
	End If

	Call GetMetaValuewithForm(objArticle)

	'接口
	Call Filter_Plugin_PostArticle_Core(objArticle)

	If objArticle.Post Then
		Call ScanTagCount(strTag & objArticle.Tag)
		Call BuildArticle(objArticle.ID,True,True)
		If objArticle.FType=ZC_POST_TYPE_PAGE And Request.Form("edtAddNavBar")="True" Then
			Call AddNavBar(objArticle.ID)
		End If
		PostArticle=True
		Call Filter_Plugin_PostArticle_Succeed(objArticle)
	End If

	Set objArticle=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Del Article
'*********************************************************
Function DelArticle(intID)

	Dim strTag

	If intID<>"" Then
		Dim objTestArticle
		Set objTestArticle=New TArticle
		If objTestArticle.LoadInfobyID(intID) Then
			If Not((objTestArticle.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
			strTag=objTestArticle.Tag
		Else
			Call ShowError(9)
		End If
		Set objTestArticle=Nothing
	End If

	Dim objArticle
	Set objArticle=New TArticle

	If objArticle.LoadInfoByID(intID) Then

		If objArticle.Del Then 
			objArticle.Statistic
			DelArticle=True
		End If 
		Call ScanTagCount(strTag)

		Call BlogReBuild_Comments
		Call BlogReBuild_Default

	End If

	Set objArticle=Nothing

End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Post Category
'*********************************************************
Function PostCategory()

	If Instr(Request.ServerVariables("HTTP_REFERER"),"?id=0")>0 Then

		Call BlogConfig.Write("ZC_UNCATEGORIZED_NAME",Request.Form("edtName"))
		Call BlogConfig.Write("ZC_UNCATEGORIZED_ALIAS",Request.Form("edtAlias"))
		BlogConfig.Save
		PostCategory=True
		Exit Function
		Response.End
	End If

	Dim objCategory
	Set objCategory=New TCategory
	objCategory.ID=Request.Form("edtID")
	objCategory.Name=Request.Form("edtName")
	objCategory.Order=Request.Form("edtOrder")
	objCategory.ParentID=Request.Form("edtPareID")
	objCategory.Alias=Request.Form("edtAlias")
	objCategory.TemplateName=Request.Form("edtTemplate")
	objCategory.LogTemplate=Request.Form("edtLogTemplate")

	Call GetMetaValuewithForm(objCategory)

	'接口
	Call Filter_Plugin_PostCategory_Core(objCategory)


	If objCategory.Post Then

		PostCategory=True

		Call Filter_Plugin_PostCategory_Succeed(objCategory)

	End If

	Set objCategory=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Del Category
'*********************************************************
Function DelCategory(intID)

	Dim objCategory
	Set objCategory=New TCategory

	If objCategory.LoadInfobyID(intID) Then
		If objCategory.Del Then DelCategory=True
	End If

	Set objCategory=Nothing

End Function
'*********************************************************





'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Post Comment
'*********************************************************
Function PostComment(strKey,intRevertCommentID)

	Call GetUser()

	If IsEmpty(Request.Form("inpAjax"))=False Then
		ShowError_Custom="Call RespondError(id,ZVA_ErrorMsg(id)):Response.End"
	End If

	If ZC_COMMENT_TURNOFF Then
		Call ShowError(40)
	End If

	If ZC_COMMENT_VERIFY_ENABLE Then
		If CheckVerifyNumber(Request.Form("inpVerify"))=False Then Call ShowError(38)
	End If

	Dim inpID,inpName,inpArticle,inpEmail,inpHomePage,inpParentID

	inpID=Request.Form("inpID")
	inpName=Request.Form("inpName")
	inpArticle=Request.Form("inpArticle")
	inpEmail=Request.Form("inpEmail")
	inpHomePage=Request.Form("inpHomePage")
	inpParentID=intRevertCommentID
	
	If Len(inpArticle)=0 Or Len(inpArticle)>ZC_CONTENT_MAX Then
		Call  ShowError(46)
	End If

	Dim objComment
	Dim objArticle
	Dim tmpCount

	Set objComment=New TComment


	If CLng(inpParentID)>0 Then
		
		Dim i
		i=GetCommentFloor(inpParentID)
		If i>ZC_COMMNET_MAXFLOOR-1 Then	Call ShowError(52)

	End If


	objComment.log_ID=inpID
	objComment.AuthorID=BlogUser.ID
	objComment.Author=inpName
	objComment.Content=inpArticle
	objComment.Email=inpEmail
	objComment.HomePage=inpHomePage
	objComment.ParentID=inpParentID


	'接口
	Call Filter_Plugin_PostComment_Core(objComment)

	If objComment.IsThrow=True Then Call ShowError(14)

	If objComment.AuthorID>0 Then
		objComment.Author  =Users(objComment.AuthorID).Name
		objComment.EMail   =Users(objComment.AuthorID).Email
		objComment.HomePage=Users(objComment.AuthorID).HomePage
	End If

	If objComment.log_ID>0 Then
		Set objArticle=New TArticle
		If objArticle.LoadInfoByID(objComment.log_ID) Then
			If Not (strKey=objArticle.CommentKey) Then Call ShowError(43)
			If objArticle.Level<4 Then Call ShowError(44)
		End If
		Set objArticle=Nothing
	End If

	Dim objUser
	For Each objUser in Users
		If IsObject(objUser) Then
			If (UCase(objUser.Name)=UCase(objComment.Author)) And (objUser.ID<>objComment.AuthorID) Then ShowError(31)
		End If
	Next

	If objComment.Post Then

		If objComment.IsCheck=True Then Call ShowError(53)

		Call BuildArticle(objComment.log_ID,False,True)
		Call BlogReBuild_Comments
		Call BlogReBuild_Default
		PostComment=True
		Call Filter_Plugin_PostComment_Succeed(objComment)

	End if

	If IsEmpty(Request.Form("inpAjax"))=False Then
		Call ReturnAjaxComment(objComment)
		Call ClearGlobeCache
		Call LoadGlobeCache
	End If

	Set objComment=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Del Comment
'*********************************************************
Function DelComment(intID,intLog_ID)

	Dim objComment
	Dim objArticle

	Set objComment=New TComment
	Set objArticle=New TArticle

	If objComment.LoadInfobyID(intID) Then

		If objComment.log_ID>0 Then
			Dim objTestArticle
			Set objTestArticle=New TArticle
			If objTestArticle.LoadInfobyID(objComment.log_ID) Then
				If Not((objComment.AuthorID=BlogUser.ID) Or (objTestArticle.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
			Else
				Call ShowError(9)
			End If
			Set objTestArticle=Nothing

			Dim allcomm,i
			If SearchChildComments(intID,allcomm)=True Then
				For Each i In allcomm.Keys
					Dim objSubComment
					Set objSubComment=New TComment
					If objSubComment.LoadInfobyID(i) Then
						objSubComment.Del
					End If
				Next
			End If

		End If
		DelChild objComment.ID
		If objComment.Del Then

			Call BuildArticle(objComment.log_ID,False,True)
			Call BlogReBuild_Comments
			Call BlogReBuild_Default

			DelComment=True
		End If

	End If

	Set objComment=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Save Comment
'*********************************************************
Function SaveComment()

	Dim objComment
	Dim objArticle

	Set objComment=New TComment

	If objComment.LoadInfoByID(Request.Form("inpID")) Then
		objComment.Author=Request.Form("inpName")
		objComment.Email=Request.Form("inpEmail")
		objComment.HomePage=Request.Form("inpHomePage")
		objComment.Content=Request.Form("txaContent")
	Else
		Call ShowError(61)
	End If


	If objComment.log_ID>0 Then
		Set objArticle=New TArticle
		If objArticle.LoadInfoByID(objComment.log_ID) Then
			If Not ((objArticle.AuthorID=BlogUser.ID) Or (objComment.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
		End If
		Set objArticle=Nothing
	End If

	Call Filter_Plugin_PostComment_Core(objComment)

	If objComment.Post Then

		Call BuildArticle(objComment.log_ID,False,False)
		Call BlogReBuild_Comments
		Call BlogReBuild_Default

		SaveComment=True

		Call Filter_Plugin_PostComment_Succeed(objComment)

	End if

	Set objComment=Nothing

End Function
'*********************************************************



'*********************************************************
' 目的：    Save Rev Comment
'*********************************************************
Function SaveRevComment()

	Dim objRevComment
	Dim objNewComment
	Dim objArticle

	Set objNewComment=New TComment
	Set objRevComment=New TComment

	If objRevComment.LoadInfoByID(Request.Form("intRevID")) Then

		objNewComment.ParentID=objRevComment.ID
		objNewComment.log_ID=objRevComment.log_ID
		objNewComment.AuthorID=BlogUser.ID
		objNewComment.Author=BlogUser.Name
		objNewComment.Email=BlogUser.Email
		objNewComment.HomePage=BlogUser.HomePage
		objNewComment.Content=Request.Form("txaContent")

	Else
		Call ShowError(61)
	End If

	If Len(objNewComment.Content)=0 Or Len(objNewComment.Content)>ZC_CONTENT_MAX Then
		Call ShowError(46)
	End If

	If objNewComment.log_ID>0 Then
		Set objArticle=New TArticle
		If objArticle.LoadInfoByID(objNewComment.log_ID) Then
			If Not ((objArticle.AuthorID=BlogUser.ID) Or (objNewComment.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
		End If
		Set objArticle=Nothing
	End If

	Call Filter_Plugin_PostComment_Core(objNewComment)

	If objNewComment.Post Then

		Call BuildArticle(objNewComment.log_ID,False,False)
		Call BlogReBuild_Comments
		Call BlogReBuild_Default

		SaveRevComment=True

		Call Filter_Plugin_PostComment_Succeed(objNewComment)

	End if

	Set objNewComment=Nothing
	Set objRevComment=Nothing

End Function
'*********************************************************





'*********************************************************
' 目的：    Return Ajax Comment
'*********************************************************
Dim ReturnAjaxComment_aryTemplateTagsName
Dim ReturnAjaxComment_aryTemplateTagsValue

Function ReturnAjaxComment_Plugin(aryTemplateTagsName,aryTemplateTagsValue)
	ReturnAjaxComment_aryTemplateTagsName=aryTemplateTagsName
	ReturnAjaxComment_aryTemplateTagsValue=aryTemplateTagsValue
End Function
'Mark5
Function ReturnAjaxComment(objComment)

	On Error Resume Next

	Dim i,j
	i=0
	Dim objArticle


	'Filter_Plugin_TArticle_Export_TemplateTags
	Call Add_Filter_Plugin("Filter_Plugin_TArticle_Export_TemplateTags","ReturnAjaxComment_Plugin")

	Set objArticle=New TArticle
	If objArticle.LoadInfoByID(objComment.log_ID) Then
		Call objArticle.Export(ZC_DISPLAY_MODE_ALL)
		i=objArticle.CommNums
	End If


	Dim strC
	strC=GetTemplate("TEMPLATE_B_ARTICLE_COMMENT")
	objComment.Count=objComment.Count+1
	strC=objComment.MakeTemplate(strC)
	strC=Replace(strC,"<#ZC_BLOG_HOST#>",BlogHost)

	Dim aryTemplateTagsName2
	Dim aryTemplateTagsValue2

	aryTemplateTagsName2=TemplateTagsDic.Keys
	aryTemplateTagsValue2=TemplateTagsDic.Items

	j=UBound(ReturnAjaxComment_aryTemplateTagsName)
	For i=1 to j
		If IsNull(ReturnAjaxComment_aryTemplateTagsValue(i))=False Then
			strC = Replace(strC,"<#" & ReturnAjaxComment_aryTemplateTagsName(i) & "#>", ReturnAjaxComment_aryTemplateTagsValue(i))
		End If
	Next

	j=UBound(aryTemplateTagsName2)

	For i=1 to j
		strC=Replace(strC,"<#" & aryTemplateTagsName2(i) & "#>",aryTemplateTagsValue2(i))
	Next


	strC= Replace(strC,vbCrLf,"")
	strC= Replace(strC,vbLf,"")
	strC= Replace(strC,vbTab,"")
	Response.Write strC

	ReturnAjaxComment=True

End Function
'*********************************************************





'*********************************************************
' 目的：    Get Comment Ajax
'*********************************************************
Function GetComment(logid,page)

	Dim objArticle
	Set objArticle=New TArticle

	'Filter_Plugin_TArticle_Export_TemplateTags
	Call Add_Filter_Plugin("Filter_Plugin_TArticle_Export_TemplateTags","ReturnAjaxComment_Plugin")

	If objArticle.LoadInfoByID(logid) Then
		objArticle.CommentsPage=page
		Call objArticle.Export(ZC_DISPLAY_MODE_COMMENTS)
		s=objArticle.subhtml
	End If

	Dim i,j,s
	Dim aryTemplateTagsName2
	Dim aryTemplateTagsValue2

	aryTemplateTagsName2=TemplateTagsDic.Keys
	aryTemplateTagsValue2=TemplateTagsDic.Items

	j=UBound(ReturnAjaxComment_aryTemplateTagsName)
	For i=1 to j
		If IsNull(ReturnAjaxComment_aryTemplateTagsValue(i))=False Then
			s = Replace(s,"<#" & ReturnAjaxComment_aryTemplateTagsName(i) & "#>", ReturnAjaxComment_aryTemplateTagsValue(i))
		End If
	Next

	j=UBound(aryTemplateTagsName2)

	For i=1 to j
		s=Replace(s,"<#" & aryTemplateTagsName2(i) & "#>",aryTemplateTagsValue2(i))
	Next

	Dim objRegExp
	Set objRegExp=New RegExp
	objRegExp.IgnoreCase =True
	objRegExp.Global=True
	objRegExp.Pattern="<div id=""AjaxComment[\D\d]+?</div>"
	s= objRegExp.Replace(s,"")


	s= Replace(s,vbCrLf,"")
	s= Replace(s,vbLf,"")
	s= Replace(s,vbTab,"")

	Response.Write s

End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Post TrackBack
'*********************************************************
Function PostTrackBack(intID,strKey)

	Dim objTrackBack
	Dim objArticle

	Dim keys
	Dim i,j,k,b

	If ZC_TRACKBACK_TURNOFF Then
		Call RespondError(41,ZVA_ErrorMsg(41))
	End If

	If Len(strKey)=5 Then

		If CheckVerifyNumber(strKey)=False Then Call ShowError(43)

	ElseIf Len(strKey)=8 Then

		Set objArticle=New TArticle
		If objArticle.LoadInfoByID(intID) Then
			If Not (strKey=objArticle.TrackBackKey) Then Call RespondError(43)
			If objArticle.Level<4 Then Call RespondError(44)
		End If
		Set objArticle=Nothing

	Else
		Exit Function
	End If

	Set objTrackBack=New TTrackBack
	Set objArticle=New TArticle

	objTrackBack.log_ID=intID
	objTrackBack.URL=Request.Form("url")
	objTrackBack.Title=Request.Form("title")
	objTrackBack.Blog=Request.Form("blog_name")
	objTrackBack.Excerpt=Request.Form("excerpt")

	'接口
	Call Filter_Plugin_PostTrackBack_Core(objTrackBack)

	If objTrackBack.Post Then
		Call BuildArticle(objTrackBack.log_ID,False,True)
		BlogReBuild_TrackBacks
		PostTrackBack=True
		Call Filter_Plugin_PostTrackBack_Succeed(objTrackBack)
	End If

	Response.ContentType = "text/xml"
	Response.Clear
	Response.Write objTrackBack.TbXML

	Set objTrackBack=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Del TrackBack
'*********************************************************
Function DelTrackBack(intID,intLog_ID)

	Dim objTrackBack
	Dim objArticle

	Set objTrackBack=New TTrackBack
	Set objArticle=New TArticle

	If objTrackBack.LoadInfobyID(intID) Then

		Dim objTestArticle
		Set objTestArticle=New TArticle
		If objTestArticle.LoadInfobyID(objTrackBack.log_ID) Then
			If Not((objTestArticle.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
		Else
			Call ShowError(9)
		End If
		Set objTestArticle=Nothing

		If objTrackBack.Del Then
			Call BuildArticle(objTrackBack.log_ID,False,True)
			BlogReBuild_TrackBacks
			DelTrackBack=True
		End If

	End If

	Set objTrackBack=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Send TrackBack
'*********************************************************
Function SendTrackBack()

	Dim objTrackBack
	Dim objArticle

	Set objTrackBack=New TTrackBack
	Set objArticle=New TArticle

	If objArticle.LoadInfobyID(Request.Form("edtID")) Then
		objTrackBack.URL=objArticle.Url
		objTrackBack.Title=objArticle.Title
		objTrackBack.Blog=ZC_BLOG_NAME
		objTrackBack.Excerpt=Left(objArticle.HtmlContent,250)
	Else
		Call ShowError(9)
	End If

	If objTrackBack.Send(Request.Form("edtTrackBack")) Then SendTrackBack=True
	Set objTrackBack=Nothing

End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Edit User
'*********************************************************
Function EditUser()

	Dim objUser
	Set objUser=New TUser
	objUser.ID=Request.Form("edtID")
	objUser.Level=Request.Form("edtLevel")
	objUser.Name=Request.Form("edtName")
	objUser.Email=Request.Form("edtEmail")
	objUser.HomePage=Request.Form("edtHomePage")
	objUser.Alias=Request.Form("edtAlias")

	If BlogUser.Level<4 Then
		objUser.Intro=Request.Form("edtIntro")
	End If

	If Trim(Request.Form("edtPassWord"))<>"" Then
		objUser.PassWord=objUser.CreatePasswordByOriginal(Request.Form("edtPassWord"))
		If Not CheckRegExp(Request.Form("edtPassWord"),"[password]") Then Call ShowError(54)
	End If

	Call GetMetaValuewithForm(objUser)

	If Not((CLng(objUser.ID)=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function

	'接口
	Call Filter_Plugin_EditUser_Core(objUser)

	If objUser.Edit(BlogUser) Then
		Call Filter_Plugin_EditUser_Succeed(objUser)
		EditUser=True
	End IF

	Set objUser=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Del User
'*********************************************************
Function DelUser(intID)

	Dim objRS
	Dim objUser
	Dim objUpLoadFile

	Set objUser=New TUser
	objUser.ID=intID
	If objUser.Del(BlogUser) Then DelUser=True
	Set objUser=Nothing

End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Blog ReBuild
'*********************************************************
Function MakeBlogReBuild()

	'plugin node
	bAction_Plugin_MakeBlogReBuild_Begin=False
	For Each sAction_Plugin_MakeBlogReBuild_Begin in Action_Plugin_MakeBlogReBuild_Begin
		If Not IsEmpty(sAction_Plugin_MakeBlogReBuild_Begin) Then Call Execute(sAction_Plugin_MakeBlogReBuild_Begin)
		If bAction_Plugin_MakeBlogReBuild_Begin=True Then Exit Function
	Next

	Call MakeBlogReBuild_Core()

	Session("batchtime")=Session("batchtime")+RunTime

	Call SetBlogHint(True,False,Empty)

	MakeBlogReBuild=True

	'plugin node
	bAction_Plugin_MakeBlogReBuild_End=False
	For Each sAction_Plugin_MakeBlogReBuild_End in Action_Plugin_MakeBlogReBuild_End
		If Not IsEmpty(sAction_Plugin_MakeBlogReBuild_End) Then Call Execute(sAction_Plugin_MakeBlogReBuild_End)
		If bAction_Plugin_MakeBlogReBuild_End=True Then Exit Function
	Next

End Function
'*********************************************************





'*********************************************************
' 目的：    文件重建 批处理 前置
'*********************************************************
Function BeforeFileReBuild()

	If ZC_POST_STATIC_MODE<>"STATIC" Then Exit Function

	Dim objRS
	Dim objArticle

	Set objRS=Server.CreateObject("ADODB.Recordset")
	objRS.CursorType = adOpenKeyset
	objRS.LockType = adLockReadOnly
	objRS.ActiveConnection=objConn
	objRS.Source="SELECT [log_ID] FROM [blog_Article] WHERE [log_Level]>1"
	objRS.Open()

	If (Not objRS.bof) And (Not objRS.eof) Then

		objRS.PageSize = ZC_REBUILD_FILE_COUNT

		Dim i
		For i=1 To objRS.PageCount
			Call AddBatch(ZC_MSG073 & "<"&i&">","Call MakeFileReBuild("&i&")")
		Next

	End If

End Function
'*********************************************************



'*********************************************************
' 目的：    All Files ReBuild
'*********************************************************
Function MakeFileReBuild(intPage)

	'plugin node
	'bAction_Plugin_MakeFileReBuild_Begin=False
	'For Each sAction_Plugin_MakeFileReBuild_Begin in Action_Plugin_MakeFileReBuild_Begin
	'	If Not IsEmpty(sAction_Plugin_MakeFileReBuild_Begin) Then Call Execute(sAction_Plugin_MakeFileReBuild_Begin)
	'	If bAction_Plugin_MakeFileReBuild_Begin=True Then Exit Function
	'Next

	Dim i,j

	Dim objRS
	Dim objArticle

	Set objRS=Server.CreateObject("ADODB.Recordset")
	objRS.CursorType = adOpenKeyset
	objRS.LockType = adLockReadOnly
	objRS.ActiveConnection=objConn
	objRS.Source="SELECT [log_ID] FROM [blog_Article] WHERE [log_Level]>1"
	objRS.Open()

	If (Not objRS.bof) And (Not objRS.eof) Then

		objRS.PageSize = ZC_REBUILD_FILE_COUNT

		objRS.AbsolutePage = intPage

		For i = 1 To objRS.PageSize

			Call BuildArticle(objRS("log_ID"),False,False)

			objRS.MoveNext
			If objRS.eof Then Exit For
			
			
		Next

		Session("batchtime")=Session("batchtime")+RunTime

	End If

	'plugin node
	'bAction_Plugin_MakeFileReBuild_End=False
	'For Each sAction_Plugin_MakeFileReBuild_End in Action_Plugin_MakeFileReBuild_End
	'	If Not IsEmpty(sAction_Plugin_MakeFileReBuild_End) Then Call Execute(sAction_Plugin_MakeFileReBuild_End)
	'	If bAction_Plugin_MakeFileReBuild_End=True Then Exit Function
	'Next

End Function
'*********************************************************




'*********************************************************
' 目的：    Batch ALL
'*********************************************************
Function BatchAll()

	On Error Resume Next

	Server.ScriptTimeout = 1200

	If Request.QueryString("cancel")="true" Then
		Session("batch").RemoveAll
		Session("batchorder")=0
		Session("batchtime")=0
	End If 
	
	
	If IsObject(Session("batch")) Then
	
		Dim i
		Dim a
		Set a = Session("batch")
		Dim b
		b=a.Keys
		Dim c
		c=a.Items
	
		Dim intAllTime
	
	 
		If a.Count >0 Then
	
			For i = 0 To 0
	
				Response.Write "<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd""><html><head><meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8""/><meta http-equiv=""refresh"" content="""&ZC_REBUILD_FILE_INTERVAL&";URL="&BlogHost & "zb_system/cmd.asp?act=batch"&"&all="&intAllTime&"""/><style>body{padding:0; margin:0;background:#dbe3ff;}img{border:0;padding:0; margin:0;background:Transparent;}</style></head><body>"
				Response.Write "<img src='image/admin/loading.gif' width='20'>"
				Response.Write "<script type=""text/javascript"">parent.Batch2Tip("""&b(0) & ZC_MSG109&""")</script>"
				If Session("batchorder")=Session("batch").Count Then
					Response.Write "<script type=""text/javascript"">parent.BatchBegin()</script>"
				End If
				Response.Write "<div class=""hidden"">"
				Call GetBlogHint()
				Response.Write "</div>"
	
				Response.Flush
	
				Response.Write "</body></html>"
	
				Call Execute(c(0))
				Session("batch").Remove(b(0))
	
			Next
	
		Else
	
	
			Response.Write "<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd""><html><head><meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8""/><style>body{padding:0; margin:0;background:#dbe3ff;}img{border:0;padding:0; margin:0;background:Transparent;}</style></head><body>"
			Response.Write "<img src='image/admin/ok.png' width='16'>"
			Response.Write "<script type=""text/javascript"">parent.Batch2Tip("""&ZC_MSG227 & Replace(ZC_MSG169,"%n",Session("batchtime")/1000) &""")</script>"
			Response.Write "<script type=""text/javascript"">parent.BatchEnd()</script>"
	
			Response.Write "<div class=""hidden"">"
			Call GetBlogHint()
			Response.Write "</div>"
			If Session("batchtime")/1000>0 Then
				Response.Write "<script type=""text/javascript"">parent.BatchNotify();</script>"
			End If
			
			Response.Write "</body></html>"
	
			Session.Abandon
	
		End If
	End If

End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    List User Rights
'*********************************************************
Function ListUser_Rights()

	Dim s
	Dim i
	Dim t
	Dim strAction
	Dim aryAction

	strAction="Root|login|verify|logout|admin|cmt|vrs|rss|batch|BlogReBuild|FileReBuild|ArticleMng|ArticleEdt|ArticlePst|ArticleDel|CategoryMng|CategoryPst|CategoryDel|CommentMng|CommentDel|UserMng|UserEdt|UserMod|UserCrt|UserDel|FileMng|FileUpload|FileDel|Search|TagMng|TagEdt|TagPst|TagDel|SettingMng|SettingSav|PlugInMng|FunctionMng"

	aryAction=Split(strAction, "|")

	s=Split(ZC_MSG019,"%s")

	Response.Write "<!DOCTYPE html PUBLIC ""-//W3C//DTD XHTML 1.0 Transitional//EN"" ""http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd""><html xmlns=""http://www.w3.org/1999/xhtml"" xml:lang="""&ZC_BLOG_LANGUAGE&""" lang="""&ZC_BLOG_LANGUAGE&"""><head><meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8"" /><meta http-equiv=""Content-Language"" content="""&ZC_BLOG_LANGUAGE&""" /><link rel=""stylesheet"" rev=""stylesheet"" href=""css/admin.css"" type=""text/css"" media=""screen"" /><title>"&ZC_BLOG_TITLE & ZC_MSG044 & ZC_MSG021&"</title></head><body class=""short""><div class=""bg""><div id=""wrapper""><div class=""logo""><img src=""image/admin/none.gif"" title=""Z-Blog"" alt=""Z-Blog""/></div><div class=""login"" style=""width:300px;""><form id=""frmLogin"" method=""post"" action=""""><dl><dd>"


	Response.Write ZC_MSG001 & ":" & BLogUser.Name & "<br/><br/>"
	Response.Write ZC_MSG249 & ":" & ZVA_User_Level_Name(BLogUser.Level) & "<br/><br/>"

	For i=LBound(aryAction) To UBound(aryAction)
		If Not CheckRights(aryAction(i)) Then t=t & "<p style='display:none;'>" & Replace(s(i) & "%s","%s",":<font color=Red>fail</font>"&"",1,1) & "</p>" Else t=t & "<p>" & Replace(s(i) & "%s","%s",":<font color=green>ok</font>"&"",1,1) & "</p><br/>" 
	Next

	Response.Write t

	Response.Write "</dd></dl></div></div></div></body></html>"


	ListUser_Rights=True

End Function
'*********************************************************





'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Save Blog Setting
'*********************************************************
Function SaveSetting()

	On Error Resume Next

	If BlogConfig.Exists("ZC_SYNTAXHIGHLIGHTER_ENABLE")=False Then Call BlogConfig.Write("ZC_SYNTAXHIGHLIGHTER_ENABLE",False)

	If BlogConfig.Exists("ZC_CODEMIRROR_ENABLE")=False Then Call BlogConfig.Write("ZC_CODEMIRROR_ENABLE",False)

	If BlogConfig.Exists("ZC_ARTICLE_EXCERPT_MAX")=False Then Call BlogConfig.Write("ZC_ARTICLE_EXCERPT_MAX",250)

	If BlogConfig.Exists("ZC_POST_STATIC_MODE")=False Then Call BlogConfig.Write("ZC_POST_STATIC_MODE","STATIC")
	
	If BlogConfig.Exists("ZC_HTTP_LASTMODIFIED")=False Then Call BlogConfig.Write("ZC_HTTP_LASTMODIFIED",False)

	Dim a,b,c,d
	b=LoadFromFile(BlogPath &"zb_users\c_option.asp","utf-8")
	Set d=CreateObject("Scripting.Dictionary")
	For Each a In BlogConfig.Meta.Names
		If InStr(b,"Dim "& a)>0 Then
			If a<>"ZC_BLOG_VERSION" And a<>"" Then
				Call Execute("Call BlogConfig.Write("""&a&""","&a&")")
			End If
		End If
	Next
	Err.Clear

	Call BlogConfig.Write("ZC_BLOG_CLSID",ZC_BLOG_CLSID_ORIGINAL)

	For Each a In Request.Form 
		b=Mid(a,4,Len(a))
		If BlogConfig.Exists(b)=True Then
			If b="ZC_UPLOAD_FILESIZE" Or b="ZC_DISPLAY_COUNT" Or b="ZC_SEARCH_COUNT" Or b="ZC_MUTUALITY_COUNT" Or b="ZC_MUTUALITY_COUNT" Or b="ZC_COMMENTS_DISPLAY_COUNT"  Or b="ZC_REBUILD_FILE_COUNT"  Or b="ZC_REBUILD_FILE_INTERVAL" Or b="ZC_DISPLAY_COUNT_WAP"  Or b="ZC_COMMENT_COUNT_WAP"  Or b="ZC_PAGEBAR_COUNT_WAP"  Or b="ZC_WAP_MUTUALITY_LIMIT" Then
				c=Request.Form(a)
				Call CheckParameter(c,"int",0)
				d.add b,CStr(c)
			Else
				d.add b,Request.Form(a)
			End If
		End If
	Next

	If BlogConfig.Read("ZC_STATIC_DIRECTORY")<>d.Item("ZC_STATIC_DIRECTORY")Then
		Call CreatDirectoryByCustomDirectory(d.Item("ZC_STATIC_DIRECTORY"))
		Call SetBlogHint(Empty,Empty,True)
	End If

	If BlogConfig.Read("ZC_BLOG_HOST")<>d.Item("ZC_BLOG_HOST")Then
		If Left(d.Item("ZC_BLOG_HOST"),7)<>"http://" And Left(d.Item("ZC_BLOG_HOST"),8)<>"https://" Then
			d.Item("ZC_BLOG_HOST")="http://" & d.Item("ZC_BLOG_HOST")
		End If
		If Right(d.Item("ZC_BLOG_HOST"),1)<>"/" Then
			d.Item("ZC_BLOG_HOST")=d.Item("ZC_BLOG_HOST") & "/"
		End If
		'Call SetBlogHint(Empty,Empty,True)
	End If
	If BlogConfig.Read("ZC_BLOG_TITLE")<>d.Item("ZC_BLOG_TITLE")Then Call SetBlogHint(Empty,Empty,True)
	If BlogConfig.Read("ZC_BLOG_SUBTITLE")<>d.Item("ZC_BLOG_SUBTITLE")Then Call SetBlogHint(Empty,Empty,True)
	'If BlogConfig.Read("ZC_BLOG_NAME")<>d.Item("ZC_BLOG_NAME")Then Call SetBlogHint(Empty,Empty,True)
	'If BlogConfig.Read("ZC_BLOG_SUB_NAME")<>d.Item("ZC_BLOG_SUB_NAME")Then Call SetBlogHint(Empty,Empty,True)

	If BlogConfig.Read("ZC_BLOG_COPYRIGHT")<>d.Item("ZC_BLOG_COPYRIGHT")Then Call SetBlogHint(Empty,Empty,True)
	If BlogConfig.Read("ZC_BLOG_LANGUAGE")<>d.Item("ZC_BLOG_LANGUAGE")Then Call SetBlogHint(Empty,Empty,True)
	If BlogConfig.Read("ZC_BLOG_COPYRIGHT")<>d.Item("ZC_BLOG_COPYRIGHT")Then
		d.Item("ZC_BLOG_COPYRIGHT")=Replace(Replace(d.Item("ZC_BLOG_COPYRIGHT"),vbCr,""),vbLf,"")
		Call SetBlogHint(Empty,Empty,True)
	End If

	If BlogConfig.Read("ZC_COMMENT_TURNOFF")<>d.Item("ZC_COMMENT_TURNOFF")Then Call SetBlogHint(Empty,Empty,True)
	If BlogConfig.Read("ZC_COMMENT_REVERSE_ORDER_EXPORT")<>d.Item("ZC_COMMENT_REVERSE_ORDER_EXPORT")Then Call SetBlogHint(Empty,Empty,True)
	If BlogConfig.Read("ZC_COMMENTS_DISPLAY_COUNT")<>d.Item("ZC_COMMENTS_DISPLAY_COUNT")Then Call SetBlogHint(Empty,Empty,True)

	'If BlogConfig.Read("ZC_BLOG_CLSID")<>d.Item("ZC_BLOG_CLSID")Then
	'	If CheckRegExp(d.Item("ZC_BLOG_CLSID"),"[guid]")=False Then d.Item("ZC_BLOG_CLSID")=RndGuid()
	'	Call SetBlogHint(Empty,Empty,True)
	'End If

	For Each a In d.Keys
		Call BlogConfig.Write(a,d.Item(a))
	Next

	Call BlogConfig.Write("ZC_BLOG_NAME",BlogConfig.Read("ZC_BLOG_TITLE"))
	Call BlogConfig.Write("ZC_BLOG_SUB_NAME",BlogConfig.Read("ZC_BLOG_SUBTITLE"))

	Call SaveConfig2Option()

	Call MakeBlogReBuild_Core()

	SaveSetting=True


End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Post Tag
'*********************************************************
Function PostTag()

	Dim objTag
	Set objTag=New TTag
	objTag.ID=Request.Form("edtID")
	objTag.Name=Request.Form("edtName")
	objTag.Order=Request.Form("edtOrder")
	objTag.Intro=Request.Form("edtIntro")
	objTag.Alias=Request.Form("edtAlias")
	objTag.TemplateName=Request.Form("edtTemplate")

	'接口
	Call Filter_Plugin_PostTag_Core(objTag)

	If objTag.Post Then
		Call GetTagsbyTagIDList("{"&objTag.ID&"}")
		Call ScanTagCount("{"&objTag.ID&"}")
		PostTag=True
		Call Filter_Plugin_PostTag_Succeed(objTag)
	End If
	Set objTag=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：    Del Tag
'*********************************************************
Function DelTag(intID)

	Dim objTag
	Set objTag=New TTag
	objTag.ID=intID

	Call GetTagsbyTagIDList("{"&objTag.ID&"}")

	If objTag.Del Then DelTag=True
	Set objTag=Nothing

End Function
'*********************************************************




'/////////////////////////////////////////////////////////////////////////////////////////
'*********************************************************
' 目的：    Post KeyWord
'*********************************************************
Function PostKeyWord()

End Function
'*********************************************************




'*********************************************************
' 目的：    Del Tag
'*********************************************************
Function DelKeyWord(intID)

End Function
'*********************************************************




'*********************************************************
' 目的：
'*********************************************************
Function PostSiteFile(tpath)
	If Instr(lcase(tpath),"global.asa") then postsitefile=false:exit function
	Dim txaContent
	txaContent=Request.Form("txaContent")

	If IsEmpty(txaContent) Then txaContent=Null

	If Not IsNull(tpath) Then

		If Not IsNull(txaContent) Then

			Call SaveToFile(BlogPath & tpath,txaContent,"utf-8",False)

			PostSiteFile=True

		End IF

	End If


End Function
'*********************************************************




'*********************************************************
' 目的：
'*********************************************************
Function DelSiteFile(tpath)

	Dim Fso
	Set Fso = Createobject("Scripting.Filesystemobject")
	If Fso.FileExists(BlogPath & tpath) Then
		Fso.Deletefile(BlogPath & tpath)
		Set Fso = Nothing

		DelSiteFile=True

		Exit Function
	Else
		Set Fso = Nothing
		Exit Function
	End If

End Function
'*********************************************************




'*********************************************************
' 目的：
'*********************************************************
Function GetRealUrlofTrackBackUrl(intID)



End Function
'*********************************************************



'*********************************************************
' 目的：  审核评论
'*********************************************************
Function AuditComment()

	On Error Resume Next
	Dim i,j
	Dim s,t
	Dim aryArticle()
	s=Request.Form("edtBatch")
	If isEmpty(s) Then s=Request.QueryString("id")
	If s="delall" Then
		objConn.Execute "DELETE FROM [blog_Comment] WHERE [comm_isCheck]<>0"
		AuditComment=True
		Exit Function
	End If
	t=Split(s,",")
	
	ReDim Preserve aryArticle(UBound(t))
	For j=0 To UBound(t)-1
		aryArticle(j)=0
	Next

	Dim objComment
	Dim objArticle
	Dim objRs

	For i=0 To UBound(t)'-1
		If t(i)="" Then Exit For
		Set objComment=New TComment
		If objComment.LoadInfobyID(t(i)) Then
			If objComment.log_ID>0 Then
				Dim objTestArticle
				Set objTestArticle=New TArticle
				If objTestArticle.LoadInfobyID(objComment.log_ID) Then

					For j=0 To UBound(t)
						If aryArticle(j)=0 Then
							aryArticle(j)=objComment.log_ID
						End If
						If aryArticle(j)=objComment.log_ID Then Exit For
					Next

					If Not((objComment.AuthorID=BlogUser.ID) Or (objTestArticle.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
				Else
					Call ShowError(9)
				End If
				Set objTestArticle=Nothing


				Dim allcomm,ii
				If SearchChildComments(t(i),allcomm)=True Then
					For Each ii In allcomm.Keys
						Dim objSubComment
						Set objSubComment=New TComment
						If objSubComment.LoadInfobyID(ii) Then
							objSubComment.isCheck=IIf(objSubComment.isCheck,False,True)
							Call Filter_Plugin_CommentAduit_Core(objSubComment,True)
							objSubComment.Post
						End If
					Next
				End If

			Else

			End If

			DelChild objComment.ID
			objComment.isCheck=IIf(objComment.isCheck,False,True)
			Call Filter_Plugin_CommentAduit_Core(objComment,False)
			objComment.Post

		End If
		Set objComment=Nothing
	Next


	For j=0 To UBound(t)
		If aryArticle(j)>0 Then
			Call BuildArticle(aryArticle(j),False,False)
		End If
	Next

	Call BlogReBuild_Comments
	Call BlogReBuild_Default

	AuditComment=True

End Function
'*********************************************************


'*********************************************************
' 目的：
'*********************************************************
Function DelCommentBatch()
	On Error Resume Next
	Dim i,j
	Dim s,t
	Dim aryArticle()
	s=Request.Form("edtBatch")
	t=Split(s,",")

	ReDim Preserve aryArticle(UBound(t))
	For j=0 To UBound(t)-1
		aryArticle(j)=0
	Next

	Dim objComment
	Dim objArticle
	Dim objRs

	For i=0 To UBound(t)-1
		Set objComment=New TComment
		If objComment.LoadInfobyID(t(i)) Then
			If objComment.log_ID>0 Then
				Dim objTestArticle
				Set objTestArticle=New TArticle
				If objTestArticle.LoadInfobyID(objComment.log_ID) Then

					For j=0 To UBound(t)-1
						If aryArticle(j)=0 Then
							aryArticle(j)=objComment.log_ID
						End If
						If aryArticle(j)=objComment.log_ID Then Exit For
					Next

					If Not((objComment.AuthorID=BlogUser.ID) Or (objTestArticle.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
				Else
					Call ShowError(9)
				End If
				Set objTestArticle=Nothing


				Dim allcomm,ii
				If SearchChildComments(t(i),allcomm)=True Then
					For Each ii In allcomm.Keys
						Dim objSubComment
						Set objSubComment=New TComment
						If objSubComment.LoadInfobyID(ii) Then
							objSubComment.Del
						End If
					Next
				End If

			Else

			End If

			DelChild objComment.ID
			objComment.Del

		End If
		Set objComment=Nothing
	Next


	For j=0 To UBound(t)-1
		If aryArticle(j)>0 Then
			Call BuildArticle(aryArticle(j),False,False)
		End If
	Next

	Call BlogReBuild_Comments
	Call BlogReBuild_Default

	DelCommentBatch=True

End Function
'*********************************************************
'*********************************************************
' 目的：
'*********************************************************
Function DelChild(ID)
	Dim objRs,tmpParentID,tmpID
	Set objRs=objConn.Execute("SELECT comm_ParentID,comm_ID FROM [blog_Comment] WHERE comm_ParentID="&ID)
	Do Until objRS.bof Or objRS.eof
		tmpParentID=clng(objRs("comm_ParentID"))
		tmpID=clng(objRs("comm_ID"))

		If tmpParentID>0 Then
			DelChild(tmpID)
		End If
		objConn.Execute "DELETE FROM [blog_Comment] WHERE comm_ID="&tmpID
		objRS.MoveNext
	Loop
End Function
'*********************************************************

'*********************************************************
' 目的：
'*********************************************************
Function DelTrackBackBatch()

	Dim i,j
	Dim s,t
	Dim aryArticle()
	s=Request.Form("edtBatch")
	t=Split(s,",")

	ReDim Preserve aryArticle(UBound(t))
	For j=0 To UBound(t)-1
		aryArticle(j)=0
	Next

	Dim objTrackBack
	Dim objArticle

	Set objArticle=New TArticle


	For i=0 To UBound(t)-1
		Set objTrackBack=New TTrackBack
		If objTrackBack.LoadInfobyID(t(i)) Then
			Dim objTestArticle
			Set objTestArticle=New TArticle
			If objTestArticle.LoadInfobyID(objTrackBack.log_ID) Then

				For j=0 To UBound(t)-1
					If aryArticle(j)=0 Then
						aryArticle(j)=objTrackBack.log_ID
					End If
					If aryArticle(j)=objTrackBack.log_ID Then Exit For
				Next

				If Not((objTestArticle.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True)) Then Exit Function
			Else
				Call ShowError(9)
			End If
			Set objTestArticle=Nothing
			objTrackBack.Del
		End If
		Set objTrackBack=Nothing
	Next


	For j=0 To UBound(t)-1
		If aryArticle(j)>0 Then
			Call BuildArticle(aryArticle(j),False,False)
		End If
	Next

	BlogReBuild_TrackBacks
	DelTrackBackBatch=True

End Function
'*********************************************************




'*********************************************************
' 目的：     文件删除
'*********************************************************
Function DelFileBatch()

	Dim i,j
	Dim s,t

	s=Request.Form("edtBatch")
	t=Split(s,",")

	Dim objUpLoadFile

	For i=0 To UBound(t)-1
		t(i)=CLng(t(i))
		If t(i)>0 Then
			Set objUpLoadFile=New TUpLoadFile
			If objUpLoadFile.LoadInfoByID(t(i)) Then
				If (objUpLoadFile.AuthorID=BlogUser.ID) Or (CheckRights("Root")=True) Then
					objUpLoadFile.Del
				End If
			Else
				Exit Function
			End If
			Set objUpLoadFile=Nothing
		End If
	Next

	DelFileBatch=True

End Function
'*********************************************************




'*********************************************************
' 目的：    Save Theme Setting
'*********************************************************
Function SaveTheme()

	Dim i,j
	Dim s,t

	Dim strZC_BLOG_CSS
	Dim strZC_BLOG_THEME

	strZC_BLOG_CSS=Request.Form("edtZC_BLOG_CSS")
	strZC_BLOG_THEME=Request.Form("edtZC_BLOG_THEME")

	Call ScanPluginToThemeFile(strZC_BLOG_CSS,strZC_BLOG_THEME)

	If UCase(strZC_BLOG_CSS)<>UCase(CStr(ZC_BLOG_CSS)) Then Call SetBlogHint(Empty,True,Empty)
	If UCase(strZC_BLOG_THEME)<>UCase(CStr(ZC_BLOG_THEME)) Then Call SetBlogHint(Empty,True,True):Call UninstallPlugin(ZC_BLOG_THEME)

	Call BlogConfig.Write("ZC_BLOG_CSS",strZC_BLOG_CSS)

	Call BlogConfig.Write("ZC_BLOG_THEME",strZC_BLOG_THEME)

	Call SaveConfig2Option()

	Call ClearGlobeCache

	SaveTheme=True

End Function
'*********************************************************




'*********************************************************
' 目的：    Save Links
'*********************************************************
Function SaveLink()

	SaveLink=True

End Function
'*********************************************************




'*********************************************************
' 目的：    ActivePlugIn By Name
'*********************************************************
Function ActivePlugInByName(strPluginName)

	Dim s,i,t,b,aryAllXml,strContent
	b=False
	s= ZC_USING_PLUGIN_LIST

	If s="" Then
		s=strPluginName
	Else
		t=Split(ZC_USING_PLUGIN_LIST,"|")
		For i=LBound(t) To UBound(t)
			If UCase(t(i))=UCase(strPluginName) Then
				b=True
			End If
		Next
		If b<>True Then
			s=s & "|" & strPluginName
		End If
	End If
	
	aryAllXml=GetAllXmlPath(s)
	
	If b=False Then
		'走起！	
		'第1步：判断依赖	

		If CheckDependency(ZC_USING_PLUGIN_LIST,strPluginName)=False Then Exit Function
		'第2步：得到所有插件XML文件绝对地址
		
		'第3步：读取所有XML文件
		strContent=CheckConflictReWriteAndToFile(strPluginName,aryAllXml,True)
		If strContent(0)=False Then Exit Function
		'第4步：判断冲突
		'第5步：判断重写
	Else
		strContent=CheckConflictReWriteAndToFile(strPluginName,aryAllXml,False)
	End If

	Dim strZC_USING_PLUGIN_LIST
	
	strZC_USING_PLUGIN_LIST=s

	Call BlogConfig.Write("ZC_USING_PLUGIN_LIST",strZC_USING_PLUGIN_LIST)

	Call SaveConfig2Option()

	Call ScanPluginToIncludeFile(strContent(2))

	Call AddBatch(ZC_MSG202 & strPluginName,"Call InstallPlugin("""&strPluginName&""")")

	ActivePlugInByName=True

End Function
'*********************************************************

'*********************************************************
' 目的：   验证依赖
'*********************************************************
Function CheckDependency(strPluginList,strName)
	CheckDependency=True
	Dim strTemp,sptTemp
	strTemp=UCase("|"&strPluginList&"|") '得到全部启用的插件列表以便InStr
	Dim objXml
	Set objXml=CreateObject("Microsoft.XMLDOM")	
	objXml.async = False
	objXml.ValidateOnParse=False
	objXml.Load(BlogPath & "zb_users\plugin\" & strName & "\plugin.xml")
	sptTemp=Split(UCase(TryToGetAdvanced(objXml,"dependency")),"|")
	Dim i
	Dim NotInstalledPlugin,bolNotInstall
	For i=0 To Ubound(sptTemp)
		If InStr(strTemp,"|"&sptTemp(i)&"|")<=0 Then
			NotInstalledPlugin=NotInstalledPlugin & sptTemp(i) & " "
			bolNotInstall=True
		End If
	Next
	If bolNotInstall Then
		SetBlogHint_Custom ZC_MSG282 & NotInstalledPlugin
		CheckDependency=False
	End If
	Set objXml=Nothing
End Function
'*********************************************************

'*********************************************************
' 目的：   停用时验证依赖
'*********************************************************
Function CheckDependencyDisable(aryPluginList,strPluginName)

	Dim strXmlFile,objXmlFile
	Dim strDependency,strReturnDependency,bolDependency,strInclude,strID
	Dim aryR
	Dim j,i,k
	bolDependency=False
	
	Set objXmlFile=Server.CreateObject("Microsoft.XMLDOM")
	objXmlFile.async = False
	objXmlFile.ValidateOnParse=False
	'Stop
	For j=0 To Ubound(aryPluginList)
		strXmlFile =aryPluginList(j)
		objXmlFile.load(strXmlFile)
		If objXmlFile.readyState=4 Then
			If objXmlFile.parseError.errorCode <> 0 Then
			Else
				strID=objXmlFile.documentElement.selectSingleNode("id").text
				strInclude=objXmlFile.documentElement.selectSingleNode("include").text
				strDependency=Split(UCase(TryToGetAdvanced(objXmlFile,"dependency")),"|")
				If Trim(strInclude)<>"" Then
					If Len(LoadFromFile(BlogPath & "zb_users/plugin/" & strID & "/" & strInclude,"utf-8"))>0 Then
						For i=0 To Ubound(strDependency)
							If strDependency(i)=UCase(strPluginName) Then
								strReturnDependency=strReturnDependency & strID & " "
								i=Ubound(strDependency)+1
								bolDependency=True
							End If
						Next
					End If
				End If
			End If
		End If
	Next
	If bolDependency Then SetBlogHint_Custom ZC_MSG283 & strReturnDependency
	CheckDependencyDisable=Not(bolDependency)
End Function
'*********************************************************

'*********************************************************
' 目的：   得到全部XML地址
'*********************************************************
Function GetAllXmlPath(newZC_USING_PLUGIN_LIST)

	Dim aryPL,i,j,s,t
	aryPL=Split(newZC_USING_PLUGIN_LIST,"|")

	If newZC_USING_PLUGIN_LIST<>"" Then
		i=UBound(aryPL)
	Else
		i=0
		GetAllXmlPath=aryPL
		Exit Function
	End If

	Dim fso, f, f1, fc
	Dim aryXmlFile()
	Redim aryXmlFile(-1)
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set f = fso.GetFolder(BlogPath & "zb_users/plugin/")
	Set fc = f.SubFolders
	For j=0 To i
		If fso.FileExists(BlogPath & "zb_users/plugin/" & aryPL(j) & "/" & "plugin.xml") Then
			If CheckPluginStateByNewValue(aryPL(j),newZC_USING_PLUGIN_LIST) Then
				Redim Preserve aryXmlFile(Ubound(aryXmlFile)+1)
				aryXmlFile(Ubound(aryXmlFile))=BlogPath & "zb_users/plugin/" & aryPL(j) & "/" & "plugin.xml"
			End If
		End If
	Next
	GetAllXmlPath=aryXmlFile
	Set f=Nothing
	Set fso=Nothing
End Function
'*********************************************************

'*********************************************************
' 目的：  兼容老版本Z-BLOG2.0，防止出错
'*********************************************************
Function TryToGetAdvanced(objXml,singleNode)
	On Error Resume Next
	TryToGetAdvanced=""
	TryToGetAdvanced=objXml.documentElement.selectSingleNode("advanced/"&singleNode).text
	Err.Clear
End Function
'*********************************************************


'*********************************************************
' 目的：   验证冲突、重写以及写入文件【好绕口，望天】
'*********************************************************
Function CheckConflictReWriteAndToFile(strPluginName,aryFilePath,bolCheck)
	Dim ReturnArray(2)
	ReturnArray(0)=True  'Conflict
	ReturnArray(1)=True  'ReWrite
	ReturnArray(2)=False 'GetText
	Dim strXmlFile,objXmlFile,aryJoinText,strID,strInclude,strConflict,strRewrite
	Dim thisRewrite,thisConflict
	Dim strResponseConflict,strResponseRewrite
	Dim aryR
	Redim aryJoinText(Ubound(aryFilePath))
	Dim j,i,k
	
	Set objXmlFile=Server.CreateObject("Microsoft.XMLDOM")
	objXmlFile.async = False
	objXmlFile.ValidateOnParse=False
	'先读一遍自己的配置文件得到重写和冲突信息，冲突后面一个一个比对
	If bolCheck Then
		strXmlFile = BlogPath & "zb_users/plugin/" & strPluginName & "/" & "plugin.xml"
		objXmlFile.load(strXmlFile)
		thisRewrite=Split(UCase(TryToGetAdvanced(objXmlFile,"rewritefunctions")),"|")
		thisConflict=Split(UCase(TryToGetAdvanced(objXmlFile,"conflict")),"|")
	End If
	
	'Stop
	For j=0 To Ubound(aryFilePath)
		strXmlFile =aryFilePath(j)
		objXmlFile.load(strXmlFile)
		If objXmlFile.readyState=4 Then
			If objXmlFile.parseError.errorCode <> 0 Then
			Else
				strID=objXmlFile.documentElement.selectSingleNode("id").text
				strInclude=objXmlFile.documentElement.selectSingleNode("include").text
				strRewrite=Split(UCase(TryToGetAdvanced(objXmlFile,"rewritefunctions")),"|")
				strConflict=Split(UCase(TryToGetAdvanced(objXmlFile,"conflict")),"|")
				If Trim(strInclude)<>"" Then
					If Len(LoadFromFile(BlogPath & "zb_users/plugin/" & strID & "/" & strInclude,"utf-8"))>0 Then
						aryJoinText(j)="<!--"&" #include file="""&_
										strID &_
										"/"&_
										strInclude &_
										""" -->"
						If bolCheck Then
							'先判断是否冲突，从两个方面判断。
							'第一步：判断待启用插件是否与该插件冲突——
							For i=0 To Ubound(thisConflict)
								If thisConflict(i)=UCase(strID) Then
									ReturnArray(0)=False
									strResponseConflict=strResponseConflict & strID & " "
								End If
							Next
							'第二步：判断该插件是否与待启用插件冲突——
							For i=0 To Ubound(strConflict)
								If strConflict(i)=UCase(strPluginName) Then
									ReturnArray(0)=False
									If InStr(strResponseConflict,strID)<=0 Then strResponseConflict=strResponseConflict & strID & " "
								End If
							Next
							
							'接着判断重写函数。
							'直接判断待启用插件是否与该插件有重写函数即可，不需要再分两个循环判断
							'不过貌似需要双重循环……？
							
							For i=0 To Ubound(thisRewrite)
								For k=0 To Ubound(strRewrite)
									If thisRewrite(i)=strRewrite(k) And strID<>strPluginName Then
										ReturnArray(1)=False
										If InStr(strResponseRewrite,strRewrite(k))<=0 Then strResponseRewrite=strResponseRewrite & strID & " "
									End If
								Next
							Next
						End If
					End If
				End If
			End If
		End If
	Next
	If ReturnArray(0)=False Then SetBlogHint_Custom(ZC_MSG283 & strResponseConflict)
	If ReturnArray(1)=False And ReturnArray(0)=True Then SetBlogHint_Custom(ZC_MSG285 & strResponseRewrite)
	ReturnArray(2)=Join(aryJoinText,vbCrlf)
	CheckConflictReWriteAndToFile=ReturnArray
End Function
'*********************************************************


'*********************************************************
' 目的：    DisablePlugIn By Name
'*********************************************************
Function DisablePlugInByName(strPluginName)

	Call UninstallPlugin(strPluginName)

	Dim s,i,t

	s=Split(ZC_USING_PLUGIN_LIST,"|")

	For i=LBound(s) To UBound(s)

		If UCase(s(i))<>UCase(strPluginName) Then

			If t="" Then
				t=s(i)
			Else
				t=t & "|" & s(i)
			End If
			
			
		End If

	Next
	
	Dim aryAllXmlPath
	aryAllXmlPath=GetAllXmlPath(t)
	
	If CheckDependencyDisable(aryAllXmlPath,strPluginName)=False Then Exit Function

	Dim strContent
	Dim strZC_USING_PLUGIN_LIST

	strZC_USING_PLUGIN_LIST=t

	Call BlogConfig.Write("ZC_USING_PLUGIN_LIST",strZC_USING_PLUGIN_LIST)

	Call SaveConfig2Option()
	
	t=CheckConflictReWriteAndToFile(strPluginName,aryAllXmlPath,False)(2)
	Call ScanPluginToIncludeFile(t)

	DisablePlugInByName=True

End Function
'*********************************************************




'*********************************************************
' 目的：
'*********************************************************
Function ScanPluginToIncludeFile(s)

	Call SaveToFile(BlogPath & "zb_users/PLUGIN/p_include.asp",s,"utf-8",False)

End Function
'*********************************************************




'*********************************************************
' 目的：
'*********************************************************
Function ScanPluginToThemeFile(newZC_BLOG_CSS,newZC_BLOG_THEME)

	On Error Resume Next

	Dim objXmlFile,strXmlFile,s

	strXmlFile =BlogPath & "zb_users/theme/" & newZC_BLOG_THEME & "/" & "theme.xml"

	Set objXmlFile=Server.CreateObject("Microsoft.XMLDOM")
	objXmlFile.async = False
	objXmlFile.ValidateOnParse=False
	objXmlFile.load(strXmlFile)
	If objXmlFile.readyState=4 Then
		If objXmlFile.parseError.errorCode <> 0 Then
		Else
			If LCase(objXmlFile.documentElement.selectSingleNode("id").text)=LCase(newZC_BLOG_THEME) Then
				Dim fso
				Set fso = CreateObject("Scripting.FileSystemObject")
				If (fso.FileExists(BlogPath & "zb_users/theme/" & objXmlFile.documentElement.selectSingleNode("id").text &"/plugin/" & objXmlFile.documentElement.selectSingleNode("plugin/include").text)) Then
					If Trim(objXmlFile.documentElement.selectSingleNode("plugin/include").text)<>"" Then
						s=s & "<!-- #include file=""../theme/"& objXmlFile.documentElement.selectSingleNode("id").text &"/plugin/"& objXmlFile.documentElement.selectSingleNode("plugin/include").text &""" -->" & vbCrLf
					End If
				End If
			End If
		End If
	End If
	Set objXmlFile=Nothing

	Call SaveToFile(BlogPath & "zb_users/PLUGIN/p_theme.asp",s,"utf-8",False)

	Err.Clear

End Function
'*********************************************************




'*********************************************************
' 目的：
'*********************************************************
Function ScanTagCount(strTags)
'strTags="{1}{2}{3}{4}{5}"
	Dim t,i,s
	Dim objRS,j,k

	If strTags<>"" Then

		s=strTags
		s=Replace(s,"}","")
		t=Split(s,"{")

		For i=LBound(t) To UBound(t)

			If t(i)<>"" Then

				k=t(i)
				Set objRS=objConn.Execute("SELECT COUNT([log_ID]) FROM [blog_Article] WHERE [log_Level]>1 AND [log_Tag] LIKE '%{" & k & "}%'")
				j=objRS(0)
				objConn.Execute("UPDATE [blog_Tag] SET [tag_Count]="&j&" WHERE [tag_ID] =" & k)
				Set objRS=Nothing

			End If

		Next

		s=Join(t,",")
		s=Right(s,Len(s)-1)

		strTags=s

	End If

End Function
'*********************************************************



'*********************************************************
' 目的：
'*********************************************************
Function SortFunction(s)

	Dim t

	t=Split(s,"_")

	Call GetFunction()

	Dim i,j

	j=1

	For i=LBound(t) To UBound(t)-1
		If (IsObject(Functions(t(i)))=True) Then
			Functions(t(i)).Order=j
			j=j+1
			Functions(t(i)).Post()
		End If
	Next

End Function
'*********************************************************




'*********************************************************
' 目的：
'*********************************************************
Function SaveFunction()

	Dim objFunction
	Set objFunction=New TFunction

	If CLng(Request.Form("inpID"))>0 Then objFunction.LoadInfoByID(Request.Form("inpID"))

	objFunction.ID=Request.Form("inpID")
	objFunction.Name=Request.Form("inpName")
	If objFunction.IsSystem=False Then objFunction.FileName=Request.Form("inpFileName")
	If objFunction.IsSystem=False Then objFunction.HtmlID=Request.Form("inpHtmlID")
	If objFunction.IsSystem=False Then objFunction.Ftype=Request.Form("inpFtype")
	objFunction.Order=Request.Form("inpOrder")
	objFunction.MaxLi=Request.Form("inpMaxLi")
	objFunction.SidebarID=Request.Form("inpSidebarID")
	objFunction.Content=Replace(Request.Form("inpContent"),VBCrlf,"")
	objFunction.Meta.SetValue "viewtype",IIf(Request.Form("viewtype")="js","js",IIf(Request.Form("viewtype")="html","html","auto"))

	If Request.Form("inpFileName")="navbar" Then
		Call GetFunction()
		If TransferHTML(objFunction.Content,"[anti-zc_blog_host]")<>Functions(FunctionMetas.GetValue("navbar")).Content Then
			Call SetBlogHint(Empty,Empty,True)
		End If
	End If

	'接口
	'Call Filter_Plugin_SaveFunction_Core(objFunction)

	If objFunction.Post Then

		SaveFunction=True
		'Call Filter_Plugin_SaveFunction_Succeed(objFunction)
	End If
	Set objFunction=Nothing

End Function
'*********************************************************




'*********************************************************
' 目的：
'*********************************************************
Function DelFunction(intID)

	Dim objFunction

	Set objFunction=New TFunction

	If objFunction.LoadInfobyID(intID) Then

		If objFunction.Del Then
			DelFunction=True
		End If

	End If

	Set objFunction=Nothing

End Function
'*********************************************************
%>