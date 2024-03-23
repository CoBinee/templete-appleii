-- HiRes 6 色に変換
--

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

-- 対象のフレームの取得
local src_frame = app.frame

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

-- サイズの取得
local dst_size_x = (sprite.width  + 14 - 1) // 14
local dst_size_y = (sprite.height + 16 - 1) // 16

-- イメージの作成
local dst_image = Image(dst_size_x, dst_size_y)

-- HiRes 6 色に変換
for y = 0, dst_size_y - 1, 1 do
    for x_14 = 0, dst_size_x - 1, 14 do

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

        -- 2 ピクセル単位にする
        for i = 0, 13, 2 do
            if pixels[i + 0] ~= pixels[i + 1] then
                if pixels[i + 0] == color_name_purple or pixels[i + 0] == color_name_blue then
                    if pixels[i + 1] ~= color_name_white and pixels[i + 1] ~= color_name_black then
                        pixels[i + 1] = pixels[i + 0]
                    end
                elseif pixels[i + 1] == color_name_green or pixels[i + 1] == color_name_orange then
                    if pixels[i + 0] ~= color_name_white and pixels[i + 0] ~= color_name_black then
                        pixels[i + 0] = pixels[i + 1]
                    end
                end
            end
            if pixels[i + 0] ~= pixels[i + 1] then
                if pixels[i + 0] == color_name_white then
                    if pixels[i + 1] ~= color_name_black then
                        pixels[i + 1] = pixels[i + 0]
                    end
                elseif pixels[i + 1] == color_name_white then
                    if pixels[i + 0] ~= color_name_black then
                        pixels[i + 0] = pixels[i + 1]
                    end
                end
            end
        end

        -- ハイビットの選択
        for i = 0, 13, 7 do
            local hibit_0 = 0
            local hibit_1 = 0
            for j = 0, 6, 1 do
                local k = i + j
                if pixels[k] == color_name_green or pixels[k] == color_name_purple then
                    hibit_0 = hibit_0 + 1
                elseif pixels[k] == color_name_orange or pixels[k] == color_name_blue then
                    hibit_1 = hibit_1 + 1
                end
            end
            if hibit_0 >= hibit_1 then
                for j = 0, 6, 1 do
                    local k = i + j
                    if pixels[k] == color_name_orange then
                        pixels[k] = color_name_purple
                    elseif pixels[k] == color_name_blue then
                        pixels[k] = color_name_green
                    end
                end
            else
                for j = 0, 6, 1 do
                    local k = i + j
                    if pixels[k] == color_name_purple then
                        pixels[k] = color_name_orange
                    elseif pixels[k] == color_name_green then
                        pixels[k] = color_name_blue
                    end
                end
            end
        end

        -- イメージへの描画
        for i = 0, 13, 1 do
            dst_image:drawPixel(x_14 + i, y, colors[pixels[i]])
        end
    end
end

-- レイヤの作成
local dst_layer = sprite:newLayer()
dst_layer.name = "#"

-- セルの作成
local dst_cel = sprite:newCel(dst_layer, src_frame)

-- イメージの設定
dst_cel.image = dst_image

-- 終了
app.alert("converted.")
