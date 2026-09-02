;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 核心框架
;;;  模块: 全局参数与工艺设置 (settings.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  说明: 所有工艺参数集中在此管理, 设计师可按本厂标准修改。
;;;        修改后重新加载本文件即可生效 (无需重新安装)。
;;;  兼容: AutoCAD 2000+ / 中望 CAD / 浩辰 CAD (AutoLISP 环境)
;;; ============================================================

;;; ---------- 板材与结构参数 (单位: 毫米) ----------
(setq *rc-thk*        18)
(setq *rc-back-thk*   9)
(setq *rc-gap*        2)
(setq *rc-top-gap*    5)
(setq *rc-bottom-gap* 15)
(setq *rc-plinth*     100)
(setq *rc-rod-d*      32)
(setq *rc-drawer-h*   200)
(setq *rc-open-gap*   3)

;;; ---------- 默认绘制参数 ----------
(setq *rc-door-num*   2)
(setq *rc-shelf-num*  3)
(setq *rc-depth*      600)
(setq *rc-dim-off*    20)
(setq *rc-gs-gap*     30)
(setq *rc-gs-w*       8)
(setq *rc-dk-d*       20)
(setq *rc-dk-gap*     50)
(setq *rc-jg-w*       45)
(setq *rc-jg-h*       55)

;;; ---------- 五金与孔位参数 ----------
(setq *rc-hinge-cup*  35)
(setq *rc-hinge-edge* 100)
(setq *rc-cam-pitch*  32)
(setq *rc-cam-d*      5)
(setq *rc-handle-len* 128)

;;; ---------- 标注样式参数 ----------
(setq *rc-dim-txt*    35)
(setq *rc-dim-asz*    25)
(setq *rc-dim-exe*    12)
(setq *rc-dim-exo*    8)
(setq *rc-dim-gap*    8)

;;; ---------- 图层体系 ----------
(setq *rc-layers* '(
  (("RC-柜体" 7))
  (("RC-内部" 1))
  (("RC-门板" 3))
  (("RC-五金" 4))
  (("RC-灯带" 5))
  (("RC-标注" 2))
  (("RC-辅助" 8))
  (("RC-文字" 7))
))

(defun rc:version () "RuiCAD v0.2.0 (开源版)")
