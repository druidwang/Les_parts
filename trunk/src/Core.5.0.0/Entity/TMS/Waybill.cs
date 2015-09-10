
using System;
using System.Collections.Generic;
using System.Linq;
using com.Sconit.Entity;
//TODO: Add other using statements here

namespace com.Sconit.Entity.TMS
{
    public partial class Waybill 
    {
        #region Non O/R Mapping Properties

        /// <summary>
        /// 提送费+其他服务费+装卸货费
        /// </summary>
        public decimal Fee
        {
            get
            {
                return (this.InOutFee.HasValue ? this.InOutFee.Value : 0)
                            + (this.SendFee.HasValue ? this.SendFee.Value : 0)
                            + (this.ServiceFee.HasValue ? this.ServiceFee.Value : 0);
            }
        }

        public string DriverName
        {
            get
            {
                if (string.IsNullOrEmpty(this.DriverDesc))
                {
                    return this.Driver;
                }
                else
                {
                    return this.DriverDesc;
                }
            }
        }
        public decimal Qty
        {
            get
            {
                if (!string.IsNullOrEmpty(this.FreightNo) || this.Type == TMSConstants.CODE_MASTER_TMS_TYPE_RST)
                {
                    return 1;
                }
                if (this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS)
                {
                    return 1;
                }
                else if (this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS_KM)
                {
                    return this.Km.HasValue && this.TonnageVolume.HasValue ? this.Km.Value * this.TonnageVolume.Value : 0;
                }
                else if (this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_STERE
                                    || this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_LADDERSTERE
                                    || this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS_LADDER
                                    || this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_BUS_STERE)
                {
                    return this.ActVolume;
                }
                else if (this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_KG)
                {
                    return this.ActWeight;
                }
                else if (this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_UOM)
                {
                    return this.ActUnitPack;
                }
                else if (this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_PALLET)
                {
                    return this.ActPalletQty;
                }
                else if (this.PricingMethod == TMSConstants.CODE_MASTER_TMS_PRICELIST_UNITPACK)
                {
                    return this.ActUnitPack;
                }
                /*
                else if (this.ActPalletQty.HasValue && this.PalletVolume.HasValue)
                {
                    return this.ActPalletQty.Value * this.PalletVolume.Value;
                }  */
                else
                {
                    return 0;
                }
            }
        }

        /// <summary>
        /// 载重率
        /// </summary>
        public decimal? ActWeightUtilization
        {
            get
            {
                if (!this.TonnageWeight.HasValue)
                {
                    return null;
                }
                else if (this.TonnageWeight.Value == 0)
                {
                    return 0;
                }
                else
                {
                    return ActWeight / TonnageWeight.Value;
                }
            }
        }

        public decimal? ActDutyCycle
        {
            get
            {
                if (!this.TonnageVolume.HasValue)
                {
                    return null;
                }
                else if (this.TonnageVolume.Value == 0)
                {
                    return 0;
                }
                else
                {
                    return (ActVolume + (this.ActVolume2.HasValue ? this.ActVolume2.Value : 0)) / TonnageVolume.Value;
                }
            }
        }

        public string CarrierName
        {
            get
            {
                return this.Carrier + "[" + this.CarrierDesc + "]";
            }
        }

        public string FlowName
        {
            get
            {
                if (String.IsNullOrEmpty(this.Flow)) return string.Empty;
                return this.Flow + "[" + this.FlowDesc + "]";
            }
        }

        public string ShipFromTo
        {
            get
            {
                return this.ShipFrom + "-" + this.ShipTo;
            }
        }

        public string ShipToName
        {
            get
            {
                return this.ShipTo + "[" + this.ShipToDesc + "]";
            }
        }

        public string ShipFromName
        {
            get
            {
                return this.ShipFrom + "[" + this.ShipFromDesc + "]";
            }
        }

        private IList<WaybillDet> _waybillDets;
        public IList<WaybillDet> WaybillDets
        {
            get
            {
                if (_waybillDets == null)
                {
                    _waybillDets = new List<WaybillDet>();
                }
                return _waybillDets;
            }
            set
            {
                _waybillDets = value;
            }
        }

        public decimal WaybillDetsPalletQty
        {
            get
            {
                return WaybillDets.Sum(d => d.PalletQty);
            }
        }
        public decimal WaybillDetsVolume
        {
            get
            {
                return WaybillDets.Sum(d => d.Volume);
            }
        }
        public decimal WaybillDetsUnitPack
        {
            get
            {
                return WaybillDets.Sum(d => d.UnitPack);
            }
        }
        public decimal WaybillDetsWeight
        {
            get
            {
                return WaybillDets.Sum(d => d.Weight);
            }
        }
        public void AddWaybillDet(WaybillDet waybillDet)
        {
            if (this.WaybillDets == null)
            {
                this.WaybillDets = new List<WaybillDet>();
                this.WaybillDets.Add(waybillDet);
            }
            else
            {
                //查找Sequence，插入到合适位置
                int position = this.WaybillDets.Count;
                for (int i = 0; i < this.WaybillDets.Count; i++)
                {
                    WaybillDet od = this.WaybillDets[i];
                    if (od.Seq > waybillDet.Seq)
                    {
                        position = i;
                        break;
                    }
                }
                this.WaybillDets.Insert(position, waybillDet);
            }
        }
        public WaybillDet GetWaybillDetById(int id)
        {
            if (this.WaybillDets != null)
            {
                int rowIndex = -1;
                for (int i = 0; i < this.WaybillDets.Count; i++)
                {
                    if (this.WaybillDets[i].Id == id)
                    {
                        rowIndex = i;
                        break;
                    }
                }

                if (rowIndex > -1)
                {
                    return this.WaybillDets[rowIndex];
                }
            }

            return null;
        }

        public void RemoveWaybillDetById(int id)
        {
            if (this.WaybillDets != null)
            {
                int rowIndex = -1;
                for (int i = 0; i < this.WaybillDets.Count; i++)
                {
                    if (this.WaybillDets[i].Id == id)
                    {
                        rowIndex = i;
                        break;
                    }
                }

                if (rowIndex > -1)
                {
                    this.WaybillDets.RemoveAt(rowIndex);
                }
            }
        }

        public void RemoveWaybillDetByRowIndex(int rowIndex)
        {
            if (this.WaybillDets != null)
            {
                this.WaybillDets.RemoveAt(rowIndex);
            }
        }

        public void RemoveWaybillDetBySequence(int sequence)
        {
            if (this.WaybillDets != null)
            {
                int rowIndex = -1;
                for (int i = 0; i < this.WaybillDets.Count; i++)
                {
                    if (this.WaybillDets[i].Seq == sequence)
                    {
                        rowIndex = i;
                        break;
                    }
                }

                if (rowIndex > -1)
                {
                    this.WaybillDets.RemoveAt(rowIndex);
                }
            }
        }
        #endregion
    }
}