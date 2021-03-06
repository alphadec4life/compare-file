<#
.Synopsis
   compare-file script borrowed/taken from Lee Holmes' website referenced in description - thanks Lee Holmes!
.DESCRIPTION
   https://www.leeholmes.com/using-powershell-to-compare-diff-files/
.EXAMPLE
    compare-file -file_1 .\b4_cim.xml -file_2 .\b4_gps.xml -report .
 [Output]
    WARNING: File compare between b4_cim.xml / b4_gps.xml are identical! Exiting script.
.EXAMPLE
   compare-file -file_1 C:\Temp\zzDEL1\zzGSV_del\zzDelete1.txt -file_2 C:\Temp\zzDEL1\zzGSV_del\zzDelete2.txt -report $env:TEMP
.INPUTS
   Inputs to this cmdlet (if any)
.OUTPUTS
   Output from this cmdlet (if any)
.NOTES
   If script becomes corrupt, reference above link and copy/paste back-in an approved ISE and re-save.
.COMPONENT
   The component this cmdlet belongs to the R1 RDW System Administrator Jeff Giese
.ROLE
   The role this cmdlet belongs to the R1 RDW System Administrator Jeff Giese
.FUNCTIONALITY
   Great tool to compare files/configurations/settings/etc to point-out delta's as-well-as matching lines.
   Final version was saved on 2021-7-15
#>

function compare-file{
    param(
        [string]$file_1="",
        [string]$file_2="",

    ## The pattern (if any) to use as a filter for file
    ## differences
    ##    [string]$pattern = ".*",
        [string]$report = ""
)


$Date = Get-Date
$HourMinDATE = $Date.ToString("HH" + "mm" + "__yyyy_MM_dd")
# testing     $report = "C:\users\VHAV20GIESEJ\_script\compare_file\_files"  used for testing purposes before function was complete
$server = $env:COMPUTERNAME

if($report -eq $null){
    $report = "$($env:temp)"
}

sl $report

#file/file name/content/location/search pattern
# note, when testing i populated the below vars but once the param was in place the vars would be overwriten. 
# testing     $file_1 = ""
    #testing  $file_1 = "C:\users\VHAV20GIESEJ\_script\compare_file\_files\file4.txt"
# testing     $file_2 = ""
    #testing  $file_2 = "C:\users\VHAV20GIESEJ\_script\compare_file\_files\file5.txt"
$content_1 = gc $file_1
$content_2 = gc $file_2
$file_name_1 = $($content_1.pschildname) | select -Unique
$file_name_2 = $($content_2.pschildname) | select -Unique
$file_path_1 = $content_1.pspath | select -Unique
$file_path_2 = $content_2.pspath | select -Unique
$pattern = ".*"
# testing     $report = ""

#quick check
$file_hash_1 = Get-FileHash $($content_1.pspath) | select -Unique | select -ExpandProperty hash
$file_hash_2 = Get-FileHash $($content_2.pspath) | select -Unique | select -ExpandProperty hash

$file_HT = [ordered]@{}
$file_HT.Clear()

$file_HT += @{
    DateTimeOf_Report = $Date
    ComputerName = $server
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
    search_pattern = $pattern
}

$file_ht.GetEnumerator() | select name,value | sort name | ConvertTo-Csv -NoTypeInformation | Out-File $report\compare_delta.csv -Force

if($file_hash_1 -eq $file_hash_2){
    Write-Warning "File compare between $($file_name_1) / $($file_name_2) are identical! Exiting script."
    
    $file_ht += @{
        ("File_Hash_1_SHA256" + "_" + $("$file_hash_1")) = ("File_Hash_2_SHA256" + "_" + $("$file_hash_2"))
    }

    write-output "File compare between $($file_name_1) / $($file_name_2) are identical! Exiting script." | Out-File $report\compare_delta.csv -Append
    move-item $report\compare_delta.csv ("compare_" + "$($file_name_1.split(".")[0])" + "-" + "$($file_name_2.split(".")[0])" + "_" + "$($HourMinDATE)" + ".csv")
    break
}
else{
    Write "comparing file contents for $($file_name_1) and $($file_name_2)..."
    sleep 1
    cls
}

## Compare the two files. Get-Content annotates output objects with
## a 'ReadCount' property that represents the line number in the file
## that the text came from.

#to display delta's and equals between 2 files:    Compare-Object $content_1 $content_2 -IncludeEqual | %{$psitem} | select sideindicator,inputobject | select sideindicator, {$_.InputObject.ReadCount},inputobject #| ConvertTo-Csv -NoTypeInformation | Out-File $report\compare_delta.csv -Force
#Compare-Object $content_1 $content_2 | %{$_} | select sideindicator,inputobject | select @{name="file1_<=delta=>_file2:";e={$_.sideindicator}},@{name="delta_@_line_#:";e={$_.InputObject.ReadCount}},@{name="delta:";e={$_.inputobject}} | ConvertTo-Csv -NoTypeInformation | Out-File $report\compare_delta.csv -Force
Compare-Object $content_1 $content_2 -IncludeEqual | %{$_} | select sideindicator,inputobject | select @{name="file1_<=delta=>_file2:";e={$_.sideindicator}},@{name="delta_@_line_#:";e={$_.InputObject.ReadCount}},@{name="delta:";e={$_.inputobject}} | ConvertTo-Csv -NoTypeInformation | Out-File $report\compare_delta.csv -Force
$delta_csv = import-csv $report\compare_delta.csv

for($i=0;$i -lt $delta_csv.Count;$i++){

    if($($delta_csv."file1_<=delta=>_file2:"[$i]) -eq "=>"){
        Write-Warning "delta on $($file_2) @ line $($delta_csv."delta_@_line_#:"[$i]), delta =  $($delta_csv."delta:"[$i])"

        $file_HT += @{
            ($($delta_csv."delta_@_line_#:"[$i]) + "_" + "line_item_delta_on__" + "$($file_Name_2)") = $($delta_csv."delta:"[$i])
        }
    }
    elseif($($delta_csv."file1_<=delta=>_file2:"[$i]) -eq "<="){
        write-warning "delta on $($file_1) @ line $($delta_csv."delta_@_line_#:"[$i]), delta =  $($delta_csv."delta:"[$i])"

        $file_HT += @{
            ($($delta_csv."delta_@_line_#:"[$i]) + "_" + "line_item_delta_on__" + "$($file_Name_1)") = $($delta_csv."delta:"[$i])
        }
    }
    else{
        $file_HT += @{
            ($($delta_csv."delta_@_line_#:"[$i]) + "_" + "is_EQUAL_on_both_files" + "_at_line_") = $($delta_csv."delta:"[$i])
        }
    }
}


$file_ht.GetEnumerator() | select name,value | ConvertTo-Csv -NoTypeInformation | Out-File $report\compare_delta.csv -Force
move-item $report\compare_delta.csv ("compare_" + "$($file_name_1.split(".")[0])" + "-" + "$($file_name_2.split(".")[0])" + "_" + "$($HourMinDATE)" + ".csv")

ii $report

}
