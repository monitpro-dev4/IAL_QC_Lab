<#
  API workflow test: the Document Management flow as it works today, over HTTP,
  signed in as a real Chemist, Lab Supervisor, Lab Manager and Employee.
  Covers: add -> supervisor -> manager, reject with comment, revisions at any time
  (older revisions kept as Superseded), latest revision shown in the list, title
  change on revision, self-approval, employee view, newest-first lists.

  Run it against a TEST database only, after Api_Smoke_Test.ps1 (it signs in as
  the admin that test creates):
    $env:ConnectionStrings__Conn = "Server=localhost;Database=IAL_QC_Test;Integrated Security=True;TrustServerCertificate=True;"
    $env:FileSettings__DocumentRoot = "C:\IAL_QC_Files\TestDocuments"
    dotnet run --project ..\IAL_QC_API
    .\Api_Workflow_Test.ps1 -BaseUrl http://localhost:5080
#>
param([string]$BaseUrl = "http://localhost:5080", [string]$AdminUser = "api_admin", [string]$AdminPassword = "Admin@2026")

$ErrorActionPreference = "Stop"
$api = "$BaseUrl/api"
$pass = 0; $fail = 0
function Check($name, $ok, $detail = "") {
    if ($ok) { $script:pass++; Write-Output ("PASS  " + $name + $(if ($detail) { "  ($detail)" })) }
    else     { $script:fail++; Write-Output ("FAIL  " + $name + "  " + $detail) }
}
function Call($method, $path, $token, $body) {
    $h = @{}; if ($token) { $h["Authorization"] = "Bearer $token" }
    try {
        $p = @{ Method = $method; Uri = "$api/$path"; Headers = $h; UseBasicParsing = $true }
        if ($body) { $p.Body = ($body | ConvertTo-Json -Depth 5); $p.ContentType = "application/json" }
        $r = Invoke-WebRequest @p
        return @{ Status = [int]$r.StatusCode; Body = ($r.Content | ConvertFrom-Json); Raw = $r.Content }
    } catch {
        $resp = $_.Exception.Response
        if (-not $resp) { throw }
        $text = (New-Object IO.StreamReader($resp.GetResponseStream())).ReadToEnd()
        return @{ Status = [int]$resp.StatusCode; Body = $(if ($text) { try { $text | ConvertFrom-Json } catch { $null } } else { $null }) }
    }
}
function Form($path, $token, [hashtable]$fields, $filePath) {
    $a = @("-s", "-X", "POST", "-H", "Authorization: Bearer $token", "$api/$path")
    foreach ($k in $fields.Keys) { $a += @("-F", "$k=$($fields[$k])") }
    if ($filePath) { $a += @("-F", "File=@$filePath") }
    (& curl.exe @a) | ConvertFrom-Json
}
function Login($u, $p) { (Call POST "Auth/Login" $null @{ userName = $u; password = $p }).Body }
function List($token, $search, $approvedOnly = $false) {
    @((Call GET ("Document/DocumentList?approvedOnly=" + $approvedOnly.ToString().ToLower() + $(if ($search) { "&search=$search" })) $token).Body)
}
function Submit($token, $versionID) { (Call POST "Document/DocumentVersionSubmit" $token @{ versionID = $versionID; userID = 0 }).Body }
function Decide($token, $versionID, $action, $comments) {
    (Call POST "Document/DocumentVersionApprove" $token @{ versionID = $versionID; action = $action; userID = 0; comments = $comments }).Body
}

$stamp = Get-Date -Format "HHmmss"
$tmp = Join-Path $env:TEMP "ialqc_wf"; New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$f1 = Join-Path $tmp "AC list r1.pdf"; Set-Content -Path $f1 -Value "%PDF-1.4 revision one" -NoNewline
$f2 = Join-Path $tmp "AC list r2.pdf"; Set-Content -Path $f2 -Value "%PDF-1.4 revision two" -NoNewline
$f3 = Join-Path $tmp "AC list r3.pdf"; Set-Content -Path $f3 -Value "%PDF-1.4 revision three" -NoNewline
$f4 = Join-Path $tmp "AC list r4.pdf"; Set-Content -Path $f4 -Value "%PDF-1.4 revision four" -NoNewline

# ---------------- Users: the admin's password is the user's password (no forced change)
$A = (Login $AdminUser $AdminPassword).token
Check "Admin signs in" ([bool]$A)
$rid = @{}; (Call GET "Master/RoleMasterGet" $A).Body | ForEach-Object { $rid[$_.roleName] = $_.roleID }
$people = @(
    @("WF Chemist", "wf_chem$stamp", "Lab Chemist"), @("WF Supervisor", "wf_sup$stamp", "Lab Supervisor"),
    @("WF Manager", "wf_mgr$stamp", "Lab Manager"), @("WF Employee", "wf_emp$stamp", "Employee"))
$tok = @{}
foreach ($p in $people) {
    $r = (Call POST "User/UserInsertUpdate" $A @{ userID = 0; name = $p[0]; employeeID = $p[1]; userName = $p[1]; password = "Pass1234"; roleIDs = "$($rid[$p[2]])" }).Body
    $l = Login $p[1] "Pass1234"
    $tok[$p[2]] = $l.token
    Check "$($p[2]) created and signs in with the admin's password, no forced change" ($r.errorMessage -eq "" -and $l.token -and -not $l.mustChangePassword) $r.errorMessage
}
$C = $tok["Lab Chemist"]; $S = $tok["Lab Supervisor"]; $M = $tok["Lab Manager"]; $E = $tok["Employee"]
Check "Signed-in chemist can open documents straight away" ((Call GET "Document/DocumentList" $C).Status -eq 200)
$users = @((Call GET "User/UsersGet" $A).Body)
Check "Users list: newest first" ($users[0].userName -eq "wf_emp$stamp") $users[0].userName

# ---------------- Add document (no category) -> goes to the supervisor
$num = "WF-$stamp"
$r = Form "Document/DocumentCreate" $C @{ DocumentNumber = $num; Title = "AC list"; RevisionNo = 1; ChangeSummary = "First issue"; UserID = 0 } $f1
Check "Chemist adds a document without a category" ($r.errorMessage -eq "" -and $r.id -gt 0) $r.errorMessage
$doc = $r.id; $v1 = $r.secondID
Check "Sent to the Lab Supervisor" ((Submit $C $v1).errorMessage -eq "")
$row = (List $C $num)[0]
Check "List shows it: rev 1, waiting for supervisor, uploaded by chemist" ($row.revisionNo -eq 1 -and $row.versionStatus -eq "Submitted" -and $row.editedBy -eq "WF Chemist") "$($row.revisionNo) $($row.versionStatus) $($row.editedBy)"
Check "Employee does not see it yet" ((List $E $num).Count -eq 0)
Check "Newest document is first in the list" ((List $C)[0].documentNumber -eq $num) (List $C)[0].documentNumber

# ---------------- Rules
Check "Chemist cannot approve" ((Decide $C $v1 "Approved" "").errorMessage -ne "")
Check "Manager cannot act before the supervisor" ((Decide $M $v1 "Approved" "").errorMessage -like "*Level 1*") (Decide $M $v1 "Approved" "").errorMessage
Check "Reject needs a comment" ((Decide $S $v1 "Rejected" "").errorMessage -like "*Comments*")
Check "Supervisor rejects with a comment" ((Decide $S $v1 "Rejected" "Section 4 missing").errorMessage -eq "")
Check "List shows Rejected" ((List $C $num)[0].versionStatus -eq "Rejected")

# ---------------- Revision after rejection: new revision, title changed, rev 1 kept
$r = Form "Document/DocumentVersionCreate" $C @{ DocumentID = $doc; Title = "AC list - full"; ChangeSummary = "Added section 4" } $f2
Check "Chemist uploads revision 2 with a new title" ($r.errorMessage -eq "" -and $r.id -gt 0) $r.errorMessage
$v2 = $r.id; Submit $C $v2 | Out-Null
$row = (List $C $num)[0]
Check "List shows the latest: rev 2, waiting for supervisor, new title" ($row.revisionNo -eq 2 -and $row.versionStatus -eq "Submitted" -and $row.title -eq "AC list - full") "$($row.revisionNo) $($row.versionStatus) $($row.title)"

# ---------------- Revision while waiting for the manager
Check "Supervisor approves rev 2" ((Decide $S $v2 "Approved" "OK").errorMessage -eq "")
Check "List shows waiting for manager" ((List $C $num)[0].versionStatus -eq "Supervisor Approved")
$r = Form "Document/DocumentVersionCreate" $C @{ DocumentID = $doc; ChangeSummary = "Corrected limits" } $f3
$v3 = $r.id; Submit $C $v3 | Out-Null
$row = (List $C $num)[0]
Check "Revision 3 while waiting: list shows rev 3 back at the supervisor" ($r.errorMessage -eq "" -and $row.revisionNo -eq 3 -and $row.versionStatus -eq "Submitted") "$($r.errorMessage) $($row.revisionNo) $($row.versionStatus)"
Check "Title kept when none is sent" ($row.title -eq "AC list - full") $row.title

# ---------------- Approve rev 3
Check "Supervisor approves rev 3" ((Decide $S $v3 "Approved" "").errorMessage -eq "")
Check "Manager approves rev 3" ((Decide $M $v3 "Approved" "Issue").errorMessage -eq "")
$row = (List $C $num)[0]
Check "List: rev 3 Approved, approved by the manager" ($row.revisionNo -eq 3 -and $row.versionStatus -eq "Approved" -and $row.approvedBy -eq "WF Manager") "$($row.versionStatus) $($row.approvedBy)"
$erow = (List $E $num $true)[0]
Check "Employee now sees rev 3" ($erow.revisionNo -eq 3) $erow.revisionNo

# ---------------- History keeps every upload, files still downloadable
$h = (Call GET "Document/DocumentHistory?documentId=$doc" $C).Body
$st = ($h.versions | Sort-Object revisionNo | ForEach-Object { "$($_.revisionNo):$($_.statusName)" }) -join ", "
Check "All 3 revisions kept (1 and 2 Superseded, 3 Approved)" ($st -eq "1:Superseded, 2:Superseded, 3:Approved") $st
$out = Join-Path $tmp "downloaded.pdf"
$code = & curl.exe -s -o $out -w "%{http_code}" -H "Authorization: Bearer $C" "$api/Document/DocumentDownload?versionId=$v1"
$got = if (Test-Path $out) { Get-Content $out -Raw } else { "" }
Check "Rev 1 file still downloads with its own content" ($code -eq "200" -and $got -eq "%PDF-1.4 revision one") "$code $got"

# ---------------- Revision after approval
$r = Form "Document/DocumentVersionCreate" $C @{ DocumentID = $doc; ChangeSummary = "Yearly review" } $f4
$v4 = $r.id; Submit $C $v4 | Out-Null
$row = (List $C $num)[0]
Check "Rev 4 after approval: list shows rev 4 waiting for supervisor" ($row.revisionNo -eq 4 -and $row.versionStatus -eq "Submitted") "$($row.revisionNo) $($row.versionStatus)"
$erow = (List $E $num $true)[0]
Check "Employee still sees approved rev 3 until rev 4 is approved" ($erow.revisionNo -eq 3 -and $erow.versionStatus -eq "Approved") "$($erow.revisionNo) $($erow.versionStatus)"
$st = ((Call GET "Document/DocumentHistory?documentId=$doc" $C).Body.versions | Where-Object revisionNo -eq 3).statusName
Check "Rev 3 stays Approved while rev 4 waits" ($st -eq "Approved") $st
Check "Chemist (not an approver) cannot approve rev 4" ((Decide $C $v4 "Approved" "").errorMessage -ne "")

# ---------------- Self-approval: a supervisor can approve a revision they uploaded
$r = Form "Document/DocumentVersionCreate" $S @{ DocumentID = $doc; ChangeSummary = "Supervisor update" } $f1
$v5 = $r.id; Submit $S $v5 | Out-Null
$res = Decide $S $v5 "Approved" ""
Check "Supervisor approves own upload" ($res.errorMessage -eq "" -and (List $C $num)[0].versionStatus -eq "Supervisor Approved") $res.errorMessage

Remove-Item $tmp -Recurse -Force
Write-Output ""
Write-Output "RESULT: $pass passed, $fail failed"
if ($fail -gt 0) { exit 1 }
