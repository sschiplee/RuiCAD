;;; ============================================================
;;;  RuiCAD 开源全屋定制 CAD 工具箱 · 命令模块
;;;  模块: 设置与帮助 (panel.lsp)
;;;  ------------------------------------------------------------
;;;  协议: MIT License
;;;  命令: RC 工艺参数设置 | RCH 帮助(命令表) | RCV 版本
;;; ============================================================

;;; ---------- RC 工艺参数设置 (命令行交互) ----------
(defun c:RC ()
  (rc:env)
  (princ "\n===== RuiCAD 工艺参数设置 =====")
  (setq *rc-thk*        (rc:getreal "常规板材厚度(mm)" *rc-thk*))
  (setq *rc-back-thk*   (rc:getreal "背板厚度(mm)" *rc-back-thk*))
  (setq *rc-gap*        (rc:getreal "门缝(mm)" *rc-gap*))
  (setq *rc-plinth*     (rc:getreal "踢脚高度(mm)" *rc-plinth*))
  (setq *rc-rod-d*      (rc:getreal "衣杆直径(mm)" *rc-rod-d*))
  (setq *rc-depth*      (rc:getreal "柜体深度(mm,轴测用)" *rc-depth*))
  (setq *rc-door-num*   (rc:getint "门板默认数量" *rc-door-num*))
  (setq *rc-shelf-num*  (rc:getint "层板默认数量" *rc-shelf-num*))
  (setq *rc-dim-off*    (rc:getreal "标注偏移距离(mm)" *rc-dim-off*))
  (princ "\n[RC] 参数已更新, 立即生效")
  (princ))

;;; ---------- RCH 帮助: 命令表 ----------
(defun c:RCH ()
  (rc:env)
  (princ "\n============== RuiCAD 命令速查表 ==============")
  (princ "\n[柜体框架]")
  (princ "\n  KJ 框架   DG 标准柜   WG 吊柜   HQ 双线墙   TTM 榻榻米")
  (princ "\n[板件部件]")
  (princ "\n  LB 立板   CB 层板(横)  ZC 竖隔板  HD 活动层板")
  (princ "\n  MD 门板   BL 玻璃门    CY 抽屉    WC 外抽面板")
  (princ "\n  YG 衣杆   FF 挂衣服    DD 灯带    BQ 背板")
  (princ "\n  GS 隔栅   DK 洞洞板    JG 酒格    XS 见光板")
  (princ "\n  JT 踢脚   YH 圆角      KD 墙体开洞")
  (princ "\n[五金孔位]")
  (princ "\n  JL 铰链(自动定数)  LS 拉手  SYH 三合一32系统排孔")
  (princ "\n[视图生成]")
  (princ "\n  TZ 假三维轴测  FM 俯视投影  PQ 剖切符号  FD 大样放大")
  (princ "\n[标注统计]")
  (princ "\n  BZ 一键标注  NBZ 内部分段  DBZ 逐段连续  BM 门板标注")
  (princ "\n  MJ 面积  WJ 部件清单  BH 板件编号")
  (princ "\n  BOM 拆单CSV  BOM2 详细统计CSV(含线长/圆/多段线)")
  (princ "\n[编辑工具]")
  (princ "\n  KS 智能拉伸  QL 清理去重  TC 区域填充")
  (princ "\n[通用工具]")
  (princ "\n  PRIM 批量图片  TK 图框编号  TS 文字刷  KB 图库")
  (princ "\n  RC 参数设置  RCH 本帮助  RCV 版本")
  (princ "\n==============================================")
  (princ))

;;; ---------- RCV 版本信息 ----------
(defun c:RCV ()
  (princ "\n[RuiCAD] ")
  (princ (rc:version))
  (princ " - 开源免费, 无需注册登录, 人人可用")
  (princ))

(princ "\n[RuiCAD] 设置与帮助模块已加载")
(princ)
