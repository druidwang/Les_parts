using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.Serialization;
using System.Data;
using System.Data.SqlClient;
using MongoDB.Bson;
using MongoDB.Driver;
using System.Threading;

namespace ConsoleApplication1
{
    class Program
    {
        static void Main(string[] args)
        {
            //using (SqlConnection sqlConn = new SqlConnection("Data Source=localhost;Initial Catalog=test;User ID=sa;Password=P@ssw0rd"))
            //{
            //    sqlConn.Open();
            //    using(SqlTransaction mySqlTransaction = sqlConn.BeginTransaction())
            //    {
            //        SqlCommand cmd = new SqlCommand();
            //    }
            //}

            ////连接信息
            //string conn = "mongodb://localhost";
            //string database = "demoBase";
            //string collection = "demoCollection";

            //MongoServer mongodb = MongoServer.Create(conn);//连接数据库
            //MongoDatabase mongoDataBase = mongodb.GetDatabase(database);//选择数据库名
            //MongoCollection mongoCollection = mongoDataBase.GetCollection(collection);//选择集合，相当于表

            //mongodb.Connect();

            ////普通插入
            //var o = new { Uid = 123, Name = "xixiNormal", PassWord = "111111" };
            //mongoCollection.Insert(o);

            ////对象插入
            //Person p = new Person { Uid = 124, Name = "xixiObject", PassWord = "222222" };
            //mongoCollection.Insert(p);

            ////BsonDocument 插入
            //BsonDocument b = new BsonDocument();
            //b.Add("Uid", 125);
            //b.Add("Name", "xixiBson");
            //b.Add("PassWord", "333333");
            //mongoCollection.Insert(b);



            // Create an instance of the test class.    

            using (SqlConnection sqlConn = new SqlConnection("Data Source=localhost;Initial Catalog=test;User ID=sa;Password=P@ssw0rd"))
            {
                sqlConn.Open();
                using (SqlTransaction mySqlTransaction = sqlConn.BeginTransaction())
                {
                    SqlCommand cmd = new SqlCommand("update tb1 set name='qqweqweq' where id=1",sqlConn);
                    cmd.Transaction = mySqlTransaction;
                    cmd.ExecuteNonQuery();
                    
                    AsyncDemo ad = new AsyncDemo();

                    // Create the delegate.     
                    AsyncDelegate dlgt = new AsyncDelegate(ad.TestMethod);

                    // Initiate the asychronous call.     
                    IAsyncResult ar = dlgt.BeginInvoke(null, null);

                    Thread.Sleep(0);

                    // Call EndInvoke to Wait for        
                    //the asynchronous call to complete,     
                    // and to retrieve the results.     
                    //dlgt.EndInvoke(ar);
                    
                    mySqlTransaction.Commit();
                }
            }



            //Console.WriteLine("The call executed on thread {0},with return value \"{1}\".", threadId, ret);

            Console.ReadLine();
        }
    }

    class Person
    {
        public int Uid;
        public string Name;
        public string PassWord;

    }


    public class AsyncDemo
    {
        // The method to be executed asynchronously.     
        //     
        public void TestMethod()
        {
            //连接信息
            string conn = "mongodb://localhost";
            string database = "demoBase";
            string collection = "demoCollection";

            MongoServer mongodb = MongoServer.Create(conn);//连接数据库
            MongoDatabase mongoDataBase = mongodb.GetDatabase(database);//选择数据库名
            MongoCollection mongoCollection = mongoDataBase.GetCollection(collection);//选择集合，相当于表

            mongodb.Connect();

            //普通插入
            var o = new { Uid = 123, Name = "xixiNormal", PassWord = "111111" };
            mongoCollection.Insert(o);

            //对象插入
            Person p = new Person { Uid = 124, Name = "xixiObject", PassWord = "222222" };
            mongoCollection.Insert(p);

            //BsonDocument 插入
            BsonDocument b = new BsonDocument();
            b.Add("Uid", 125);
            b.Add("Name", "xixiBson");
            b.Add("PassWord", "333333");
            mongoCollection.Insert(b);
            Thread.Sleep(10000);
        }
    }

    // The delegate must have the same signature as the method     
    // you want to call asynchronously.     
    public delegate void AsyncDelegate();   
}