; iocs.s - Input/Output Control System
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


; コードの定義
;
.segment    "BOOT"

; IOCS を初期化する
;
.global _IocsInitialize
.proc   _IocsInitialize

    ; スタックの設定
    tsx
    stx     IOCS_0_STACK_L
    lda     #$01
    sta     IOCS_0_STACK_H

    ; FILE MANAGER PARAMETER LIST の取得
    lda     #$0e
    sta     IOCS_0_DOS_PARAM_L
    lda     DOSWARM + $0002
    sta     IOCS_0_DOS_PARAM_H
    ldy     #$00
    lda     (IOCS_0_DOS_PARAM), y
    tax
    iny
    lda     (IOCS_0_DOS_PARAM), y
    stx     IOCS_0_DOS_PARAM_L
    sta     IOCS_0_DOS_PARAM_H

    ; キーコードの初期化
    lda     #$00
    sta     IOCS_0_KEYCODE

    ; 乱数の初期化
    lda     #$24
    sta     IOCS_0_RANDOM_L
    lda     #$20
    sta     IOCS_0_RANDOM_H

    ; カーソル位置を最下行に設定
    lda     #23
    sta     CV
    lda     #0
    sta     CH

    ; 終了
    rts

.endproc

; IOCS を更新する
;
.global _IocsUpdate
.proc   _IocsUpdate

    ; キーコードの取得
    lda     KBD
    bpl     :+
    sta     KBDSTRB
    and     #$7f
    jmp     :++
:
    lda     #$00
:
    sta     IOCS_0_KEYCODE

    ; 乱数の更新
    jsr     _IocsGetRandomNumber

    ; 終了
    rts

.endproc

; CATALOG を実行する
;
.global _IocsCatalog
.proc   _IocsCatalog

    ; OUT
    ;   a = 0 ... 成功 / else ... エラーコード

    ; DOS BUFFER の取得
    jsr     IocsUseDosBuffer

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; FILE MANAGER PARAMETER LIST の設定
    ldy     #DosParamCatalog::call
    lda     #$06
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosParamCatalog::drive
    lda     DOS_DEFAULT_DRIVE
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosParamCatalog::slot
    lda     DOS_DEFAULT_SLOT
    sta     (IOCS_0_DOS_PARAM), y

    ; DOS BUFFER アドレスの設定
    jsr     IocsSetDosBufferAddress

    ; CATALOG の呼び出し
    jsr     DOSCALL

    ; DOS BUFFER の解放
    jsr     IocsUnuseDosBuffer

    ; 返り値の取得
    ldy     #DosParamCatalog::return_code
    lda     (IOCS_0_DOS_PARAM), y

    ; 終了
    rts

.endproc

; バイナリファイルを読み込む
;
.global _IocsBload
.proc   _IocsBload

    ; IN
    ;   ax[0..1] = ファイル名
    ;   ax[2..3] = 読み込み先
    ; OUT
    ;   a = 0 ... 成功 / else ... エラーコード

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; ファイル名の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_H

    ; リトライのエントリポイント
@retry:

    ; ファイルを開く
    lda     #$04
    ldx     #$01
    jsr     IocsOpen
    tax
    bne     @error

    ; ヘッダの読み込み
    lda     #<IOCS_0_DOS_HEADER
    sta     IOCS_0_DOS_ADDRESS_L
    lda     #>IOCS_0_DOS_HEADER
    sta     IOCS_0_DOS_ADDRESS_H
    lda     #<$0004
    sta     IOCS_0_DOS_LENGTH_L
    lda     #>$0004
    sta     IOCS_0_DOS_LENGTH_H
    jsr     IocsLoad
    tax
    bne     @close

    ; アドレスの取得
    ldy     #$02
    lda     (IOCS_0_ARG), y
    iny
    ora     (IOCS_0_ARG), y
    beq     :+
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_ADDRESS_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_ADDRESS_H
:
    
    ; データの読み込み
    jsr     IocsLoad
    tax
    bne     @close

    ; ファイルを閉じる
    jsr     IocsClose
    tax
    bne     @error

    ; 終了
    rts

    ; エラー
@close:
    jsr     IocsClose
@error:
    jsr     IocsDiskError
    jmp     @retry

.endproc

; バイナリファイルを書き込む
;
.global _IocsBsave
.proc   _IocsBsave

    ; IN
    ;   ax[0..1] = ファイル名
    ;   ax[2..3] = 書き込み元
    ;   ax[4..5] = 書き込むバイト数
    ; OUT
    ;   a = 0 ... 成功 / else ... エラーコード

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; ファイル名の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_FILENAME_H

    ; リトライのエントリポイント
@retry:

    ; ファイルを開く
    lda     #$04
    sta     IOCS_0_DOS_FILETYPE
    lda     #$00
    sta     IOCS_0_DOS_FLAG
    jsr     IocsOpen
    tax
    bne     @error

    ; ヘッダの書き込み
    lda     IOCS_0_ARG_L
    clc
    adc     #$02
    sta     IOCS_0_DOS_ADDRESS_L
    lda     IOCS_0_ARG_H
    adc     #$00
    sta     IOCS_0_DOS_ADDRESS_H
    lda     #<$0004
    sta     IOCS_0_DOS_LENGTH_L
    lda     #>$0004
    sta     IOCS_0_DOS_LENGTH_H
    jsr     IocsSave
    tax
    bne     @close
    
    ; データの書き込み
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_ADDRESS_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_ADDRESS_H
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_LENGTH_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_DOS_LENGTH_H
    jsr     IocsSave
    tax
    bne     @close

    ; ファイルを閉じる
    jsr     IocsClose
    tax
    bne     @error

    ; 終了
    rts

    ; エラー
@close:
    jsr     IocsClose
@error:
    jsr     IocsDiskError
    jmp     @retry

.endproc

; バイナリファイルを実行する
;
.global _IocsBrun
.proc   _IocsBrun

    ; IN
    ;   ax[0..1] = ファイル名
    ;   ax[2..3] = 読み込み/ジャンプ先

    ; ファイルの読み込み
    jsr     _IocsBload

    ; 実行
    jmp     (IOCS_0_DOS_ADDRESS)

.endproc

; 空いている DOS BUFFER をゼロページに取得する
;
.proc   IocsUseDosBuffer

    ; OUT
    ;   IOCS_0_DOS_BUFFER = DOS BUFFER

    ; DOS ルーチンから DOS BUFFER のエントリポイントを取得
    ldy     #$00
    sty     IOCS_0_DOS_BUFFER_L
    lda     DOSWARM + $0002
    sta     IOCS_0_DOS_BUFFER_H

    ; DOS BUFFER の確認
:
    lda     (IOCS_0_DOS_BUFFER), y
    tax
    iny
    lda     (IOCS_0_DOS_BUFFER), y
    sta     IOCS_0_DOS_BUFFER_H
    stx     IOCS_0_DOS_BUFFER_L
    bne     :+
    txa
    beq     @error
:

    ; ファイル名の確認
    ldy     #$00
    lda     (IOCS_0_DOS_BUFFER), y
    beq     :+
    ldy     #DosBuffer::next_buffer_address
    jmp     :--
:

    ; 終了
    rts

    ; エラー終了
@error:
    ldx     #<@error_message
    lda     #>@error_message
    jmp     _IocsError
@error_message:
    .asciiz "ERR - NO BUFFER"

.endproc

; DOS BUFFER を解放する
;
.proc   IocsUnuseDosBuffer

    ; IN
    ;   IOCS_0_DOS_BUFFER = DOS BUFFER

    ; DOS BUFFER のファイル名をクリア
    ldy     #DosBuffer::filename
    lda     #$00
    sta     (IOCS_0_DOS_BUFFER), y

    ; 終了
    rts

.endproc

; DOS BUFFER にファイル名をコピーする
;
.proc   IocsCopyFilenameToBuffer

    ; IN
    ;   IOCS_0_DOS_FILENAME = ファイル名
    ;   IOCS_0_DOS_BUFFER   = コピー先

    ; ファイル名のコピー
    ldy     #$00
    ldx     #$1e
:
    lda     (IOCS_0_DOS_FILENAME), y
    beq     :+
    ora     #$80
    sta     (IOCS_0_DOS_BUFFER), y
    iny
    dex
    bne     :-
    rts
:
    ; 残りを空白で埋める
    lda     #$a0
:
    sta     (IOCS_0_DOS_BUFFER), y
    iny
    dex
    bne     :-

    ; 終了
    rts

.endproc

; DOS BUFFER のアドレスを FILE MANAGER PARAMETER LIST に設定する
;
.proc   IocsSetDosBufferAddress

    ; IN
    ;   IOCS_0_DOS_BUFFER = DOS BUFFER
    ;   IOCS_0_DOS_PARAM  = FILE MANAGER PARAMETER LIST

    ; WORKAREA アドレスの設定
    ldy     #DosBuffer::workarea_address + $00
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::workarea_address + $00
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosBuffer::workarea_address + $01
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::workarea_address + $01
    sta     (IOCS_0_DOS_PARAM), y

    ; LIST SECTOR アドレスの設定
    ldy     #DosBuffer::list_sector_address + $00
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::list_sector_address + $00
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosBuffer::list_sector_address + $01
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::list_sector_address + $01
    sta     (IOCS_0_DOS_PARAM), y

    ; DATA SECTOR アドレスの設定
    ldy     #DosBuffer::data_sector_address + $00
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::data_sector_address + $00
    sta     (IOCS_0_DOS_PARAM), y
    ldy     #DosBuffer::data_sector_address + $01
    lda     (IOCS_0_DOS_BUFFER), y
    ldy     #DosParam::data_sector_address + $01
    sta     (IOCS_0_DOS_PARAM), y

    ; 終了
    rts

.endproc

; ディスクエラーの復帰待ちを行う
;
.proc   IocsDiskError

    ; メッセージの表示とキー入力待ち
    ldx     #<@error_message
    lda     #>@error_message
    jsr     _IocsRetry
    rts

@error_message:
    .asciiz "INSERT CORRECT DISK AND PRESS KEY"

.endproc

; ファイルを開く
;
.proc   IocsOpen

    ; IN
    ;   IOCS_0_DOS_FILENAME = ファイル名
    ;   IOCS_0_DOS_FILETYPE = ファイルタイプ
    ;   IOCS_0_DOS_FLAG     = 0 ... ファイルがない場合は作成する
    ; OUT
    ;   a = 0 ... 成功 / else ... エラーコード

    ; DOS BUFFER の取得
    jsr     IocsUseDosBuffer

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; OPEN の設定
    ldy     #DosParamOpen::call
    lda     #$01
    sta     (IOCS_0_DOS_PARAM), y

    ; レコード長の設定
    ldy     #DosParamOpen::record_length
    lda     #$00
    sta     (IOCS_0_DOS_PARAM), y
    iny
    sta     (IOCS_0_DOS_PARAM), y

    ; ボリュームの設定
    ldy     #DosParamOpen::volume
;   lda     DOS_DEFAULT_VOLUME
;;  lda     #$00
    sta     (IOCS_0_DOS_PARAM), y

    ; ドライブの設定
    ldy     #DosParamOpen::drive
    lda     DOS_DEFAULT_DRIVE
    sta     (IOCS_0_DOS_PARAM), y

    ; スロットの設定
    ldy     #DosParamOpen::slot
    lda     DOS_DEFAULT_SLOT
    sta     (IOCS_0_DOS_PARAM), y

    ; ファイルタイプの設定
    ldy     #DosParamOpen::filetype
    lda     IOCS_0_DOS_FILETYPE
    sta     (IOCS_0_DOS_PARAM), y

    ; ファイル名アドレスの設定
    ldy     #DosParamOpen::filename_address
    lda     IOCS_0_DOS_BUFFER_L
    sta     (IOCS_0_DOS_PARAM), y
    iny
    lda     IOCS_0_DOS_BUFFER_H
    sta     (IOCS_0_DOS_PARAM), y

    ; ファイル名のコピー
    jsr     IocsCopyFilenameToBuffer

    ; DOS BUFFER アドレスの設定
    jsr     IocsSetDosBufferAddress

    ; OPEN の呼び出し
    ldx     IOCS_0_DOS_FLAG
    jsr     DOSCALL

    ; 返り値の取得
    lda     #$06
    ldx     IOCS_0_DOS_FLAG
    beq     :+
    lda     #$00
:
    jsr     IocsGetReturnCode
    tax
    beq     :+
    pha
    jsr     IocsUnuseDosBuffer
    pla
:

    ; 終了
    rts

.endproc

; ファイルを閉じる
;
.proc   IocsClose

    ; OUT
    ;   a = 0 ... 成功 / else ... エラーコード

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; CLOSE の設定
    ldy     #DosParamOpen::call
    lda     #$02
    sta     (IOCS_0_DOS_PARAM), y

    ; CLOSE の呼び出し
    jsr     DOSCALL

    ; DOS BUFFER の解放
    jsr     IocsUnuseDosBuffer

    ; 返り値の取得
    lda     #$00
    jsr     IocsGetReturnCode

    ; 終了
    rts

.endproc

; ファイルを読み込む
;
.proc   IocsLoad

    ; IN
    ;   IOCS_0_DOS_ADDRESS = 読み込み先
    ;   IOCS_0_DOS_LENGTH  = 読み込むバイト数
    ; OUT
    ;   a = 0 ... 成功 / else ... エラーコード

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; READ の設定
    ldy     #DosParamRead::call
    lda     #$03
    sta     (IOCS_0_DOS_PARAM), y
;;  ldy     #DosParamRead::subcall
    iny
    lda     #$02
    sta     (IOCS_0_DOS_PARAM), y

;   ; レコード番号の設定
;   ldy     #DosParamRead::record_number
;   lda     #$00
;   sta     (IOCS_0_DOS_PARAM), y
;   iny
;   sta     (IOCS_0_DOS_PARAM), y

;   ; オフセットの設定
;   ldy     #DosParamRead::byte_offset
;   lda     #$00
;   sta     (IOCS_0_DOS_PARAM), y
;   iny
;   sta     (IOCS_0_DOS_PARAM), y

    ; 読み込むバイト数の設定
    ldy     #DosParamRead::read_length
    lda     IOCS_0_DOS_LENGTH_L
    sta     (IOCS_0_DOS_PARAM), y
    iny
    lda     IOCS_0_DOS_LENGTH_H
    sta     (IOCS_0_DOS_PARAM), y

    ; 読み込み先の設定
    ldy     #DosParamRead::read_address
    lda     IOCS_0_DOS_ADDRESS_L
    sta     (IOCS_0_DOS_PARAM), y
    iny
    lda     IOCS_0_DOS_ADDRESS_H
    sta     (IOCS_0_DOS_PARAM), y

    ; READ の呼び出し
    jsr     DOSCALL
    
    ; 返り値の取得
    lda     #$00
    jsr     IocsGetReturnCode

    ; 終了
    rts

.endproc

; ファイルを書き込む
;
.proc   IocsSave

    ; IN
    ;   IOCS_0_DOS_ADDRESS = 書き込み元
    ;   IOCS_0_DOS_LENGTH  = 書き込むバイト数
    ; OUT
    ;   a = 0 ... 成功 / else ... エラーコード

    ; FILE MANAGER PARAMETER LIST は取得済み

    ; WRITE の設定
    ldy     #DosParamWrite::call
    lda     #$04
    sta     (IOCS_0_DOS_PARAM), y
;;  ldy     #DosParamWrite::subcall
    iny
    lda     #$02
    sta     (IOCS_0_DOS_PARAM), y

;   ; レコード番号の設定
;   ldy     #DosParamWrite::record_number
;   lda     #$00
;   sta     (IOCS_0_DOS_PARAM), y
;   iny
;   sta     (IOCS_0_DOS_PARAM), y

;   ; オフセットの設定
;   ldy     #DosParamWrite::byte_offset
;   lda     #$00
;   sta     (IOCS_0_DOS_PARAM), y
;   iny
;   sta     (IOCS_0_DOS_PARAM), y

    ; 書き込むバイト数の設定（-1 する）
    ldy     #DosParamWrite::write_length
    lda     IOCS_0_DOS_LENGTH_L
    sec
    sbc     #$01
    sta     (IOCS_0_DOS_PARAM), y
    lda     IOCS_0_DOS_LENGTH_H
    sbc     #$00
    iny
    sta     (IOCS_0_DOS_PARAM), y

    ; 書き込み元の設定
    ldy     #DosParamWrite::write_address
    lda     IOCS_0_DOS_ADDRESS_L
    sta     (IOCS_0_DOS_PARAM), y
    iny
    lda     IOCS_0_DOS_ADDRESS_H
    sta     (IOCS_0_DOS_PARAM), y

    ; WRITE の呼び出し
    jsr     DOSCALL
    
    ; 返り値の取得
    lda     #$00
    jsr     IocsGetReturnCode

    ; 終了
    rts

.endproc

; リターンコードを取得する
;
.proc   IocsGetReturnCode

    ; IN
    ;   IOCS_0_DOS_PARAM = FILE MANAGER PARAMETER LIST
    ;   a                = エラーとしないコード
    ; OUT
    ;   a = 0 ... 成功 / else ... エラーコード

    ; リターンコードの取得
    ldy     #DosParam::return_code
    sec
    sbc     (IOCS_0_DOS_PARAM), y
    beq     :+
    lda     (IOCS_0_DOS_PARAM), y
    beq     :+

    ; エラーの出力
    pha
    ldx     #<@error_message
    lda     #>@error_message
    jsr     _IocsCoutString
    pla
    pha
    jsr     PRBYTE
    jsr     CROUT1
    pla
:

    ; 終了
    rts

    ; エラ〜メッセージ
@error_message:
    .asciiz "ERR - CODE "

.endproc

; VRAM をクリアする
;
.global _IocsClearVram
.proc   _IocsClearVram

    ; $2000..$3fff を 0 クリアする
    lda     #<HGR1SCRN
    sta     IOCS_0_HGR_DST_L
    lda     #>HGR1SCRN
    sta     IOCS_0_HGR_DST_H
    ldx     #$20
:
    ldy     #$00
    tya
:
    sta     (IOCS_0_HGR_DST), y
    inc     IOCS_0_HGR_DST_L
    bne     :-
    inc     IOCS_0_HGR_DST_H
    dex
    bne     :--

    ; 終了
    rts

.endproc

; VRAM のアドレスを取得する
;
.global _IocsGetVramAddress
.proc   _IocsGetVramAddress

    ; IN
    ;   x = X タイル位置
    ;   y = Y タイル位置
    ; OUT
    ;   ax = アドレス
    ; WORK
    ;   IOCS_0_WORK_0

    ; アドレス計算
    txa
    clc
    adc     hgr_tile_y_address_low, y
    tax
    lda     #$00
    adc     hgr_tile_y_address_high, y

    ; 終了
    rts

.endproc

; 7x8 タイルセットのピクセルパターンアドレスを取得する
;
.global _IocsGet7x8PatternAddress
.proc   _IocsGet7x8PatternAddress

    ; IN
    ;   yx = タイルセット
    ;   a  = タイル番号
    ; OUT
    ;   ax = 7x8 ピクセルパターン
    ; WORK
    ;   IOCS_0_WORK_0

    ; ax = yx + a * 8
    stx     IOCS_0_WORK_0
    ldx     #$00
    stx     IOCS_0_WORK_1
    asl     a
    rol     IOCS_0_WORK_1
    asl     a
    rol     IOCS_0_WORK_1
    asl     a
    rol     IOCS_0_WORK_1
;;  clc
    adc     IOCS_0_WORK_0
    tax
    tya
    adc     IOCS_0_WORK_1

    ; 終了
    rts

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンをタイル位置を指定して描画する
;
.proc   IocsDraw7x8PatternXy

    ; IN
    ;   IOCS_0_HGR_SRC = 7x8 ピクセルパターン
    ;   x              = X タイル位置
    ;   y              = Y タイル位置

    ; 転送先アドレスの取得
    jsr     _IocsGetVramAddress

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを VRAM アドレスを指定して描画する
;
.proc IocsDraw7x8PatternAx

    ; IN
    ;   IOCS_0_HGR_SRC = 7x8 ピクセルパターン
    ;   ax             = VRAM アドレス

    ; 転送先アドレスの設定
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_HGR_DST へ描画する
;
.proc IocsDraw7x8Pattern0

    ; IN
    ;   IOCS_0_HGR_SRC = 7x8 ピクセルパターン
    ;   IOCS_0_HGR_DST = VRAM アドレス

    ; IOCS_0_HGR_DST_H の保存
    lda     IOCS_0_HGR_DST_H
    pha

    ; 8 ライン分の描画
    ldx     #$00

    ; 1 ライン目
    ldy     #$00
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 2 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 3 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 4 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 5 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 6 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 7 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 8 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; IOCS_0_HGR_DST_H の復帰
    pla
    sta     IOCS_0_HGR_DST_H

    ; 終了
    rts

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_MASK でマスクして指定されたタイル位置へ描画する
;
.proc   IocsDraw7x8MaskedXy

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   x               = X タイル位置
    ;   y               = Y タイル位置

    ; 転送先アドレスの取得
    jsr     _IocsGetVramAddress

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_MASK でマスクして指定された VRAM アドレスへ描画する
;
.proc IocsDraw7x8MaskedAx

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   ax              = VRAM アドレス

    ; 転送先アドレスの設定
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_MASK でマスクして IOCS_0_HGR_DST へ描画する
;
.proc IocsDraw7x8Masked0

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   IOCS_0_HGR_DST  = VRAM アドレス

    ; IOCS_0_HGR_DST_H の保存
    lda     IOCS_0_HGR_DST_H
    pha

    ; 8 ライン分の描画
    ldx     #$00

    ; 1 ライン目
    ldy     #$00
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 2 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 3 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 4 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 5 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 6 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 7 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 8 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_DST, x)
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; IOCS_0_HGR_DST_H の復帰
    pla
    sta     IOCS_0_HGR_DST_H

    ; 終了
    rts

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_BASE に IOCS_0_MASK でマスクして重ね合わせて指定されたタイル位置へ描画する
;
.proc   IocsDraw7x8LayeredXy

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   IOCS_0_HGR_BASE = 7x8 重ね合わせられるピクセルパターン
    ;   x               = X タイル位置
    ;   y               = Y タイル位置

    ; 転送先アドレスの取得
    jsr     _IocsGetVramAddress

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_BASE に IOCS_0_MASK でマスクして重ね合わせて指定された VRAM アドレスへ描画する
;
.proc IocsDraw7x8LayeredAx

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   IOCS_0_HGR_BASE = 7x8 重ね合わせられるピクセルパターン
    ;   ax              = VRAM アドレス

    ; 転送先アドレスの設定
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

.endproc

; IOCS_0_HGR_SRC の 7x8 ピクセルパターンを IOCS_0_BASE に IOCS_0_MASK でマスクして重ね合わせて IOCS_0_HGR_DST へ描画する
;
.proc IocsDraw7x8Layered0

    ; IN
    ;   IOCS_0_HGR_SRC  = 7x8 重ね合わせるピクセルパターン
    ;   IOCS_0_HGR_MASK = 7x8 マスクパターン
    ;   IOCS_0_HGR_BASE = 7x8 重ね合わせられるピクセルパターン
    ;   IOCS_0_HGR_DST  = VRAM アドレス

    ; IOCS_0_HGR_DST_H の保存
    lda     IOCS_0_HGR_DST_H
    pha

    ; 8 ライン分の描画
    ldx     #$00

    ; 1 ライン目
    ldy     #$00
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 2 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 3 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 4 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 5 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 6 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 7 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; 8 ライン目
    iny
    lda     IOCS_0_HGR_DST_H
    clc
    adc     #$04
    sta     IOCS_0_HGR_DST_H
    lda     (IOCS_0_HGR_BASE), y
    and     (IOCS_0_HGR_MASK), y
    ora     (IOCS_0_HGR_SRC), y
    sta     (IOCS_0_HGR_DST, x)

    ; IOCS_0_HGR_DST_H の復帰
    pla
    sta     IOCS_0_HGR_DST_H

    ; 終了
    rts

.endproc

; 文字列を描画する
;
.global _IocsDrawString
.proc   _IocsDrawString

    ; IN
    ;   ax[0]    = X タイル位置
    ;   ax[1]    = Y タイル位置
    ;   ax[2..3] = 文字列

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; 描画アドレスの取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_STRING_VRAM_X
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_STRING_VRAM_Y
    tay
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 文字列の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_STRING_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_STRING_H

    ; 文字列の描画
    lda     #$00
    sta     IOCS_0_HGR_STRING_INDEX
@draw_start:

    ; 文字の取得
    ldy     IOCS_0_HGR_STRING_INDEX
    lda     (IOCS_0_HGR_STRING), y
    beq     @draw_end

    ; 改行
    cmp     #$0d
    beq     :+
    cmp     #$0a
    bne     :++
:
    ldy     #$00
    ldx     IOCS_0_HGR_STRING_VRAM_X
    inc     IOCS_0_HGR_STRING_VRAM_Y
    ldy     IOCS_0_HGR_STRING_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H
    inc     IOCS_0_HGR_STRING_INDEX
    jmp     @draw_start
:    

    ; 1 文字の描画
    ldx     #<font
    ldy     #>font
    sec
    sbc     #$20
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H
    jsr     IocsDraw7x8Pattern0
    inc     IOCS_0_HGR_DST_L
    inc     IOCS_0_HGR_STRING_INDEX
    jmp     @draw_start

    ; 文字列の描画の終了
@draw_end:

    ; 終了
    rts

.endproc

; 7x8 サイズのピクセルパターンを描画する
;
.global _IocsDraw7x8Pattern
.proc   _IocsDraw7x8Pattern

    ; IN
    ;   ax[0]    = X タイル位置
    ;   ax[1]    = Y タイル位置
    ;   ax[2..3] = タイルセット
    ;   ax[4]    = タイル番号

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; ピクセルパターンの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
    pha
    ldy     #$02
    lda     (IOCS_0_ARG), y
    tax
    iny
    lda     (IOCS_0_ARG), y
    tay
    pla
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; 位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    tax
    iny
    lda     (IOCS_0_ARG), y
    tay

    ; ピクセルパターンの描画
    jsr     IocsDraw7x8PatternXy
    
    ; 終了
    rts

.endproc

; 7x8 ピクセルパターンのタイルセットを描画する
;
.global _IocsDraw7x8Tileset
.proc   _IocsDraw7x8Tileset

    ; IN
    ;   ax[0]      = X タイル位置
    ;   ax[1]      = Y タイル位置
    ;   ax[2]      = 描画の幅
    ;   ax[3]      = 描画の高さ
    ;   ax[4..5]   = タイルセット
    ;   ax[6]      = タイル番号

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; タイルセットの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_SRC_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SRC_H
    ldy     #$06
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_SRC_L
    ldy     IOCS_0_HGR_SRC_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; 描画位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_VRAM_X
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_VRAM_Y

    ; 描画の高さの設定
    ldy     #$03
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_Y
@draw_y:

    ; VRAM アドレスの取得
    ldx     IOCS_0_HGR_TILESET_VRAM_X
    ldy     IOCS_0_HGR_TILESET_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 描画の幅の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_X
@draw_x:

    ; 縦 8 ピクセル分のパターンの描画
    jsr     IocsDraw7x8Pattern0

    ; 次のタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_L
    bcc     :+
    inc     IOCS_0_HGR_SRC_H
:

    ; 次の桁へ
    dec     IOCS_0_HGR_TILESET_X
    beq     :++
    inc     IOCS_0_HGR_TILESET_L
    bne     :+
    inc     IOCS_0_HGR_TILESET_H
:
    inc     IOCS_0_HGR_DST_L
    jmp     @draw_x
:

    ; 次の行へ
    dec     IOCS_0_HGR_TILESET_Y
    beq     :+
    inc     IOCS_0_HGR_TILESET_VRAM_Y
    jmp     @draw_y
:

    ; 終了
    rts

.endproc

; 7x8 ピクセルパターンのマスクしたタイルセットを描画する
;
.global _IocsDraw7x8MaskedTileset
.proc   _IocsDraw7x8MaskedTileset

    ; IN
    ;   ax[0]      = X タイル位置
    ;   ax[1]      = Y タイル位置
    ;   ax[2]      = 描画の幅
    ;   ax[3]      = 描画の高さ
    ;   ax[4..5]   = タイルセット
    ;   ax[6..7]   = マスクタイルセット
    ;   ax[8]      = タイル番号

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; タイルセットの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_SRC_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SRC_H
    ldy     #$08
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_SRC_L
    ldy     IOCS_0_HGR_SRC_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; マスクタイルセットの取得
    ldy     #$06
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_MASK_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_MASK_H
;;  ldy     #$08
    iny
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_MASK_L
    ldy     IOCS_0_HGR_MASK_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_MASK_L
    sta     IOCS_0_HGR_MASK_H

    ; 描画位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_VRAM_X
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_VRAM_Y

    ; 描画の高さの設定
    ldy     #$03
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_Y
@draw_y:

    ; VRAM アドレスの取得
    ldx     IOCS_0_HGR_TILESET_VRAM_X
    ldy     IOCS_0_HGR_TILESET_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 描画の幅の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILESET_X
@draw_x:

    ; 縦 8 ピクセル分のパターンの描画
    jsr     IocsDraw7x8Masked0

    ; 次のタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_L
    bcc     :+
    inc     IOCS_0_HGR_SRC_H
:

    ; 次のマスクタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_MASK_L
    sta     IOCS_0_HGR_MASK_L
    bcc     :+
    inc     IOCS_0_HGR_MASK_H
:

    ; 次の桁へ
    dec     IOCS_0_HGR_TILESET_X
    beq     :++
    inc     IOCS_0_HGR_TILESET_L
    bne     :+
    inc     IOCS_0_HGR_TILESET_H
:
    inc     IOCS_0_HGR_DST_L
    jmp     @draw_x
:

    ; 次の行へ
    dec     IOCS_0_HGR_TILESET_Y
    beq     :+
    inc     IOCS_0_HGR_TILESET_VRAM_Y
    jmp     @draw_y
:

    ; 終了
    rts

.endproc

; 7x8 ピクセルパターンのタイルマップを描画する
;
.global _IocsDraw7x8Tilemap
.proc   _IocsDraw7x8Tilemap

    ; IN
    ;   ax[0]    = X タイル位置
    ;   ax[1]    = Y タイル位置
    ;   ax[2]    = 描画の幅
    ;   ax[3]    = 描画の高さ
    ;   ax[4..5] = タイルセット
    ;   ax[6..7] = タイルマップ
    ;   ax[8]    = タイルマップの開始 X 位置
    ;   ax[9]    = タイルマップの開始 Y 位置

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; タイルセットの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_TILESET_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_TILESET_H

    ; タイルマップの取得
;;  ldy     #$06
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_H

    ; タイルマップの幅の取得
    ldy     #$00
    lda     (IOCS_0_HGR_TILEMAP), y
    sta     IOCS_0_HGR_TILEMAP_WIDTH

    ; タイルマップの次の行への加算値の取得
    ldy     #$02
    sec
    sbc     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_NEXTLINE
    inc     IOCS_0_HGR_TILEMAP_NEXTLINE

    ; タイルマップの開始アドレスの取得
    ldy     #$08
    lda     (IOCS_0_ARG), y
    clc
    adc     #$02                ; タイルマップの幅は 253 以下と仮定
    adc     IOCS_0_HGR_TILEMAP_L
    sta     IOCS_0_HGR_TILEMAP_L
    bcc     :+
    inc     IOCS_0_HGR_TILEMAP_H
:
    iny
    lda     (IOCS_0_ARG), y
    ldx     IOCS_0_HGR_TILEMAP_WIDTH
    jsr     _IocsAxX
    tay
    txa
    clc
    adc     IOCS_0_HGR_TILEMAP_L
    sta     IOCS_0_HGR_TILEMAP_L
    tya
    adc     IOCS_0_HGR_TILEMAP_H
    sta     IOCS_0_HGR_TILEMAP_H

    ; 描画位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_VRAM_X
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_VRAM_Y

    ; 描画の高さの設定
    ldy     #$03
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_Y
@draw_y:

    ; VRAM アドレスの取得
    ldx     IOCS_0_HGR_TILEMAP_VRAM_X
    ldy     IOCS_0_HGR_TILEMAP_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 描画の幅の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_TILEMAP_X
@draw_x:

    ; ピクセルパターンの取得
    ldy     #$00
    lda     (IOCS_0_HGR_TILEMAP), y
    ldx     IOCS_0_HGR_TILEMAP_TILESET_L
    ldy     IOCS_0_HGR_TILEMAP_TILESET_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; 縦 8 ピクセル分のパターンの描画
    jsr     IocsDraw7x8Pattern0

    ; 次の桁へ
    dec     IOCS_0_HGR_TILEMAP_X
    beq     :++
    inc     IOCS_0_HGR_TILEMAP_L
    bne     :+
    inc     IOCS_0_HGR_TILEMAP_H
:
    inc     IOCS_0_HGR_DST_L
    jmp     @draw_x
:

    ; 次の行へ
    dec     IOCS_0_HGR_TILEMAP_Y
    beq     :++
    lda     IOCS_0_HGR_TILEMAP_NEXTLINE
    clc
    adc     IOCS_0_HGR_TILEMAP_L
    sta     IOCS_0_HGR_TILEMAP_L
    bcc     :+
    inc     IOCS_0_HGR_TILEMAP_H
:
    inc     IOCS_0_HGR_TILEMAP_VRAM_Y
    jmp     @draw_y
:

    ; 終了
    rts

.endproc

; 7x8 ピクセルパターンのスプライトを描画する
;
.global _IocsDraw7x8Sprite
.proc   _IocsDraw7x8Sprite

    ; IN
    ;   ax[0]      = X タイル位置
    ;   ax[1]      = Y タイル位置
    ;   ax[2]      = 描画の幅
    ;   ax[3]      = 描画の高さ
    ;   ax[4..5]   = スプライトタイルセット
    ;   ax[6..7]   = マスクタイルセット
    ;   ax[8]      = スプライトのタイル番号
    ;   ax[9..10]  = タイルマップタイルセット
    ;   ax[11..12] = タイルマップ
    ;   ax[13]     = タイルマップの開始 X 位置
    ;   ax[14]     = タイルマップの開始 Y 位置

    ; 引数の保持
    stx     IOCS_0_ARG_L
    sta     IOCS_0_ARG_H

    ; スプライトタイルセットの取得
    ldy     #$04
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_SRC_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SRC_H
    ldy     #$08
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_SRC_L
    ldy     IOCS_0_HGR_SRC_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_H

    ; マスクタイルセットの取得
    ldy     #$06
    lda     (IOCS_0_ARG), y
;   sta     IOCS_0_HGR_MASK_L
    tax
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_MASK_H
;;  ldy     #$08
    iny
    lda     (IOCS_0_ARG), y
;   ldx     IOCS_0_HGR_MASK_L
    ldy     IOCS_0_HGR_MASK_H
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_MASK_L
    sta     IOCS_0_HGR_MASK_H

    ; タイルマップタイルセットの取得
    ldy     #$09
    lda     (IOCS_0_ARG), y
    sta     @tilemap_tileset_l
    iny
    lda     (IOCS_0_ARG), y
    sta     @tilemap_tileset_h

    ; タイルマップの取得
    ldy     #$0b
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_L
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_H

    ; タイルマップの幅の取得
    ldy     #$00
    lda     (IOCS_0_HGR_SPRITE_TILEMAP), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_WIDTH

    ; タイルマップの次の行への加算値の取得
    ldy     #$02
    sec
    sbc     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_NEXTLINE
    inc     IOCS_0_HGR_SPRITE_TILEMAP_NEXTLINE

    ; タイルマップの開始アドレスの取得
    ldy     #$0d
    lda     (IOCS_0_ARG), y
    clc
    adc     #$02                ; タイルマップの幅は 253 以下と仮定
    adc     IOCS_0_HGR_SPRITE_TILEMAP_L
    sta     IOCS_0_HGR_SPRITE_TILEMAP_L
    bcc     :+
    inc     IOCS_0_HGR_SPRITE_TILEMAP_H
:
    iny
    lda     (IOCS_0_ARG), y
    ldx     IOCS_0_HGR_SPRITE_TILEMAP_WIDTH
    jsr     _IocsAxX
    tay
    txa
    clc
    adc     IOCS_0_HGR_SPRITE_TILEMAP_L
    sta     IOCS_0_HGR_SPRITE_TILEMAP_L
    tya
    adc     IOCS_0_HGR_SPRITE_TILEMAP_H
    sta     IOCS_0_HGR_SPRITE_TILEMAP_H

    ; 描画位置の取得
    ldy     #$00
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_VRAM_X
    iny
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_VRAM_Y

    ; 描画の高さの設定
    ldy     #$03
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_Y
@draw_y:

    ; VRAM アドレスの取得
    ldx     IOCS_0_HGR_SPRITE_VRAM_X
    ldy     IOCS_0_HGR_SPRITE_VRAM_Y
    jsr     _IocsGetVramAddress
    stx     IOCS_0_HGR_DST_L
    sta     IOCS_0_HGR_DST_H

    ; 描画の幅の設定
    ldy     #$02
    lda     (IOCS_0_ARG), y
    sta     IOCS_0_HGR_SPRITE_TILEMAP_X
@draw_x:

    ; タイルマップの取得
    ldy     #$00
    lda     (IOCS_0_HGR_SPRITE_TILEMAP), y
    ldx     @tilemap_tileset_l
    ldy     @tilemap_tileset_h
    jsr     _IocsGet7x8PatternAddress
    stx     IOCS_0_HGR_BASE_L
    sta     IOCS_0_HGR_BASE_H

    ; 縦 8 ピクセル分のパターンの重ね合わせ描画
    jsr     IocsDraw7x8Layered0

    ; 次のスプライトタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_SRC_L
    sta     IOCS_0_HGR_SRC_L
    bcc     :+
    inc     IOCS_0_HGR_SRC_H
:

    ; 次のマスクタイルセットへ
    lda     #$08
    clc
    adc     IOCS_0_HGR_MASK_L
    sta     IOCS_0_HGR_MASK_L
    bcc     :+
    inc     IOCS_0_HGR_MASK_H
:

    ; 次の桁へ
    dec     IOCS_0_HGR_SPRITE_TILEMAP_X
    beq     :++
    inc     IOCS_0_HGR_SPRITE_TILEMAP_L
    bne     :+
    inc     IOCS_0_HGR_SPRITE_TILEMAP_H
:
    inc     IOCS_0_HGR_DST_L
    jmp     @draw_x
:

    ; 次の行へ
    dec     IOCS_0_HGR_SPRITE_TILEMAP_Y
    beq     :++
    lda     IOCS_0_HGR_SPRITE_TILEMAP_NEXTLINE
    clc
    adc     IOCS_0_HGR_SPRITE_TILEMAP_L
    sta     IOCS_0_HGR_SPRITE_TILEMAP_L
    bcc     :+
    inc     IOCS_0_HGR_SPRITE_TILEMAP_H
:
    inc     IOCS_0_HGR_SPRITE_VRAM_Y
    jmp     @draw_y
:

    ; 終了
    rts

; タイルマップタイルセット
@tilemap_tileset_l:
    .byte   $00
@tilemap_tileset_h:
    .byte   $00

.endproc

; COUT による文字列の出力を行う
;
.global _IocsCoutString
.proc   _IocsCoutString

    ; IN
    ;   ax = 文字列
    ; WORK
    ;   IOCS_0_WORK_0..1

    ; 文字列の出力
    stx     IOCS_0_WORK_0
    sta     IOCS_0_WORK_1
    ldy     #$00
:
    lda     (IOCS_0_WORK_0), y
    beq     :+
    ora     #$80
    jsr     COUT1
    iny
    jmp     :-
:

    ; 終了
    rts

.endproc

; メモリダンプする
;
.global _IocsDump
.proc   _IocsDump

    ; IN
    ;   ax = アドレス
    ;    y x 16 バイトをダンプ
    ; WORK
    ;   IOCS_0_WORK_0..2

    ; 
    stx     IOCS_0_WORK_0
    sta     IOCS_0_WORK_1
    sty     IOCS_0_WORK_2

    ; 16 バイトずつダンプ
:
    ldx     IOCS_0_WORK_0
    lda     IOCS_0_WORK_1
    jsr     PRNTAX
    lda     #$a0
    jsr     COUT1
    ldy     #$00
:
    lda     (IOCS_0_WORK_0), y
    jsr     PRBYTE
    iny
    tya
    and     #$07
    bne     :-
    lda     #$a0
    jsr     COUT1
    tya
    and     #$10
    beq     :-
    jsr     CROUT1
    dec     IOCS_0_WORK_2
    beq     :+
    lda     IOCS_0_WORK_0
    clc
    adc     #$10
    sta     IOCS_0_WORK_0
    bcc     :--
    inc     IOCS_0_WORK_1
    jmp     :--
:

    ; 終了
    rts

.endproc

; A * X の計算を行う
;
.global _IocsAxX
.proc   _IocsAxX

    ; IN
    ;   a = かけられる数
    ;   x = かける数
    ; OUT
    ;   ax = 結果
    ; WORK
    ;   IOCS_WORK_0..1

    ; ax = a * x
    lsr     a
    sta     IOCS_0_WORK_0
    dex                         ; あらかじめ -1 しておく
    stx     IOCS_0_WORK_1
    lda     #0
    ldx     #8
@loop:
    bcc     @skip
;;  clc                         ; ここは必ず cf = 1 なので +1 される
    adc     IOCS_0_WORK_1
@skip:
    ror     a
    ror     IOCS_0_WORK_0
    dex
    bne     @loop
    ldx     IOCS_0_WORK_0
  
    ; 終了
    rts

.endproc

; YX + A * 8 の計算を行う
;
.global _IocsYXplus8A
.proc   _IocsYXplus8A

    ; IN
    ;   yx = 足される数
    ;   a  = 8 倍される数
    ; OUT
    ;   ax = 結果
    ; WORK
    ;   IOCS_WORK_0..1

    ; ax = yx + a * 8
    sta     IOCS_0_WORK_0
    lda     #$00
    asl     IOCS_0_WORK_0
    rol     a
    asl     IOCS_0_WORK_0
    rol     a
    asl     IOCS_0_WORK_0
    rol     a
    sta     IOCS_0_WORK_1
    txa
;;  clc
    adc     IOCS_0_WORK_0
    tax
    tya
    adc     IOCS_0_WORK_1

    ; 終了
    rts

.endproc

; 乱数を取得する
;
.global _IocsGetRandomNumber
.proc   _IocsGetRandomNumber

    ; OUT
    ;   a = 乱数
    ; WORK
    ;   IOCS_0_WORK_0

    ; IOCS_0_RANDOM = IOCS_0_RANDOM * 5 + 1
.if 1
    lda     IOCS_0_RANDOM_H
    sta     IOCS_0_WORK_0
    lda     IOCS_0_RANDOM_H
    asl     a
    rol     IOCS_0_WORK_0
    asl     a
    rol     IOCS_0_WORK_0
    clc
    adc     IOCS_0_RANDOM_L
    sta     IOCS_0_RANDOM_L
    lda     IOCS_0_WORK_0
    adc     IOCS_0_RANDOM_H
    sta     IOCS_0_RANDOM_H
    inc     IOCS_0_RANDOM_L
    bne     :+
    inc     IOCS_0_RANDOM_H
:
.else
    lda     IOCS_0_RANDOM_H
    asl     a
    asl     a
    clc
    adc     IOCS_0_RANDOM_H
    sta     IOCS_0_RANDOM_H
    inc     IOCS_0_RANDOM_H
.endif

    ; 乱数の取得
    lda     IOCS_0_RANDOM_H

    ; 終了
    rts

.endproc

; エラーに対してリトライ待ちをする
;
.global _IocsRetry
.proc   _IocsRetry

    ; IN
    ;   ax = エラーメッセージ

    ; MIX モードの設定
    sta     MIXSET

    ; メッセージの表示
    jsr     _IocsCoutString

    ; BEEP
    jsr     BELL

    ; キー入力待ち
:
    lda     KBD
    bpl     :-
    lda     KBDSTRB

    ; 改行
    jsr     CROUT1

    ; MIX モードの解除
    sta     MIXCLR

    ; 終了
    rts

.endproc

; アプリケーションをエラー終了する
;
.global _IocsError
.proc   _IocsError

    ; IN
    ;   ax = エラーメッセージ

    ; テキストの設定
    sta     TXTSET
    sta     LOWSCR

    ; メッセージの表示
    jsr     _IocsCoutString

    ; BEEP
    jsr     BELL

    ; DOS への復帰
    jmp     DOSWARM

.endproc

; フォント
;
font:

.incbin     "resources/fonts/font-8.ts"

; かな
;
kana:

.incbin     "resources/fonts/kana-8a.ts"
.incbin     "resources/fonts/kana-8b.ts"

; HiRes グラフィックス
;

; VRAM アドレス
hgr_tile_y_address_low:

    .byte   <$2000, <$2080, <$2100, <$2180, <$2200, <$2280, <$2300, <$2380
    .byte   <$2028, <$20a8, <$2128, <$21a8, <$2228, <$22a8, <$2328, <$23a8
    .byte   <$2050, <$20d0, <$2150, <$21d0, <$2250, <$22d0, <$2350, <$23d0

hgr_tile_y_address_high:

    .byte   >$2000, >$2080, >$2100, >$2180, >$2200, >$2280, >$2300, >$2380
    .byte   >$2028, >$20a8, >$2128, >$21a8, >$2228, >$22a8, >$2328, >$23a8
    .byte   >$2050, >$20d0, >$2150, >$21d0, >$2250, >$22d0, >$2350, >$23d0
