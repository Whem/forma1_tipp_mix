using forma_app.Pages;

namespace forma_app.Services
{
    public class NavigationService
    {
        public enum NavigationPageEnum
        {
            Main,
            Register,
            Statistics,
            Qa,
            Login,
            QaSummary,
            FillResult,
            Compare
        }

        public NavigationService()
        {
            PagesByKey.Add(NavigationPageEnum.Main, typeof(MainPage));
            PagesByKey.Add(NavigationPageEnum.Register, typeof(RegisterPage));
            PagesByKey.Add(NavigationPageEnum.Statistics, typeof(StatisticsPage));
            PagesByKey.Add(NavigationPageEnum.Qa, typeof(QaPage));
            PagesByKey.Add(NavigationPageEnum.Login, typeof(LoginPage));
            PagesByKey.Add(NavigationPageEnum.QaSummary, typeof(QaSummaryPage));
            PagesByKey.Add(NavigationPageEnum.FillResult, typeof(FillResultPage));
            PagesByKey.Add(NavigationPageEnum.Compare, typeof(ComparePage));

        }

        public async Task OnNavigateAsync(NavigationPageEnum navigationPageEnum, bool isThreaded)
        {
            if (NavigationHistory.Count == 0)
                AddWithTimeout(navigationPageEnum, 2000);
            else
            {
                InsertWithTimeout(navigationPageEnum, 2000);
            }

            if (isThreaded)
            {
                MainThread.BeginInvokeOnMainThread(() =>
                {
                    Shell.Current.GoToAsync(OnGetPageTypeFromEnum(navigationPageEnum), false);
                });
            }
            else
                await Shell.Current.GoToAsync(OnGetPageTypeFromEnum(navigationPageEnum), false);
        }

        private readonly ReaderWriterLockSlim _cacheLock = new ReaderWriterLockSlim();

        public bool AddWithTimeout(NavigationPageEnum navigationPageEnum, int timeout)
        {
            if (_cacheLock.TryEnterWriteLock(timeout))
            {
                try
                {
                    NavigationHistory.Add(navigationPageEnum);
                }
                finally
                {
                    _cacheLock.ExitWriteLock();
                }

                return true;
            }

            return false;
        }

        public bool InsertWithTimeout(NavigationPageEnum navigationPageEnum, int timeout)
        {
            if (_cacheLock.TryEnterWriteLock(timeout))
            {
                try
                {
                    NavigationHistory.Insert(0, navigationPageEnum);
                }
                finally
                {
                    _cacheLock.ExitWriteLock();
                }

                return true;
            }

            return false;
        }


        public List<NavigationPageEnum> NavigationHistory { get; set; } = new();


        public Dictionary<NavigationPageEnum, Type> PagesByKey = new Dictionary<NavigationPageEnum, Type>();


        private string? OnGetPageTypeFromEnum(NavigationPageEnum navigationPageEnum)
        {
            return PagesByKey.FirstOrDefault(p => p.Key == navigationPageEnum).Value?.Name;
        }
    }
}

