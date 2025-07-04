#      全屏强制休息提醒脚本 - 稳定版 V3.1
# ===================================================================
# --- ✨ 全新！超级个性化定制区 ✨ ---

# 1. 强制休息的总时长（秒）
$BreakDurationSeconds = 20

# 2. 背景设置 (三选一)
$UseDesktopWallpaper = $true
$BackgroundImagePath = ''
$SolidBackgroundColor = 'Black'

# 3. 文字内容设置
$Title = "🦉👀 强制休息时间！"
$MainMessage = "身体是革命的本钱，请好好放松一下"
$Suggestions = "深呼吸 · 远眺窗外 · 让眼睛放松一下"

# 4. 专业功能增强
$OverlayTransparency = 150

# --- 核心代码区 (下面这部分复制就行，无需改动) ---

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 启用视觉样式
try {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    [System.Windows.Forms.Application]::SetCompatibleTextRenderingDefault($false)
} catch {
    # 忽略视觉样式设置错误
}

# 创建主窗口
$form = New-Object System.Windows.Forms.Form
$form.Text = $Title
$form.FormBorderStyle = 'None'
$form.WindowState = 'Maximized'
$form.TopMost = $true
$form.ShowInTaskbar = $false

# 安全地启用双缓冲
try {
    $form.GetType().GetProperty('DoubleBuffered', [System.Reflection.BindingFlags]'NonPublic,Instance').SetValue($form, $true)
} catch {
    # 如果双缓冲设置失败，继续执行
}

# --- 智能背景处理 ---
try {
    if ($UseDesktopWallpaper) {
        $wallpaperPath = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name Wallpaper -ErrorAction SilentlyContinue).Wallpaper
        if ($wallpaperPath -and (Test-Path $wallpaperPath -ErrorAction SilentlyContinue)) {
            $form.BackgroundImage = [System.Drawing.Image]::FromFile($wallpaperPath)
            $form.BackgroundImageLayout = 'Stretch'
        } else { 
            $form.BackColor = [System.Drawing.Color]::Black
        }
    } elseif (-not [string]::IsNullOrEmpty($BackgroundImagePath) -and (Test-Path $BackgroundImagePath -ErrorAction SilentlyContinue)) {
        $form.BackgroundImage = [System.Drawing.Image]::FromFile($BackgroundImagePath)
        $form.BackgroundImageLayout = 'Stretch'
    } else { 
        $form.BackColor = [System.Drawing.Color]::Black
    }
} catch { 
    $form.BackColor = [System.Drawing.Color]::Black
}

# 创建半透明遮罩层
$overlayPanel = New-Object System.Windows.Forms.Panel
$overlayPanel.Dock = 'Fill'
$overlayPanel.BackColor = [System.Drawing.Color]::FromArgb($OverlayTransparency, 0, 0, 0)

# 安全地为遮罩层启用双缓冲
try {
    $overlayPanel.GetType().GetProperty('DoubleBuffered', [System.Reflection.BindingFlags]'NonPublic,Instance').SetValue($overlayPanel, $true)
} catch {
    # 如果双缓冲设置失败，继续执行
}

$form.Controls.Add($overlayPanel)

# 创建核心显示标签
$label = New-Object System.Windows.Forms.Label
$label.Font = New-Object System.Drawing.Font('Microsoft YaHei', 24, [System.Drawing.FontStyle]::Bold)
$label.ForeColor = [System.Drawing.Color]::White
$label.BackColor = [System.Drawing.Color]::Transparent
$label.AutoSize = $false
$label.Dock = 'Fill'
$label.TextAlign = 'MiddleCenter'

# 安全地为标签启用双缓冲
try {
    $label.GetType().GetProperty('DoubleBuffered', [System.Reflection.BindingFlags]'NonPublic,Instance').SetValue($label, $true)
} catch {
    # 如果双缓冲设置失败，继续执行
}

$overlayPanel.Controls.Add($label)

# 剩余时间变量
$Script:remainingSeconds = $BreakDurationSeconds

# 创建更新文字的函数
function Update-CountdownText {
    try {
        $newText = "$MainMessage`n`n$Suggestions`n`n将在 $Script:remainingSeconds 秒后自动关闭..."
        
        # 只有在文字真的改变时才更新
        if ($label.Text -ne $newText) {
            $label.Text = $newText
        }
    } catch {
        # 如果更新失败，尝试简单更新
        $label.Text = "休息时间：$Script:remainingSeconds 秒"
    }
}

# 首次设置提醒文字
Update-CountdownText

# 创建计时器
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000

# 计时器事件处理
$timer.Add_Tick({
    try {
        $Script:remainingSeconds--
        Update-CountdownText
        
        if ($Script:remainingSeconds -le 0) {
            $timer.Stop()
            $form.Close()
        }
    } catch {
        # 如果计时器出错，强制关闭
        $timer.Stop()
        $form.Close()
    }
})

# 窗体显示事件
$form.Add_Shown({
    try {
        $timer.Start()
    } catch {
        # 如果计时器启动失败，设置备用关闭方式
        Start-Sleep -Seconds $BreakDurationSeconds
        $form.Close()
    }
})

# 窗体关闭事件，释放资源
$form.Add_FormClosed({
    try {
        if ($timer) {
            $timer.Stop()
            $timer.Dispose()
        }
        if ($form.BackgroundImage) {
            $form.BackgroundImage.Dispose()
        }
    } catch {
        # 忽略资源释放错误
    }
})

# 禁用快捷键关闭
$form.Add_KeyDown({
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::F4 -and $_.Alt) {
        $_.Handled = $true
    }
    if ($_.KeyCode -eq [System.Windows.Forms.Keys]::Escape) {
        $_.Handled = $true
    }
})

# 显示窗体
try {
    $result = $form.ShowDialog()
} catch {
    Write-Host "窗体显示时出现错误: $($_.Exception.Message)"
} finally {
    # 确保资源被释放
    try {
        if ($timer) { $timer.Dispose() }
        if ($form) { $form.Dispose() }
    } catch {
        # 忽略最终清理错误
    }
}

Write-Host "休息时间结束！"