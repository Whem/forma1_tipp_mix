using forma_app.ViewModels;

namespace forma_app.Pages;

public partial class LoginPage : ContentPage
{
    public LoginPage(LoginViewModel loginViewModel)
    {
        InitializeComponent();
        BindingContext = loginViewModel;
    }
	
}