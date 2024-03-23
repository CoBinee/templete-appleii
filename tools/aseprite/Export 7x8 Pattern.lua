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
local dialog_title = "Export 7x8 Pattern"

-- ファイルダイアログを開く
local export_dialog = Dialog {
    title = dialog_title, 
    hexpand = true, 
    vexpand = true
}
export_dialog:file {
    id = 'path', 
    label = 'Pattern File', 
    open = false, 
    save = true, 
    filename = '', 
    filetypes = {'ts'}
}
export_dialog:slider {
    id = 'width',
    label = 'Tile Width', 
    min = 1, 
    max = 8, 
    value = 1
}
export_dialog:slider {
    id = 'height',
    label = 'Tile Height', 
    min = 1, 
    max = 8, 
    value = 1
}
export_dialog:check {
    id = 'even', 
    label = '', 
    text = 'even base', 
    selected = true
}
export_dialog:check {
    id = 'mask', 
    label = '', 
    text = 'mask', 
    selected = false
}
export_dialog:button {
    id = 'export', 
    text = 'Export'
}
export_dialog:show()

-- ダイアログの結果の取得
local export_dialog_data = export_dialog.data
if not export_dialog_data.export then
    return
end

-- 出力先パスの取得
local export_path = export_dialog_data.path
if not export_path or export_path == "" then
    return
end

-- 偶数/奇数の取得
local export_even_odd = 0
if not export_dialog_data.even then
    export_even_odd = 1
end

-- マスクの取得
local export_mask = false
if export_dialog_data.mask then
    export_mask = true
end

-- タイルサイズの取得
local tile_size_x = export_dialog_data.width
local tile_size_y = export_dialog_data.height

-- セルサイズの取得
local cell_size_x = (((sprite.width + 7 - 1) // 7) + tile_size_x - 1) // tile_size_x
local cell_size_y = (((sprite.height + 8 - 1) // 8) + tile_size_y - 1) // tile_size_y

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

-- ファイルを開く
local export_file = io.open(export_path, 'w+b')
if not export_file then
    return app.alert("error - " .. export_path .. "is no opened.")
end

-- パターンの生成
for c_y = 0, cell_size_y - 1, 1 do
    for c_x = 0, cell_size_x - 1, 1 do
        for t_y = 0, tile_size_y - 1, 1 do
            for t_x = 0, tile_size_x - 1, 1 do

                -- 縦 8 ピクセル毎の処理
                for p_y = 0, 7, 1 do
                    local y = (c_y * tile_size_y + t_y) * 8 + p_y

                    -- 横 7 ピクセルづつ色を取得
                    local pixels = {}
                    for p_x = 0, 6, 1 do
                        local x = (c_x * tile_size_x + t_x) * 7 + p_x
                        pixels[p_x] = color_name_black
                        if x >= src_cel.bounds.x and x < src_cel.bounds.x + src_cel.bounds.width and y >= src_cel.bounds.y and y < src_cel.bounds.y + src_cel.bounds.height then
                            local pixel = src_image:getPixel(x - src_cel.bounds.x, y - src_cel.bounds.y)
                            local color = Color(pixel)
                            if not export_mask then
                                if color.alpha == 255 then
                                    if color.red < color_threshold and color.green >= color_threshold and color.blue < color_threshold then
                                        pixels[p_x] = color_name_green
                                    elseif color.red >= color_threshold and color.green < color_threshold and color.blue >= color_threshold then
                                        pixels[p_x] = color_name_purple
                                    elseif color.red >= color_threshold and color.green >= color_threshold and color.blue < color_threshold then
                                        pixels[p_x] = color_name_orange
                                    elseif color.red < color_threshold and color.green >= color_threshold and color.blue >= color_threshold then
                                        pixels[p_x] = color_name_blue
                                    elseif color.red >= color_threshold and color.green >= color_threshold and color.blue >= color_threshold then
                                        pixels[p_x] = color_name_white
                                    end
                                end
                            else
                                if color.alpha < 255 then
                                    pixels[p_x] = color_name_white
                                end
                            end
                        else
                            if not export_mask then
                                ;
                            else
                                pixels[p_x] = color_name_white
                            end
                        end
                    end

                    -- ハイビットの取得
                    local hibit = 0x00
                    for i = 0, 6, 1 do
                        if pixels[i] == color_name_orange or pixels[i] == color_name_blue then
                            hibit = 0x80
                        end
                    end

                    -- パターンの取得
                    local pattern = 0x00
                    if (c_x * tile_size_x + t_x) % 2 == export_even_odd then
                        for i = 0, 6, 1 do
                            if pixels[i] == color_name_white then
                                pattern = pattern | (1 << i)
                            elseif i % 2 == 0 and (pixels[i] == color_name_purple or pixels[i] == color_name_blue) then
                                pattern = pattern | (1 << i)
                            elseif i % 2 == 1 and (pixels[i] == color_name_green or pixels[i] == color_name_orange) then
                                pattern = pattern | (1 << i)
                            end
                        end
                    else
                        for i = 0, 6, 1 do
                            if pixels[i] == color_name_white then
                                pattern = pattern | (1 << i)
                            elseif i % 2 == 1 and (pixels[i] == color_name_purple or pixels[i] == color_name_blue) then
                                pattern = pattern | (1 << i)
                            elseif i % 2 == 0 and (pixels[i] == color_name_green or pixels[i] == color_name_orange) then
                                pattern = pattern | (1 << i)
                            end
                        end
                    end
                    if export_mask and pattern == 0x7f then
                        hibit = 0x80
                    end

                    -- パターンの書き込み
                    export_file:write(string.format('%c', pattern | hibit))
                end
            end
        end
    end
end

-- ファイルを閉じる
export_file:close()

-- 終了
app.alert("exported.")
