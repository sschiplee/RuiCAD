;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 总入口
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  使用: 在 CAD 中 APPLOAD 加载本文件即可 (或在命令行 load)
;;;  说明: 自动定位本文件目录并加载全部模块, 输入 RCH 查看命令表
;;; ============================================================

;;; ---------- 自动定位 RuiCAD 根目录 ----------
;;; 说明: APPLOAD 加载本文件时, AutoCAD 会把文件所在目录临时
;;;       加入支持路径, 因此 findfile "init.lsp" 可用;
;;;       若已安装(install.lsp), 则支持路径已永久包含该目录。
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

;;; 仍未定位则给出提示
(if (or (null *rc-root*) (= *rc-root* ""))
  (princ "\n[RuiCAD] 错误: 无法定位插件目录, 请先运行 install.lsp 安装!")
  (progn
    ;; 加载核心框架
    (load (strcat *rc-root* "\\core\\settings.lsp"))
    (load (strcat *rc-root* "\\core\\utils.lsp"))
    ;; 加载命令模块
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
