# Automaticphotocropper
============================================================
1. RUN.BAT — ГЛАВНЫЙ ЗАПУСК ПРОГРАММЫ
============================================================


КОД:

@echo off
chcp 65001 >nul
setlocal


КОММЕНТАРИЙ:

@echo off отключает показ выполняемых CMD-команд.

chcp 65001 переключает консоль на UTF-8, чтобы русский текст
отображался нормально.

>nul скрывает служебное сообщение команды chcp.

setlocal создаёт локальную область переменных. После завершения BAT
эти переменные не останутся в системе.


------------------------------------------------------------

КОД:

set "BASE=%~dp0"
set "SCRIPT=%BASE%SquarePhotos.ps1"
set "SETTINGS=%BASE%settings.json"
set "SETTINGS_LAUNCHER=%BASE%Settings.bat"


КОММЕНТАРИЙ:

%~dp0 возвращает папку, в которой находится Run.bat.

BASE хранит путь к папке программы.

SCRIPT хранит путь к основному обработчику изображений.

SETTINGS хранит путь к файлу настроек.

SETTINGS_LAUNCHER хранит путь к BAT-файлу, который открывает окно
настроек.


------------------------------------------------------------

КОД:

if not exist "%SCRIPT%" (
    echo ОШИБКА: рядом не найден SquarePhotos.ps1
    pause
    exit /b 1
)


КОММЕНТАРИЙ:

Проверяет, лежит ли рядом основной PowerShell-скрипт.

Если файла нет, программа показывает ошибку, ждёт нажатия клавиши
и завершает работу с кодом 1.


------------------------------------------------------------

КОД:

if not exist "%SETTINGS_LAUNCHER%" (
    echo ОШИБКА: рядом не найден Settings.bat
    pause
    exit /b 1
)


КОММЕНТАРИЙ:

Проверяет наличие файла Settings.bat.

Если он отсутствует, окно настроек открыть невозможно, поэтому запуск
останавливается.


------------------------------------------------------------

КОД:

if not exist "%SETTINGS%" (
    echo Настройки ещё не созданы.
    echo Сейчас откроется окно настроек.
    call "%SETTINGS_LAUNCHER%"
)


КОММЕНТАРИЙ:

Если settings.json ещё не создан, автоматически запускается
Settings.bat.

Команда call нужна, чтобы после закрытия окна настроек Run.bat
продолжил выполнение.


------------------------------------------------------------

КОД:

if not exist "%SETTINGS%" (
    echo.
    echo ОШИБКА: настройки не были сохранены.
    pause
    exit /b 1
)


КОММЕНТАРИЙ:

После закрытия окна программа повторно проверяет settings.json.

Если пользователь нажал «Отмена» или настройки не удалось записать,
обработка изображений не начинается.


------------------------------------------------------------

КОД:

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass ^
    -File "%SCRIPT%" ^
    -SettingsFile "%SETTINGS%"


КОММЕНТАРИЙ:

Запускает SquarePhotos.ps1.

-NoLogo убирает приветственный текст PowerShell.

-NoProfile не загружает пользовательский профиль PowerShell.

-ExecutionPolicy Bypass разрешает выполнить локальный PS1-файл.

-File указывает запускаемый скрипт.

-SettingsFile передаёт путь к settings.json.


------------------------------------------------------------

КОД:

set "CODE=%ERRORLEVEL%"


КОММЕНТАРИЙ:

Сохраняет код завершения PowerShell.

0 — всё успешно.

1 — критическая ошибка.

2 — часть файлов обработать не удалось.


------------------------------------------------------------

КОД:

if "%CODE%"=="0" (
    echo Обработка завершена.
) else (
    echo Обработка завершена с ошибкой. Код: %CODE%
)


КОММЕНТАРИЙ:

Показывает пользователю, успешно ли закончилась обработка.


------------------------------------------------------------

КОД:

pause
exit /b %CODE%


КОММЕНТАРИЙ:

pause не даёт окну консоли закрыться сразу.

exit /b завершает BAT с тем же кодом, который вернул PowerShell.


============================================================
2. SETTINGS.BAT — ЗАПУСК ОКНА НАСТРОЕК
============================================================


КОД:

@echo off
setlocal
set "BASE=%~dp0"


КОММЕНТАРИЙ:

Скрывает команды, создаёт локальные переменные и определяет папку
программы.


------------------------------------------------------------

КОД:

if not exist "%BASE%SettingsGui.ps1" (
    echo ОШИБКА: рядом не найден SettingsGui.ps1
    pause
    exit /b 1
)


КОММЕНТАРИЙ:

Проверяет наличие PowerShell-файла, который создаёт графическое окно.


------------------------------------------------------------

КОД:

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -STA ^
    -WindowStyle Hidden ^
    -File "%BASE%SettingsGui.ps1" ^
    -SettingsFile "%BASE%settings.json"


КОММЕНТАРИЙ:

Запускает окно настроек.

-STA требуется для нормальной работы Windows Forms.

-WindowStyle Hidden скрывает консоль PowerShell.

Само графическое окно при этом остаётся видимым.


============================================================
3. SETTINGS.JSON — ХРАНЕНИЕ НАСТРОЕК
============================================================


КОД:

{
  "InputDir": "C:\\Photos\\Input",
  "OutputDir": "C:\\Photos\\Output",
  "OutputSize": 330,
  "JpegQuality": 90,
  "SampleSize": 8,
  "FillMode": "rowmatch",
  "ManualColor": "#FFFFFF"
}


КОММЕНТАРИЙ:

InputDir — папка исходных файлов.

OutputDir — папка готовых файлов.

OutputSize — сторона итогового квадрата.

330 означает 330×330.

JpegQuality — качество JPG, JPEG и JFIF.

SampleSize — толщина полосы у края, которую анализирует программа.

FillMode — режим заполнения полей.

ManualColor — ручной цвет в HEX-формате.


============================================================
4. SETTINGSGUI.PS1 — ОКНО НАСТРОЕК
============================================================


КОД:

param(
    [Parameter(Mandatory = $true)]
    [string]$SettingsFile
)


КОММЕНТАРИЙ:

Скрипт принимает обязательный параметр SettingsFile.

В него Settings.bat передаёт путь к settings.json.


------------------------------------------------------------

КОД:

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'


КОММЕНТАРИЙ:

Строгий режим помогает обнаруживать ошибки в переменных.

ErrorActionPreference = Stop заставляет PowerShell останавливать
выполнение при ошибке, чтобы её можно было обработать через catch.


------------------------------------------------------------

КОД:

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing


КОММЕНТАРИЙ:

System.Windows.Forms содержит окна, кнопки, поля ввода и списки.

System.Drawing содержит цвета, размеры, координаты и графические типы.


------------------------------------------------------------

КОД:

[System.Windows.Forms.Application]::EnableVisualStyles()


КОММЕНТАРИЙ:

Включает стандартное современное оформление элементов Windows.


------------------------------------------------------------

КОД:

function Test-HexColor {
    param([string]$Value)
    return $Value -match '^#[0-9A-Fa-f]{6}$'
}


КОММЕНТАРИЙ:

Проверяет, соответствует ли цвет формату:

#RRGGBB

Правильные примеры:

#FFFFFF
#000000
#808080

Неправильные:

FFFFFF
#FFF
red


------------------------------------------------------------

КОД:

function Convert-HexToColor {
    param([string]$Value)

    if (-not (Test-HexColor -Value $Value)) {
        throw 'Цвет должен быть записан в формате #RRGGBB.'
    }

    return [System.Drawing.ColorTranslator]::FromHtml($Value)
}


КОММЕНТАРИЙ:

Преобразует строку вроде #FFFFFF в объект цвета System.Drawing.Color.

Если строка неправильная, создаётся ошибка.


------------------------------------------------------------

КОД:

function Convert-ColorToHex {
    param([System.Drawing.Color]$Color)

    return '#{0:X2}{1:X2}{2:X2}' -f
        $Color.R,
        $Color.G,
        $Color.B
}


КОММЕНТАРИЙ:

Преобразует выбранный в системном окне цвет обратно в HEX.

Например:

R=255, G=255, B=255

превращается в:

#FFFFFF


------------------------------------------------------------

КОД:

$defaults = [ordered]@{
    InputDir    = ''
    OutputDir   = ''
    OutputSize  = 330
    JpegQuality = 90
    SampleSize  = 8
    FillMode    = 'rowmatch'
    ManualColor = '#FFFFFF'
}


КОММЕНТАРИЙ:

Создаёт настройки по умолчанию.

Они используются, если settings.json ещё не существует или повреждён.


------------------------------------------------------------

КОД:

$loaded =
    Get-Content -LiteralPath $SettingsFile -Raw -Encoding UTF8 |
    ConvertFrom-Json


КОММЕНТАРИЙ:

Читает весь settings.json и превращает его в PowerShell-объект.


------------------------------------------------------------

КОД:

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


КОММЕНТАРИЙ:

Перебирает все известные настройки.

Если параметр присутствует в JSON, его сохранённое значение заменяет
значение по умолчанию.


------------------------------------------------------------

КОД:

$dialog =
    New-Object System.Windows.Forms.FolderBrowserDialog


КОММЕНТАРИЙ:

Создаёт стандартное окно Windows для выбора папки.


------------------------------------------------------------

КОД:

if ($dialog.ShowDialog() -eq
    [System.Windows.Forms.DialogResult]::OK) {

    $Target.Text = $dialog.SelectedPath
}


КОММЕНТАРИЙ:

Если пользователь нажал OK, выбранный путь записывается в текстовое
поле настроек.


------------------------------------------------------------

КОД:

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Настройки квадратных изображений'
$form.StartPosition = 'CenterScreen'
$form.ClientSize = New-Object System.Drawing.Size(820, 570)


КОММЕНТАРИЙ:

Создаёт главное окно настроек.

Окно появляется по центру экрана.

Рабочая область имеет размер 820×570 пикселей.


------------------------------------------------------------

КОД:

$form.FormBorderStyle =
    [System.Windows.Forms.FormBorderStyle]::FixedDialog

$form.MaximizeBox = $false
$form.MinimizeBox = $false


КОММЕНТАРИЙ:

Запрещает растягивать, разворачивать и сворачивать окно.


------------------------------------------------------------

КОД:

$inputBox = New-Object System.Windows.Forms.TextBox
$inputBox.Text = [string]$settings.InputDir


КОММЕНТАРИЙ:

Создаёт поле исходной папки и подставляет ранее сохранённый путь.


------------------------------------------------------------

КОД:

$inputButton.Add_Click({
    Select-Folder
        -Target $inputBox
        -Description 'Выберите папку с исходными изображениями'
})


КОММЕНТАРИЙ:

При нажатии на кнопку открывает выбор папки.

Выбранный путь записывается в inputBox.


------------------------------------------------------------

КОД:

$sizeBox = New-Object System.Windows.Forms.NumericUpDown
$sizeBox.Minimum = 32
$sizeBox.Maximum = 4096
$sizeBox.Increment = 10


КОММЕНТАРИЙ:

Создаёт числовое поле размера результата.

Минимум — 32×32.

Максимум — 4096×4096.

Стрелки меняют значение по 10 пикселей.


------------------------------------------------------------

КОД:

$qualityBox.Minimum = 1
$qualityBox.Maximum = 100


КОММЕНТАРИЙ:

Ограничивает качество JPEG диапазоном от 1 до 100.


------------------------------------------------------------

КОД:

$sampleBox.Minimum = 2
$sampleBox.Maximum = 100


КОММЕНТАРИЙ:

Ограничивает толщину анализируемой полосы диапазоном от 2 до 100
пикселей.


------------------------------------------------------------

КОД:

[void]$modeBox.Items.Add(
    'rowmatch — построчное продолжение фона'
)

[void]$modeBox.Items.Add(
    'gradient — автоматический градиент'
)

[void]$modeBox.Items.Add(
    'side — автоматические цвета сторон'
)

[void]$modeBox.Items.Add(
    'manual — один цвет вручную'
)


КОММЕНТАРИЙ:

Добавляет в выпадающий список четыре режима заполнения.


------------------------------------------------------------

КОД:

switch (([string]$settings.FillMode).ToLowerInvariant()) {
    'gradient' { $modeBox.SelectedIndex = 1 }
    'side'     { $modeBox.SelectedIndex = 2 }
    'manual'   { $modeBox.SelectedIndex = 3 }
    default    { $modeBox.SelectedIndex = 0 }
}


КОММЕНТАРИЙ:

Выбирает сохранённый режим.

Если значение неизвестно, включается rowmatch.


------------------------------------------------------------

КОД:

function Update-ModeControls {
    $manual = $modeBox.SelectedIndex -eq 3

    $sampleBox.Enabled = -not $manual
    $colorBox.Enabled = $manual
    $colorButton.Enabled = $manual
}


КОММЕНТАРИЙ:

В режиме manual включает выбор ручного цвета.

В автоматических режимах включает толщину выборки.

Ненужные поля становятся недоступными.


------------------------------------------------------------

КОД:

$colorButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.ColorDialog
    $dialog.FullOpen = $true
})


КОММЕНТАРИЙ:

Создаёт стандартное окно Windows для выбора цвета.


------------------------------------------------------------

КОД:

if ($dialog.ShowDialog() -eq
    [System.Windows.Forms.DialogResult]::OK) {

    $colorBox.Text =
        Convert-ColorToHex -Color $dialog.Color
}


КОММЕНТАРИЙ:

После выбора цвета записывает его HEX-код в текстовое поле.


------------------------------------------------------------

КОД:

if ([string]::IsNullOrWhiteSpace($inputPath)) {
    MessageBox::Show(
        'Укажите папку с исходными изображениями.'
    )

    return
}


КОММЕНТАРИЙ:

Не позволяет сохранить настройки с пустой исходной папкой.


------------------------------------------------------------

КОД:

if (-not (
    Test-Path
        -LiteralPath $inputPath
        -PathType Container
)) {
    MessageBox::Show(
        'Исходная папка не существует.'
    )

    return
}


КОММЕНТАРИЙ:

Проверяет, существует ли исходная папка на диске.


------------------------------------------------------------

КОД:

if ($inputFull.Equals(
    $outputFull,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    MessageBox::Show(
        'Входная и выходная папки должны отличаться.'
    )

    return
}


КОММЕНТАРИЙ:

Не позволяет сохранять результаты в исходную папку.

Это защищает оригиналы от перезаписи.


------------------------------------------------------------

КОД:

$fillMode = switch ($modeBox.SelectedIndex) {
    1 { 'gradient' }
    2 { 'side' }
    3 { 'manual' }
    default { 'rowmatch' }
}


КОММЕНТАРИЙ:

Преобразует выбранный пункт списка во внутреннее название режима.


------------------------------------------------------------

КОД:

$data = [ordered]@{
    InputDir    = $inputFull
    OutputDir   = $outputFull
    OutputSize  = [int]$sizeBox.Value
    JpegQuality = [int]$qualityBox.Value
    SampleSize  = [int]$sampleBox.Value
    FillMode    = $fillMode
    ManualColor = $manualColor
}


КОММЕНТАРИЙ:

Собирает все настройки окна в один объект.


------------------------------------------------------------

КОД:

$json = $data | ConvertTo-Json

$utf8 =
    New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText(
    $SettingsFile,
    $json,
    $utf8
)


КОММЕНТАРИЙ:

Преобразует настройки в JSON и сохраняет settings.json в UTF-8.


============================================================
5. SQUAREPHOTOS.PS1 — ОСНОВНАЯ ОБРАБОТКА
============================================================


КОД:

param(
    [Parameter(Mandatory = $true)]
    [string]$SettingsFile
)


КОММЕНТАРИЙ:

Принимает путь к settings.json от Run.bat.


------------------------------------------------------------

КОД:

function Apply-ExifOrientation {
    param([System.Drawing.Image]$Image)

    $orientationId = 0x0112
}


КОММЕНТАРИЙ:

Начинает функцию исправления ориентации фотографии.

0x0112 — EXIF-тег, в котором камера или телефон хранит информацию
о повороте.


------------------------------------------------------------

КОД:

switch ($orientation) {
    3 {
        $Image.RotateFlip(
            Rotate180FlipNone
        )
    }

    6 {
        $Image.RotateFlip(
            Rotate90FlipNone
        )
    }

    8 {
        $Image.RotateFlip(
            Rotate270FlipNone
        )
    }
}


КОММЕНТАРИЙ:

Поворачивает изображение согласно EXIF.

Это особенно важно для фотографий с телефона.


------------------------------------------------------------

КОД:

function Get-EdgeAverageColor {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Edge,
        [int]$SampleSize
    )
}


КОММЕНТАРИЙ:

Функция вычисляет средний цвет выбранного края изображения.

Edge может быть:

Left
Right
Top
Bottom


------------------------------------------------------------

КОД:

if ($Edge -eq 'Left' -or $Edge -eq 'Right') {
    $band = [Math]::Min(
        $SampleSize,
        [Math]::Max(
            1,
            [Math]::Floor($bitmapWidth / 4.0)
        )
    )
}


КОММЕНТАРИЙ:

Вычисляет толщину вертикальной полосы для анализа.

Она не может быть больше SampleSize и не занимает больше четверти
изображения.


------------------------------------------------------------

КОД:

if ($pixel.GetSaturation() -le 0.40 -and
    $pixel.GetBrightness() -ge 0.35) {

    $filteredR += $pixel.R
    $filteredG += $pixel.G
    $filteredB += $pixel.B
    $filteredCount++
}


КОММЕНТАРИЙ:

Отбирает относительно светлые и не слишком насыщенные пиксели.

Идея — не учитывать тёмные волосы и одежду, а использовать фон.


------------------------------------------------------------

КОД:

return [System.Drawing.Color]::FromArgb(
    [Math]::Round(
        $filteredR / $filteredCount
    ),
    [Math]::Round(
        $filteredG / $filteredCount
    ),
    [Math]::Round(
        $filteredB / $filteredCount
    )
)


КОММЕНТАРИЙ:

Вычисляет средние значения красного, зелёного и синего каналов.

Из них создаётся итоговый цвет края.


============================================================
6. РЕЖИМ ROWMATCH
============================================================


КОД:

function Get-LineEdgeColor {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [string]$Edge,
        [int]$LineIndex,
        [int]$SampleSize,
        [int]$SmoothRadius = 2
    )
}


КОММЕНТАРИЙ:

Вычисляет цвет не всего края сразу, а отдельной строки или отдельного
столбца.

LineIndex — номер анализируемой строки или столбца.

SmoothRadius = 2 означает, что программа учитывает несколько соседних
строк, чтобы цвет не дёргался резко.


------------------------------------------------------------

КОД:

$startY =
    [Math]::Max(
        0,
        $LineIndex - $SmoothRadius
    )

$endY =
    [Math]::Min(
        $bitmapHeight,
        $LineIndex + $SmoothRadius + 1
    )


КОММЕНТАРИЙ:

Определяет диапазон соседних строк вокруг текущей строки.

Например, при SmoothRadius = 2 анализируются:

две строки выше;
текущая строка;
две строки ниже.


------------------------------------------------------------

КОД:

if ($pixel.GetSaturation() -le 0.45 -and
    $pixel.GetBrightness() -ge 0.38) {

    $backgroundR += $pixel.R
    $backgroundG += $pixel.G
    $backgroundB += $pixel.B
    $backgroundCount++
}


КОММЕНТАРИЙ:

Пытается определить, какие пиксели похожи на фон.

Слишком тёмные или слишком цветные пиксели отбрасываются.


------------------------------------------------------------

КОД:

return [pscustomobject]@{
    Color        = $color
    IsBackground = $true
}


КОММЕНТАРИЙ:

Возвращает не только цвет, но и признак того, удалось ли найти
подходящий фон.

IsBackground = true означает, что строка содержит достаточно фоновых
пикселей.


------------------------------------------------------------

КОД:

function Mix-Color {
    param(
        [System.Drawing.Color]$PreviousColor,
        [System.Drawing.Color]$CurrentColor,
        [double]$CurrentWeight = 0.35
    )
}


КОММЕНТАРИЙ:

Смешивает цвет предыдущей строки с цветом текущей.

Это сглаживает переходы между строками и уменьшает видимые полосы.


------------------------------------------------------------

КОД:

$previousWeight = 1.0 - $CurrentWeight


КОММЕНТАРИЙ:

Если текущий цвет имеет вес 0.35, предыдущий получает вес 0.65.


------------------------------------------------------------

КОД:

([int]$PreviousColor.R * $previousWeight) +
([int]$CurrentColor.R * $CurrentWeight)


КОММЕНТАРИЙ:

Вычисляет сглаженное значение красного канала.

Та же операция выполняется для зелёного и синего.


------------------------------------------------------------

КОД:

function Fill-RowMatchBackground {
    param(
        [System.Drawing.Graphics]$Graphics,
        [System.Drawing.Bitmap]$SourceBitmap,
        [int]$CanvasSize,
        [int]$DrawX,
        [int]$DrawY,
        [int]$DrawWidth,
        [int]$DrawHeight,
        [int]$SampleSize,
        [bool]$PadLeftRight
    )
}


КОММЕНТАРИЙ:

Главная функция режима rowmatch.

Она получает:

исходное изображение;
размер холста;
координаты фотографии;
размер фотографии;
толщину выборки;
расположение пустых полей.


------------------------------------------------------------

КОД:

if ($PadLeftRight) {
    $leftFallback =
        Get-EdgeAverageColor
            -Bitmap $SourceBitmap
            -Edge 'Left'
            -SampleSize $SampleSize

    $rightFallback =
        Get-EdgeAverageColor
            -Bitmap $SourceBitmap
            -Edge 'Right'
            -SampleSize $SampleSize
}


КОММЕНТАРИЙ:

Если поля находятся слева и справа, сначала рассчитываются запасные
цвета всего левого и правого края.

Они используются, если в конкретной строке фон распознать не удалось.


------------------------------------------------------------

КОД:

$firstProfile =
    New-Object System.Drawing.Bitmap(
        1,
        $CanvasSize
    )

$secondProfile =
    New-Object System.Drawing.Bitmap(
        1,
        $CanvasSize
    )


КОММЕНТАРИЙ:

Создаёт две узкие вертикальные картинки шириной 1 пиксель.

Первая содержит профиль цвета левого края.

Вторая содержит профиль цвета правого края.


------------------------------------------------------------

КОД:

for ($canvasY = 0;
    $canvasY -lt $CanvasSize;
    $canvasY++) {


КОММЕНТАРИЙ:

Перебирает каждую строку итогового изображения.


------------------------------------------------------------

КОД:

$sourceY =
    [Math]::Round(
        $position *
        ($SourceBitmap.Height - 1)
    )


КОММЕНТАРИЙ:

Переводит координату строки итогового изображения в координату строки
исходной фотографии.


------------------------------------------------------------

КОД:

$leftResult =
    Get-LineEdgeColor
        -Bitmap $SourceBitmap
        -Edge 'Left'
        -LineIndex $sourceY
        -SampleSize $SampleSize


КОММЕНТАРИЙ:

Рассчитывает цвет левого края для конкретной строки.


------------------------------------------------------------

КОД:

if ($leftResult.IsBackground) {
    if ($hasLeftBackground) {
        $lastLeft =
            Mix-Color
                -PreviousColor $lastLeft
                -CurrentColor $leftResult.Color
    }
    else {
        $lastLeft = $leftResult.Color
        $hasLeftBackground = $true
    }
}


КОММЕНТАРИЙ:

Если фон в строке найден, его цвет сглаживается с предыдущей строкой.

При первом найденном фоне цвет просто принимается без смешивания.


------------------------------------------------------------

КОД:

$firstProfile.SetPixel(
    0,
    $canvasY,
    $lastLeft
)


КОММЕНТАРИЙ:

Записывает рассчитанный цвет в вертикальный профиль левого поля.


------------------------------------------------------------

КОД:

$Graphics.DrawImage(
    $firstProfile,
    $leftRectangle
)


КОММЕНТАРИЙ:

Растягивает профиль шириной 1 пиксель на всю ширину левого пустого поля.

Каждая строка сохраняет свой цвет, поэтому фон меняется по высоте.


------------------------------------------------------------

КОД:

if (-not $PadLeftRight) {
    $firstProfile =
        New-Object System.Drawing.Bitmap(
            $CanvasSize,
            1
        )
}


КОММЕНТАРИЙ:

Если поля сверху и снизу, создаётся горизонтальный профиль высотой
1 пиксель.

Цвет рассчитывается отдельно для каждого столбца.


============================================================
7. РЕЖИМ GRADIENT
============================================================


КОД:

$brush =
    New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $Rectangle,
        $FirstColor,
        $SecondColor,
        $Direction
    )


КОММЕНТАРИЙ:

Создаёт плавный градиент между двумя цветами.


------------------------------------------------------------

КОД:

$Graphics.FillRectangle(
    $brush,
    $Rectangle
)


КОММЕНТАРИЙ:

Закрашивает прямоугольную область этим градиентом.


============================================================
8. РЕЖИМ SIDE
============================================================


КОД:

$firstRectangle =
    New-Object System.Drawing.Rectangle(
        0,
        0,
        $half,
        $CanvasSize
    )

$secondRectangle =
    New-Object System.Drawing.Rectangle(
        $half,
        0,
        $otherHalf,
        $CanvasSize
    )


КОММЕНТАРИЙ:

Делит холст на две половины.


------------------------------------------------------------

КОД:

Fill-Solid
    -Graphics $Graphics
    -Rectangle $firstRectangle
    -Color $FirstColor

Fill-Solid
    -Graphics $Graphics
    -Rectangle $secondRectangle
    -Color $SecondColor


КОММЕНТАРИЙ:

Закрашивает каждую половину отдельным цветом.

После этого середину перекрывает фотография, поэтому видны только поля.


============================================================
9. РЕЖИМ MANUAL
============================================================


КОД:

if ($FillMode -eq 'manual') {
    $Graphics.Clear($ManualColor)
    return
}


КОММЕНТАРИЙ:

Полностью заполняет холст выбранным вручную цветом.

После этого поверх фона рисуется фотография.


============================================================
10. ПОИСК ФАЙЛОВ
============================================================


КОД:

$files = @(
    Get-ChildItem
        -LiteralPath $inputFull
        -File |
    Where-Object {
        $_.Extension.ToLowerInvariant() -in @(
            '.jpg',
            '.jpeg',
            '.jfif',
            '.png'
        )
    }
)


КОММЕНТАРИЙ:

Находит во входной папке только поддерживаемые изображения.

Подпапки не обрабатываются.


============================================================
11. РАСЧЁТ РАЗМЕРА ИЗОБРАЖЕНИЯ
============================================================


КОД:

$scale = [Math]::Min(
    $outputSize / [double]$sourceWidth,
    $outputSize / [double]$sourceHeight
)


КОММЕНТАРИЙ:

Рассчитывает масштаб, при котором изображение полностью помещается
в квадрат.

Берётся меньшее из двух значений, поэтому фотография не обрезается.


------------------------------------------------------------

КОД:

$drawWidth =
    [Math]::Round(
        $sourceWidth * $scale
    )

$drawHeight =
    [Math]::Round(
        $sourceHeight * $scale
    )


КОММЕНТАРИЙ:

Рассчитывает ширину и высоту фотографии после масштабирования.

Пропорции сохраняются.


------------------------------------------------------------

КОД:

$drawX =
    [Math]::Floor(
        ($outputSize - $drawWidth) / 2.0
    )

$drawY =
    [Math]::Floor(
        ($outputSize - $drawHeight) / 2.0
    )


КОММЕНТАРИЙ:

Рассчитывает координаты, чтобы фотография находилась по центру.


------------------------------------------------------------

КОД:

$padLeftRight =
    $drawWidth -lt $outputSize


КОММЕНТАРИЙ:

Проверяет, появились ли свободные поля слева и справа.

Если ширина фотографии равна размеру холста, поля находятся сверху
и снизу.


============================================================
12. СОЗДАНИЕ ИТОГОВОГО ХОЛСТА
============================================================


КОД:

$canvas =
    New-Object System.Drawing.Bitmap(
        $outputSize,
        $outputSize,
        Format24bppRgb
    )


КОММЕНТАРИЙ:

Создаёт новое квадратное изображение выбранного размера.


------------------------------------------------------------

КОД:

$graphics =
    [System.Drawing.Graphics]::FromImage(
        $canvas
    )


КОММЕНТАРИЙ:

Создаёт объект рисования для холста.


------------------------------------------------------------

КОД:

$graphics.InterpolationMode =
    HighQualityBicubic

$graphics.CompositingQuality =
    HighQuality

$graphics.PixelOffsetMode =
    HighQuality

$graphics.SmoothingMode =
    HighQuality


КОММЕНТАРИЙ:

Включает качественное масштабирование и наложение фотографии.


============================================================
13. РИСОВАНИЕ ФОТОГРАФИИ
============================================================


КОД:

$destination =
    New-Object System.Drawing.Rectangle(
        $drawX,
        $drawY,
        $drawWidth,
        $drawHeight
    )


КОММЕНТАРИЙ:

Создаёт прямоугольник, который определяет положение и размер фотографии
на холсте.


------------------------------------------------------------

КОД:

$graphics.DrawImage(
    $workingBitmap,
    $destination
)


КОММЕНТАРИЙ:

Рисует фотографию поверх подготовленного фона.


============================================================
14. СОХРАНЕНИЕ ФАЙЛА
============================================================


КОД:

$outputPath =
    Join-Path
        -Path $outputFull
        -ChildPath $file.Name


КОММЕНТАРИЙ:

Создаёт путь результата с тем же именем, что у исходного файла.


------------------------------------------------------------

КОД:

if (Test-Path
    -LiteralPath $outputPath
    -PathType Leaf) {

    Remove-Item
        -LiteralPath $outputPath
        -Force
}


КОММЕНТАРИЙ:

Если результат с таким именем уже существует, старый файл удаляется.


------------------------------------------------------------

КОД:

if ($file.Extension.ToLowerInvariant() -in @(
    '.jpg',
    '.jpeg',
    '.jfif'
)) {
    Save-Jpeg
        -Bitmap $canvas
        -Path $outputPath
        -Quality $jpegQuality
}


КОММЕНТАРИЙ:

JPG, JPEG и JFIF сохраняются JPEG-кодеком с выбранным качеством.


------------------------------------------------------------

КОД:

else {
    $canvas.Save(
        $outputPath,
        [System.Drawing.Imaging.ImageFormat]::Png
    )
}


КОММЕНТАРИЙ:

PNG сохраняется PNG-кодеком.


============================================================
15. ОСВОБОЖДЕНИЕ ПАМЯТИ
============================================================


КОД:

finally {
    if ($null -ne $graphics) {
        $graphics.Dispose()
    }

    if ($null -ne $canvas) {
        $canvas.Dispose()
    }

    if ($null -ne $workingBitmap) {
        $workingBitmap.Dispose()
    }

    if ($null -ne $source) {
        $source.Dispose()
    }
}


КОММЕНТАРИЙ:

Закрывает графические объекты и освобождает память.

Без Dispose изображения могли бы оставаться заблокированными,
а память постепенно заполнялась бы.


============================================================
16. ОБРАБОТКА ОШИБОК
============================================================


КОД:

catch {
    Write-Host (
        "[ОШИБКА] {0}: {1}" -f
        $file.Name,
        $_.Exception.Message
    ) -ForegroundColor Red

    $failed++
}


КОММЕНТАРИЙ:

Если конкретный файл не удалось обработать, программа показывает
его имя и причину ошибки.

Остальные файлы продолжают обрабатываться.


------------------------------------------------------------

КОД:

if ($failed -gt 0) {
    exit 2
}

exit 0


КОММЕНТАРИЙ:

Если были ошибки отдельных файлов, возвращается код 2.

Если всё прошло успешно, возвращается код 0.

