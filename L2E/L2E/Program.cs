using System;
using System.Linq;
using System.Data.Entity;

namespace L2E
{
    public static class Program
    {
        private static hotelbookingEntities db = new hotelbookingEntities();
        private const string seperator = "--------------------------------------------------------------------------";
        private const string functionSeperator = "##########################################################################";
        static void Main(string[] args)
        {
            //Showing generated sql output in console
            //db.Database.Log = Console.WriteLine;

            ConferenceRoomOverviewDefferedLazy();
            ConferenceRoomOverviewImmidiateEager();
            CreateNewConfConferenceRoom();
            HotelWorkDayCalculator();

            db.Dispose();
            Console.WriteLine("Tryk på en tast for at afslutte.");
            Console.ReadKey();
        }

        private static void ConferenceRoomOverviewDefferedLazy()
        {
            Console.WriteLine(functionSeperator);
            Console.WriteLine("Room overview, enter room name:");
            var roomName = "Room G50";
            // Remove input for easy testing
            roomName = Console.ReadLine();

            var room = db.ConferenceRooms.FirstOrDefault(r => r.Name == roomName);
            if (room != null)
            {
                var result = room.Bookings.Where(b => b.StartDate > DateTime.Now).OrderBy(b => b.StartDate);
                if (result.Any())
                {
                    string allignementString = "{0,-15}{1,-15}{2,-10}{3,-10}";

                    Console.WriteLine(seperator);
                    Console.WriteLine(allignementString, "Navn", "Fradato", "Varighed", "Antal deltagere");
                    Console.WriteLine(seperator);
                    foreach (var booking in result)
                    {
                        Console.WriteLine(allignementString, booking.CompanyCustomer.Name, booking.StartDate.ToShortDateString(), booking.Days, booking.Participants);
                    }
                    Console.WriteLine(seperator);
                    Console.WriteLine();
                }
                else
                {
                    Console.WriteLine("Der blev ikke fundet nogle fremtidige bookinger for det mødelokale");
                }
            }
            else
            {
                Console.WriteLine("Mødelokalet blev ikke fundet..");
            }
            Console.WriteLine(functionSeperator);
        }

        private static void ConferenceRoomOverviewImmidiateEager()
        {
            Console.WriteLine(functionSeperator);
            Console.WriteLine("Room overview, enter room name:");
            var roomName = "Room G50";
            // Remove input for easy testing
            roomName = Console.ReadLine();
            var room = db.Bookings.Include(b => b.CompanyCustomer).Where(b => b.StartDate > DateTime.Now && b.ConferenceRoom.Name == roomName).OrderBy(b => b.StartDate).ToList();
            if (room != null)
            {
                var result = room;
                if (result.Any())
                {
                    string allignementString = "{0,-15}{1,-15}{2,-10}{3,-10}";

                    Console.WriteLine(seperator);
                    Console.WriteLine(allignementString, "Navn", "Fradato", "Varighed", "Antal deltagere");
                    Console.WriteLine(seperator);
                    foreach (var booking in result)
                    {
                        Console.WriteLine(allignementString, booking.CompanyCustomer.Name, booking.StartDate.ToShortDateString(), booking.Days, booking.Participants);
                    }
                    Console.WriteLine(seperator);
                    Console.WriteLine();
                }
                else
                {
                    Console.WriteLine("Der blev ikke fundet nogle fremtidige bookinger for det mødelokale");
                }
            }
            else
            {
                Console.WriteLine("Mødelokalet blev ikke fundet..");
            }
            Console.WriteLine(functionSeperator);
        }

        private static void CreateNewConfConferenceRoom()
        {
            Console.WriteLine(functionSeperator);
            Console.WriteLine("Oprettelse af nyt mødelokale.");
            Console.WriteLine("Tast hotel id:");
            var hotelId = GetPositiveIntFromUser();
            Console.WriteLine("Tast lokale navn:");
            var roomName = Console.ReadLine();
            Console.WriteLine("Indtast kapacitet:");
            var capacity = GetPositiveIntFromUser();

            db.ConferenceRooms.Add(new ConferenceRoom()
            {
                HotelId = hotelId,
                Capacity = capacity,
                Name = roomName
            });
            db.SaveChanges();
            Console.WriteLine(functionSeperator);
        }

        private static void HotelWorkDayCalculator()
        {
            Console.WriteLine(functionSeperator);
            Console.WriteLine("Udregning af hvad der sker på et hotel en bestemt dato.");
            Console.WriteLine("Indtast hotel id:");

            var hotelId = 2;
            // Remove input for easy testing
            hotelId = GetPositiveIntFromUser();

            Console.WriteLine("Indtast dato:");
            var date = DateTime.Parse("19-05-2020");
            // Remove input for easy testing
            date = GetDateFromUser();

            var activeBookings = db.Bookings.Where(b => b.HotelId == hotelId && (b.StartDate <= date && DbFunctions.AddDays(b.StartDate, b.Days) > date)).ToList();
            int breakfastAndLunch = 0;
            int dinnerAndNights = 0;
            foreach (var booking in activeBookings)
            {
                breakfastAndLunch += booking.Participants;

                if (booking.StartDate.AddDays(booking.Days - 1) != date)
                {
                    dinnerAndNights += booking.Participants;
                }
            }
            if (activeBookings.Any())
            {
                Console.WriteLine(seperator);
                Console.WriteLine("Morgenmad:\t" + breakfastAndLunch);
                Console.WriteLine("Frokost:\t" + breakfastAndLunch);
                Console.WriteLine("Aftensmad:\t" + dinnerAndNights);
                Console.WriteLine("Overnatninger:\t" + dinnerAndNights);
                Console.WriteLine(seperator);

            }
            else
            {
                Console.WriteLine("No bookings on that date.");
            }
            Console.WriteLine(functionSeperator);
        }

        private static int GetPositiveIntFromUser()
        {
            while (true)
            {
                int input;
                if (int.TryParse(Console.ReadLine(), out input) && input > 0)
                {
                    return input;
                }
                Console.WriteLine("Indtast venligst et positivt heltal mindre end: " + int.MaxValue);
            }
        }

        private static DateTime GetDateFromUser()
        {
            Console.WriteLine("Datoformat: DD-MM-YYYY");
            while (true)
            {
                DateTime result;
                var userInput = Console.ReadLine();
                if (userInput.Length == 10 && DateTime.TryParse(userInput, out result))
                {
                    return result;
                }
                Console.WriteLine("Indtast venligst en dato i det korrekte format:");
            }
        }

    }
}
