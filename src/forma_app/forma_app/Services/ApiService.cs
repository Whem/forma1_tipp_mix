using forma_app.Api;
using forma_app.Client;

namespace forma_app.Services
{
    public class ApiService
    {
        public ApiService()
        {
            GlobalConfiguration.Instance = new Configuration();
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
    }
}
