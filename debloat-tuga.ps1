<#
.SYNOPSIS
    TugaDebloat
.DESCRIPTION
    Ferramenta gráfica avançada com mais de 100 otimizações para Windows 11.
    Focada em performance máxima, debloat, privacidade e redes.
    Criado pelo TugaTech - por @DJPRMF.
#>

# Forçar execução como Administrador
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ==============================================================================
# ALERTA E CRIAÇÃO DE PONTO DE RESTAURO
# ==============================================================================
$msgRestore = [System.Windows.Forms.MessageBox]::Show("É altamente recomendado criar um Ponto de Restauro do sistema antes de proceder com otimizações profundas.`n`nPretende que o TugaDebloat crie um Ponto de Restauro automaticamente agora?", "TugaDebloat - Segurança", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)

if ($msgRestore -eq [System.Windows.Forms.DialogResult]::Yes) {
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "TugaDebloat - Antes da Otimizacao" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show("Ponto de Restauro criado com sucesso!", "TugaDebloat", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Não foi possível criar o Ponto de Restauro automaticamente. Verifique se a Proteção do Sistema está ativa na drive C:\.`n`nErro: $($_.Exception.Message)", "Erro", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

# ==============================================================================
# BASE DE DADOS DE TWEAKS
# ==============================================================================
$Global:Tweaks = @(
    # ========================== PRIVACIDADE ==========================
    @{ Category="Privacidade"; Title="Desativar Telemetria Básica (DiagTrack)"; Description="Desativa o serviço 'Connected User Experiences and Telemetry' e define o nível de telemetria para 0 no Registo, impedindo o envio de dados de diagnóstico para a Microsoft."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" 0 -Type DWord -Force; Stop-Service "DiagTrack" -WarningAction SilentlyContinue; Set-Service "DiagTrack" -StartupType Disabled -WarningAction SilentlyContinue } },
    @{ Category="Privacidade"; Title="Desativar ID de Publicidade"; Description="Remove a autorização do sistema para gerar um identificador único de publicidade, impedindo que as apps criem perfis baseados no seu comportamento."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" "Enabled" 0 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Desativar Experiências Personalizadas"; Description="Impede que o Windows utilize o seu histórico de diagnóstico para oferecer dicas, recomendações e anúncios personalizados."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy" "TailoredExperiencesWithDiagnosticDataEnabled" 0 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Desativar Histórico de Atividades"; Description="Impede o Windows de guardar o histórico das aplicações abertas e sites visitados localmente ou na cloud."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "EnableActivityFeed" 0 -Type DWord -Force; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" "PublishUserActivities" 0 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Desativar Inking & Typing Insights"; Description="Impede o envio dos seus padrões de digitação e escrita para a Microsoft para melhorar o reconhecimento de idioma."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\InputPersonalization" "RestrictImplicitInkCollection" 1 -Type DWord -Force; Set-ItemProperty "HKCU:\Software\Microsoft\InputPersonalization\TrainedDataStore" "HarvestContacts" 0 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Desativar Cortana"; Description="Desativa o processo da Cortana e remove o acesso ao assistente de voz do sistema."; Action={ New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" "AllowCortana" 0 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Desativar Relatório de Erros (WER)"; Description="Impede o envio automático de relatórios de erros e dumps de memória para a Microsoft após o encerramento inesperado de aplicações."; Action={ New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" "Disabled" 1 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Desativar SmartScreen (Edge/Loja)"; Description="Desativa o serviço de verificação de reputação de ficheiros e sites (Cuidado: reduz a segurança no Edge)."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\AppHost" "EnableWebContentEvaluation" 0 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Desativar Sensor de Localização"; Description="Bloqueia o serviço de geolocalização para todas as aplicações do sistema."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" "Value" "Deny" -Force } },
    @{ Category="Privacidade"; Title="Desativar Acesso ao Microfone"; Description="Bloqueia o acesso ao hardware de microfone para todas as aplicações UWP."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\microphone" "Value" "Deny" -Force } },
    @{ Category="Privacidade"; Title="Desativar Acesso à Câmara"; Description="Bloqueia o acesso ao hardware de câmara para todas as aplicações UWP."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\webcam" "Value" "Deny" -Force } },
    @{ Category="Privacidade"; Title="Desativar Partilha de Contactos/Calendário"; Description="Impede que aplicações acedam aos dados de contactos e calendários do utilizador."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\contacts" "Value" "Deny" -Force } },
    @{ Category="Privacidade"; Title="Desativar Notificações no Ecrã de Bloqueio"; Description="Impede que e-mails e mensagens sejam lidos na tela de bloqueio sem sessão iniciada."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings" "NOC_GLOBAL_SETTING_ALLOW_TOASTS_ABOVE_LOCK" 0 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Ocultar Email no Ecrã de Login"; Description="Remove o endereço de e-mail da conta do ecrã de bloqueio para maior privacidade."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "DontDisplayLastUserName" 1 -Type DWord -Force; Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "BlockUserFromShowingAccountDetailsOnSignin" 1 -Type DWord -Force } },
    @{ Category="Privacidade"; Title="Desativar Telemetria do Office"; Description="Bloqueia o envio de telemetria interna das aplicações do pacote Microsoft Office."; Action={ New-Item "HKCU:\Software\Policies\Microsoft\Office\16.0\osm" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKCU:\Software\Policies\Microsoft\Office\16.0\osm" "EnableLogging" 0 -Type DWord -Force -ErrorAction SilentlyContinue } },
    @{ Category="Privacidade"; Title="Desativar Programa CEIP"; Description="Desativa o programa de melhoria da experiência do cliente (Customer Experience Improvement Program)."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\SQMClient\Windows" "CEIPEnable" 0 -Type DWord -Force -ErrorAction SilentlyContinue } },
    @{ Category="Privacidade"; Title="Desativar Inventário de Dispositivos"; Description="Impede o Windows de recolher inventário de hardware e software instalado para fins de compatibilidade."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat" "DisableInventory" 1 -Type DWord -Force } },

    # ========================== DEBLOAT APPS ==========================
    @{ Category="Debloat Apps"; Title="Remover TikTok"; Description="Desinstala a aplicação TikTok do Windows."; Action={ Get-AppxPackage "*TikTok*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Spotify"; Description="Desinstala o cliente Spotify."; Action={ Get-AppxPackage "*Spotify*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Instagram"; Description="Desinstala a aplicação Instagram."; Action={ Get-AppxPackage "*Instagram*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Facebook"; Description="Desinstala a aplicação Facebook."; Action={ Get-AppxPackage "*Facebook*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover LinkedIn"; Description="Desinstala a aplicação LinkedIn."; Action={ Get-AppxPackage "*LinkedIn*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Microsoft Teams"; Description="Desinstala a aplicação integrada do Microsoft Teams."; Action={ Get-AppxPackage "*Teams*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover OneDrive (Cliente)"; Description="Desinstala o executável de sincronização do OneDrive."; Action={ Start-Process "$env:systemroot\SysWOW64\OneDriveSetup.exe" "/uninstall" -Wait -WindowStyle Hidden -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Windows Alarms"; Description="Desinstala a app Relógio/Alarmes."; Action={ Get-AppxPackage "*WindowsAlarms*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Windows Maps"; Description="Desinstala a app Mapas."; Action={ Get-AppxPackage "*WindowsMaps*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Windows Camera"; Description="Desinstala a app Câmara."; Action={ Get-AppxPackage "*WindowsCamera*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Voice Recorder"; Description="Desinstala a app Gravador de Voz."; Action={ Get-AppxPackage "*SoundRecorder*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Zune Music/Video"; Description="Desinstala apps Zune de media."; Action={ Get-AppxPackage "*Zune*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Bing Weather"; Description="Desinstala a app Meteorologia."; Action={ Get-AppxPackage "*BingWeather*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Bing News / Finance"; Description="Desinstala apps Bing de Notícias e Finanças."; Action={ Get-AppxPackage "*BingNews*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxPackage "*BingFinance*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Microsoft Solitaire"; Description="Desinstala a coleção Solitaire."; Action={ Get-AppxPackage "*Solitaire*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Sticky Notes"; Description="Desinstala a app Notas Autocolantes."; Action={ Get-AppxPackage "*StickyNotes*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover 3D Viewer / Builder"; Description="Desinstala apps de visualização/construção 3D."; Action={ Get-AppxPackage "*3DViewer*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxPackage "*3DBuilder*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Your Phone (Phone Link)"; Description="Desinstala a integração de telemóvel."; Action={ Get-AppxPackage "*YourPhone*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Xbox Game Bar & Overlay"; Description="Desinstala a Game Bar da Microsoft."; Action={ Get-AppxPackage "*XboxGamingOverlay*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxPackage "*XboxSpeechToTextOverlay*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Xbox App e Identity Provider"; Description="Desinstala apps Xbox e provider de identidade."; Action={ Get-AppxPackage "*XboxApp*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxPackage "*XboxIdentityProvider*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Get Help / Feedback Hub"; Description="Desinstala apps de ajuda e feedback."; Action={ Get-AppxPackage "*FeedbackHub*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxPackage "*GetHelp*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Mail e Calendar"; Description="Desinstala a app Email e Calendário."; Action={ Get-AppxPackage "*windowscommunicationsapps*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover Mixed Reality Portal"; Description="Desinstala o portal de Mixed Reality."; Action={ Get-AppxPackage "*MixedReality*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Remover OneNote (UWP)"; Description="Desinstala a versão UWP do OneNote."; Action={ Get-AppxPackage "*OneNote*" -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } },
    @{ Category="Debloat Apps"; Title="Limpar Pacotes Provisionados"; Description="Remove ficheiros de instalação de apps bloatware da imagem do sistema."; Action={ Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -match "TikTok|Spotify|Instagram|Facebook|Xbox|Zune" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue } },

    # ========================== DESEMPENHO ==========================
    @{ Category="Desempenho"; Title="Ativar Ultimate Performance Plan"; Description="Define o plano de energia do Windows para 'Desempenho Máximo', focando na baixa latência."; Action={ powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 | Out-Null; powercfg -setactive e9a42b02-d5df-448d-aa00-03f14749eb61 } },
    @{ Category="Desempenho"; Title="Desativar Windows Copilot"; Description="Desativa o Copilot e remove-o da barra de tarefas através de política de registo."; Action={ New-Item "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" 1 -Type DWord -Force } },
    @{ Category="Desempenho"; Title="Desativar Widgets"; Description="Remove o painel de Widgets que consome recursos em background."; Action={ New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0 -Type DWord -Force } },
    @{ Category="Desempenho"; Title="Desativar Apps em Segundo Plano"; Description="Impede que apps UWP mantenham processos ativos sem estarem abertas."; Action={ New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" "GlobalUserDisabled" 1 -Type DWord -Force } },
    @{ Category="Desempenho"; Title="Desativar Instalação Silenciosa de Bloatware"; Description="Impede o Windows de instalar apps patrocinadas automaticamente."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "SilentInstalledAppsEnabled" 0 -Type DWord -Force; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" "OemPreInstalledAppsEnabled" 0 -Type DWord -Force } },
    @{ Category="Desempenho"; Title="Desativar Edge Prelaunch & Tab Preloading"; Description="Impede o Edge de pré-carregar na memória ao arrancar o sistema."; Action={ New-Item "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" "AllowPrelaunch" 0 -Type DWord -Force; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader" "AllowTabPreloading" 0 -Type DWord -Force } },
    @{ Category="Desempenho"; Title="Desativar Superfetch (SysMain)"; Description="Desativa o serviço SysMain, recomendado apenas para SSDs e NVMe."; Action={ Stop-Service "SysMain" -Force -WarningAction SilentlyContinue; Set-Service "SysMain" -StartupType Disabled -WarningAction SilentlyContinue } },
    @{ Category="Desempenho"; Title="Desativar Hibernação"; Description="Liberta espaço em disco ao remover o ficheiro hiberfil.sys."; Action={ powercfg.exe /hibernate off } },
    @{ Category="Desempenho"; Title="Desativar Fast Startup"; Description="Desativa a funcionalidade de arranque rápido para evitar problemas de drivers e uptime elevado."; Action={ Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" "HiberbootEnabled" 0 -Type DWord -Force } },
    @{ Category="Desempenho"; Title="Desativar Xbox Game DVR"; Description="Desativa a gravação de ecrã integrada da Xbox para ganhar performance gráfica."; Action={ Set-ItemProperty "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0 -Type DWord -Force; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0 -Type DWord -Force -ErrorAction SilentlyContinue } },
    @{ Category="Desempenho"; Title="Desativar Atraso de Arranque de Apps"; Description="Remove o atraso artificial de inicialização após login."; Action={ New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" "StartupDelayInMSec" 0 -Type DWord -Force } },
    @{ Category="Desempenho"; Title="Otimizar Agendamento CPU"; Description="Define a prioridade para aplicações em vez de serviços de background."; Action={ Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" 38 -Type DWord -Force } },
    @{ Category="Desempenho"; Title="Aumentar Cache NTFS"; Description="Aumenta o buffer de memória para operações de ficheiros no sistema de ficheiros NTFS."; Action={ fsutil behavior set memoryusage 2 } },
    @{ Category="Desempenho"; Title="Desativar 8dot3 Name Creation"; Description="Desativa a criação de nomes de ficheiros curtos (8.3), acelerando o acesso ao disco."; Action={ fsutil behavior set disable8dot3 1 } },
    @{ Category="Desempenho"; Title="Desativar Last Access Update (NTFS)"; Description="Impede que o Windows atualize o timestamp de acesso a cada ficheiro, reduzindo latência no disco."; Action={ fsutil behavior set disablelastaccess 1 } },

    # ========================== INTERFACE ==========================
    @{ Category="Interface"; Title="Menu Contexto Clássico (Win 10)"; Description="Desativa o menu 'Mostrar mais opções' do Windows 11."; Action={ New-Item "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" "(Default)" "" -Force } },
    @{ Category="Interface"; Title="Barra de Tarefas à Esquerda"; Description="Move os ícones da barra de tarefas para a esquerda."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarAl" 0 -Type DWord -Force } },
    @{ Category="Interface"; Title="Modo Escuro Global"; Description="Força o modo escuro para todo o sistema e aplicações."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "AppsUseLightTheme" 0 -Type DWord -Force; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "SystemUsesLightTheme" 0 -Type DWord -Force } },
    @{ Category="Interface"; Title="Ocultar TaskView, Chat, Widgets"; Description="Remove botões desnecessários da taskbar."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowTaskViewButton" 0 -Type DWord -Force; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "TaskbarMn" 0 -Type DWord -Force } },
    @{ Category="Interface"; Title="Mostrar Extensões de Ficheiros"; Description="Exibe as extensões (.exe, .pdf) por omissão no Explorador."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0 -Type DWord -Force } },
    @{ Category="Interface"; Title="Mostrar Ficheiros Ocultos"; Description="Exibe pastas e ficheiros ocultos."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1 -Type DWord -Force } },
    @{ Category="Interface"; Title="Mostrar Ficheiros de Sistema (Super Hidden)"; Description="Exibe ficheiros essenciais do SO."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowSuperHidden" 1 -Type DWord -Force } },
    @{ Category="Interface"; Title="Desativar Transparências (Acrylic)"; Description="Remove efeitos de transparência da UI."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0 -Type DWord -Force } },
    @{ Category="Interface"; Title="Remover Atraso do Aero Peek"; Description="Acelera a visualização de janelas ao passar o rato."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "DesktopLivePreviewHoverTime" 1 -Type DWord -Force } },
    @{ Category="Interface"; Title="Desativar Animações (UI Rápida)"; Description="Remove as animações de janelas."; Action={ Set-ItemProperty "HKCU:\Control Panel\Desktop" "UserPreferencesMask" ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary -Force; Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2 -Type DWord -Force } },
    @{ Category="Interface"; Title="Abrir Explorador em 'Este PC'"; Description="Faz com que o explorador abra em 'Este PC' em vez de 'Acesso Rápido'."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "LaunchTo" 1 -Type DWord -Force } },
    @{ Category="Interface"; Title="Remover Pasta 3D Objects"; Description="Remove 3D Objects do Explorador de ficheiros."; Action={ Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" -Recurse -ErrorAction SilentlyContinue } },
    @{ Category="Interface"; Title="Remover sufixo '- Atalho'"; Description="Impede a adição do nome '- Atalho' ao criar links."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer" "link" ([byte[]](0,0,0,0)) -Type Binary -Force } },
    @{ Category="Interface"; Title="Desativar ecrã de Setup (SCOOBE)"; Description="Desativa o ecrã 'Terminar configuração' pós-update."; Action={ Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\UserProfileEngagement" "ScoobeSystemSettingEnabled" 0 -Type DWord -Force } },
    @{ Category="Interface"; Title="Adicionar 'Copiar para' no menu contexto"; Description="Facilita mover/copiar ficheiros rapidamente."; Action={ New-Item "HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers\Copy To" "(Default)" "{C2FBB630-2971-11D1-A18C-00C04FD75D13}" -Force } },
    @{ Category="Interface"; Title="Adicionar 'Mover para' no menu contexto"; Description="Adiciona opção de mover ficheiros ao menu botão direito."; Action={ New-Item "HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKCR:\AllFilesystemObjects\shellex\ContextMenuHandlers\Move To" "(Default)" "{C2FBB631-2971-11D1-A18C-00C04FD75D13}" -Force } },

    # ========================== REDE E DNS ==========================
    @{ Category="Rede e DNS"; Title="DNS: Restaurar Automático (Padrão/ISP)"; Description="Remove os servidores DNS fixos e volta a obter os endereços automaticamente a partir do seu router (DHCP)."; Action={ Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses -ne $null} | Set-DnsClientServerAddress -ResetServerAddresses } },
    @{ Category="Rede e DNS"; Title="DNS: Cloudflare (1.1.1.1)"; Description="Configura adaptadores para o resolver Cloudflare."; Action={ Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses -ne $null} | Set-DnsClientServerAddress -ServerAddresses ("1.1.1.1","1.0.0.1") } },
    @{ Category="Rede e DNS"; Title="DNS: Control D (Uncensored)"; Description="Configura adaptadores para o resolver Control D."; Action={ Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses -ne $null} | Set-DnsClientServerAddress -ServerAddresses ("76.76.2.0","76.76.10.0") } },
    @{ Category="Rede e DNS"; Title="DNS: AdGuard (Bloqueador de Anúncios)"; Description="Configura adaptadores para o resolver AdGuard."; Action={ Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses -ne $null} | Set-DnsClientServerAddress -ServerAddresses ("94.140.14.14","94.140.15.15") } },
    @{ Category="Rede e DNS"; Title="DNS: Quad9 (Proteção Malware)"; Description="Configura adaptadores para o resolver Quad9."; Action={ Get-DnsClientServerAddress | Where-Object {$_.ServerAddresses -ne $null} | Set-DnsClientServerAddress -ServerAddresses ("9.9.9.9","149.112.112.112") } },
    @{ Category="Rede e DNS"; Title="Ativar DNS over HTTPS (DoH) Global"; Description="Habilita suporte nativo DoH no sistema."; Action={ Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" "EnableAutoDoh" 2 -Type DWord -Force } },
    @{ Category="Rede e DNS"; Title="Desativar Limite de Largura de Banda (QoS)"; Description="Remove o limite de 20% reservado pelo QoS nativo."; Action={ New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched" "NonBestEffortLimit" 0 -Type DWord -Force } },
    @{ Category="Rede e DNS"; Title="Desativar P2P Delivery Optimization"; Description="Impede que o seu PC seja usado para enviar atualizações de Windows para outros."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" "DODownloadMode" 0 -Type DWord -Force } },
    @{ Category="Rede e DNS"; Title="Desativar Pesquisa Web no Iniciar"; Description="Remove integração com Bing na barra de pesquisa."; Action={ New-Item "HKCU:\Software\Policies\Microsoft\Windows\Explorer" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKCU:\Software\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" 1 -Type DWord -Force } },
    @{ Category="Rede e DNS"; Title="Otimizar TCP (Disable Nagle Algorithm)"; Description="Reduz latência (ping) desativando o algoritmo de Nagle."; Action={ Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" "TcpAckFrequency" 1 -Type DWord -ErrorAction SilentlyContinue; Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\*" "TCPNoDelay" 1 -Type DWord -ErrorAction SilentlyContinue } },
    @{ Category="Rede e DNS"; Title="Otimizar TCP (Network Throttling)"; Description="Desativa o limitador de tráfego de rede para multimédia."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "NetworkThrottlingIndex" 0xFFFFFFFF -Type DWord -Force } },
    @{ Category="Rede e DNS"; Title="Otimizar TCP (System Responsiveness)"; Description="Define a prioridade da rede para aplicações em vez de tarefas de fundo."; Action={ Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" "SystemResponsiveness" 0 -Type DWord -Force } },
    @{ Category="Rede e DNS"; Title="Desativar NetBIOS sobre TCP/IP"; Description="Desativa protocolo antigo de resolução de nomes (NetBIOS)."; Action={ Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" "EnableLMHOSTS" 0 -Type DWord -Force } },
    @{ Category="Rede e DNS"; Title="Desativar IPv6"; Description="Desativa IPv6 se não for utilizado na sua rede local/ISP."; Action={ New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters" -Name "DisabledComponents" -Value 0xff -PropertyType DWord -Force -ErrorAction SilentlyContinue } },
    @{ Category="Rede e DNS"; Title="Desativar SMBv1"; Description="Desativa o protocolo inseguro SMBv1 para mitigar riscos de segurança."; Action={ Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -Confirm:$false -ErrorAction SilentlyContinue } },

    # ========================== SERVIÇOS E SEGURANÇA ==========================
    @{ Category="Serviços"; Title="Desativar Indexador de Pesquisa"; Description="Desativa a indexação de ficheiros se utilizar ferramentas como o 'Everything' ou apenas pesquisa por ficheiros."; Action={ Stop-Service "WSearch" -Force -WarningAction SilentlyContinue; Set-Service "WSearch" -StartupType Disabled -WarningAction SilentlyContinue } },
    @{ Category="Serviços"; Title="Desativar Print Spooler"; Description="Desativa a impressão se não for necessário imprimir documentos."; Action={ Stop-Service "Spooler" -Force -WarningAction SilentlyContinue; Set-Service "Spooler" -StartupType Disabled -WarningAction SilentlyContinue } },
    @{ Category="Serviços"; Title="Desativar Fax"; Description="Desativa o serviço de Fax, raramente utilizado."; Action={ Stop-Service "Fax" -Force -WarningAction SilentlyContinue; Set-Service "Fax" -StartupType Disabled -WarningAction SilentlyContinue } },
    @{ Category="Serviços"; Title="Desativar Serviços XBOX"; Description="Desativa serviços em segundo plano da Xbox se não jogar na app Xbox."; Action={ "XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc" | ForEach-Object { Stop-Service $_ -Force -WarningAction SilentlyContinue; Set-Service $_ -StartupType Disabled -WarningAction SilentlyContinue } } },
    @{ Category="Serviços"; Title="Desativar Windows Insider Service"; Description="Desativa os serviços de teste do Windows Insider."; Action={ Stop-Service "wisvc" -Force -WarningAction SilentlyContinue; Set-Service "wisvc" -StartupType Disabled -WarningAction SilentlyContinue } },
    @{ Category="Serviços"; Title="Desativar Maps Broker"; Description="Desativa o serviço de mapas que corre em segundo plano."; Action={ Stop-Service "MapsBroker" -Force -WarningAction SilentlyContinue; Set-Service "MapsBroker" -StartupType Disabled -WarningAction SilentlyContinue } },
    @{ Category="Serviços"; Title="Desativar Reinício por Updates"; Description="Impede que o Windows force reinícios com o utilizador logado."; Action={ New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" "NoAutoRebootWithLoggedOnUsers" 1 -Type DWord -Force } },
    @{ Category="Serviços"; Title="Excluir Drivers do Windows Update"; Description="Impede o Windows de atualizar drivers automaticamente."; Action={ New-Item "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Force -ErrorAction SilentlyContinue | Out-Null; Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" "ExcludeWUDriversInQualityUpdate" 1 -Type DWord -Force } },

    # ========================== LIMPEZA E MANUTENÇÃO ==========================
    @{ Category="Limpeza"; Title="Limpar Temp"; Description="Elimina ficheiros temporários das pastas TEMP."; Action={ Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path "$env:WINDIR\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue } },
    @{ Category="Limpeza"; Title="Limpar Prefetch"; Description="Elimina ficheiros na pasta Prefetch do sistema."; Action={ Remove-Item -Path "$env:WINDIR\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue } },
    @{ Category="Limpeza"; Title="Limpar Cache de Windows Update"; Description="Liberta espaço limpando a pasta SoftwareDistribution/Download."; Action={ Stop-Service "wuauserv" -Force -WarningAction SilentlyContinue; Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue; Start-Service "wuauserv" -WarningAction SilentlyContinue } },
    @{ Category="Limpeza"; Title="Flush DNS Cache"; Description="Limpa o cache de resolução de nomes (DNS)."; Action={ Clear-DnsClientCache } },
    @{ Category="Limpeza"; Title="Limpar Event Viewer"; Description="Apaga todos os logs de eventos do sistema."; Action={ wevtutil el | ForEach-Object { wevtutil cl "$_" 2>$null } } }
)

# ==============================================================================
# CONSTRUÇÃO DA INTERFACE GRÁFICA (LIGHT MODE CLÁSSICO)
# ==============================================================================
$FontMain = New-Object System.Drawing.Font("Segoe UI", 9.5)
$FontBold = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$FontTitle = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)

$Form = New-Object System.Windows.Forms.Form
$Form.Text = "TugaDebloat"
$Form.Size = New-Object System.Drawing.Size(850, 750)
$Form.StartPosition = "CenterScreen"
$Form.FormBorderStyle = "FixedDialog"
$Form.MaximizeBox = $false
$Form.BackColor = [System.Drawing.Color]::White

$HeaderLabel = New-Object System.Windows.Forms.Label
$HeaderLabel.Text = "TugaDebloat"
$HeaderLabel.Font = $FontTitle
$HeaderLabel.ForeColor = [System.Drawing.Color]::DarkBlue
$HeaderLabel.AutoSize = $true
$HeaderLabel.Location = New-Object System.Drawing.Point(20, 15)
$Form.Controls.Add($HeaderLabel)

$SubLabel = New-Object System.Windows.Forms.Label
$SubLabel.Text = "Selecione as definições a aplicar no sistema."
$SubLabel.Font = $FontMain
$SubLabel.Location = New-Object System.Drawing.Point(23, 48)
$SubLabel.AutoSize = $true
$Form.Controls.Add($SubLabel)

$TabControl = New-Object System.Windows.Forms.TabControl
$TabControl.Location = New-Object System.Drawing.Point(20, 85)
$TabControl.Size = New-Object System.Drawing.Size(800, 380)
$TabControl.Font = $FontMain
$Form.Controls.Add($TabControl)

$DescLabel = New-Object System.Windows.Forms.Label
$DescLabel.Text = "Detalhe da Otimização:"
$DescLabel.Font = $FontBold
$DescLabel.AutoSize = $true
$DescLabel.Location = New-Object System.Drawing.Point(20, 480)
$Form.Controls.Add($DescLabel)

$DescriptionBox = New-Object System.Windows.Forms.TextBox
$DescriptionBox.Location = New-Object System.Drawing.Point(20, 505)
$DescriptionBox.Size = New-Object System.Drawing.Size(800, 45)
$DescriptionBox.Multiline = $true
$DescriptionBox.ReadOnly = $true
$DescriptionBox.BackColor = [System.Drawing.Color]::Info
$DescriptionBox.BorderStyle = "FixedSingle"
$DescriptionBox.Font = $FontMain
$DescriptionBox.Text = "Selecione um item acima para visualizar a descrição."
$Form.Controls.Add($DescriptionBox)

$UpdateDescription = {
    param($SelectedItem)
    if ($SelectedItem) {
        $Tweak = $Global:Tweaks | Where-Object { $_.Title -eq $SelectedItem }
        if ($Tweak -and $Tweak.Description) {
            $DescriptionBox.Text = $Tweak.Description
        } else {
            $DescriptionBox.Text = "Modifica definições de registo e sistema relativas a esta funcionalidade."
        }
    }
}

$Categories = @("Privacidade", "Debloat Apps", "Desempenho", "Interface", "Rede e DNS", "Serviços", "Limpeza")
$CheckedListBoxes = @()

foreach ($Cat in $Categories) {
    $TabPage = New-Object System.Windows.Forms.TabPage
    $TabPage.Text = $Cat
    $TabPage.BackColor = [System.Drawing.Color]::White

    $CheckedListBox = New-Object System.Windows.Forms.CheckedListBox
    $CheckedListBox.Location = New-Object System.Drawing.Point(10, 45)
    $CheckedListBox.Size = New-Object System.Drawing.Size(770, 290)
    $CheckedListBox.CheckOnClick = $true
    $CheckedListBox.Font = $FontMain
    $CheckedListBox.BorderStyle = "None"
    
    # Evento para atualizar a descrição
    $CheckedListBox.Add_SelectedIndexChanged({
        if ($this.SelectedItem) {
            & $UpdateDescription $this.SelectedItem
        }
    })

    # Evento para exclusividade nos botões de DNS (simular RadioButton)
    $CheckedListBox.add_ItemCheck({
        param($sender, $e)
        $item = $sender.Items[$e.Index]
        
        # Se estamos a marcar um item que começa por "DNS:"
        if ($e.NewValue -eq [System.Windows.Forms.CheckState]::Checked -and $item -match "^DNS:") {
            # Percorrer todos os itens e desmarcar os outros que também começam por "DNS:"
            for ($i = 0; $i -lt $sender.Items.Count; $i++) {
                if ($i -ne $e.Index -and $sender.Items[$i] -match "^DNS:") {
                    $sender.SetItemChecked($i, $false)
                }
            }
        }
    })
    
    $BtnSelectAll = New-Object System.Windows.Forms.Button
    $BtnSelectAll.Text = "Marcar Todos"
    $BtnSelectAll.Location = New-Object System.Drawing.Point(10, 10)
    $BtnSelectAll.Size = New-Object System.Drawing.Size(130, 28)
    $BtnSelectAll.Add_Click({ for ($i=0; $i -lt $this.Parent.Controls[2].Items.Count; $i++) { $this.Parent.Controls[2].SetItemChecked($i, $true) } })
    
    $BtnSelectNone = New-Object System.Windows.Forms.Button
    $BtnSelectNone.Text = "Desmarcar Todos"
    $BtnSelectNone.Location = New-Object System.Drawing.Point(150, 10)
    $BtnSelectNone.Size = New-Object System.Drawing.Size(130, 28)
    $BtnSelectNone.Add_Click({ for ($i=0; $i -lt $this.Parent.Controls[2].Items.Count; $i++) { $this.Parent.Controls[2].SetItemChecked($i, $false) } })

    $TabPage.Controls.Add($BtnSelectAll)
    $TabPage.Controls.Add($BtnSelectNone)

    $CatTweaks = $Global:Tweaks | Where-Object { $_.Category -eq $Cat }
    foreach ($Tweak in $CatTweaks) { [void]$CheckedListBox.Items.Add($Tweak.Title, $false) }
    
    $TabPage.Controls.Add($CheckedListBox)
    $TabControl.TabPages.Add($TabPage)
    $CheckedListBoxes += $CheckedListBox
}

$LogBox = New-Object System.Windows.Forms.TextBox
$LogBox.Location = New-Object System.Drawing.Point(20, 560)
$LogBox.Size = New-Object System.Drawing.Size(800, 80)
$LogBox.Multiline = $true
$LogBox.ScrollBars = "Vertical"
$LogBox.ReadOnly = $true
$LogBox.BackColor = [System.Drawing.Color]::WhiteSmoke
$LogBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$Form.Controls.Add($LogBox)

function Write-Log($Message) {
    $LogBox.AppendText("[$((Get-Date).ToString('HH:mm:ss'))] $Message`r`n")
    $LogBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

$ApplyButton = New-Object System.Windows.Forms.Button
$ApplyButton.Text = "APLICAR OTIMIZAÇÕES"
$ApplyButton.Size = New-Object System.Drawing.Size(300, 45)
$ApplyButton.Location = New-Object System.Drawing.Point(275, 650)
$ApplyButton.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$ApplyButton.BackColor = [System.Drawing.Color]::FromArgb(0, 120, 215)
$ApplyButton.ForeColor = [System.Drawing.Color]::White
$ApplyButton.FlatStyle = "Flat"
$ApplyButton.Add_Click({
    $ApplyButton.Enabled = $false
    Write-Log "A iniciar..."
    foreach ($clb in $CheckedListBoxes) {
        foreach ($checkedItem in $clb.CheckedItems) {
            $TweakToRun = $Global:Tweaks | Where-Object { $_.Title -eq $checkedItem }
            if ($TweakToRun) {
                Write-Log "A aplicar: $($TweakToRun.Title)..."
                try { Invoke-Command -ScriptBlock $TweakToRun.Action -ErrorAction Stop } catch { Write-Log "[ERRO] $($_.Exception.Message)" }
            }
        }
    }
    Write-Log "Concluído."
    [System.Windows.Forms.MessageBox]::Show("Otimizações aplicadas.")
    $ApplyButton.Enabled = $true
})
$Form.Controls.Add($ApplyButton)

$SiteLink = New-Object System.Windows.Forms.LinkLabel
$SiteLink.Text = "Visite o TugaTech"
$SiteLink.Location = New-Object System.Drawing.Point(20, 665)
$SiteLink.AutoSize = $true
$SiteLink.Add_Click({ Start-Process "https://tugatech.com.pt" })
$Form.Controls.Add($SiteLink)

$CreditsLabel = New-Object System.Windows.Forms.Label
$CreditsLabel.Text = "Criado pelo TugaTech - por @DJPRMF"
$CreditsLabel.Location = New-Object System.Drawing.Point(580, 665)
$CreditsLabel.AutoSize = $true
$CreditsLabel.Font = $FontMain
$CreditsLabel.ForeColor = [System.Drawing.Color]::Gray
$Form.Controls.Add($CreditsLabel)

[void]$Form.ShowDialog()