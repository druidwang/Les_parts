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
            this.btnExit = new System.Windows.Forms.Button();
            this.btnLogOff = new System.Windows.Forms.Button();
            this.tbKeyCode = new System.Windows.Forms.TextBox();
            this.lblUserStatus = new System.Windows.Forms.Label();
            this.tabInventory = new System.Windows.Forms.TabPage();
            this.btnBindContainerOut = new System.Windows.Forms.Button();
            this.btnBindContainerIn = new System.Windows.Forms.Button();
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
            this.tabModuleSelect = new System.Windows.Forms.TabControl();
            this.tabProcurement = new System.Windows.Forms.TabPage();
            this.btnProductionReceive = new System.Windows.Forms.Button();
            this.btnPurchaseReturn = new System.Windows.Forms.Button();
            this.btnQuickReturn = new System.Windows.Forms.Button();
            this.btnPickListOnline = new System.Windows.Forms.Button();
            this.btnOrderShip = new System.Windows.Forms.Button();
            this.btnPickListShip = new System.Windows.Forms.Button();
            this.btnPickList = new System.Windows.Forms.Button();
            this.btnReceive = new System.Windows.Forms.Button();
            this.tabInventory.SuspendLayout();
            this.tabModuleSelect.SuspendLayout();
            this.tabProcurement.SuspendLayout();
            this.SuspendLayout();
            // 
            // btnExit
            // 
            this.btnExit.Location = new System.Drawing.Point(176, 266);
            this.btnExit.Name = "btnExit";
            this.btnExit.Size = new System.Drawing.Size(72, 20);
            this.btnExit.TabIndex = 2;
            this.btnExit.Text = "退出";
            this.btnExit.Click += new System.EventHandler(this.btnExit_Click);
            // 
            // btnLogOff
            // 
            this.btnLogOff.Location = new System.Drawing.Point(98, 266);
            this.btnLogOff.Name = "btnLogOff";
            this.btnLogOff.Size = new System.Drawing.Size(72, 20);
            this.btnLogOff.TabIndex = 1;
            this.btnLogOff.Text = "注销";
            this.btnLogOff.Click += new System.EventHandler(this.btnLogOff_Click);
            // 
            // tbKeyCode
            // 
            this.tbKeyCode.Location = new System.Drawing.Point(7, 263);
            this.tbKeyCode.Name = "tbKeyCode";
            this.tbKeyCode.Size = new System.Drawing.Size(81, 23);
            this.tbKeyCode.TabIndex = 3;
            this.tbKeyCode.KeyUp += new System.Windows.Forms.KeyEventHandler(this.tbKeyCode_KeyUp);
            // 
            // lblUserStatus
            // 
            this.lblUserStatus.Location = new System.Drawing.Point(12, 243);
            this.lblUserStatus.Name = "lblUserStatus";
            this.lblUserStatus.Size = new System.Drawing.Size(215, 17);
            this.lblUserStatus.Text = "当前用户:";
            // 
            // tabInventory
            // 
            this.tabInventory.Controls.Add(this.btnBindContainerOut);
            this.tabInventory.Controls.Add(this.btnBindContainerIn);
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
            this.tabInventory.Size = new System.Drawing.Size(233, 195);
            this.tabInventory.Text = "仓库";
            // 
            // btnBindContainerOut
            // 
            this.btnBindContainerOut.Location = new System.Drawing.Point(128, 150);
            this.btnBindContainerOut.Name = "btnBindContainerOut";
            this.btnBindContainerOut.Size = new System.Drawing.Size(98, 20);
            this.btnBindContainerOut.TabIndex = 12;
            this.btnBindContainerOut.Text = "12.托盘拆包";
            this.btnBindContainerOut.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnBindContainerOut.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnBindContainerIn
            // 
            this.btnBindContainerIn.Location = new System.Drawing.Point(15, 150);
            this.btnBindContainerIn.Name = "btnBindContainerIn";
            this.btnBindContainerIn.Size = new System.Drawing.Size(100, 20);
            this.btnBindContainerIn.TabIndex = 11;
            this.btnBindContainerIn.Text = "11.托盘打包";
            this.btnBindContainerIn.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnBindContainerIn.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnBinning
            // 
            this.btnBinning.Location = new System.Drawing.Point(15, 70);
            this.btnBinning.Name = "btnBinning";
            this.btnBinning.Size = new System.Drawing.Size(100, 20);
            this.btnBinning.TabIndex = 5;
            this.btnBinning.Text = "5.装箱";
            this.btnBinning.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnBinning.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnDevanning
            // 
            this.btnDevanning.Location = new System.Drawing.Point(128, 70);
            this.btnDevanning.Name = "btnDevanning";
            this.btnDevanning.Size = new System.Drawing.Size(98, 20);
            this.btnDevanning.TabIndex = 6;
            this.btnDevanning.Text = "6.拆箱";
            this.btnDevanning.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnDevanning.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnHuStatus
            // 
            this.btnHuStatus.Location = new System.Drawing.Point(128, 96);
            this.btnHuStatus.Name = "btnHuStatus";
            this.btnHuStatus.Size = new System.Drawing.Size(98, 20);
            this.btnHuStatus.TabIndex = 8;
            this.btnHuStatus.Text = "8.条码状态";
            this.btnHuStatus.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnHuStatus.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnHuClone
            // 
            this.btnHuClone.Location = new System.Drawing.Point(128, 122);
            this.btnHuClone.Name = "btnHuClone";
            this.btnHuClone.Size = new System.Drawing.Size(98, 20);
            this.btnHuClone.TabIndex = 10;
            this.btnHuClone.Text = "10.条码克隆";
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
            this.btnStockTaking.Size = new System.Drawing.Size(100, 20);
            this.btnStockTaking.TabIndex = 7;
            this.btnStockTaking.Text = "7.盘点";
            this.btnStockTaking.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnStockTaking.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnReBinning
            // 
            this.btnReBinning.Location = new System.Drawing.Point(128, 18);
            this.btnReBinning.Name = "btnReBinning";
            this.btnReBinning.Size = new System.Drawing.Size(98, 20);
            this.btnReBinning.TabIndex = 2;
            this.btnReBinning.Text = "2.翻箱";
            this.btnReBinning.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnReBinning.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPutAway
            // 
            this.btnPutAway.Location = new System.Drawing.Point(15, 44);
            this.btnPutAway.Name = "btnPutAway";
            this.btnPutAway.Size = new System.Drawing.Size(100, 20);
            this.btnPutAway.TabIndex = 3;
            this.btnPutAway.Text = "3.上架";
            this.btnPutAway.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPutAway.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPickUp
            // 
            this.btnPickUp.Location = new System.Drawing.Point(128, 44);
            this.btnPickUp.Name = "btnPickUp";
            this.btnPickUp.Size = new System.Drawing.Size(99, 20);
            this.btnPickUp.TabIndex = 4;
            this.btnPickUp.Text = "4.下架";
            this.btnPickUp.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPickUp.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnTransfer
            // 
            this.btnTransfer.Location = new System.Drawing.Point(15, 18);
            this.btnTransfer.Name = "btnTransfer";
            this.btnTransfer.Size = new System.Drawing.Size(100, 20);
            this.btnTransfer.TabIndex = 1;
            this.btnTransfer.Text = "1.移库";
            this.btnTransfer.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnTransfer.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // tabModuleSelect
            // 
            this.tabModuleSelect.Controls.Add(this.tabProcurement);
            this.tabModuleSelect.Controls.Add(this.tabInventory);
            this.tabModuleSelect.Location = new System.Drawing.Point(3, 13);
            this.tabModuleSelect.Name = "tabModuleSelect";
            this.tabModuleSelect.SelectedIndex = 0;
            this.tabModuleSelect.Size = new System.Drawing.Size(241, 224);
            this.tabModuleSelect.TabIndex = 0;
            this.tabModuleSelect.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            this.tabModuleSelect.SelectedIndexChanged += new System.EventHandler(this.tabModuleSelect_SelectedIndexChanged);
            // 
            // tabProcurement
            // 
            this.tabProcurement.Controls.Add(this.btnProductionReceive);
            this.tabProcurement.Controls.Add(this.btnPurchaseReturn);
            this.tabProcurement.Controls.Add(this.btnQuickReturn);
            this.tabProcurement.Controls.Add(this.btnPickListOnline);
            this.tabProcurement.Controls.Add(this.btnOrderShip);
            this.tabProcurement.Controls.Add(this.btnPickListShip);
            this.tabProcurement.Controls.Add(this.btnPickList);
            this.tabProcurement.Controls.Add(this.btnReceive);
            this.tabProcurement.Location = new System.Drawing.Point(4, 25);
            this.tabProcurement.Name = "tabProcurement";
            this.tabProcurement.Size = new System.Drawing.Size(233, 195);
            this.tabProcurement.Text = "收发";
            // 
            // btnProductionReceive
            // 
            this.btnProductionReceive.Location = new System.Drawing.Point(19, 51);
            this.btnProductionReceive.Name = "btnProductionReceive";
            this.btnProductionReceive.Size = new System.Drawing.Size(90, 20);
            this.btnProductionReceive.TabIndex = 10;
            this.btnProductionReceive.Text = "3.成品入库";
            this.btnProductionReceive.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnProductionReceive.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPurchaseReturn
            // 
            this.btnPurchaseReturn.Location = new System.Drawing.Point(123, 15);
            this.btnPurchaseReturn.Name = "btnPurchaseReturn";
            this.btnPurchaseReturn.Size = new System.Drawing.Size(90, 20);
            this.btnPurchaseReturn.TabIndex = 7;
            this.btnPurchaseReturn.Text = "2.采购退货";
            this.btnPurchaseReturn.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPurchaseReturn.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnQuickReturn
            // 
            this.btnQuickReturn.Location = new System.Drawing.Point(19, 86);
            this.btnQuickReturn.Name = "btnQuickReturn";
            this.btnQuickReturn.Size = new System.Drawing.Size(90, 20);
            this.btnQuickReturn.TabIndex = 6;
            this.btnQuickReturn.Text = "5.领料退库";
            this.btnQuickReturn.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnQuickReturn.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPickListOnline
            // 
            this.btnPickListOnline.Location = new System.Drawing.Point(123, 86);
            this.btnPickListOnline.Name = "btnPickListOnline";
            this.btnPickListOnline.Size = new System.Drawing.Size(90, 20);
            this.btnPickListOnline.TabIndex = 1;
            this.btnPickListOnline.Text = "6.拣货上线";
            this.btnPickListOnline.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPickListOnline.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnOrderShip
            // 
            this.btnOrderShip.Location = new System.Drawing.Point(123, 51);
            this.btnOrderShip.Name = "btnOrderShip";
            this.btnOrderShip.Size = new System.Drawing.Size(90, 20);
            this.btnOrderShip.TabIndex = 4;
            this.btnOrderShip.Text = "4.订单发货";
            this.btnOrderShip.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnOrderShip.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPickListShip
            // 
            this.btnPickListShip.Location = new System.Drawing.Point(123, 122);
            this.btnPickListShip.Name = "btnPickListShip";
            this.btnPickListShip.Size = new System.Drawing.Size(90, 20);
            this.btnPickListShip.TabIndex = 3;
            this.btnPickListShip.Text = "8.拣货发货";
            this.btnPickListShip.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPickListShip.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnPickList
            // 
            this.btnPickList.Location = new System.Drawing.Point(19, 122);
            this.btnPickList.Name = "btnPickList";
            this.btnPickList.Size = new System.Drawing.Size(90, 20);
            this.btnPickList.TabIndex = 2;
            this.btnPickList.Text = "7.拣货";
            this.btnPickList.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnPickList.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            // 
            // btnReceive
            // 
            this.btnReceive.Location = new System.Drawing.Point(19, 15);
            this.btnReceive.Name = "btnReceive";
            this.btnReceive.Size = new System.Drawing.Size(90, 20);
            this.btnReceive.TabIndex = 5;
            this.btnReceive.Text = "1.收货";
            this.btnReceive.Click += new System.EventHandler(this.UCModuleSelect_Click);
            this.btnReceive.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
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
            this.Size = new System.Drawing.Size(273, 289);
            this.KeyUp += new System.Windows.Forms.KeyEventHandler(this.UCModuleSelect_KeyUp);
            this.tabInventory.ResumeLayout(false);
            this.tabModuleSelect.ResumeLayout(false);
            this.tabProcurement.ResumeLayout(false);
            this.ResumeLayout(false);

        }

        #endregion

        private System.Windows.Forms.Button btnExit;
        private System.Windows.Forms.Button btnLogOff;
        private System.Windows.Forms.TextBox tbKeyCode;
        private System.Windows.Forms.Label lblUserStatus;
        private System.Windows.Forms.TabPage tabInventory;
        private System.Windows.Forms.Button btnBinning;
        private System.Windows.Forms.Button btnHuStatus;
        private System.Windows.Forms.Button btnHuClone;
        private System.Windows.Forms.Button btnMiscInOut;
        private System.Windows.Forms.Button btnStockTaking;
        private System.Windows.Forms.Button btnReBinning;
        private System.Windows.Forms.Button btnPutAway;
        private System.Windows.Forms.Button btnPickUp;
        private System.Windows.Forms.Button btnTransfer;
        private System.Windows.Forms.TabControl tabModuleSelect;
        private System.Windows.Forms.TabPage tabProcurement;
        private System.Windows.Forms.Button btnPurchaseReturn;
        private System.Windows.Forms.Button btnQuickReturn;
        private System.Windows.Forms.Button btnPickListOnline;
        private System.Windows.Forms.Button btnOrderShip;
        private System.Windows.Forms.Button btnPickListShip;
        private System.Windows.Forms.Button btnPickList;
        private System.Windows.Forms.Button btnReceive;
        private System.Windows.Forms.Button btnBindContainerOut;
        private System.Windows.Forms.Button btnBindContainerIn;
        private System.Windows.Forms.Button btnDevanning;
        private System.Windows.Forms.Button btnProductionReceive;
    }
}
