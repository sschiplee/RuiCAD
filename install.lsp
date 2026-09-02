;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 一键安装
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  使用: 在 CAD 中 APPLOAD 选择本文件加载, 即完成安装并自动加载插件。
;;;  效果: 1. 将 RuiCAD 目录永久加入 CAD 支持路径
;;;        2. 立即加载全部插件模块
;;;  卸载: 命令行输入 RC-UNINSTALL 可移除支持路径
;;; ============================================================

(defun rc:install-locate ()
  (vl-string-right-trim
    "\\"
    (vl-string-right-trim
      "install.lsp"
      (findfile "install.lsp"))))

(defun rc:install-addpath (dir / old up)
  (setq old (getenv "ACAD"))
  (if (null old) (setq old ""))
  (if (not (vl-string-search (strcase dir) (strcase old)))
    (progn
      (setenv "ACAD" (strcat old ";" dir))
      (princ (strcat "\n[RuiCAD] 已将目录加入支持路径: " dir))
      t)
    (progn
      (princ (strcat "\n[RuiCAD] 目录已在支持路径中: " dir))
      nil)))

(defun c:RC-UNINSTALL (/ dir old segs new s)
  (setq dir (rc:install-locate))
  (setq old (getenv "ACAD"))
  (setq segs (rc:split old ";"))
  (setq new "")
  (foreach s segs
    (if (not (vl-string-search (strcase dir) (strcase s)))
      (if (= new "") (setq new s) (setq new (strcat new ";" s)))))
  (setenv "ACAD" new)
  (princ "\n[RuiCAD] 已从支持路径移除(卸载完成)")
  (princ))

(defun rc:install ()
  (setq *rc-root* (rc:install-locate))
  (if (and *rc-root* (/= *rc-root* ""))
    (progn
      (rc:install-addpath *rc-root*)
      (load (strcat *rc-root* "\\init.lsp"))
      (princ "\n[RuiCAD] 安装完成! 输入 RCH 查看命令表"))
    (princ "\n[RuiCAD] 安装失败: 无法定位安装目录"))
  (princ))

(rc:install)
