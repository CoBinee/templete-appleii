; app.inc - アプリケーション
; 


; ゼロページ
;
APP_0                       :=  $e0
APP_0_PROC                  :=  $e0
APP_0_PROC_L                :=  $e0
APP_0_PROC_H                :=  $e1
APP_0_STATE                 :=  $e2
APP_0_USER                  :=  $e3
APP_0_USER_END              :=  $fb
APP_0_WORK_0                :=  $fc
APP_0_WORK_1                :=  $fd
APP_0_WORK_2                :=  $fe
APP_0_WORK_3                :=  $ff

; ユーザ
;
APP_0_WASD                  :=  APP_0_USER + $00
APP_0_X                     :=  APP_0_USER + $01
APP_0_Y                     :=  APP_0_USER + $02
APP_0_DIRECTION             :=  APP_0_USER + $03
APP_0_ANIMATION             :=  APP_0_USER + $04
APP_0_WAIT_0                :=  APP_0_USER + $05
APP_0_WAIT_1                :=  APP_0_USER + $06
