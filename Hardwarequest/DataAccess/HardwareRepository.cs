using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using Hardwarequest.Models;

namespace Hardwarequest.DataAccess
{
    public class HardwareRepository
    {
        private const string Columns =
            "Id, Name, ChildDescription, ImagePath, PartKey, CreatedAt";

        public List<HardwareComponent> GetAll()
        {
            var list = new List<HardwareComponent>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT " + Columns + " FROM HardwareComponents ORDER BY Name", con))
            {
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read()) list.Add(Map(r));
            }
            return list;
        }

        // Components whose name or description contains the search term.
        // A blank term returns everything (same as GetAll).
        public List<HardwareComponent> Search(string term)
        {
            if (string.IsNullOrWhiteSpace(term)) return GetAll();

            var list = new List<HardwareComponent>();
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT " + Columns + " FROM HardwareComponents " +
                "WHERE Name LIKE @q OR ChildDescription LIKE @q ORDER BY Name", con))
            {
                cmd.Parameters.AddWithValue("@q", "%" + term.Trim() + "%");
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    while (r.Read()) list.Add(Map(r));
            }
            return list;
        }

        public HardwareComponent GetById(int id)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "SELECT " + Columns + " FROM HardwareComponents WHERE Id=@id", con))
            {
                cmd.Parameters.AddWithValue("@id", id);
                con.Open();
                using (SqlDataReader r = cmd.ExecuteReader())
                    return r.Read() ? Map(r) : null;
            }
        }

        public int Create(HardwareComponent c)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "INSERT INTO HardwareComponents (Name, ChildDescription, ImagePath, PartKey) " +
                "VALUES (@n, @d, @img, @pk); SELECT CAST(SCOPE_IDENTITY() AS INT);", con))
            {
                AddCoreParams(cmd, c);
                con.Open();
                return (int)cmd.ExecuteScalar();
            }
        }

        public void Update(HardwareComponent c)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand(
                "UPDATE HardwareComponents SET Name=@n, ChildDescription=@d, " +
                "ImagePath=@img, PartKey=@pk WHERE Id=@id", con))
            {
                AddCoreParams(cmd, c);
                cmd.Parameters.AddWithValue("@id", c.Id);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        public void Delete(int id)
        {
            using (SqlConnection con = Db.GetConnection())
            using (var cmd = new SqlCommand("DELETE FROM HardwareComponents WHERE Id=@id", con))
            {
                cmd.Parameters.AddWithValue("@id", id);
                con.Open();
                cmd.ExecuteNonQuery();
            }
        }

        private static void AddCoreParams(SqlCommand cmd, HardwareComponent c)
        {
            cmd.Parameters.AddWithValue("@n", c.Name);
            cmd.Parameters.AddWithValue("@d", c.ChildDescription);
            cmd.Parameters.AddWithValue("@img", (object)c.ImagePath ?? DBNull.Value);
            cmd.Parameters.AddWithValue("@pk", (object)c.PartKey ?? DBNull.Value);
        }

        private static HardwareComponent Map(IDataRecord r) => new HardwareComponent
        {
            Id = (int)r["Id"],
            Name = (string)r["Name"],
            ChildDescription = (string)r["ChildDescription"],
            ImagePath = r["ImagePath"] as string,
            PartKey = r["PartKey"] as string,
            CreatedAt = (DateTime)r["CreatedAt"]
        };
    }
}
