using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Mvvm.Input;
using forma_app.Model;
using forma_app.Services;

namespace forma_app.ViewModels
{
    public class RegisterViewModel : BaseViewModel
    {
        private string? _email;
        private string? _password;
        private string? _confirmPassword;
        private Language? _language;
        private string? _nickName;
        private ObservableCollection<Language>? _languages;
        public ApiService ApiService { get; }
        public NavigationService NavigationService { get; }

        public string? Email
        {
            get => _email;
            set => SetProperty(ref _email, value);
        }

        public string? Password
        {
            get => _password;
            set
            {
                if (SetProperty(ref _password, value)) OnPropertyChanged(nameof(RegisterCommand));
            }
        }

        public string? ConfirmPassword
        {
            get => _confirmPassword;
            set
            {
                if (SetProperty(ref _confirmPassword, value)) OnPropertyChanged(nameof(RegisterCommand));
            }
        }

        public Language? Language
        {
            get => _language;
            set => SetProperty(ref _language, value);
        }

        public string? NickName
        {
            get => _nickName;
            set => SetProperty(ref _nickName, value);
        }

        public ObservableCollection<Language>? Languages
        {
            get => _languages;
            set => SetProperty(ref _languages, value);
        }

        public RegisterViewModel(ApiService apiService, NavigationService navigationService)
        {
            ApiService = apiService;
            NavigationService = navigationService;

            Task.Run(async () =>
            {
                var languages = await ApiService.SystemApi.SystemLanguageListAsync();
                Languages = new ObservableCollection<Language>(languages);
            });
        }

        public RelayCommand RegisterCommand => new RelayCommand(async () =>
        {
            if (Password != ConfirmPassword)
            {
                await Toast.Make("Passwords do not match").Show();
                return;
            }

            if (string.IsNullOrEmpty(Email))
            {
                await Toast.Make("You must enter an email").Show();
                return;
            }

            if (string.IsNullOrEmpty(Password))
            {
                await Toast.Make("You must enter a password").Show();
                return;
            }

            if (string.IsNullOrEmpty(NickName))
            {
                await Toast.Make("You must enter a nickname").Show();
                return;
            }

            if (Language == null)
            {
                await Toast.Make("You must select a language").Show();
                return;
            }

            try
            {
                var response = await ApiService.UserEndpoint.UserRegisterCreateAsync(new PostRegistrationRequest(Email, Password, NickName, Language.Id));

                if (response != null)
                {
                    await Toast.Make("User registered successfully").Show();
                    await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Login, true);
                }
                else
                {
                    await Toast.Make("Error registering user").Show();
                }
            }
            catch (Exception e)
            {
                await Toast.Make("Error registering user").Show();
            }

            
        });

        public RelayCommand BackCommand => new RelayCommand(async () => await NavigationService.OnNavigateAsync(NavigationService.NavigationPageEnum.Login, true).ConfigureAwait(false));
    }
}
