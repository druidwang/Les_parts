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
    public class UserController : BaseController
    {

        public IGenericMgr genericMgr { get; set; }
        // GET: User
        public ActionResult Index()
        {
            return View();
        }

        [AllowAnonymous]
        public ActionResult GetUsers()
        {
            var users = genericMgr.FindAll<User>();
            var user = this.genericMgr.FindById<User>(1);
            //user.TelPhone = "13764365351";
            //this.genericMgr.Update(user);
            return Json(users);
        }

        [HttpGet]
        public ActionResult Edit(string Id)
        {
            if (!string.IsNullOrEmpty(Id))
            {
                var User = this.genericMgr.FindById<User>(Int32.Parse(Id));
                return View(User);
            }
            else
            {
                return View();
            }
            
        }
    }
}