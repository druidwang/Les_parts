using Castle.Facilities.AutoTx;
using Castle.MicroKernel.Registration;
using Castle.Windsor;
using Castle.Windsor.Installer;
using com.Sconit.Web.Filters;
using com.Sconit.WebBase.Pluming;
using NHibernate.Event;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Http;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;

namespace SconitWeb
{
    public class MvcApplication : System.Web.HttpApplication, IContainerAccessor
    {
        private static IWindsorContainer container;

        public IWindsorContainer Container
        {
            get { return container; }
        }
        protected void Application_Start()
        {
            BootstrapContainer();
            AreaRegistration.RegisterAllAreas();
            GlobalConfiguration.Configure(WebApiConfig.Register);
            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);
        }


        protected void Application_End()
        {
            container.Dispose();
        }

        private static void RegisterGlobalFilters(GlobalFilterCollection filters)
        {
            filters.Add(new HandleErrorAttribute());
            filters.Add(new ExceptionFilter());
        }


        private static void BootstrapContainer()
        {
            container = new WindsorContainer();
            container.AddFacility("transactionmanagement", new TransactionFacility());
            container.Install(Configuration.FromAppConfig());
            var cfg = container.Resolve<NHibernate.Cfg.Configuration>();
            cfg.SetListener(NHibernate.Event.ListenerType.PostUpdate, new AuditUpdateListener());
            //container.Install(FromAssembly.Named("com.Sconit.Persistence"));
            //container.Install(FromAssembly.Named("com.Sconit.Service"));
            //container.Install(FromAssembly.Named("com.Sconit.Service.MRP"));
            //container.Install(FromAssembly.Named("com.Sconit.Service.SI"));
            container.Install(FromAssembly.InDirectory(new AssemblyFilter(AppDomain.CurrentDomain.RelativeSearchPath)));
            //container.Install(FromAssembly.InDirectory();
            //container.Install(FromAssembly.This());
            var controllerFactory = new WindsorControllerFactory(container);
            ControllerBuilder.Current.SetControllerFactory(controllerFactory);
        }


    }

    public class AuditUpdateListener : IPostUpdateEventListener
    {
        private const string _noValueString = "*No Value*";

        private static string getStringValueFromStateArray(object[] stateArray, int position)
        {
            var value = stateArray[position];

            return value == null || value.ToString() == string.Empty
                    ? _noValueString
                    : value.ToString();
        }

        /// <summary>
        /// 更新事件，将脏数据和更新后的数据存入Log表中
        /// </summary>
        /// <param name="event">更新的event</param>
        public void OnPostUpdate(PostUpdateEvent @event)
        {
            
        }
    }
}





































