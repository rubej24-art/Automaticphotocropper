param(
    [Parameter(Mandatory = $true)]
    [string]$SettingsFile
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

function Test-HexColor {
    param([string]$Value)
    return $Value -match '^#[0-9A-Fa-f]{6}$'
}

function Convert-HexToColor {
    param([string]$Value)

    if (-not (Test-HexColor -Value $Value)) {
        throw 'Цвет должен быть записан в формате #RRGGBB, например #FFFFFF.'
    }

    return [System.Drawing.ColorTranslator]::FromHtml($Value)
}

function Convert-ColorToHex {
    param([System.Drawing.Color]$Color)
    return '#{0:X2}{1:X2}{2:X2}' -f $Color.R, $Color.G, $Color.B
}

function Read-Settings {
    $defaults = [ordered]@{
        InputDir    = ''
        OutputDir   = ''
        OutputSize  = 330
        JpegQuality = 90
        SampleSize  = 8
        FillMode    = 'rowmatch'
        ManualColor = '#FFFFFF'
    }

    if (-not (Test-Path -LiteralPath $SettingsFile -PathType Leaf)) {
        return [pscustomobject]$defaults
    }

    try {
        $loaded = Get-Content -LiteralPath $SettingsFile -Raw -Encoding UTF8 |
            ConvertFrom-Json

        foreach ($name in @(
            'InputDir',
            'OutputDir',
            'OutputSize',
            'JpegQuality',
            'SampleSize',
            'FillMode',
            'ManualColor'
        )) {
            if ($loaded.PSObject.Properties.Name -contains $name) {
                $defaults[$name] = $loaded.$name
            }
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Не удалось прочитать старые настройки.`r`nБудут использованы значения по умолчанию.`r`n`r`n$($_.Exception.Message)",
            'Настройки',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }

    return [pscustomobject]$defaults
}

function Select-Folder {
    param(
        [System.Windows.Forms.TextBox]$Target,
        [string]$Description
    )

    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true

    if (-not [string]::IsNullOrWhiteSpace($Target.Text) -and
        (Test-Path -LiteralPath $Target.Text -PathType Container)) {
        $dialog.SelectedPath = $Target.Text
    }

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $Target.Text = $dialog.SelectedPath
    }

    $dialog.Dispose()
}

$settings = Read-Settings

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Настройки квадратных изображений'
$form.StartPosition = 'CenterScreen'
$form.ClientSize = New-Object System.Drawing.Size(820, 570)
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox = $false
$form.MinimizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Конвертация изображений в квадрат'
$title.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 15)
$title.Location = New-Object System.Drawing.Point(24, 18)
$title.Size = New-Object System.Drawing.Size(750, 34)
$form.Controls.Add($title)

$info = New-Object System.Windows.Forms.Label
$info.Text = 'Фото вписывается целиком без обрезки. Поля заполняются автоматически или выбранным вручную цветом.'
$info.Location = New-Object System.Drawing.Point(27, 55)
$info.Size = New-Object System.Drawing.Size(755, 43)
$form.Controls.Add($info)

$inputLabel = New-Object System.Windows.Forms.Label
$inputLabel.Text = 'Папка с исходными JPG, JPEG, JFIF и PNG:'
$inputLabel.Location = New-Object System.Drawing.Point(27, 105)
$inputLabel.Size = New-Object System.Drawing.Size(700, 23)
$form.Controls.Add($inputLabel)

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Location = New-Object System.Drawing.Point(30, 130)
$inputBox.Size = New-Object System.Drawing.Size(640, 27)
$inputBox.Text = [string]$settings.InputDir
$form.Controls.Add($inputBox)

$inputButton = New-Object System.Windows.Forms.Button
$inputButton.Text = 'Выбрать…'
$inputButton.Location = New-Object System.Drawing.Point(681, 128)
$inputButton.Size = New-Object System.Drawing.Size(105, 31)
$inputButton.Add_Click({
    Select-Folder -Target $inputBox -Description 'Выберите папку с исходными изображениями'
})
$form.Controls.Add($inputButton)

$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = 'Папка для готовых изображений:'
$outputLabel.Location = New-Object System.Drawing.Point(27, 170)
$outputLabel.Size = New-Object System.Drawing.Size(700, 23)
$form.Controls.Add($outputLabel)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(30, 195)
$outputBox.Size = New-Object System.Drawing.Size(640, 27)
$outputBox.Text = [string]$settings.OutputDir
$form.Controls.Add($outputBox)

$outputButton = New-Object System.Windows.Forms.Button
$outputButton.Text = 'Выбрать…'
$outputButton.Location = New-Object System.Drawing.Point(681, 193)
$outputButton.Size = New-Object System.Drawing.Size(105, 31)
$outputButton.Add_Click({
    Select-Folder -Target $outputBox -Description 'Выберите папку для готовых изображений'
})
$form.Controls.Add($outputButton)

$sizeLabel = New-Object System.Windows.Forms.Label
$sizeLabel.Text = 'Размер итогового квадрата:'
$sizeLabel.Location = New-Object System.Drawing.Point(30, 245)
$sizeLabel.Size = New-Object System.Drawing.Size(210, 23)
$form.Controls.Add($sizeLabel)

$sizeBox = New-Object System.Windows.Forms.NumericUpDown
$sizeBox.Location = New-Object System.Drawing.Point(240, 242)
$sizeBox.Size = New-Object System.Drawing.Size(105, 27)
$sizeBox.Minimum = 32
$sizeBox.Maximum = 4096
$sizeBox.Increment = 10
$sizeBox.Value = [Math]::Min(
    4096,
    [Math]::Max(32, [int]$settings.OutputSize)
)
$form.Controls.Add($sizeBox)

$sizeHint = New-Object System.Windows.Forms.Label
$sizeHint.Text = 'пикселей; результат будет N × N'
$sizeHint.Location = New-Object System.Drawing.Point(357, 245)
$sizeHint.Size = New-Object System.Drawing.Size(300, 23)
$sizeHint.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($sizeHint)

$qualityLabel = New-Object System.Windows.Forms.Label
$qualityLabel.Text = 'Качество JPEG:'
$qualityLabel.Location = New-Object System.Drawing.Point(30, 285)
$qualityLabel.Size = New-Object System.Drawing.Size(150, 23)
$form.Controls.Add($qualityLabel)

$qualityBox = New-Object System.Windows.Forms.NumericUpDown
$qualityBox.Location = New-Object System.Drawing.Point(180, 282)
$qualityBox.Size = New-Object System.Drawing.Size(90, 27)
$qualityBox.Minimum = 1
$qualityBox.Maximum = 100
$qualityBox.Value = [Math]::Min(
    100,
    [Math]::Max(1, [int]$settings.JpegQuality)
)
$form.Controls.Add($qualityBox)

$qualityHint = New-Object System.Windows.Forms.Label
$qualityHint.Text = '90 — хороший баланс качества и размера'
$qualityHint.Location = New-Object System.Drawing.Point(283, 285)
$qualityHint.Size = New-Object System.Drawing.Size(340, 23)
$qualityHint.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($qualityHint)

$modeLabel = New-Object System.Windows.Forms.Label
$modeLabel.Text = 'Режим заполнения полей:'
$modeLabel.Location = New-Object System.Drawing.Point(30, 325)
$modeLabel.Size = New-Object System.Drawing.Size(210, 23)
$form.Controls.Add($modeLabel)

$modeBox = New-Object System.Windows.Forms.ComboBox
$modeBox.Location = New-Object System.Drawing.Point(240, 322)
$modeBox.Size = New-Object System.Drawing.Size(390, 28)
$modeBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
[void]$modeBox.Items.Add('rowmatch — построчное продолжение фона')
[void]$modeBox.Items.Add('gradient — автоматический градиент')
[void]$modeBox.Items.Add('side — автоматические цвета сторон')
[void]$modeBox.Items.Add('manual — один цвет вручную')

switch (([string]$settings.FillMode).ToLowerInvariant()) {
    'gradient' { $modeBox.SelectedIndex = 1 }
    'side'     { $modeBox.SelectedIndex = 2 }
    'manual'   { $modeBox.SelectedIndex = 3 }
    default    { $modeBox.SelectedIndex = 0 }
}
$form.Controls.Add($modeBox)

$sampleLabel = New-Object System.Windows.Forms.Label
$sampleLabel.Text = 'Толщина автоматической выборки:'
$sampleLabel.Location = New-Object System.Drawing.Point(30, 365)
$sampleLabel.Size = New-Object System.Drawing.Size(245, 23)
$form.Controls.Add($sampleLabel)

$sampleBox = New-Object System.Windows.Forms.NumericUpDown
$sampleBox.Location = New-Object System.Drawing.Point(275, 362)
$sampleBox.Size = New-Object System.Drawing.Size(90, 27)
$sampleBox.Minimum = 2
$sampleBox.Maximum = 100
$sampleBox.Value = [Math]::Min(
    100,
    [Math]::Max(2, [int]$settings.SampleSize)
)
$form.Controls.Add($sampleBox)

$sampleHint = New-Object System.Windows.Forms.Label
$sampleHint.Text = 'пикселей; для rowmatch, gradient и side'
$sampleHint.Location = New-Object System.Drawing.Point(378, 365)
$sampleHint.Size = New-Object System.Drawing.Size(390, 23)
$sampleHint.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($sampleHint)

$colorLabel = New-Object System.Windows.Forms.Label
$colorLabel.Text = 'Цвет фона вручную:'
$colorLabel.Location = New-Object System.Drawing.Point(30, 405)
$colorLabel.Size = New-Object System.Drawing.Size(180, 23)
$form.Controls.Add($colorLabel)

$colorBox = New-Object System.Windows.Forms.TextBox
$colorBox.Location = New-Object System.Drawing.Point(210, 402)
$colorBox.Size = New-Object System.Drawing.Size(120, 27)
$colorBox.Text = [string]$settings.ManualColor
$form.Controls.Add($colorBox)

$colorPreview = New-Object System.Windows.Forms.Panel
$colorPreview.Location = New-Object System.Drawing.Point(342, 402)
$colorPreview.Size = New-Object System.Drawing.Size(46, 27)
$colorPreview.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($colorPreview)

$colorButton = New-Object System.Windows.Forms.Button
$colorButton.Text = 'Выбрать цвет…'
$colorButton.Location = New-Object System.Drawing.Point(401, 399)
$colorButton.Size = New-Object System.Drawing.Size(135, 33)
$form.Controls.Add($colorButton)

$colorHint = New-Object System.Windows.Forms.Label
$colorHint.Text = 'HEX, например #FFFFFF'
$colorHint.Location = New-Object System.Drawing.Point(549, 405)
$colorHint.Size = New-Object System.Drawing.Size(210, 23)
$colorHint.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($colorHint)

function Update-ColorPreview {
    $value = $colorBox.Text.Trim()

    if (Test-HexColor -Value $value) {
        $colorPreview.BackColor = Convert-HexToColor -Value $value
    }
    else {
        $colorPreview.BackColor = [System.Drawing.Color]::White
    }
}

function Update-ModeControls {
    $manual = $modeBox.SelectedIndex -eq 3

    $sampleBox.Enabled = -not $manual
    $sampleHint.Enabled = -not $manual
    $colorBox.Enabled = $manual
    $colorPreview.Enabled = $manual
    $colorButton.Enabled = $manual
    $colorHint.Enabled = $manual
}

$modeBox.Add_SelectedIndexChanged({
    Update-ModeControls
})

$colorBox.Add_TextChanged({
    Update-ColorPreview
})

$colorButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.ColorDialog
    $dialog.FullOpen = $true

    if (Test-HexColor -Value $colorBox.Text.Trim()) {
        $dialog.Color = Convert-HexToColor -Value $colorBox.Text.Trim()
    }

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $colorBox.Text = Convert-ColorToHex -Color $dialog.Color
    }

    $dialog.Dispose()
})

Update-ColorPreview
Update-ModeControls

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = 'Сохранить'
$saveButton.Location = New-Object System.Drawing.Point(574, 505)
$saveButton.Size = New-Object System.Drawing.Size(102, 38)
$form.Controls.Add($saveButton)

$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = 'Отмена'
$cancelButton.Location = New-Object System.Drawing.Point(684, 505)
$cancelButton.Size = New-Object System.Drawing.Size(102, 38)
$form.Controls.Add($cancelButton)

$saveButton.Add_Click({
    $inputPath = $inputBox.Text.Trim().Trim('"')
    $outputPath = $outputBox.Text.Trim().Trim('"')

    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        [System.Windows.Forms.MessageBox]::Show(
            'Укажите папку с исходными изображениями.',
            'Не заполнено',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    if (-not (Test-Path -LiteralPath $inputPath -PathType Container)) {
        [System.Windows.Forms.MessageBox]::Show(
            'Исходная папка не существует.',
            'Неверный путь',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    if ([string]::IsNullOrWhiteSpace($outputPath)) {
        [System.Windows.Forms.MessageBox]::Show(
            'Укажите папку для готовых изображений.',
            'Не заполнено',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    try {
        $inputFull = [System.IO.Path]::GetFullPath($inputPath).TrimEnd('\', '/')
        $outputFull = [System.IO.Path]::GetFullPath($outputPath).TrimEnd('\', '/')
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            'Один из путей указан неверно.',
            'Неверный путь',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    if ($inputFull.Equals(
        $outputFull,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        [System.Windows.Forms.MessageBox]::Show(
            'Входная и выходная папки должны отличаться.',
            'Неверные настройки',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $fillMode = switch ($modeBox.SelectedIndex) {
        1 { 'gradient' }
        2 { 'side' }
        3 { 'manual' }
        default { 'rowmatch' }
    }

    $manualColor = $colorBox.Text.Trim().ToUpperInvariant()

    if ($fillMode -eq 'manual' -and
        -not (Test-HexColor -Value $manualColor)) {
        [System.Windows.Forms.MessageBox]::Show(
            'Укажите цвет в формате #RRGGBB, например #FFFFFF.',
            'Неверный цвет',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    if (-not (Test-HexColor -Value $manualColor)) {
        $manualColor = '#FFFFFF'
    }

    $data = [ordered]@{
        InputDir    = $inputFull
        OutputDir   = $outputFull
        OutputSize  = [int]$sizeBox.Value
        JpegQuality = [int]$qualityBox.Value
        SampleSize  = [int]$sampleBox.Value
        FillMode    = $fillMode
        ManualColor = $manualColor
    }

    try {
        $json = $data | ConvertTo-Json
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($SettingsFile, $json, $utf8)

        [System.Windows.Forms.MessageBox]::Show(
            'Настройки сохранены.',
            'Готово',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null

        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Не удалось сохранить настройки:`r`n$($_.Exception.Message)",
            'Ошибка',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    }
})

$cancelButton.Add_Click({
    $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Close()
})

$form.AcceptButton = $saveButton
$form.CancelButton = $cancelButton

[void]$form.ShowDialog()
