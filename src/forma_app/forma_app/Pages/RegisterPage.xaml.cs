using forma_app.ViewModels;

namespace forma_app.Pages;

public partial class RegisterPage : ContentPage
{
	public RegisterPage(RegisterViewModel registerViewModel)
	{
		InitializeComponent();
		BindingContext = registerViewModel;	
	}
}