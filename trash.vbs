' 把文件/文件夹移到 Windows 回收站
'
' 为什么需要它：
'   nvim-tree 的「移到回收站」依赖外部命令 trash，Windows 上默认没有
'   （那命令是 Linux/macOS 的）。这里用 Windows 自带的 COM 组件完成，
'   不需要安装任何东西，文件会进系统回收站，可在资源管理器里还原。
'
' 被谁调用：
'   lua/plugins/nvim-tree.lua 里的
'     trash = { cmd = "cscript.exe //nologo <本文件路径>" }
'   nvim-tree 会在命令后追加【用 shellescape 转义过的绝对路径】，
'   所以这里用 WScript.Arguments 接收。
'
' 退出码：0 = 全部成功；1 = 有失败（nvim-tree 会弹警告）
'
' 调试：设环境变量 NVIM_TRASH_LOG 为一个文件路径，脚本会把处理过程写进去

Option Explicit

Dim fso, shell, args, i, target, failed, logPath, logFile, useLog
Set fso = CreateObject("Scripting.FileSystemObject")
Set shell = CreateObject("Shell.Application")
Set args = WScript.Arguments

' 可选日志
useLog = False
logPath = CreateObject("WScript.Shell").ExpandEnvironmentStrings("%NVIM_TRASH_LOG%")
If logPath <> "" And logPath <> "%NVIM_TRASH_LOG%" Then
  useLog = True
  Set logFile = fso.CreateTextFile(logPath, True)
  logFile.WriteLine "参数个数: " & args.Count
End If

Sub Log(msg)
  If useLog Then logFile.WriteLine msg
End Sub

If args.Count = 0 Then
  If useLog Then logFile.Close
  WScript.Quit 0
End If

failed = 0

For i = 0 To args.Count - 1
  target = args(i)
  Log "--- 第 " & (i + 1) & " 个 ---"
  Log "原始参数: [" & target & "]"

  ' Neovim 传的是正斜杠路径（C:/Users/...），
  ' 而 FileExists / FolderExists 不认正斜杠，先换回反斜杠
  target = Replace(target, "/", "\")
  Log "换斜杠后: [" & target & "]"

  ' 防御：万一引号被带进来（"C:\path"），剥掉
  If Len(target) >= 2 Then
    If Left(target, 1) = """" Then target = Mid(target, 2)
    If Right(target, 1) = """" Then target = Left(target, Len(target) - 1)
  End If
  Log "剥引号后: [" & target & "]"

  If fso.FileExists(target) Or fso.FolderExists(target) Then
    Log "  存在性检查: 通过"
    On Error Resume Next
    Dim item
    Set item = shell.Namespace(0).ParseName(target)
    Log "  ParseName 错误码 = " & Err.Number
    If Err.Number = 0 And Not (item Is Nothing) Then
      Log "  item.Name = " & item.Name
      item.InvokeVerb "delete"
      Log "  InvokeVerb 错误码 = " & Err.Number
      If Err.Number = 0 Then
        Log "  结果: 成功"
      Else
        Log "  结果: InvokeVerb 失败 - " & Err.Description
        failed = failed + 1
      End If
    Else
      Log "  结果: ParseName 失败 - " & Err.Description
      failed = failed + 1
    End If
    Err.Clear
    On Error GoTo 0
  Else
    Log "  存在性检查: 不通过（文件不存在？）"
    failed = failed + 1
  End If
Next

If useLog Then
  logFile.WriteLine "失败数: " & failed
  logFile.Close
End If

If failed > 0 Then
  WScript.Quit 1
End If
WScript.Quit 0
