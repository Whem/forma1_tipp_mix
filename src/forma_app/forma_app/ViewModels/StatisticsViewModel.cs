using System.Collections.ObjectModel;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Mvvm.Input;
using forma_app.Model;
using forma_app.Services;

namespace forma_app.ViewModels
{
    public class StatisticsViewModel : BaseViewModel
    {
        private ObservableCollection<UserScoreStatistics> _statistics;

        public StatisticsViewModel(ApiService apiService, NavigationService navigationService)
        {
            ApiService = apiService;
            NavigationService = navigationService;

            Task.Run(async () =>
            {
                try
                {
                    IsBusy = true;
                    await Task.Delay(2000);
                    

                    Statistics = new ObservableCollection<UserScoreStatistics>();
                    List<UserScoreStatistics>? statistics = await ApiService.StatisticApi.StatisticStatisticsListAsync("total");
                    foreach (var user in statistics)
                    {
                        MainThread.BeginInvokeOnMainThread(() =>
                        {
                            Statistics.Add(user);
                        });
                    }

                    
                }
                catch (Exception e)
                {
                    MainThread.BeginInvokeOnMainThread(async () => { await Toast.Make(e.Message).Show(); });
                }
                finally
                {
                    IsBusy = false;
                }

            });
        }

        public ObservableCollection<UserScoreStatistics> Statistics
        {
            get => _statistics;
            set => SetProperty(ref _statistics, value);
        }

        public ApiService ApiService { get; }
        public NavigationService NavigationService { get; }
        
        public RelayCommand BackCommand => new RelayCommand(async () =>
        {
            await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Main, false);
        });
    }
}
