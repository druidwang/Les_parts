using com.Sconit.Entity.ACC;
using com.Sconit.Service;
using com.Sconit.Web.Controllers;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace SconitWeb.Controllers
{
    public class HomeController : BaseController
    {
        public IGenericMgr genericMgr { get; set; }

        public ActionResult Index()
        {
            
            return View();
        }

        public ActionResult About()
        {
            ViewBag.Message = "Your application description page.";

            return View();
        }

        public ActionResult Contact()
        {
            ViewBag.Message = "Your contact page.";

            return View();
        }


        [AllowAnonymous]
        public ActionResult ListUsers()
        {
            return View();
        }

        [AllowAnonymous]
        public ActionResult GetUsers()
        {
            var users = genericMgr.FindAll<User>();
            var user = this.genericMgr.FindById<User>(1);
            user.TelPhone = "13764365351";
            //this.genericMgr.Update(user);
            return Json(users);
        }

        public ActionResult Test()
        {
            return View();
        }
    }
}