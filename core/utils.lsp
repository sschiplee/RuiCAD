;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 核心框架
;;;  模块: 通用工具函数 (utils.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  说明: 图层管理 / 图元创建 / 几何计算 等基础能力。
;;;        所有绘图命令均依赖本模块, 请先加载。
;;; ============================================================

;;; ---------- 图层管理 ----------
;;; rc:layer 确保图层存在(不存在则创建), 返回图层名
(defun rc:layer (name color)
  (if (not (tblsearch "LAYER" name))
    (entmake (list (cons 0 "LAYER")
                   (cons 100 "AcDbSymbolTableRecord")
                   (cons 100 "AcDbLayerTableRecord")
                   (cons 2 name)
                   (cons 70 0)
                   (cons 62 color)
                   (cons 6 "Continuous"))))
  name)

;;; rc:golayer 切换到指定图层(自动创建)
(defun rc:golayer (name color)
  (rc:layer name color)
  (setvar "CLAYER" name)
  name)

;;; 按 settings 初始化全部图层
(defun rc:init-layers ()
  (foreach item *rc-layers*
    (rc:layer (car item) (cadr item))))

;;; ---------- 标注样式初始化 (按毫米图纸放大, 保证清晰) ----------
(defun rc:dimsetup ()
  (setvar "DIMSCALE" 1)
  (setvar "DIMTXT"  *rc-dim-txt*)   ; 文字高度
  (setvar "DIMASZ"  *rc-dim-asz*)   ; 箭头大小
  (setvar "DIMEXE"  *rc-dim-exe*)   ; 界线超出
  (setvar "DIMEXO"  *rc-dim-exo*)   ; 界线偏移
  (setvar "DIMGAP"  *rc-dim-gap*)
  (setvar "DIMTAD"  1)              ; 文字在尺寸线上方
  (setvar "DIMTIH"  0)              ; 文字随尺寸线方向
  (setvar "DIMTOH"  0)
  (setvar "DIMDEC"  0)              ; 整数毫米, 无小数
  (setvar "DIMLUNIT" 2)             ; 小数格式
  (setvar "DIMZIN"  8)              ; 消去尾零
  (setvar "DIMCLRD" 2)              ; 尺寸线 黄
  (setvar "DIMCLRE" 2)              ; 界线 黄
  (setvar "DIMCLRT" 2)              ; 文字 黄
  (setvar "DIMTXSTY" "Standard")
  t)

;;; ---------- 图元创建 ----------
;;; rc:line 画一条直线到指定图层
(defun rc:line (p1 p2 layer)
  (entmake (list (cons 0 "LINE")
                 (cons 100 "AcDbEntity")
                 (cons 8 layer)
                 (cons 100 "AcDbLine")
                 (cons 10 p1)
                 (cons 11 p2))))

;;; rc:rect 画矩形(四点闭合), 返回矩形外框点列表
(defun rc:rect (p1 p2 layer)
  (rc:line p1 (list (car p2) (cadr p1)) layer)
  (rc:line (list (car p2) (cadr p1)) p2 layer)
  (rc:line p2 (list (car p1) (cadr p2)) layer)
  (rc:line (list (car p1) (cadr p2)) p1 layer)
  (list p1 (list (car p2) (cadr p1)) p2 (list (car p1) (cadr p2))))

;;; rc:circle 画圆
(defun rc:circle (cen rad layer)
  (entmake (list (cons 0 "CIRCLE")
                 (cons 100 "AcDbEntity")
                 (cons 8 layer)
                 (cons 100 "AcDbCircle")
                 (cons 10 cen)
                 (cons 40 rad))))

;;; rc:text 写单行文字 (点, 内容, 字高, 图层)
(defun rc:text (pt str h layer)
  (entmake (list (cons 0 "TEXT")
                 (cons 100 "AcDbEntity")
                 (cons 8 layer)
                 (cons 100 "AcDbText")
                 (cons 10 pt)
                 (cons 40 h)
                 (cons 1 str)
                 (cons 7 "Standard"))))

;;; ---------- 几何计算 ----------
;;; rc:dist 两点距离
(defun rc:dist (p1 p2)
  (sqrt (+ (expt (- (car p2) (car p1)) 2)
           (expt (- (cadr p2) (cadr p1)) 2))))

;;; rc:mid 两点中点
(defun rc:mid (p1 p2)
  (list (/ (+ (car p1) (car p2)) 2.0)
        (/ (+ (cadr p1) (cadr p2)) 2.0)))

;;; rc:div-pts 返回线段 p1->p2 按 n 等分后的 n-1 个内分点
(defun rc:div-pts (p1 p2 n / dx dy i lst)
  (setq dx (/ (- (car p2) (car p1)) n))
  (setq dy (/ (- (cadr p2) (cadr p1)) n))
  (setq i 1 lst nil)
  (while (< i n)
    (setq lst (cons (list (+ (car p1) (* dx i)) (+ (cadr p1) (* dy i))) lst))
    (setq i (1+ i)))
  (reverse lst))

;;; rc:offset-pt 点沿向量方向偏移距离
(defun rc:offset-pt (p v d)
  (list (+ (car p) (* (car v) d))
        (+ (cadr p) (* (cadr v) d))))

;;; rc:get-rect 交互获取矩形两点并返回 '(p1 p2) (带取消保护)
(defun rc:get-rect (msg / p1 p2)
  (setq p1 (getpoint (strcat "\n" msg " - 指定第一角点: ")))
  (if p1
    (progn
      (setq p2 (getcorner p1 (strcat "\n" msg " - 指定对角点: ")))
      (if p2 (list p1 p2) nil)))
  )

;;; rc:region 为 rc:get-rect 的兼容别名(部分模块使用此命名)
(defun rc:region (msg) (rc:get-rect msg))

;;; ---------- 数值输入辅助 ----------
;;; rc:getint 带默认值的整数输入
(defun rc:getint (msg def / v)
  (initget 6)  ; 禁止0和负数
  (setq v (getint (strcat "\n" msg " <" (itoa def) ">: ")))
  (if v v def))

;;; rc:getreal 带默认值的实数输入
(defun rc:getreal (msg def / v)
  (initget 6)
  (setq v (getreal (strcat "\n" msg " <" (rtos def 2 0) ">: ")))
  (if v v def))

;;; ---------- 几何范围选择(不依赖屏幕窗口, 无头/GUI 均稳定) ----------
;;; rc:seg-box 判断线段 ab 的包围盒是否与矩形区域[xL,yB,xR,yT]相交
(defun rc:seg-box (a b xL yB xR yT / ax1 ax2 ay1 ay2)
  (setq ax1 (min (car a) (car b))  ax2 (max (car a) (car b))
        ay1 (min (cadr a) (cadr b)) ay2 (max (cadr a) (cadr b)))
  (and (<= ax1 xR) (>= ax2 xL) (<= ay1 yT) (>= ay2 yB)))

;;; rc:lines-in-box 返回与矩形区域相交的 LINE 图元名列表(lay 为 nil 则不限图层)
(defun rc:lines-in-box (xL yB xR yT lay / ss i ed a b out flt)
  (setq out nil
        flt (if lay (list (cons 0 "LINE") (cons 8 lay)) (list (cons 0 "LINE"))))
  (if (setq ss (ssget "_X" flt))
    (progn (setq i 0)
      (while (< i (sslength ss))
        (setq ed (entget (ssname ss i))
              a (cdr (assoc 10 ed)) b (cdr (assoc 11 ed)))
        (if (rc:seg-box a b xL yB xR yT) (setq out (cons (ssname ss i) out)))
        (setq i (1+ i)))))
  (reverse out))

;;; ---------- 环境准备 ----------
;;; rc:split 按单字符分隔符拆分字符串, 返回字符串列表
(defun rc:split (str sep / out i start c)
  (setq out nil i 0 start 0)
  (while (< i (strlen str))
    (setq c (substr str (1+ i) 1))
    (if (= c sep)
      (progn
        (setq out (cons (substr str (1+ start) (- i start)) out))
        (setq start (1+ i))))
    (setq i (1+ i)))
  (reverse (cons (substr str (1+ start)) out)))

;;; rc:env 初始化: 关回显/初始化图层/初始化标注
(defun rc:env ()
  (setvar "CMDECHO" 0)
  (setvar "BLIPMODE" 0)
  (rc:init-layers)
  (rc:dimsetup)
  t)

;;; 加载本模块时的自动初始化
(rc:env)
(princ "\n[RuiCAD] 工具模块已加载 - ")(princ (rc:version))
(princ)
