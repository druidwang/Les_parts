using System;
using System.Collections.Generic;

using System.Text;
using System.Reflection;
using System.IO;
using System.Web;

namespace com.Sconit.Utility
{
    /// <summary>
    /// 通用方法类
    /// </summary>
    public class LoadFunctions
    {

        private static string m_AssemblyDirectory = null;
        /// <summary>
        /// 获得运行exe或dll的目录
        /// </summary>
        /// <returns>返回目录字符串</returns>
        public static string AssemblyDirectory
        {
            get
            {
                if (string.IsNullOrEmpty(m_AssemblyDirectory))
                {
                    string binPath;
                    HttpContext context = HttpContext.Current;
                    if (context != null)
                    {
                        binPath = context.Server.MapPath("/bin/");
                    }
                    else
                    {
                        Assembly assembly = Assembly.GetCallingAssembly();
                        FileInfo AssemblyFileInfo = new FileInfo(assembly.Location);
                        binPath = AssemblyFileInfo.DirectoryName;
                    }
                    m_AssemblyDirectory = binPath;
                }
                return m_AssemblyDirectory;
            }
        }

        /// <summary>
        /// 加载<see cref="filename"/>应用程序集
        /// </summary>
        /// <param name="filename"></param>
        /// <param name="shadow">加载影子dll</param>
        public static Assembly GetAssembly(
            string filename,
            bool shadow = true
        )
        {

            string allFileName = LoadFunctions.AssemblyDirectory + filename;
            Assembly assembly;
            if (!shadow)
            {
                assembly = Assembly.LoadFile(allFileName);
            }
            else
            {
                string dllName = allFileName.Remove(allFileName.LastIndexOf("."));
                assembly = Assembly.Load(dllName);
            }

            return assembly;
        }
        /// <summary>
        /// 加载<see cref="path"/>目录下的应用程序集
        /// </summary>
        /// <param name="load">加载动作</param>
        /// <param name="pattern">扩展名</param>
        /// <param name="path">指定加载的目录，默认是运行目录</param>
        /// <param name="except">排除一些程序集的方法</param>      
        /// <param name="shadow">加载影子dll</param>
        /// <param name="doError">加载文件错误</param>
        public static void LoadAssembly(
            Action<Assembly> load,
            string pattern = "*.*",
            string path = "",
            Func<string, bool> except = null,
            bool shadow = false,
           Action<Exception> doError = null)
        {

            string adjustPath = path;

            if (string.IsNullOrWhiteSpace(adjustPath))
            {
                adjustPath = LoadFunctions.AssemblyDirectory;
            }

            DirectoryInfo dirInfo = new DirectoryInfo(adjustPath);
            foreach (FileInfo file in dirInfo.GetFiles(pattern))
            {
                try
                {
                    bool isFilePass = true;
                    if (except != null)
                    {
                        isFilePass = !except(file.FullName);

                    }

                    if (isFilePass)
                    {
                        Assembly assembly;
                        if (!shadow)
                        {
                            assembly = Assembly.LoadFile(file.FullName);
                        }
                        else
                        {
                            string dllName = file.Name.Remove(file.Name.LastIndexOf("."));
                            assembly = Assembly.Load(dllName);
                        }
                        load(assembly);
                    }
                }
                catch (Exception error)
                {
                    if (doError != null)
                    {
                        doError(error);
                    }
                }
            }
        }



    }
}
