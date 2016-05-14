using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using NPOI.SS.UserModel;
using System.Collections;
using System.Xml;
using System.Web;
using System.Net;
using System.IO;



namespace com.Sconit.Utility
{
    public static class ObixHelper
    {

    
/// <summary>
        /// 通过 WebRequest/WebResponse 类访问远程地址并返回结果，需要Basic认证；
        /// 调用端自己处理异常
        /// </summary>
        /// <param name="uri"></param>
        /// <param name="timeout">访问超时时间，单位毫秒；如果不设置超时时间，传入0</param>
        /// <param name="encoding">如果不知道具体的编码，传入null</param>
        /// <param name="username"></param>
        /// <param name="password"></param>
        /// <returns></returns>
        public static string Request_WebRequest(string uri, int timeout, Encoding encoding, string username, string password)
        {
            string result = string.Empty;

            WebRequest request = WebRequest.Create(new Uri(uri));

            if (!string.IsNullOrEmpty(username) && !string.IsNullOrEmpty(password))
            {
                request.Credentials = GetCredentialCache(uri, username, password);
                request.Headers.Add("Authorization", GetAuthorization(username, password));
            }

            if (timeout > 0)
                request.Timeout = timeout;

            WebResponse response = request.GetResponse();
            Stream stream = response.GetResponseStream();
            StreamReader sr = encoding == null ? new StreamReader(stream) : new StreamReader(stream, encoding);

            string xmlValue = string.Empty;
             XmlDocument doc = new XmlDocument();
             doc.Load(sr);

             XmlElement root =  doc.DocumentElement;

             XmlNodeList listNodes = root.SelectNodes("/obj/ref/config");
             foreach (XmlNode node in listNodes )
            {
                xmlValue += node.InnerText + "\n";
             }

            result = sr.ReadToEnd();

            sr.Close();
            stream.Close();

            return result;
    
             }

        #region # 生成 Http Basic 访问凭证 #

        private static CredentialCache GetCredentialCache(string uri, string username, string password)
        {
            string authorization = string.Format("{0}:{1}", username, password);

            CredentialCache credCache = new CredentialCache();
            credCache.Add(new Uri(uri), "Basic", new NetworkCredential(username, password));

            return credCache;
        }

        private static string GetAuthorization(string username, string password)
        {
            string authorization = string.Format("{0}:{1}", username, password);

            return "Basic " + Convert.ToBase64String(new ASCIIEncoding().GetBytes(authorization));
        }

        #endregion



    }
}
