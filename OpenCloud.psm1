function Find-OpenCloudItem {
    [OutputType([System.Xml.XmlDocument])]
    param (
        [Alias("OpenCloudUrl")] [ValidateNotNullOrWhiteSpace()] [string]$url,
        [Alias("ItemPath")] [ValidateNotNullOrWhiteSpace()] [string]$path,
        [Alias("UserId")] [ValidateNotNullOrWhiteSpace()] [string]$id,
        [Alias("UserPassword")] [ValidateNotNullOrWhiteSpace()] [string]$pass,
        [Alias("SpaceId")] [string]$space,
        [Alias("BaseItemOnly")] [switch]$base,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        $rest = @{
            Uri = $space ? "$url/dav/spaces/$space/$path" : "$url/remote.php/dav/files/$id/$path"
            Headers = @{ Depth = $base ? 0 : 1 }
            CustomMethod = "PROPFIND"
            Authentication = "Basic"
            Credential = [PSCredential]::new($id, (ConvertTo-SecureString $pass -AsPlainText -Force))
        }
        return Invoke-RestMethod @rest
    }
    catch { if ($silent) { return $null } else { throw } }
}

function Get-OpenCloudItem {
    [OutputType([System.IO.FileInfo])]
    param (
        [Alias("OpenCloudUrl")] [ValidateNotNullOrWhiteSpace()] [string]$url,
        [Alias("ItemPath")] [ValidateNotNullOrWhiteSpace()] [string]$path,
        [Alias("DownloadPath")] [ValidateNotNullOrWhiteSpace()] [string]$destination,
        [Alias("UserId")] [ValidateNotNullOrWhiteSpace()] [string]$id,
        [Alias("UserPassword")] [ValidateNotNullOrWhiteSpace()] [string]$pass,
        [Alias("SpaceId")] [string]$space,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        $rest = @{
            Uri = $space ? "$url/dav/spaces/$space/$path" : "$url/remote.php/dav/files/$id/$path"
            Method = "Get"
            Authentication = "Basic"
            Credential = [PSCredential]::new($id, (ConvertTo-SecureString $pass -AsPlainText -Force))
            OutFile = $destination
        }
        Invoke-RestMethod @rest | Out-Null
        if (Test-Path -Path $destination -PathType Leaf -ErrorAction Stop) { return Get-Item -Path $destination -ErrorAction Stop }
        else { return Get-ChildItem -Path $destination -ErrorAction Stop | Sort-Object -Property LastWriteTime, CreationTime -Descending | Select-Object -First 1 }
    }
    catch { if ($silent) { return $null } else { throw } }
}

function Set-OpenCloudItem {
    [OutputType([bool])]
    param (
        [Alias("OpenCloudUrl")] [ValidateNotNullOrWhiteSpace()] [string]$url,
        [Alias("ItemPath")] [ValidateNotNullOrWhiteSpace()] [string]$path,
        [Alias("UploadPath")] [ValidateNotNullOrWhiteSpace()] [string]$source,
        [Alias("UserId")] [ValidateNotNullOrWhiteSpace()] [string]$id,
        [Alias("UserPassword")] [ValidateNotNullOrWhiteSpace()] [string]$pass,
        [Alias("SpaceId")] [string]$space,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        $rest = @{
            Uri = $space ? "$url/dav/spaces/$space/$path" : "$url/remote.php/dav/files/$id/$path"
            Method = "Put"
            Authentication = "Basic"
            Credential = [PSCredential]::new($id, (ConvertTo-SecureString $pass -AsPlainText -Force))
            InFile = $source
        }
        Invoke-RestMethod @rest | Out-Null
        return $true
    }
    catch { if ($silent) { return $false } else { throw } }
}

function Set-OpenCloudDirectory {
    [OutputType([bool])]
    param (
        [Alias("OpenCloudUrl")] [ValidateNotNullOrWhiteSpace()] [string]$url,
        [Alias("DirectoryPath")] [ValidateNotNullOrWhiteSpace()] [string]$path,
        [Alias("UserId")] [ValidateNotNullOrWhiteSpace()] [string]$id,
        [Alias("UserPassword")] [ValidateNotNullOrWhiteSpace()] [string]$pass,
        [Alias("SpaceId")] [string]$space,
        [Alias("OnErrorContinue")] [switch]$silent
    )
    try {
        if (!(Find-OpenCloudItem $url $path $id $pass $space -BaseItemOnly -OnErrorContinue)) {
            $rest = @{
                Uri = $space ? "$url/dav/spaces/$space/$path" : "$url/remote.php/dav/files/$id/$path"
                CustomMethod = "MKCOL"
                Authentication = "Basic"
                Credential = [PSCredential]::new($id, (ConvertTo-SecureString $pass -AsPlainText -Force))
            }
            Invoke-RestMethod @rest | Out-Null
        }
        return $true
    }
    catch { if ($silent) { return $false } else { throw } }
}
