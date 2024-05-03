using forma_app.ViewModels;

namespace forma_app.Pages;

public partial class ComparePage : ContentPage
{
	public ComparePage(CompareViewModel compareViewModel)
	{
		InitializeComponent();
		BindingContext = compareViewModel;
	}
}