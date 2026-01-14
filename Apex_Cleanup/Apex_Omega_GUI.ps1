<#
    .SYNOPSIS
    APEX OMEGA PROTOCOL - SINGULARITY INTERFACE (V8.0 FINAL)
    ENGINE: HYBRID CORE (PS5.1 / PS7 COMPATIBLE)
    RENDER: WPF HARDWARE ACCELERATED
    STATUS: GOLD MASTER
#>

# ---------------------------------------------------------
# 0. KERNEL PRE-FLIGHT
# ---------------------------------------------------------
$ErrorActionPreference = "Stop"

# 1. Assemblies laden (Silent Try/Catch für Robustheit)
try {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName WindowsBase
} catch {
    [System.Windows.Forms.MessageBox]::Show("CRITICAL KERNEL FAILURE: .NET Assemblies missing.`n$_", "APEX CRASH", 0, 16)
    Exit
}

# 2. Host Detection (Wer bin ich? V5 oder V7?)
$PSVersion = $PSVersionTable.PSVersion.Major
if ($PSScriptRoot) { $RootPath = $PSScriptRoot } 
else { $RootPath = [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\') }

# 3. Backend-Engine festlegen (Damit Sub-Prozesse sauber starten)
if ($PSVersion -ge 7) { $BackendExe = "pwsh" } else { $BackendExe = "powershell" }

# ---------------------------------------------------------
# 1. VISUAL CORTEX (XAML - OPTIMIZED RENDER)
# ---------------------------------------------------------
# TextOptions.TextFormattingMode="Display" sorgt für gestochen scharfe Schrift
# UseLayoutRounding="True" verhindert verwaschene Linien
[xml]$XAML = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="APEX OMEGA COMMANDER" Height="750" Width="1100"
        WindowStyle="None" ResizeMode="NoResize" AllowsTransparency="True"
        Background="Transparent" WindowStartupLocation="CenterScreen"
        UseLayoutRounding="True" TextOptions.TextFormattingMode="Display">

    <Window.Resources>
        <!-- COLOR MATRIX 2100 -->
        <SolidColorBrush x:Key="VoidBrush" Color="#F2050505"/> <!-- Deep Black -->
        <SolidColorBrush x:Key="CyanNeon" Color="#00E5FF"/>
        <SolidColorBrush x:Key="GoldNeon" Color="#D4AF37"/>
        <SolidColorBrush x:Key="AlertRed" Color="#FF2040"/>
        <SolidColorBrush x:Key="TextMain" Color="#F5F5F5"/>
        <SolidColorBrush x:Key="TextDim" Color="#888888"/>
        <SolidColorBrush x:Key="PanelBack" Color="#08FFFFFF"/> 

        <!-- CYBER BUTTON STYLE -->
        <Style TargetType="Button" x:Key="CyberButton">
            <Setter Property="Background" Value="#05FFFFFF"/>
            <Setter Property="Foreground" Value="{StaticResource CyanNeon}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="#4000E5FF"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Name="border" Background="{TemplateBinding Background}" 
                                BorderBrush="{TemplateBinding BorderBrush}" 
                                BorderThickness="{TemplateBinding BorderThickness}" 
                                CornerRadius="0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#2000E5FF"/>
                                <Setter TargetName="border" Property="BorderBrush" Value="{StaticResource CyanNeon}"/>
                                <Setter Property="Foreground" Value="White"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="{StaticResource CyanNeon}"/>
                                <Setter Property="Foreground" Value="Black"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="BorderBrush" Value="#303030"/>
                                <Setter Property="Foreground" Value="#505050"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- QUANTUM TOGGLE STYLE -->
        <Style TargetType="CheckBox" x:Key="ToggleSwitch">
            <Setter Property="Foreground" Value="{StaticResource TextMain}"/>
            <Setter Property="Background" Value="#151515"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="CheckBox">
                        <Grid Margin="0,5,0,5">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="60"/>
                            </Grid.ColumnDefinitions>
                            
                            <!-- Text Label -->
                            <StackPanel Grid.Column="0" VerticalAlignment="Center" Margin="0,0,10,0">
                                <TextBlock Text="{TemplateBinding Content}" FontSize="13" FontWeight="Bold" Foreground="{StaticResource TextMain}"/>
                                <TextBlock Name="DescText" Text="{Binding Tag, RelativeSource={RelativeSource TemplatedParent}}" FontSize="10" Foreground="{StaticResource TextDim}" TextWrapping="Wrap" Margin="0,2,0,0"/>
                            </StackPanel>
                            
                            <!-- The Switch -->
                            <Border Grid.Column="1" Width="50" Height="26" CornerRadius="0" Background="{TemplateBinding Background}" BorderBrush="#404040" BorderThickness="1">
                                <Rectangle Name="Rect" Width="20" Height="18" Fill="#606060" HorizontalAlignment="Left" Margin="3,0,0,0"/>
                            </Border>
                        </Grid>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsChecked" Value="True">
                                <Setter Property="Background" Value="#151515"/>
                                <Setter TargetName="Rect" Property="Fill" Value="{StaticResource CyanNeon}"/>
                                <Setter TargetName="Rect" Property="HorizontalAlignment" Value="Right"/>
                                <Setter TargetName="Rect" Property="Margin" Value="0,0,3,0"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <!-- MASTER FRAME -->
    <Border Background="{StaticResource VoidBrush}" BorderBrush="{StaticResource CyanNeon}" BorderThickness="1">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="60"/> <!-- Head -->
                <RowDefinition Height="*"/>  <!-- Body -->
                <RowDefinition Height="40"/> <!-- Foot -->
            </Grid.RowDefinitions>

            <!-- HEADER -->
            <Grid Grid.Row="0" Name="DragZone" Background="#10FFFFFF">
                <TextBlock Text="APEX OMEGA // SINGULARITY" Foreground="{StaticResource GoldNeon}" FontSize="16" FontWeight="Bold" VerticalAlignment="Center" Margin="20,0,0,0" IsHitTestVisible="False"/>
                <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,10,0">
                    <Button Name="BtnMin" Content="_" Width="40" Height="30" Style="{StaticResource CyberButton}" Margin="5" VerticalAlignment="Top"/>
                    <Button Name="BtnClose" Content="X" Width="40" Height="30" Style="{StaticResource CyberButton}" Margin="5" Foreground="{StaticResource AlertRed}" VerticalAlignment="Top"/>
                </StackPanel>
            </Grid>

            <!-- CORE -->
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="280"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- LEFT RAIL -->
                <Border Grid.Column="0" Background="{StaticResource PanelBack}" BorderBrush="#20FFFFFF" BorderThickness="0,0,1,0">
                    <StackPanel Margin="20">
                        <TextBlock Text="/// PRESETS" Foreground="{StaticResource TextDim}" FontSize="10" Margin="0,0,0,15"/>
                        
                        <Button Name="PreGame" Content="GAMER OPTIMIZATION" Height="45" Style="{StaticResource CyberButton}" Margin="0,0,0,15"/>
                        <TextBlock Text="MAX FPS / LOW LATENCY" Foreground="#505050" FontSize="9" FontWeight="Bold" Margin="2,-12,0,20"/>

                        <Button Name="PreLock" Content="FORTRESS LOCKDOWN" Height="45" Style="{StaticResource CyberButton}" Margin="0,0,0,15" Foreground="{StaticResource AlertRed}"/>
                        <TextBlock Text="ZERO TOLERANCE SECURITY" Foreground="#505050" FontSize="9" FontWeight="Bold" Margin="2,-12,0,20"/>

                        <Rectangle Height="1" Fill="#20FFFFFF" Margin="0,20"/>
                        
                        <TextBlock Text="/// UTILITIES" Foreground="{StaticResource TextDim}" FontSize="10" Margin="0,0,0,15"/>
                        <Button Name="ToolGate" Content="GATEKEEPER (UNLOCK)" Height="35" Style="{StaticResource CyberButton}" Margin="0,0,0,10"/>
                        <Button Name="ToolAudit" Content="SYSTEM AUDIT" Height="35" Style="{StaticResource CyberButton}"/>
                    </StackPanel>
                </Border>

                <!-- MAIN DECK -->
                <ScrollViewer Grid.Column="1" VerticalScrollBarVisibility="Auto" Margin="25">
                    <StackPanel>
                        <TextBlock Text="MODULE CONFIGURATION MATRIX" Foreground="{StaticResource CyanNeon}" FontSize="14" FontWeight="Bold" Margin="0,0,0,20"/>

                        <!-- BLOCK 1 -->
                        <Border BorderBrush="#20FFFFFF" BorderThickness="1" Padding="15" Margin="0,0,0,15" Background="{StaticResource PanelBack}">
                            <StackPanel>
                                <TextBlock Text="[A] SYSTEM HYGIENE" Foreground="{StaticResource GoldNeon}" FontSize="11" Margin="0,0,0,10"/>
                                <CheckBox Name="chkClean" Content="VISUAL PURGE" Tag="Removes Bing, Suggestions, Edge Sidebar &amp; Ads." Style="{StaticResource ToggleSwitch}" IsChecked="True"/>
                                <CheckBox Name="chkBloat" Content="APP EXORCISM" Tag="Removes CandyCrush, Xbox, Solitaire &amp; Bloat." Style="{StaticResource ToggleSwitch}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                        <!-- BLOCK 2 -->
                        <Border BorderBrush="#20FFFFFF" BorderThickness="1" Padding="15" Margin="0,0,0,15" Background="{StaticResource PanelBack}">
                            <StackPanel>
                                <TextBlock Text="[B] PRIVACY SHIELD" Foreground="{StaticResource GoldNeon}" FontSize="11" Margin="0,0,0,10"/>
                                <CheckBox Name="chkLock" Content="TELEMETRY KILL" Tag="Disables DiagTrack, WerSvc &amp; Data Collection." Style="{StaticResource ToggleSwitch}" IsChecked="True"/>
                                <CheckBox Name="chkDNS" Content="DNS ENCRYPTION" Tag="Routes traffic via Mullvad/Quad9 (No Logs)." Style="{StaticResource ToggleSwitch}" IsChecked="True"/>
                                <CheckBox Name="chkSec" Content="GHOST PROTOCOL" Tag="Disables SMBv1, NetBIOS, LLMNR (Anti-Hack)." Style="{StaticResource ToggleSwitch}" IsChecked="True"/>
                            </StackPanel>
                        </Border>

                        <!-- BLOCK 3 -->
                        <Border BorderBrush="#20FFFFFF" BorderThickness="1" Padding="15" Margin="0,0,0,15" Background="{StaticResource PanelBack}">
                            <StackPanel>
                                <TextBlock Text="[C] FIREWALL STRATEGY" Foreground="{StaticResource GoldNeon}" FontSize="11" Margin="0,0,0,10"/>
                                <Grid Margin="0,5,0,0">
                                    <Grid.ColumnDefinitions>
                                        <ColumnDefinition Width="*"/>
                                        <ColumnDefinition Width="*"/>
                                    </Grid.ColumnDefinitions>
                                    <RadioButton Name="RadGame" Grid.Column="0" Content="GAMING (BALANCED)" Foreground="White" IsChecked="True" GroupName="Strat" Margin="5"/>
                                    <RadioButton Name="RadFort" Grid.Column="1" Content="FORTRESS (STRICT)" Foreground="White" GroupName="Strat" Margin="5"/>
                                </Grid>
                            </StackPanel>
                        </Border>

                        <!-- DANGER ZONE -->
                         <Border BorderBrush="{StaticResource AlertRed}" BorderThickness="1" Padding="15" Margin="0,0,0,15" Background="#08FF0000">
                            <StackPanel>
                                <TextBlock Text="[!] DANGER ZONE" Foreground="{StaticResource AlertRed}" FontSize="11" FontWeight="Bold" Margin="0,0,0,10"/>
                                <CheckBox Name="chkSil" Content="WINDOWS SILENCE" Tag="WARNING: PERMANENTLY DESTROYS WINDOWS UPDATE." Style="{StaticResource ToggleSwitch}" IsChecked="False"/>
                            </StackPanel>
                        </Border>

                        <Button Name="BtnEngage" Content="INITIATE OPTIMIZATION" Height="55" FontSize="14" Style="{StaticResource CyberButton}" Background="#15D4AF37" BorderBrush="{StaticResource GoldNeon}" Margin="0,10,0,0"/>
                    </StackPanel>
                </ScrollViewer>
            </Grid>

            <!-- FOOTER -->
            <Grid Grid.Row="2" Background="#15000000">
                <TextBlock Name="StatusTxt" Text="SYSTEM ONLINE. WAITING FOR COMMAND." Foreground="{StaticResource TextDim}" FontSize="11" VerticalAlignment="Center" Margin="20,0,0,0" FontFamily="Consolas"/>
                <TextBlock Text="V8.0" Foreground="#303030" FontSize="10" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,20,0"/>
            </Grid>
        </Grid>
    </Border>
</Window>
'@

# ---------------------------------------------------------
# 2. PARSE ENGINE
# ---------------------------------------------------------
try {
    $Reader = (New-Object System.Xml.XmlNodeReader $XAML)
    $Window = [Windows.Markup.XamlReader]::Load($Reader)
} catch {
    # Falls das hier passiert, ist das XAML kaputt. Message Box statt Console Error.
    [System.Windows.Forms.MessageBox]::Show("VISUAL CORE FAILURE.`nDetails: $_", "FATAL ERROR", 0, 16)
    Exit
}

# Auto-Binding von XAML Objekten an PowerShell Variablen
$Nodes = $XAML.SelectNodes("//*[@Name]")
foreach ($Node in $Nodes) {
    Set-Variable -Name $Node.Name -Value $Window.FindName($Node.Name) -Scope Global
}

# ---------------------------------------------------------
# 3. LOGIC CONTROLLER (MANUAL EVENT BINDING)
# ---------------------------------------------------------

# --- Window Movement ---
# Wir nutzen DragZone (Header), damit man das Fenster bewegen kann
$DragZone.Add_MouseLeftButtonDown({ $Window.DragMove() })
$BtnMin.Add_Click({ $Window.WindowState = "Minimized" })
$BtnClose.Add_Click({ $Window.Close() })

# --- UI Helper ---
function Set-Status ($Msg, $Color="Gray") {
    try {
        $StatusTxt.Text = "> $Msg"
        if ($Color -eq "Red") { $StatusTxt.Foreground = [System.Windows.Media.Brushes]::Red }
        elseif ($Color -eq "Green") { $StatusTxt.Foreground = [System.Windows.Media.Brushes]::Lime }
        elseif ($Color -eq "Cyan") { $StatusTxt.Foreground = [System.Windows.Media.Brushes]::Cyan }
        elseif ($Color -eq "Gold") { $StatusTxt.Foreground = [System.Windows.Media.Brushes]::Gold }
        else { $StatusTxt.Foreground = [System.Windows.Media.Brushes]::Gray }
        
        # Async Refresh, damit die GUI nicht einfriert
        [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::ContextIdle)
    } catch {}
}

# --- Presets ---
$PreGame.Add_Click({
    Set-Status "LOADING: GAMING CONFIGURATION..." "Green"
    $chkClean.IsChecked = $true
    $chkBloat.IsChecked = $true
    $chkLock.IsChecked = $true
    $chkDNS.IsChecked = $true
    $chkSec.IsChecked = $true
    $chkSil.IsChecked = $false
    $RadGame.IsChecked = $true
})

$PreLock.Add_Click({
    Set-Status "LOADING: FORTRESS CONFIGURATION..." "Red"
    $chkClean.IsChecked = $true
    $chkBloat.IsChecked = $true
    $chkLock.IsChecked = $true
    $chkDNS.IsChecked = $true
    $chkSec.IsChecked = $true
    # Silence ist immer optional, zu gefährlich für Auto-Check
    $RadFort.IsChecked = $true
})

# --- External Tools ---
# Wir nutzen hier $BackendExe (pwsh oder powershell), damit Version konsistent bleibt
$ToolAudit.Add_Click({
    Set-Status "STARTING AUDIT SUB-SYSTEM..."
    Start-Process $BackendExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$RootPath\Audit_Apex.ps1`""
})

$ToolGate.Add_Click({
    Set-Status "STARTING GATEKEEPER..."
    if ($RadFort.IsChecked) {
        Start-Process $BackendExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$RootPath\Full Fortress Pfad\Gatekeeper_Full.ps1`""
    } else {
        Start-Process $BackendExe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -NoExit -File `"$RootPath\Gaming Pfad\Gatekeeper_Gaming.ps1`""
    }
})

# --- EXECUTION ENGINE ---
$BtnEngage.Add_Click({
    $BtnEngage.IsEnabled = $false
    $BtnEngage.Content = "PROCESSING..."
    Set-Status "INITIALIZING SEQUENCE..." "Green"
    
    # Snapshot der Konfiguration
    $Config = @{
        Clean = $chkClean.IsChecked; Bloat = $chkBloat.IsChecked; Lock = $chkLock.IsChecked
        Sec = $chkSec.IsChecked; DNS = $chkDNS.IsChecked; Sil = $chkSil.IsChecked
        Strategy = if ($RadGame.IsChecked) { "GAMING" } else { "FORTRESS" }
    }

    # Logik-Block (Läuft synchron im Hauptthread mit UI Updates)
    $ExecLogic = {
        Start-Sleep -Milliseconds 250

        # Helper Funktion für saubere Pfade
        function Run-Safe ($RelPath) {
            $Path = Join-Path $RootPath $RelPath
            if (Test-Path $Path) {
                # Wir rufen den Code direkt im aktuellen Scope auf für maximale Geschwindigkeit
                # oder starten einen Prozess wenn Isolation gewünscht ist.
                # Hier: Direktaufruf via Dot-Sourcing (schneller, bessere Fehleranzeige)
                try {
                    & $Path
                    return $true
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("ERROR executing $RelPath `nDetails: $_", "MODULE ERROR", 0, 16)
                    return $false
                }
            } else {
                [System.Windows.Forms.MessageBox]::Show("MISSING FILE: $RelPath", "FILE ERROR", 0, 48)
                return $false
            }
        }

        if ($Config.Clean) { Set-Status "EXEC: VISUAL CLEANUP..." "Cyan"; Run-Safe "Basic\Cleanup.ps1" }
        if ($Config.Bloat) { Set-Status "EXEC: APP EXORCISM..." "Cyan"; Run-Safe "Basic\DeBloat.ps1" }
        if ($Config.Lock)  { Set-Status "EXEC: TELEMETRY LOCKDOWN..." "Cyan"; Run-Safe "Basic\Lockdown.ps1" }
        if ($Config.Sec)   { Set-Status "EXEC: GHOST PROTOCOL..." "Cyan"; Run-Safe "Basic\Security_Hardening_Ghost.ps1" }
        if ($Config.DNS)   { Set-Status "EXEC: DNS SHIELD..." "Cyan"; Run-Safe "Basic\DNS_Privacy.ps1" }
        
        if ($Config.Sil)   { Set-Status "EXEC: WINDOWS SILENCE..." "Red"; Run-Safe "Windows Silence\Windows_Silence.ps1" }

        if ($Config.Strategy -eq "GAMING") {
             Set-Status "APPLYING: GAMING PROFILE..." "Gold"
             Run-Safe "Gaming Pfad\Gaming_Boost.ps1"
             Run-Safe "Gaming Pfad\Defender_Gaming.ps1"
        } else {
             Set-Status "APPLYING: FORTRESS PROFILE..." "Red"
             Run-Safe "Full Fortress Pfad\Full_Lockdown.ps1"
             Run-Safe "Full Fortress Pfad\Defender_Fortress.ps1"
        }

        Set-Status "OPTIMIZATION COMPLETE." "Green"
        [System.Windows.Forms.MessageBox]::Show("OPTIMIZATION SUCCESSFUL.`nPLEASE RESTART YOUR SYSTEM.", "APEX OMEGA", 0, 64)
        
        $BtnEngage.IsEnabled = $true
        $BtnEngage.Content = "INITIATE OPTIMIZATION"
    }
    
    # Ausführen
    & $ExecLogic
})

# ---------------------------------------------------------
# 4. IGNITION
# ---------------------------------------------------------
try {
    $Window.ShowDialog() | Out-Null
} catch {
    [System.Windows.Forms.MessageBox]::Show("CRITICAL UI CRASH.`n$_", "APEX CRASH", 0, 16)
}