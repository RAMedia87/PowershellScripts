﻿# Abfrage des Clientnamens
$clientName = Read-Host -Prompt "Bitte geben Sie den Namen des Clients ein"

if ([string]::IsNullOrWhiteSpace($clientName)) {
    Write-Host "Es wurde kein Clientname eingegeben. Das Skript wird beendet."
    exit
}

Write-Host "Verbindung wird mit Client '$clientName' hergestellt..."

# PowerShell Skript, das auf dem Remote-Client ausgeführt werden soll
$scriptBlock = {
    # Überprüfen, ob der Dienst "Intune Management Extension" läuft
    $serviceName = "IntuneManagementExtension"
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    # Wenn der Dienst läuft, stoppen wir ihn
    if ($service -and $service.Status -eq "Running") {
        Write-Host "Dienst '$serviceName' wird gestoppt..."
        Stop-Service -Name $serviceName -Force
        Start-Sleep -Seconds 5
    } else {
        Write-Host "Dienst '$serviceName' läuft nicht."
    }

    # Deinstallieren der Intune Management Extension (falls vorhanden)
    Write-Host "Deinstalliere Intune Management Extension..."
    $IMEPath = "C:\Program Files (x86)\Microsoft Intune Management Extension"
    if (Test-Path -Path $IMEPath) {
        $IMEUninstallPath = "$IMEPath\intunemanagementextension.exe"
        if (Test-Path -Path $IMEUninstallPath) {
            Write-Host "Starte Deinstallation der Intune Management Extension..."
            Start-Process -FilePath $IMEUninstallPath -ArgumentList "/uninstall" -Wait
        } else {
            Write-Host "Intune Management Extension Deinstallationsprogramm nicht gefunden."
        }
    } else {
        Write-Host "Intune Management Extension nicht installiert."
    }

    # Warten, bis die Deinstallation abgeschlossen ist
    Start-Sleep -Seconds 10

    # Überprüfen, ob das Verzeichnis noch existiert
    if (Test-Path -Path $IMEPath) {
        Write-Host "Verzeichnis Intune Management Extension wurde nicht entfernt, versuche manuelle Entfernung..."
        Remove-Item -Path $IMEPath -Recurse -Force
    }

    # Neuinstallation der Intune Management Extension (via Microsoft Intune)
    Write-Host "Starte Neuinstallation der Intune Management Extension..."
    $intuneInstallerPath = "C:\Program Files (x86)\Microsoft Intune Management Extension\intunemanagementextension.exe"
    if (-Not (Test-Path -Path $intuneInstallerPath)) {
        Write-Host "Intune Management Extension ist nicht im Standardpfad gefunden. Installiere über die neuesten Updates."
        # Hier könnte man den Befehl ausführen, um sicherzustellen, dass die neuesten Updates von Intune installiert werden.
        # Dies hängt davon ab, wie Intune in Ihrer Umgebung bereitgestellt wird (z.B. durch Windows Update oder eine manuelle Installation).
        # Beispiel: Start-Process -FilePath "IntuneInstaller.exe" -ArgumentList "/install"
    } else {
        Write-Host "Intune Management Extension ist bereits installiert."
    }

    # Service starten
    Write-Host "Starte Dienst '$serviceName'..."
    Start-Service -Name $serviceName

    Write-Host "Die Intune Management Extension wurde erfolgreich repariert."
}

# Skript remote ausführen
try {
    Invoke-Command -ComputerName $clientName -ScriptBlock $scriptBlock -Credential (Get-Credential) -ErrorAction Stop
} catch {
    Write-Host "Fehler beim Verbinden mit dem Client '$clientName': $_" -ForegroundColor Red
}
