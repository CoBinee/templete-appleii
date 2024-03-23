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

-- 対象のレイヤの取得
local src_layer = src_cel.layer
if not src_layer.isTilemap then
    return app.alert("error - no tilemap.")
end

-- 対象のタイルセットの取得
local src_tileset = src_layer.tileset
if not src_tileset then
    return app.alert("error - no tileset.")
end

-- 対象のイメージの取得
local src_image = src_cel.image
if not src_image then
    return app.alert("error - no image.")
end
    
-- ダイアログの設定
local dialog_title = "Export x2 Tilemap"

-- ファイルダイアログを開く
local export_dialog = Dialog {
    title = dialog_title, 
    hexpand = true, 
    vexpand = true
}
export_dialog:file {
    id = 'path', 
    label = 'Tilemap File', 
    open = false, 
    save = true, 
    filename = '', 
    filetypes = {'tm'}
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

-- マップサイズの取得
local map_size_x = src_image.width
local map_size_y = src_image.height

-- タイルサイズの取得
local tile_size_x = export_dialog_data.width
local tile_size_y = export_dialog_data.height

-- ファイルを開く
local export_file = io.open(export_path, 'w+b')
if not export_file then
    return app.alert("error - " .. export_path .. "is no opened.")
end

-- サイズの書き込み
export_file:write(string.format('%c', map_size_x * tile_size_x))
export_file:write(string.format('%c', map_size_y * tile_size_y))

-- タイルマップの生成
for m_y = 0, map_size_y - 1, 1 do
    for t_y = 0, tile_size_y - 1, 1 do
        for m_x = 0, map_size_x - 1, 1 do
            local pixel = src_image:getPixel(m_x, m_y)
            pixel = pixel - 1 + src_tileset.baseIndex
            for t_x = 0, tile_size_x - 1, 1 do
                export_file:write(string.format('%c', pixel * (tile_size_x * tile_size_y) + t_y * tile_size_x + t_x))
            end
        end
    end
end

-- ファイルを閉じる
export_file:close()

-- 終了
app.alert("exported.")
