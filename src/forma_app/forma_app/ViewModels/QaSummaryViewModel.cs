using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.Input;
using forma_app.Model;
using forma_app.Services;

namespace forma_app.ViewModels
{
    public class QaSummaryViewModel : BaseViewModel
    {
        public ApiService ApiService { get; }
        public NavigationService NavigationService { get; }
        private ObservableCollection<SummaryQa>? _answers;

        public ObservableCollection<SummaryQa>? Answers
        {
            get => _answers;
            set => SetProperty(ref _answers, value);
        }

        public QaSummaryViewModel(ApiService apiService, NavigationService navigationService)
        {
            ApiService = apiService;
            NavigationService = navigationService;

            Task.Run(async () =>
            {
                var currentRace = await ApiService.DataApi.DataCurrentRaceRetrieveAsync();

                var answers = await ApiService.TipsApi.TipsAnswersListAsync(currentRace.Id);

                MainThread.BeginInvokeOnMainThread(() =>
                {   
                    Answers = new ObservableCollection<SummaryQa>();
                    foreach (Answer answer in answers)
                    {
                        Answers.Add(new SummaryQa(answer));
                    }
                });
            });
        }

        public RelayCommand BackToMainCommand => new RelayCommand(async () => await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Main, false).ConfigureAwait(false));

        public RelayCommand GoToQaCommand => new RelayCommand(async () => await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Qa, false).ConfigureAwait(false));
    }
}
