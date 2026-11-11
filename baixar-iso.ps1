#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Repo,
    [string]$Workflow = 'build-iso.yml',
    [string]$OutputDir
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $PSScriptRoot 'out'
}

function Fail([string]$Message) {
    Write-Host ""
    Write-Host "ERRO: $Message" -ForegroundColor Red
    exit 1
}

$gh = (Get-Command gh -ErrorAction SilentlyContinue).Source
if (-not $gh) {
    $fallback = Join-Path $env:ProgramFiles 'GitHub CLI\gh.exe'
    if (Test-Path $fallback) { $gh = $fallback }
    else { Fail "gh nao encontrado. Instale com: winget install --id GitHub.cli -e" }
}

function Invoke-Gh([string[]]$GhArgs) {
    $ErrorActionPreference = 'Continue'
    $result = & $gh @GhArgs 2>&1
    $code = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    return [pscustomobject]@{ ExitCode = $code; Output = $result }
}

$auth = Invoke-Gh @('auth', 'status')
if ($auth.ExitCode -ne 0) { Fail "Voce nao esta logado no GitHub. Rode: gh auth login" }

if (-not $Repo) {
    $view = Invoke-Gh @('repo', 'view', '--json', 'nameWithOwner', '-q', '.nameWithOwner')
    if ($view.ExitCode -eq 0) { $Repo = ($view.Output | Out-String).Trim() }
    if ([string]::IsNullOrWhiteSpace($Repo)) {
        Fail "Informe o repositorio: .\baixar-iso.ps1 -Repo usuario/repo"
    }
}
if ($Repo -notmatch '^[^/]+/[^/]+$') { Fail "Repositorio invalido: $Repo (use o formato usuario/repo)" }

Write-Host "Repositorio: $Repo"

$repoInfo = Invoke-Gh @('api', "repos/$Repo", '--jq', '.size')
if ($repoInfo.ExitCode -ne 0) { Fail "Repositorio nao encontrado ou sem acesso: $Repo" }
if ((($repoInfo.Output | Out-String).Trim()) -eq '0') {
    Fail "O repositorio $Repo esta vazio. Envie o projeto e rode o workflow antes de baixar a ISO."
}

$listArgs = @('run', 'list', '--repo', $Repo, '--workflow', $Workflow, '--status', 'success', '--limit', '1',
    '--json', 'databaseId,displayTitle,createdAt,headBranch')
$listed = Invoke-Gh $listArgs
if ($listed.ExitCode -ne 0) {
    Fail "Nao foi possivel consultar as execucoes. Confira o repositorio e seu acesso."
}

$runs = @()
$runsJson = ($listed.Output | Out-String).Trim()
if ($runsJson) { $runs = @($runsJson | ConvertFrom-Json) }

if ($runs.Count -eq 0) {
    Write-Host "Nenhuma execucao bem-sucedida de '$Workflow' encontrada." -ForegroundColor Yellow
    Write-Host "Ultimas execucoes:"
    $recent = Invoke-Gh @('run', 'list', '--repo', $Repo, '--workflow', $Workflow, '--limit', '5')
    $recent.Output | ForEach-Object { Write-Host $_ }
    exit 1
}

$run = $runs[0]
Write-Host ("Execucao: #{0} '{1}' ({2}, branch {3})" -f $run.databaseId, $run.displayTitle, $run.createdAt, $run.headBranch)

$stage = Join-Path ([System.IO.Path]::GetTempPath()) ("masterfps-iso-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $stage | Out-Null

try {
    Write-Host "Baixando o artifact MasterFPSOS-ISO..."
    $download = Invoke-Gh @('run', 'download', "$($run.databaseId)", '--repo', $Repo, '-n', 'MasterFPSOS-ISO', '-D', $stage)
    if ($download.ExitCode -ne 0) { Fail "Falha no download. O artifact pode ter expirado (padrao: 90 dias)." }

    $isos = @(Get-ChildItem -Path $stage -Filter *.iso -Recurse -File)
    if ($isos.Count -eq 0) { Fail "O artifact baixado nao contem nenhum arquivo .iso." }

    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    foreach ($iso in $isos) {
        $dest = Join-Path $OutputDir $iso.Name
        Move-Item -Path $iso.FullName -Destination $dest -Force
        $sha = (Get-FileHash -Path $dest -Algorithm SHA256).Hash
        Write-Host ""
        Write-Host "ISO salva: $dest"
        Write-Host ("Tamanho: {0} GB" -f [math]::Round($iso.Length / 1GB, 2))
        Write-Host "SHA256: $sha"
    }
}
finally {
    Remove-Item -Path $stage -Recurse -Force -ErrorAction SilentlyContinue
}
