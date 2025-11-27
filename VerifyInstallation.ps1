# ===================================================================
# Script de verification de l'installation du systeme de galeries
# Usage: .\VerifyInstallation.ps1
# ===================================================================

Write-Host "[VERIFICATION] Systeme de galeries" -ForegroundColor Cyan
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

$errors = 0
$warnings = 0

# Fonction pour verifier un fichier
function Test-FileExists {
    param(
        [string]$Path,
        [string]$Description,
        [bool]$Critical = $true
    )
    
    if (Test-Path $Path) {
        Write-Host "[OK] $Description" -ForegroundColor Green
        Write-Host "     $Path" -ForegroundColor Gray
        return $true
    } else {
        if ($Critical) {
            Write-Host "[ERREUR] $Description - MANQUANT" -ForegroundColor Red
            $script:errors++
        } else {
            Write-Host "[WARN] $Description - MANQUANT (optionnel)" -ForegroundColor Yellow
            $script:warnings++
        }
        Write-Host "     $Path" -ForegroundColor Gray
        return $false
    }
}

# Fonction pour verifier le contenu d'un fichier
function Test-FileContains {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Description
    )
    
    if (Test-Path $Path) {
        $content = Get-Content $Path -Raw
        if ($content -match $Pattern) {
            Write-Host "[OK] $Description" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[ERREUR] $Description" -ForegroundColor Red
            Write-Host "     Pattern non trouve: $Pattern" -ForegroundColor Gray
            $script:errors++
            return $false
        }
    }
    return $false
}

Write-Host "[FICHIERS PRINCIPAUX]" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------" -ForegroundColor Gray

# Script PowerShell
Test-FileExists ".\GenerateMiniatures.ps1" "Script de generation des miniatures"

# Page photo
Test-FileExists ".\_pages\photo.md" "Page photo" -Critical $false
if (-not (Test-Path ".\_pages\photo.md")) {
    Test-FileExists ".\photo.md" "Page photo (racine)" -Critical $false
}

Write-Host ""
Write-Host "[ASSETS CSS]" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------" -ForegroundColor Gray

# CSS
$customCssExists = Test-FileExists ".\assets\css\custom.css" "CSS principal"
$galleryCssExists = Test-FileExists ".\assets\css\gallery.css" "CSS des galeries"

# Verifier l'import dans custom.css
if ($customCssExists) {
    Write-Host ""
    Write-Host "Verification de l'import dans custom.css..." -ForegroundColor Cyan
    Test-FileContains ".\assets\css\custom.css" "gallery" "Import de gallery.css detecte"
}

Write-Host ""
Write-Host "[ASSETS JAVASCRIPT]" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------" -ForegroundColor Gray

# JavaScript
$galleryJsExists = Test-FileExists ".\assets\js\gallery.js" "Script JavaScript des galeries"

# Verifier le contenu du JS
if ($galleryJsExists) {
    Write-Host ""
    Write-Host "Verification du contenu de gallery.js..." -ForegroundColor Cyan
    Test-FileContains ".\assets\js\gallery.js" "loadGalleries" "Fonction loadGalleries presente"
    Test-FileContains ".\assets\js\gallery.js" "PhotoSwipeLightbox" "Integration PhotoSwipe presente"
}

Write-Host ""
Write-Host "[STRUCTURE DES GALERIES]" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------" -ForegroundColor Gray

# Dossier galeries
$galeriesExists = Test-FileExists ".\galeries" "Dossier galeries" -Critical $false

if ($galeriesExists) {
    # Verifier les sous-dossiers
    $galleries = Get-ChildItem -Path ".\galeries" -Directory
    
    if ($galleries.Count -eq 0) {
        Write-Host "[WARN] Aucune galerie trouvee dans le dossier galeries/" -ForegroundColor Yellow
        Write-Host "     Creez un dossier (ex: 'Juillet 2955') et ajoutez-y des PNG" -ForegroundColor Gray
        $warnings++
    } else {
        Write-Host "[OK] $($galleries.Count) galerie(s) trouvee(s)" -ForegroundColor Green
        
        foreach ($gallery in $galleries) {
            Write-Host ""
            Write-Host "   Galerie: $($gallery.Name)" -ForegroundColor Cyan
            
            # Verifier les images
            $images = Get-ChildItem -Path $gallery.FullName -Filter "*.png"
            Write-Host "      Images PNG: $($images.Count)" -ForegroundColor Gray
            
            # Verifier le dossier thumbs
            $thumbsPath = Join-Path $gallery.FullName "thumbs"
            if (Test-Path $thumbsPath) {
                $thumbs = Get-ChildItem -Path $thumbsPath -Filter "*.jpg"
                Write-Host "      Miniatures: $($thumbs.Count)" -ForegroundColor Gray
            } else {
                Write-Host "      [WARN] Pas de dossier thumbs/ - Lancez GenerateMiniatures.ps1" -ForegroundColor Yellow
            }
            
            # Verifier index.json
            $indexPath = Join-Path $gallery.FullName "index.json"
            if (Test-Path $indexPath) {
                Write-Host "      [OK] index.json present" -ForegroundColor Green
            } else {
                Write-Host "      [ERREUR] index.json manquant - Lancez GenerateMiniatures.ps1" -ForegroundColor Red
                $errors++
            }
        }
    }
    
    # Verifier l'index global
    Write-Host ""
    $globalIndexExists = Test-Path ".\galeries\galleries-index.json"
    if ($globalIndexExists) {
        Write-Host "[OK] Index global (galleries-index.json) present" -ForegroundColor Green
    } else {
        Write-Host "[ERREUR] Index global (galleries-index.json) manquant" -ForegroundColor Red
        Write-Host "     Lancez: .\GenerateMiniatures.ps1" -ForegroundColor Gray
        $errors++
    }
}

Write-Host ""
Write-Host "[CONFIGURATION JEKYLL]" -ForegroundColor Yellow
Write-Host "---------------------------------------------------------" -ForegroundColor Gray

# Verifier _config.yml
$configExists = Test-FileExists ".\_config.yml" "Fichier de configuration Jekyll"

if ($configExists) {
    Write-Host ""
    Write-Host "Verification de la configuration..." -ForegroundColor Cyan
    Test-FileContains ".\_config.yml" "jekyll-include-cache" "Plugin jekyll-include-cache"
    
    $config = Get-Content ".\_config.yml" -Raw
    if ($config -match "include:") {
        Write-Host "[OK] Section 'include' trouvee" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Section 'include' non trouvee - Jekyll pourrait ignorer les assets" -ForegroundColor Yellow
        $warnings++
    }
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "[RESUME]" -ForegroundColor Yellow
Write-Host "=========================================================" -ForegroundColor Cyan

if ($errors -eq 0 -and $warnings -eq 0) {
    Write-Host "[OK] Installation complete et correcte !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prochaines etapes:" -ForegroundColor Yellow
    Write-Host "   1. Si vous n'avez pas de galeries, creez-en une:" -ForegroundColor White
    Write-Host "      mkdir galeries\ma-premiere-galerie" -ForegroundColor Gray
    Write-Host "      # Copiez des PNG dedans" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   2. Generez les miniatures:" -ForegroundColor White
    Write-Host "      .\GenerateMiniatures.ps1" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   3. Testez localement avec Jekyll:" -ForegroundColor White
    Write-Host "      bundle exec jekyll serve" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   4. Puis commitez et pushez:" -ForegroundColor White
    Write-Host "      git add ." -ForegroundColor Gray
    Write-Host "      git commit -m 'Systeme de galeries OK'" -ForegroundColor Gray
    Write-Host "      git push" -ForegroundColor Gray
} else {
    Write-Host "[ATTENTION] Installation incomplete" -ForegroundColor Yellow
    Write-Host "   Erreurs critiques: $errors" -ForegroundColor Red
    Write-Host "   Avertissements: $warnings" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Actions recommandees:" -ForegroundColor Yellow
    
    if (-not $galleryCssExists) {
        Write-Host "   * Creez assets/css/gallery.css avec le contenu fourni" -ForegroundColor White
    }
    
    if (-not $galleryJsExists) {
        Write-Host "   * Creez assets/js/gallery.js avec le contenu fourni" -ForegroundColor White
    }
    
    if (-not $customCssExists) {
        Write-Host "   * Creez assets/css/custom.css" -ForegroundColor White
    } elseif (-not ((Get-Content ".\assets\css\custom.css" -Raw) -match "gallery")) {
        Write-Host "   * Ajoutez @import url('/assets/css/gallery.css'); a la fin de custom.css" -ForegroundColor White
    }
    
    if ($galeriesExists -and -not (Test-Path ".\galeries\galleries-index.json")) {
        Write-Host "   * Lancez: .\GenerateMiniatures.ps1" -ForegroundColor White
    }
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan