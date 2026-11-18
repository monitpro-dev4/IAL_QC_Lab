<#
  API smoke test: login + Document Management, over HTTP.
  Run it against an EMPTY TEST database only (it does first-time setup and creates users):
    $env:ConnectionStrings__Conn = "Server=localhost;Database=IAL_QC_Test;Integrated Security=True;TrustServerCertificate=True;"
    $env:FileSettings__DocumentRoot = "C:\IAL_QC_Files\TestDocuments"
    dotnet run --project ..\IAL_QC_API
    .\Api_Smoke_Test.ps1 -BaseUrl http://localhost:5080
#>
param([string]$BaseUrl = "http://localhost:5080")

$ErrorActionPreference = "Stop"
$api = "$BaseUrl/api"
$pass = 0; $fail = 0
function Check($name, $ok, $detail = "") {
    if ($ok) { $script:pass++; Write-Output ("PASS  " + $name + $(if ($detail) { "  ($detail)" })) }
    else     { $script:fail++; Write-Output ("FAIL  " + $name + "  " + $detail) }
}
# Returns @{ Status; Body } and never throws, so 401/403 can be checked
function Call($method, $path, $token, $body) {
    $h = @{}; if ($token) { $h["Authorization"] = "Bearer $token" }
    try {
        $p = @{ Method = $method; Uri = "$api/$path"; Headers = $h; UseBasicParsing = $true }
        if ($body) { $p.Body = ($body | ConvertTo-Json -Depth 5); $p.ContentType = "application/json" }
        $r = Invoke-WebRequest @p
        return @{ Status = [int]$r.StatusCode; Body = ($r.Content | ConvertFrom-Json) }
    } catch {
        $resp = $_.Exception.Response
        if (-not $resp) { throw }
        $text = (New-Object IO.StreamReader($resp.GetResponseStream())).ReadToEnd()
        return @{ Status = [int]$resp.StatusCode; Body = $(if ($text) { $text | ConvertFrom-Json } else { $null }) }
    }
}
function Form($path, $token, [hashtable]$fields, $filePath) {
    $a = @("-s", "-X", "POST", "-H", "Authorization: Bearer $token", "$api/$path")
    foreach ($k in $fields.Keys) { $a += @("-F", "$k=$($fields[$k])") }
    if ($filePath) { $a += @("-F", "File=@$filePath") }
    (& curl.exe @a) | ConvertFrom-Json
}
function Login($u, $p) { (Call POST "Auth/Login" $null @{ userName = $u; password = $p }).Body }

$tmp = Join-Path $env:TEMP "ialqc_smoke"; New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$pdf1 = Join-Path $tmp "Inst Calibration.pdf"; Set-Content -Path $pdf1 -Value "%PDF-1.4 test revision 1" -NoNewline
$pdf2 = Join-Path $tmp "Inst Calibration r2.pdf"; Set-Content -Path $pdf2 -Value "%PDF-1.4 test revision 2" -NoNewline
$bad  = Join-Path $tmp "virus.exe"; Set-Content -Path $bad -Value "MZ" -NoNewline

# ---------------- Setup and login
Check "Setup needed on empty database" ((Call GET "Auth/SetupStatus").Body.needsSetup -eq $true)
$r = Call POST "Auth/Setup" $null @{ name = "Api Admin"; employeeID = "A00"; userName = "api_admin"; password = "" }
Check "Setup rejects empty password" ($r.Body.errorMessage -eq "Password Is Required") $r.Body.errorMessage
$adm = (Call POST "Auth/Setup" $null @{ name = "Api Admin"; employeeID = "A00"; userName = "api_admin"; password = "Admin@2026" }).Body
Check "Setup creates admin and signs in" ($adm.token -and $adm.roles -contains "Administrator" -and -not $adm.mustChangePassword)
$r = Call POST "Auth/Setup" $null @{ name = "X"; employeeID = "X"; userName = "x"; password = "Another1x" }
Check "Setup refused once users exist" ($r.Body.errorMessage -like "Setup Is Already Done*") $r.Body.errorMessage
$A = $adm.token

Check "No token -> 401" ((Call GET "Document/DocumentList").Status -eq 401)
Check "Bad token -> 401" ((Call GET "Document/DocumentList" "not-a-token").Status -eq 401)

$roles = (Call GET "Master/RoleMasterGet" $A).Body; $rid = @{}; $roles | ForEach-Object { $rid[$_.roleName] = $_.roleID }
$sop = ((Call GET "Master/DocumentCategoryGet" $A).Body | Where-Object categoryCode -eq "SOP").categoryID

$r = Call POST "User/UserInsertUpdate" $A @{ userID = 0; name = "No Pwd"; employeeID = "A90"; userName = "nopwd"; roleIDs = "5" }
Check "New user needs a password" ($r.Body.errorMessage -eq "Password Is Required") $r.Body.errorMessage
$ids = @{}
foreach ($u in @(@("Api Chemist","A01","api_chem","Lab Chemist"), @("Api Supervisor","A02","api_sup","Lab Supervisor"), @("Api Manager","A03","api_mgr","Lab Manager"), @("Api Employee","A04","api_emp","Employee"))) {
    $r = Call POST "User/UserInsertUpdate" $A @{ userID = 0; name = $u[0]; employeeID = $u[1]; userName = $u[2]; password = "Temp1234"; roleIDs = "$($rid[$u[3]])" }
    $ids[$u[2]] = $r.Body.id
}
Check "Admin adds 4 users" (($ids.Values | Where-Object { $_ -gt 0 }).Count -eq 4)

$l = Login "api_chem" "Temp1234"
Check "First login: no forced password change" ($l.token -and -not $l.mustChangePassword) 
Check "New user can open pages right away" ((Call GET "Document/DocumentList" $l.token).Status -eq 200)
$r = Call POST "Auth/ChangePassword" $l.token @{ currentPassword = "wrong"; newPassword = "Chem2026x" }
Check "Change password: wrong current refused" ($r.Body.errorMessage -eq "Current Password Is Wrong") $r.Body.errorMessage
$r = Call POST "Auth/ChangePassword" $l.token @{ currentPassword = "Temp1234"; newPassword = "Chem2026x" }
Check "Change password ok" ($r.Body.errorMessage -eq "") $r.Body.errorMessage
$C = $l.token
Check "Same session works after change" ((Call GET "Document/DocumentList" $C).Status -eq 200)
Check "Old password no longer works" ((Login "api_chem" "Temp1234").errorMessage -eq "Invalid Username Or Password")
foreach ($u in "api_sup","api_mgr","api_emp") { $t = (Login $u "Temp1234").token; Call POST "Auth/ChangePassword" $t @{ currentPassword = "Temp1234"; newPassword = "Pass2026x" } | Out-Null }
$S = (Login "api_sup" "Pass2026x").token; $M = (Login "api_mgr" "Pass2026x").token; $E = (Login "api_emp" "Pass2026x").token
$me = (Call GET "Auth/Me" $S).Body
Check "Auth/Me returns user and roles" ($me.userName -eq "api_sup" -and $me.roles -contains "Lab Supervisor")

Check "Unknown user: same message as wrong password" ((Login "ghost" "whatever1").errorMessage -eq "Invalid Username Or Password")
Check "Employee cannot open user admin -> 403" ((Call GET "User/UsersGet" $E).Status -eq 403)
Check "Chemist cannot add categories -> 403" ((Call POST "Master/DocumentCategoryInsertUpdate" $C @{ categoryID = 0; categoryCode = "ZZ"; categoryName = "Hack" }).Status -eq 403)

# ---------------- Documents (user always taken from the token)
$r = Form "Document/DocumentCreate" $C @{ DocumentNumber = "IAL-SOP-123"; Title = "Inst Calibration"; CategoryID = $sop; RevisionNo = 1; UserID = 99999 } $bad
Check "Blocked file type (.exe)" ($r.errorMessage -like "File Type Not Allowed*") $r.errorMessage
$doc = Form "Document/DocumentCreate" $C @{ DocumentNumber = "IAL-SOP-123"; Title = "Inst Calibration"; CategoryID = $sop; RevisionNo = 1; ChangeSummary = "First issue"; UserID = 99999 } $pdf1
Check "Create document (fake UserID in request ignored)" ($doc.id -gt 0 -and $doc.errorMessage -eq "") $doc.errorMessage
$v1 = $doc.secondID
$det = (Call GET "Document/DocumentGetById?documentId=$($doc.id)" $C).Body
Check "Created by the signed-in chemist" ($det.pendingVersion.editedBy -eq "Api Chemist") $det.pendingVersion.editedBy
$r = Form "Document/DocumentCreate" $E @{ DocumentNumber = "IAL-SOP-999"; Title = "x"; CategoryID = $sop } $pdf1
Check "Employee cannot add documents" ($r.errorMessage -eq "You Do Not Have Permission To Add Documents") $r.errorMessage

Call POST "Document/DocumentVersionSubmit" $C @{ versionID = $v1 } | Out-Null
$code = & curl.exe -s -o NUL -w "%{http_code}" -H "Authorization: Bearer $E" "$api/Document/DocumentDownload?versionId=$v1"
Check "Employee cannot open a draft file -> 403" ($code -eq "403") $code
$code = & curl.exe -s -o NUL -w "%{http_code}" "$api/Document/DocumentDownload?versionId=$v1"
Check "Download without token -> 401" ($code -eq "401") $code
$p = (Call GET "Document/DocumentPendingApprovals" $S).Body
Check "Supervisor pending list (from token)" (@($p).Count -eq 1)
Check "Manager blocked at level 1" ((Call POST "Document/DocumentVersionApprove" $M @{ versionID = $v1; action = "Approved" }).Body.errorMessage -like "Only The Lab Supervisor*")
Call POST "Document/DocumentVersionApprove" $S @{ versionID = $v1; action = "Approved"; comments = "OK" } | Out-Null
$r = Call POST "Document/DocumentVersionApprove" $M @{ versionID = $v1; action = "Approved"; comments = "Issue" }
Check "Two approvals" ($r.Body.errorMessage -eq "") $r.Body.errorMessage
$list = (Call GET "Document/DocumentList?approvedOnly=false" $E).Body
Check "Employee sees approved doc (drafts filter ignored)" (@($list).Count -eq 1 -and $list[0].approvedBy -eq "Api Manager")
$out = Join-Path $tmp "dl.pdf"
& curl.exe -s -o $out -H "Authorization: Bearer $E" "$api/Document/DocumentDownload?versionId=$v1"
Check "Employee downloads approved file" ((Get-Content $out -Raw) -eq (Get-Content $pdf1 -Raw))

$nv = Form "Document/DocumentVersionCreate" $C @{ DocumentID = $doc.id; ChangeSummary = "Updated limits"; ReasonForChange = "Yearly review" } $pdf1
Call POST "Document/DocumentVersionSubmit" $C @{ versionID = $nv.id } | Out-Null
Check "Reject needs comments" ((Call POST "Document/DocumentVersionApprove" $S @{ versionID = $nv.id; action = "Rejected" }).Body.errorMessage -eq "Comments Are Required When Rejecting")
Call POST "Document/DocumentVersionApprove" $S @{ versionID = $nv.id; action = "Rejected"; comments = "Wrong file" } | Out-Null
$up = Form "Document/DocumentVersionUpdate" $C @{ VersionID = $nv.id; ChangeSummary = "Correct file" } $pdf2
Check "Re-upload after rejection" ($up.errorMessage -eq "") $up.errorMessage
Call POST "Document/DocumentVersionSubmit" $C @{ versionID = $nv.id } | Out-Null
Call POST "Document/DocumentVersionApprove" $S @{ versionID = $nv.id; action = "Approved" } | Out-Null
Call POST "Document/DocumentVersionApprove" $M @{ versionID = $nv.id; action = "Approved" } | Out-Null
$h = (Call GET "Document/DocumentHistory?documentId=$($doc.id)" $C).Body
Check "Rev 2 current, rev 1 superseded" ((($h.versions | Where-Object revisionNo -eq 2).statusName -eq "Approved") -and (($h.versions | Where-Object revisionNo -eq 1).statusName -eq "Superseded"))
Check "Chemist cannot make obsolete" ((Call POST "Document/DocumentActiveStatusUpdate" $C @{ documentID = $doc.id; isActive = "N" }).Body.errorMessage -like "Only The Lab Manager*")

# ---------------- Sessions
Call POST "Auth/Logout" $E | Out-Null
Check "Token stops working after sign out" ((Call GET "Auth/Me" $E).Status -eq 401)
$r = Call POST "User/UserPasswordReset" $A @{ userID = $ids["api_sup"]; newPassword = "Reset2026x" }
Check "Admin resets password" ($r.Body.errorMessage -eq "") $r.Body.errorMessage
Check "Reset signs the user out everywhere" ((Call GET "Auth/Me" $S).Status -eq 401)
Check "Reset password works with no forced change" ((Login "api_sup" "Reset2026x").mustChangePassword -eq $false)
Call POST "User/UserActiveStatusUpdate" $A @{ userID = $ids["api_mgr"]; isActive = "N" } | Out-Null
Check "Deactivated user's session ends" ((Call GET "Auth/Me" $M).Status -eq 401)
Check "Deactivated user cannot sign in" ((Login "api_mgr" "Pass2026x").errorMessage -eq "Invalid Username Or Password")
Check "Admin cannot deactivate self" ((Call POST "User/UserActiveStatusUpdate" $A @{ userID = $adm.userID; isActive = "N" }).Body.errorMessage -eq "You Cannot Deactivate Yourself")
1..4 | ForEach-Object { Login "api_chem" "wrong-$_" | Out-Null }
$r = Login "api_chem" "wrong-5"
Check "5 wrong passwords lock the account" ($r.errorMessage -like "Too Many Wrong Passwords*") $r.errorMessage
Check "Locked even with the right password" ((Login "api_chem" "Chem2026x").errorMessage -like "Too Many Wrong Passwords*")
Call POST "User/UserPasswordReset" $A @{ userID = $ids["api_chem"]; newPassword = "Unlock2026x" } | Out-Null
Check "Admin reset unlocks" ((Login "api_chem" "Unlock2026x").token -ne "")

Write-Output ""
Write-Output "RESULT: $pass passed, $fail failed"
