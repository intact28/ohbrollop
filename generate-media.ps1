# ================================================================
# WEDDING GALLERY MEDIA GENERATOR
#
# Creates:
#   - 1000px thumbnails
#   - 2560px display images
#   - video poster images
#   - media.json
#
# Originals are NEVER modified.
# ================================================================

$ErrorActionPreference = "Stop"


# ================================================================
# SETTINGS
# ================================================================

$repoOwner = "intact28"
$repoName  = "ohbrollop"
$repo      = "$repoOwner/$repoName"

$originalRoot =
    "D:\Downloads\wedding-originals"

$generatedRoot =
    Join-Path `
        (Split-Path $originalRoot -Parent) `
        "wedding-web-assets"

$outputFile =
    Join-Path `
        $PSScriptRoot `
        "media.json"


# Image settings

$thumbnailMaxSize = 1000
$thumbnailQuality = 80

$webMaxSize = 2560
$webQuality = 85


# Upload batch size
$uploadBatchSize = 25


# ================================================================
# SOURCE CONFIGURATION
#
# Order here is also the natural gallery order.
# ================================================================

$sources = @(

    @{
        Key = "forberedelser"
        Path = Join-Path $originalRoot "photographer\forberedelser"

        OriginalRelease = "photos-forberedelser"
        ThumbRelease = "thumbs-forberedelser"
        WebRelease = "web-forberedelser"

        Album = "photographer"
        Category = "forberedelser"
    },

    @{
        Key = "vigsel"
        Path = Join-Path $originalRoot "photographer\vigsel"

        OriginalRelease = "photos-vigsel"
        ThumbRelease = "thumbs-vigsel"
        WebRelease = "web-vigsel"

        Album = "photographer"
        Category = "vigsel"
    },

    @{
        Key = "brudfolje"
        Path = Join-Path $originalRoot "photographer\brudfolje"

        OriginalRelease = "photos-brudfolje"
        ThumbRelease = "thumbs-brudfolje"
        WebRelease = "web-brudfolje"

        Album = "photographer"
        Category = "brudfolje"
    },

    @{
        Key = "portratt"
        Path = Join-Path $originalRoot "photographer\portratt"

        OriginalRelease = "photos-portratt"
        ThumbRelease = "thumbs-portratt"
        WebRelease = "web-portratt"

        Album = "photographer"
        Category = "portratt"
    },

    @{
        Key = "mingel"
        Path = Join-Path $originalRoot "photographer\mingel"

        OriginalRelease = "photos-mingel"
        ThumbRelease = "thumbs-mingel"
        WebRelease = "web-mingel"

        Album = "photographer"
        Category = "mingel"
    },

    @{
        Key = "gruppbild-familj"
        Path = Join-Path $originalRoot "photographer\gruppbild-familj"

        OriginalRelease = "photos-gruppbild-familj"
        ThumbRelease = "thumbs-gruppbild-familj"
        WebRelease = "web-gruppbild-familj"

        Album = "photographer"
        Category = "gruppbild-familj"
    },

    @{
        Key = "middag"
        Path = Join-Path $originalRoot "photographer\middag"

        OriginalRelease = "photos-middag"
        ThumbRelease = "thumbs-middag"
        WebRelease = "web-middag"

        Album = "photographer"
        Category = "middag"
    },

    @{
        Key = "golden-hour"
        Path = Join-Path $originalRoot "photographer\golden-hour"

        OriginalRelease = "photos-golden-hour"
        ThumbRelease = "thumbs-golden-hour"
        WebRelease = "web-golden-hour"

        Album = "photographer"
        Category = "golden-hour"
    },

    @{
        Key = "guests"
        Path = Join-Path $originalRoot "guests\photos"

        OriginalRelease = "photos-guests"
        ThumbRelease = "thumbs-guests"
        WebRelease = "web-guests"

        Album = "guests"
        Category = $null
    },

    @{
        Key = "photobooth"
        Path = Join-Path $originalRoot "photobooth"

        OriginalRelease = "photos-photobooth"
        ThumbRelease = "thumbs-photobooth"
        WebRelease = "web-photobooth"

        Album = "photobooth"
        Category = $null
    }
)


$videoFolder =
    Join-Path `
        $originalRoot `
        "guests\videos"


$posterFolder =
    Join-Path `
        $generatedRoot `
        "video-posters"


# ================================================================
# SUPPORTED FILE TYPES
# ================================================================

$imageExtensions = @(
    ".jpg",
    ".jpeg",
    ".png",
    ".webp",
    ".avif"
)

$videoExtensions = @(
    ".mp4",
    ".mov",
    ".m4v",
    ".webm"
)


# ================================================================
# CHECK REQUIRED PROGRAMS
# ================================================================

Write-Host ""
Write-Host "Checking required tools..."
Write-Host ""


if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {

    throw "GitHub CLI (gh) was not found."

}


if (-not (Get-Command magick -ErrorAction SilentlyContinue)) {

    throw @"
ImageMagick was not found.

Install it with:

winget install --id ImageMagick.ImageMagick -e

Then restart PowerShell.
"@

}


if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {

    throw "FFmpeg was not found."

}


Write-Host "gh      : OK"
Write-Host "magick  : OK"
Write-Host "ffmpeg  : OK"


# ================================================================
# URL HELPER
# ================================================================

function Get-GitHubAssetUrl {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Release,

        [Parameter(Mandatory = $true)]
        [string]$Filename
    )


    $encodedFilename =
        [System.Uri]::EscapeDataString(
            $Filename
        )


    return (
        "https://github.com/" +
        "$repoOwner/$repoName/" +
        "releases/download/" +
        "$Release/" +
        "$encodedFilename"
    )
}


# ================================================================
# DERIVED JPEG NAME
# ================================================================

function Get-DerivedFilename {

    param(
        [Parameter(Mandatory = $true)]
        [string]$OriginalFilename
    )


    return (
        [System.IO.Path]::GetFileNameWithoutExtension(
            $OriginalFilename
        ) +
        ".jpg"
    )
}


# ================================================================
# GET DISPLAY-ORIENTED IMAGE DIMENSIONS
#
# -auto-orient means portrait JPEGs with EXIF rotation return the
# dimensions the browser will actually display.
# ================================================================

function Get-ImageDimensions {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )


    try {

        $result =
            & magick `
                $Path `
                -auto-orient `
                -format "%w|%h" `
                "info:" `
                2>$null


        if ($LASTEXITCODE -ne 0) {
            throw "ImageMagick returned an error."
        }


        $text =
            ($result -join "").Trim()


        $parts =
            $text.Split("|")


        if ($parts.Count -ne 2) {
            throw "Unexpected dimension result: $text"
        }


        return @{
            Width =
                [int]$parts[0]

            Height =
                [int]$parts[1]
        }

    }
    catch {

        Write-Warning `
            "Could not read dimensions: $Path"

        return $null
    }
}


# ================================================================
# GENERATE JPEG
# ================================================================

function Convert-ToGalleryJpeg {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination,

        [Parameter(Mandatory = $true)]
        [int]$MaxSize,

        [Parameter(Mandatory = $true)]
        [int]$Quality
    )


    $destinationFolder =
        Split-Path `
            $Destination `
            -Parent


    New-Item `
        -ItemType Directory `
        -Force `
        -Path $destinationFolder |
        Out-Null


    $resizeGeometry =
        "${MaxSize}x${MaxSize}>"


    $arguments = @(

        $Source,

        "-auto-orient",

        "-resize",
        $resizeGeometry,

        # If an image has transparency, flatten it onto white.
        "-background",
        "white",

        "-alpha",
        "remove",

        "-alpha",
        "off",

        # Remove EXIF/GPS metadata from WEB COPIES only.
        # Originals remain untouched.
        "-strip",

        # Progressive JPEG loading.
        "-interlace",
        "Plane",

        "-quality",
        "$Quality",

        $Destination
    )


    & magick @arguments


    if ($LASTEXITCODE -ne 0) {

        throw `
            "Image conversion failed: $Source"

    }


    if (-not (Test-Path $Destination)) {

        throw `
            "ImageMagick did not create: $Destination"

    }
}


# ================================================================
# ENSURE GITHUB RELEASE EXISTS
# ================================================================

function Ensure-Release {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Tag
    )


    # ------------------------------------------------------------
    # gh returns an error when the release does not exist.
    # That is expected here, so temporarily prevent PowerShell
    # from terminating on native stderr output.
    # ------------------------------------------------------------

    $previousErrorActionPreference =
        $ErrorActionPreference


    $ErrorActionPreference =
        "Continue"


    & gh `
        release `
        view `
        $Tag `
        --repo $repo `
        *> $null


    $releaseExists =
        ($LASTEXITCODE -eq 0)


    $ErrorActionPreference =
        $previousErrorActionPreference


    # ------------------------------------------------------------
    # Release already exists
    # ------------------------------------------------------------

    if ($releaseExists) {

        Write-Host "Release exists: $Tag"

        return
    }


    # ------------------------------------------------------------
    # Release does not exist - create it
    # ------------------------------------------------------------

    Write-Host "Creating GitHub release: $Tag"


    & gh `
        release `
        create `
        $Tag `
        --repo $repo `
        --title $Tag `
        --notes "Generated wedding gallery web assets"


    if ($LASTEXITCODE -ne 0) {

        throw "Could not create GitHub release: $Tag"

    }


    Write-Host "Created: $Tag"
}


# ================================================================
# GET ASSET NAMES IN A RELEASE
# ================================================================

function Get-ReleaseAssetNames {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Tag
    )


    $releaseId =
        & gh `
            api `
            "repos/$repoOwner/$repoName/releases/tags/$Tag" `
            --jq ".id"


    if (
        $LASTEXITCODE -ne 0 -or
        [string]::IsNullOrWhiteSpace($releaseId)
    ) {

        throw `
            "Could not get release ID for $Tag"

    }


    $releaseId =
        $releaseId.Trim()


    $names =
        @(
            & gh `
                api `
                --paginate `
                "repos/$repoOwner/$repoName/releases/$releaseId/assets?per_page=100" `
                --jq ".[].name"
        )


    if ($LASTEXITCODE -ne 0) {

        throw `
            "Could not read release assets for $Tag"

    }


    $lookup =
        @{}


    foreach ($name in $names) {

        if (
            -not [string]::IsNullOrWhiteSpace(
                $name
            )
        ) {

            $lookup[
                $name.Trim().ToLowerInvariant()
            ] =
                $true

        }
    }


    return $lookup
}


# ================================================================
# UPLOAD ONLY MISSING FILES
# ================================================================

function Upload-MissingFiles {

    param(
        [Parameter(Mandatory = $true)]
        [string]$ReleaseTag,

        [Parameter(Mandatory = $true)]
        [array]$Files
    )


    Ensure-Release `
        $ReleaseTag


    $existing =
        Get-ReleaseAssetNames `
            $ReleaseTag


    $missing =
        @(
            $Files |
            Where-Object {

                -not $existing.ContainsKey(
                    $_.Name.ToLowerInvariant()
                )

            }
        )


    Write-Host `
        "$ReleaseTag : $($Files.Count) local, $($missing.Count) to upload"


    if ($missing.Count -eq 0) {

        return

    }


    for (
        $i = 0;
        $i -lt $missing.Count;
        $i += $uploadBatchSize
    ) {

        $batch =
            @(
                $missing |
                Select-Object `
                    -Skip $i `
                    -First $uploadBatchSize
            )


        $start =
            $i + 1


        $end =
            [Math]::Min(
                $i + $uploadBatchSize,
                $missing.Count
            )


        Write-Host `
            "  Uploading $start-$end of $($missing.Count)..."


        $arguments =
            @(
                "release",
                "upload",
                $ReleaseTag
            )


        foreach ($file in $batch) {

            $arguments +=
                $file.FullName

        }


        $arguments +=
            @(
                "--repo",
                $repo
            )


        & gh @arguments


        if ($LASTEXITCODE -ne 0) {

            throw `
                "Upload failed for release $ReleaseTag"

        }
    }
}


# ================================================================
# PREPARE OUTPUT DIRECTORY
# ================================================================

New-Item `
    -ItemType Directory `
    -Force `
    -Path $generatedRoot |
    Out-Null


# ================================================================
# MEDIA COLLECTION
# ================================================================

$media =
    [System.Collections.Generic.List[object]]::new()


# ================================================================
# PROCESS ALL PHOTOS
# ================================================================

Write-Host ""
Write-Host "======================================"
Write-Host "PROCESSING PHOTOS"
Write-Host "======================================"


foreach ($source in $sources) {

    Write-Host ""
    Write-Host "--------------------------------------"
    Write-Host $source.Key
    Write-Host "--------------------------------------"


    if (-not (Test-Path $source.Path)) {

        throw `
            "Source folder does not exist: $($source.Path)"

    }


    $originalFiles =
        @(
            Get-ChildItem `
                $source.Path `
                -File |
            Where-Object {

                $imageExtensions -contains
                $_.Extension.ToLowerInvariant()

            } |
            Sort-Object Name
        )


    Write-Host `
        "Original images: $($originalFiles.Count)"


    # ============================================================
    # CHECK DERIVED FILENAMES FOR COLLISIONS
    # ============================================================

    $derivedNames =
        @{}


    foreach ($file in $originalFiles) {

        $derivedName =
            Get-DerivedFilename `
                $file.Name


        $key =
            $derivedName.ToLowerInvariant()


        if ($derivedNames.ContainsKey($key)) {

            throw @"
Two files would create the same derived filename:

$($derivedNames[$key])
$file

Derived name:
$derivedName
"@

        }


        $derivedNames[$key] =
            $file.FullName
    }


    # ============================================================
    # LOCAL OUTPUT DIRECTORIES
    # ============================================================

    $thumbDirectory =
        Join-Path `
            $generatedRoot `
            "thumbs\$($source.Key)"


    $webDirectory =
        Join-Path `
            $generatedRoot `
            "web\$($source.Key)"


    New-Item `
        -ItemType Directory `
        -Force `
        -Path $thumbDirectory |
        Out-Null


    New-Item `
        -ItemType Directory `
        -Force `
        -Path $webDirectory |
        Out-Null


    # ============================================================
    # GENERATE DERIVATIVES
    # ============================================================

    $counter = 0


    foreach ($file in $originalFiles) {

        $counter++


        $derivedName =
            Get-DerivedFilename `
                $file.Name


        $thumbPath =
            Join-Path `
                $thumbDirectory `
                $derivedName


        $webPath =
            Join-Path `
                $webDirectory `
                $derivedName


        Write-Host `
            "[$counter/$($originalFiles.Count)] $($file.Name)"


        # --------------------------------------------------------
        # THUMBNAIL
        # --------------------------------------------------------

        if (-not (Test-Path $thumbPath)) {

            Convert-ToGalleryJpeg `
                -Source $file.FullName `
                -Destination $thumbPath `
                -MaxSize $thumbnailMaxSize `
                -Quality $thumbnailQuality

        }


        # --------------------------------------------------------
        # DISPLAY VERSION
        # --------------------------------------------------------

        if (-not (Test-Path $webPath)) {

            Convert-ToGalleryJpeg `
                -Source $file.FullName `
                -Destination $webPath `
                -MaxSize $webMaxSize `
                -Quality $webQuality

        }


        # --------------------------------------------------------
        # ORIGINAL DIMENSIONS
        # --------------------------------------------------------

        $dimensions =
            Get-ImageDimensions `
                $file.FullName


        if ($null -eq $dimensions) {

            throw `
                "Could not determine dimensions for $($file.FullName)"

        }


        # --------------------------------------------------------
        # MEDIA.JSON ENTRY
        # --------------------------------------------------------

        $item =
            [ordered]@{

                type =
                    "image"

                thumb =
                    Get-GitHubAssetUrl `
                        $source.ThumbRelease `
                        $derivedName

                src =
                    Get-GitHubAssetUrl `
                        $source.WebRelease `
                        $derivedName

                original =
                    Get-GitHubAssetUrl `
                        $source.OriginalRelease `
                        $file.Name

                album =
                    $source.Album

                alt =
                    ""

                name =
                    $file.Name

                width =
                    $dimensions.Width

                height =
                    $dimensions.Height
            }


        if ($null -ne $source.Category) {

            $item.category =
                $source.Category

        }


        $media.Add(
            [PSCustomObject]$item
        )
    }


    # ============================================================
    # UPLOAD THUMBNAILS
    # ============================================================

    $thumbFiles =
        @(
            Get-ChildItem `
                $thumbDirectory `
                -File `
                -Filter "*.jpg" |
            Sort-Object Name
        )


    Upload-MissingFiles `
        -ReleaseTag $source.ThumbRelease `
        -Files $thumbFiles


    # ============================================================
    # UPLOAD DISPLAY IMAGES
    # ============================================================

    $webFiles =
        @(
            Get-ChildItem `
                $webDirectory `
                -File `
                -Filter "*.jpg" |
            Sort-Object Name
        )


    Upload-MissingFiles `
        -ReleaseTag $source.WebRelease `
        -Files $webFiles
}


# ================================================================
# VIDEO POSTERS
# ================================================================

Write-Host ""
Write-Host "======================================"
Write-Host "PROCESSING VIDEOS"
Write-Host "======================================"


New-Item `
    -ItemType Directory `
    -Force `
    -Path $posterFolder |
    Out-Null


$videos =
    @(
        Get-ChildItem `
            $videoFolder `
            -File |
        Where-Object {

            $videoExtensions -contains
            $_.Extension.ToLowerInvariant()

        } |
        Sort-Object Name
    )


Write-Host ""
Write-Host "Videos found: $($videos.Count)"


foreach ($video in $videos) {

    $posterName =
        [System.IO.Path]::GetFileNameWithoutExtension(
            $video.Name
        ) +
        "-poster.jpg"


    $posterPath =
        Join-Path `
            $posterFolder `
            $posterName


    # ============================================================
    # CREATE POSTER
    # ============================================================

    if (-not (Test-Path $posterPath)) {

        Write-Host `
            "Generating poster: $posterName"


        $temporaryPoster =
            Join-Path `
                $posterFolder `
                (
                    [System.Guid]::NewGuid().ToString() +
                    ".jpg"
                )


        # Try one second into the video

        & ffmpeg `
            -hide_banner `
            -loglevel error `
            -y `
            -ss 1 `
            -i $video.FullName `
            -frames:v 1 `
            $temporaryPoster


        # Very short video: try first frame instead

        if (-not (Test-Path $temporaryPoster)) {

            & ffmpeg `
                -hide_banner `
                -loglevel error `
                -y `
                -i $video.FullName `
                -frames:v 1 `
                $temporaryPoster

        }


        if (-not (Test-Path $temporaryPoster)) {

            throw `
                "Could not extract poster from $($video.Name)"

        }


        # Resize poster to max 1000px

        Convert-ToGalleryJpeg `
            -Source $temporaryPoster `
            -Destination $posterPath `
            -MaxSize 1000 `
            -Quality 82


        Remove-Item `
            $temporaryPoster `
            -Force
    }


    # ============================================================
    # VIDEO ENTRY
    # ============================================================

    $posterDimensions =
        Get-ImageDimensions `
            $posterPath


    if ($null -eq $posterDimensions) {

        throw `
            "Could not determine poster dimensions: $posterPath"

    }


    $posterUrl =
        Get-GitHubAssetUrl `
            "photos-guests" `
            $posterName


    $videoUrl =
        Get-GitHubAssetUrl `
            "photos-guests" `
            $video.Name


    $item =
        [ordered]@{

            type =
                "video"

            # Gallery preview
            thumb =
                $posterUrl

            # Explicit poster field for <video>
            poster =
                $posterUrl

            # Original video
            src =
                $videoUrl

            original =
                $videoUrl

            album =
                "guests"

            alt =
                ""

            name =
                $video.Name

            width =
                $posterDimensions.Width

            height =
                $posterDimensions.Height
        }


    $media.Add(
        [PSCustomObject]$item
    )
}


# ================================================================
# UPLOAD MISSING VIDEO POSTERS
# ================================================================

$posterFiles =
    @(
        Get-ChildItem `
            $posterFolder `
            -File `
            -Filter "*-poster.jpg" |
        Sort-Object Name
    )


Upload-MissingFiles `
    -ReleaseTag "photos-guests" `
    -Files $posterFiles


# ================================================================
# WRITE MEDIA.JSON
# ================================================================

Write-Host ""
Write-Host "======================================"
Write-Host "WRITING MEDIA.JSON"
Write-Host "======================================"


$media |
    ConvertTo-Json `
        -Depth 10 |
    Set-Content `
        -Path $outputFile `
        -Encoding UTF8


# ================================================================
# SUMMARY
# ================================================================

$imageCount =
    @(
        $media |
        Where-Object {
            $_.type -eq "image"
        }
    ).Count


$videoCount =
    @(
        $media |
        Where-Object {
            $_.type -eq "video"
        }
    ).Count


$missingDimensions =
    @(
        $media |
        Where-Object {

            -not $_.width -or
            -not $_.height

        }
    ).Count


$missingThumbs =
    @(
        $media |
        Where-Object {

            [string]::IsNullOrWhiteSpace(
                $_.thumb
            )

        }
    ).Count


Write-Host ""
Write-Host "======================================"
Write-Host "FINISHED"
Write-Host "======================================"
Write-Host ""

Write-Host "Generated files:"
Write-Host $generatedRoot
Write-Host ""

Write-Host "Output:"
Write-Host $outputFile
Write-Host ""

Write-Host "Total media: $($media.Count)"
Write-Host "Images: $imageCount"
Write-Host "Videos: $videoCount"
Write-Host "Items without dimensions: $missingDimensions"
Write-Host "Items without thumbnails: $missingThumbs"

Write-Host ""
Write-Host "Thumbnail size: max ${thumbnailMaxSize}px"
Write-Host "Display size: max ${webMaxSize}px"
Write-Host ""