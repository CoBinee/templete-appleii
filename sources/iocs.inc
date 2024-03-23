; iocs.inc - Input/Output Control System
; 


; ゼロページ
;

; $00..$1f : IOCS で使用
; $e0..$ff : アプリケーションで使用

; IOCS
IOCS_0_STACK                        :=  $00
IOCS_0_STACK_L                      :=  $00
IOCS_0_STACK_H                      :=  $01
IOCS_0_ARG                          :=  $02
IOCS_0_ARG_L                        :=  $02
IOCS_0_ARG_H                        :=  $03
IOCS_0_DOS_PARAM                    :=  $04
IOCS_0_DOS_PARAM_L                  :=  $04
IOCS_0_DOS_PARAM_H                  :=  $05
IOCS_0_KEYCODE                      :=  $06
IOCS_0_RANDOM                       :=  $07
IOCS_0_RANDOM_L                     :=  $07
IOCS_0_RANDOM_H                     :=  $08
IOCS_0_09                           :=  $09
IOCS_0_0A                           :=  $0a
IOCS_0_0B                           :=  $0b

; WORK
IOCS_0_WORK_0                       :=  $0c
IOCS_0_WORK_1                       :=  $0d
IOCS_0_WORK_2                       :=  $0e
IOCS_0_WORK_3                       :=  $0f

; DOS
IOCS_0_DOS_BUFFER                   :=  $10
IOCS_0_DOS_BUFFER_L                 :=  $10
IOCS_0_DOS_BUFFER_H                 :=  $11
IOCS_0_DOS_FILENAME                 :=  $12
IOCS_0_DOS_FILENAME_L               :=  $12
IOCS_0_DOS_FILENAME_H               :=  $13
IOCS_0_DOS_HEADER                   :=  $14
IOCS_0_DOS_ADDRESS                  :=  $14
IOCS_0_DOS_ADDRESS_L                :=  $14
IOCS_0_DOS_ADDRESS_H                :=  $15
IOCS_0_DOS_LENGTH                   :=  $16
IOCS_0_DOS_LENGTH_L                 :=  $16
IOCS_0_DOS_LENGTH_H                 :=  $17
IOCS_0_DOS_FILETYPE                 :=  $18
IOCS_0_DOS_FLAG                     :=  $19

; HGR - 7x8
IOCS_0_HGR_SRC                      :=  $10
IOCS_0_HGR_SRC_L                    :=  $10
IOCS_0_HGR_SRC_H                    :=  $11
IOCS_0_HGR_DST                      :=  $12
IOCS_0_HGR_DST_L                    :=  $12
IOCS_0_HGR_DST_H                    :=  $13
IOCS_0_HGR_MASK                     :=  $14
IOCS_0_HGR_MASK_L                   :=  $14
IOCS_0_HGR_MASK_H                   :=  $15
IOCS_0_HGR_BASE                     :=  $16
IOCS_0_HGR_BASE_L                   :=  $16
IOCS_0_HGR_BASE_H                   :=  $17

; HGR - String
IOCS_0_HGR_STRING                   :=  $14
IOCS_0_HGR_STRING_L                 :=  $14
IOCS_0_HGR_STRING_H                 :=  $15
IOCS_0_HGR_STRING_INDEX             :=  $16
IOCS_0_HGR_STRING_VRAM_X            :=  $17
IOCS_0_HGR_STRING_VRAM_Y            :=  $18

; HGR - Tileset
IOCS_0_HGR_TILESET                  :=  $18
IOCS_0_HGR_TILESET_L                :=  $18
IOCS_0_HGR_TILESET_H                :=  $19
IOCS_0_HGR_TILESET_X                :=  $1a
IOCS_0_HGR_TILESET_Y                :=  $1b
IOCS_0_HGR_TILESET_VRAM_X           :=  $1c
IOCS_0_HGR_TILESET_VRAM_Y           :=  $1d


; HGR - Tilemap
IOCS_0_HGR_TILEMAP                  :=  $14
IOCS_0_HGR_TILEMAP_L                :=  $14
IOCS_0_HGR_TILEMAP_H                :=  $15
IOCS_0_HGR_TILEMAP_WIDTH            :=  $16
IOCS_0_HGR_TILEMAP_NEXTLINE         :=  $17
IOCS_0_HGR_TILEMAP_X                :=  $18
IOCS_0_HGR_TILEMAP_Y                :=  $19
IOCS_0_HGR_TILEMAP_TILESET          :=  $1a
IOCS_0_HGR_TILEMAP_TILESET_L        :=  $1a
IOCS_0_HGR_TILEMAP_TILESET_H        :=  $1b
IOCS_0_HGR_TILEMAP_VRAM_X           :=  $1c
IOCS_0_HGR_TILEMAP_VRAM_Y           :=  $1d

; HGR - Sprite
IOCS_0_HGR_SPRITE_TILEMAP           :=  $18
IOCS_0_HGR_SPRITE_TILEMAP_L         :=  $18
IOCS_0_HGR_SPRITE_TILEMAP_H         :=  $19
IOCS_0_HGR_SPRITE_TILEMAP_WIDTH     :=  $1a
IOCS_0_HGR_SPRITE_TILEMAP_NEXTLINE  :=  $1b
IOCS_0_HGR_SPRITE_TILEMAP_X         :=  $1c
IOCS_0_HGR_SPRITE_TILEMAP_Y         :=  $1d
IOCS_0_HGR_SPRITE_VRAM_X            :=  $1e
IOCS_0_HGR_SPRITE_VRAM_Y            :=  $1f


; カナ
;
_SP     =   $60     ; 
_PR     =   $61     ; 。
_OB     =   $62     ; 「
_CB     =   $63     ; 」
_CM     =   $64     ; 、
_BP     =   $65     ; ・
_WO     =   $66     ; ヲ
__a     =   $67     ; ァ
__i     =   $68     ; ィ
__u     =   $69     ; ゥ
__e     =   $6a     ; ェ
__o     =   $6b     ; ォ
_ya     =   $6c     ; ャ
_yu     =   $6d     ; ュ
_yo     =   $6e     ; ョ
_tu     =   $6f     ; ッ
_HF     =   $70     ; ー
__A     =   $71     ; ア
__I     =   $72     ; イ
__U     =   $73     ; ウ
__E     =   $74     ; エ
__O     =   $75     ; オ
_KA     =   $76     ; カ
_KI     =   $77     ; キ
_KU     =   $78     ; ク
_KE     =   $79     ; ケ
_KO     =   $7a     ; コ
_SA     =   $7b     ; サ
_SI     =   $7c     ; シ
_SU     =   $7d     ; ス
_SE     =   $7e     ; セ
_SO     =   $7f     ; ソ
_TA     =   $80     ; タ
_TI     =   $81     ; チ
_TU     =   $82     ; ツ
_TE     =   $83     ; テ
_TO     =   $84     ; ト
_NA     =   $85     ; ナ
_NI     =   $86     ; ニ
_NU     =   $87     ; ヌ
_NE     =   $88     ; ネ
_NO     =   $89     ; ノ
_HA     =   $8a     ; ハ
_HI     =   $8b     ; ヒ
_HU     =   $8c     ; フ
_HE     =   $8d     ; ヘ
_HO     =   $8e     ; ホ
_MA     =   $8f     ; マ
_MI     =   $90     ; ミ
_MU     =   $91     ; ム
_ME     =   $92     ; メ
_MO     =   $93     ; モ
_YA     =   $94     ; ヤ
_YU     =   $95     ; ユ
_YO     =   $96     ; ヨ
_RA     =   $97     ; ラ
_RI     =   $98     ; リ
_RU     =   $99     ; ル
_RE     =   $9a     ; レ
_RO     =   $9b     ; ロ
_WA     =   $9c     ; ワ
__N     =   $9d     ; ン
_VM     =   $9e     ; ゛
_PM     =   $9f     ; ゜
_GA     =   $a0     ; ガ
_GI     =   $a1     ; ギ
_GU     =   $a2     ; グ
_GE     =   $a3     ; ゲ
_GO     =   $a4     ; ゴ
_ZA     =   $a5     ; ザ
_ZI     =   $a6     ; ジ
_ZU     =   $a7     ; ズ
_ZE     =   $a8     ; ゼ
_ZO     =   $a9     ; ゾ
_DA     =   $aa     ; ダ
_DI     =   $ab     ; ヂ
_DU     =   $ac     ; ヅ
_DE     =   $ad     ; デ
_DO     =   $ae     ; ド
_BA     =   $af     ; バ
_BI     =   $b0     ; ビ
_BU     =   $b1     ; ブ
_BE     =   $b2     ; ベ
_BO     =   $b3     ; ボ
_PA     =   $b4     ; パ
_PI     =   $b5     ; ピ
_PU     =   $b6     ; プ
_PE     =   $b7     ; ペ
_PO     =   $b8     ; ポ
