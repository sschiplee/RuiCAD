;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 命令模块
;;;  模块: 编辑与效率工具 (edit.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  命令: KS智能拉伸 QL清理(零长度+重合去重) TC区域填充
;;; ============================================================

;;; ---------- KS 智能拉伸 ----------
(defun c:KS (/ p1 p2 b d)
  (rc:env)
  (princ "\nKS 智能拉伸: 交叉窗口框选要移动的一侧顶点")
  (setq p1 (getpoint "\n指定交叉窗口第一角点: "))
  (if p1
    (progn
      (setq p2 (getcorner p1 "\n指定对角点(从右向左框): "))
      (setq b (getpoint "\n指定基点: "))
      (if (and p2 b)
        (progn
          (setq d (getpoint b "\n指定位移目标点: "))
          (if d
            (progn (command "_.stretch" "_C" p1 p2 "" "_non" b "_non" d)
                   (princ "\n[KS] 拉伸完成"))
            (princ "\n[KS] 已取消")))
        (princ "\n[KS] 已取消")))
    (princ "\n[KS] 已取消"))
  (princ))

;;; ---------- QL 清理: 删零长度线 + 重合重复线, 返回删除数 ----------
(defun rc:clean (/ ss i en ed a b lay seen del key)
  (setq del 0)
  (if (setq ss (ssget "_X" (list (cons 0 "LINE"))))
    (progn (setq i 0)
      (while (< i (sslength ss))
        (setq en (ssname ss i) ed (entget en)
              a (cdr (assoc 10 ed)) b (cdr (assoc 11 ed)))
        (if (< (rc:dist a b) 0.01) (progn (entdel en) (setq del (1+ del))))
        (setq i (1+ i)))))
  (setq seen nil)
  (if (setq ss (ssget "_X" (list (cons 0 "LINE"))))
    (progn (setq i 0)
      (while (< i (sslength ss))
        (setq en (ssname ss i) ed (entget en)
              a (cdr (assoc 10 ed)) b (cdr (assoc 11 ed)) lay (cdr (assoc 8 ed)))
        (setq key (strcat lay "|"
                  (rtos (min (car a) (car b)) 2 2) "," (rtos (min (cadr a) (cadr b)) 2 2)
                  "|" (rtos (max (car a) (car b)) 2 2) "," (rtos (max (cadr a) (cadr b)) 2 2)))
        (if (member key seen)
          (progn (entdel en) (setq del (1+ del)))
          (setq seen (cons key seen)))
        (setq i (1+ i)))))
  del)

(defun c:QL ()
  (rc:env)
  (setq n (rc:clean))
  (princ (strcat "\n[QL] 清理完成, 删除 " (itoa n) " 个无效/重复线段"))
  (princ))

;;; ---------- TC 区域填充 ----------
(defun rc:fill (ss pat scale)
  (command "_.-hatch" "_P" pat scale "0" "_S" ss "" "")
  t)

(defun c:TC ()
  (rc:env)
  (princ "\nTC 填充 - 选择闭合边界对象(矩形/多段线): ")
  (setq ss (ssget))
  (if ss
    (progn
      (initget "SOLID ANSI31 ANSI32 AR-RROOF")
      (setq pat (getkword "\n填充图案 [SOLID实心/ANSI31斜线/ANSI32网格/AR-RROOF木纹] <ANSI31>: "))
      (if (null pat) (setq pat "ANSI31"))
      (setq sc (rc:getreal "填充比例" 20))
      (rc:fill ss pat sc)
      (princ "\n[TC] 填充已生成"))
    (princ "\n[TC] 已取消"))
  (princ))

(princ "\n[RuiCAD] 编辑与效率工具模块已加载")
(princ)
