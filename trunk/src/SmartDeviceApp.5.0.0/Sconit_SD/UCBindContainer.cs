using System;
using System.Linq;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Text;
using System.Windows.Forms;
using com.Sconit.SmartDevice.SmartDeviceRef;

namespace com.Sconit.SmartDevice
{
    public partial class UCBindContainer : UCBase
    {
        private ContainerDetail _containerDetail;
        private bool _isIn = false;
        private static UCBindContainer _ucBindContainer;
        private static object obj = new object();


        public UCBindContainer(User user, bool isIn)
            : base(user)
        {
            this._isIn = isIn;
            this.InitializeComponent();
            base.btnOrder.Text = "OK";
            this.Reset();
        }

        public static UCBindContainer GetUCBindContainer(User user, bool isIn)
        {
            if (_ucBindContainer == null)
            {
                lock (obj)
                {
                    if (_ucBindContainer == null)
                    {
                        _ucBindContainer = new UCBindContainer(user, isIn);
                    }
                }
            }
            _ucBindContainer.user = user;
            _ucBindContainer.Reset();
            return _ucBindContainer;
        }


        protected override void ScanBarCode()
        {
            string barCode = this.tbBarCode.Text.Trim();
            this.tbBarCode.Focus();
            this.tbBarCode.Text = string.Empty;
            string op = Utility.GetBarCodeType(this.user.BarCodeTypes, barCode);

            if (barCode.Length < 3)
            {
                throw new BusinessException("条码格式不合法");
            }

            if (this._containerDetail == null && !this.isCancel)
            {
                if (op == CodeMaster.BarCodeType.COT.ToString())
                {
                    this._containerDetail = smartDeviceService.GetContainerDetail(barCode);
                    if (this._containerDetail == null)
                    {
                        throw new BusinessException("扫描的容器不存在");
                    }
                    else
                    {
                        this.lblMessage.Text = "请扫描物料条码";
                        this.lblMessage.ForeColor = Color.Black;
                    }
                }
                else
                {
                    throw new BusinessException("请先扫描容器条码");
                }
            }
            else if (!this.isCancel)
            {
                if (op == CodeMaster.BarCodeType.HU.ToString())
                {
                    Hu hu = this.smartDeviceService.GetHu(barCode);
                    if (hu == null)
                    {
                        throw new BusinessException("此条码不存在");
                    }
                    else if (hu.Status != HuStatus.Location)
                    {
                        throw new BusinessException("条码不在库存中,不能装入容器");
                    }
                    else if(hu.IsFreeze)
                    {
                        throw new BusinessException("条码被冻结,不能装入容器");
                    }
                    else if (hu.OccupyType != OccupyType.None)
                    {
                        throw new BusinessException("条码被{0}占用!", hu.OccupyReferenceNo);
                    }
                    else
                    {
                        var isHuInContainer = smartDeviceService.IsHuInContainer(hu.HuId);
                        if (this._isIn == true)
                        {
                            if (isHuInContainer == true)
                            {
                                throw new BusinessException("条码已在容器中!");
                            }
                            this.smartDeviceService.ContainerBind(this._containerDetail.ContainerId, hu.HuId, this.user.Code);
                        }
                        else
                        { 
                            //如果是拆，检查条码是否是在容器中
                            if (isHuInContainer == false)
                            {
                                throw new BusinessException("条码未在容器中!");
                            }
                            this.smartDeviceService.ContainerUnBind(this._containerDetail.ContainerId, hu.HuId, this.user.Code);
                        }
                        //hus.Add(hu);
                        
                        this.isCancel = false;
                    }
                }
                else
                {
                    throw new BusinessException("条码格式不合法");
                }
            }
            else
            {
                if (op == CodeMaster.BarCodeType.HU.ToString())
                {
                    if (hus.Where(h => h.HuId == barCode).ToList().Count > 0)
                    {
                        this.hus = this.hus.Where(h => h.HuId != barCode).ToList();
                        base.gvHuListDataBind();
                    }
                    else
                    {
                        throw new BusinessException("条码{0}未扫入不需取消", barCode);
                    }
                }
            }
            this.gvHuListDataBind();
        }

        protected override void gvHuListDataBind()
        {
            if(this._containerDetail != null)
            {
                this.hus = smartDeviceService.GetContainerHu(this._containerDetail.ContainerId).ToList();
            }
            base.gvHuListDataBind();
        }

        private void btnOrder_Click(object sender, EventArgs e)
        {
            this.tbBarCode_KeyUp(null, null);
        }

        protected override void DoSubmit()
        {
            this.Reset();
            //if (hus.Equals(null))
            //{
            //    throw new BusinessException("未扫入物料条码,不可以提交");
            //}

            //smartDeviceService.BatchUpdateMiscOrderDetails(this.miscOrderMaster.MiscOrderNo, hus.Select(h => h.HuId).ToArray(),this.user.Code);
            //this.Reset();
            //this.lblMessage.ForeColor = Color.Green;
            //this.lblMessage.Text = "出库成功";
            //this.isMark = true;
        }

        protected override Hu DoCancel()
        {
            if (this.hus == null || this.hus.Count == 0)
            {
                this.Reset();
                return null;
            }

            Hu firstHu = hus.First();
            this.lblMessage.Text = "已取消条码:" + firstHu.HuId;
            this.lblMessage.ForeColor = Color.Red;
            hus.Remove(firstHu);
            this.gvHuListDataBind();

            return firstHu;
        }

        protected override void Reset()
        {
            this.hus = new List<Hu>();
            this._containerDetail = null;
            base.lblMessage.Text = "请扫描容器条码";
            base.lblMessage.ForeColor = Color.Black;
            //this.lblMessage.Text = string.Empty;
            this.tbBarCode.Text = string.Empty;
            this.isCancel = false;
            this.isMasterBind = true;
            this.lblBarCode.ForeColor = Color.Black;
            this.gvHuListDataBind();
            this.tbBarCode.Focus();
        }
    }
}
