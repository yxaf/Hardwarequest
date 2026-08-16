using System.Diagnostics;
using Hardwarequest.Models;

namespace Hardwarequest.DataAccess
{
    // Populates the database with demo content the FIRST time the app runs against
    // an empty database. Each section is independent and idempotent (it only seeds
    // when its table is empty), so re-running is safe and a partial DB still fills
    // in the gaps. Any failure is swallowed so seeding never blocks app startup.
    public static class DataSeeder
    {
        public static void SeedIfEmpty()
        {
            UpgradePlainTextPasswords();
            EnsureAdmin();
            SeedHardware();
            SeedTopics();
            SeedQuiz();
            SeedForum();
        }

        private static void SeedTopics()
        {
            try
            {
                var repo = new TopicRepository();
                if (repo.GetAll().Count > 0) return;

                int? adminId = new UserRepository().GetByUsername("admin")?.UserId;
                repo.Create(new Topic
                {
                    Title = "How a CPU works",
                    CreatedByUserId = adminId,
                    Body = "The CPU, or processor, is the brain of the computer.\r\n\r\n" +
                           "It works in a simple loop: it fetches an instruction from memory, " +
                           "decodes it to understand what to do, and then executes it. It repeats " +
                           "this billions of times every second.\r\n\r\n" +
                           "Because it is so fast, the CPU can run your games, play videos and open " +
                           "your favourite apps almost instantly. The faster the CPU and the more " +
                           "cores it has, the more work it can do at the same time."
                });
            }
            catch (System.Exception ex) { Debug.WriteLine("Topics seed skipped: " + ex.Message); }
        }

        // Re-saves every account still holding a plain-text password as a salted PBKDF2
        // hash. Passwords themselves are unchanged, so everyone signs in with what they
        // already use. Idempotent: a migrated row no longer looks like plain text and is
        // skipped from then on. Login upgrades any row this misses, so a failure here
        // costs nothing.
        private static void UpgradePlainTextPasswords()
        {
            try
            {
                var users = new UserRepository();
                foreach (User u in users.GetAll())
                {
                    // The stored value IS the password while the row is unmigrated.
                    if (PasswordHasher.IsPlainText(u.PasswordSalt, u.PasswordHash))
                        users.SetPassword(u.Username, u.PasswordHash);
                }
            }
            catch (System.Exception ex) { Debug.WriteLine("Password upgrade skipped: " + ex.Message); }
        }

        // Guarantees the database always has an administrator to sign in with.
        // Only creates one when it is missing — an existing admin keeps whatever
        // password it has, so a changed password is never reset behind the user's back.
        private static void EnsureAdmin()
        {
            try
            {
                const string AdminPassword = "Admin#123";
                var users = new UserRepository();
                if (users.GetByUsername("admin") != null) return;

                string salt = PasswordHasher.NewSalt();
                users.Create(new User
                {
                    Username = "admin",
                    Email = "admin@hardwarequest.local",
                    FullName = "Administrator",
                    PasswordHash = PasswordHasher.Hash(AdminPassword, salt),
                    PasswordSalt = salt,
                    Role = UserRole.Administrator
                });
            }
            catch (System.Exception ex) { Debug.WriteLine("Admin ensure skipped: " + ex.Message); }
        }

        private static void SeedHardware()
        {
            try
            {
                var repo = new HardwareRepository();
                if (repo.GetAll().Count > 0) return;

                // PartKeys match the 3D Explorer parts so the two modules line up.
                repo.Create(new HardwareComponent { Name = "CPU (Processor)", PartKey = "cpu",
                    ChildDescription = "The CPU is the brain of the computer. It does the thinking and runs your programs by carrying out millions of instructions every second." });
                repo.Create(new HardwareComponent { Name = "Motherboard", PartKey = "motherboard",
                    ChildDescription = "The motherboard is the main board that everything plugs into. It connects all the parts so they can talk to each other." });
                repo.Create(new HardwareComponent { Name = "RAM (Memory)", PartKey = "ram",
                    ChildDescription = "RAM is short-term memory. It holds the things the computer is using right now so it can reach them very quickly." });
                repo.Create(new HardwareComponent { Name = "Graphics Card (GPU)", PartKey = "gpu",
                    ChildDescription = "The graphics card draws the pictures, games and videos you see on the screen. It is great at doing lots of work at once." });
                repo.Create(new HardwareComponent { Name = "SSD (Storage)", PartKey = "ssd",
                    ChildDescription = "The SSD is long-term storage. It keeps your files, photos and programs even after the computer is turned off." });
                repo.Create(new HardwareComponent { Name = "Power Supply (PSU)", PartKey = "psu",
                    ChildDescription = "The power supply takes electricity from the wall and turns it into the safe, steady power every part of the computer needs." });
            }
            catch (System.Exception ex) { Debug.WriteLine("Hardware seed skipped: " + ex.Message); }
        }

        private static void SeedQuiz()
        {
            try
            {
                var repo = new QuizRepository();
                if (repo.GetAllQuizzes().Count > 0) return;

                int? adminId = new UserRepository().GetByUsername("admin")?.UserId;
                int quizId = repo.CreateQuiz(new Models.Quiz
                {
                    Title = "Computer Basics",
                    Difficulty = QuizDifficulty.Easy,
                    Description = "Start here! A friendly first quiz about the main parts inside a computer.",
                    CreatedByUserId = adminId,
                    IsPublished = true
                });

                repo.CreateQuestion(new Question { QuizId = quizId, CorrectOption = 'B',
                    Text = "Which part is known as the 'brain' of the computer?",
                    OptionA = "RAM", OptionB = "CPU", OptionC = "SSD", OptionD = "Power supply" });
                repo.CreateQuestion(new Question { QuizId = quizId, CorrectOption = 'C',
                    Text = "What does the graphics card (GPU) mainly do?",
                    OptionA = "Store files", OptionB = "Supply power", OptionC = "Draw images on the screen", OptionD = "Connect to the internet" });
                repo.CreateQuestion(new Question { QuizId = quizId, CorrectOption = 'A',
                    Text = "Which part keeps your files even after the computer is switched off?",
                    OptionA = "SSD", OptionB = "RAM", OptionC = "CPU", OptionD = "Fan" });
                repo.CreateQuestion(new Question { QuizId = quizId, CorrectOption = 'D',
                    Text = "What do all the other parts plug into?",
                    OptionA = "The CPU", OptionB = "The SSD", OptionC = "The graphics card", OptionD = "The motherboard" });
            }
            catch (System.Exception ex) { Debug.WriteLine("Quiz seed skipped: " + ex.Message); }
        }

        private static void SeedForum()
        {
            try
            {
                var forum = new ForumRepository();
                if (forum.GetAllThreads().Count > 0) return;

                // Open the welcome thread as the seeded administrator.
                User admin = new UserRepository().GetByUsername("admin");
                if (admin == null) return;

                forum.CreateThread(admin.UserId,
                    "Welcome to the HardwareQuest forum! ",
                    "Hi everyone! Use this space to ask questions about computer hardware and " +
                    "share what you have learned. Try the 3D Explorer and the quizzes, then " +
                    "tell us which part is your favourite and why.");
            }
            catch (System.Exception ex) { Debug.WriteLine("Forum seed skipped: " + ex.Message); }
        }
    }
}
