-- スプライトの取得
local sprite = app.sprite
if not sprite then
    return app.alert("error - no sprite.")
end
if sprite.colorMode ~= ColorMode.RGB then
    return app.alert("error - script suport only RGB color mode.")
end

-- 対象のセルの取得
local src_cel = app.cel
if not src_cel then
    return app.alert("error - no selected cel.")
end

-- 対象のイメージの取得
local src_image = src_cel.image
if not src_image then
    return app.alert("error - no image.")
end

-- ダイアログの設定
local export_dialog_title = "Export Image File"

-- ファイルダイアログを開く
local export_dialog = Dialog {
    title = export_dialog_title, 
    hexpand = true, 
    vexpand = true
}
export_dialog:file {
    id = 'path', 
    label = 'Export File', 
    open = false, 
    save = true, 
    filename = '', 
    filetypes = {'hgr'}
}
export_dialog:button {
    id = 'export', 
    text = 'Export'
}
export_dialog:show()

-- 出力先パスの取得
local export_dialog_data = export_dialog.data
if not export_dialog_data.export then
    return
end
local export_path = export_dialog_data.path
if not export_path or export_path == "" then
    return
end

-- サイズの設定
local export_size_x = 280
local export_size_y = 192

-- 色の作成
local colors = {
    black  = Color {r =   0, g =   0, b =   0, a = 255}, 
    green  = Color {r =  38, g = 195, b =  15, a = 255}, 
    purple = Color {r = 217, g =  60, b = 240, a = 255}, 
    orange = Color {r = 217, g = 104, b =  15, a = 255}, 
    blue   = Color {r =  38, g = 151, b = 240, a = 255}, 
    white  = Color {r = 255, g = 255, b = 255, a = 255}
}
local color_name_black  = 'black'
local color_name_green  = 'green'
local color_name_purple = 'purple'
local color_name_orange = 'orange'
local color_name_blue   = 'blue'
local color_name_white  = 'white'
local color_threshold = 64

-- VRAM の作成
local vram = {}
for i = 0x2000, 0x3fff, 0x0001 do
    vram[i] = 0x00
end

-- 8 行毎のアドレス
local line_address_8 = {
    0x2000, 0x2080, 0x2100, 0x2180, 0x2200, 0x2280, 0x2300, 0x2380, 
    0x2028, 0x20a8, 0x2128, 0x21a8, 0x2228, 0x22a8, 0x2328, 0x23a8, 
    0x2050, 0x20d0, 0x2150, 0x21d0, 0x2250, 0x22d0, 0x2350, 0x23d0, 
}

-- VRAM への展開
for y = 0, export_size_y - 1, 1 do
    for x_14 = 0, export_size_x - 1, 14 do

        -- アドレスの取得
        local address = line_address_8[(y // 8) + 1] + ((y % 8) * 0x0400) + (x_14 // 7)

        -- 14 ピクセルづつ色を取得
        local pixels = {}
        for i = 0, 13, 1 do
            local x = x_14 + i
            pixels[i] = color_name_black
            if x >= src_cel.bounds.x and x < src_cel.bounds.x + src_cel.bounds.width and y >= src_cel.bounds.y and y < src_cel.bounds.y + src_cel.bounds.height then
                local pixel = src_image:getPixel(x - src_cel.bounds.x, y - src_cel.bounds.y)
                local color = Color(pixel)
                if color.alpha == 255 then
                    if color.red < color_threshold and color.green >= color_threshold and color.blue < color_threshold then
                        pixels[i] = color_name_green
                    elseif color.red >= color_threshold and color.green < color_threshold and color.blue >= color_threshold then
                        pixels[i] = color_name_purple
                    elseif color.red >= color_threshold and color.green >= color_threshold and color.blue < color_threshold then
                        pixels[i] = color_name_orange
                    elseif color.red < color_threshold and color.green >= color_threshold and color.blue >= color_threshold then
                        pixels[i] = color_name_blue
                    elseif color.red >= color_threshold and color.green >= color_threshold and color.blue >= color_threshold then
                        pixels[i] = color_name_white
                    end
                end
            end
        end

        -- ハイビットの取得
        local hibit_0 = 0x00
        local hibit_1 = 0x00
        for i = 0, 6, 1 do
            if pixels[i] == color_name_orange or pixels[i] == color_name_blue then
                hibit_0 = 0x80
            end
        end
        for i = 7, 13, 1 do
            if pixels[i] == color_name_orange or pixels[i] == color_name_blue then
                hibit_1 = 0x80
            end
        end
        
        -- パターンの取得
        local pattern = 0x0000
        for i = 0, 13, 1 do
            if i % 2 == 0 then
                if pixels[i] == color_name_purple or pixels[i] == color_name_blue or pixels[i] == color_name_white then
                    pattern = pattern | (1 << i)
                end
            else
                if pixels[i] == color_name_green or pixels[i] == color_name_orange or pixels[i] == color_name_white then
                    pattern = pattern | (1 << i)
                end
            end
        end

        -- パターンの設定
        vram[address + 0x0000] = (pattern & 0x7f) | hibit_0
        vram[address + 0x0001] = (pattern >> 7) | hibit_1
    end
end

-- ファイルを開く
local export_file = io.open(export_path, 'w+b')
if not export_file then
    return app.alert("error - " .. export_path .. "is no opened.")
end

-- VRAM の書き込み
for i = 0x2000, 0x3fff, 0x0001 do
    export_file:write(string.format('%c', vram[i]))
end

-- ファイルを閉じる
export_file:close()

-- 終了
app.alert("exported.")
