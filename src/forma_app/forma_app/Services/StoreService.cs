using CommunityToolkit.Mvvm.ComponentModel;

namespace forma_app.Services
{
    public class StoreService : ObservableObject
    {
        private bool _rememberMe;
        private bool _stayLoggedIn;
        private string? _token;
        private string? _email;
        private string? _password;

        public StoreService()
        {
            
        }

        public async Task LoadInitialDataAsync()
        {
            await RefreshRememberMeAsync().ConfigureAwait(false);
            await RefreshStayLoggedInAsync().ConfigureAwait(false);
            await RefreshTokenAsync().ConfigureAwait(false);
            await RefreshEmailAsync().ConfigureAwait(false);
            await RefreshPasswordAsync().ConfigureAwait(false);
        }

        public bool StayLoggedIn
        {
            get => _stayLoggedIn;
            set
            {
                SetProperty(ref _stayLoggedIn, value);
                if (!value)
                {
                    Token = null;
                    UpdateTokenAsync(null).ConfigureAwait(false);
                }

                if (value == _stayLoggedIn)
                    UpdateStayLoggedInAsync(value);
                
            }
        }

        public bool RememberMe
        {
            get => _rememberMe;
            set
            {
                SetProperty(ref _rememberMe, value);
                if (!value)
                {
                    StayLoggedIn = false;
                    UpdateStayLoggedInAsync(false).ConfigureAwait(false);
                }

                if (value == _rememberMe)
                    UpdateRememberMeAsync(value);
            }
        }

        public string? Token
        {
            get => _token;
            set
            {
                SetProperty(ref _token, value);

                if (value == _token)
                    UpdateTokenAsync(value).ConfigureAwait(false);
            }
        }

        public string? Email
        {
            get => _email;
            set
            {
                SetProperty(ref _email, value);

                if (value == _email)
                    UpdateEmailAsync(value).ConfigureAwait(false);
            }
        }

        public string? Password
        {
            get => _password;
            set
            {
                SetProperty(ref _password, value);

                if (value == _password)
                    UpdatePasswordAsync(value).ConfigureAwait(false);
            }
        }


        // Asynchronous methods to refresh properties from secure storage
        public async Task RefreshStayLoggedInAsync()
        {
            var result = await SecureStorage.Default.GetAsync("stay_logged_in").ConfigureAwait(false);
            StayLoggedIn = bool.TryParse(result, out bool value) && value;
        }

        public async Task RefreshRememberMeAsync()
        {
            var result = await SecureStorage.Default.GetAsync("remember_me").ConfigureAwait(false);
            RememberMe = bool.TryParse(result, out bool value) && value;
        }

        public async Task RefreshTokenAsync()
        {
            Token = await SecureStorage.Default.GetAsync("token").ConfigureAwait(false);
        }

        // Asynchronous methods to update secure storage and refresh properties
        public async Task UpdateStayLoggedInAsync(bool value)
        {
            await SecureStorage.Default.SetAsync("stay_logged_in", value.ToString()).ConfigureAwait(false);
            if (StayLoggedIn != value)
                await RefreshStayLoggedInAsync().ConfigureAwait(false);
        }

        public async Task UpdateRememberMeAsync(bool value)
        {
            await SecureStorage.Default.SetAsync("remember_me", value.ToString()).ConfigureAwait(false);
            if (RememberMe != value)
                await RefreshRememberMeAsync().ConfigureAwait(false);
        }

        public async Task UpdateTokenAsync(string? value)
        {
            if (value != null)
            {
                await SecureStorage.Default.SetAsync("token", value).ConfigureAwait(false);
                if (Token != value)
                    await RefreshTokenAsync().ConfigureAwait(false);
            }
        }

        public async Task UpdateEmailAsync(string? value)
        {
            if (value != null)
            {
                await SecureStorage.Default.SetAsync("email", value).ConfigureAwait(false);
                if (Email != value)
                    await RefreshEmailAsync().ConfigureAwait(false);
            }
        }

        public async Task UpdatePasswordAsync(string? value)
        {
            if (value != null)
            {
                await SecureStorage.Default.SetAsync("password", value).ConfigureAwait(false);
                if (Password != value)
                    await RefreshPasswordAsync().ConfigureAwait(false);
            }
        }


        public async Task ClearAllAsync()
        {
            await SecureStorage.Default.SetAsync("stay_logged_in", "false").ConfigureAwait(false);
            await SecureStorage.Default.SetAsync("remember_me", "false").ConfigureAwait(false);
            await SecureStorage.Default.SetAsync("token", "").ConfigureAwait(false);
            await SecureStorage.Default.SetAsync("email", "").ConfigureAwait(false);
            await SecureStorage.Default.SetAsync("password", "").ConfigureAwait(false);
            await LoadInitialDataAsync().ConfigureAwait(false);
        }

        public async Task RefreshEmailAsync()
        {
            Email = await SecureStorage.Default.GetAsync("email").ConfigureAwait(false);
        }

        public async Task RefreshPasswordAsync()
        {
            Password = await SecureStorage.Default.GetAsync("password").ConfigureAwait(false);
        }


    }
}
