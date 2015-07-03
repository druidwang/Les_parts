using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(SconitWeb.Startup))]
namespace SconitWeb
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
