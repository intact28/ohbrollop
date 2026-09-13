# ================================================================
# WEDDING GALLERY MEDIA GENERATOR
#
# Creates:
#   - 1000px thumbnails
#   - 2560px display images
#   - video poster images
#   - media.json
#
# Sources:
#   photographer\...  -> photographer
#   guests\photos     -> guests
#   guests\videos     -> guests
#   camera            -> guests (photos + videos)
#   photobooth        -> photobooth
#
# GitHub releases:
#
#   Guest originals/videos/posters:
#       photos-guests
#
#   Guest thumbnails:
#       thumbs-guests
#
#   Guest display images:
#       web-guests
#
# Camera media uses those SAME guest releases.
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


# Number of assets uploaded to GitHub per gh command

$uploadBatchSize = 25


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
# PHOTO SOURCES
#
# This order becomes the natural media.json order.
#
# Camera is intentionally Album = guests and uses the SAME
# releases as guests.
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
        Key = "camera"
        Path = Join-Path $originalRoot "camera"

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


# ================================================================
# VIDEO SOURCES
#
# Both guest videos and camera videos belong to Gästbilder.
# ================================================================

$videoSources = @(

    @{
        Key = "guests"

        Path =
            Join-Path `
                $originalRoot `
                "guests\videos"

        Release = "photos-guests"

        Album = "guests"
    },

    @{
        Key = "camera"

        Path =
            Join-Path `
                $originalRoot `
                "camera"

        Release = "photos-guests"

        Album = "guests"
    }

)


$posterRoot =
    Join-Path `
        $generatedRoot `
        "video-posters"


# ================================================================
# CHECK REQUIRED TOOLS
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
# GITHUB ASSET FILENAME NORMALIZATION
#
# GitHub can normalize special characters when release assets
# are uploaded.
#
# Example seen in this project:
#
#     photo(0).jpg
#
# becomes:
#
#     photo.0.jpg
#
# We therefore normalize names before:
#   - comparing local files with release assets
#   - constructing download URLs
#   - checking collisions
# ================================================================

function ConvertTo-GitHubAssetName {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Filename
    )


    $name =
        $Filename


    # GitHub normalized parentheses in our existing assets:
    #
    # photo(0).jpg
    #
    # became:
    #
    # photo.0.jpg
    #
    # IMPORTANT:
    # Do NOT replace + signs.
    # GitHub keeps filenames such as:
    #
    # 2026-07-25T211253+0200.jpg

    $name =
        $name -replace '\(', '.'


    $name =
        $name -replace '\)', '.'


    # Collapse duplicate dots caused by:
    #
    # (0).jpg -> .0..jpg

    $name =
        $name -replace '\.{2,}', '.'


    $name =
        $name.Trim('.')


    return $name
}


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


    $githubFilename =
        ConvertTo-GitHubAssetName `
            $Filename


    $encodedFilename =
        [System.Uri]::EscapeDataString(
            $githubFilename
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
# GENERATE OPTIMIZED JPEG
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

        "-background",
        "white",

        "-alpha",
        "remove",

        "-alpha",
        "off",

        "-strip",

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


    # A missing release is expected when running against a new tag.
    # Temporarily prevent that expected gh error from terminating
    # the entire script.

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


    if ($releaseExists) {

        return

    }


    Write-Host `
        "Creating GitHub release: $Tag"


    & gh `
        release `
        create `
        $Tag `
        --repo $repo `
        --title $Tag `
        --notes "Generated wedding gallery web assets"


    if ($LASTEXITCODE -ne 0) {

        throw `
            "Could not create GitHub release: $Tag"

    }


    Write-Host `
        "Created: $Tag"
}


# ================================================================
# GET EXISTING RELEASE ASSET NAMES
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
        [string]::IsNullOrWhiteSpace(
            $releaseId
        )
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

            $normalizedName =
                $name.Trim().ToLowerInvariant()


            $lookup[$normalizedName] =
                $true

        }
    }


    return $lookup
}


# ================================================================
# UPLOAD ONLY FILES THAT ARE NOT ALREADY ON GITHUB
#
# IMPORTANT:
# Comparison uses the normalized GitHub asset name.
#
# Thus:
#
#     local:  photo(0).jpg
#     remote: photo.0.jpg
#
# correctly counts as the SAME file.
# ================================================================

function Upload-MissingFiles {

    param(
        [Parameter(Mandatory = $true)]
        [string]$ReleaseTag,

        [Parameter(Mandatory = $true)]
        [array]$Files
    )


    if ($Files.Count -eq 0) {

        Write-Host `
            "$ReleaseTag : no files to process"

        return

    }


    Ensure-Release `
        $ReleaseTag


    $existing =
        Get-ReleaseAssetNames `
            $ReleaseTag


    $missing =
        @(
            $Files |
            Where-Object {

                $githubName =
                    ConvertTo-GitHubAssetName `
                        $_.Name


                -not $existing.ContainsKey(
                    $githubName.ToLowerInvariant()
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
# PREPARE OUTPUT DIRECTORIES
# ================================================================

New-Item `
    -ItemType Directory `
    -Force `
    -Path $generatedRoot |
    Out-Null


New-Item `
    -ItemType Directory `
    -Force `
    -Path $posterRoot |
    Out-Null


# ================================================================
# COMMON PATHS
# ================================================================

$guestPhotoFolder =
    Join-Path `
        $originalRoot `
        "guests\photos"


$guestVideoFolder =
    Join-Path `
        $originalRoot `
        "guests\videos"


$cameraFolder =
    Join-Path `
        $originalRoot `
        "camera"


# ================================================================
# CHECK GUEST/CAMERA RELEASE FILENAME COLLISIONS
#
# Because guests + camera all use photos-guests, the GitHub asset
# names must remain unique AFTER GitHub-style normalization.
# ================================================================

Write-Host ""
Write-Host "======================================"
Write-Host "CHECKING GUEST FILE NAMES"
Write-Host "======================================"
Write-Host ""


$guestOriginalFilesForCheck =
    @()


foreach (
    $folder in @(
        $guestPhotoFolder,
        $guestVideoFolder,
        $cameraFolder
    )
) {

    if (Test-Path $folder) {

        $guestOriginalFilesForCheck +=
            @(
                Get-ChildItem `
                    $folder `
                    -File |
                Where-Object {

                    $extension =
                        $_.Extension.ToLowerInvariant()


                    (
                        $imageExtensions -contains
                        $extension
                    ) -or (
                        $videoExtensions -contains
                        $extension
                    )

                }
            )
    }
}


# ------------------------------------------------
# Check original names after GitHub normalization
# ------------------------------------------------

$normalizedOriginalNames =
    @{}


foreach ($file in $guestOriginalFilesForCheck) {

    $githubName =
        ConvertTo-GitHubAssetName `
            $file.Name


    $key =
        $githubName.ToLowerInvariant()


    if ($normalizedOriginalNames.ContainsKey($key)) {

        throw @"

Two guest/camera files would have the same GitHub release asset name:

$($normalizedOriginalNames[$key])
$($file.FullName)

GitHub asset name:
$githubName

Rename one of the files and run the script again.
"@

    }


    $normalizedOriginalNames[$key] =
        $file.FullName
}


# ------------------------------------------------
# Check derived thumbnail/web filenames
#
# Example:
#
# photo.jpg
# photo.png
#
# both produce:
#
# photo.jpg
# ------------------------------------------------

$guestImageFilesForCheck =
    @(
        $guestOriginalFilesForCheck |
        Where-Object {

            $imageExtensions -contains
            $_.Extension.ToLowerInvariant()

        }
    )


$normalizedDerivedNames =
    @{}


foreach ($file in $guestImageFilesForCheck) {

    $derivedName =
        Get-DerivedFilename `
            $file.Name


    $githubDerivedName =
        ConvertTo-GitHubAssetName `
            $derivedName


    $key =
        $githubDerivedName.ToLowerInvariant()


    if ($normalizedDerivedNames.ContainsKey($key)) {

        throw @"

Two guest/camera images would create the same GitHub thumbnail/display filename:

$($normalizedDerivedNames[$key])
$($file.FullName)

Generated GitHub filename:
$githubDerivedName

Rename one of these files and run the script again.
"@

    }


    $normalizedDerivedNames[$key] =
        $file.FullName
}


Write-Host `
    "Guest/camera filename check: OK"


# ================================================================
# UPLOAD CAMERA ORIGINALS
#
# Existing guest originals are already uploaded.
#
# Camera photos + videos are new, so upload them to:
#
#     photos-guests
#
# The comparison logic above means rerunning this safely skips
# anything already uploaded.
# ================================================================

Write-Host ""
Write-Host "======================================"
Write-Host "UPLOADING CAMERA ORIGINALS"
Write-Host "======================================"
Write-Host ""


if (-not (Test-Path $cameraFolder)) {

    throw `
        "Camera folder does not exist: $cameraFolder"

}


$cameraOriginalFiles =
    @(
        Get-ChildItem `
            $cameraFolder `
            -File |
        Where-Object {

            $extension =
                $_.Extension.ToLowerInvariant()


            (
                $imageExtensions -contains
                $extension
            ) -or (
                $videoExtensions -contains
                $extension
            )

        } |
        Sort-Object Name
    )


Write-Host `
    "Camera originals: $($cameraOriginalFiles.Count)"


Upload-MissingFiles `
    -ReleaseTag "photos-guests" `
    -Files $cameraOriginalFiles


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
    # CHECK DERIVED FILENAMES WITHIN THIS SOURCE
    # ============================================================

    $derivedNames =
        @{}


    foreach ($file in $originalFiles) {

        $derivedName =
            Get-DerivedFilename `
                $file.Name


        $githubDerivedName =
            ConvertTo-GitHubAssetName `
                $derivedName


        $key =
            $githubDerivedName.ToLowerInvariant()


        if ($derivedNames.ContainsKey($key)) {

            throw @"

Two files would create the same GitHub derived filename:

$($derivedNames[$key])
$($file.FullName)

GitHub derived filename:
$githubDerivedName
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
        # 2560PX DISPLAY VERSION
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
# PROCESS VIDEOS + CREATE POSTERS
# ================================================================

Write-Host ""
Write-Host "======================================"
Write-Host "PROCESSING VIDEOS"
Write-Host "======================================"


foreach ($videoSource in $videoSources) {

    Write-Host ""
    Write-Host "--------------------------------------"
    Write-Host "Videos: $($videoSource.Key)"
    Write-Host "--------------------------------------"


    if (-not (Test-Path $videoSource.Path)) {

        Write-Warning `
            "Video folder does not exist: $($videoSource.Path)"

        continue

    }


    $posterFolder =
        Join-Path `
            $posterRoot `
            $videoSource.Key


    New-Item `
        -ItemType Directory `
        -Force `
        -Path $posterFolder |
        Out-Null


    $videos =
        @(
            Get-ChildItem `
                $videoSource.Path `
                -File |
            Where-Object {

                $videoExtensions -contains
                $_.Extension.ToLowerInvariant()

            } |
            Sort-Object Name
        )


    Write-Host `
        "Videos found: $($videos.Count)"


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


        # ========================================================
        # CREATE POSTER
        # ========================================================

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


            # First try one second into the video.

            & ffmpeg `
                -hide_banner `
                -loglevel error `
                -y `
                -ss 1 `
                -i $video.FullName `
                -frames:v 1 `
                $temporaryPoster


            # For very short videos, try the first frame.

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


            Convert-ToGalleryJpeg `
                -Source $temporaryPoster `
                -Destination $posterPath `
                -MaxSize 1000 `
                -Quality 82


            Remove-Item `
                $temporaryPoster `
                -Force
        }


        # ========================================================
        # VIDEO ENTRY
        # ========================================================

        $posterDimensions =
            Get-ImageDimensions `
                $posterPath


        if ($null -eq $posterDimensions) {

            throw `
                "Could not determine poster dimensions: $posterPath"

        }


        $posterUrl =
            Get-GitHubAssetUrl `
                $videoSource.Release `
                $posterName


        $videoUrl =
            Get-GitHubAssetUrl `
                $videoSource.Release `
                $video.Name


        $item =
            [ordered]@{

                type =
                    "video"

                thumb =
                    $posterUrl

                poster =
                    $posterUrl

                src =
                    $videoUrl

                original =
                    $videoUrl

                album =
                    $videoSource.Album

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


    # ============================================================
    # UPLOAD VIDEO POSTERS
    # ============================================================

    $posterFiles =
        @(
            Get-ChildItem `
                $posterFolder `
                -File `
                -Filter "*-poster.jpg" |
            Sort-Object Name
        )


    Upload-MissingFiles `
        -ReleaseTag $videoSource.Release `
        -Files $posterFiles
}


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