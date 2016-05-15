using System;
using System.Xml.Serialization;

namespace com.Sconit.Entity.MES
{
    [Serializable]
    public partial class MESScanControlPoint : EntityBase
    {
        #region O/R Mapping Properties

        [XmlIgnore]
        public Int32 Id { get; set; }
        public string TraceCode { get; set; }
        public string ProdItem { get; set; }
        public string Op { get; set; }
        public string OpReference { get; set; }
        public string ControlPoint { get; set; }
        public string ScanDate { get; set; }
        public string ScanTime { get; set; }

        [XmlIgnore]
        public DateTime CreateDate { get; set; }
        [XmlIgnore]
        public int Status { get; set; }
        [XmlIgnore]
        public string Note { get; set; }
        #endregion

        public override int GetHashCode()
        {
            if (Id != 0)
            {
                return Id.GetHashCode();
            }
            else
            {
                return base.GetHashCode();
            }
        }

        public override bool Equals(object obj)
        {
            MESScanControlPoint another = obj as MESScanControlPoint;

            if (another == null)
            {
                return false;
            }
            else
            {
                return (this.Id == another.Id);
            }
        }
    }

}