using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(Web.Group.Startup))]
namespace Web.Group
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
