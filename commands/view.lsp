;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 命令模块
;;;  模块: 视图生成 (view.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  命令: TZ 假三维轴测 | FM 俯视投影 | PQ 剖切平侧面 | FD 大样放大
;;; ============================================================

;;; ---------- TZ 假三维轴测图 ----------
(defun rc:axono (p1 p2 depth dir / dx dy o1 o2 o3 o4 x1 y1 x2 y2)
  (setq x1 (car p1) y1 (cadr p1))
  (setq x2 (car p2) y2 (cadr p2))
  (if (= dir 0)
    (setq dx (- depth) dy (- depth))
    (setq dx depth   dy (- depth)))
  (rc:rect p1 p2 "RC-柜体")
  (setq o1 (list (+ x1 dx) (+ y1 dy)))
  (setq o2 (list (+ x2 dx) (+ y1 dy)))
  (setq o3 (list (+ x2 dx) (+ y2 dy)))
  (setq o4 (list (+ x1 dx) (+ y2 dy)))
  (rc:rect o1 o3 "RC-内部")
  (rc:line (list x1 y2) (list x2 y2) "RC-内部")
  (rc:line o4 o3 "RC-内部")
  (rc:line (list x1 y2) o4 "RC-内部")
  (rc:line (list x2 y2) o3 "RC-内部")
  (rc:line (list x2 y1) (list x2 y2) "RC-内部")
  (rc:line o2 o3 "RC-内部")
  (rc:line (list x2 y1) o2 "RC-内部")
  (rc:line (list x2 y2) o3 "RC-内部"))

(defun c:TZ ()
  (rc:env)
  (setq r (rc:region "TZ 假三维轴测"))
  (if r
    (progn
      (setq d (rc:getreal "挤出深度" *rc-depth*))
      (setq dir (rc:getint "方向(0右上 1右下)" 0))
      (rc:axono (car r) (cadr r) d dir)
      (princ "\n[TZ] 假三维已生成"))
    (princ "\n[TZ] 已取消"))
  (princ))

;;; ---------- FM 俯视投影 ----------
(defun rc:plan (p1 p2 depth thk / x1 y1 x2 y2 w en ed a b)
  (setq x1 (car p1) y1 (cadr p1))
  (setq x2 (car p2) y2 (cadr p2))
  (setq w (- x2 x1))
  (rc:rect (list x1 (- y1 depth)) (list x2 y1) "RC-柜体")
  (foreach en (rc:lines-in-box (+ x1 thk) (+ y1 thk) (- x2 thk) (- y2 thk) nil)
    (setq ed (entget en) a (cdr (assoc 10 ed)) b (cdr (assoc 11 ed)))
    (if (and (equal (car a) (car b) 0.01)
             (> (abs (- (cadr a) (cadr b))) thk))
      (rc:line (list (car a) (- y1 depth)) (list (car a) y1) "RC-内部")))
  t)

(defun c:FM ()
  (rc:env)
  (setq r (rc:region "FM 俯视投影"))
  (if r
    (progn
      (setq d (rc:getreal "柜体深度" *rc-depth*))
      (setq thk (rc:getreal "板厚" *rc-thk*))
      (rc:plan (car r) (cadr r) d thk)
      (princ "\n[FM] 俯视图已生成"))
    (princ "\n[FM] 已取消"))
  (princ))

;;; ---------- PQ 剖切符号 ----------
(defun rc:section (p1 p2 type / m)
  (setq m (rc:mid p1 p2))
  (if (= type 0)
    (progn
      (rc:line (list (car p1) (cadr m)) (list (car p2) (cadr m)) "RC-辅助")
      (rc:text (list (car p1) (+ (cadr m) 30)) "A" 30 "RC-文字")
      (rc:text (list (car p2) (+ (cadr m) 30)) "A" 30 "RC-文字"))
    (progn
      (rc:line (list (car m) (cadr p1)) (list (car m) (cadr p2)) "RC-辅助")
      (rc:text (list (+ (car m) 30) (cadr p1)) "A" 30 "RC-文字")
      (rc:text (list (+ (car m) 30) (cadr p2)) "A" 30 "RC-文字"))))

(defun c:PQ ()
  (rc:env)
  (setq r (rc:region "PQ 剖切符号"))
  (if r
    (progn
      (setq ty (rc:getint "剖切方向(0纵向 1横向)" 0))
      (rc:section (car r) (cadr r) ty)
      (princ "\n[PQ] 剖切符号已生成"))
    (princ "\n[PQ] 已取消"))
  (princ))

;;; ---------- FD 大样图局部放大 ----------
(defun rc:detail (ss base scale pt / ns)
  (command "_.copy" ss "" "_non" base "_non" pt "")
  (setq ns (ssget "_P"))
  (if ns (command "_.scale" ns "" "_non" pt scale))
  t)

(defun c:FD ()
  (rc:env)
  (princ "\nFD 大样放大 - 请选择要放大的对象: ")
  (setq ss (ssget))
  (if ss
    (progn
      (setq base (getpoint "\n指定放大基点: "))
      (if base
        (progn
          (setq s (rc:getreal "放大倍数" 3))
          (setq pt (getpoint base "\n指定放置位置: "))
          (if pt
            (progn
              (rc:detail ss base s pt)
              (princ "\n[FD] 大样图已生成"))
            (princ "\n[FD] 已取消")))
        (princ "\n[FD] 已取消")))
    (princ "\n[FD] 已取消"))
  (princ))

(princ "\n[RuiCAD] 视图生成模块已加载")
(princ)
