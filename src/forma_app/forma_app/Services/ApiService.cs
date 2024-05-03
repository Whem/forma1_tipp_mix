using CommunityToolkit.Mvvm.ComponentModel;
using forma_app.Api;
using forma_app.Client;

namespace forma_app.Services
{
    public class ApiService : ObservableObject
    {
        private bool _isAdmin;

        public ApiService()
        {
            GlobalConfiguration.Instance = new Configuration();
            // https://fonetipper.online
            // http://localhost:8000
            GlobalConfiguration.Instance.BasePath = "https://fonetipper.online";
            UserEndpoint = new UserApi();
            TipsApi = new TipsApi();
            DataApi = new DataApi();
            StatisticApi = new StatisticApi();
            SystemApi = new SystemApi();
        }

        public UserApi UserEndpoint { get; set; }
        public TipsApi TipsApi { get; private set; }
        public DataApi DataApi { get; private set; }
        public StatisticApi StatisticApi { get; private set; }
        public SystemApi SystemApi { get; private set; }

        public bool IsAdmin
        {
            get => _isAdmin;
            set => SetProperty(ref _isAdmin, value);
        }
    }
}
