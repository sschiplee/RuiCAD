;;; ============================================================
;;;  RuiCAD 自测框架 (test_main.lsp)
;;;  在 accoreconsole 中无头运行, 逐个调用 rc: 逻辑函数,
;;;  校验"无LISP错误"且"确实生成图元", 输出 PASS/FAIL 报告。
;;; ============================================================
(vl-load-com)
(setq *rc-pass* 0 *rc-fail* 0 *rc-fails* '())

;;; 统计图元总数 (typ=nil 全部, 否则按类型)
(defun rc:entcount (typ / ss)
  (if typ
    (setq ss (ssget "_X" (list (cons 0 typ))))
    (setq ss (ssget "_X")))
  (if ss (sslength ss) 0))

;;; 单个用例: name 名称, fn 函数符号, args 参数表, min-delta 至少新增图元数
(defun rc:t (name fn args min-delta / b a res)
  (setq b (rc:entcount nil))
  (setq res (vl-catch-all-apply fn args))
  (setq a (rc:entcount nil))
  (cond
    ((vl-catch-all-error-p res)
     (setq *rc-fail* (1+ *rc-fail*))
     (setq *rc-fails* (cons (strcat name " -> " (vl-catch-all-error-message res)) *rc-fails*))
     (princ (strcat "\n[FAIL] " name " : " (vl-catch-all-error-message res))))
    ((>= (- a b) min-delta)
     (setq *rc-pass* (1+ *rc-pass*))
     (princ (strcat "\n[PASS] " name " (+" (itoa (- a b)) ")")))
    (t
     (setq *rc-fail* (1+ *rc-fail*))
     (setq *rc-fails* (cons (strcat name " : expect +" (itoa min-delta) " got +" (itoa (- a b))) *rc-fails*))
     (princ (strcat "\n[FAIL] " name " : expect +" (itoa min-delta) " but +" (itoa (- a b)))))))

;;; 纯函数用例: 只校验不报错且返回非nil
(defun rc:tv (name fn args / res)
  (setq res (vl-catch-all-apply fn args))
  (cond
    ((vl-catch-all-error-p res)
     (setq *rc-fail* (1+ *rc-fail*))
     (setq *rc-fails* (cons (strcat name " -> " (vl-catch-all-error-message res)) *rc-fails*))
     (princ (strcat "\n[FAIL] " name " : " (vl-catch-all-error-message res))))
    ((null res)
     (setq *rc-fail* (1+ *rc-fail*))
     (setq *rc-fails* (cons (strcat name " : returned nil") *rc-fails*))
     (princ (strcat "\n[FAIL] " name " : returned nil")))
    (t
     (setq *rc-pass* (1+ *rc-pass*))
     (princ (strcat "\n[PASS] " name " = " (vl-princ-to-string res))))))

(defun rc:run-all ()
  (princ "\n########## RuiCAD 自测开始 ##########")
  ;; ---- 框架/标准柜/墙 ----
  (rc:t "KJ-frame框架"     'rc:frame    (list '(0 0) '(900 2400) 18) 8)
  (rc:t "DG-unitcab标准柜" 'rc:unit-cab (list '(2000 0) 1800.0 2400.0 18.0 3 100 2) 10)
  (rc:t "HQ-wall画墙"      'rc:wall     (list '(0 -3000) '(3000 -3000) 120.0) 4)
  ;; ---- 板件部件 ----
  (rc:t "LB-lboard立板"    'rc:lboard   (list '(0 0) '(900 2400) 450.0 18.0) 2)
  (rc:t "CB-shelves层板"   'rc:shelves  (list '(0 0) '(900 2400) 3 18.0) 3)
  (rc:t "ZC-vboards竖隔板" 'rc:vboards  (list '(0 0) '(900 2400) 2 18.0) 4)
  (rc:t "HD-active活动层板" 'rc:active-shelf (list '(0 0) '(900 18) 18.0 5.0) 4)
  (rc:t "MD-doors门板"     'rc:doors    (list '(0 0) '(900 2400) 3 2.0 1) 12)
  (rc:t "BL-glass玻璃门"   'rc:glass    (list '(0 -1000) '(400 -400)) 6)
  (rc:t "CY-drawers抽屉"   'rc:drawers  (list '(0 -2000) '(900 -1000) 3 18.0) 5)
  (rc:t "WC-wcout外抽"     'rc:wcout    (list '(1500 -2000) '(1900 -1800)) 6)
  (rc:t "YG-rod衣杆"       'rc:rod      (list '(0 0) '(900 1800) 1800.0 32.0) 3)
  (rc:t "FF-cloth挂衣"     'rc:cloth    (list '(0 -4000) '(900 -2200) 3) 10)
  (rc:t "DD-led灯带"       'rc:led      (list '(1500 -4000) '(2400 -3400)) 2)
  (rc:t "BQ-back背板"      'rc:back     (list '(0 0) '(900 2400) 9.0) 2)
  (rc:t "GS-gs隔栅"        'rc:gs       (list '(1500 0) '(1800 600) 30.0 8.0) 4)
  (rc:t "DK-dk洞洞"        'rc:dk       (list '(0 -5000) '(200 -4800) 20.0 50.0) 4)
  (rc:t "JG-jg酒格"        'rc:jg       (list '(1500 -5000) '(1800 -4700) 45.0 55.0) 4)
  (rc:t "XS-side见光板"    'rc:side     (list '(0 0) '(900 2400) 0 18.0) 4)
  (rc:t "JT-plinth踢脚"    'rc:plinth   (list '(0 0) '(900 2400) 100.0) 4)
  (rc:t "YH-chamfer圆角"   'rc:chamfer  (list '(2000 -4000) '(2400 -3600) 30.0) 1)
  (rc:t "TTM-tatami榻榻米" 'rc:tatami   (list '(3000 -5000) '(4800 -4200) 3) 15)
  ;; KD 墙体开洞: 先造一条横跨水平墙线, 再开洞(删1加2侧段+2封口, 净增3)
  (rc:line '(10000 100) '(11000 100) "RC-柜体")
  (rc:t "KD-wallhole开洞"  'rc:wall-hole (list 10300.0 10700.0 0.0 200.0) 3)
  ;; ---- 五金孔位 ----
  (rc:t "JL-hinges铰链"    'rc:hinges    (list '(12000 0) '(12400 2400) 1 100.0) 8)
  (rc:t "LS-handle拉手"    'rc:handle    (list '(13000 0) '(13400 600) 0.35 128.0) 3)
  (rc:t "SYH-cambolts三合一" 'rc:cam-bolts (list '(14000 0) '(14200 600) 0 32.0 5.0) 10)
  ;; ---- 视图 ----
  (rc:t "TZ-axono轴测"     'rc:axono    (list '(3000 0) '(3900 2400) 600.0 0) 8)
  ;; FM 俯视: 先在区域内放一条内部竖板线, 应被识别并投影(外框4+投影1=5)
  (rc:line '(3300 -3000) '(3300 -600) "RC-内部")
  (rc:t "FM-plan俯视"      'rc:plan     (list '(3000 -3000) '(3900 -600) 600.0 18.0) 5)
  (rc:t "PQ-section剖切"   'rc:section  (list '(3000 0) '(3900 2400) 0) 3)
  ;; ---- 标注/统计 ----
  (rc:t "BZ-dimrect标注"   'rc:dimrect  (list '(4000 0) '(4900 2400)) 2)
  (rc:t "NBZ-diminner内标" 'rc:diminner (list '(4000 -3000) '(4900 -600) 4) 3)
  (rc:t "BM-dimdoors门板标" 'rc:dim-doors (list '(5000 0) '(5900 2400) 3 2.0) 3)
  ;; DBZ 连续标注: 先造两条内部竖线, 形成 0/300/600/900 三段
  (rc:line '(20000 0) '(20000 2400) "RC-内部")
  (rc:line '(20300 0) '(20300 2400) "RC-内部")
  (rc:line '(20600 0) '(20600 2400) "RC-内部")
  (rc:t "DBZ-dimchain连续标" 'rc:dimchain (list '(20000 0) '(20900 2400) 20.0) 3)
  (rc:t "TK-num图框编号"   'rc:num      (list 1 '(5000 0) 100 3) 3)
  ;; BH 板件编号: 选灯带图层(DD生成2条), 应编号并加圆+文字
  (setq tmpss (ssget "_X" (list (cons 8 "RC-灯带"))))
  (rc:tv "BH-numparts编号" 'rc:num-parts (list tmpss))
  ;; ---- 编辑工具 ----
  (rc:line '(30000 0) '(30100 0) "RC-柜体")      ; 基线
  (rc:line '(30000 0) '(30100 0) "RC-柜体")      ; 完全重合
  (rc:line '(30200 0) '(30200 0) "RC-柜体")      ; 零长度
  (rc:tv "QL-clean清理去重" 'rc:clean nil)
  (rc:tv "EXIST-KS拉伸命令" 'type (list c:KS))
  (rc:tv "EXIST-TC填充命令" 'type (list c:TC))
  ;; ---- 纯函数 ----
  (rc:tv "MJ-area面积"      'rc:area        (list '(0 0) '(900 2400)))
  (rc:tv "WJ-countlayer统计" 'rc:count-layer (list "RC-柜体"))
  (rc:tv "UTIL-dist距离"    'rc:dist        (list '(0 0) '(3 4)))
  (rc:tv "UTIL-mid中点"     'rc:mid         (list '(0 0) '(10 20)))
  (rc:tv "UTIL-divpts等分"  'rc:div-pts     (list '(0 0) '(900 0) 3))
  (rc:tv "UTIL-split拆分"   'rc:split       (list "a;b;c" ";"))
  (rc:tv "HW-hingecount门高" 'rc:hinge-count (list 2400))
  (rc:tv "ALIAS-region别名" 'type (list rc:region))
  (rc:tv "VER-version版本"  'rc:version     nil)
  ;; ---- 汇总 ----
  (princ "\n==================================================")
  (princ (strcat "\n  RuiCAD 自测结果: PASS=" (itoa *rc-pass*)
                 "  FAIL=" (itoa *rc-fail*)))
  (if (> *rc-fail* 0)
    (progn
      (princ "\n  ---- 失败明细 ----")
      (foreach f (reverse *rc-fails*) (princ (strcat "\n  [FAIL] " f))))
    (princ "\n  全部用例通过 ✓"))
  (princ "\n==================================================")
  (princ))
