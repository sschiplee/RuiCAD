;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 总入口
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  使用: 在 CAD 中 APPLOAD 加载本文件即可 (或在命令行 load)
;;;  说明: 自动定位本文件目录并加载全部模块, 输入 RCH 查看命令表
;;; ============================================================

;;; ---------- 自动定位 RuiCAD 根目录 ----------
(if (null *rc-root*)
  (setq *rc-root*
    (vl-string-right-trim
      "\\"
      (vl-string-right-trim
        "init.lsp"
        (findfile "init.lsp")))))

;;; 若仍为空(非常规加载), 尝试从环境变量读取
(if (or (null *rc-root*) (= *rc-root* ""))
  (setq *rc-root* (getenv "RC_ROOT")))

(if (or (null *rc-root*) (= *rc-root* ""))
  (princ "\n[RuiCAD] 错误: 无法定位插件目录, 请先运行 install.lsp 安装!")
  (progn
    (load (strcat *rc-root* "\\core\\settings.lsp"))
    (load (strcat *rc-root* "\\core\\utils.lsp"))
    (load (strcat *rc-root* "\\commands\\draw.lsp"))
    (load (strcat *rc-root* "\\commands\\parts.lsp"))
    (load (strcat *rc-root* "\\commands\\view.lsp"))
    (load (strcat *rc-root* "\\commands\\dim.lsp"))
    (load (strcat *rc-root* "\\commands\\hardware.lsp"))
    (load (strcat *rc-root* "\\commands\\edit.lsp"))
    (load (strcat *rc-root* "\\commands\\panel.lsp"))
    (princ "\n==========================================")
    (princ "\n  RuiCAD 开源全屋定制 CAD 工具箱 已加载")
    (princ "\n  输入 RCH 查看全部命令 | RC 设置参数")
    (princ "\n  开源免费 · 无需注册登录 · 人人可用")
    (princ "\n==========================================")
    (princ)))

(princ)
