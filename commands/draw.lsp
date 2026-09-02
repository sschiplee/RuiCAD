;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 命令模块
;;;  模块: 柜体框架与标准柜 (draw.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  对标: 光速 KJ/KG, 碧福 框架/一键库, 雷神 WG/DG/KJ, 沐辰 标准柜
;;;  命令: KJ 画框架 | DG 标准柜 | WG 吊柜 | HQ 画墙
;;; ============================================================

;;; ---------- KJ 画柜体框架 (双线结构) ----------
;;; rc:frame p1 左下角 p2 右上角 thk 板厚 -> 画外框+内框, 返回内框角点
(defun rc:frame (p1 p2 thk / px1 py1 px2 py2 i1 i2)
  (setq px1 (car p1) py1 (cadr p1))
  (setq px2 (car p2) py2 (cadr p2))
  ;; 外框
  (rc:rect p1 p2 "RC-柜体")
  ;; 内框: 向内缩 thk (保证最小边, 防止反向)
  (setq i1 (list (+ px1 thk) (+ py1 thk)))
  (setq i2 (list (- px2 thk) (- py2 thk)))
  (if (and (< (car i1) (car i2)) (< (cadr i1) (cadr i2)))
    (progn
      (rc:rect i1 i2 "RC-内部")
      (list i1 i2))
    (list p1 p2))
  )

(defun c:KJ ()
  (rc:env)
  (setq r (rc:get-rect "KJ 画柜体框架"))
  (if r
    (progn
      (setq thk (rc:getreal "板材厚度" *rc-thk*))
      (rc:frame (car r) (cadr r) thk)
      (princ "\n[KJ] 柜体框架已生成"))
    (princ "\n[KJ] 已取消"))
  (princ))

;;; ---------- DG 参数化标准柜 (一键库核心) ----------
;;; rc:unit-cab base 左下角 w 宽 h 高 thk 板厚 shelves 层板数
;;;         kick 踢脚高(0无) door 门板数(0无门) -> 生成柜体立面
(defun rc:unit-cab (base w h thk shelves kick door / p0 p1 cx
                     p2 p3 top bot span pts i x1 x2)
  (setq p0 base)                              ; 左下
  (setq p1 (list (+ (car p0) w) (cadr p0)))   ; 右下
  (setq p2 (list (car p1) (+ (cadr p1) h)))   ; 右上
  (setq p3 (list (car p0) (+ (cadr p0) h)))   ; 左上
  ;; 踢脚
  (if (> kick 0)
    (progn
      (rc:rect p0 (list (car p1) (+ (cadr p0) kick)) "RC-柜体")
      (setq p0 (list (car p0) (+ (cadr p0) kick)))))
  ;; 左右侧板(双线)
  (rc:rect (list (car p0) (cadr p0)) (list (+ (car p0) thk) (- (cadr p2) thk)) "RC-柜体")
  (rc:rect (list (- (car p2) thk) (cadr p0)) (list (car p2) (- (cadr p2) thk)) "RC-柜体")
  ;; 顶底板
  (rc:rect (list (+ (car p0) thk) (cadr p0)) (list (- (car p2) thk) (+ (cadr p0) thk)) "RC-柜体")
  (rc:rect (list (+ (car p0) thk) (- (cadr p2) thk)) (list (- (car p2) thk) (cadr p2)) "RC-柜体")
  ;; 层板等分 (在内部空间)
  (setq top (- (cadr p2) (* 2 thk)))
  (setq bot (+ (cadr p0) (* 2 thk)))
  (if (> shelves 0)
    (progn
      (setq span (- top bot))
      (setq i 1)
      (while (<= i shelves)
        (setq y (+ bot (/ (* span i) (1+ shelves))))
        (rc:line (list (+ (car p0) thk) y) (list (- (car p2) thk) y) "RC-内部")
        (setq i (1+ i)))))
  ;; 门板 (均分)
  (if (> door 0)
    (progn
      (setq cx (car p0))
      (setq span (/ w door))
      (setq i 1)
      (while (<= i door)
        (setq x2 (+ cx (* span i)))
        (rc:rect (list x2 (cadr p0))
                 (list (- x2 *rc-gap*) (- (cadr p2) *rc-top-gap*))
                 "RC-门板")
        (setq cx x2)
        (setq i (1+ i)))))
  t)

(defun c:DG ()
  (rc:env)
  (setq base (getpoint "\nDG 标准柜 - 指定左下角点: "))
  (if base
    (progn
      (setq w  (rc:getreal "柜体宽度" 1800))
      (setq h  (rc:getreal "柜体高度" 2400))
      (setq thk (rc:getreal "板材厚度" *rc-thk*))
      (setq sh (rc:getint "层板数量" *rc-shelf-num*))
      (setq kc (rc:getint "踢脚高度" *rc-plinth*))
      (setq dn (rc:getint "门板数量(0=无)" *rc-door-num*))
      (rc:unit-cab base w h thk sh kc dn)
      (princ "\n[DG] 标准柜已生成"))
    (princ "\n[DG] 已取消"))
  (princ))

;;; ---------- WG 吊柜 (悬空柜, 底部无踢脚) ----------
(defun c:WG ()
  (rc:env)
  (setq base (getpoint "\nWG 吊柜 - 指定左下角点: "))
  (if base
    (progn
      (setq w  (rc:getreal "吊柜宽度" 1200))
      (setq h  (rc:getreal "吊柜高度" 700))
      (setq thk (rc:getreal "板材厚度" *rc-thk*))
      (setq sh (rc:getint "层板数量" 1))
      (setq dn (rc:getint "门板数量(0=无)" *rc-door-num*))
      (rc:unit-cab base w h thk sh 0 dn)
      (princ "\n[WG] 吊柜已生成"))
    (princ "\n[WG] 已取消"))
  (princ))

;;; ---------- HQ 画墙 (双线墙) ----------
;;; rc:wall p1 p2 墙厚 thk -> 画双线墙
(defun rc:wall (p1 p2 thk / ang d p1a p1b p2a p2b)
  (setq ang (angle p1 p2))
  (setq d   (/ thk 2.0))
  (setq p1a (polar p1 (+ ang (* pi 0.5)) d))
  (setq p1b (polar p1 (- ang (* pi 0.5)) d))
  (setq p2a (polar p2 (+ ang (* pi 0.5)) d))
  (setq p2b (polar p2 (- ang (* pi 0.5)) d))
  (rc:line p1a p2a "RC-柜体")
  (rc:line p1b p2b "RC-柜体")
  (rc:line p1a p1b "RC-柜体")
  (rc:line p2a p2b "RC-柜体"))

(defun c:HQ ()
  (rc:env)
  (setq p1 (getpoint "\nHQ 画墙 - 指定起点: "))
  (if p1
    (progn
      (setq p2 (getpoint p1 "\n指定终点: "))
      (if p2
        (progn
          (setq thk (rc:getreal "墙厚" 120))
          (rc:wall p1 p2 thk)
          (princ "\n[HQ] 墙体已生成"))
        (princ "\n[HQ] 已取消")))
    (princ "\n[HQ] 已取消"))
  (princ))

(princ "\n[RuiCAD] 柜体框架模块已加载")
(princ)
