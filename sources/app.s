; app.s - アプリケーション
;


; 6502 - CPU の選択
.setcpu     "6502"

; 自動インポート
.autoimport +

; エスケープシーケンスのサポート
.feature    string_escapes


; ファイルの参照
;
.include    "apple2.inc"
.include    "iocs.inc"
.include    "app.inc"


; コードの定義
;
.segment    "APP"

; アプリケーションのエントリポイント
;
.proc       AppEntry

    ; アプリケーションの初期化

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; 画面モードの設定
    sta     HIRES
    sta     LOWSCR
    sta     MIXCLR
    sta     TXTCLR

.endproc

; アプリケーションを更新する
;
.proc   AppUpdate

    ; ゼロページのクリア
    ldy     #APP_0
    lda     #$00
:
    sta     $00, y
    iny
    bne     :-

    ; 処理の設定
    lda     #<AppDemo
    sta     APP_0_PROC_L
    lda     #>AppDemo
    sta     APP_0_PROC_H

    ; 状態の設定
;   lda     #$00
;   sta     APP_0_STATE

    ; 処理の繰り返し
@loop:

    ; IOCS の更新
    jsr     _IocsUpdate

    ; 処理の実行
    lda     #>(:+ - $0001)
    pha
    lda     #<(:+ - $0001)
    pha
    jmp     (APP_0_PROC)
:

    ; ループ
    jmp     @loop

.endproc

; デモを実行する
;
.proc   AppDemo

    ; 状態別の処理
    lda     #<@state
    sta     APP_0_WORK_0
    lda     #>@state
    sta     APP_0_WORK_1
    lda     APP_0_STATE
    asl     a
    tay
    lda     (APP_0_WORK_0), y
    sta     APP_0_WORK_2
    iny
    lda     (APP_0_WORK_0), y
    sta     APP_0_WORK_3
    jmp     (APP_0_WORK_2)

; ステート
@state:
    .word   AppDemoLoadImage
    .word   AppDemoSaveVram
    .word   AppDemoLoadVram
    .word   AppDemoLoadScroll
    .word   AppDemoViewScroll
    .word   AppDemoLoadSprite
    .word   AppDemoViewSprite
    .word   AppDemoEnd

.endproc

; イメージファイルを読み込む
;
.proc   AppDemoLoadImage

    ; イメージファイルの読み込み
    ldx     #<@image_file_arg
    lda     #>@image_file_arg
    jsr     _IocsBload

    ; 文字列の描画
    ldx     #<@string_arg
    lda     #>@string_arg
    jsr     _IocsDrawString

    ; 終了
    inc     APP_0_STATE
    rts

; イメージファイル
@image_file_arg:
    .word   @image_name
    .word   $0000
@image_name:
    .asciiz "IMAGE.HGR"

; 文字列
@string_arg:
    .byte   12
    .byte   22
    .word   @string_text
@string_text:
    .asciiz "HELLO, APPLE ][."
    
.endproc

; VRAM をファイルに書き込む
;
.proc   AppDemoSaveVram

    ; VRAM のファイルへの書き込み
    ldx     #<@vram_file_arg
    lda     #>@vram_file_arg
    jsr     _IocsBsave

    ; 終了
    inc     APP_0_STATE
    rts

; VRAM ファイル
@vram_file_arg:
    .word   @vram_name
    .word   HGR1SCRN
    .word   $2000
@vram_name:
    .asciiz "VRAM.HGR"

.endproc

; 書き込んだ VRAM ファイルを再読み込みする
;
.proc   AppDemoLoadVram

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; VRAM ファイルの読み込み
    ldx     #<@vram_file_arg
    lda     #>@vram_file_arg
    jsr     _IocsBload

    ; 完了
    inc     APP_0_STATE
    rts

; VRAM ファイル
@vram_file_arg:
    .word   @vram_name
    .word   HGR1SCRN
    .word   $2000
@vram_name:
    .asciiz "VRAM.HGR"

.endproc

; スクロールさせる 7x8 タイルマップを読み込む
;
.proc   AppDemoLoadScroll

    ; タイルセットの読み込み
    ldx     #<@scroll_tileset_even_file_arg
    lda     #>@scroll_tileset_even_file_arg
    jsr     _IocsBload

    ; タイルセットの読み込み
    ldx     #<@scroll_tileset_odd_file_arg
    lda     #>@scroll_tileset_odd_file_arg
    jsr     _IocsBload

    ; タイルマップの読み込み
    ldx     #<@scroll_tilemap_file_arg
    lda     #>@scroll_tilemap_file_arg
    jsr     _IocsBload

    ; VRAM のクリア
    jsr     _IocsClearVram

    ; キーのクリア
    lda     #$00
    sta     APP_0_WASD
    sta     KBDSTRB

    ; 初期設定
    lda     #$00
    sta     APP_0_WASD
    sta     APP_0_X
    sta     APP_0_Y

    ; 終了
    inc     APP_0_STATE
    rts

; タイルセットファイル
@scroll_tileset_even_file_arg:
    .word   @scroll_tileset_even_name
    .word   tileset_even
@scroll_tileset_even_name:
    .asciiz "TILE7X8-1E.TS"
@scroll_tileset_odd_file_arg:
    .word   @scroll_tileset_odd_name
    .word   tileset_odd
@scroll_tileset_odd_name:
    .asciiz "TILE7X8-1O.TS"

; タイルマップファイル
@scroll_tilemap_file_arg:
    .word   @scroll_tilemap_name
    .word   tilemap
@scroll_tilemap_name:
    .asciiz "TILE7X8-1.TM"

.endproc

; 7x8 タイルマップをスクロール表示する
;
.proc   AppDemoViewScroll

    ; キー入力
    ldx     APP_0_WASD
    lda     IOCS_0_KEYCODE
    cmp     #'W'
    bne     :+
    ldx     #$00
    jmp     @scroll_inputed
:
    cmp     #'S'
    bne     :+
    ldx     #$01
    jmp     @scroll_inputed
:
    cmp     #'A'
    bne     :+
    ldx     #$02
    jmp     @scroll_inputed
:
    cmp     #'D'
    bne     :+
    ldx     #$03
;   jmp     @scroll_inputed
:
@scroll_inputed:
    stx     APP_0_WASD

    ; 移動
    lda     APP_0_WASD
    bne     :+
    lda     APP_0_Y
    beq     @scroll_moved
    dec     APP_0_Y
    jmp     @scroll_moved
:
    cmp     #$01
    bne     :+
    lda     APP_0_Y
    clc
    adc     @scroll_tilemap_arg + $0003
    cmp     tilemap + $0001
    bcs     @scroll_moved
    inc     APP_0_Y
    jmp     @scroll_moved
:
    cmp     #$02
    bne     :+
    lda     APP_0_X
    beq     @scroll_moved
    dec     APP_0_X
    jmp     @scroll_moved
:
    lda     APP_0_X
    clc
    adc     @scroll_tilemap_arg + $0002
    cmp     tilemap + $0000
    bcs     @scroll_moved
    inc     APP_0_X
;   jmp     @scroll_moved
@scroll_moved:

    ; 位置の更新
    lda     APP_0_X
    sta     @scroll_tilemap_arg + $0008
    lda     APP_0_Y
    sta     @scroll_tilemap_arg + $0009

    ; タイルマップの選択
    lda     APP_0_X
    lsr     a
    bcs     :+
    ldx     #<tileset_even
    lda     #>tileset_even
;;  jmp     :++
    bcc     :++
:
    ldx     #<tileset_odd
    lda     #>tileset_odd
:
    stx     @scroll_tilemap_arg + $0004
    sta     @scroll_tilemap_arg + $0005

    ; タイルマップの描画
    ldx     #<@scroll_tilemap_arg
    lda     #>@scroll_tilemap_arg
    jsr     _IocsDraw7x8Tilemap

    ; 終了
    lda     IOCS_0_KEYCODE
    cmp     #' '
    bne     :+
    inc     APP_0_STATE
:
    rts

; タイルマップ
@scroll_tilemap_arg:
    .byte   $04, $00
    .byte   $20, $14
    .word   tileset_even
    .word   tilemap
    .byte   $00, $00

.endproc

; スプライトを読み込む
;
.proc   AppDemoLoadSprite

    ; タイルセットの読み込み
    ldx     #<@sprite_tileset_file_arg
    lda     #>@sprite_tileset_file_arg
    jsr     _IocsBload

    ; タイルマップの読み込み
    ldx     #<@sprite_tilemap_file_arg
    lda     #>@sprite_tilemap_file_arg
    jsr     _IocsBload

    ; タイルマップの描画
    ldx     #<@sprite_tilemap_arg
    lda     #>@sprite_tilemap_arg
    jsr     _IocsDraw7x8Tilemap

    ; スプライトの読み込み
    ldx     #<@sprite_sprite_even_file_arg
    lda     #>@sprite_sprite_even_file_arg
    jsr     _IocsBload
    ldx     #<@sprite_sprite_odd_file_arg
    lda     #>@sprite_sprite_odd_file_arg
    jsr     _IocsBload
    ldx     #<@sprite_sprite_mask_file_arg
    lda     #>@sprite_sprite_mask_file_arg
    jsr     _IocsBload

    ; キーのクリア
    lda     #$00
    sta     APP_0_WASD
    sta     KBDSTRB

    ; 初期設定
    lda     #$08
    sta     APP_0_X
    lda     #$00
    sta     APP_0_DIRECTION
    sta     APP_0_ANIMATION
    lda     #$01
    sta     APP_0_WAIT_0
    sta     APP_0_WAIT_1

    ; 終了
    inc     APP_0_STATE
    rts

; タイルセットファイル
@sprite_tileset_file_arg:
    .word   @sprite_tileset_name
    .word   tileset_even
@sprite_tileset_name:
    .asciiz "TILE7X8-2.TS"

; タイルマップファイル
@sprite_tilemap_file_arg:
    .word   @sprite_tilemap_name
    .word   tilemap
@sprite_tilemap_name:
    .asciiz "TILE7X8-2.TM"

; タイルマップ
@sprite_tilemap_arg:
    .byte   $04, $00
    .byte   $20, $14
    .word   tileset_even
    .word   tilemap
    .byte   $00, $00

; スプライト
@sprite_sprite_even_file_arg:
    .word   @sprite_sprite_even_name
    .word   sprite_even
@sprite_sprite_even_name:
    .asciiz "SPRITE-E.TS"
@sprite_sprite_odd_file_arg:
    .word   @sprite_sprite_odd_name
    .word   sprite_odd
@sprite_sprite_odd_name:
    .asciiz "SPRITE-O.TS"
@sprite_sprite_mask_file_arg:
    .word   @sprite_sprite_mask_name
    .word   sprite_mask
@sprite_sprite_mask_name:
    .asciiz "SPRITE-MASK.TS"

.endproc

; スプライトを描画する
;
.proc   AppDemoViewSprite

    ; キー入力
    lda     IOCS_0_KEYCODE
    cmp     #'W'
    bne     :+
    lda     APP_0_WAIT_1
    cmp     #$10
    bcs     @sprite_inputed
    adc     #$01
    sta     APP_0_WAIT_0
    sta     APP_0_WAIT_1
    jmp     @sprite_inputed
:
    cmp     #'S'
    bne     :+
    lda     APP_0_WAIT_1
    cmp     #$02
    bcc     @sprite_inputed
    sbc     #$01
    sta     APP_0_WAIT_0
    sta     APP_0_WAIT_1
;   jmp     @sprite_inputed
:
@sprite_inputed:

    ; タイルマップのクリア
    lda     #$00
    sta     @sprite_tilemap_arg + $0002

    ; ウェイトの更新
    dec     APP_0_WAIT_0
    bne     @sprite_draw
    lda     APP_0_WAIT_1
    sta     APP_0_WAIT_0

    ; 移動
    lda     APP_0_DIRECTION
    beq     :++
    lda     APP_0_X
    beq     :+
    dec     APP_0_X
    lda     APP_0_X
    sta     @sprite_sprite_arg + $000d
    clc
    adc     #$02
    sta     @sprite_tilemap_arg + $0008
    lda     #$01
    sta     @sprite_tilemap_arg + $0002
    jmp     @sprite_moved
:
    lda     #$00
    sta     APP_0_DIRECTION
    jmp     @sprite_moved
:
    lda     APP_0_X
    cmp     #$1e
    bcs     :+
    inc     APP_0_X
    lda     APP_0_X
    sta     @sprite_sprite_arg + $000d
    sec
    sbc     #$01
    sta     @sprite_tilemap_arg + $0008
    lda     #$01
    sta     @sprite_tilemap_arg + $0002
    jmp     @sprite_moved
:
    lda     #$20
    sta     APP_0_DIRECTION
;   jmp     @sprite_moved
@sprite_moved:

    ; アニメーションの更新
    lda     APP_0_ANIMATION
    clc
    adc     #$08
    and     #$18
    sta     APP_0_ANIMATION
    ora     APP_0_DIRECTION
    sta     @sprite_sprite_arg + $0008
;   sta     @sprite_sprite_arg + $0006

    ; スプライトの描画
@sprite_draw:
    lda     @sprite_sprite_arg + $000d
    clc
    adc     #$04
    sta     @sprite_sprite_arg + $0000
    lsr     a
    bcs     :+
    ldx     #<sprite_even
    lda     #>sprite_even
    jmp     :++
:
    ldx     #<sprite_odd
    lda     #>sprite_odd
:
    stx     @sprite_sprite_arg + $0004
    sta     @sprite_sprite_arg + $0005
    ldx     #<@sprite_sprite_arg
    lda     #>@sprite_sprite_arg
    jsr     _IocsDraw7x8Sprite
;   jsr     _IocsDraw7x8Tileset

    ; タイルマップの描画
    lda     @sprite_tilemap_arg + $0002
    beq     :+
    lda     @sprite_tilemap_arg + $0008
    clc
    adc     #$04
    sta     @sprite_tilemap_arg + $0000
    ldx     #<@sprite_tilemap_arg
    lda     #>@sprite_tilemap_arg
    jsr     _IocsDraw7x8Tilemap
:

    ; 終了
    lda     IOCS_0_KEYCODE
    cmp     #' '
    bne     :+
    inc     APP_0_STATE
:
    rts

; スプライト
@sprite_sprite_arg:
    .byte   $00, $0e
    .byte   $02, $04
    .word   sprite_even
    .word   sprite_mask
    .byte   $00
    .word   tileset_even
    .word   tilemap
    .byte   $08, $0e

; タイルマップ
@sprite_tilemap_arg:
    .byte   $00, $0e
    .byte   $01, $04
    .word   tileset_even
    .word   tilemap
    .byte   $00, $0e

.endproc

; デモを終了する
;
.proc   AppDemoEnd

    ; 最初に戻る
    lda     #$00
    sta     APP_0_STATE

    ; 終了
    rts

.endproc


; データの定義
;
.segment    "BSS"

; ワーク
;
tileset_even:
    .res    $0008 * $0100

tileset_odd:

sprite_even:
    .res    $0008 * $0080
sprite_odd:
    .res    $0008 * $0080
sprite_mask:
    .res    $0008 * $0080

tilemap:
    .res    100 * 94 + $0002

