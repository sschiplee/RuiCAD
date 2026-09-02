;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 命令模块
;;;  模块: 标注统计与通用工具 (dim.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  命令: BZ一键标注 NBZ内部标注 DBZ逐段连续标注 BM门板标注
;;;        MJ面积 WJ部件清单 BOM拆单(CSV) BOM2详细统计(CSV) BH板件编号
;;;        PRIM批量图片 TK图框编号 TS文字刷 KB图库
;;; ============================================================
(vl-load-com)

;;; ---------- BZ 一键标注 ----------
(defun rc:dimrect (p1 p2 / x1 y1 x2 y2 off)
  (rc:golayer "RC-标注" 2)
  (setq x1 (car p1) y1 (cadr p1))
  (setq x2 (car p2) y2 (cadr p2))
  (setq off *rc-dim-off*)
  (command "_.dimlinear" "_non" (list x1 y1) "_non" (list x2 y1)
           "_non" (list (/ (+ x1 x2) 2.0) (- y1 off)))
  (command "_.dimlinear" "_non" (list x1 y1) "_non" (list x1 y2)
           "_non" (list (- x1 off) (/ (+ y1 y2) 2.0)))
  (rc:golayer "RC-柜体" 7)
  t)

(defun c:BZ ()
  (rc:env)
  (setq r (rc:region "BZ 一键标注"))
  (if r
    (progn (rc:dimrect (car r) (cadr r)) (princ "\n[BZ] 标注已生成"))
    (princ "\n[BZ] 已取消"))
  (princ))

;;; ---------- NBZ 内部标注 ----------
(defun rc:diminner (p1 p2 n / x1 x2 span i x)
  (rc:golayer "RC-标注" 2)
  (setq x1 (car p1) x2 (car p2))
  (setq span (- x2 x1))
  (setq i 1)
  (while (< i n)
    (setq x (+ x1 (/ (* span i) n)))
    (command "_.dimlinear" "_non" (list x1 (cadr p1)) "_non" (list x (cadr p1))
             "_non" (list (/ (+ x1 x) 2.0) (- (cadr p1) *rc-dim-off*)))
    (setq i (1+ i)))
  (rc:golayer "RC-柜体" 7)
  t)

(defun c:NBZ ()
  (rc:env)
  (setq r (rc:region "NBZ 内部标注"))
  (if r
    (progn
      (setq n (rc:getint "分段数量" 4))
      (rc:diminner (car r) (cadr r) n)
      (princ "\n[NBZ] 内部标注已生成"))
    (princ "\n[NBZ] 已取消"))
  (princ))

;;; ---------- DBZ 逐段连续标注 ----------
(defun rc:dimchain (p1 p2 off / xL xR yb yT en ed a b xs sorted prevn curn k)
  (rc:golayer "RC-标注" 2)
  (setq xL (car p1) xR (car p2) yb (cadr p1) yT (cadr p2))
  (setq xs (list xL xR))
  (foreach en (rc:lines-in-box xL yb xR yT nil)
    (setq ed (entget en) a (cdr (assoc 10 ed)) b (cdr (assoc 11 ed)))
    (if (equal (car a) (car b) 0.01) (setq xs (cons (car a) xs))))
  (setq sorted (vl-sort xs '(lambda (u v) (< u v))))
  (setq xs nil)
  (foreach x sorted
    (if (or (null xs) (> (abs (- x (car xs))) 1)) (setq xs (cons x xs))))
  (setq sorted (reverse xs))
  (setq k 0)
  (while (< k (1- (length sorted)))
    (setq prevn (nth k sorted) curn (nth (1+ k) sorted))
    (command "_.dimlinear" "_non" (list prevn yb) "_non" (list curn yb)
             "_non" (list (/ (+ prevn curn) 2.0) (- yb off)))
    (setq k (1+ k)))
  (rc:golayer "RC-柜体" 7)
  t)

(defun c:DBZ ()
  (rc:env)
  (setq r (rc:region "DBZ 逐段连续标注"))
  (if r
    (progn (rc:dimchain (car r) (cadr r) *rc-dim-off*)
           (princ "\n[DBZ] 已自动识别并逐段连续标注"))
    (princ "\n[DBZ] 已取消"))
  (princ))

;;; ---------- BM 门板标注 ----------
(defun rc:dim-doors (p1 p2 n gap / w i xa xb y)
  (rc:golayer "RC-标注" 2)
  (setq w (/ (- (car p2) (car p1)) n) i 0
        y (- (cadr p2) *rc-dim-off*))
  (while (< i n)
    (setq xa (+ (car p1) (* i w)) xb (+ xa w))
    (command "_.dimlinear" "_non" (list xa (cadr p1)) "_non" (list (- xb gap) (cadr p1))
             "_non" (list (/ (+ xa xb) 2.0) y))
    (setq i (1+ i)))
  (rc:golayer "RC-柜体" 7)
  t)

(defun c:BM ()
  (rc:env)
  (setq r (rc:region "BM 门板标注"))
  (if r
    (progn
      (setq n (rc:getint "门板数量" *rc-door-num*))
      (rc:dim-doors (car r) (cadr r) n *rc-gap*)
      (princ "\n[BM] 门板逐扇标注已生成"))
    (princ "\n[BM] 已取消"))
  (princ))

;;; ---------- MJ 面积统计 ----------
(defun rc:area (p1 p2 / a)
  (command "_.area"
           "_non" p1
           "_non" (list (car p2) (cadr p1))
           "_non" p2
           "_non" (list (car p1) (cadr p2))
           "")
  (setq a (getvar "AREA"))
  (princ (strcat "\n[面积] " (rtos a 2 2) " 平方毫米 = "
                 (rtos (/ a 1000000.0) 2 4) " 平方米"))
  a)

(defun c:MJ ()
  (rc:env)
  (setq r (rc:region "MJ 面积计算"))
  (if r
    (rc:area (car r) (cadr r))
    (princ "\n[MJ] 已取消"))
  (princ))

;;; ---------- 图层统计辅助 ----------
(defun rc:count-layer (lay / ss)
  (if (setq ss (ssget "_X" (list (cons 8 lay))))
    (sslength ss)
    0))

;;; ---------- WJ 部件清单 ----------
(defun c:WJ ()
  (rc:env)
  (princ "\n[WJ] 全图部件清单统计:")
  (foreach item *rc-layers*
    (princ (strcat "\n  图层 " (car item) " : "
                   (itoa (rc:count-layer (car item))) " 个图元")))
  (princ "\n[WJ] 统计完成")
  (princ))

;;; ---------- BOM 拆单统计 CSV ----------
(defun rc:bom (path / f rows lay n)
  (setq rows nil)
  (foreach item *rc-layers*
    (setq lay (car item))
    (setq n (rc:count-layer lay))
    (if (> n 0) (setq rows (cons (list lay n) rows))))
  (if (setq f (open path "w"))
    (progn
      (write-line "部件类型,图元数量" f)
      (foreach r (reverse rows)
        (write-line (strcat (car r) "," (itoa (cadr r))) f))
      (close f)
      (strcat "\n[BOM] 已输出: " path))
    "\n[BOM] 输出失败"))

(defun c:BOM ()
  (rc:env)
  (setq fname (getfiled "BOM 导出 CSV" "RuiCAD_BOM" "csv" 1))
  (if fname (princ (rc:bom fname)) (princ "\n[BOM] 已取消"))
  (princ))

;;; ---------- BOM2 详细统计 CSV ----------
(defun rc:layer-len (lay / ss i ed tot a b)
  (setq tot 0.0)
  (if (setq ss (ssget "_X" (list (cons 8 lay) (cons 0 "LINE"))))
    (progn (setq i 0)
      (while (< i (sslength ss))
        (setq ed (entget (ssname ss i)))
        (setq a (cdr (assoc 10 ed)) b (cdr (assoc 11 ed)))
        (setq tot (+ tot (rc:dist a b)))
        (setq i (1+ i)))))
  tot)

(defun rc:bom2 (path / f item lay nl nc np ll ss)
  (if (setq f (open path "w"))
    (progn
      (write-line "图层,线段数,线段总长mm,圆数量,多段线数" f)
      (foreach item *rc-layers*
        (setq lay (car item))
        (setq nl (if (setq ss (ssget "_X" (list (cons 8 lay)(cons 0 "LINE")))) (sslength ss) 0))
        (setq nc (if (setq ss (ssget "_X" (list (cons 8 lay)(cons 0 "CIRCLE")))) (sslength ss) 0))
        (setq np (if (setq ss (ssget "_X" (list (cons 8 lay)(cons 0 "LWPOLYLINE")))) (sslength ss) 0))
        (setq ll (rc:layer-len lay))
        (if (> (+ nl nc np) 0)
          (write-line (strcat lay "," (itoa nl) "," (rtos ll 2 0) ","
                                   (itoa nc) "," (itoa np)) f)))
      (close f)
      (strcat "\n[BOM2] 详细统计已输出: " path))
    "\n[BOM2] 输出失败"))

(defun c:BOM2 ()
  (rc:env)
  (setq fname (getfiled "BOM2 详细统计 CSV" "RuiCAD_BOM2" "csv" 1))
  (if fname (princ (rc:bom2 fname)) (princ "\n[BOM2] 已取消"))
  (princ))

;;; ---------- BH 板件编号 ----------
(defun rc:num-parts (ss / i en ed p n h)
  (rc:golayer "RC-文字" 7)
  (setq i 0 n 1 h *rc-dim-txt*)
  (while (< i (sslength ss))
    (setq en (ssname ss i) ed (entget en) p (cdr (assoc 10 ed)))
    (if p
      (progn
        (rc:circle p (* h 0.9) "RC-文字")
        (rc:text (list (- (car p) (* h 0.32)) (- (cadr p) (* h 0.34)))
                 (itoa n) (* h 0.68) "RC-文字")
        (setq n (1+ n))))
    (setq i (1+ i)))
  (rc:golayer "RC-柜体" 7)
  (1- n))

(defun c:BH ()
  (rc:env)
  (princ "\nBH 板件编号 - 选择要编号的板件/图元: ")
  (setq ss (ssget))
  (if ss
    (progn
      (setq cnt (rc:num-parts ss))
      (princ (strcat "\n[BH] 已编号 " (itoa cnt) " 个板件")))
    (princ "\n[BH] 已取消"))
  (princ))

;;; ---------- PRIM 批量导入图片 ----------
(defun rc:image (file pt w)
  (if (findfile file)
    (progn (command "_.imageattach" "_non" file "_non" pt "_non" w "") t)
    nil))

(defun c:PRIM ()
  (rc:env)
  (princ "\nPRIM 批量导入图片(逐张):")
  (setq more "Y")
  (while (= more "Y")
    (setq fn (getfiled "选择图片" "" "jpg;png;bmp;tif" 4))
    (if fn
      (progn
        (setq pt (getpoint "\n指定插入点: "))
        (if pt (progn (setq w (rc:getreal "显示宽度" 600)) (rc:image fn pt w)
                      (princ "\n已插入一张图片"))))
      (setq more "N"))
    (if (and (= more "Y") fn)
      (progn (initget "Y N")
        (setq more (getkword "\n继续插入下一张? [Y/N] <Y>: "))
        (if (null more) (setq more "Y"))))
    (if (null fn) (setq more "N")))
  (princ "\n[PRIM] 图片导入完成")
  (princ))

;;; ---------- TK 图框编号 ----------
(defun rc:num (start pt step count / i v p)
  (setq i 0)
  (while (< i count)
    (setq v (+ start i))
    (setq p (list (car pt) (- (cadr pt) (* i step))))
    (rc:text p (strcat "图号-"
                       (if (< v 10) (strcat "0" (itoa v)) (itoa v)))
             80 "RC-文字")
    (setq i (1+ i))))

(defun c:TK ()
  (rc:env)
  (setq pt (getpoint "\nTK 图框编号 - 指定起始位置: "))
  (if pt
    (progn
      (setq st (rc:getint "起始编号" 1))
      (setq cnt (rc:getint "数量" 5))
      (rc:num st pt 100 cnt)
      (princ "\n[TK] 编号已生成"))
    (princ "\n[TK] 已取消"))
  (princ))

;;; ---------- TS 文字刷子 ----------
(defun rc:textmatch (src dst / ed st)
  (setq ed (entget src))
  (setq st (cdr (assoc 1 ed)))
  (entmod (subst (cons 1 st) (assoc 1 (entget dst)) (entget dst)))
  (entupd dst))

(defun c:TS ()
  (rc:env)
  (setq src (car (entsel "\nTS 文字刷 - 选择源文字: ")))
  (if src
    (progn
      (princ "\n选择要修改的文字(可多选): ")
      (setq ss (ssget (list (cons 0 "TEXT"))))
      (if ss
        (progn (setq i 0)
          (while (< i (sslength ss))
            (rc:textmatch src (ssname ss i))
            (setq i (1+ i)))
          (princ "\n[TS] 文字已批量修改"))
        (princ "\n[TS] 未选择目标")))
    (princ "\n[TS] 已取消"))
  (princ))

;;; ---------- KB 图库 (存块/插块) ----------
(defun rc:make-block (name ss base)
  (command "_.-block" name base ss "")
  (if (tblsearch "BLOCK" name)
    (progn (command "_.-insert" name "_non" base 1 1 0) t)
    nil))

(defun c:KB ()
  (rc:env)
  (princ "\nKB 图库 - 请选择要存入图库的对象: ")
  (setq ss (ssget))
  (if ss
    (progn
      (setq name (getstring "\n图块名称: "))
      (if (and name (/= name ""))
        (progn
          (setq base (getpoint "\n指定基点: "))
          (if base
            (progn (rc:make-block name ss base)
                   (princ (strcat "\n[KB] 图块已建立并可插入")))
            (princ "\n[KB] 已取消")))
        (princ "\n[KB] 名称无效")))
    (princ "\n[KB] 已取消"))
  (princ))

(princ "\n[RuiCAD] 标注统计与通用工具模块已加载")
(princ)
