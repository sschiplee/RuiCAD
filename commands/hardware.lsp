;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 命令模块
;;;  模块: 五金与孔位 (hardware.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  命令: JL铰链(按门高自动定数) LS拉手 SYH三合一32mm系统排孔
;;; ============================================================

;;; ---------- 按门高决定铰链数量(行业经验) ----------
(defun rc:hinge-count (h)
  (cond ((< h 600) 2)
        ((< h 1200) 3)
        ((< h 1800) 4)
        (t 5)))

;;; ---------- JL 铰链: 在门板一侧竖边上自动布置铰杯 ----------
(defun rc:hinges (p1 p2 side edge / x h n i y yb yt)
  (setq h (- (cadr p2) (cadr p1)))
  (setq n (rc:hinge-count h))
  (setq x (if (= side 0) (+ (car p1) edge) (- (car p2) edge)))
  (setq yb (+ (cadr p1) edge) yt (- (cadr p2) edge))
  (setq i 0)
  (while (< i n)
    (setq y (if (= n 1)
              (/ (+ (cadr p1) (cadr p2)) 2.0)
              (+ yb (/ (* (- yt yb) i) (1- n)))))
    (rc:circle (list x y) (/ *rc-hinge-cup* 2.0) "RC-五金")
    (if (= side 0)
      (rc:line (list (+ x (/ *rc-hinge-cup* 2.0)) y) (list (+ x (/ *rc-hinge-cup* 2.0) 24) y) "RC-五金")
      (rc:line (list (- x (/ *rc-hinge-cup* 2.0)) y) (list (- x (/ *rc-hinge-cup* 2.0) 24) y) "RC-五金"))
    (setq i (1+ i))))

(defun c:JL ()
  (rc:env)
  (setq r (rc:region "JL 铰链(框选门板)"))
  (if r
    (progn
      (setq side (rc:getint "铰链装在哪侧(0左 1右)" 1))
      (setq edge (rc:getreal "铰杯距门边" *rc-hinge-edge*))
      (rc:hinges (car r) (cadr r) side edge)
      (princ "\n[JL] 铰链已按门高自动布置"))
    (princ "\n[JL] 已取消"))
  (princ))

;;; ---------- LS 拉手: 门板横装条形拉手(双支脚) ----------
(defun rc:handle (p1 p2 hpos len / cx cy dx)
  (setq cx (/ (+ (car p1) (car p2)) 2.0))
  (setq cy (+ (cadr p1) (* (- (cadr p2) (cadr p1)) hpos)))
  (setq dx (/ len 2.0))
  (rc:line (list (- cx dx) cy) (list (+ cx dx) cy) "RC-五金")
  (rc:line (list (- cx dx) cy) (list (- cx dx) (+ cy 12)) "RC-五金")
  (rc:line (list (+ cx dx) cy) (list (+ cx dx) (+ cy 12)) "RC-五金"))

(defun c:LS ()
  (rc:env)
  (setq r (rc:region "LS 拉手(框选门板)"))
  (if r
    (progn
      (setq hp (rc:getreal "拉手竖向位置(0底边~1顶边)" 0.35))
      (setq len (rc:getreal "拉手长度" *rc-handle-len*))
      (rc:handle (car r) (cadr r) hp len)
      (princ "\n[LS] 拉手已生成"))
    (princ "\n[LS] 已取消"))
  (princ))

;;; ---------- SYH 三合一排孔(32mm 系统): 板边一列系统孔 ----------
(defun rc:cam-bolts (p1 p2 side pitch d / x y y0 y1 inset)
  (setq y0 (cadr p1) y1 (cadr p2))
  (setq inset 37)
  (setq x (if (= side 0) (+ (car p1) inset) (- (car p2) inset)))
  (setq y (+ y0 pitch))
  (while (< y y1)
    (rc:circle (list x y) (/ d 2.0) "RC-五金")
    (setq y (+ y pitch))))

(defun c:SYH ()
  (rc:env)
  (setq r (rc:region "SYH 三合一排孔(框选板件)"))
  (if r
    (progn
      (setq side (rc:getint "排孔在哪侧(0左 1右)" 0))
      (setq pitch (rc:getreal "孔距(32系统)" *rc-cam-pitch*))
      (rc:cam-bolts (car r) (cadr r) side pitch *rc-cam-d*)
      (princ "\n[SYH] 三合一系统孔已排布"))
    (princ "\n[SYH] 已取消"))
  (princ))

(princ "\n[RuiCAD] 五金与孔位模块已加载")
(princ)
