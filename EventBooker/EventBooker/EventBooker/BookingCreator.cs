using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading;

namespace EventBooker
{
    public class BookingCreator
    {
        //Instance variables
        private int _hotelId;
        private int _conferenceRoomId;
        private SqlConnection _connection;
        private SqlTransaction _transaction;

        //User input
        private int _customerId;
        private string _hotelName;
        private int _participants;
        private DateTime _startDate;
        private int _days;

        //Method used for testing
        private void GetInputFromMethod()
        {
            _customerId = 1;
            //_hotelName = "Danhostel";
            _hotelName = "Guldsmeden";

            _participants = 4;
            _startDate = DateTime.Now.AddDays(4);
            _days = 5;
        }

        public void Run()
        {
            try
            {
                Console.WriteLine("Med denne applikation kan du booke et hotel arrangement.");

                //GetInputFromUser();

                //For testing the code without entering data every time.
                GetInputFromMethod();

                SetHotelIdFromName();
                _transaction = GetConnection().BeginTransaction(IsolationLevel.Serializable);

                //Find the smallest vacant room
                var vacantRoom = GetVacantRoom();
                _conferenceRoomId = vacantRoom;

                //My first intuition was to create the same logic contained in booking_helper_trigger.
                //Inserting the booking and checking if that went well, using the trigger seems smarter.                
                try
                {
                    InsertBooking();
                }
                catch (Exception)
                {
                    throw new Exception("Der er desværre ikke plads på hotelet i den valgte periode.");
                }

                //Find name of the room.
                var roomName = GetNameOfRoom(vacantRoom);

                //Asking if the user wants to confirm the booking.
                Console.WriteLine("Vil du genenmføre bookingen, og booke rummet: {0} ?", roomName);
                Console.WriteLine("Tryk J for Ja eller N for Nej");
                if (ShouldProceedWithBooking())
                {
                    _transaction.Commit();
                    Console.WriteLine("Bookingen er gennemført.");
                }
                else
                {
                    _transaction.Rollback();
                    Console.WriteLine("Bookingen er annulleret.");
                }
            }
            catch (Exception ex)
            {
                if (_transaction != null)
                {
                    _transaction.Rollback();
                }
                Console.WriteLine(ex.Message);
            }
            finally
            {
                if (_connection != null)
                {
                    _connection.Close();
                }
                Console.WriteLine("Tryk på en vilkårlig tast for at afslutte.");
                Console.ReadKey();
            }
        }

        private void InsertBooking()
        {
            var query = "INSERT INTO Booking (HotelId, ConferenceRoomId, CompanyCustomerId, Participants, StartDate, Days) " +
                                     "VALUES (@HotelId, @ConferenceRoomId, @CompanyCustomerId, @Participants, @StartDate, @Days) ";

            SqlCommand command = new SqlCommand(query, GetConnection());
            command.Transaction = _transaction;
            command.Parameters.AddWithValue("@HotelId", _hotelId);
            command.Parameters.AddWithValue("@ConferenceRoomId", _conferenceRoomId);
            command.Parameters.AddWithValue("@CompanyCustomerId", _customerId);
            command.Parameters.AddWithValue("@Participants", _participants);
            command.Parameters.AddWithValue("@StartDate", _startDate.Date);
            command.Parameters.AddWithValue("@Days", _days);
            command.ExecuteNonQuery();
        }

        private string GetNameOfRoom(int vacantRoom)
        {
            var query = "SELECT Name " +
                        "FROM ConferenceRoom " +
                        "WHERE Id = @RoomId ";

            SqlCommand command = new SqlCommand(query, GetConnection());
            command.Transaction = _transaction;
            command.Parameters.AddWithValue("@RoomId", vacantRoom);
            SqlDataReader reader = command.ExecuteReader();

            string result = "";
            using (reader)
            {
                if (reader.HasRows)
                {
                    while (reader.Read())
                    {
                        result = reader.GetString(0);
                    }
                }
                else
                {
                    throw new Exception("Der blev ikke fundet et mødelokale med det id.");
                }
            }
            return result;
        }

        private void SetHotelIdFromName()
        {
            var query = "SELECT Id " +
                        "FROM Hotel " +
                        "WHERE Name = @HotelName ";

            SqlCommand command = new SqlCommand(query, GetConnection());
            command.Parameters.AddWithValue("@HotelName", _hotelName);
            SqlDataReader reader = command.ExecuteReader();

            using (reader)
            {
                if (reader.HasRows)
                {
                    while (reader.Read())
                    {
                        _hotelId = reader.GetInt32(0);
                    }
                }
                else
                {
                    throw new Exception("Der findes desværre ikke et hotel med det navn.");
                }
            }
        }

        private int GetVacantRoom()
        {
            var query = "DECLARE @Result INT " +
                        "EXEC @Result = smallest_available_conference_room @HotelId, @StartDate, @Days, @Participants " +
                        "SELECT @Result ";

            SqlCommand command = new SqlCommand(query, GetConnection());
            command.Transaction = _transaction;
            command.Parameters.AddWithValue("@HotelId", _hotelId);
            command.Parameters.AddWithValue("@StartDate", _startDate.Date);
            command.Parameters.AddWithValue("@Days", _days);
            command.Parameters.AddWithValue("@Participants", _participants);

            SqlDataReader reader = command.ExecuteReader();
            int result = 0;
            using (reader)
            {
                if (reader.HasRows)
                {
                    while (reader.Read())
                    {
                        if (reader.IsDBNull(0))
                        {
                            throw new Exception("Der blev desværre ikke fundet et passende ledigt mødelokale.");
                        }
                        return reader.GetInt32(0);
                    }
                }
                else
                {
                    throw new Exception("Der blev desværre ikke fundet et passende ledigt mødelokale.");
                }
            }
            return result;
        }

        private void GetInputFromUser()
        {

            Console.WriteLine("Indtast kunde id:");
            _customerId = GetPositiveIntFromUser();

            Console.WriteLine("Indtast hotel navn:");
            _hotelName = Console.ReadLine();

            Console.WriteLine("Indtast antal deltagere:");
            _participants = GetPositiveIntFromUser();

            Console.WriteLine("Indtast start dato:");
            _startDate = GetFutureDateFromUser();

            Console.WriteLine("Indtast arrangementets varighed i dage:");
            _days = GetPositiveIntFromUser();
        }

        private void SleepFor(int pauseTimeInSeconds)
        {
            for (int i = pauseTimeInSeconds; i > 0; i--)
            {
                Console.WriteLine(i);
                Thread.Sleep(1000);
            }
        }

        private SqlConnection GetConnection()
        {
            string connectionString = "Server=localhost,1439;Database=hotelbooking;User=sa;Password=MyPass@word;";

            if (_connection == null)
            {
                _connection = new SqlConnection(connectionString);
                _connection.Open();
            }
            return _connection;
        }

        private int GetPositiveIntFromUser()
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

        private DateTime GetFutureDateFromUser()
        {
            Console.WriteLine("Datoformat: DD-MM-YYYY");
            while (true)
            {
                DateTime result;
                var userInput = Console.ReadLine();
                if (userInput.Length == 10 && DateTime.TryParse(userInput, out result))
                {
                    if (result.Date >= DateTime.Now.Date)
                    {
                        return result;
                    }
                    Console.WriteLine("Det er ikke tilladt at booke i fortiden.");
                }
                Console.WriteLine("Indtast venligst en dato i det korrekte format:");
            }
        }

        private bool ShouldProceedWithBooking()
        {
            var valg = Console.ReadKey(true).KeyChar;
            var positiveValg = new char[] { 'J', 'j' };
            var negativeValg = new char[] { 'N', 'n' };
            while (!positiveValg.Contains(valg) && !negativeValg.Contains(valg))
            {
                Console.WriteLine("Tryk J for Ja eller N for Nej");
                valg = Console.ReadKey(true).KeyChar;
            }
            return positiveValg.Contains(valg);
        }
    }
}
