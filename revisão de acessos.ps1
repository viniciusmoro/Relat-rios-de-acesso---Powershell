# ==============================================================================
# Script de Auditoria de Permissões NTFS (Exportação Direta para PDF)
# Objetivo: Gerar um PDF estruturado por área com bloco de assinaturas formal
# ==============================================================================

# Carrega a biblioteca nativa do .NET para consultar o AD (Sem depender de RSAT)
Add-Type -AssemblyName System.DirectoryServices.AccountManagement

# 1. Define a pasta raiz das áreas 
$RootFolder = "" 
# 2. Local onde os relatórios serão salvos 
$ExportFolder = ""

# Cria a pasta de destino caso não exista
if (-not (Test-Path $ExportFolder)) {
    New-Item -Path $ExportFolder -ItemType Directory | Out-Null
}

# Coleta dados para o cabeçalho do relatório institucional
$CurrentControl = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$RunDate = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

Write-Host "Mapeando subdiretórios em $RootFolder..." -ForegroundColor Cyan
$TargetDirectories = Get-ChildItem -Path $RootFolder -Directory | Select-Object -ExpandProperty FullName

Write-Host "Foram encontrados $($TargetDirectories.Count) departamentos. Gerando PDFs..." -ForegroundColor Magenta

foreach ($Dir in $TargetDirectories) {
    if (-not (Test-Path $Dir)) {
        Write-Host "[AVISO] Caminho inacessível nesta sessão: $Dir" -ForegroundColor DarkYellow
        continue
    }

    $Folder = Get-Item -Path $Dir
    $AreaName = $Folder.Name
    Write-Host "`nAnalisando área: $AreaName" -ForegroundColor Yellow

    $ACLs = Get-Acl -Path $Folder.FullName
    $RowsHtml = ""

    # Extrai cada permissão da pasta
    foreach ($Access in $ACLs.Access) {
        $Identity = $Access.IdentityReference.Value
        $Rights = $Access.FileSystemRights
        $Type = $Access.AccessControlType

        # Adiciona a linha de acesso direto (Grupo ou Usuário base)
        $RowsHtml += "<tr><td>$($Folder.FullName)</td><td>$Identity</td><td>Acesso Direto</td><td>$Type</td><td>$Rights</td></tr>"

        # Expansão de grupos do AD para listar os usuários finais
        if ($Identity -match "\\" -and $Identity -notmatch "BUILTIN|NT AUTHORITY|CREATOR OWNER|Todos|Everyone") {
            $DomainName = $Identity.Split('\')[0]
            $AccountName = $Identity.Split('\')[1]

            try {
                $Context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Domain, $DomainName)
                $Group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($Context, $AccountName)

                if ($Group -ne $null) {
                    $Members = $Group.GetMembers($true)
                    foreach ($Member in $Members) {
                        $RowsHtml += "<tr class='inherited'><td>$($Folder.FullName)</td><td>$Identity</td><td>$DomainName\$($Member.SamAccountName)</td><td>Herdado do Grupo</td><td>$Rights</td></tr>"
                    }
                }
            } catch {
                # Ignora falhas de leitura de objetos específicos silenciosamente
            }
        }
    }

    # 2. Caminhos para os arquivos temporários e finais
    $TempHtmlPath = Join-Path $ExportFolder "temp_$AreaName.html"
    
    # === Nome do PDF ===
    $ExportPDF = Join-Path $ExportFolder "Relatorio_Acessos_$AreaName.pdf"

    # Monta o design do relatório usando HTML e CSS estruturado para impressão ()
    $HtmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; color: #333; line-height: 1.4; }
        .header { border-bottom: 3px solid #0056b3; padding-bottom: 8px; margin-bottom: 20px; }
        .header h1 { margin: 0; color: #0056b3; font-size: 18pt; text-transform: uppercase; }
        .metadata { margin-bottom: 25px; font-size: 10pt; background: #f8f9fa; padding: 12px; border-radius: 4px; border: 1px solid #eee; }
        .metadata table { width: 100%; border: none; }
        .metadata td { padding: 4px; border: none; }
        table.data-table { width: 100%; border-collapse: collapse; margin-top: 15px; font-size: 9.5pt; }
        table.data-table th { background-color: #0056b3; color: white; border: 1px solid #004494; text-align: left; padding: 10px; font-weight: bold; }
        table.data-table td { border: 1px solid #dddddd; padding: 8px; text-align: left; }
        table.data-table tr:nth-child(even) { background-color: #f9f9f9; }
        .inherited { color: #666; font-style: italic; background-color: #fafafa; }
        .signature-section { margin-top: 60px; page-break-inside: avoid; }
        .signature-table { width: 100%; border: none; margin-top: 50px; }
        .signature-table td { width: 50%; text-align: center; border: none; padding: 20px; font-size: 10pt; }
        .signature-line { width: 85%; margin: 0 auto; border-top: 1px solid #444; padding-top: 8px; }
    </style>
</head>
<body>
    <div class='header'>
        <h1>NTFS Permissions Reporter - Resultados de Auditoria</h1>
    </div>
    
    <div class='metadata'>
        <table>
            <tr><td><strong>Diretório Alvo:</strong> $Dir</td><td><strong>Executado por:</strong> $CurrentControl</td></tr>
            <tr><td><strong>Data de Exportação:</strong> $RunDate</td><td><strong>Escopo:</strong> Nível Root + Expansão AD Estendida</td></tr>
        </table>
    </div>
    
    <table class='data-table'>
        <thead>
            <tr>
                <th>Caminho (Path)</th>
                <th>Grupo / Conta Origem</th>
                <th>Usuário Final (Membro AD)</th>
                <th>Tipo de Permissão</th>
                <th>Direitos NTFS</th>
            </tr>
        </thead>
        <tbody>
            $RowsHtml
        </tbody>
    </table>

    <!-- Bloco de Assinaturas Conforme Padrão -->
    <div class='signature-section'>
        <table class='signature-table'>
            <tr>
                <td>
                    <div class='signature-line'></div>
                    <strong>Assinatura Gerente / Supervisor da Área ($AreaName)</strong><br>Data: ____/____/_______
                </td>
                <td>
                    <div class='signature-line'></div>
                    <strong>Assinatura Controller</strong><br>Data: ____/____/_______
                </td>
            </tr>
        </table>
    </div>
</body>
</html>
"@

    # Grava o HTML temporário
    $HtmlContent | Out-File -FilePath $TempHtmlPath -Encoding utf8

    # 3. Executa a conversão para PDF usando o motor de renderização do Edge (Headless)
    try {
        $EdgeArgs = @(
            "--headless",
            "--disable-gpu",
            "--print-to-pdf=$ExportPDF",
            $TempHtmlPath
        )
        
        Start-Process -FilePath "msedge.exe" -ArgumentList $EdgeArgs -Wait -ErrorAction Stop
        Write-Host "  [+] PDF gerado com sucesso: $ExportPDF" -ForegroundColor Green
    } catch {
        Write-Host "  [ERRO] Falha ao invocar conversor PDF do Microsoft Edge: $_" -ForegroundColor Red
    }

    # Remove o arquivo temporário de transição
    if (Test-Path $TempHtmlPath) {
        Remove-Item -Path $TempHtmlPath -Force
    }
}

Write-Host "`nProcesso finalizado com sucesso! Todos os PDFs estão disponíveis em: $ExportFolder" -ForegroundColor Green=
