Option Explicit
Dim sh, fso, base, app, log, py, execObj, out, lines, i, candidate, cmd
Set sh = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
base = fso.GetParentFolderName(WScript.ScriptFullName)
app = base & "\app.py"
log = base & "\server.log"
sh.CurrentDirectory = base

' If the server is already running, do nothing.
On Error Resume Next
Set execObj = sh.Exec("cmd.exe /d /c powershell -NoProfile -Command ""try { $c=New-Object Net.Sockets.TcpClient; $c.Connect('127.0.0.1',5000); $c.Close(); exit 0 } catch { exit 1 }""")
execObj.StdOut.ReadAll
execObj.StdErr.ReadAll
If Err.Number = 0 Then
    If execObj.ExitCode = 0 Then WScript.Quit 0
End If
Err.Clear
On Error GoTo 0

' IMPORTANT: resolve the same Python executable that works from CMD.
' Do not use the Python Launcher (py), and avoid WindowsApps placeholder paths.
py = ""
On Error Resume Next
Set execObj = sh.Exec("cmd.exe /d /c python.exe -c ""import sys; print(sys.executable)""")
out = execObj.StdOut.ReadAll
On Error GoTo 0
If Len(out) > 0 Then
    lines = Split(Replace(out, vbCr, ""), vbLf)
    For i = 0 To UBound(lines)
        candidate = Trim(lines(i))
        If Len(candidate) > 0 Then
            If fso.FileExists(candidate) Then
                py = candidate
                Exit For
            End If
        End If
    Next
End If

' Fallback to PATH lookup if the Python command could not report sys.executable.
If Len(py) = 0 Then
    On Error Resume Next
    Set execObj = sh.Exec("cmd.exe /d /c where.exe python.exe")
    out = execObj.StdOut.ReadAll
    On Error GoTo 0
    If Len(out) > 0 Then
        lines = Split(Replace(out, vbCr, ""), vbLf)
        For i = 0 To UBound(lines)
            candidate = Trim(lines(i))
            If Len(candidate) > 0 Then
                If fso.FileExists(candidate) Then
                    ' Ignore the Microsoft Store WindowsApps shim when possible.
                    If InStr(1, candidate, "\WindowsApps\", vbTextCompare) = 0 Then
                        py = candidate
                        Exit For
                    End If
                End If
            End If
        Next
    End If
End If

' Common per-user/system installations.
If Len(py) = 0 Then
    candidate = sh.ExpandEnvironmentStrings("%LocalAppData%") & "\Programs\Python\Python313\python.exe"
    If fso.FileExists(candidate) Then py = candidate
End If
If Len(py) = 0 Then
    candidate = sh.ExpandEnvironmentStrings("%LocalAppData%") & "\Programs\Python\Python312\python.exe"
    If fso.FileExists(candidate) Then py = candidate
End If
If Len(py) = 0 Then
    candidate = sh.ExpandEnvironmentStrings("%LocalAppData%") & "\Programs\Python\Python311\python.exe"
    If fso.FileExists(candidate) Then py = candidate
End If
If Len(py) = 0 Then
    candidate = "C:\Program Files\Python313\python.exe"
    If fso.FileExists(candidate) Then py = candidate
End If
If Len(py) = 0 Then
    candidate = "C:\Program Files\Python312\python.exe"
    If fso.FileExists(candidate) Then py = candidate
End If

If Len(py) = 0 Then
    Dim stamp
    stamp = Now
    Dim tf
    Set tf = fso.OpenTextFile(log, 8, True)
    tf.WriteLine CStr(stamp) & " - ERROR: Could not locate a usable python.exe."
    tf.Close
    WScript.Quit 2
End If

' Run the exact Python executable with no visible console window.
' Output is redirected to server.log for troubleshooting.
cmd = "cmd.exe /d /c " & Chr(34) & Chr(34) & py & Chr(34) & " " & Chr(34) & app & Chr(34) & " > " & Chr(34) & log & Chr(34) & " 2>&1" & Chr(34)
sh.Run cmd, 0, False
Set sh = Nothing
