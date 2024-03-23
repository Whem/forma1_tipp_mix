using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Mvvm.Input;
using forma_app.Client;
using forma_app.Model;
using forma_app.Services;

namespace forma_app.ViewModels
{
    public class LoginViewModel : BaseViewModel
    {
        public ApiService ApiService { get; }
        public NavigationService NavigationService { get; }
        private string? _email = null;
        private string? _password = null;

        public StoreService StoreService { get; set; } 

        public LoginViewModel(ApiService apiService, NavigationService navigationService, StoreService storeService)
        {
            ApiService = apiService;
            NavigationService = navigationService;
            StoreService = storeService;

            Task.Run(async () =>
            {
                await StoreService.LoadInitialDataAsync();
                if (StoreService.RememberMe)
                {
                    Email = StoreService.Email;
                    Password = StoreService.Password;
                }
                else
                {
                    Email = null;
                    Password = null;
                }
            });
            
        }

        public string? Email
        {
            get => _email;
            set => SetProperty(ref _email, value);
        }

        public string? Password
        {
            get => _password;
            set => SetProperty(ref _password, value);
        }

        public RelayCommand LoginCommand => new(async () => await LoginAsync().ConfigureAwait(false));

        public async Task LoginAsync()
        {
            if (string.IsNullOrEmpty(Email))
            {
                Application.Current?.MainPage!.DisplayAlert("Error", "You must enter an email.", "Accept").ConfigureAwait(false);
                return;
            }

            if (string.IsNullOrEmpty(Password))
            {
                Application.Current?.MainPage!.DisplayAlert("Error", "You must enter a password.", "Accept").ConfigureAwait(false);
                return;
            }

            try
            {
                Login? response = await ApiService.UserEndpoint.UserLoginCreateAsync(new PostLoginRequest(Email, Password)).ConfigureAwait(false);
                if (response == null)
                {
                    await Toast.Make("User or password incorrect or server is down.").Show();
                    return;
                }
                ApiService.DataApi.Configuration.AccessToken = response.JwtToken;
                ApiService.TipsApi.Configuration.AccessToken = response.JwtToken;
                ApiService.StatisticApi.Configuration.AccessToken = response.JwtToken;
                if (StoreService.RememberMe)
                {
                    StoreService.Email = Email;
                    StoreService.Password = Password;
                }
                else
                {
                    StoreService.Email = null;
                    StoreService.Password = null;
                }

                await StoreService.UpdateEmailAsync(StoreService.Email);
                await StoreService.UpdatePasswordAsync(StoreService.Password);


                await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Main, true).ConfigureAwait(false);
            }
            catch (ApiException)
            {
                await Toast.Make("User or password incorrect or server is down.").Show();
            }

            
        }

        public RelayCommand RegisterCommand => new(async () => await RegisterAsync().ConfigureAwait(false));

        public async Task RegisterAsync()
        {
            try
            {
                var result = await ApiService.SystemApi.SystemPingRetrieveAsync();
                if (result != null)
                {

                }
                else
                {
                    await Toast.Make("Server is down").Show();
                    return;
                }
            }
            catch (Exception e)
            {
                
            }

            await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Register, false).ConfigureAwait(false);
        }
    }
}
