-- HardwareQuest schema (SQL Server LocalDB)
-- Safe to re-run: drops child tables first.
IF OBJECT_ID('dbo.ForumPosts','U')        IS NOT NULL DROP TABLE dbo.ForumPosts;
IF OBJECT_ID('dbo.ForumThreads','U')      IS NOT NULL DROP TABLE dbo.ForumThreads;
IF OBJECT_ID('dbo.Topics','U')            IS NOT NULL DROP TABLE dbo.Topics;
IF OBJECT_ID('dbo.Scores','U')            IS NOT NULL DROP TABLE dbo.Scores;
IF OBJECT_ID('dbo.Questions','U')         IS NOT NULL DROP TABLE dbo.Questions;
IF OBJECT_ID('dbo.Quizzes','U')           IS NOT NULL DROP TABLE dbo.Quizzes;
IF OBJECT_ID('dbo.HardwareComponents','U')IS NOT NULL DROP TABLE dbo.HardwareComponents;
IF OBJECT_ID('dbo.Users','U')             IS NOT NULL DROP TABLE dbo.Users;

CREATE TABLE Users (
    UserId        INT IDENTITY(1,1) PRIMARY KEY,
    Username      NVARCHAR(50)  NOT NULL UNIQUE,
    Email         NVARCHAR(256) NOT NULL UNIQUE,
    FullName      NVARCHAR(100) NOT NULL,
    PasswordHash  NVARCHAR(256) NOT NULL,  -- Base64 PBKDF2-SHA256 hash, never the password
    PasswordSalt  NVARCHAR(256) NOT NULL,  -- Base64 random salt, one per user
    Role          NVARCHAR(20)  NOT NULL,
    CreatedAt     DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE HardwareComponents (
    Id               INT IDENTITY(1,1) PRIMARY KEY,
    Name             NVARCHAR(100) NOT NULL,
    ChildDescription NVARCHAR(MAX) NOT NULL,
    ImagePath        NVARCHAR(256) NULL,
    PartKey          NVARCHAR(50)  NULL,
    CreatedAt        DATETIME      NOT NULL DEFAULT GETDATE()
);

CREATE TABLE Quizzes (
    QuizId      INT IDENTITY(1,1) PRIMARY KEY,
    Title       NVARCHAR(100) NOT NULL,
    Difficulty  NVARCHAR(10)  NOT NULL,
    Description  NVARCHAR(500) NULL,
    ImagePath    NVARCHAR(256) NULL,
    CreatedByUserId INT NULL,
    IsPublished BIT NOT NULL DEFAULT 1
);

CREATE TABLE Topics (
    TopicId         INT IDENTITY(1,1) PRIMARY KEY,
    Title           NVARCHAR(150) NOT NULL,
    Body            NVARCHAR(MAX) NOT NULL,
    ImagePath       NVARCHAR(256) NULL,
    CreatedByUserId INT NULL,
    CreatedAt       DATETIME NOT NULL DEFAULT GETDATE()
);

CREATE TABLE Questions (
    QuestionId    INT IDENTITY(1,1) PRIMARY KEY,
    QuizId        INT           NOT NULL,
    Text          NVARCHAR(500) NOT NULL,
    OptionA       NVARCHAR(200) NULL,
    OptionB       NVARCHAR(200) NULL,
    OptionC       NVARCHAR(200) NULL,
    OptionD       NVARCHAR(200) NULL,
    CorrectOption CHAR(1)       NOT NULL,
    CONSTRAINT FK_Questions_Quizzes FOREIGN KEY (QuizId) REFERENCES Quizzes(QuizId)
);

CREATE TABLE Scores (
    ScoreId INT IDENTITY(1,1) PRIMARY KEY,
    UserId  INT      NOT NULL,
    QuizId  INT      NOT NULL,
    Points  INT      NOT NULL,
    TakenAt DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Scores_Users   FOREIGN KEY (UserId) REFERENCES Users(UserId),
    CONSTRAINT FK_Scores_Quizzes FOREIGN KEY (QuizId) REFERENCES Quizzes(QuizId)
);

CREATE TABLE ForumThreads (
    ThreadId        INT IDENTITY(1,1) PRIMARY KEY,
    Title           NVARCHAR(200) NOT NULL,
    CreatedByUserId INT           NOT NULL,
    CreatedAt       DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Threads_Users FOREIGN KEY (CreatedByUserId) REFERENCES Users(UserId)
);

CREATE TABLE ForumPosts (
    PostId    INT IDENTITY(1,1) PRIMARY KEY,
    ThreadId  INT           NOT NULL,
    UserId    INT           NOT NULL,
    Body      NVARCHAR(MAX) NOT NULL,
    CreatedAt DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Posts_Threads FOREIGN KEY (ThreadId) REFERENCES ForumThreads(ThreadId),
    CONSTRAINT FK_Posts_Users   FOREIGN KEY (UserId)   REFERENCES Users(UserId)
);
