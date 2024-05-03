using forma_app.ViewModels;

namespace forma_app.Pages;

public partial class FillResultPage : ContentPage
{
	public FillResultPage(FillResultViewModel fillResultViewModel)
	{
		InitializeComponent();
		BindingContext = fillResultViewModel;
	}
}