using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CommunityToolkit.Mvvm.Input;
using forma_app.Services;

namespace forma_app.ViewModels
{
    public class MainViewModel(NavigationService navigationService, ApiService apiService) : BaseViewModel
    {
        public ApiService ApiService { get; } = apiService;
        public RelayCommand QaCommand => new RelayCommand(async () => await navigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Qa, false).ConfigureAwait(false));

        public RelayCommand StatisticsCommand => new RelayCommand(async () => await navigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Statistics, false).ConfigureAwait(false));

        
        public RelayCommand FillResultsCommand => new RelayCommand(async () => await navigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.FillResult, false).ConfigureAwait(false));
    }
}
