<#2022-3-28
.Synopsis
   compare-file script borrowed/updated from Lee Holmes' website referenced in description - thanks Lee Holmes!
.DESCRIPTION
   https://www.leeholmes.com/using-powershell-to-compare-diff-files/
.EXAMPLE
    compare-file -file_1 .\b4_cim.xml -file_2 .\b4_gps.xml -report .
 [Output]
    WARNING: File compare between b4_cim.xml / b4_gps.xml are identical! Exiting script.
.EXAMPLE
   compare-file -file_1 C:\Temp\zzDEL1\zzGSV_del\zzDelete1.txt -file_2 C:\Temp\zzDEL1\zzGSV_del\zzDelete2.txt -report $env:TEMP
 [Output]
    REPORT location set!
    comparing file contents for zzDelete1.txt and zzDelete2.txt...
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   If script becomes corrupt, reference above link and copy/paste back-in an approved ISE and re-save.
   During script execution, each file that are being compared against, are examined for total lines in each document and even 
   the NULL valued lines are counted in the file
.COMPONENT
   The component this cmdlet belongs to the R1 RDW System Administrator Jeff Giese
.ROLE
   The role this cmdlet belongs to the R1 RDW System Administrator Jeff Giese
.FUNCTIONALITY
   Great tool to compare files/configurations/settings/etc to point-out delta's as-well-as matching lines.
   Final version was saved on 2021-7-29
#>
#2022-3-29
#WORKING on the search pattern section - testing to see if i can look thru 2 documents looking for key words/search pattern(s)
#should i add the account executing the script to the HT section?
#
function compare-file{
    param(
        [Parameter(Mandatory=$false)]
        [string]$file_1="",
        [string]$file_2="",
#ADD MORE PARAMS???
# Default directories?
# A
# B
#REMOVE PATTERN? I NEVER USED IT AND IT'S NOT CALLED/USED IN THE SCRIPT...        
    ## The pattern (if any) to use as a filter for file
    ## differences
#        [string]$pattern = ".*",
        [string]$report = ""
)

$Date = Get-Date
$HourMinDATE = $Date.ToString("HH" + "mm" + "__yyyy_MM_dd")
$match_HT_1 = [ordered]@{}
$match_HT_2 = [ordered]@{}
# testing - comment out/remove on final version!    
## $report = "C:\Users\VHAV20GIESEJ\CO__Work-Change-Orders\CDW_CO\2022\TMS_AD-Group_POC_Listing__2022-3-1\source_files"
$reportSTART = [datetime]::Now
####$reportEND = [datetime]::Now
$server = $env:COMPUTERNAME

if([string]::IsNullOrWhiteSpace($report)){
    write-warning "Report location is not set! Setting report location to Windows users' temporary profile location ('$env:temp')`
    NOTE - files stored in this location cannot be retrieved after system restart, and if report is needed re-do script and set `
    the report location!"
    $report_b4 = ""
    $report_b4 = $($pwd.Path)
    push-location
    $report = ""
    $report = $($env:temp)
    $report_set = $false
}
else{
    write "REPORT location set!"
    $report_set = $true
}

$content_1 = gc $file_1
$content_2 = gc $file_2
$file_name_1 = $($content_1.pschildname) | select -Unique
$file_name_2 = $($content_2.pschildname) | select -Unique
$file_path_1 = $content_1.pspath | select -Unique
$file_path_2 = $content_2.pspath | select -Unique
##$pattern = ".*" #PATTERN MAY BE THE FIRST TO GO, DON'T THINK IT'S USED AND I'M COMMENTING OUT FOR NOW AND IF NO ADVERSE EFFECTS IT WILL BE REMOVED
#ON THE FINAL SCRIPT!
# testing     $report = ""

#quick check
####$reportSTART
$file_hash_1 = Get-FileHash $($content_1.pspath) | select -Unique | select -ExpandProperty hash
$file_hash_2 = Get-FileHash $($content_2.pspath) | select -Unique | select -ExpandProperty hash
####$reportEND

sl $report

$file_HT = [ordered]@{}
$file_HT.Clear()

$file_HT += @{
    DateTimeOf_Report = $reportSTART
    ComputerName = $server
    AD_UserAccount = ($env:USERDOMAIN + "\" + $env:USERNAME)
#file line count info:
    File_LineCount_1 = $content_1.Count
    File_LineCount_2 = $content_2.Count
#file path info:
    File_Location_1 = $content_1.pspath | select -Unique
    File_Location_2 = $content_2.pspath | select -Unique
#file name info:
    File_Name_1 = $content_1.pschildname | select -Unique
    File_Name_2 = $content_2.pschildname | select -Unique
#file hash info:
    File_Hash_1_SHA256 = $file_hash_1
    File_Hash_2_SHA256 = $file_hash_2
#search pattern:
##    search_pattern = $pattern  #COMMENTING OUT SEARCH PATTERN, TBD IF NEEDED OR NOT AND MAY BE REMOVED FROM THE FINAL VERSION OF THE SCRIPT.
}


#HT set to known values to be used on final report (if report location set)
$file_ht.GetEnumerator() | select name,value | sort name | ConvertTo-Csv -NoTypeInformation | Out-File $report\compare_delta.csv -Force

if($file_hash_1 -eq $file_hash_2){

    Write-Warning "File compare between $($file_name_1) / $($file_name_2) are identical! Exiting script."
    
    $file_ht += @{
        ("File_Hash_1_SHA256" + "_" + $("$file_hash_1")) = ("File_Hash_2_SHA256" + "_" + $("$file_hash_2"))
    }

    write-output "File compare between $($file_name_1) / $($file_name_2) are identical! Exiting script." | Out-File $report\compare_delta.csv -Append
    move-item $report\compare_delta.csv ("compare_" + "$($file_name_1.split(".")[0])" + "-" + "$($file_name_2.split(".")[0])" + "_" + "$($HourMinDATE)" + ".csv")
    Pop-Location
    break
}
else{
    Write "comparing file contents for $($file_name_1) and $($file_name_2)..."
    sleep 1
}

#file1/2 matches:
Compare-Object $content_1 $content_2 -IncludeEqual -ExcludeDifferent | select sideindicator,{$_.inputobject.readcount},inputobject | sort inputobject,{[int] $_.inputobject.readcount},sideindicator | select @{n="File_1_LineNUM_Match";e={$_.InputObject.ReadCount}}, @{n="Matching_Entry";e={$_.InputObject}} | ConvertTo-Csv -NoTypeInformation | out-file $report\MATCH_file1.csv -Force
#file2/1 matches:
Compare-Object $content_2 $content_1 -IncludeEqual -ExcludeDifferent | select sideindicator,{$_.inputobject.readcount},inputobject | sort inputobject,{[int] $_.inputobject.readcount},sideindicator | select @{n="File_2_LineNUM_Match";e={$_.InputObject.ReadCount}}, @{n="Matching_Entry";e={$_.InputObject}}  | ConvertTo-Csv -NoTypeInformation | out-file $report\MATCH_file2.csv -Force
$COMP = Compare-Object $content_1 $content_2 -IncludeEqual | select sideindicator,{[int]$_.inputobject.readcount},inputobject | sort {[int]$_.inputobject.readcount},inputobject
#show matching entries to the screen
$COMP | ?{$_.sideindicator -eq "=="} | select sideindicator,inputobject | sort inputobject

$file_1_MATCH = import-csv .\MATCH_file1.csv
$file_2_MATCH = Import-Csv .\MATCH_file2.csv

$match_HT_1 = [ordered]@{}
$match_HT_2 = [ordered]@{}

#since i'm dealing with matching values and i know both file1/file2 have the same # of entries i put them both in the same for loop (no luck with getting the foreach loop to work)
for($i=0;$i -lt $file_1_MATCH.Count;$i++){
    $match_HT_1 += @{
        $file_1_Match.file_1_LineNUM_Match[$i] = $file_1_MATCH.Matching_Entry[$i]
    }
    $match_HT_2 += @{
        $file_2_Match.file_2_LineNUM_Match[$i] = $file_2_MATCH.Matching_Entry[$i]
    }
}

$MATCH_COMBINED = [ordered]@{}

for($i=0;$i -lt $match_HT_1.Count;$i++){

if($match_HT_1[$i] -eq $match_HT_2[$i]){
    $MATCH_COMBINED += @{
        (($file_1_MATCH.File_1_LineNUM_Match[$i]) + "_" + $($file_HT.File_Name_1.Split(".")[0]) + "__" + ($file_2_MATCH.File_2_LineNUM_Match[$i]) + "_" + "$($file_HT.File_Name_2.Split(".")[0])" + "__EQUAL") = ($file_1_MATCH.Matching_Entry[$i])
    }
}
else{
    Write-Warning "no match `n
    $match_HT_1.Values[$i] = $match_HT_2.Values[$i]"
    read-host
    }
}

$MATCH_COMBINED.GetEnumerator() | select key,value | sort value | ConvertTo-Csv -NoTypeInformation | Out-File $report\MATCH_REPORT.csv -Force


$file_HT += @{
    EndOf_Report_TS = [datetime]::Now
}

$file_HT_SORT_BEGINNING = [ordered]@{}
$file_HT_SORT_BEGINNING.Clear()
$file_HT_SORT_BEGINNING = $($file_HT.GetEnumerator() | select name,value | sort name)

$file_HT_SORT_END = [ordered]@{}
$file_HT_SORT_END.Clear()

$file_MATCH = import-csv MATCH_REPORT.csv
for($i=0;$i -lt $file_MATCH.Count;$i++){
    $file_HT_SORT_END += @{
        $file_MATCH.Key[$i] = $file_MATCH.Value[$i]
    }
}

#Captures the HT info for just FYI purposes:
$file_HT_SORT_BEGINNING.GetEnumerator() | select name,value | ConvertTo-Csv -NoTypeInformation | Out-File $report\_REPORT1.csv -Force -Verbose
#File sorted kept so if another sort is needed it can be done
$file_HT_SORT_END.GetEnumerator() | select name,value | ConvertTo-Csv -NoTypeInformation | Out-File $report\_REPORT2.csv -Force -Verbose

$Final_Report_BEGIN = import-csv $report\_REPORT1.csv
$Final_Report_END = import-csv $report\_REPORT2.csv
$Final_Report = $Final_Report_BEGIN + $Final_Report_END
$Final_Report | ConvertTo-Csv -NoTypeInformation | Out-File $report\compare_delta.csv -Force

sleep -Milliseconds 200
copy-item $report\compare_delta.csv ("compare_" + "$($file_name_1.split(".")[0])" + "-" + "$($file_name_2.split(".")[0])" + "_" + "$([datetime]::Now.ToString("HH" + "mm" + "__yyyy_MM_dd"))" + ".csv")

#clean-up
ri ("_REPORT1.csv","_REPORT2.csv","compare_delta.csv","MATCH_file1.csv","MATCH_file2.csv","MATCH_REPORT.csv") -Verbose

if($report_set -eq $true){
    ii $report
}
elseif($report -eq $null){
    write-warning "Ye old 'report path' was set to NULL! this indicates the user doesn't want the report and the following files will be removed:"
    Read-Host "Press Enter/Return to remove the following files: _REPORT1.csv/_REPORT2.csv/compare_delta.csv/MATCH_file1.csv/MATCH_file2.csv/MATCH_REPORT.csv"
    ri ("_REPORT1.csv","_REPORT2.csv","compare_delta.csv","MATCH_file1.csv","MATCH_file2.csv","MATCH_REPORT.csv") -Verbose
}
else{
    sl $report_b4
    pop-location
    continue
}
}
