// ============================================================
//  RuiCAD 开源全屋定制 CAD 工具箱 · 图形安装器
//  编译: csc /target:winexe /out:RuiCAD-Setup.exe Setup.cs /resource:...
//  作者: RuiCAD contributors   协议: MIT
//  说明: 单文件免管理员安装; 自动检测 AutoCAD/中望/浩辰并配置开机自动加载。
// ============================================================
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Text;
using System.Windows.Forms;
using Microsoft.Win32;

namespace RuiCADSetup
{
    static class Program
    {
        // 安装文件清单: { 相对路径, 嵌入资源名 }
        static readonly string[][] Files = new string[][]
        {
            new string[]{"init.lsp",                 "rc.init.lsp"},
            new string[]{"install.lsp",              "rc.install.lsp"},
            new string[]{"LICENSE",                  "rc.LICENSE"},
            new string[]{"core\\settings.lsp",       "rc.core.settings.lsp"},
            new string[]{"core\\utils.lsp",          "rc.core.utils.lsp"},
            new string[]{"commands\\draw.lsp",       "rc.commands.draw.lsp"},
            new string[]{"commands\\parts.lsp",      "rc.commands.parts.lsp"},
            new string[]{"commands\\view.lsp",       "rc.commands.view.lsp"},
            new string[]{"commands\\dim.lsp",        "rc.commands.dim.lsp"},
            new string[]{"commands\\hardware.lsp",   "rc.commands.hardware.lsp"},
            new string[]{"commands\\edit.lsp",       "rc.commands.edit.lsp"},
            new string[]{"commands\\panel.lsp",      "rc.commands.panel.lsp"},
        };

        const string AppName = "RuiCAD 全屋定制CAD工具箱";
        const string AppShort = "RuiCAD";
        internal static string DefaultDir = Path.Combine(
            Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
            "RuiCAD");
        static string UninstKey = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\RuiCAD";

        [STAThread]
        static int Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            bool uninstall = false, silent = false;
            foreach (string a in args)
            {
                string u = a.ToUpper();
                if (u == "/UNINSTALL" || u == "-UNINSTALL" || u == "/U") uninstall = true;
                if (u == "/SILENT" || u == "/S" || u == "-S") silent = true;
            }

            if (uninstall)
            {
                DoUninstall(silent);
                return 0;
            }
            if (silent)
            {
                string log;
                DoInstall(DefaultDir, out log);
                return 0;
            }
            Application.Run(new WizardForm());
            return 0;
        }

        // ---------------- 安装 ----------------
        internal static bool DoInstall(string dir, out string log)
        {
            StringBuilder sb = new StringBuilder();
            bool ok = true;
            try
            {
                // 1. 释放文件 (UTF-8 BOM, 保证各版本CAD中文不乱码)
                sb.AppendLine("[1/3] 释放插件文件...");
                Assembly asm = Assembly.GetExecutingAssembly();
                UTF8Encoding utf8bom = new UTF8Encoding(true);
                foreach (string[] f in Files)
                {
                    string rel = f[0], res = f[1];
                    string target = Path.Combine(dir, rel);
                    Directory.CreateDirectory(Path.GetDirectoryName(target));
                    using (Stream rs = asm.GetManifestResourceStream(res))
                    using (FileStream fs = new FileStream(target, FileMode.Create, FileAccess.Write))
                    {
                        if (rs == null) { sb.AppendLine("  缺少资源: " + res); continue; }
                        using (StreamReader sr = new StreamReader(rs, new UTF8Encoding(false)))
                        using (StreamWriter sw = new StreamWriter(fs, utf8bom))
                            sw.Write(sr.ReadToEnd());
                    }
                }
                sb.AppendLine("  已释放 " + Files.Length + " 个文件到: " + dir);

                // 2. 配置 CAD 自动加载
                sb.AppendLine("[2/3] 检测并配置 CAD 自动加载...");
                int cadCount = ConfigureCad(dir, true, sb);
                sb.AppendLine("  共配置 " + cadCount + " 个 CAD 配置档案");

                // 3. 注册卸载信息 + 复制自身为卸载程序
                sb.AppendLine("[3/3] 注册卸载信息...");
                RegisterUninstall(dir);
                sb.AppendLine("  完成");

                // 4. 若 CAD 正在运行, 立即向所有打开的图纸注入加载(无需重启 CAD)
                int live = LiveLoad(Path.Combine(dir, "init.lsp"));
                if (live > 0) sb.AppendLine("  检测到正在运行的 CAD, 已在 " + live + " 个窗口即时加载, 无需重启");
            }
            catch (Exception ex)
            {
                ok = false;
                sb.AppendLine("安装出错: " + ex.Message);
            }
            log = sb.ToString();
            return ok;
        }

        // 配置(或移除)所有已安装 CAD 的支持路径与启动套件, 返回处理的档案数
        static int ConfigureCad(string dir, bool add, StringBuilder sb)
        {
            int count = 0;
            string initLsp = Path.Combine(dir, "init.lsp");
            count += ConfigureVendor(@"Software\Autodesk\AutoCAD", dir, initLsp, add, sb, "AutoCAD");
            count += ConfigureVendor(@"Software\ZWSOFT\ZWCAD", dir, initLsp, add, sb, "中望CAD");
            count += ConfigureVendor(@"Software\Gstarsoft\GstarCAD", dir, initLsp, add, sb, "浩辰CAD");
            return count;
        }

        static int ConfigureVendor(string rootRel, string dir, string initLsp,
                                   bool add, StringBuilder sb, string label)
        {
            int n = 0;
            try
            {
                using (RegistryKey root = Registry.CurrentUser.OpenSubKey(rootRel))
                {
                    if (root == null) return 0;
                    foreach (string ver in root.GetSubKeyNames())
                    {
                        using (RegistryKey verKey = root.OpenSubKey(ver))
                        {
                            if (verKey == null) continue;
                            foreach (string prod in verKey.GetSubKeyNames())
                            {
                                using (RegistryKey prodKey = verKey.OpenSubKey(prod, true))
                                {
                                    if (prodKey == null) continue;
                                    if (HandleProfiles(prodKey, dir, initLsp, add, sb, label)) n++;
                                }
                            }
                        }
                    }
                }
            }
            catch (Exception ex) { sb.AppendLine("  (" + label + " 扫描跳过: " + ex.Message + ")"); }
            return n;
        }

        static bool HandleProfiles(RegistryKey prodKey, string dir, string initLsp,
                                   bool add, StringBuilder sb, string label)
        {
            bool touched = false;
            using (RegistryKey profiles = prodKey.OpenSubKey("Profiles"))
            {
                if (profiles != null)
                {
                    foreach (string pname in profiles.GetSubKeyNames())
                    {
                        using (RegistryKey gen = profiles.OpenSubKey(pname + @"\General", true))
                        {
                            if (gen == null) continue;
                            object cur = gen.GetValue("ACAD");
                            string s = cur == null ? "" : cur.ToString();
                            string ns = add ? AppendPath(s, dir) : RemovePath(s, dir);
                            if (ns != s) { gen.SetValue("ACAD", ns, RegistryValueKind.String); touched = true; }
                        }
                    }
                }
            }
            try
            {
                using (RegistryKey startup = prodKey.CreateSubKey(@"Dialogs\Appload\Startup"))
                {
                    var names = new List<string>(startup.GetValueNames());
                    bool exists = false;
                    foreach (string vn in names)
                        if (string.Equals(Convert.ToString(startup.GetValue(vn)),
                                          initLsp, StringComparison.OrdinalIgnoreCase))
                            exists = true;
                    if (add)
                    {
                        if (!exists)
                        {
                            int idx = 1;
                            while (names.Contains(idx.ToString())) idx++;
                            startup.SetValue(idx.ToString(), initLsp, RegistryValueKind.String);
                            touched = true;
                        }
                    }
                    else
                    {
                        foreach (string vn in names)
                            if (string.Equals(Convert.ToString(startup.GetValue(vn)),
                                              initLsp, StringComparison.OrdinalIgnoreCase))
                            { startup.DeleteValue(vn, false); touched = true; }
                    }
                }
            }
            catch (Exception ex) { sb.AppendLine("  (启动套件配置跳过: " + ex.Message + ")"); }
            if (touched) sb.AppendLine("  已" + (add ? "配置" : "移除") + " " + label + ": " + prodKey.Name.Substring(prodKey.Name.LastIndexOf('\\') + 1));
            return touched;
        }

        static string AppendPath(string s, string dir)
        {
            string[] parts = s.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries);
            foreach (string p in parts)
                if (string.Equals(p.Trim(), dir, StringComparison.OrdinalIgnoreCase)) return s;
            string r = s.TrimEnd(';');
            return (r.Length == 0 ? dir : r + ";" + dir);
        }
        static string RemovePath(string s, string dir)
        {
            var keep = new List<string>();
            foreach (string p in s.Split(new char[] { ';' }, StringSplitOptions.RemoveEmptyEntries))
                if (!string.Equals(p.Trim(), dir, StringComparison.OrdinalIgnoreCase)) keep.Add(p.Trim());
            return string.Join(";", keep.ToArray());
        }

        static void RegisterUninstall(string dir)
        {
            try
            {
                string exe = Assembly.GetExecutingAssembly().Location;
                string uninstExe = Path.Combine(dir, "RuiCAD-Uninstall.exe");
                try { File.Copy(exe, uninstExe, true); } catch { }
                using (RegistryKey k = Registry.CurrentUser.CreateSubKey(UninstKey))
                {
                    k.SetValue("DisplayName", AppName, RegistryValueKind.String);
                    k.SetValue("DisplayVersion", "0.2.0", RegistryValueKind.String);
                    k.SetValue("Publisher", "RuiCAD contributors (MIT开源)", RegistryValueKind.String);
                    k.SetValue("InstallLocation", dir, RegistryValueKind.String);
                    k.SetValue("UninstallString", "\"" + uninstExe + "\" /uninstall", RegistryValueKind.String);
                    k.SetValue("NoModify", 1, RegistryValueKind.DWord);
                    k.SetValue("NoRepair", 1, RegistryValueKind.DWord);
                }
            }
            catch { }
        }

        // ---------------- 即时加载正在运行的 CAD(免重启) ----------------
        static int LiveLoad(string initLsp)
        {
            string[] progIds = { "AutoCAD.Application", "ZWCAD.Application", "GstarCAD.Application" };
            string cmd = "(load \"" + initLsp.Replace("\\", "/") + "\")(princ)\n";
            int n = 0;
            foreach (string pid in progIds)
            {
                object app = null;
                try { app = Marshal.GetActiveObject(pid); }
                catch { continue; }
                if (app == null) continue;
                try
                {
                    object docs = app.GetType().InvokeMember("Documents", BindingFlags.GetProperty, null, app, null);
                    int cnt = (int)docs.GetType().InvokeMember("Count", BindingFlags.GetProperty, null, docs, null);
                    for (int i = 0; i < cnt; i++)
                    {
                        object doc = docs.GetType().InvokeMember("Item", BindingFlags.InvokeMethod | BindingFlags.GetProperty, null, docs, new object[] { i });
                        if (doc != null)
                        {
                            doc.GetType().InvokeMember("SendCommand", BindingFlags.InvokeMethod, null, doc, new object[] { cmd });
                            n++;
                        }
                    }
                }
                catch { }
            }
            return n;
        }

        // ---------------- 卸载 ----------------
        static void DoUninstall(bool silent)
        {
            string dir = DefaultDir;
            try
            {
                using (RegistryKey k = Registry.CurrentUser.OpenSubKey(UninstKey))
                    if (k != null) { object o = k.GetValue("InstallLocation"); if (o != null) dir = o.ToString(); }
            }
            catch { }

            if (!silent)
            {
                DialogResult r = MessageBox.Show(
                    "确定要卸载 " + AppName + " 吗?\n将移除自动加载配置和安装文件。",
                    "RuiCAD 卸载", MessageBoxButtons.YesNo, MessageBoxIcon.Question);
                if (r != DialogResult.Yes) return;
            }

            StringBuilder sb = new StringBuilder();
            ConfigureCad(dir, false, sb);
            try
            {
                Registry.CurrentUser.DeleteSubKeyTree(UninstKey, false);
            }
            catch { }
            try
            {
                ProcessStartInfo psi = new ProcessStartInfo("cmd.exe",
                    string.Format("/c ping 127.0.0.1 -n 3 >nul & rmdir /s /q \"{0}\"", dir))
                { CreateNoWindow = true, WindowStyle = ProcessWindowStyle.Hidden, UseShellExecute = false };
                Process.Start(psi);
            }
            catch { try { if (Directory.Exists(dir)) Directory.Delete(dir, true); } catch { } }

            if (!silent)
                MessageBox.Show("RuiCAD 已卸载完成。", "卸载完成", MessageBoxButtons.OK, MessageBoxIcon.Information);
        }
    }

    // ==================== 安装向导窗体 ====================
    class WizardForm : Form
    {
        TextBox txtDir; Button btnBrowse, btnMain, btnCancel;
        ProgressBar bar; TextBox txtLog; Label lblTitle, lblSub;
        Panel p1, p2;
        bool installed = false;

        public WizardForm()
        {
            Text = "RuiCAD 全屋定制CAD工具箱 · 安装";
            Width = 560; Height = 460;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false; StartPosition = FormStartPosition.CenterScreen;
            Font = new Font("微软雅黑", 9F);
            BackColor = Color.White;

            lblTitle = new Label { Left = 20, Top = 18, Width = 500, Height = 30,
                Text = "RuiCAD 全屋定制 CAD 工具箱", Font = new Font("微软雅黑", 15F, FontStyle.Bold) };
            lblSub = new Label { Left = 22, Top = 52, Width = 500, Height = 22, ForeColor = Color.DimGray,
                Text = "开源免费 · 无需注册登录 · 支持 AutoCAD / 中望 / 浩辰" };
            Controls.Add(lblTitle); Controls.Add(lblSub);

            p1 = new Panel { Left = 20, Top = 90, Width = 510, Height = 270 };
            Label l1 = new Label { Left = 0, Top = 10, Width = 480, Text = "安装位置:" };
            txtDir = new TextBox { Left = 0, Top = 34, Width = 400, Text = Program.DefaultDir };
            btnBrowse = new Button { Left = 408, Top = 32, Width = 90, Text = "浏览..." };
            btnBrowse.Click += (s, e) =>
            {
                using (FolderBrowserDialog fd = new FolderBrowserDialog())
                {
                    if (fd.ShowDialog() == DialogResult.OK) txtDir.Text = fd.SelectedPath;
                }
            };
            Label l2 = new Label { Left = 0, Top = 78, Width = 490, Height = 120,
                Text = "安装内容:\r\n" +
                       "  · 40+ 全屋定制绘图命令(柜体/板件/五金/轴测/标注/拆单/编辑)\r\n" +
                       "  · 自动检测并配置已安装的 CAD, 开机自动加载\r\n" +
                       "  · 独立图层体系与工艺参数, 不影响现有插件\r\n" +
                       "  · 安装后打开 CAD, 输入 RCH 即可查看全部命令\r\n\r\n" +
                       "本软件以 MIT 协议开源, 安装无需管理员权限。" ,
                ForeColor = Color.Black };
            p1.Controls.Add(l1); p1.Controls.Add(txtDir); p1.Controls.Add(btnBrowse); p1.Controls.Add(l2);
            Controls.Add(p1);

            p2 = new Panel { Left = 20, Top = 90, Width = 510, Height = 270, Visible = false };
            bar = new ProgressBar { Left = 0, Top = 6, Width = 500, Height = 18, Style = ProgressBarStyle.Continuous };
            txtLog = new TextBox { Left = 0, Top = 36, Width = 500, Height = 220,
                Multiline = true, ReadOnly = true, ScrollBars = ScrollBars.Vertical,
                BackColor = Color.FromArgb(248,248,248), Font = new Font("Consolas", 9F) };
            p2.Controls.Add(bar); p2.Controls.Add(txtLog);
            Controls.Add(p2);

            btnMain = new Button { Left = 350, Top = 375, Width = 95, Height = 32, Text = "立即安装" };
            btnCancel = new Button { Left = 455, Top = 375, Width = 75, Height = 32, Text = "取消" };
            btnMain.Click += OnMain;
            btnCancel.Click += (s, e) => { if (installed) DialogResult = DialogResult.OK; this.Close(); };
            Controls.Add(btnMain); Controls.Add(btnCancel);
        }

        void OnMain(object s, EventArgs e)
        {
            if (installed) { this.Close(); return; }
            string dir = txtDir.Text.Trim();
            if (dir.Length == 0) { MessageBox.Show("请选择安装位置"); return; }
            p1.Visible = false; p2.Visible = true;
            btnMain.Enabled = false; btnCancel.Enabled = false;
            Application.DoEvents();
            bar.Style = ProgressBarStyle.Marquee;
            string log;
            bool ok = Program.DoInstall(dir, out log);
            txtLog.Text = log;
            bar.Style = ProgressBarStyle.Continuous;
            bar.Value = 100;
            installed = true;
            btnMain.Enabled = true; btnCancel.Enabled = true;
            btnMain.Text = "完成";
            if (ok)
            {
                txtLog.AppendText("\r\n✅ 安装成功! 现在打开 CAD 即可使用, 输入 RCH 查看命令表。");
                MessageBox.Show("安装成功!\n\n打开 AutoCAD/中望/浩辰 即可自动加载。\n输入命令 RCH 查看全部绘图命令。",
                    "安装完成", MessageBoxButtons.OK, MessageBoxIcon.Information);
            }
            else
            {
                txtLog.AppendText("\r\n❌ 安装未完全成功, 请查看上方日志。");
            }
        }
    }
}
