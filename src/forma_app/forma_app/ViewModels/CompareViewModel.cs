using System.Collections.ObjectModel;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Mvvm.Input;
using forma_app.Model;
using forma_app.Services;

namespace forma_app.ViewModels
{
    public class CompareViewModel : BaseViewModel
    {
        private ObservableCollection<Race>? _races;
        private Race? _selectedRace;

        public CompareViewModel(ApiService apiService, NavigationService navigationService)
        {
            ApiService = apiService;
            NavigationService = navigationService;

            Task.Run(async () =>
            {
                List<Race>? races = await ApiService.DataApi.DataRacesListAsync();

                Races = new ObservableCollection<Race>();

                foreach (Race race in races)
                {
                    MainThread.BeginInvokeOnMainThread(() =>
                    {
                        Races.Add(race);
                    });
                }

                
            });
        }

        public ObservableCollection<Race>? Races
        {
            get => _races;
            set => SetProperty(ref _races, value);
        }

        public Race? SelectedRace
        {
            get => _selectedRace;
            set => SetProperty(ref _selectedRace, value);
        }
        public ApiService ApiService { get; private set; }
        public NavigationService NavigationService { get; private set; }

        public RelayCommand CompareCommand => new RelayCommand(async () =>
        {
            if (SelectedRace == null)
            {
                MainThread.BeginInvokeOnMainThread(() =>
                {
                    
                });
                await Toast.Make("You must select").Show();
            }

            if (SelectedRace != null)
                await ApiService.StatisticApi.StatisticCompareCreateAsync(new PostCompareRequest(SelectedRace.Id));
        });
    }
}
