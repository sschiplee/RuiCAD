;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 命令模块
;;;  模块: 板件与部件 (parts.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  命令: LB立板 CB层板 ZC竖隔板 HD活动层板 MD门板 BL玻璃门 CY抽屉 WC外抽
;;;        YG衣杆 FF挂衣 DD灯带 BQ背板 GS隔栅 DK洞洞 JG酒格 XS见光板 JT踢脚
;;;        YH圆角 KD墙体开洞 TTM榻榻米
;;; ============================================================

;;; ---------- 区域选择辅助 ----------
(defun rc:region (msg) (rc:get-rect msg))

;;; ---------- LB 立板 ----------
(defun rc:lboard (p1 p2 x thk / x1 x2)
  (setq x1 (- x (/ thk 2.0)))
  (setq x2 (+ x (/ thk 2.0)))
  (rc:line (list x1 (cadr p1)) (list x1 (cadr p2)) "RC-内部")
  (rc:line (list x2 (cadr p1)) (list x2 (cadr p2)) "RC-内部"))

(defun c:LB ()
  (rc:env)
  (setq r (rc:region "LB 画立板"))
  (if r
    (progn
      (setq p (getpoint (car r) "\n指定立板位置: "))
      (if p
        (progn
          (setq thk (rc:getreal "板厚" *rc-thk*))
          (rc:lboard (car r) (cadr r) (car p) thk)
          (princ "\n[LB] 立板已生成"))
        (princ "\n[LB] 已取消")))
    (princ "\n[LB] 已取消"))
  (princ))

;;; ---------- CB 层板 (横向均分) ----------
(defun rc:shelves (p1 p2 n thk / y1 y2 span i y)
  (setq y1 (+ (cadr p1) thk))
  (setq y2 (- (cadr p2) thk))
  (setq span (- y2 y1))
  (setq i 1)
  (while (<= i n)
    (setq y (+ y1 (/ (* span i) (1+ n))))
    (rc:line (list (car p1) y) (list (car p2) y) "RC-内部")
    (setq i (1+ i))))

(defun c:CB ()
  (rc:env)
  (setq r (rc:region "CB 均分层板"))
  (if r
    (progn
      (setq n (rc:getint "层板数量" *rc-shelf-num*))
      (setq thk (rc:getreal "板厚" *rc-thk*))
      (rc:shelves (car r) (cadr r) n thk)
      (princ "\n[CB] 层板已生成"))
    (princ "\n[CB] 已取消"))
  (princ))

;;; ---------- ZC 竖隔板 (竖向均分) ----------
(defun rc:vboards (p1 p2 n thk / x1 x2 yb yt span i cx lx rx)
  (setq x1 (+ (car p1) thk) x2 (- (car p2) thk))
  (setq yb (+ (cadr p1) thk) yt (- (cadr p2) thk))
  (setq span (- x2 x1) i 1)
  (while (<= i n)
    (setq cx (+ x1 (/ (* span i) (1+ n))))
    (setq lx (- cx (/ thk 2.0)) rx (+ cx (/ thk 2.0)))
    (rc:line (list lx yb) (list lx yt) "RC-内部")
    (rc:line (list rx yb) (list rx yt) "RC-内部")
    (setq i (1+ i))))

(defun c:ZC ()
  (rc:env)
  (setq r (rc:region "ZC 竖隔板均分"))
  (if r
    (progn
      (setq n (rc:getint "竖隔板数量" 1))
      (setq thk (rc:getreal "板厚" *rc-thk*))
      (rc:vboards (car r) (cadr r) n thk)
      (princ "\n[ZC] 竖隔板已生成"))
    (princ "\n[ZC] 已取消"))
  (princ))

;;; ---------- HD 活动层板 (双线 + 两端销孔) ----------
(defun rc:active-shelf (p1 p2 thk d / x1 x2 y my)
  (setq x1 (car p1) x2 (car p2) y (cadr p1) my (+ y (/ thk 2.0)))
  (rc:line (list x1 y) (list x2 y) "RC-内部")
  (rc:line (list x1 (+ y thk)) (list x2 (+ y thk)) "RC-内部")
  (rc:circle (list (+ x1 9) my) (/ d 2.0) "RC-五金")
  (rc:circle (list (- x2 9) my) (/ d 2.0) "RC-五金"))

(defun c:HD ()
  (rc:env)
  (setq r (rc:region "HD 活动层板"))
  (if r
    (progn
      (setq thk (rc:getreal "层板厚" *rc-thk*))
      (rc:active-shelf (car r) (cadr r) thk 5)
      (princ "\n[HD] 活动层板已生成(两端销孔)"))
    (princ "\n[HD] 已取消"))
  (princ))

;;; ---------- MD 门板 (均分 n 扇, 含缝隙与拉手) ----------
(defun rc:doors (p1 p2 n gap dir / w i x1 x2 mid)
  (setq w (/ (- (car p2) (car p1)) n))
  (setq i 0)
  (while (< i n)
    (setq x1 (+ (car p1) (* i w)))
    (setq x2 (+ x1 w))
    (rc:rect (list x1 (cadr p1))
             (list (- x2 gap) (cadr p2))
             "RC-门板")
    (if (> dir 0)
      (progn
        (setq mid (list (+ x1 (/ w 2.0)) (/ (+ (cadr p1) (cadr p2)) 2.0)))
        (if (= dir 1)
          (rc:line mid (list (- (car mid) 30) (cadr mid)) "RC-五金")
          (rc:line mid (list (+ (car mid) 30) (cadr mid)) "RC-五金"))))
    (setq i (1+ i))))

(defun c:MD ()
  (rc:env)
  (setq r (rc:region "MD 画门板"))
  (if r
    (progn
      (setq n (rc:getint "门板数量" *rc-door-num*))
      (setq gap (rc:getreal "门缝" *rc-gap*))
      (setq dir (rc:getint "拉手(0无 1左 2右)" 1))
      (rc:doors (car r) (cadr r) n gap dir)
      (princ "\n[MD] 门板已生成"))
    (princ "\n[MD] 已取消"))
  (princ))

;;; ---------- BL 玻璃门 ----------
(defun rc:glass (p1 p2)
  (rc:rect p1 p2 "RC-门板")
  (rc:line p1 p2 "RC-内部")
  (rc:line (list (car p2) (cadr p1)) (list (car p1) (cadr p2)) "RC-内部"))

(defun c:BL ()
  (rc:env)
  (setq r (rc:region "BL 玻璃门"))
  (if r
    (progn
      (rc:glass (car r) (cadr r))
      (princ "\n[BL] 玻璃门已生成"))
    (princ "\n[BL] 已取消"))
  (princ))

;;; ---------- CY 抽屉 (均分 n 个 + 把手) ----------
(defun rc:drawers (p1 p2 n thk / x1 x2 y1 y2 span i y mid y1a y2a)
  (setq x1 (car p1) x2 (car p2))
  (setq y1 (+ (cadr p1) thk))
  (setq y2 (- (cadr p2) thk))
  (setq span (- y2 y1))
  (setq i 1)
  (while (< i n)
    (setq y (+ y1 (/ (* span i) n)))
    (rc:line (list x1 y) (list x2 y) "RC-内部")
    (setq i (1+ i)))
  (setq i 0)
  (while (< i n)
    (setq y1a (+ y1 (/ (* span i) n)))
    (setq y2a (+ y1 (/ (* span (1+ i)) n)))
    (setq mid (list (/ (+ x1 x2) 2.0) (/ (+ y1a y2a) 2.0)))
    (rc:line (list (- (car mid) 40) (cadr mid)) (list (+ (car mid) 40) (cadr mid)) "RC-五金")
    (setq i (1+ i))))

(defun c:CY ()
  (rc:env)
  (setq r (rc:region "CY 画抽屉"))
  (if r
    (progn
      (setq n (rc:getint "抽屉数量" 3))
      (setq thk (rc:getreal "板厚" *rc-thk*))
      (rc:drawers (car r) (cadr r) n thk)
      (princ "\n[CY] 抽屉已生成"))
    (princ "\n[CY] 已取消"))
  (princ))

;;; ---------- WC 外抽面板 (免拉手) ----------
(defun rc:wcout (p1 p2 / gap cx)
  (setq gap 15)
  (setq cx (/ (+ (car p1) (car p2)) 2.0))
  (rc:rect p1 (list (car p2) (- (cadr p2) gap)) "RC-门板")
  (rc:line (list (car p1) (- (cadr p2) gap)) (list (car p2) (- (cadr p2) gap)) "RC-内部")
  (rc:line (list cx (- (cadr p2) gap)) (list cx (+ (cadr p2) 10)) "RC-五金"))

(defun c:WC ()
  (rc:env)
  (setq r (rc:region "WC 外抽面板"))
  (if r
    (progn
      (rc:wcout (car r) (cadr r))
      (princ "\n[WC] 外抽面板已生成"))
    (princ "\n[WC] 已取消"))
  (princ))

;;; ---------- YG 衣杆 ----------
(defun rc:rod (p1 p2 y d / x1 x2 cx)
  (setq x1 (car p1) x2 (car p2) cx (/ (+ x1 x2) 2.0))
  (rc:circle (list cx y) (/ d 2.0) "RC-五金")
  (rc:line (list x1 y) (list (- cx (/ d 2.0)) y) "RC-五金")
  (rc:line (list (+ cx (/ d 2.0)) y) (list x2 y) "RC-五金"))

(defun c:YG ()
  (rc:env)
  (setq r (rc:region "YG 画衣杆"))
  (if r
    (progn
      (setq p (getpoint (car r) "\n指定衣杆位置: "))
      (if p
        (progn
          (setq d (rc:getreal "衣杆直径" *rc-rod-d*))
          (rc:rod (car r) (cadr r) (cadr p) d)
          (princ "\n[YG] 衣杆已生成"))
        (princ "\n[YG] 已取消")))
    (princ "\n[YG] 已取消"))
  (princ))

;;; ---------- FF 挂衣服 ----------
(defun rc:cloth (p1 p2 n / w i x1 x2 h top bot)
  (setq w (/ (- (car p2) (car p1)) n))
  (setq top (- (cadr p2) 5))
  (setq bot (+ (cadr p1) 5))
  (setq h (- top bot))
  (setq i 0)
  (while (< i n)
    (setq x1 (+ (car p1) (* i w)))
    (setq x2 (+ x1 w))
    (rc:line (list (+ x1 (* w 0.5)) top) (list (+ x1 (* w 0.25)) (- top (* h 0.15))) "RC-五金")
    (rc:line (list (+ x1 (* w 0.5)) top) (list (+ x1 (* w 0.75)) (- top (* h 0.15))) "RC-五金")
    (rc:line (list (+ x1 (* w 0.2)) (- top (* h 0.2))) (list (+ x1 (* w 0.8)) (- top (* h 0.2))) "RC-内部")
    (rc:line (list (+ x1 (* w 0.2)) (- top (* h 0.2))) (list (+ x1 (* w 0.3)) bot) "RC-内部")
    (rc:line (list (+ x1 (* w 0.8)) (- top (* h 0.2))) (list (+ x1 (* w 0.7)) bot) "RC-内部")
    (rc:line (list (+ x1 (* w 0.3)) bot) (list (+ x1 (* w 0.7)) bot) "RC-内部")
    (setq i (1+ i))))

(defun c:FF ()
  (rc:env)
  (setq r (rc:region "FF 挂衣服"))
  (if r
    (progn
      (setq n (rc:getint "衣服数量" 3))
      (rc:cloth (car r) (cadr r) n)
      (princ "\n[FF] 衣物已生成"))
    (princ "\n[FF] 已取消"))
  (princ))

;;; ---------- DD 灯带 ----------
(defun rc:led (p1 p2 / y)
  (setq y (- (cadr p2) 10))
  (rc:line (list (+ (car p1) 5) y) (list (- (car p2) 5) y) "RC-灯带")
  (rc:line (list (+ (car p1) 5) (- y 5)) (list (- (car p2) 5) (- y 5)) "RC-灯带"))

(defun c:DD ()
  (rc:env)
  (setq r (rc:region "DD 画灯带"))
  (if r
    (progn
      (rc:led (car r) (cadr r))
      (princ "\n[DD] 灯带已生成"))
    (princ "\n[DD] 已取消"))
  (princ))

;;; ---------- BQ 背板 ----------
(defun rc:back (p1 p2 thk)
  (rc:line (list (+ (car p1) thk) (cadr p1)) (list (+ (car p1) thk) (cadr p2)) "RC-内部")
  (rc:line (list (- (car p2) thk) (cadr p1)) (list (- (car p2) thk) (cadr p2)) "RC-内部"))

(defun c:BQ ()
  (rc:env)
  (setq r (rc:region "BQ 画背板"))
  (if r
    (progn
      (setq thk (rc:getreal "背板厚度" *rc-back-thk*))
      (rc:back (car r) (cadr r) thk)
      (princ "\n[BQ] 背板已生成"))
    (princ "\n[BQ] 已取消"))
  (princ))

;;; ---------- GS 隔栅板 ----------
(defun rc:gs (p1 p2 gap w / x x1 x2)
  (setq x (car p1))
  (while (< x (car p2))
    (setq x1 (+ x (/ w 2.0)))
    (setq x2 (- (+ x gap) (/ w 2.0)))
    (if (< x2 (car p2))
      (rc:rect (list x1 (cadr p1)) (list x2 (cadr p2)) "RC-内部"))
    (setq x (+ x gap))))

(defun c:GS ()
  (rc:env)
  (setq r (rc:region "GS 隔栅板"))
  (if r
    (progn
      (setq gap (rc:getreal "栅条间距" *rc-gs-gap*))
      (setq w (rc:getreal "栅条宽度" *rc-gs-w*))
      (rc:gs (car r) (cadr r) gap w)
      (princ "\n[GS] 隔栅板已生成"))
    (princ "\n[GS] 已取消"))
  (princ))

;;; ---------- DK 洞洞板 ----------
(defun rc:dk (p1 p2 d gap / x y)
  (setq x (+ (car p1) gap))
  (while (< x (car p2))
    (setq y (+ (cadr p1) gap))
    (while (< y (cadr p2))
      (rc:circle (list x y) (/ d 2.0) "RC-内部")
      (setq y (+ y gap)))
    (setq x (+ x gap))))

(defun c:DK ()
  (rc:env)
  (setq r (rc:region "DK 洞洞板"))
  (if r
    (progn
      (setq d (rc:getreal "孔径" *rc-dk-d*))
      (setq gap (rc:getreal "孔距" *rc-dk-gap*))
      (rc:dk (car r) (cadr r) d gap)
      (princ "\n[DK] 洞洞板已生成"))
    (princ "\n[DK] 已取消"))
  (princ))

;;; ---------- JG 酒格 (菱形交叉) ----------
(defun rc:jg (p1 p2 w h / x y i j nw nh)
  (setq nw (max 1 (fix (/ (- (car p2) (car p1)) w))))
  (setq nh (max 1 (fix (/ (- (cadr p2) (cadr p1)) h))))
  (setq x (car p1))
  (setq i 0)
  (while (<= i nw)
    (setq y (cadr p1))
    (setq j 0)
    (while (<= j nh)
      (rc:line (list x y) (list (+ x w) (+ y h)) "RC-内部")
      (rc:line (list (+ x w) y) (list x (+ y h)) "RC-内部")
      (setq y (+ y h))
      (setq j (1+ j)))
    (setq x (+ x w))
    (setq i (1+ i))))

(defun c:JG ()
  (rc:env)
  (setq r (rc:region "JG 酒格"))
  (if r
    (progn
      (setq w (rc:getreal "格宽" *rc-jg-w*))
      (setq h (rc:getreal "格深" *rc-jg-h*))
      (rc:jg (car r) (cadr r) w h)
      (princ "\n[JG] 酒格已生成"))
    (princ "\n[JG] 已取消"))
  (princ))

;;; ---------- XS 见光板/侧板 ----------
(defun rc:side (p1 p2 side thk / x)
  (if (= side 0)
    (setq x (car p1))
    (setq x (car p2)))
  (rc:rect (list x (cadr p1)) (list (+ x thk) (cadr p2)) "RC-柜体"))

(defun c:XS ()
  (rc:env)
  (setq r (rc:region "XS 见光板/侧板"))
  (if r
    (progn
      (setq side (rc:getint "侧板位置(0左 1右)" 0))
      (setq thk (rc:getreal "板厚" *rc-thk*))
      (rc:side (car r) (cadr r) side thk)
      (princ "\n[XS] 侧板已生成"))
    (princ "\n[XS] 已取消"))
  (princ))

;;; ---------- JT 踢脚 ----------
(defun rc:plinth (p1 p2 h)
  (rc:rect p1 (list (car p2) (+ (cadr p1) h)) "RC-柜体"))

(defun c:JT ()
  (rc:env)
  (setq r (rc:region "JT 踢脚"))
  (if r
    (progn
      (setq h (rc:getreal "踢脚高度" *rc-plinth*))
      (rc:plinth (car r) (cadr r) h)
      (princ "\n[JT] 踢脚已生成"))
    (princ "\n[JT] 已取消"))
  (princ))

;;; ---------- YH 圆角矩形 (LWPOLYLINE 凸度) ----------
(defun rc:chamfer (p1 p2 r / x1 y1 x2 y2 b)
  (setq x1 (car p1) y1 (cadr p1))
  (setq x2 (car p2) y2 (cadr p2))
  (setq b (- (sqrt 2.0) 1.0))
  (entmake (list (cons 0 "LWPOLYLINE")
                 (cons 100 "AcDbEntity")
                 (cons 8 "RC-柜体")
                 (cons 100 "AcDbPolyline")
                 (cons 90 8)
                 (cons 70 1)
                 (cons 10 (list x1 (+ y1 r)))
                 (cons 42 b)
                 (cons 10 (list (+ x1 r) y1))
                 (cons 10 (list (- x2 r) y1))
                 (cons 42 b)
                 (cons 10 (list x2 (+ y1 r)))
                 (cons 10 (list x2 (- y2 r)))
                 (cons 42 b)
                 (cons 10 (list (- x2 r) y2))
                 (cons 10 (list (+ x1 r) y2))
                 (cons 42 b)
                 (cons 10 (list x1 (- y2 r))))))

(defun c:YH ()
  (rc:env)
  (setq r (rc:region "YH 圆角"))
  (if r
    (progn
      (setq rr (rc:getreal "圆角半径" 30))
      (rc:chamfer (car r) (cadr r) rr)
      (princ "\n[YH] 圆角矩形已生成"))
    (princ "\n[YH] 已取消"))
  (princ))

;;; ---------- KD 墙体开洞 ----------
(defun rc:wall-hole (xL xR yB yT / lst en ed a b lay)
  (foreach en (rc:lines-in-box xL yB xR yT nil)
    (setq ed (entget en) a (cdr (assoc 10 ed)) b (cdr (assoc 11 ed)) lay (cdr (assoc 8 ed)))
    (if (and (equal (cadr a) (cadr b) 0.01)
             (< (car a) xL) (> (car b) xR))
      (progn
        (entdel en)
        (rc:line a (list xL (cadr a)) lay)
        (rc:line (list xR (cadr a)) b lay))))
  (rc:line (list xL yB) (list xL yT) "RC-柜体")
  (rc:line (list xR yB) (list xR yT) "RC-柜体"))

(defun c:KD ()
  (rc:env)
  (setq r (rc:region "KD 墙体开洞(框选洞口范围)"))
  (if r
    (progn
      (rc:wall-hole (car (car r)) (car (cadr r)) (cadr (car r)) (cadr (cadr r)))
      (princ "\n[KD] 洞口已开(自动断线封口)"))
    (princ "\n[KD] 已取消"))
  (princ))

;;; ---------- TTM 榻榻米 (下部抽屉 + 上部翻盖) ----------
(defun rc:tatami (p1 p2 nd / x1 y1 x2 dh w span i cx thk)
  (setq x1 (car p1) y1 (cadr p1) x2 (car p2) thk *rc-thk*)
  (setq w (- x2 x1))
  (setq dh (* (- (cadr p2) (cadr p1)) 0.32))
  (rc:rect p1 p2 "RC-柜体")
  (setq span (/ w nd) i 0)
  (while (< i nd)
    (setq cx (+ x1 (* span (1+ i))))
    (rc:rect (list (+ x1 (* span i)) y1) (list (- cx *rc-gap*) (+ y1 dh)) "RC-门板")
    (setq i (1+ i)))
  (rc:line (list x1 (+ y1 dh)) (list x2 (+ y1 dh)) "RC-内部")
  (rc:rect (list x1 (+ y1 dh)) (list x2 (- (cadr p2) *rc-gap*)) "RC-门板"))

(defun c:TTM ()
  (rc:env)
  (setq r (rc:region "TTM 榻榻米"))
  (if r
    (progn
      (setq nd (rc:getint "下部抽屉数量" 3))
      (rc:tatami (car r) (cadr r) nd)
      (princ "\n[TTM] 榻榻米已生成"))
    (princ "\n[TTM] 已取消"))
  (princ))

(princ "\n[RuiCAD] 板件与部件模块已加载")
(princ)
