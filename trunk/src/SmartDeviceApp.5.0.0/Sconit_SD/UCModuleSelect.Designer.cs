using System.Linq;
namespace com.Sconit.SmartDevice
{
    partial class UCModuleSelect
    {
        /// <summary> 
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary> 
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Component Designer generated code

        /// <summary> 
        /// Required method for Designer support - do not modify 
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.tabModuleSelect = new System.Windows.Forms.TabControl();
            this.tabProcurement = new System.Windows.Forms.TabPage();
            this.btnQuickReturn = new System.Windows.Forms.Button();
            this.btnPickListOnline = new System.Windows.Forms.Button();
            this.btnOrderShip = new System.Windows.Forms.Button();
            this.btnPickListShip = new System.Windows.Forms.Button();
            this.btnPickList = new System.Windows.Forms.Button();
            this.btnReceive = new System.Windows.Forms.Button();
            this.tabProduction = new System.Windows.Forms.TabPage();
            this.btnAnDon = new System.Windows.Forms.Button();
            this.btnMaterialIn = new System.Windows.Forms.Button();
            this.btnFiReceipt = new System.Windows.Forms.Button();
            this.btnAging = new System.Windows.Forms.Button();
            this.btnStartAging = new System.Windows.Forms.Button();
            this.btnProdutionOffline = new System.Windows.Forms.Button();
            this.btnForceMaterialIn = new System.Windows.Forms.Button();
            this.btnFilter = new System.Windows.Forms.Button();
            this.btnMaterialReturn = new System.Windows.Forms.Button();
            this.btnProductionOnline = new System.Windows.Forms.Button();
            this.tabInventory = new System.Windows.Forms.TabPage();
            this.btnBinning = new System.Windows.Forms.Button();
            this.btnDevanning = new System.Windows.Forms.Button();
            this.btnHuStatus = new System.Windows.Forms.Button();
            this.btnHuClone = new System.Windows.Forms.Button();
            this.btnMiscInOut = new System.Windows.Forms.Button();
            this.btnStockTaking = new System.Windows.Forms.Button();
            this.btnReBinning = new System.Windows.Forms.Button();
            this.btnPutAway = new System.Windows.Forms.Button();
            this.btnPickUp = new System.Windows.Forms.Button();
            this.btnTransfer = new System.Windows.Forms.Button();
            this.tabQuality = new System.Windows.Forms.TabPage();
            this.btnFreeze = new System.Windows.Forms.Button();
            this.btnUnfreeze = new System.Windows.Forms.Button();
            this.btnInspect = new System.Windows.Forms.Button();
            this.btnQualify = new System.Windows.Forms.Button();
            this.btnExit = new System.Windows.Forms.Button();
            this.btnLogOff = new System.Windows.Forms.Button();
            this.tbKeyCode = new System.Windows.Forms.TextBox();
            this.lblUserStatus = new System.Windows.Forms.Label();
            this.btnSpChk = new System.Windows.Forms.Button();
            this.tabModuleSelect.SuspendLayout();
            this.tabProcurement.SuspendLayout();
            this.tabProduction.SuspendLayout();
            this.tabInventory.SuspendLayout();
            this.tabQuality.SuspendLayout();
            this.SuspendLayout();
            // 
            // tabModuleSelect
            // 
            this.tabModuleSelect.Controls.Add(this.tabProcurement);
            this.tabModuleSelect.Controls.Add(this.tabProduction);
            this.tabModuleSelect.Controls.Add(this.tabInventory);
            this.tabModuleSelect.Controls.Add(this.tabQuality);
            this.tabModuleSelect.Location = new System.Drawing.Point(3, 13);
            this.tabModuleSelect.Name = "tabModuleSelect";
            this.tabModuleSelect.SelectedIndex = 0;
            this.tabModuleSelect.Size = new System.Drawing.Size(234, 224);
            this.tabModuleSelect.TabIndex = 0;
            this.tabModuleSelect.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            this.tabModuleSelect.SelectedIndexChanged += new System.EventHandler(this.tabModuleSelect_SelectedIndexChanged);
            // 
            // tabProcurement
            // 
            this.tabProcurement.Controls.Add(this.btnQuickReturn);
            this.tabProcurement.Controls.Add(this.btnPickListOnline);
            this.tabProcurement.Controls.Add(this.btnOrderShip);
            this.tabProcurement.Controls.Add(this.btnPickListShip);
            this.tabProcurement.Controls.Add(this.btnPickList);
            this.tabProcurement.Controls.Add(this.btnReceive);
            this.tabProcurement.Location = new System.Drawing.Point(4, 25);
            this.tabProcurement.Name = "tabProcurement";
            this.tabProcurement.Size = new System.Drawing.Size(226, 195);
            this.tabProcurement.Text = "收发";
            // 
            // btnQuickReturn
            // 
            this.btnQuickReturn.Location = new System.Drawing.Point(115, 70);
            this.btnQuickReturn.Name = "btnQuickReturn";
            this.btnQuickReturn.Size = new System.Drawing.Size(90, 20);
            this.btnQuickReturn.TabIndex = 6;
            this.btnQuickReturn.Text = "6.领料退库";
            this.btnQuickReturn.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnQuickReturn.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPickListOnline
            // 
            this.btnPickListOnline.Location = new System.Drawing.Point(19, 18);
            this.btnPickListOnline.Name = "btnPickListOnline";
            this.btnPickListOnline.Size = new System.Drawing.Size(90, 20);
            this.btnPickListOnline.TabIndex = 1;
            this.btnPickListOnline.Text = "1.拣货上线";
            this.btnPickListOnline.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPickListOnline.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnOrderShip
            // 
            this.btnOrderShip.Location = new System.Drawing.Point(115, 44);
            this.btnOrderShip.Name = "btnOrderShip";
            this.btnOrderShip.Size = new System.Drawing.Size(90, 20);
            this.btnOrderShip.TabIndex = 4;
            this.btnOrderShip.Text = "4.订单发货";
            this.btnOrderShip.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnOrderShip.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPickListShip
            // 
            this.btnPickListShip.Location = new System.Drawing.Point(19, 44);
            this.btnPickListShip.Name = "btnPickListShip";
            this.btnPickListShip.Size = new System.Drawing.Size(90, 20);
            this.btnPickListShip.TabIndex = 3;
            this.btnPickListShip.Text = "3.拣货发货";
            this.btnPickListShip.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPickListShip.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPickList
            // 
            this.btnPickList.Location = new System.Drawing.Point(115, 18);
            this.btnPickList.Name = "btnPickList";
            this.btnPickList.Size = new System.Drawing.Size(90, 20);
            this.btnPickList.TabIndex = 2;
            this.btnPickList.Text = "2.拣货";
            this.btnPickList.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPickList.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnReceive
            // 
            this.btnReceive.Location = new System.Drawing.Point(19, 70);
            this.btnReceive.Name = "btnReceive";
            this.btnReceive.Size = new System.Drawing.Size(90, 20);
            this.btnReceive.TabIndex = 5;
            this.btnReceive.Text = "5.收货";
            this.btnReceive.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnReceive.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // tabProduction
            // 
            this.tabProduction.Controls.Add(this.btnSpChk);
            this.tabProduction.Controls.Add(this.btnAnDon);
            this.tabProduction.Controls.Add(this.btnMaterialIn);
            this.tabProduction.Controls.Add(this.btnFiReceipt);
            this.tabProduction.Controls.Add(this.btnAging);
            this.tabProduction.Controls.Add(this.btnStartAging);
            this.tabProduction.Controls.Add(this.btnProdutionOffline);
            this.tabProduction.Controls.Add(this.btnForceMaterialIn);
            this.tabProduction.Controls.Add(this.btnFilter);
            this.tabProduction.Controls.Add(this.btnMaterialReturn);
            this.tabProduction.Controls.Add(this.btnProductionOnline);
            this.tabProduction.Location = new System.Drawing.Point(4, 25);
            this.tabProduction.Name = "tabProduction";
            this.tabProduction.Size = new System.Drawing.Size(226, 195);
            this.tabProduction.Text = "生产";
            // 
            // btnAnDon
            // 
            this.btnAnDon.Enabled = false;
            this.btnAnDon.Location = new System.Drawing.Point(112, 147);
            this.btnAnDon.Name = "btnAnDon";
            this.btnAnDon.Size = new System.Drawing.Size(90, 20);
            this.btnAnDon.TabIndex = 6;
            this.btnAnDon.Text = "6.按灯";
            this.btnAnDon.Visible = false;
            this.btnAnDon.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnAnDon.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnMaterialIn
            // 
            this.btnMaterialIn.Enabled = false;
            this.btnMaterialIn.Location = new System.Drawing.Point(16, 121);
            this.btnMaterialIn.Name = "btnMaterialIn";
            this.btnMaterialIn.Size = new System.Drawing.Size(90, 20);
            this.btnMaterialIn.TabIndex = 3;
            this.btnMaterialIn.Text = "3.投料";
            this.btnMaterialIn.Visible = false;
            this.btnMaterialIn.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnMaterialIn.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnFiReceipt
            // 
            this.btnFiReceipt.Location = new System.Drawing.Point(16, 69);
            this.btnFiReceipt.Name = "btnFiReceipt";
            this.btnFiReceipt.Size = new System.Drawing.Size(186, 20);
            this.btnFiReceipt.TabIndex = 3;
            this.btnFiReceipt.Text = "0.后加工生产收货";
            this.btnFiReceipt.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnFiReceipt.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnAging
            // 
            this.btnAging.Location = new System.Drawing.Point(112, 43);
            this.btnAging.Name = "btnAging";
            this.btnAging.Size = new System.Drawing.Size(90, 20);
            this.btnAging.TabIndex = 3;
            this.btnAging.Text = "3.老化结束";
            this.btnAging.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnAging.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnStartAging
            // 
            this.btnStartAging.Location = new System.Drawing.Point(16, 43);
            this.btnStartAging.Name = "btnStartAging";
            this.btnStartAging.Size = new System.Drawing.Size(90, 20);
            this.btnStartAging.TabIndex = 2;
            this.btnStartAging.Text = "2.老化开始";
            this.btnStartAging.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnStartAging.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnProdutionOffline
            // 
            this.btnProdutionOffline.Enabled = false;
            this.btnProdutionOffline.Location = new System.Drawing.Point(111, 95);
            this.btnProdutionOffline.Name = "btnProdutionOffline";
            this.btnProdutionOffline.Size = new System.Drawing.Size(90, 20);
            this.btnProdutionOffline.TabIndex = 12;
            this.btnProdutionOffline.Text = "2.下线";
            this.btnProdutionOffline.Visible = false;
            this.btnProdutionOffline.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnProdutionOffline.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnForceMaterialIn
            // 
            this.btnForceMaterialIn.Enabled = false;
            this.btnForceMaterialIn.Location = new System.Drawing.Point(16, 147);
            this.btnForceMaterialIn.Name = "btnForceMaterialIn";
            this.btnForceMaterialIn.Size = new System.Drawing.Size(89, 20);
            this.btnForceMaterialIn.TabIndex = 5;
            this.btnForceMaterialIn.Text = "5.强制投料";
            this.btnForceMaterialIn.Visible = false;
            this.btnForceMaterialIn.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnForceMaterialIn.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnFilter
            // 
            this.btnFilter.Location = new System.Drawing.Point(16, 18);
            this.btnFilter.Name = "btnFilter";
            this.btnFilter.Size = new System.Drawing.Size(90, 20);
            this.btnFilter.TabIndex = 1;
            this.btnFilter.Text = "1.过滤";
            this.btnFilter.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnFilter.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnMaterialReturn
            // 
            this.btnMaterialReturn.Enabled = false;
            this.btnMaterialReturn.Location = new System.Drawing.Point(112, 121);
            this.btnMaterialReturn.Name = "btnMaterialReturn";
            this.btnMaterialReturn.Size = new System.Drawing.Size(89, 20);
            this.btnMaterialReturn.TabIndex = 4;
            this.btnMaterialReturn.Text = "4.退料";
            this.btnMaterialReturn.Visible = false;
            this.btnMaterialReturn.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnMaterialReturn.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnProductionOnline
            // 
            this.btnProductionOnline.Enabled = false;
            this.btnProductionOnline.Location = new System.Drawing.Point(16, 95);
            this.btnProductionOnline.Name = "btnProductionOnline";
            this.btnProductionOnline.Size = new System.Drawing.Size(90, 20);
            this.btnProductionOnline.TabIndex = 11;
            this.btnProductionOnline.Text = "1.上线";
            this.btnProductionOnline.Visible = false;
            this.btnProductionOnline.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnProductionOnline.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // tabInventory
            // 
            this.tabInventory.Controls.Add(this.btnBinning);
            this.tabInventory.Controls.Add(this.btnDevanning);
            this.tabInventory.Controls.Add(this.btnHuStatus);
            this.tabInventory.Controls.Add(this.btnHuClone);
            this.tabInventory.Controls.Add(this.btnMiscInOut);
            this.tabInventory.Controls.Add(this.btnStockTaking);
            this.tabInventory.Controls.Add(this.btnReBinning);
            this.tabInventory.Controls.Add(this.btnPutAway);
            this.tabInventory.Controls.Add(this.btnPickUp);
            this.tabInventory.Controls.Add(this.btnTransfer);
            this.tabInventory.Location = new System.Drawing.Point(4, 25);
            this.tabInventory.Name = "tabInventory";
            this.tabInventory.Size = new System.Drawing.Size(226, 195);
            this.tabInventory.Text = "仓库";
            // 
            // btnBinning
            // 
            this.btnBinning.Location = new System.Drawing.Point(15, 70);
            this.btnBinning.Name = "btnBinning";
            this.btnBinning.Size = new System.Drawing.Size(90, 20);
            this.btnBinning.TabIndex = 5;
            this.btnBinning.Text = "5.装箱";
            this.btnBinning.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnBinning.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnDevanning
            // 
            this.btnDevanning.Location = new System.Drawing.Point(121, 70);
            this.btnDevanning.Name = "btnDevanning";
            this.btnDevanning.Size = new System.Drawing.Size(100, 20);
            this.btnDevanning.TabIndex = 6;
            if (user.Permissions.ToList().Select(p => p.PermissionCode).Contains("Client_UnPackAllowCs"))
            {
                this.btnDevanning.Text = "6.拆箱含寄售";
            }
            else
            {
                this.btnDevanning.Text = "6.拆箱不含寄售";
            }
            this.btnDevanning.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnDevanning.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnHuStatus
            // 
            this.btnHuStatus.Location = new System.Drawing.Point(121, 96);
            this.btnHuStatus.Name = "btnHuStatus";
            this.btnHuStatus.Size = new System.Drawing.Size(90, 20);
            this.btnHuStatus.TabIndex = 8;
            this.btnHuStatus.Text = "8.条码状态";
            this.btnHuStatus.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnHuStatus.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnHuClone
            // 
            this.btnHuClone.Location = new System.Drawing.Point(121, 122);
            this.btnHuClone.Name = "btnHuClone";
            this.btnHuClone.Size = new System.Drawing.Size(90, 20);
            this.btnHuClone.TabIndex = 10;
            this.btnHuClone.Text = "0.条码克隆";
            this.btnHuClone.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnHuClone.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnMiscInOut
            // 
            this.btnMiscInOut.Location = new System.Drawing.Point(15, 122);
            this.btnMiscInOut.Name = "btnMiscInOut";
            this.btnMiscInOut.Size = new System.Drawing.Size(100, 20);
            this.btnMiscInOut.TabIndex = 9;
            this.btnMiscInOut.Text = "9.计划外出入";
            this.btnMiscInOut.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnMiscInOut.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnStockTaking
            // 
            this.btnStockTaking.Location = new System.Drawing.Point(15, 96);
            this.btnStockTaking.Name = "btnStockTaking";
            this.btnStockTaking.Size = new System.Drawing.Size(90, 20);
            this.btnStockTaking.TabIndex = 7;
            this.btnStockTaking.Text = "7.盘点";
            this.btnStockTaking.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnStockTaking.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnReBinning
            // 
            this.btnReBinning.Location = new System.Drawing.Point(121, 18);
            this.btnReBinning.Name = "btnReBinning";
            this.btnReBinning.Size = new System.Drawing.Size(90, 20);
            this.btnReBinning.TabIndex = 2;
            this.btnReBinning.Text = "2.翻箱";
            this.btnReBinning.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnReBinning.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPutAway
            // 
            this.btnPutAway.Location = new System.Drawing.Point(15, 44);
            this.btnPutAway.Name = "btnPutAway";
            this.btnPutAway.Size = new System.Drawing.Size(90, 20);
            this.btnPutAway.TabIndex = 3;
            this.btnPutAway.Text = "3.上架";
            this.btnPutAway.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPutAway.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPickUp
            // 
            this.btnPickUp.Location = new System.Drawing.Point(121, 44);
            this.btnPickUp.Name = "btnPickUp";
            this.btnPickUp.Size = new System.Drawing.Size(90, 20);
            this.btnPickUp.TabIndex = 4;
            this.btnPickUp.Text = "4.下架";
            this.btnPickUp.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPickUp.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnTransfer
            // 
            this.btnTransfer.Location = new System.Drawing.Point(15, 18);
            this.btnTransfer.Name = "btnTransfer";
            this.btnTransfer.Size = new System.Drawing.Size(90, 20);
            this.btnTransfer.TabIndex = 1;
            this.btnTransfer.Text = "1.移库";
            this.btnTransfer.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnTransfer.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // tabQuality
            // 
            this.tabQuality.Controls.Add(this.btnFreeze);
            this.tabQuality.Controls.Add(this.btnUnfreeze);
            this.tabQuality.Controls.Add(this.btnInspect);
            this.tabQuality.Controls.Add(this.btnQualify);
            this.tabQuality.Location = new System.Drawing.Point(4, 25);
            this.tabQuality.Name = "tabQuality";
            this.tabQuality.Size = new System.Drawing.Size(226, 195);
            this.tabQuality.Text = "质量";
            // 
            // btnFreeze
            // 
            this.btnFreeze.Location = new System.Drawing.Point(15, 44);
            this.btnFreeze.Name = "btnFreeze";
            this.btnFreeze.Size = new System.Drawing.Size(90, 20);
            this.btnFreeze.TabIndex = 3;
            this.btnFreeze.Text = "3.冻结";
            this.btnFreeze.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnFreeze.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnUnfreeze
            // 
            this.btnUnfreeze.Location = new System.Drawing.Point(121, 44);
            this.btnUnfreeze.Name = "btnUnfreeze";
            this.btnUnfreeze.Size = new System.Drawing.Size(90, 20);
            this.btnUnfreeze.TabIndex = 4;
            this.btnUnfreeze.Text = "4.解冻";
            this.btnUnfreeze.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnUnfreeze.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnInspect
            // 
            this.btnInspect.Location = new System.Drawing.Point(15, 18);
            this.btnInspect.Name = "btnInspect";
            this.btnInspect.Size = new System.Drawing.Size(90, 20);
            this.btnInspect.TabIndex = 1;
            this.btnInspect.Text = "1.报验";
            this.btnInspect.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnInspect.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnQualify
            // 
            this.btnQualify.Location = new System.Drawing.Point(121, 18);
            this.btnQualify.Name = "btnQualify";
            this.btnQualify.Size = new System.Drawing.Size(90, 20);
            this.btnQualify.TabIndex = 2;
            this.btnQualify.Text = "2.判定";
            this.btnQualify.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnQualify.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnExit
            // 
            this.btnExit.Location = new System.Drawing.Point(159, 266);
            this.btnExit.Name = "btnExit";
            this.btnExit.Size = new System.Drawing.Size(72, 20);
            this.btnExit.TabIndex = 2;
            this.btnExit.Text = "退出";
            this.btnExit.Click += new System.EventHandler(this.btnExit_Click);
            // 
            // btnLogOff
            // 
            this.btnLogOff.Location = new System.Drawing.Point(81, 266);
            this.btnLogOff.Name = "btnLogOff";
            this.btnLogOff.Size = new System.Drawing.Size(72, 20);
            this.btnLogOff.TabIndex = 1;
            this.btnLogOff.Text = "注销";
            this.btnLogOff.Click += new System.EventHandler(this.btnLogOff_Click);
            // 
            // tbKeyCode
            // 
            this.tbKeyCode.Location = new System.Drawing.Point(7, 266);
            this.tbKeyCode.Name = "tbKeyCode";
            this.tbKeyCode.Size = new System.Drawing.Size(51, 23);
            this.tbKeyCode.TabIndex = 3;
            this.tbKeyCode.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tbKeyCode_KeyUp);
            // 
            // lblUserStatus
            // 
            this.lblUserStatus.Location = new System.Drawing.Point(12, 243);
            this.lblUserStatus.Name = "lblUserStatus";
            this.lblUserStatus.Size = new System.Drawing.Size(215, 20);
            this.lblUserStatus.Text = "当前用户:";
            // 
            // btnSpChk
            // 
            this.btnSpChk.Location = new System.Drawing.Point(16, 95);
            this.btnSpChk.Name = "btnSpChk";
            this.btnSpChk.Size = new System.Drawing.Size(98, 20);
            this.btnSpChk.TabIndex = 13;
            this.btnSpChk.Text = "4.小料配料检查";
            this.btnSpChk.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnSpChk.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // UCModuleSelect
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(96F, 96F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Dpi;
            this.Controls.Add(this.lblUserStatus);
            this.Controls.Add(this.tbKeyCode);
            this.Controls.Add(this.btnLogOff);
            this.Controls.Add(this.btnExit);
            this.Controls.Add(this.tabModuleSelect);
            this.Name = "UCModuleSelect";
            this.Size = new System.Drawing.Size(240, 295);
            this.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            this.tabModuleSelect.ResumeLayout(false);
            this.tabProcurement.ResumeLayout(false);
            this.tabProduction.ResumeLayout(false);
            this.tabInventory.ResumeLayout(false);
            this.tabQuality.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.TabControl tabModuleSelect;
        private System.Windows.Forms.TabPage tabProcurement;
        private System.Windows.Forms.TabPage tabInventory;
        private System.Windows.Forms.Button btnReceive;
        private System.Windows.Forms.Button btnStockTaking;
        private System.Windows.Forms.Button btnReBinning;
        private System.Windows.Forms.Button btnPutAway;
        private System.Windows.Forms.Button btnPickUp;
        private System.Windows.Forms.Button btnTransfer;
        private System.Windows.Forms.Button btnExit;
        private System.Windows.Forms.TabPage tabProduction;
        private System.Windows.Forms.Button btnHuStatus;
        private System.Windows.Forms.Button btnMaterialIn;
        private System.Windows.Forms.Button btnProdutionOffline;
        private System.Windows.Forms.Button btnProductionOnline;
        private System.Windows.Forms.Button btnBinning;
        private System.Windows.Forms.Button btnDevanning;
        private System.Windows.Forms.Button btnLogOff;
        private System.Windows.Forms.Button btnPickListOnline;
        private System.Windows.Forms.Button btnOrderShip;
        private System.Windows.Forms.Button btnQuickReturn;
        private System.Windows.Forms.Button btnPickListShip;
        private System.Windows.Forms.Button btnPickList;
        private System.Windows.Forms.Button btnAnDon;
        private System.Windows.Forms.TabPage tabQuality;
        private System.Windows.Forms.Button btnInspect;
        private System.Windows.Forms.Button btnQualify;
        private System.Windows.Forms.Button btnMaterialReturn;
        private System.Windows.Forms.Button btnHuClone;
        private System.Windows.Forms.Button btnMiscInOut;
        private System.Windows.Forms.Button btnFreeze;
        private System.Windows.Forms.Button btnUnfreeze;
        private System.Windows.Forms.Button btnForceMaterialIn;
        private System.Windows.Forms.Button btnFiReceipt;
        private System.Windows.Forms.Button btnStartAging;
        private System.Windows.Forms.Button btnFilter;
        private System.Windows.Forms.TextBox tbKeyCode;
        private System.Windows.Forms.Button btnAging;
        private System.Windows.Forms.Label lblUserStatus;
        private System.Windows.Forms.Button btnSpChk;
    }
}
