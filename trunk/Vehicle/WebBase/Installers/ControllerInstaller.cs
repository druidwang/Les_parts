using System.Web.Mvc;
using Castle.MicroKernel.Registration;
using Castle.MicroKernel.SubSystems.Configuration;
using Castle.Windsor;
using System.Web;

namespace com.Sconit.WebBase.Installer
{
    public class ControllerInstaller : IWindsorInstaller
    {
        public void Install(IWindsorContainer container, IConfigurationStore store)
        {
            //container.Register(AllTypes.FromThisAssembly()
            //         .BasedOn<IController>()
            //        .If(t => !t.Name.Contains("Base"))
            //       .Configure(c => c.Named(c.ServiceType.FullName).LifeStyle.Transient));


            container.Register(AllTypes.FromAssemblyInDirectory(new AssemblyFilter(HttpContext.Current.Server.MapPath("/bin/")))
                .BasedOn<IController>()
                    .If(t => !t.Name.Contains("Base"))
                   .Configure(c => c.Named(c.ServiceType.FullName).LifeStyle.Transient));
        }
    }
}