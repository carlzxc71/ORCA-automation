$outputPath = "C:\Temp\ORCA"
if (!(Test-Path -Path $outputPath)) {
    New-Item -Path $outputPath -ItemType Directory
}

$content = Invoke-ORCA -Output HTML -OutputOptions @{HTML=@{OutputDirectory=$outputPath}} 

$content.result